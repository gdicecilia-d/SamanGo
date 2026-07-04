import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'admin_reports_view.dart';

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
// Widgets reutilizables de esta vista
// ===========================================================================

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
      decoration: AdminPalette.card(radius: 14),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AdminPalette.primaryLight),
            child: Center(
              child: Text(inicial,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AdminPalette.primaryDark)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombreCompleto.isEmpty ? 'Sin nombre' : nombreCompleto,
                    style: GoogleFonts.outfit(
                        fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w600, color: AdminPalette.ink)),
                Text(correo, style: GoogleFonts.outfit(fontSize: isMobile ? 11 : 12, color: AdminPalette.slate)),
                Text('Carnet: $carnet',
                    style: GoogleFonts.outfit(fontSize: isMobile ? 11 : 12, color: AdminPalette.mist)),
              ],
            ),
          ),
          AdminStatusBadge(
            label: activo ? 'Activo' : 'Inhabilitado',
            color: activo ? AdminPalette.success : AdminPalette.danger,
            icon: activo ? Icons.check_circle_outline : Icons.block,
          ),
          const SizedBox(width: 8),
          _buildMenuButton(),
        ],
      ),
    );
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: AdminPalette.slate, size: isMobile ? 20 : 24),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      onSelected: onAction,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: AdminPalette.primary, size: 18),
              const SizedBox(width: 8),
              Text('Inhabilitar/Activar cuenta', style: GoogleFonts.outfit(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, color: AdminPalette.danger, size: 18),
              const SizedBox(width: 8),
              Text('Eliminar cuenta', style: GoogleFonts.outfit(fontSize: 13, color: AdminPalette.danger)),
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

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje, style: GoogleFonts.outfit()),
      backgroundColor: AdminPalette.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          Positioned(top: isMobile ? 130 : 100, right: 16, child: AdminBackButton(onTap: _volver)),
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

  Widget _buildMobileLayout() => _buildLayout(isMobile: true);
  Widget _buildDesktopLayout() => _buildLayout(isMobile: false);

  Widget _buildLayout({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(title: 'Administrar Estudiantes', isMobile: isMobile),
          const SizedBox(height: 16),
          AdminSegmentedTabs(
            labels: _tabs.map((t) => t.label).toList(),
            selectedIndex: _selectedTab,
            onChanged: (index) => setState(() => _selectedTab = index),
            isMobile: isMobile,
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildStudentsList(isMobile)),
        ],
      ),
    );
  }

  Widget _buildStudentsList(bool isMobile) {
    final tab = _tabs[_selectedTab];

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('estudiantes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AdminPalette.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: GoogleFonts.outfit(color: AdminPalette.danger)),
          );
        }

        final estudiantes = (snapshot.data?.docs ?? [])
            .where((doc) => (doc.data()['activo'] as bool? ?? true) == tab.activos)
            .toList();

        if (estudiantes.isEmpty) {
          return AdminEmptyState(icon: tab.emptyIcon, message: tab.emptyMessage);
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