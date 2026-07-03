import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'admin_reports_view.dart';

/// Paleta y estilos compartidos del módulo admin.
/// (Repetida en los demás admin_*.dart — candidata a un archivo de tema
/// compartido único cuando terminemos de pulir todas las vistas.)
class _Palette {
  static const primary = Color(0xFFFC6707);
  static const primaryLight = Color(0xFFFDDBB3);
  static const textDark = Color(0xFF333333);
  static const textGrey = Color(0xFF666666);
  static const textLight = Color(0xFF888888);
  static const textFaint = Color(0xFF999999);
  static const border = Color(0xFFE0E0E0);
  static const green = Color(0xFF4CAF50);
  static const red = Color(0xFFF44336);
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

  static final drawerRole = GoogleFonts.outfit(fontSize: 12, color: _Palette.textGrey);

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

/// Definición de cada pestaña: etiqueta, si filtra por activos o no, y
/// los textos/íconos para el estado vacío.
class _StudentTab {
  final String label;
  final bool activos;
  final IconData emptyIcon;
  final String emptyMessage;

  const _StudentTab(this.label, this.activos, this.emptyIcon, this.emptyMessage);
}

// ===========================================================================
// Widgets reutilizables
// ===========================================================================

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

/// Tarjeta con la info de un estudiante y su menú de acciones.
class _StudentCard extends StatelessWidget {
  final String nombreCompleto;
  final String correo;
  final String carnet;
  final bool activo;
  final bool isMobile;
  final ValueChanged<String> onAction;

  const _StudentCard({
    required this.nombreCompleto,
    required this.correo,
    required this.carnet,
    required this.activo,
    required this.isMobile,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final inicial = nombreCompleto.isNotEmpty ? nombreCompleto[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _Palette.primaryLight),
            child: Center(
              child: Text(inicial,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: _Palette.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombreCompleto.isEmpty ? 'Sin nombre' : nombreCompleto,
                    style: GoogleFonts.outfit(
                        fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w600, color: _Palette.textDark)),
                Text(correo, style: GoogleFonts.outfit(fontSize: isMobile ? 11 : 12, color: _Palette.textGrey)),
                Text('Carnet: $carnet',
                    style: GoogleFonts.outfit(fontSize: isMobile ? 11 : 12, color: _Palette.textLight)),
              ],
            ),
          ),
          _StatusBadge(
            label: activo ? 'Activo' : 'Inhabilitado',
            color: activo ? _Palette.green : _Palette.red,
          ),
          const SizedBox(width: 8),
          _buildMenuButton(),
        ],
      ),
    );
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: _Palette.textGrey, size: isMobile ? 20 : 24),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      onSelected: onAction,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(Icons.person_outline, color: _Palette.primary, size: 18),
              SizedBox(width: 8),
              Text('Inhabilitar/Activar cuenta'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: _Palette.red, size: 18),
              SizedBox(width: 8),
              Text('Eliminar cuenta', style: TextStyle(color: _Palette.red)),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Vista principal
// ===========================================================================

class AdminStudentsView extends StatefulWidget {
  const AdminStudentsView({super.key});

  @override
  State<AdminStudentsView> createState() => _AdminStudentsViewState();
}

