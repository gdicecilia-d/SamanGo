// Pantalla principal del estudiante 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/student_header.dart';
import 'widgets/search_bar.dart';
import 'widgets/recommendations.dart';
import 'widgets/categories.dart';
import 'widgets/offers.dart';
import 'widgets/notifications_panel.dart';
import 'widgets/trending_chart.dart';
import '../../widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'edit_profile_view.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class StudentHomeView extends StatefulWidget {
  const StudentHomeView({super.key});

  @override
  State<StudentHomeView> createState() => _StudentHomeViewState();
}

class _StudentHomeViewState extends State<StudentHomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _handleMenuSelected(String menu, BuildContext context) {
    if (menu == 'Mis Viajes') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mis Viajes - Próximamente'), backgroundColor: Color(0xFFFC6707)),
      );
    } else if (menu == 'Favoritos') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favoritos - Próximamente'), backgroundColor: Color(0xFFFC6707)),
      );
    }
  }

  void _handleEditProfile(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileView()));
  }

  void _handleLogout(BuildContext context) async {
    await Provider.of<AuthController>(context, listen: false).logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
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
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer(context) : null,
      body: Column(
        children: [
          UserHeader(
            activeMenu: 'Inicio',
            onMenuSelected: (menu) => _handleMenuSelected(menu, context),
            onEditProfile: () => _handleEditProfile(context),
            onLogout: () => _handleLogout(context),
            menuItems: const ['Inicio', 'Mis Viajes', 'Favoritos'],
            isMobile: isMobile,
            onNotificationsTap: null,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(
            child: isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
          ),
        ],
      ),
      floatingActionButton: isMobile
          ? null
          : FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFFFC6707),
              child: const Icon(Icons.help_outline, color: Colors.white),
            ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
                    child: Consumer<AuthController>(
                      builder: (context, auth, _) {
                        return Text(
                          auth.usuarioActual?.nombre ?? 'Estudiante',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                        );
                      }
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFFFC6707), size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                      _handleEditProfile(context);
                    },
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mis Viajes - Próximamente'), backgroundColor: Color(0xFFFC6707)),
              );
            }),
            _buildDrawerItem('Favoritos', Icons.favorite_border, () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favoritos - Próximamente'), backgroundColor: Color(0xFFFC6707)),
              );
            }),
            _buildDrawerItem('Notificaciones', Icons.notifications_none_outlined, () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificaciones - Próximamente'), backgroundColor: Color(0xFFFC6707)),
              );
            }),
            const Spacer(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            _buildDrawerItem('Cerrar Sesión', Icons.logout_outlined, () {
              Navigator.pop(context);
              CustomConfirmDialog.show(
                context: context,
                title: 'Cerrar Sesión',
                message: '¿Estás seguro de que deseas cerrar sesión?',
                confirmText: 'Salir',
                icon: Icons.logout,
              ).then((confirm) {
                if (confirm == true) {
                  _handleLogout(context);
                }
              });
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

  Widget _buildMobileLayout(BuildContext context) {
    final nombreCompleto = Provider.of<AuthController>(context).usuarioActual?.nombre ?? 'Estudiante';
    final primerNombre = nombreCompleto.split(' ').first;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                children: [
                  const TextSpan(text: '¡Hola '),
                  TextSpan(
                    text: primerNombre,
                    style: const TextStyle(color: Color(0xFFFC6707))
                  ),
                  const TextSpan(text: '! ¿A dónde quieres viajar hoy?'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SearchBarWidget(),
          const SizedBox(height: 24),
          const RecommendationsSection(),
          const SizedBox(height: 32),
          const CategoriesSection(),
          const SizedBox(height: 32),
          const OffersSection(),
          const SizedBox(height: 32),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: const TrendingChart(),
            ),
          ),
          const SizedBox(height: 20),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final nombreCompleto = Provider.of<AuthController>(context).usuarioActual?.nombre ?? 'Estudiante';
    final primerNombre = nombreCompleto.split(' ').first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
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
                        TextSpan(
                          text: primerNombre,
                          style: const TextStyle(color: Color(0xFFFC6707))
                        ),
                        const TextSpan(text: '! ¿A dónde quieres viajar hoy?'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SearchBarWidget(),
                const SizedBox(height: 32),
                const RecommendationsSection(),
                const SizedBox(height: 48),
                const CategoriesSection(),
                const SizedBox(height: 48),
                const OffersSection(),
                const SizedBox(height: 40),
                _buildFooter(context),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80),
                const NotificationsPanel(),
                const SizedBox(height: 24),
                const TrendingChart(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20, horizontal: isMobile ? 16 : 0),
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