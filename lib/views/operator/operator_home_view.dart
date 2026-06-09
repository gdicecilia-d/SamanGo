// Pantalla principal del operador
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../shared/app_header.dart';
import 'operator_edit_profile_view.dart';
import 'operator_publish_view.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthController>(context, listen: false);
      final notifCtrl = Provider.of<NotificacionController>(context, listen: false);
      if (auth.usuarioActual != null) {
        notifCtrl.listenToNotificaciones(auth.usuarioActual!.id, collectionName: 'operadores');
      }
    });
  }

  void _handleMenuSelected(String menu) {
    if (menu == 'Publicar') {
      setState(() {
        _activeMenu = menu;
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OperatorPublishView()),
      ).then((_) {
        setState(() {
          _refreshKey++;
        });
      });
    } else if (menu == 'Solicitudes') {
      _mostrarMensaje('Solicitudes - Próximamente');
    } else if (menu == 'Inicio') {
      setState(() {
        _activeMenu = menu;
      });
    }
  }

  void _handleEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OperatorEditProfileView()),
    );
  }

  void _handleLogout() {
    _mostrarDialogoCerrarSesion();
  }

  void _mostrarDialogoCerrarSesion() {
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
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
        );
      }
    });
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFFC6707),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _eliminarPublicacion(String id, String nombre) async {
    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: 'Eliminar publicación',
      message: '¿Estás seguro de que deseas eliminar "$nombre"? Esta acción no se puede deshacer.',
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
        setState(() {
          _refreshKey++;
        });
      } catch (e) {
        _mostrarMensaje('Error al eliminar');
      }
    }
  }

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
              child: const Icon(Icons.help_outline, color: Colors.white),
            )
          : null,
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
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFC6707), width: 2),
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFFFDDBB3),
                      child: Icon(Icons.person, color: Color(0xFFFC6707), size: 28),
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
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
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
              _mostrarMensaje('Solicitudes - Próximamente');
            }),
            const Spacer(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            _buildDrawerItem('Cerrar Sesión', Icons.logout_outlined, () {
              Navigator.pop(context);
              _handleLogout();
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    final isActive = title == _activeMenu;
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

  Widget _buildMobileLayout(String empresa, String operadorId) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                                children: [
                                  const TextSpan(text: '¡Hola '),
                                  TextSpan(text: empresa, style: const TextStyle(color: Color(0xFFFC6707))),
                                  const TextSpan(text: '! Revise el estado de sus servicios'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildMainContent(isMobile: true, operadorId: operadorId),
                    const SizedBox(height: 30),
                  ],
                ),
                _buildFooter(true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(String empresa, String operadorId) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                                      children: [
                                        const TextSpan(text: '¡Hola '),
                                        TextSpan(text: empresa, style: const TextStyle(color: Color(0xFFFC6707))),
                                        const TextSpan(text: '! Revise el estado de sus servicios'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildMainContent(isMobile: false, operadorId: operadorId),
                          const SizedBox(height: 30),
                        ],
                      ),
                      _buildFooter(false),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 320,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 260,
                          child: const NotificationsPanel(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 260,
                          child: _buildTrendingChart(),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainContent({required bool isMobile, required String operadorId}) {
    final crossAxisCount = isMobile ? 2 : 3;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
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
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFC6707)));
            }

            if (snapshot.hasError) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFF44336)),
                      const SizedBox(height: 12),
                      Text(
                        'Error al cargar las publicaciones',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final destinos = snapshot.data?.docs ?? [];
            
            if (destinos.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFCCCCCC)),
                        SizedBox(height: 12),
                        Text(
                          'No tienes publicaciones aún',
                          style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Presiona "Publicar" para crear tu primer paquete turístico',
                          style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                    onDelete: () {
                      _eliminarPublicacion(doc.id, data['nombre'] ?? 'este destino');
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrendingChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
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