class _AdminStudentsViewState extends State<AdminStudentsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const String _activeMenu = 'Usuarios';
  int _selectedTab = 0;

  static const List<_StudentTab> _tabs = [
    _StudentTab('Activos', true, Icons.people_outline, 'No hay estudiantes activos'),
    _StudentTab('Inhabilitados', false, Icons.block, 'No hay estudiantes inhabilitados'),
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

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje),
      backgroundColor: _Palette.primary,
      duration: const Duration(seconds: 2),
    ));
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();
  void _volver() => Navigator.pop(context);

  // --- Acciones sobre estudiantes ---

  Future<void> _handleStudentAction(String action, String studentId, String nombre, bool activo) {
    return switch (action) {
      'toggle' => _toggleStudentStatus(studentId, nombre, activo),
      'delete' => _deleteStudent(studentId, nombre),
      _ => Future.value(),
    };
  }

  /// Recibe [activoActual] directamente (ya disponible en la tarjeta) en
  /// vez de volver a consultar Firestore solo para leerlo.
  Future<void> _toggleStudentStatus(String studentId, String nombre, bool activoActual) async {
    final nuevoEstado = !activoActual;
    final accion = nuevoEstado ? 'habilitar' : 'inhabilitar';

    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: '${nuevoEstado ? 'Habilitar' : 'Inhabilitar'} cuenta',
      message: '¿Estás seguro de que deseas $accion la cuenta de "$nombre"?',
      confirmText: 'Confirmar',
      icon: nuevoEstado ? Icons.check_circle : Icons.block,
    );
    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('estudiantes')
          .doc(studentId)
          .update({'activo': nuevoEstado});
      _mostrarMensaje('Cuenta ${nuevoEstado ? 'habilitada' : 'inhabilitada'} correctamente');
      setState(() {});
    } catch (e) {
      _mostrarMensaje('Error al cambiar el estado: $e');
    }
  }

  Future<void> _deleteStudent(String studentId, String nombre) async {
    try {
      final tieneReservasActivas = await _tieneReservasActivas(studentId);
      if (tieneReservasActivas) {
        _mostrarMensaje('No se puede eliminar al estudiante porque tiene reservas activas.');
        return;
      }

      final confirm = await CustomConfirmDialog.show(
        context: context,
        title: 'Eliminar cuenta',
        message: '¿Estás seguro de que deseas eliminar permanentemente la cuenta de "$nombre"?',
        confirmText: 'Eliminar',
        icon: Icons.delete_forever,
      );
      if (confirm != true) return;

      await FirebaseFirestore.instance.collection('estudiantes').doc(studentId).delete();
      _mostrarMensaje('Cuenta eliminada correctamente');
      setState(() {});
    } catch (e) {
      _mostrarMensaje('Error al eliminar la cuenta: $e');
    }
  }

  static const _estadosReservaActiva = ['solicitado', 'aceptado', 'verificandoPago', 'pagado'];

  Future<bool> _tieneReservasActivas(String studentId) async {
    final reservas = await FirebaseFirestore.instance
        .collection('reservas')
        .where('estudianteId', isEqualTo: studentId)
        .get();

    return reservas.docs.any((doc) {
      final estado = doc.data()['estadoActual'] as String? ?? '';
      return _estadosReservaActiva.contains(estado);
    });
  }

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
      body: Stack(
        children: [
          Column(
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
          Positioned(top: isMobile ? 130 : 100, right: 16, child: _buildVolverButton()),
        ],
      ),
    );
  }

  Widget _buildVolverButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _volver,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, color: _Palette.primary, size: 16),
              const SizedBox(width: 4),
              Text('Volver',
                  style: GoogleFonts.outfit(fontSize: 16, color: _Palette.primary, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
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

  Widget _buildMobileLayout() => _buildLayout(isMobile: true);
  Widget _buildDesktopLayout() => _buildLayout(isMobile: false);

  Widget _buildLayout({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Administrar Estudiantes', style: _Styles.title(isMobile)),
          const SizedBox(height: 16),
          _buildTabBar(isMobile),
          const SizedBox(height: 16),
          Expanded(child: _buildStudentsList(isMobile)),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isMobile) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(30)),
      child: Row(children: [for (var i = 0; i < _tabs.length; i++) _buildTab(i, isMobile)]),
    );
  }

  Widget _buildTab(int index, bool isMobile) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
          decoration: BoxDecoration(
            color: isSelected ? _Palette.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              _tabs[index].label,
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 14 : 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : _Palette.textGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsList(bool isMobile) {
    final tab = _tabs[_selectedTab];

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('estudiantes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _Palette.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.outfit(color: Colors.red)));
        }

        final estudiantes = (snapshot.data?.docs ?? [])
            .where((doc) => (doc.data()['activo'] as bool? ?? true) == tab.activos)
            .toList();

        if (estudiantes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tab.emptyIcon, size: 48, color: const Color(0xFFCCCCCC)),
                const SizedBox(height: 12),
                Text(tab.emptyMessage, style: GoogleFonts.outfit(fontSize: 14, color: _Palette.textFaint)),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: estudiantes.length,
          itemBuilder: (context, index) {
            final doc = estudiantes[index];
            final data = doc.data();
            final nombreCompleto = '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}'.trim();
            final activo = data['activo'] as bool? ?? true;

            return _StudentCard(
              nombreCompleto: nombreCompleto,
              correo: data['correo'] as String? ?? 'Sin correo',
              carnet: data['carnet'] as String? ?? 'Sin carnet',
              activo: activo,
              isMobile: isMobile,
              onAction: (action) => _handleStudentAction(action, doc.id, nombreCompleto, activo),
            );
          },
        );
      },
    );
  }
}