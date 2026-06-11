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

class _OperatorRequestsViewState extends State<OperatorRequestsView> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> _menuItems = ['Inicio', 'Publicar', 'Solicitudes'];
  late TabController _tabController;
  List<String> _misPaquetesIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarPaquetesDelOperador();
  }

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
    Navigator.push(context, MaterialPageRoute(builder: (_) => const OperatorEditProfileView()));
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
      }
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

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
              ],
            ),
          ),
          Expanded(
            child: _misPaquetesIds.isEmpty
                ? const Center(child: Text('Cargando o no tienes paquetes publicados...'))
                : StreamBuilder<List<Reserva>>(
                    stream: Provider.of<ReservaController>(context, listen: false).obtenerReservasDeMisPaquetes(_misPaquetesIds),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFFC6707)));
                      }

                      final reservas = snapshot.data ?? [];

                      final solicitudes = reservas.where((r) => r.estadoActual == EstadoReserva.solicitado).toList();
                      final pagos = reservas.where((r) => r.estadoActual == EstadoReserva.verificandoPago).toList();

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildListaReservas(solicitudes, 'No hay solicitudes pendientes.'),
                          _buildListaReservas(pagos, 'No hay pagos por verificar.'),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaReservas(List<Reserva> reservas, String emptyMessage) {
    if (reservas.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: GoogleFonts.outfit(fontSize: 18, color: const Color(0xFF999999)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: reservas.length,
      itemBuilder: (context, index) {
        final reserva = reservas[index];
        return _buildReservaCard(reserva);
      },
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
            Text(
              'Solicitante ID: ${reserva.estudianteId}', // Idealmente cruzar con coleccion usuarios para ver nombre
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Fecha: ${reserva.fechaInicio?.day}/${reserva.fechaInicio?.month}/${reserva.fechaInicio?.year}'),
            Text('Personas: ${reserva.numeroPersonas}'),
            Text('Total a cobrar: \$${reserva.totalGeneral.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 16),
            _buildBotonesAccion(reserva),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonesAccion(Reserva reserva) {
    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);

    if (reserva.estadoActual == EstadoReserva.solicitado) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rechazado')));
            },
            child: const Text('Rechazar', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              await reservaCtrl.cambiarEstadoReserva(reserva, EstadoReserva.aceptado, auth.usuarioActual!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC6707), foregroundColor: Colors.white),
            child: const Text('Aceptar Solicitud'),
          ),
        ],
      );
    } else if (reserva.estadoActual == EstadoReserva.verificandoPago) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
               // Reject payment logic
            },
            child: const Text('Rechazar Comprobante', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              await reservaCtrl.cambiarEstadoReserva(reserva, EstadoReserva.pagado, auth.usuarioActual!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Aceptar Pago'),
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
          const DrawerHeader(decoration: BoxDecoration(color: Color(0xFFFC6707)), child: Text('Operador', style: TextStyle(color: Colors.white))),
          ListTile(
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
              _handleMenuSelected('Inicio');
            },
          ),
          ListTile(
            title: const Text('Solicitudes', style: TextStyle(color: Color(0xFFFC6707), fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
