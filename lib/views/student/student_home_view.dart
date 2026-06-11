// Home estudiante 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/app_header.dart';
import '../../controllers/auth_controller.dart';
import 'edit_profile_view.dart';
import 'widgets/search_bar.dart';
import 'widgets/categories.dart';
import 'widgets/destination_card.dart';
import 'widgets/horizontal_scroll_section.dart';
import 'destination_detail_view.dart';
import 'favorites_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import '../../controllers/notificacion_controller.dart';
import 'widgets/notifications_panel.dart';

class StudentHomeView extends StatefulWidget {
  const StudentHomeView({super.key});

  @override
  State<StudentHomeView> createState() => _StudentHomeViewState();
}

class _StudentHomeViewState extends State<StudentHomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeMenu = 'Inicio';
  final List<String> _menuItems = ['Inicio', 'Mis Viajes', 'Favoritos'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthController>(context, listen: false);
      final notifCtrl = Provider.of<NotificacionController>(context, listen: false);
      if (auth.usuarioActual != null) {
        notifCtrl.listenToNotificaciones(auth.usuarioActual!.id);
      }
    });
  }

  void _handleMenuSelected(String menu) {
    if (menu == 'Mis Viajes') {
      _mostrarMensaje('Mis Viajes - Próximamente');
    } else if (menu == 'Favoritos') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FavoritesView()),
      );
    }
  }

  void _handleEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileView()),
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

  bool _esOferta(dynamic isOfferValue) {
    if (isOfferValue == null) return false;
    if (isOfferValue is bool) return isOfferValue;
    if (isOfferValue is String) return isOfferValue.toLowerCase() == 'true';
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final auth = Provider.of<AuthController>(context);
    final nombre = auth.usuarioActual?.nombre ?? 'Estudiante';
    final primerNombre = nombre.split(' ').first;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer() : null,
      body: Column(
        children: [
          AppHeader(
            activeMenu: 'Inicio',
            onMenuSelected: _handleMenuSelected,
            onEditProfile: _handleEditProfile,
            onLogout: _handleLogout,
            menuItems: _menuItems,
            isMobile: isMobile,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(
            child: isMobile 
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                              children: [
                                const TextSpan(text: '¡Hola '),
                                TextSpan(text: primerNombre, style: const TextStyle(color: Color(0xFFFC6707))),
                                const TextSpan(text: '! ¿A dónde quieres viajar hoy?'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildMainContent(isMobile: true),
                        _buildFooter(true),
                      ],
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                                      children: [
                                        const TextSpan(text: '¡Hola '),
                                        TextSpan(text: primerNombre, style: const TextStyle(color: Color(0xFFFC6707))),
                                        const TextSpan(text: '! ¿A dónde quieres viajar hoy?'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _buildMainContent(isMobile: false),
                                _buildFooter(false),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 320,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
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
                  ),
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
                          user?.nombre ?? 'Estudiante',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                        ),
                        Text(
                          user?.apellido ?? '',
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
            _buildDrawerItem('Inicio', Icons.home_outlined, () {
              Navigator.pop(context);
            }),
            _buildDrawerItem('Mis Viajes', Icons.airplane_ticket_outlined, () {
              Navigator.pop(context);
              _mostrarMensaje('Mis Viajes - Próximamente');
            }),
            _buildDrawerItem('Favoritos', Icons.favorite_border, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesView()),
              );
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
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFC6707)),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF333333)),
      ),
      onTap: onTap,
    );
  }

  Widget _buildMainContent({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: const SearchBarWidget(),
        ),
        const SizedBox(height: 32),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('destinos')
              .where('activo', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFFC6707))),
              );
            }
            
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }
            
            final todosDestinos = snapshot.data!.docs;
            final destinosNormales = todosDestinos.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return !_esOferta(data['isOffer']);
            }).toList();
            
            final cards = destinosNormales.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DestinationCard(
                id: doc.id,
                nombre: data['nombre'] ?? '',
                ubicacion: data['ubicacion'] ?? '',
                precio: (data['precio'] ?? 0).toDouble(),
                duracion: data['duracion'] ?? 'Full Day',
                imagenUrl: data['imagen'] ?? '',
                isOffer: false,
                cuposDisponibles: data['cuposDisponibles'] ?? 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DestinationDetailView(destinoId: doc.id),
                    ),
                  );
                },
              );
            }).toList();
            
            return HorizontalScrollSection(
              title: 'Destinos Disponibles',
              children: cards,
            );
          },
        ),

        const SizedBox(height: 32),

        const CategoriesSection(),

        const SizedBox(height: 32),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('destinos')
              .where('activo', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0))),
              );
            }
            
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }
            
            final todosDestinos = snapshot.data!.docs;
            final ofertas = todosDestinos.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _esOferta(data['isOffer']);
            }).toList();
            
            final cards = ofertas.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DestinationCard(
                id: doc.id,
                nombre: data['nombre'] ?? '',
                ubicacion: data['ubicacion'] ?? '',
                precio: (data['precio'] ?? 0).toDouble(),
                duracion: data['duracion'] ?? 'Full Day',
                imagenUrl: data['imagen'] ?? '',
                isOffer: true,
                cuposDisponibles: data['cuposDisponibles'] ?? 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DestinationDetailView(destinoId: doc.id),
                    ),
                  );
                },
              );
            }).toList();
            
            return HorizontalScrollSection(
              title: 'Ofertas Especiales',
              children: cards,
            );
          },
        ),
      ],
    );
  }

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
}