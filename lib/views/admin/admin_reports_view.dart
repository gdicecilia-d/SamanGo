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
import 'admin_users_view.dart';

/// Paleta y estilos compartidos del módulo admin.
/// (Repetida en los otros admin_*.dart — candidata a un archivo de tema
/// compartido único cuando terminemos de pulir todas las vistas.)
class _Palette {
  static const primary = Color(0xFFFC6707);
  static const primaryLight = Color(0xFFFDDBB3);
  static const textDark = Color(0xFF333333);
  static const textGrey = Color(0xFF666666);
  static const textFaint = Color(0xFF999999);
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
  final bool replace;

  const _MenuEntry(this.title, this.icon, [this.viewBuilder, this.replace = false]);
}

/// Estado de un reporte: agrupa el valor guardado en Firestore, la
/// etiqueta visible y el color, en vez de tener dos switches paralelos
/// (uno para el label y otro para el color) que había que mantener
/// sincronizados a mano.
enum ReporteEstado {
  resuelto('verde', 'Resuelto', Color(0xFF4CAF50)),
  revision('amarillo', 'En revisión', Color(0xFFFF9800)),
  urgente('rojo', 'Urgente', Color(0xFFF44336));

  final String value;
  final String label;
  final Color color;

  const ReporteEstado(this.value, this.label, this.color);

  static ReporteEstado fromValue(String? value) {
    return ReporteEstado.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReporteEstado.revision,
    );
  }
}

// ===========================================================================
// Widgets reutilizables
// ===========================================================================

/// Punto de color + etiqueta de texto para un estado de reporte.
class _EstadoBadge extends StatelessWidget {
  final ReporteEstado estado;

  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: estado.color),
        ),
        const SizedBox(width: 8),
        Text(
          estado.label,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: estado.color),
        ),
      ],
    );
  }
}

/// Fila "label: valor" usada en el diálogo de detalle del reporte.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _Palette.textGrey)),
        ),
        Expanded(
          child: Text(value, style: GoogleFonts.outfit(fontSize: 13, color: _Palette.textDark)),
        ),
      ],
    );
  }
}

/// Bloque de texto largo con fondo gris (usado para "Mensaje del usuario"
/// y "Comentarios adicionales").
class _NoteBlock extends StatelessWidget {
  final String emoji;
  final String title;
  final String content;

  const _NoteBlock({required this.emoji, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$emoji $title',
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _Palette.textDark)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
          child: Text(content, style: GoogleFonts.outfit(fontSize: 14, color: _Palette.textDark)),
        ),
      ],
    );
  }
}

