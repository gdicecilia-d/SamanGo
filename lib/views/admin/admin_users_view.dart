// Pantalla de gestión de usuarios (Administrador)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../auth/login_view.dart';
import 'admin_theme.dart';
import '../shared/app_header.dart';
import '../shared/widgets/custom_dialog.dart';
import 'admin_edit_profile_view.dart';
import 'admin_home_view.dart';
import 'admin_management_view.dart';
import 'admin_operators_view.dart';
import 'admin_reports_view.dart';
import 'admin_students_view.dart';

/// Cada tipo de usuario administrable: título de la tarjeta, ícono,
/// subtítulo, degradado propio y la vista a la que navega al tocarla.
class _UserTypeOption {
  final String title;
  final IconData icon;
  final String subtitle;
  final String stat;
  final IconData statIcon;
  final Gradient gradient;
  final WidgetBuilder viewBuilder;

  const _UserTypeOption({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.stat,
    required this.statIcon,
    required this.gradient,
    required this.viewBuilder,
  });
}

/// Tarjeta grande y clickeable para un tipo de usuario (Estudiantes,
/// Operadores...). Cada una lleva su propio degradado de cabecera con
/// un ícono decorativo de fondo, para que se distingan entre sí de un
/// vistazo en vez de ser dos bloques idénticos con solo el ícono chico
/// cambiando.
class _UserTypeCard extends StatefulWidget {
  final _UserTypeOption option;
  final bool isMobile;

  const _UserTypeCard({required this.option, required this.isMobile});

  @override
  State<_UserTypeCard> createState() => _UserTypeCardState();
}

class _UserTypeCardState extends State<_UserTypeCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final option = widget.option;
    final isMobile = widget.isMobile;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: option.viewBuilder)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AdminPalette.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hover ? 0.10 : 0.05),
                blurRadius: _hover ? 20 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera con degradado propio + ícono decorativo de fondo.
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  height: isMobile ? 100 : 130,
                  decoration: BoxDecoration(gradient: option.gradient),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: -10,
                        top: -18,
                        child: Icon(option.icon, size: isMobile ? 110 : 140, color: Colors.white.withOpacity(0.16)),
                      ),
                      Positioned(
                        left: 20,
                        bottom: -26,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10)],
                          ),
                          child: Icon(option.icon, color: AdminPalette.ink, size: 26),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, isMobile ? 20 : 30, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.title,
                        style: GoogleFonts.outfit(
                            fontSize: isMobile ? 16 : 19, fontWeight: FontWeight.bold, color: AdminPalette.ink)),
                    const SizedBox(height: 4),
                    Text(option.subtitle, style: AdminStyles.subtitle),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(option.statIcon, size: 14, color: AdminPalette.slate),
                            const SizedBox(width: 6),
                            Text(option.stat, style: GoogleFonts.outfit(fontSize: 12, color: AdminPalette.slate)),
                          ],
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: option.gradient,
                            shape: BoxShape.circle,
                            boxShadow: _hover
                                ? [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10)]
                                : null,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Vista principal
// ===========================================================================

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const String _activeMenu = 'Usuarios';

  static const _operatorsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AdminPalette.secondary, Color(0xFF1FA093)],
  );

  static final List<_UserTypeOption> _userTypes = [
    _UserTypeOption(
      title: 'Administrar Estudiantes',
      icon: Icons.school_rounded,
      subtitle: 'Cuentas, estados y accesos de los estudiantes',
      stat: 'Activos e inhabilitados',
      statIcon: Icons.people_alt_outlined,
      gradient: AdminPalette.gradient,
      viewBuilder: (_) => const AdminStudentsView(),
    ),
    _UserTypeOption(
      title: 'Administrar Operadores',
      icon: Icons.business_center_rounded,
      subtitle: 'Tours, disponibilidad y cuentas de operadores',
      stat: 'Verificados y pendientes',
      statIcon: Icons.verified_outlined,
      gradient: _operatorsGradient,
      viewBuilder: (_) => const AdminOperatorsView(),
    ),
  ];

  static final List<AdminMenuEntry> _menu = [
    AdminMenuEntry('Dashboard', Icons.dashboard_outlined, (_) => const AdminHomeView()),
    AdminMenuEntry('Gestión', Icons.settings_outlined, (_) => const AdminManagementView()),
    const AdminMenuEntry(_activeMenu, Icons.people_outline), // vista actual
    AdminMenuEntry('Reportes', Icons.bar_chart_outlined, (_) => const AdminReportsView()),
  ];

  // --- Navegación y acciones comunes ---

  void _handleMenuSelected(String menuTitle) {
    final entry = _menu.firstWhere((e) => e.title == menuTitle);
    final builder = entry.viewBuilder;
    if (builder == null) return; // ya estamos en esta vista
    Navigator.pushReplacement(context, MaterialPageRoute(builder: builder));
  }

  void _handleEditProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEditProfileView()));
  }

  void _handleLogout() {
    CustomConfirmDialog.show(
      context: context,
      title: 'Cerrar Sesión',
      message: '¿Estás seguro de que deseas cerrar sesión?',
      confirmText: 'Salir',
      icon: Icons.logout,
    ).then((confirm) async {
      if (confirm != true) return;
      await Provider.of<AuthController>(context, listen: false).logout();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
    });
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 850;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminPalette.cloud,
      endDrawer: isMobile ? _buildDrawer() : null,
      body: Column(
        children: [
          AppHeader(
            activeMenu: _activeMenu,
            onMenuSelected: _handleMenuSelected,
            onEditProfile: _handleEditProfile,
            onLogout: _handleLogout,
            menuItems: _menu.map((e) => e.title).toList(),
            isMobile: isMobile,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(child: isMobile ? _buildMobileLayout() : _buildDesktopLayout()),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final user = Provider.of<AuthController>(context).usuarioActual;
    return AdminDrawer(
      menu: _menu,
      activeMenu: _activeMenu,
      userName: user?.nombre,
      userFotoBase64: user?.fotoBase64,
      onEditProfile: _handleEditProfile,
      onLogout: _handleLogout,
      onMenuSelected: _handleMenuSelected,
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminSectionHeader(title: 'Administrar Usuarios', isMobile: true),
                  const SizedBox(height: 24),
                  for (var i = 0; i < _userTypes.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _UserTypeCard(option: _userTypes[i], isMobile: true),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        AdminFooter(isMobile: true),
      ],
    );
  }

  /// En desktop se agrega el mismo panel con la imagen del campus que usa
  /// el Dashboard, para que la vista no se sienta "pelada" al lado de las
  /// dos tarjetas grandes, y el mismo footer legal al pie del contenido.
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AdminSectionHeader(title: 'Administrar Usuarios', isMobile: false),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < _userTypes.length; i++) ...[
                                if (i > 0) const SizedBox(width: 24),
                                Expanded(child: _UserTypeCard(option: _userTypes[i], isMobile: false)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                AdminFooter(isMobile: false),
              ],
            ),
          ),
        ),
        const AdminCampusPanel(),
      ],
    );
  }
}