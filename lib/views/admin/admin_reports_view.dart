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
import 'admin_users_view.dart';

/// Estado de un reporte: agrupa el valor guardado en Firestore, la
/// etiqueta visible, el color y el ícono, en vez de tener switches
/// paralelos que había que mantener sincronizados a mano.
enum ReporteEstado {
  resuelto('verde', 'Resuelto', AdminPalette.success, Icons.check_circle_outline),
  revision('amarillo', 'En revisión', AdminPalette.warning, Icons.hourglass_top_rounded),
  urgente('rojo', 'Urgente', AdminPalette.danger, Icons.priority_high_rounded);

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const ReporteEstado(this.value, this.label, this.color, this.icon);

  static ReporteEstado fromValue(String? value) {
    return ReporteEstado.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReporteEstado.revision,
    );
  }
}

// ===========================================================================
// Widgets reutilizables de esta vista
// ===========================================================================

/// Fila "label: valor" usada en el diálogo de detalle del reporte.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AdminInfoRow(
      label: label,
      value: Text(value, style: AdminStyles.infoValue(false)),
    );
  }
}

/// Bloque de texto largo con fondo gris (usado para "Mensaje del usuario"
/// y "Comentarios adicionales").
class _NoteBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _NoteBlock({required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: AdminPalette.secondary),
            const SizedBox(width: 6),
            Text(title, style: AdminStyles.cardTitle.copyWith(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AdminPalette.cloud,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminPalette.line),
          ),
          child: Text(content, style: GoogleFonts.outfit(fontSize: 13, color: AdminPalette.ink, height: 1.4)),
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
    final estado = ReporteEstado.fromValue(data['estado'] as String?);
    final fecha = data['fecha'] != null ? (data['fecha'] as Timestamp).toDate() : DateTime.now();
    final fechaTexto =
        '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(gradient: AdminPalette.gradient, shape: BoxShape.circle),
                      child: const Icon(Icons.report_problem_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Detalle del reporte', style: AdminStyles.title(true))),
                    AdminStatusBadge(label: estado.label, color: estado.color, icon: estado.icon),
                  ],
                ),
                const SizedBox(height: 18),
                _DetailRow(label: 'Usuario', value: data['estudiante'] as String? ?? 'Sin nombre'),
                _DetailRow(label: 'Rol', value: rol),
                _DetailRow(label: 'Correo', value: correo),
                if (!esApelacion) _DetailRow(label: 'Tour', value: data['tour'] as String? ?? 'Sin tour'),
                _DetailRow(label: 'Tipo', value: tipoAlerta.isNotEmpty ? tipoAlerta : 'Sin tipo'),
                if (!esApelacion) _DetailRow(label: 'Calificación', value: '${data['calificacion'] ?? 0} ⭐'),
                _DetailRow(label: 'Fecha', value: fechaTexto),
                const SizedBox(height: 10),
                const Divider(color: AdminPalette.line),
                const SizedBox(height: 10),
                _NoteBlock(icon: Icons.chat_bubble_outline, title: 'Mensaje del usuario', content: mensaje),
                if (comentarios.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _NoteBlock(icon: Icons.notes_rounded, title: 'Comentarios adicionales', content: comentarios),
                ],
                const SizedBox(height: 22),
                Center(
                  child: SizedBox(
                    width: 130,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminPalette.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: Text('Cerrar', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  static final List<AdminMenuEntry> _menu = [
    AdminMenuEntry('Dashboard', Icons.dashboard_outlined, (_) => const AdminHomeView(), true),
    AdminMenuEntry('Gestión', Icons.settings_outlined, (_) => const AdminManagementView()),
    AdminMenuEntry('Usuarios', Icons.people_outline, (_) => const AdminUsersView()),
    const AdminMenuEntry(_activeMenu, Icons.bar_chart_outlined), // vista actual
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
      content: Text(mensaje, style: GoogleFonts.outfit()),
      backgroundColor: AdminPalette.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      final doc = await FirebaseFirestore.instance.collection(coleccion).doc(userId).get();
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
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(isMobile),
                  const SizedBox(height: 18),
                  Expanded(child: _buildReportsStream(isMobile)),
                ],
              ),
            ),
          ),
          AdminFooter(isMobile: isMobile),
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

  Widget _buildHeaderRow(bool isMobile) {
    return AdminSectionHeader(
      title: 'Bandeja de Reportes',
      isMobile: isMobile,
      trailing: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('reportes').snapshots(),
        builder: (context, snapshot) {
          final total = snapshot.data?.docs.length ?? 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AdminPalette.secondaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox_outlined, size: 14, color: AdminPalette.secondary),
                const SizedBox(width: 6),
                Text('$total reporte${total == 1 ? '' : 's'}',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AdminPalette.secondary)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportsStream(bool isMobile) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('reportes').orderBy('fecha', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AdminPalette.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: GoogleFonts.outfit(color: AdminPalette.danger)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const AdminEmptyState(
            icon: Icons.inbox_outlined,
            message: 'No hay reportes registrados todavía.',
          );
        }

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isMobile ? 520 : 460,
            mainAxisExtent: 172,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (context, index) => _ReportCard(
            doc: docs[index],
            getUserData: _getUserData,
            onOpenDetail: _mostrarDetalleReporte,
            onEstadoChanged: _actualizarEstadoReporte,
          ),
        );
      },
    );
  }
}

