import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../shared/app_header.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/favoritos_controller.dart';
import 'widgets/destination_card.dart';
import 'widgets/horizontal_scroll_section.dart';
import 'widgets/student_footer.dart';
import 'destination_detail_view.dart';
import 'edit_profile_view.dart';
import 'student_home_view.dart';
import 'my_trips_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'notifications_view.dart';

class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> _menuItems = ['Inicio', 'Mis Viajes', 'Favoritos'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final favoritosCtrl = Provider.of<FavoritosController>(context, listen: false);
      if (auth.usuarioActual != null) {
        favoritosCtrl.updateUsuario(auth.usuarioActual!.id);
      }
    });
  }

  void _handleMenuSelected(String menu) {
    if (menu == 'Inicio') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomeView()),
        (route) => false,
      );
    } else if (menu == 'Mis Viajes') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyTripsView()),
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer() : null,
      body: Column(
        children: [
          AppHeader(
            activeMenu: 'Favoritos',
            onMenuSelected: _handleMenuSelected,
            onEditProfile: _handleEditProfile,
            onLogout: _handleLogout,
            menuItems: _menuItems,
            isMobile: isMobile,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(
            child: Consumer<FavoritosController>(
              builder: (context, favoritosController, child) {
                final favoritosIds = favoritosController.favoritos;

                if (favoritosIds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: const Color(0xFFCCCCCC),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes destinos favoritos',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF999999),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toca el corazón en cualquier destino para añadirlo aquí',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFFCCCCCC),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('destinos')
                      .where(FieldPath.documentId, whereIn: favoritosIds)
                      .where('activo', isEqualTo: true)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFC6707)),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error al cargar favoritos',
                          style: GoogleFonts.outfit(color: Colors.red),
                        ),
                      );
                    }

                    final destinosFavoritos = snapshot.data?.docs ?? [];

                    if (destinosFavoritos.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 80,
                              color: const Color(0xFFCCCCCC),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay destinos favoritos',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final cards = destinosFavoritos.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final isOffer = _esOferta(data['isOffer']);
                      return DestinationCard(
                        id: doc.id,
                        nombre: data['nombre'] ?? 'Sin título',
                        ubicacion: data['ubicacion'] ?? '',
                        precio: (data['precio'] ?? 0).toDouble(),
                        duracion: data['duracion'] ?? 'Full Day',
                        imagenUrl: data['imagen'] ?? '',
                        isOffer: isOffer,
                        calificacionPromedio: (data['calificacionPromedio'] as num?)?.toDouble() ?? 0.0,
                        totalResenas: (data['totalResenas'] as num?)?.toInt() ?? 0,
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

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                            child: Text(
                              'Mis Favoritos',
                              style: GoogleFonts.outfit(
                                fontSize: isMobile ? 22 : 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          HorizontalScrollSection(
                            title: '',
                            showTitle: false,
                            children: cards,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          StudentFooter(isMobile: isMobile),
        ],
      ),
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDrawerItem('Inicio', Icons.home_outlined, () {
                      Navigator.pop(context);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentHomeView()),
                        (route) => false,
                      );
                    }),
                    _buildDrawerItem('Mis Viajes', Icons.airplane_ticket_outlined, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyTripsView()),
                      );
                    }),
                    _buildDrawerItem('Favoritos', Icons.favorite, () {
                      Navigator.pop(context);
                    }),
                    _buildDrawerItem('Notificaciones', Icons.notifications_outlined, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsView()),
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
    final isActive = title == 'Favoritos';
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
}