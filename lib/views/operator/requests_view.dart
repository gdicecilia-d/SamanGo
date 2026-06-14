import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/reserva_controller.dart';
import '../../models/reserva.dart';
import '../../models/estado_reserva.dart';
import '../shared/app_header.dart';
import 'operator_home_view.dart';
import 'operator_edit_profile_view.dart';
import 'operator_publish_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';

class OperatorRequestsView extends StatefulWidget {
  const OperatorRequestsView({super.key});

  @override
  State<OperatorRequestsView> createState() => _OperatorRequestsViewState();
}

class _OperatorRequestsViewState extends State<OperatorRequestsView>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> _menuItems = ['Inicio', 'Publicar', 'Solicitudes'];

  // El TabController ahora maneja 3 pestañas: Solicitudes, Pagos, En Curso
  late TabController _tabController;

  // IDs de los paquetes del operador para filtrar sus reservas
  List<String> _misPaquetesIds = [];

  @override
  void initState() {
    super.initState();
    // Solicitudes / Pagos / En Curso (viajes aceptados y pagados)
    _tabController = TabController(length: 3, vsync: this);
    _cargarPaquetesDelOperador();
  }

  // Trae los IDs de los destinos del operador para saber qué reservas mostrar
  Future<void> _cargarPaquetesDelOperador() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final userId = auth.usuarioActual?.id;
    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('destinos')
          .where('operadorId', isEqualTo: userId)
          .get();
      setState(() {
        _misPaquetesIds = snapshot.docs.map((d) => d.id).toList();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Navegación 

  void _handleMenuSelected(String menu) {
    if (menu == 'Inicio') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OperatorHomeView()),
        (route) => false,
      );
    } else if (menu == 'Publicar') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OperatorPublishView()),
      );
    }
  }

  void _handleEditProfile() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const OperatorEditProfileView()));
  }

  void _handleLogout() {
    CustomConfirmDialog.show(
      context: context,
      title: 'Cerrar Sesión',
      message: '¿Estás seguro de que deseas cerrar sesión?',
      confirmText: 'Salir',
      icon: Icons.logout,
    ).then((confirm) async {
      if (confirm == true) {
        await Provider.of<AuthController>(context, listen: false).logout();
        if (!context.mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginView()));
      }
    });
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  // Acciones de solicitud 

  // Acepta la solicitud del estudiante y lo notifica
  Future<void> _aceptarSolicitud(Reserva reserva) async {
    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: 'Aceptar solicitud',
      message:
          '¿Confirmas que deseas aceptar la solicitud de ${reserva.nombreEstudiante} ${reserva.apellidoEstudiante}?',
      confirmText: 'Aceptar',
      icon: Icons.check_circle_outline,
    );
    if (confirm != true || !context.mounted) return;

    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);

    final exito = await reservaCtrl.cambiarEstadoReserva(
        reserva, EstadoReserva.aceptado, auth.usuarioActual!);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(exito
          ? '✅ Solicitud aceptada. El estudiante fue notificado.'
          : '⚠️ No se pudo aceptar la solicitud. Intenta de nuevo.'),
      backgroundColor: exito ? Colors.green : Colors.red,
    ));
  }

  // Rechaza la solicitud con un motivo opcional y notifica al estudiante
  Future<void> _rechazarSolicitud(Reserva reserva) async {
    final motivoCtrl = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Vas a rechazar la solicitud de ${reserva.nombreEstudiante} ${reserva.apellidoEstudiante}.'),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ej: Cupos llenos para esa fecha.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);

    final exito = await reservaCtrl.rechazarSolicitud(
      reserva,
      auth.usuarioActual!,
      motivo: motivoCtrl.text.trim().isNotEmpty ? motivoCtrl.text.trim() : null,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(exito
          ? '❌ Solicitud rechazada. El estudiante fue notificado.'
          : '⚠️ No se pudo rechazar la solicitud. Intenta de nuevo.'),
      backgroundColor: exito ? Colors.orange : Colors.red,
    ));
  }

  // Acciones de pago 

  // Muestra el comprobante de pago en un diálogo para revisarlo
  void _verComprobante(Reserva reserva) {
    if (reserva.comprobanteUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('El estudiante aún no ha subido el comprobante.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Comprobante de pago'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Image.network(
              reserva.comprobanteUrl!,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : const CircularProgressIndicator(),
              errorBuilder: (_, __, ___) =>
                  const Text('No se pudo cargar la imagen'),
            ),
          ],
        ),
      ),
    );
  }

  // Confirma el pago y cambia el estado a "pagado" → el estudiante puede disfrutar el viaje
  Future<void> _aceptarPago(Reserva reserva) async {
    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: 'Confirmar pago',
      message:
          '¿Confirmas que el comprobante de ${reserva.nombreEstudiante} es válido?',
      confirmText: 'Confirmar',
      icon: Icons.check_circle_outline,
    );
    if (confirm != true || !context.mounted) return;

    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);

    final exito = await reservaCtrl.cambiarEstadoReserva(
        reserva, EstadoReserva.pagado, auth.usuarioActual!);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(exito
          ? '✅ Pago confirmado. El estudiante fue notificado.'
          : '⚠️ No se pudo confirmar el pago. Intenta de nuevo.'),
      backgroundColor: exito ? Colors.green : Colors.red,
    ));
  }

  // Rechaza el comprobante con motivo y notifica al estudiante para que reenvíe
  Future<void> _rechazarPago(Reserva reserva) async {
    final motivoCtrl = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar comprobante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Vas a rechazar el comprobante de ${reserva.nombreEstudiante} ${reserva.apellidoEstudiante}.'),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ej: Imagen borrosa, monto incorrecto.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);

    final exito = await reservaCtrl.rechazarPago(
      reserva,
      auth.usuarioActual!,
      motivo:
          motivoCtrl.text.trim().isNotEmpty ? motivoCtrl.text.trim() : null,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(exito
          ? '⚠️ Comprobante rechazado. El estudiante fue notificado.'
          : '⚠️ No se pudo rechazar el comprobante. Intenta de nuevo.'),
      backgroundColor: exito ? Colors.orange : Colors.red,
    ));
  }

  // Marcar como disfrutado 

  // El operador marca el viaje como disfrutado una vez que el estudiante ya lo realizó.
  // Esto habilita al estudiante para dejar su reseña en review_view.dart.
  Future<void> _marcarComoDisfrutado(Reserva reserva) async {
    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: 'Marcar como Disfrutado',
      message:
          '¿Confirmas que ${reserva.nombreEstudiante} ${reserva.apellidoEstudiante} ya realizó el viaje?',
      confirmText: 'Confirmar',
      icon: Icons.celebration_outlined,
    );
    if (confirm != true || !context.mounted) return;

    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);

    // Cambia el estado a "disfrutado" y notifica al estudiante para que deje su reseña
    final exito = await reservaCtrl.cambiarEstadoReserva(
        reserva, EstadoReserva.disfrutado, auth.usuarioActual!);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(exito
          ? '🎉 Viaje marcado como disfrutado. El estudiante puede dejar su reseña.'
          : '⚠️ No se pudo actualizar el estado. Intenta de nuevo.'),
      backgroundColor: exito ? const Color(0xFFFC6707) : Colors.red,
    ));
  }

  // Build 

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9F9F9),
      endDrawer: isMobile ? _buildDrawer() : null,
      body: Column(
        children: [
          AppHeader(
            activeMenu: 'Solicitudes',
            onMenuSelected: _handleMenuSelected,
            onEditProfile: _handleEditProfile,
            onLogout: _handleLogout,
            menuItems: _menuItems,
            isMobile: isMobile,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          // Pestañas: Solicitudes / Pagos / En Curso
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFC6707),
              unselectedLabelColor: const Color(0xFF888888),
              indicatorColor: const Color(0xFFFC6707),
              tabs: const [
                Tab(text: 'Solicitudes'),
                Tab(text: 'Pagos'),
                Tab(text: 'En Curso'), // viajes pagados que aún no se disfrutan
              ],
            ),
          ),
          Expanded(
            child: _misPaquetesIds.isEmpty
                ? const Center(
                    child: Text('Cargando o no tienes paquetes publicados...'))
                : StreamBuilder<List<Reserva>>(
                    stream:
                        Provider.of<ReservaController>(context, listen: false)
                            .obtenerReservasDeMisPaquetes(_misPaquetesIds),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFFFC6707)));
                      }

                      final reservas = snapshot.data ?? [];

                      // Filtros por estado para cada pestaña
                      final solicitudes = reservas
                          .where((r) =>
                              r.estadoActual == EstadoReserva.solicitado)
                          .toList();
                      final pagos = reservas
                          .where((r) =>
                              r.estadoActual == EstadoReserva.verificandoPago)
                          .toList();
                      // "En Curso" = reservas ya pagadas que el operador aún no ha marcado como disfrutadas
                      final enCurso = reservas
                          .where(
                              (r) => r.estadoActual == EstadoReserva.pagado)
                          .toList();

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildListaReservas(
                              solicitudes, 'No hay solicitudes pendientes.'),
                          _buildListaReservas(
                              pagos, 'No hay pagos por verificar.'),
                          _buildListaReservas(
                              enCurso, 'No hay viajes en curso.'),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widgets 

  Widget _buildListaReservas(List<Reserva> reservas, String emptyMessage) {
    if (reservas.isEmpty) {
      return Center(
        child: Text(emptyMessage,
            style: GoogleFonts.outfit(
                fontSize: 18, color: const Color(0xFF999999))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: reservas.length,
      itemBuilder: (context, index) => _buildReservaCard(reservas[index]),
    );
  }

  Widget _buildReservaCard(Reserva reserva) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del estudiante guardado en la reserva (sin consulta extra)
            Text(
              '${reserva.nombreEstudiante} ${reserva.apellidoEstudiante}',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Carnet: ${reserva.carnetEstudiante}',
                style: const TextStyle(color: Color(0xFF888888))),
            const SizedBox(height: 8),
            if (reserva.fechaInicio != null)
              Text(
                  'Fecha: ${reserva.fechaInicio!.day}/${reserva.fechaInicio!.month}/${reserva.fechaInicio!.year}'),
            Text('Personas: ${reserva.numeroPersonas}'),
            Text(
              'Total: \$${reserva.totalGeneral.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 16),
            _buildBotonesAccion(reserva),
          ],
        ),
      ),
    );
  }

  // Muestra botones distintos según el estado actual de la reserva
  Widget _buildBotonesAccion(Reserva reserva) {
    // Pestaña "Solicitudes": el operador acepta o rechaza la solicitud inicial
    if (reserva.estadoActual == EstadoReserva.solicitado) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => _rechazarSolicitud(reserva),
            child:
                const Text('Rechazar', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _aceptarSolicitud(reserva),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC6707),
                foregroundColor: Colors.white),
            child: const Text('Aceptar solicitud'),
          ),
        ],
      );
    }

    // Pestaña "Pagos": el operador revisa el comprobante y confirma o rechaza el pago
    if (reserva.estadoActual == EstadoReserva.verificandoPago) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => _verComprobante(reserva),
            child: const Text('Ver comprobante'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _rechazarPago(reserva),
            child:
                const Text('Rechazar', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _aceptarPago(reserva),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Confirmar pago'),
          ),
        ],
      );
    }

    // Pestaña "En Curso": el operador marca el viaje como disfrutado cuando ya ocurrió
    if (reserva.estadoActual == EstadoReserva.pagado) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => _marcarComoDisfrutado(reserva),
            icon: const Icon(Icons.celebration_outlined),
            label: const Text('Marcar como Disfrutado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC6707),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFFC6707)),
            child: Text('Operador',
                style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          ListTile(
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
              _handleMenuSelected('Inicio');
            },
          ),
          ListTile(
            title: const Text('Solicitudes',
                style: TextStyle(
                    color: Color(0xFFFC6707),
                    fontWeight: FontWeight.bold)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}