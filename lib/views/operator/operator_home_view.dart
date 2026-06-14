// Pantalla principal del operador con métricas reales
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../shared/app_header.dart';
import 'operator_edit_profile_view.dart';
import 'operator_publish_view.dart';
import 'requests_view.dart';
import 'widgets/operator_destination_card.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import '../../controllers/notificacion_controller.dart';
import '../student/widgets/notifications_panel.dart';

class OperatorHomeView extends StatefulWidget {
  const OperatorHomeView({super.key});

  @override
  State<OperatorHomeView> createState() => _OperatorHomeViewState();
}

class _OperatorHomeViewState extends State<OperatorHomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeMenu = 'Inicio';
  final List<String> _menuItems = ['Inicio', 'Publicar', 'Solicitudes'];
  int _refreshKey = 0;

  // Métricas del operador calculadas desde Firestore
  int _totalPublicaciones = 0;
  int _totalReservas = 0;
  int _reservasPendientes = 0;
  double _ingresosTotales = 0;
  double _calificacionPromedio = 0;
  int _totalResenas = 0;
  bool _cargandoMetricas = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthController>(context, listen: false);
      final notifCtrl =
          Provider.of<NotificacionController>(context, listen: false);
      if (auth.usuarioActual != null) {
        // Escucha notificaciones del operador en tiempo real
        notifCtrl.listenToNotificaciones(auth.usuarioActual!.id,
            collectionName: 'operadores');
        _cargarMetricasOperador(auth.usuarioActual!.id);
      }
    });
  }

  // Carga las métricas propias del operador: reservas, ingresos y calificación
  Future<void> _cargarMetricasOperador(String operadorId) async {
    try {
      final db = FirebaseFirestore.instance;

      // Traemos datos en paralelo para mayor velocidad
      final results = await Future.wait([
        db
            .collection('destinos')
            .where('operadorId', isEqualTo: operadorId)
            .get(),
        db
            .collection('reservas')
            .where('operadorId', isEqualTo: operadorId)
            .get(),
        db
            .collection('usuarios')
            .doc(operadorId)
            .get(),
      ]);

      final destinosSnap = results[0] as QuerySnapshot;
      final reservasSnap = results[1] as QuerySnapshot;
      final operadorDoc = results[2] as DocumentSnapshot;

      // Contamos reservas pendientes (sin pagar aún)
      int pendientes = 0;
      double ingresos = 0;
      for (final doc in reservasSnap.docs) {
        final estado = doc['estadoActual'] as String? ?? '';
        if (estado == 'solicitado' || estado == 'verificandoPago') {
          pendientes++;
        }
        // Solo sumamos ingresos de reservas confirmadas
        if (estado == 'pagado' || estado == 'disfrutado') {
          ingresos += (doc['totalGeneral'] as num? ?? 0).toDouble();
        }
      }

      // La calificación ya fue calculada por review_view al publicar reseñas
      final operadorData =
          operadorDoc.data() as Map<String, dynamic>? ?? {};
      final calificacion =
          (operadorData['calificacionPromedio'] as num? ?? 0).toDouble();
      final totalResenas =
          (operadorData['totalResenas'] as num? ?? 0).toInt();

      if (mounted) {
        setState(() {
          _totalPublicaciones = destinosSnap.docs.length;
          _totalReservas = reservasSnap.docs.length;
          _reservasPendientes = pendientes;
          _ingresosTotales = ingresos;
          _calificacionPromedio = calificacion;
          _totalResenas = totalResenas;
          _cargandoMetricas = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargandoMetricas = false);
    }
  }

  // Navegar 

  void _handleMenuSelected(String menu) {
    if (menu == 'Publicar') {
      setState(() => _activeMenu = menu);
      Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OperatorPublishView()))
          .then((_) {
        setState(() {
          _activeMenu = 'Inicio';
          _refreshKey++;
        });
      });
    } else if (menu == 'Solicitudes') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const OperatorRequestsView()));
    } else if (menu == 'Inicio') {
      setState(() => _activeMenu = menu);
    }
  }

  void _handleEditProfile() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => OperatorEditProfileView()));
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

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje),
      backgroundColor: const Color(0xFFFC6707),
      duration: const Duration(seconds: 2),
    ));
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  Future<void> _eliminarPublicacion(String id, String nombre) async {
    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: 'Eliminar publicación',
      message:
          '¿Estás seguro de que deseas eliminar "$nombre"? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      icon: Icons.delete,
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('destinos')
            .doc(id)
            .delete();
        _mostrarMensaje('Publicación eliminada');
        setState(() => _refreshKey++);
      } catch (e) {
        _mostrarMensaje('Error al eliminar');
      }
    }
  }

  // Build 

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final auth = Provider.of<AuthController>(context);
    final operadorId = auth.usuarioActual?.id ?? '';
    final empresa = auth.usuarioActual?.empresa ?? 'Operador';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer() : null,
      body: Column(
        children: [
          AppHeader(
            activeMenu: _activeMenu,
            onMenuSelected: _handleMenuSelected,
            onEditProfile: _handleEditProfile,
            onLogout: _handleLogout,
            menuItems: _menuItems,
            isMobile: isMobile,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(
            child: isMobile
                ? _buildMobileLayout(empresa, operadorId)
                : _buildDesktopLayout(empresa, operadorId),
          ),
        ],
      ),
      floatingActionButton: !isMobile
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFFFC6707),
              child:
                  const Icon(Icons.help_outline, color: Colors.white),
            )
          : null,
    );
  }

  // Layouts 

  Widget _buildMobileLayout(String empresa, String operadorId) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildWelcomeBanner(empresa, isMobile: true),
          const SizedBox(height: 16),
          // Métricas del operador en móvil
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMetricasOperador(isMobile: true),
          ),
          const SizedBox(height: 24),
          _buildMainContent(isMobile: true, operadorId: operadorId),
          _buildFooter(true),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(String empresa, String operadorId) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildWelcomeBanner(empresa, isMobile: false),
                const SizedBox(height: 24),
                // Métricas en desktop
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildMetricasOperador(isMobile: false),
                ),
                const SizedBox(height: 32),
                _buildMainContent(isMobile: false, operadorId: operadorId),
                _buildFooter(false),
              ],
            ),
          ),
        ),
        // Panel derecho: notificaciones y destinos tendencia
        Container(
          width: 320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                const NotificationsPanel(),
                const SizedBox(height: 24),
                _buildTrendingChart(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Banner de bienvenida con nombre de la empresa
  Widget _buildWelcomeBanner(String empresa, {required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24, vertical: isMobile ? 20 : 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F3),
        border: Border(bottom: BorderSide(color: Color(0xFFFFE0C0), width: 1)),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.outfit(
              fontSize: isMobile ? 18 : 22, color: const Color(0xFF333333)),
          children: [
            const TextSpan(text: '¡Hola '),
            TextSpan(
                text: empresa,
                style: const TextStyle(color: Color(0xFFFC6707))),
            const TextSpan(
                text: '! Revisa el estado de tus servicios'),
          ],
        ),
      ),
    );
  }

  // Métricas del operador 

  // publicaciones, reservas pendientes, ingresos y calificación
  Widget _buildMetricasOperador({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu resumen',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isMobile ? 1.3 : 1.4,
          children: [
            _buildMetricaTarjeta(
              titulo: 'Publicaciones',
              valor: '$_totalPublicaciones',
              icono: Icons.tour_outlined,
              color: const Color(0xFFFC6707),
            ),
            _buildMetricaTarjeta(
              titulo: 'Pendientes',
              valor: '$_reservasPendientes',
              icono: Icons.pending_actions_outlined,
              // Si hay pendientes resaltamos en rojo para llamar la atención
              color: _reservasPendientes > 0
                  ? Colors.red
                  : const Color(0xFF888888),
            ),
            _buildMetricaTarjeta(
              titulo: 'Ingresos',
              valor: '\$${_ingresosTotales.toStringAsFixed(0)}',
              icono: Icons.attach_money_outlined,
              color: Colors.green,
            ),
            _buildMetricaTarjeta(
              titulo: 'Calificación',
              // Mostramos el promedio y el total de reseñas
              valor: _calificacionPromedio > 0
                  ? '${_calificacionPromedio.toStringAsFixed(1)} ★'
                  : 'Sin reseñas',
              icono: Icons.star_outline,
              color: Colors.amber,
              subtitulo:
                  _totalResenas > 0 ? '$_totalResenas reseñas' : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricaTarjeta({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
    String? subtitulo,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icono, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spinner mientras cargan los datos
              _cargandoMetricas
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: color),
                    )
                  : Text(
                      valor,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
              Text(
                titulo,
                style: GoogleFonts.outfit(
                    fontSize: 12, color: const Color(0xFF888888)),
              ),
              if (subtitulo != null)
                Text(
                  subtitulo,
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: const Color(0xFFAAAAAA)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Publicaciones 

  Widget _buildMainContent(
      {required bool isMobile, required String operadorId}) {
    final crossAxisCount = isMobile ? 2 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: Text(
            'Tus Publicaciones',
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          key: ValueKey('operator_publications_$_refreshKey'),
          stream: FirebaseFirestore.instance
              .collection('destinos')
              .where('operadorId', isEqualTo: operadorId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFFC6707)));
            }

            if (snapshot.hasError) {
              return _buildEmptyState(
                  Icons.error_outline, 'Error al cargar las publicaciones',
                  color: const Color(0xFFF44336));
            }

            final destinos = snapshot.data?.docs ?? [];

            if (destinos.isEmpty) {
              return _buildEmptyState(Icons.inbox_outlined,
                  'No tienes publicaciones aún',
                  subtitulo:
                      'Presiona "Publicar" para crear tu primer paquete');
            }

            return Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.90,
                ),
                itemCount: destinos.length,
                itemBuilder: (context, index) {
                  final doc = destinos[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return OperatorDestinationCard(
                    id: doc.id,
                    nombre: data['nombre'] ?? 'Sin título',
                    ubicacion: data['ubicacion'] ?? '',
                    precio: (data['precio'] ?? 0).toDouble(),
                    duracion: data['duracion'] ?? 'Full Day',
                    imagenUrl: data['imagen'] ?? '',
                    isOffer: data['isOffer'] == true,
                    activo: data['activo'] == true,
                    cuposTotales: data['cuposTotales'] ?? 0,
                    cuposDisponibles: data['cuposDisponibles'] ?? 0,
                    onDelete: () => _eliminarPublicacion(
                        doc.id, data['nombre'] ?? 'este destino'),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String mensaje,
      {String? subtitulo, Color? color}) {
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
            Icon(icon,
                size: 48, color: color ?? const Color(0xFFCCCCCC)),
            const SizedBox(height: 12),
            Text(mensaje,
                style:
                    const TextStyle(fontSize: 14, color: Color(0xFF999999))),
            if (subtitulo != null) ...[
              const SizedBox(height: 8),
              Text(subtitulo,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFCCCCCC))),
            ],
          ],
        ),
      ),
    );
  }

  // Tarjeta de destinos más buscados (a futuro se puede conectar con analíticas)
  Widget _buildTrendingChart() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Destinos más buscados',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'No hay datos disponibles',
              style:
                  TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
      margin: const EdgeInsets.only(top: 40),
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

  Widget _buildDrawer() {
    final user =
        Provider.of<AuthController>(context).usuarioActual;

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
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFFC6707), width: 2),
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFFFDDBB3),
                      child: Icon(Icons.person,
                          color: Color(0xFFFC6707), size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nombre ?? 'Operador',
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF333333)),
                        ),
                        Text(
                          user?.empresa ?? '',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            ListTile(
              leading: const Icon(Icons.home_outlined,
                  color: Color(0xFFFC6707)),
              title: Text('Inicio',
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFC6707))),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined,
                  color: Color(0xFFFC6707)),
              title: Text('Publicar',
                  style: GoogleFonts.outfit(
                      fontSize: 16, color: const Color(0xFF333333))),
              onTap: () {
                Navigator.pop(context);
                _handleMenuSelected('Publicar');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inbox_outlined,
                  color: Color(0xFFFC6707)),
              title: Text('Solicitudes',
                  style: GoogleFonts.outfit(
                      fontSize: 16, color: const Color(0xFF333333))),
              onTap: () {
                Navigator.pop(context);
                _handleMenuSelected('Solicitudes');
              },
            ),
            const Spacer(),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            ListTile(
              leading: const Icon(Icons.logout_outlined,
                  color: Color(0xFFFC6707)),
              title: Text('Cerrar Sesión',
                  style: GoogleFonts.outfit(
                      fontSize: 16, color: const Color(0xFF333333))),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}