/// Tarjeta de un reporte individual: reemplaza la fila de una tabla por
/// un bloque más legible en mobile y desktop, con badge de tipo, estado
/// y un selector rápido para cambiar el estado.
class _ReportCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Future<DocumentSnapshot<Map<String, dynamic>>?> Function(String?) getUserData;
  final ValueChanged<Map<String, dynamic>> onOpenDetail;
  final void Function(String reporteId, ReporteEstado nuevoEstado) onEstadoChanged;

  const _ReportCard({
    required this.doc,
    required this.getUserData,
    required this.onOpenDetail,
    required this.onEstadoChanged,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final tour = data['tour'] as String? ?? 'Sin tour';
    final tipoAlerta = data['tipo_alerta'] as String? ?? 'Sin tipo';
    final estado = ReporteEstado.fromValue(data['estado'] as String?);
    final fallback = data['estudiante'] as String? ?? 'Sin nombre';

    return Container(
      decoration: AdminPalette.card(radius: 16),
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        future: getUserData(data['usuarioId'] as String?),
        builder: (context, snapshot) {
          var nombre = fallback;
          var correo = data['correo'] as String? ?? 'No disponible';
          final userData = snapshot.data?.data();
          if (userData != null) {
            final fullName = '${userData['nombre'] ?? ''} ${userData['apellido'] ?? ''}'.trim();
            if (fullName.isNotEmpty) nombre = fullName;
            if (userData.containsKey('correo')) correo = userData['correo'] as String;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => onOpenDetail({...data, 'estudiante': nombre, 'correo': correo}),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(color: AdminPalette.primaryLight, shape: BoxShape.circle),
                              child: const Icon(Icons.person_outline, size: 18, color: AdminPalette.primaryDark),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nombre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AdminStyles.cardTitle.copyWith(
                                          fontSize: 14, decoration: TextDecoration.underline)),
                                  Text(correo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AdminStyles.subtitle.copyWith(fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AdminStatusBadge(label: estado.label, color: estado.color, icon: estado.icon),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.tour_outlined, size: 14, color: AdminPalette.slate),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(tour, maxLines: 1, overflow: TextOverflow.ellipsis, style: AdminStyles.subtitle),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AdminPalette.cloud,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(tipoAlerta,
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AdminPalette.slate)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _EstadoDropdown(
                  estadoActual: estado,
                  onChanged: (nuevoEstado) => onEstadoChanged(doc.id, nuevoEstado),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EstadoDropdown extends StatelessWidget {
  final ReporteEstado estadoActual;
  final ValueChanged<ReporteEstado> onChanged;

  const _EstadoDropdown({required this.estadoActual, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<ReporteEstado>(
        value: estadoActual,
        items: [
          for (final estado in ReporteEstado.values)
            DropdownMenuItem(
              value: estado,
              child: Text(estado.label, style: GoogleFonts.outfit(fontSize: 13)),
            ),
        ],
        onChanged: (nuevoEstado) {
          if (nuevoEstado != null && nuevoEstado != estadoActual) onChanged(nuevoEstado);
        },
        icon: Icon(Icons.arrow_drop_down, color: estadoActual.color, size: 20),
        style: GoogleFonts.outfit(fontSize: 13, color: estadoActual.color, fontWeight: FontWeight.w600),
        elevation: 2,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}