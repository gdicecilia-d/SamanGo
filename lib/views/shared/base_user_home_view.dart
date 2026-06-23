// Base para las pantallas de inicio de usuario (Template Method)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../student/widgets/student_header.dart';
import '../student/widgets/notifications_panel.dart';
import '../student/widgets/trending_chart.dart';
import 'widgets/custom_dialog.dart';
import '../auth/login_view.dart';

// Clase abstracta que define el template
abstract class BaseUserHomeView extends StatefulWidget {
  const BaseUserHomeView({super.key});
}

// Clase State con los métodos abstractos que los hijos deben implementar
abstract class BaseUserHomeViewState<T extends BaseUserHomeView> extends State<T> {
  // Métodos abstractos que cada hijo debe implementar
  String get greetingName;
  String get subtitle;
  List<String> get menuItems;
  Widget buildMainContent(BuildContext context, bool isMobile);
  void onMenuSelected(String menu, BuildContext context);
  void onEditProfile(BuildContext context);
  bool get showHelpButton;

  void _handleLogout(BuildContext context) async {
    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: 'Cerrar Sesión',
      message: '¿Estás seguro de que deseas cerrar sesión?',
      confirmText: 'Salir',
      icon: Icons.logout,
    );
    
    if (confirm == true) {
      await Provider.of<AuthController>(context, listen: false).logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
    }
  }

  void _openDrawer() {
    final scaffoldState = Scaffold.of(context);
    if (!scaffoldState.isEndDrawerOpen) {
      scaffoldState.openEndDrawer();
    }
  }

  Widget _buildDrawer(BuildContext context) {
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
                          user?.nombre ?? 'Usuario',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                        ),
                        Text(
                          user?.correo ?? '',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFFFC6707), size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                      onEditProfile(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            _buildDrawerItem('Inicio', Icons.home_outlined, () {
              Navigator.pop(context);
              onMenuSelected('Inicio', context);
            }),
            ...menuItems.skip(1).map((item) => _buildDrawerItem(item, _getIconForMenu(item), () {
              Navigator.pop(context);
              onMenuSelected(item, context);
            })),
            const Spacer(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            _buildDrawerItem('Cerrar Sesión', Icons.logout_outlined, () {
              Navigator.pop(context);
              _handleLogout(context);
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  IconData _getIconForMenu(String menu) {
    switch (menu) {
      case 'Publicar':
        return Icons.add_box_outlined;
      case 'Solicitudes':
        return Icons.receipt_outlined;
      case 'Mis Viajes':
        return Icons.airplane_ticket_outlined;
      case 'Favoritos':
        return Icons.favorite_border;
      case 'Mis Paquetes':
        return Icons.airplane_ticket_outlined;
      case 'Reservas':
        return Icons.receipt_outlined;
      default:
        return Icons.circle_outlined;
    }
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

  Widget _buildFooter(BuildContext context, bool isMobile) {
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return Scaffold(
      key: GlobalKey<ScaffoldState>(),
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer(context) : null,
      body: Column(
        children: [
          UserHeader(
            activeMenu: 'Inicio',
            onMenuSelected: (menu) => onMenuSelected(menu, context),
            onEditProfile: () => onEditProfile(context),
            onLogout: () => _handleLogout(context),
            menuItems: menuItems,
            isMobile: isMobile,
            onNotificationsTap: null,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(
            child: isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
          ),
        ],
      ),
      floatingActionButton: (showHelpButton && !isMobile)
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFFFC6707),
              child: const Icon(Icons.help_outline, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                    children: [
                      const TextSpan(text: '¡Hola ', style: TextStyle(color: Color(0xFFFC6707))),
                      TextSpan(text: greetingName, style: const TextStyle(color: Color(0xFFFC6707))),
                      const TextSpan(text: '!', style: TextStyle(color: Color(0xFFFC6707))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          buildMainContent(context, true),
          _buildFooter(context, true),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contenido principal
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
                          children: [
                            const TextSpan(text: '¡Hola ', style: TextStyle(color: Color(0xFFFC6707))),
                            TextSpan(text: greetingName, style: const TextStyle(color: Color(0xFFFC6707))),
                            const TextSpan(text: '!', style: TextStyle(color: Color(0xFFFC6707))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                buildMainContent(context, false),
                _buildFooter(context, false),
              ],
            ),
          ),
        ),
        // Panel derecho
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
                      child: const TrendingChart(),
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
  }
}