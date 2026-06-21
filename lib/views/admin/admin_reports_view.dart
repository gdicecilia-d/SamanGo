// Pantalla de reportes (Administrador)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../shared/app_header.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'admin_home_view.dart';
import 'admin_management_view.dart';
import 'admin_users_view.dart';

class AdminReportsView extends StatefulWidget {
  const AdminReportsView({super.key});

  @override
  State<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends State<AdminReportsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _activeMenu = 'Reportes';
  final List<String> _menuItems = ['Dashboard', 'Gestión', 'Usuarios', 'Reportes'];

  void _handleMenuSelected(String menu) {
    if (menu == 'Dashboard') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeView()),
      );
    } else if (menu == 'Gestión') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminManagementView()),
      );
    } else if (menu == 'Usuarios') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminUsersView()),
      );
    }
  }

  void _handleEditProfile() {}

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
        if (!mounted) return;
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

  void _volver() {
    Navigator.pop(context);
  }

  Future<void> _actualizarEstadoReporte(String reporteId, String nuevoEstado) async {
    try {
      await FirebaseFirestore.instance
          .collection('reportes')
          .doc(reporteId)
          .update({'estado': nuevoEstado});
      
      if (!mounted) return;
      _mostrarMensaje('Estado actualizado a: ${_getEstadoLabel(nuevoEstado)}');
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error al actualizar el estado: $e');
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado) {
      case 'verde': return 'Resuelto';
      case 'amarillo': return 'En revisión';
      case 'rojo': return 'Urgente';
      default: return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'verde': return const Color(0xFF4CAF50);
      case 'amarillo': return const Color(0xFFFF9800);
      case 'rojo': return const Color(0xFFF44336);
      default: return const Color(0xFF888888);
    }
  }

  // ✅ MOSTRAR DETALLE DEL REPORTE EN UN DIÁLOGO
  void _mostrarDetalleReporte(Map<String, dynamic> data) {
    final mensaje = data['mensaje'] ?? 'Sin mensaje adicional';
    final comentarios = data['comentarios'] ?? '';
    final calificacion = data['calificacion'] ?? 0;
    final correo = data['correo'] ?? 'No disponible';
    final fecha = data['fecha'] != null 
        ? (data['fecha'] as Timestamp).toDate()
        : DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.report_problem,
              color: const Color(0xFFFC6707),
            ),
            const SizedBox(width: 10),
            Text(
              'Detalle del Reporte',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleRow('Estudiante:', data['estudiante'] ?? 'Sin nombre'),
              const SizedBox(height: 8),
              _buildDetalleRow('Correo:', correo),
              const SizedBox(height: 8),
              _buildDetalleRow('Tour:', data['tour'] ?? 'Sin tour'),
              const SizedBox(height: 8),
              _buildDetalleRow('Tipo:', data['tipo_alerta'] ?? 'Sin tipo'),
              const SizedBox(height: 8),
              _buildDetalleRow('Calificación:', '$calificacion ⭐'),
              const SizedBox(height: 8),
              _buildDetalleRow('Fecha:', '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}'),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '📝 Mensaje del estudiante:',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mensaje,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              if (comentarios.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '💬 Comentarios adicionales:',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    comentarios,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFC6707),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF666666),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

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
                menuItems: _menuItems,
                isMobile: isMobile,
                onMenuTap: isMobile ? _openDrawer : null,
              ),
              Expanded(
                child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
              ),
            ],
          ),
          Positioned(
            top: isMobile ? 80 : 100,
            right: 24,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _volver,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, color: const Color(0xFFFC6707), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Volver',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: const Color(0xFFFC6707),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFC6707), width: 2),
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFFFDDBB3),
                      child: Icon(Icons.admin_panel_settings, color: Color(0xFFFC6707), size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nombre ?? 'Administrador',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                        ),
                        Text(
                          'Administrador',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            _buildDrawerItem('Dashboard', Icons.dashboard_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Dashboard');
            }),
            _buildDrawerItem('Gestión', Icons.settings_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Gestión');
            }),
            _buildDrawerItem('Usuarios', Icons.people_outline, () {
              Navigator.pop(context);
              _handleMenuSelected('Usuarios');
            }),
            _buildDrawerItem('Reportes', Icons.bar_chart_outlined, () {
              Navigator.pop(context);
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
    final isActive = title == _activeMenu;
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

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildContent(isMobile: true),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: _buildContent(isMobile: false),
    );
  }

  Widget _buildContent({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Bandeja de Reportes',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 24),
        _buildReportsList(isMobile),
      ],
    );
  }

  Widget _buildReportsList(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reportes')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Color(0xFFFC6707)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: const Color(0xFFCCCCCC),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay reportes registrados en este momento',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: isMobile ? 12 : 20,
              horizontalMargin: isMobile ? 12 : 16,
              columns: [
                DataColumn(
                  label: Text(
                    'ID',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Estudiante',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Tour',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Tipo de Alerta',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Estado',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Acción',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
              ],
              rows: docs.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final doc = entry.value;
                final data = doc.data() as Map<String, dynamic>;
                
                final estudiante = data['estudiante'] ?? 'Sin nombre';
                final tour = data['tour'] ?? 'Sin tour';
                final tipoAlerta = data['tipo_alerta'] ?? 'Sin tipo';
                final estado = data['estado'] ?? 'amarillo';
                final mensaje = data['mensaje'] ?? '';

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '$index',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ),
                    DataCell(
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _mostrarDetalleReporte(data),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: const Color(0xFFFC6707),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                estudiante,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF333333),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        tour,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getEstadoColor(estado).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tipoAlerta,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getEstadoColor(estado),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getEstadoColor(estado),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getEstadoLabel(estado),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getEstadoColor(estado),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      DropdownButton<String>(
                        value: estado,
                        items: const [
                          DropdownMenuItem(value: 'verde', child: Text('Resuelto')),
                          DropdownMenuItem(value: 'amarillo', child: Text('En revisión')),
                          DropdownMenuItem(value: 'rojo', child: Text('Urgente')),
                        ],
                        onChanged: (nuevoEstado) {
                          if (nuevoEstado != null && nuevoEstado != estado) {
                            _actualizarEstadoReporte(doc.id, nuevoEstado);
                          }
                        },
                        underline: const SizedBox(),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: _getEstadoColor(estado),
                        ),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: _getEstadoColor(estado),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}