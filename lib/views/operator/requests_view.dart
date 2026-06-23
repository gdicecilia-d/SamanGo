import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../controllers/auth_controller.dart';
import '../../controllers/reserva_controller.dart';
import '../../models/reserva.dart';
import '../../models/estado_reserva.dart';
import '../shared/app_header.dart';
import 'operator_home_view.dart';
import 'operator_edit_profile_view.dart';
import 'operator_publish_view.dart';
import 'operator_notifications_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import '../student/widgets/horizontal_scroll_section.dart';
import '../../services/notificacion_service.dart';

class OperatorRequestsView extends StatefulWidget {
  const OperatorRequestsView({super.key});

  @override
  State<OperatorRequestsView> createState() => _OperatorRequestsViewState();
}

class _OperatorRequestsViewState extends State<OperatorRequestsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> _menuItems = ['Inicio', 'Publicar', 'Solicitudes'];
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
  }

  void _handleMenuSelected(String menu) {
    if (menu == 'Inicio') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OperatorHomeView()),
        (route) => false,
      );
    } else if (menu == 'Publicar') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OperatorPublishView()),
      );
    }
  }

  void _handleEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OperatorEditProfileView()),
    );
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
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
      }
    });
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  void _navegarADetalle(String paqueteId, bool isOffer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaqueteDetailView(
          paqueteId: paqueteId,
          isOffer: isOffer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final auth = Provider.of<AuthController>(context);
    final operadorId = auth.usuarioActual?.id ?? '';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
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
          Expanded(
            child: isMobile
                ? _buildMobileLayout(operadorId)
                : _buildDesktopLayout(operadorId),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(String operadorId) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Gestionar Solicitudes',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildPaquetesList(isMobile: true, operadorId: operadorId),
              const SizedBox(height: 24),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const Spacer(), 
              _buildFooter(true), 
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(String operadorId) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Gestionar Solicitudes',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildPaquetesList(isMobile: false, operadorId: operadorId),
              const SizedBox(height: 24),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const Spacer(), 
              _buildFooter(false), 
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    final auth = Provider.of<AuthController>(context);
    final user = auth.usuarioActual;

    return Drawer(
      backgroundColor: Colors.white,
      width: 280,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _handleEditProfile,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFC6707), width: 2),
                      ),
                      child: ClipOval(
                        child: user?.fotoBase64 != null && user!.fotoBase64!.isNotEmpty
                            ? Image.memory(
                                base64Decode(user.fotoBase64!),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const CircleAvatar(
                                backgroundColor: Color(0xFFFDDBB3),
                                child: Icon(Icons.person, color: Color(0xFFFC6707), size: 28),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nombre ?? 'Operador',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                        ),
                        Text(
                          user?.empresa ?? '',
                          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDrawerItem('Inicio', Icons.home_outlined, () {
                      Navigator.pop(context);
                      _handleMenuSelected('Inicio');
                    }),
                    _buildDrawerItem('Publicar', Icons.add_box_outlined, () {
                      Navigator.pop(context);
                      _handleMenuSelected('Publicar');
                    }),
                    _buildDrawerItem('Solicitudes', Icons.receipt_outlined, () {
                      Navigator.pop(context);
                    }),
                    _buildDrawerItem('Notificaciones', Icons.notifications_outlined, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OperatorNotificationsView()),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                _buildDrawerItem('Cerrar Sesión', Icons.logout_outlined, () {
                  Navigator.pop(context);
                  _handleLogout();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    final isActive = title == 'Solicitudes';
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFC6707)),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? const Color(0xFFFC6707) : const Color(0xFF333333),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildPaquetesList({required bool isMobile, required String operadorId}) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    double cardWidth;
    double imageHeight;
    
    if (screenWidth < 600) {
      cardWidth = 210;
      imageHeight = 115;
    } else if (screenWidth < 1200) {
      cardWidth = 250;
      imageHeight = 145;
    } else {
      cardWidth = 300;
      imageHeight = 175;
    }

    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('paquetes_list_$_refreshKey'),
      stream: FirebaseFirestore.instance
          .collection('destinos')
          .where('operadorId', isEqualTo: operadorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(color: Color(0xFFFC6707)),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final paquetes = snapshot.data!.docs;

        if (paquetes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFCCCCCC)),
                  const SizedBox(height: 12),
                  Text(
                    'No tienes paquetes publicados',
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Publica tu primer paquete para recibir solicitudes',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFCCCCCC)),
                  ),
                ],
              ),
            ),
          );
        }

        final cards = paquetes.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final isOffer = data['isOffer'] == true;
          final color = isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);

          return _buildPaqueteCard(
            doc.id,
            data['nombre'] ?? 'Sin título',
            data['ubicacion'] ?? '',
            data['duracion'] ?? 'Full Day',
            data['imagen'] ?? '',
            isOffer,
            color,
            isMobile,
            cardWidth,
            imageHeight,
          );
        }).toList();

        return HorizontalScrollSection(
          title: '',
          showTitle: false,
          children: cards,
        );
      },
    );
  }

  Widget _buildPaqueteCard(
    String paqueteId,
    String nombre,
    String ubicacion,
    String duracion,
    String imagenUrl,
    bool isOffer,
    Color color,
    bool isMobile,
    double cardWidth,
    double imageHeight,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: SizedBox(
              height: imageHeight,
              width: cardWidth,
              child: _buildImage(imagenUrl, cardWidth, imageHeight),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nombre,
                  style: GoogleFonts.outfit(
                    fontSize: screenWidth > 1200 ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: screenWidth < 600 ? 12 : 13, color: const Color(0xFF888888)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        duracion,
                        style: GoogleFonts.outfit(
                          fontSize: screenWidth < 600 ? 11 : 12,
                          color: const Color(0xFF888888),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: screenWidth < 600 ? 12 : 13, color: const Color(0xFF888888)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        ubicacion,
                        style: GoogleFonts.outfit(
                          fontSize: screenWidth < 600 ? 11 : 12,
                          color: const Color(0xFF888888),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _navegarADetalle(paqueteId, isOffer),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              'Gestionar',
                              style: GoogleFonts.outfit(
                                fontSize: screenWidth < 600 ? 11 : 12,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url, double cardWidth, double imageHeight) {
    if (url.isEmpty) {
      return Container(
        width: cardWidth,
        height: imageHeight,
        color: const Color(0xFFFDDBB3),
        child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
      );
    }

    if (url.startsWith('data:image')) {
      try {
        final base64String = url.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          width: cardWidth,
          height: imageHeight,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: cardWidth,
            height: imageHeight,
            color: const Color(0xFFFDDBB3),
            child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
          ),
        );
      } catch (_) {
        return Container(
          width: cardWidth,
          height: imageHeight,
          color: const Color(0xFFFDDBB3),
          child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
        );
      }
    }

    return Image.network(
      url,
      width: cardWidth,
      height: imageHeight,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: cardWidth,
        height: imageHeight,
        color: const Color(0xFFFDDBB3),
        child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFC6707),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Center(
        child: Text(
          '© 2026 SamanGo. Todos los derechos reservados. Comunidad UNIMET.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 10 : 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class PaqueteDetailView extends StatefulWidget {
  final String paqueteId;
  final bool isOffer;

  const PaqueteDetailView({
    super.key,
    required this.paqueteId,
    required this.isOffer,
  });

  @override
  State<PaqueteDetailView> createState() => _PaqueteDetailViewState();
}

class _PaqueteDetailViewState extends State<PaqueteDetailView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> _menuItems = ['Inicio', 'Publicar', 'Solicitudes'];
  int _refreshKey = 0;
  final NotificacionService _notificacionService = NotificacionService();

  Color get _color => widget.isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);

  void _handleMenuSelected(String menu) {
    if (menu == 'Inicio') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OperatorHomeView()),
        (route) => false,
      );
    } else if (menu == 'Publicar') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OperatorPublishView()),
      );
    } else if (menu == 'Solicitudes') {
      Navigator.pop(context);
    }
  }

  void _handleEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OperatorEditProfileView()),
    );
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
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
      }
    });
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: _color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _verificarCuposDisponibles(String paqueteId, int personasRequeridas) async {
    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final cupos = await reservaCtrl.obtenerCuposDisponibles(paqueteId);
    return cupos >= personasRequeridas;
  }

  Future<String> _obtenerNombrePaquete(String paqueteId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('destinos').doc(paqueteId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['nombre'] as String? ?? 'un destino';
      }
    } catch (e) {
      debugPrint('Error obteniendo nombre del paquete: $e');
    }
    return 'un destino';
  }

  Future<void> _aceptarSolicitud(Reserva reserva) async {
    if (!mounted) return;

    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final hayCupos = await _verificarCuposDisponibles(reserva.paqueteId, reserva.numeroPersonas);
    
    if (!hayCupos) {
      final cupos = await reservaCtrl.obtenerCuposDisponibles(reserva.paqueteId);
      _mostrarMensaje('No hay suficientes cupos disponibles. Solo quedan $cupos cupo${cupos > 1 ? 's' : ''} para ${reserva.numeroPersonas} persona${reserva.numeroPersonas > 1 ? 's' : ''}.');
      return;
    }

    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: 'Aceptar solicitud',
      message: '¿Confirmas que deseas aceptar la solicitud de ${reserva.nombreEstudiante} ${reserva.apellidoEstudiante} para ${reserva.numeroPersonas} persona${reserva.numeroPersonas > 1 ? 's' : ''}?',
      confirmText: 'Aceptar',
      icon: Icons.check_circle_outline,
    );
    if (confirm != true || !mounted) return;

    final auth = Provider.of<AuthController>(context, listen: false);

    final exito = await reservaCtrl.cambiarEstadoReserva(
      reserva,
      EstadoReserva.aceptado,
      auth.usuarioActual!,
    );

    if (!mounted) return;

    if (exito) {
      _mostrarMensaje('Solicitud aceptada. Se descontaron ${reserva.numeroPersonas} cupo${reserva.numeroPersonas > 1 ? 's' : ''}.');
      setState(() => _refreshKey++);
    } else {
      final aunHayCupos = await _verificarCuposDisponibles(reserva.paqueteId, reserva.numeroPersonas);
      if (!aunHayCupos) {
        final cupos = await reservaCtrl.obtenerCuposDisponibles(reserva.paqueteId);
        _mostrarMensaje('No hay suficientes cupos disponibles. Solo quedan $cupos cupo${cupos > 1 ? 's' : ''}.');
      } else {
        _mostrarMensaje('No se pudo aceptar la solicitud. Intenta de nuevo.');
      }
    }
  }

  Future<void> _rechazarSolicitud(Reserva reserva) async {
    if (!mounted) return;

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
              'Vas a rechazar la solicitud de ${reserva.nombreEstudiante} ${reserva.apellidoEstudiante}.',
            ),
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
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);

    final exito = await reservaCtrl.rechazarSolicitud(
      reserva,
      auth.usuarioActual!,
      motivo: motivoCtrl.text.trim().isNotEmpty ? motivoCtrl.text.trim() : null,
    );

    if (!mounted) return;

    if (exito) {
      _mostrarMensaje('Solicitud rechazada. El estudiante fue notificado.');
      setState(() => _refreshKey++);
    } else {
      _mostrarMensaje('No se pudo rechazar la solicitud. Intenta de nuevo.');
    }
  }

  Future<void> _confirmarPago(Reserva reserva) async {
    if (!mounted) return;

    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: 'Confirmar pago',
      message: '¿Confirmas que el comprobante de ${reserva.nombreEstudiante} es válido?',
      confirmText: 'Confirmar',
      icon: Icons.check_circle_outline,
    );
    if (confirm != true || !mounted) return;

    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);

    final exito = await reservaCtrl.cambiarEstadoReserva(
      reserva,
      EstadoReserva.pagado,
      auth.usuarioActual!,
    );

    if (!mounted) return;

    if (exito) {
      _mostrarMensaje('Pago confirmado. El estudiante fue notificado.');
      setState(() => _refreshKey++);
    } else {
      _mostrarMensaje('No se pudo confirmar el pago. Intenta de nuevo.');
    }
  }

  Future<void> _rechazarPago(Reserva reserva) async {
    if (!mounted) return;

    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: 'Rechazar comprobante',
      message: '¿Estás seguro de que deseas rechazar el comprobante de ${reserva.nombreEstudiante} ${reserva.apellidoEstudiante}? El estudiante podrá volver a pagar.',
      confirmText: 'Rechazar',
      icon: Icons.cancel,
    );

    if (confirm != true || !mounted) return;

    final motivoCtrl = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(24),
        title: Text(
          'Motivo del rechazo',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opcional: Puedes agregar un motivo para el rechazo.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              decoration: InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ej: Imagen borrosa, monto incorrecto.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx, motivoCtrl.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Rechazar',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);

    try {
      final nombrePaquete = await _obtenerNombrePaquete(reserva.paqueteId);

      await FirebaseFirestore.instance.collection('reservas').doc(reserva.id).update({
        'estadoActual': 'aceptado',
        'comprobanteUrl': null,
        'historial.aceptado': FieldValue.serverTimestamp(),
      });

      await _notificacionService.notificarPagoRechazado(
        estudianteId: reserva.estudianteId,
        nombrePaquete: nombrePaquete,
        motivo: motivo != null && motivo.isNotEmpty ? motivo : null,
      );

      if (!mounted) return;
      _mostrarMensaje('Comprobante rechazado. El estudiante podrá volver a pagar.');
      setState(() => _refreshKey++);
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error al rechazar el comprobante: $e');
    }
  }

  Future<void> _marcarComoDisfrutado(Reserva reserva) async {
    if (!mounted) return;

    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: 'Marcar como Disfrutado',
      message: '¿Confirmas que ${reserva.nombreEstudiante} ${reserva.apellidoEstudiante} ya realizó el viaje?',
      confirmText: 'Confirmar',
      icon: Icons.celebration_outlined,
    );
    if (confirm != true || !mounted) return;

    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);

    final exito = await reservaCtrl.cambiarEstadoReserva(
      reserva,
      EstadoReserva.disfrutado,
      auth.usuarioActual!,
    );

    if (!mounted) return;

    if (exito) {
      _mostrarMensaje('Viaje marcado como disfrutado.');
      setState(() => _refreshKey++);
    } else {
      _mostrarMensaje('No se pudo actualizar el estado. Intenta de nuevo.');
    }
  }

  Future<void> _quitarCupos(Reserva reserva) async {
    if (!mounted) return;

    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: 'Quitar cupos',
      message: '¿Estás seguro de que deseas quitar los ${reserva.numeroPersonas} cupo${reserva.numeroPersonas > 1 ? 's' : ''} reservados para ${reserva.nombreEstudiante} ${reserva.apellidoEstudiante}? Esta acción cancelará la reserva.',
      confirmText: 'Quitar cupos',
      icon: Icons.remove_circle_outline,
    );

    if (confirm != true || !mounted) return;

    try {
      final db = FirebaseFirestore.instance;
      
      final destinoRef = db.collection('destinos').doc(reserva.paqueteId);
      await destinoRef.update({
        'cuposDisponibles': FieldValue.increment(reserva.numeroPersonas),
      });

      await db.collection('reservas').doc(reserva.id).update({
        'estadoActual': 'rechazado',
        'historial.rechazado': FieldValue.serverTimestamp(),
        'comprobanteUrl': null,
      });

      _mostrarMensaje('Cupos quitados correctamente. La reserva fue cancelada.');
      setState(() => _refreshKey++);
    } catch (e) {
      _mostrarMensaje('Error al quitar los cupos: $e');
    }
  }

  void _verComprobante(Reserva reserva) {
    if (reserva.comprobanteUrl == null) {
      _mostrarMensaje('El estudiante aún no ha subido el comprobante.');
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

  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  void _volver() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final isLargeScreen = screenWidth > 1400;
    final double backButtonSize = isLargeScreen ? 20 : 16;
    final double backButtonTop = isMobile ? 130 : (isLargeScreen ? 100 : 80);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer() : null,
      body: Stack(
        children: [
          Column(
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
              Expanded(
                child: isMobile
                    ? _buildDetailMobileLayout()
                    : _buildDetailDesktopLayout(),
              ),
            ],
          ),
          Positioned(
            top: backButtonTop,
            right: 24,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _volver,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        color: _color,
                        size: backButtonSize,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Volver',
                        style: GoogleFonts.outfit(
                          fontSize: backButtonSize,
                          color: _color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMobileLayout() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Gestionar Solicitudes',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildReservasContent(isMobile: true),
              const SizedBox(height: 24),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const Spacer(),
              _buildFooter(true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailDesktopLayout() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Gestionar Solicitudes',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildReservasContent(isMobile: false),
              const SizedBox(height: 24),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const Spacer(),
              _buildFooter(false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    final auth = Provider.of<AuthController>(context);
    final user = auth.usuarioActual;

    return Drawer(
      backgroundColor: Colors.white,
      width: 280,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _handleEditProfile,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFC6707), width: 2),
                      ),
                      child: ClipOval(
                        child: user?.fotoBase64 != null && user!.fotoBase64!.isNotEmpty
                            ? Image.memory(
                                base64Decode(user.fotoBase64!),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const CircleAvatar(
                                backgroundColor: Color(0xFFFDDBB3),
                                child: Icon(Icons.person, color: Color(0xFFFC6707), size: 28),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nombre ?? 'Operador',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                        ),
                        Text(
                          user?.empresa ?? '',
                          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDrawerItem('Inicio', Icons.home_outlined, () {
                      Navigator.pop(context);
                      _handleMenuSelected('Inicio');
                    }),
                    _buildDrawerItem('Publicar', Icons.add_box_outlined, () {
                      Navigator.pop(context);
                      _handleMenuSelected('Publicar');
                    }),
                    _buildDrawerItem('Solicitudes', Icons.receipt_outlined, () {
                      Navigator.pop(context);
                    }),
                    _buildDrawerItem('Notificaciones', Icons.notifications_outlined, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OperatorNotificationsView()),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                _buildDrawerItem('Cerrar Sesión', Icons.logout_outlined, () {
                  Navigator.pop(context);
                  _handleLogout();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    final isActive = title == 'Solicitudes';
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFC6707)),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? const Color(0xFFFC6707) : const Color(0xFF333333),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildReservasContent({required bool isMobile}) {
    return StreamBuilder<List<Reserva>>(
      key: ValueKey('detalle_reservas_$_refreshKey'),
      stream: Provider.of<ReservaController>(context, listen: false)
          .obtenerReservasDeMisPaquetes([widget.paqueteId]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(color: Color(0xFFFC6707)),
            ),
          );
        }

        final reservas = snapshot.data ?? [];

        final porAceptar = reservas
            .where((r) => r.estadoActual == EstadoReserva.solicitado)
            .toList();
        final porVerificar = reservas
            .where((r) => r.estadoActual == EstadoReserva.verificandoPago)
            .toList();
        final porDisfrutar = reservas
            .where((r) => r.estadoActual == EstadoReserva.pagado)
            .toList();
        final enEsperaPago = reservas
            .where((r) => r.estadoActual == EstadoReserva.aceptado)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeccionReservas(
              'Por Aceptar Cupos',
              porAceptar,
              'solicitud',
              isMobile,
              const Color(0xFFFC6707),
            ),
            const SizedBox(height: 32),
            
            _buildSeccionReservas(
              'En Espera de Pago',
              enEsperaPago,
              'espera_pago',
              isMobile,
              const Color(0xFFFF9800),
            ),
            const SizedBox(height: 32),
            
            _buildSeccionReservas(
              'Por Verificar Pagos',
              porVerificar,
              'pago',
              isMobile,
              const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 32),
            
            _buildSeccionReservas(
              'Por Marcar Disfrutado',
              porDisfrutar,
              'disfrutado',
              isMobile,
              const Color(0xFF2196F3),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeccionReservas(
    String titulo,
    List<Reserva> reservas,
    String tipo,
    bool isMobile,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 20 : 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          if (reservas.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              ),
              child: Column(
                children: [
                  Icon(
                    tipo == 'solicitud' ? Icons.pending_actions :
                    tipo == 'espera_pago' ? Icons.hourglass_empty :
                    tipo == 'pago' ? Icons.payment : Icons.celebration,
                    size: 40,
                    color: const Color(0xFFCCCCCC),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tipo == 'solicitud' ? 'No hay solicitudes por aceptar' :
                    tipo == 'espera_pago' ? 'No hay reservas esperando pago' :
                    tipo == 'pago' ? 'No hay pagos por verificar' :
                    'No hay viajes por marcar como disfrutados',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: reservas.asMap().entries.map((entry) {
                final index = entry.key;
                final reserva = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < reservas.length - 1 ? 12 : 0),
                  child: _buildReservaCard(reserva, index + 1, tipo, isMobile),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReservaCard(Reserva reserva, int numero, String tipo, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$numero',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${reserva.nombreEstudiante} ${reserva.apellidoEstudiante}',
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    Text(
                      'Carnet: ${reserva.carnetEstudiante}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF888888),
                      ),
                    ),
                    Text(
                      'Personas: ${reserva.numeroPersonas}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people, size: 16, color: const Color(0xFF888888)),
              const SizedBox(width: 4),
              Text(
                '${reserva.numeroPersonas} persona${reserva.numeroPersonas > 1 ? 's' : ''}',
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF888888)),
              ),
              const SizedBox(width: 16),
              Icon(Icons.attach_money, size: 16, color: const Color(0xFF888888)),
              const SizedBox(width: 4),
              Text(
                '\$${reserva.totalGeneral.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF888888)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (tipo == 'solicitud' && reserva.fechaInicio != null)
            Text(
              'Fecha solicitud: ${_formatFecha(reserva.fechaInicio!)}',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF666666)),
            ),
          if (tipo == 'espera_pago' && reserva.fechaInicio != null)
            Text(
              'Fecha solicitud: ${_formatFecha(reserva.fechaInicio!)}',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF666666)),
            ),
          if (tipo == 'pago' && reserva.fechaInicio != null) ...[
            Text(
              'Fecha pago: ${_formatFecha(reserva.fechaInicio!)}',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF666666)),
            ),
            const SizedBox(height: 4),
            Text(
              'ID Transacción: ${reserva.comprobanteUrl ?? 'No disponible'}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF888888),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
          if (tipo == 'disfrutado' && reserva.fechaInicio != null)
            Text(
              'Fecha disfrutado: ${_formatFecha(reserva.fechaInicio!)}',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF666666)),
            ),
          const SizedBox(height: 12),
          _buildBotones(reserva, tipo, isMobile),
        ],
      ),
    );
  }

  Widget _buildBotones(Reserva reserva, String tipo, bool isMobile) {
    if (tipo == 'solicitud') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => _rechazarSolicitud(reserva),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: Text(
              'Rechazar',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 13 : 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _aceptarSolicitud(reserva),
            style: ElevatedButton.styleFrom(
              backgroundColor: _color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 8 : 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Aceptar',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    if (tipo == 'espera_pago') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () => _quitarCupos(reserva),
            icon: Icon(
              Icons.remove_circle_outline,
              color: Colors.red,
              size: 24,
            ),
            tooltip: 'Quitar cupos',
          ),
        ],
      );
    }

    if (tipo == 'pago') {
      final esPaypal = reserva.comprobanteUrl?.startsWith('paypal_') ?? false;
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!esPaypal)
            TextButton(
              onPressed: () => _verComprobante(reserva),
              style: TextButton.styleFrom(
                foregroundColor: _color,
              ),
              child: Text(
                'Ver comprobante',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 13 : 14,
                  color: _color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => _rechazarPago(reserva),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: Text(
              'Rechazar',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 13 : 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _confirmarPago(reserva),
            style: ElevatedButton.styleFrom(
              backgroundColor: _color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 8 : 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Confirmar',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    if (tipo == 'disfrutado') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => _marcarComoDisfrutado(reserva),
            style: ElevatedButton.styleFrom(
              backgroundColor: _color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 8 : 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Marcar Disfrutado',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFC6707),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Center(
        child: Text(
          '© 2026 SamanGo. Todos los derechos reservados. Comunidad UNIMET.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 10 : 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}