/// Diálogo con el detalle completo de un reporte.
class _ReportDetailDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ReportDetailDialog({required this.data});

  @override
  Widget build(BuildContext context) {
    final mensaje = data['mensaje'] as String? ?? 'Sin mensaje adicional';
    final comentarios = data['comentarios'] as String? ?? '';
    final correo = data['correo'] as String? ?? 'No disponible';
    final rol = data['rol'] as String? ?? 'No especificado';
    final tipoAlerta = data['tipo_alerta'] as String? ?? '';
    final esApelacion = tipoAlerta == 'Apelación';
    final fecha =
        data['fecha'] != null ? (data['fecha'] as Timestamp).toDate() : DateTime.now();
    final fechaTexto =
        '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.all(24),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.report_problem, color: _Palette.primary, size: 28),
                const SizedBox(width: 12),
                Text('Detalle del Reporte',
                    style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.bold, color: _Palette.textDark)),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Usuario:', value: data['estudiante'] as String? ?? 'Sin nombre'),
            const SizedBox(height: 8),
            _DetailRow(label: 'Rol:', value: rol),
            const SizedBox(height: 8),
            _DetailRow(label: 'Correo:', value: correo),
            const SizedBox(height: 8),
            if (!esApelacion) ...[
              _DetailRow(label: 'Tour:', value: data['tour'] as String? ?? 'Sin tour'),
              const SizedBox(height: 8),
            ],
            _DetailRow(label: 'Tipo:', value: tipoAlerta.isNotEmpty ? tipoAlerta : 'Sin tipo'),
            const SizedBox(height: 8),
            if (!esApelacion) ...[
              _DetailRow(label: 'Calificación:', value: '${data['calificacion'] ?? 0} ⭐'),
              const SizedBox(height: 8),
            ],
            _DetailRow(label: 'Fecha:', value: fechaTexto),
            const SizedBox(height: 12),
            const Divider(color: _Palette.border),
            const SizedBox(height: 8),
            _NoteBlock(emoji: '📝', title: 'Mensaje del usuario:', content: mensaje),
            if (comentarios.isNotEmpty) ...[
              const SizedBox(height: 12),
              _NoteBlock(emoji: '💬', title: 'Comentarios adicionales:', content: comentarios),
            ],
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Palette.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text('Cerrar', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Vista principal
// ===========================================================================

class AdminReportsView extends StatefulWidget {
  const AdminReportsView({super.key});

  @override
  State<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends State<AdminReportsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const String _activeMenu = 'Reportes';

  static final List<_MenuEntry> _menu = [
    _MenuEntry('Dashboard', Icons.dashboard_outlined, (_) => const AdminHomeView(), true),
    _MenuEntry('Gestión', Icons.settings_outlined, (_) => const AdminManagementView()),
    _MenuEntry('Usuarios', Icons.people_outline, (_) => const AdminUsersView()),
    const _MenuEntry(_activeMenu, Icons.bar_chart_outlined), // vista actual
  ];

  // --- Navegación y acciones comunes ---

  void _handleMenuSelected(String menuTitle) {
    final entry = _menu.firstWhere((e) => e.title == menuTitle);
    final builder = entry.viewBuilder;
    if (builder == null) return; // ya estamos en esta vista

    if (entry.replace) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: builder));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: builder));
    }
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

  // --- Datos de reportes ---

  Future<void> _actualizarEstadoReporte(String reporteId, ReporteEstado nuevoEstado) async {
    try {
      await FirebaseFirestore.instance
          .collection('reportes')
          .doc(reporteId)
          .update({'estado': nuevoEstado.value});
      if (!mounted) return;
      _mostrarMensaje('Estado actualizado a: ${nuevoEstado.label}');
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error al actualizar el estado: $e');
    }
  }

  /// Busca el usuario que generó el reporte en las 3 colecciones posibles.
  Future<DocumentSnapshot<Map<String, dynamic>>?> _getUserData(String? userId) async {
    if (userId == null || userId.isEmpty) return null;

    for (final coleccion in ['estudiantes', 'operadores', 'administradores']) {
      final doc =
          await FirebaseFirestore.instance.collection(coleccion).doc(userId).get();
      if (doc.exists) return doc;
    }
    return null;
  }

  void _mostrarDetalleReporte(Map<String, dynamic> data) {
    showDialog(context: context, builder: (_) => _ReportDetailDialog(data: data));
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

  Widget _buildMobileLayout() => _buildLayout(isMobile: true);
  Widget _buildDesktopLayout() => _buildLayout(isMobile: false);

  Widget _buildLayout({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bandeja de Reportes', style: _Styles.title(isMobile)),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildReportsList(isMobile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(bool isMobile) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('reportes').orderBy('fecha', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: _Palette.primary),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.outfit(color: Colors.red)));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_outlined, size: 64, color: Color(0xFFCCCCCC)),
                const SizedBox(height: 16),
                Text('No hay reportes registrados',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: _Palette.textFaint)),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Palette.border, width: 1),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: isMobile ? 12 : 20,
              horizontalMargin: isMobile ? 12 : 16,
              headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F5F5)),
              dividerThickness: 1,
              columns: const [
                DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Usuario', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Tour', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Acción', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: docs.asMap().entries.map((entry) => _buildRow(entry.key + 1, entry.value)).toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildRow(int index, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final estudiante = data['estudiante'] as String? ?? 'Sin nombre';
    final tour = data['tour'] as String? ?? 'Sin tour';
    final tipoAlerta = data['tipo_alerta'] as String? ?? 'Sin tipo';
    final estado = ReporteEstado.fromValue(data['estado'] as String?);

    return DataRow(
      cells: [
        DataCell(Text('$index', style: GoogleFonts.outfit(color: _Palette.textGrey))),
        DataCell(_buildUsuarioCell(data, estudiante)),
        DataCell(Text(tour, style: GoogleFonts.outfit(color: _Palette.textGrey))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: estado.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(tipoAlerta,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: estado.color)),
          ),
        ),
        DataCell(_EstadoBadge(estado: estado)),
        DataCell(_buildEstadoDropdown(doc.id, estado)),
      ],
    );
  }

  /// Celda "Usuario": busca el nombre/correo real del usuario que generó
  /// el reporte y abre el detalle al tocarla.
  Widget _buildUsuarioCell(Map<String, dynamic> data, String estudianteFallback) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      future: _getUserData(data['usuarioId'] as String?),
      builder: (context, snapshot) {
        var nombre = estudianteFallback;
        var correo = data['correo'] as String? ?? 'No disponible';

        final userData = snapshot.data?.data();
        if (userData != null) {
          final fullName = '${userData['nombre'] ?? ''} ${userData['apellido'] ?? ''}'.trim();
          if (fullName.isNotEmpty) nombre = fullName;
          if (userData.containsKey('correo')) correo = userData['correo'] as String;
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _mostrarDetalleReporte({...data, 'estudiante': nombre, 'correo': correo}),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: _Palette.primary),
                const SizedBox(width: 4),
                Text(
                  nombre,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      color: _Palette.textDark,
                      decoration: TextDecoration.underline),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstadoDropdown(String reporteId, ReporteEstado estadoActual) {
    return DropdownButton<ReporteEstado>(
      value: estadoActual,
      items: [
        for (final estado in ReporteEstado.values)
          DropdownMenuItem(value: estado, child: Text(estado.label)),
      ],
      onChanged: (nuevoEstado) {
        if (nuevoEstado != null && nuevoEstado != estadoActual) {
          _actualizarEstadoReporte(reporteId, nuevoEstado);
        }
      },
      underline: const SizedBox(),
      icon: Icon(Icons.arrow_drop_down, color: estadoActual.color, size: 20),
      style: GoogleFonts.outfit(fontSize: 13, color: estadoActual.color, fontWeight: FontWeight.w500),
      elevation: 0,
      dropdownColor: Colors.white,
      focusColor: Colors.transparent,
    );
  }
}