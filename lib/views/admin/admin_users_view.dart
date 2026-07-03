// Pantalla de gestión de usuarios (Administrador)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../auth/login_view.dart';
import '../shared/app_header.dart';
import '../shared/widgets/custom_dialog.dart';
import 'admin_edit_profile_view.dart';
import 'admin_home_view.dart';
import 'admin_management_view.dart';
import 'admin_operators_view.dart';
import 'admin_reports_view.dart';
import 'admin_students_view.dart';

/// Paleta y estilos compartidos del módulo admin.
/// (Repetida en los demás admin_*.dart — candidata a un archivo de tema
/// compartido único cuando terminemos de pulir todas las vistas.)
class _Palette {
  static const primary = Color(0xFFFC6707);
  static const primaryLight = Color(0xFFFDDBB3);
  static const textDark = Color(0xFF333333);
  static const textGrey = Color(0xFF666666);
  static const textLight = Color(0xFF888888);
  static const border = Color(0xFFE0E0E0);
}

class _Styles {
  static TextStyle title(bool isMobile) => GoogleFonts.outfit(
        fontSize: isMobile ? 24 : 28,
        fontWeight: FontWeight.bold,
        color: _Palette.textDark,
      );

  static final drawerName = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: _Palette.textDark,
  );

  static final drawerRole = GoogleFonts.outfit(fontSize: 14, color: _Palette.textGrey);

  static TextStyle drawerItem(bool isActive) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        color: isActive ? _Palette.primary : _Palette.textDark,
      );
}

class _MenuEntry {
  final String title;
  final IconData icon;
  final WidgetBuilder? viewBuilder;

  const _MenuEntry(this.title, this.icon, [this.viewBuilder]);
}

/// Cada tipo de usuario administrable: título de la tarjeta, ícono,
/// subtítulo y la vista a la que navega al tocarla.
class _UserTypeOption {
  final String title;
  final IconData icon;
  final String subtitle;
  final WidgetBuilder viewBuilder;

  const _UserTypeOption(this.title, this.icon, this.subtitle, this.viewBuilder);
}

/// Tarjeta grande y clickeable para un tipo de usuario (Estudiantes,
/// Operadores...).
class _UserTypeCard extends StatelessWidget {
  final _UserTypeOption option;
  final bool isMobile;

  const _UserTypeCard({required this.option, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: option.viewBuilder)),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _Palette.border, width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: _Palette.primaryLight, shape: BoxShape.circle),
                child: Icon(option.icon, color: _Palette.primary, size: isMobile ? 40 : 56),
              ),
              const SizedBox(height: 16),
              Text(
                option.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w600, color: _Palette.textDark),
              ),
              const SizedBox(height: 8),
              Text(option.subtitle, style: GoogleFonts.outfit(fontSize: isMobile ? 12 : 14, color: _Palette.textLight)),
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

  static final List<_UserTypeOption> _userTypes = [
    _UserTypeOption('Administrar Estudiantes', Icons.school, 'Gestionar estudiantes', (_) => const AdminStudentsView()),
    _UserTypeOption(
        'Administrar Operadores', Icons.business_center, 'Gestionar operadores', (_) => const AdminOperatorsView()),
  ];

  static final List<_MenuEntry> _menu = [
    _MenuEntry('Dashboard', Icons.dashboard_outlined, (_) => const AdminHomeView()),
    _MenuEntry('Gestión', Icons.settings_outlined, (_) => const AdminManagementView()),
    const _MenuEntry(_activeMenu, Icons.people_outline), // vista actual
    _MenuEntry('Reportes', Icons.bar_chart_outlined, (_) => const AdminReportsView()),
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
      backgroundColor: Colors.white,
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
    final tieneFoto = user?.fotoBase64 != null && user!.fotoBase64!.isNotEmpty;

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
                        border: Border.all(color: _Palette.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: tieneFoto
                            ? Image.memory(base64Decode(user!.fotoBase64!),
                                width: 50, height: 50, fit: BoxFit.cover)
                            : const CircleAvatar(
                                backgroundColor: _Palette.primaryLight,
                                child: Icon(Icons.admin_panel_settings, color: _Palette.primary, size: 28),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.nombre ?? 'Administrador', style: _Styles.drawerName),
                        Text('Administrador', style: _Styles.drawerRole),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: _Palette.border),
            for (final entry in _menu)
              _buildDrawerItem(entry.title, entry.icon, () {
                Navigator.pop(context);
                if (entry.title != _activeMenu) _handleMenuSelected(entry.title);
              }),
            const Spacer(),
            const Divider(height: 1, color: _Palette.border),
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
      leading: Icon(icon, color: _Palette.primary),
      title: Text(title, style: _Styles.drawerItem(isActive)),
      onTap: onTap,
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Administrar Usuarios', style: _Styles.title(true)),
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < _userTypes.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _UserTypeCard(option: _userTypes[i], isMobile: true),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Administrar Usuarios', style: _Styles.title(false)),
          const SizedBox(height: 24),
          Row(
            children: [
              for (var i = 0; i < _userTypes.length; i++) ...[
                if (i > 0) const SizedBox(width: 24),
                Expanded(child: _UserTypeCard(option: _userTypes[i], isMobile: false)),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}