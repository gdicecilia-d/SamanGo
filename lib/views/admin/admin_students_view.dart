// Pantalla de gestión de estudiantes (Administrador)
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
import 'admin_reports_view.dart';

class AdminStudentsView extends StatefulWidget {
  const AdminStudentsView({super.key});

  @override
  State<AdminStudentsView> createState() => _AdminStudentsViewState();
}

class _AdminStudentsViewState extends State<AdminStudentsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _activeMenu = 'Usuarios';
  final List<String> _menuItems = ['Dashboard', 'Gestión', 'Usuarios', 'Reportes'];
  int _selectedTab = 0; // 0: Activos, 1: Inhabilitados

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
    } else if (menu == 'Reportes') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminReportsView()),
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
            }),
            _buildDrawerItem('Reportes', Icons.bar_chart_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Reportes');
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            child: _buildContent(isMobile: true),
          ),
        ),
      ],
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
          'Administrar Estudiantes',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              _buildTab('Activos', 0, isMobile),
              _buildTab('Inhabilitados', 1, isMobile),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // La lista de estudiantes con scroll
        Expanded(
          child: _buildStudentsList(isMobile),
        ),
      ],
    );
  }

  Widget _buildTab(String title, int index, bool isMobile) {
    final isSelected = _selectedTab == index;
    
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedTab = index;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFC6707) : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsList(bool isMobile) {
    final bool activos = _selectedTab == 0;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('estudiantes')
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
        
        final estudiantesFiltrados = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final activo = data['activo'] as bool? ?? true;
          return activo == activos;
        }).toList();

        if (estudiantesFiltrados.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    activos ? Icons.people_outline : Icons.block,
                    size: 48,
                    color: const Color(0xFFCCCCCC),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    activos ? 'No hay estudiantes activos' : 'No hay estudiantes inhabilitados',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: estudiantesFiltrados.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = estudiantesFiltrados[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final nombre = data['nombre'] ?? 'Sin nombre';
            final apellido = data['apellido'] ?? '';
            final correo = data['correo'] ?? 'Sin correo';
            final carnet = data['carnet'] ?? 'Sin carnet';
            final activo = data['activo'] as bool? ?? true;

            return _buildStudentCard(
              id: doc.id,
              nombre: nombre,
              apellido: apellido,
              correo: correo,
              carnet: carnet,
              activo: activo,
              isMobile: isMobile,
            );
          },
        );
      },
    );
  }

  Widget _buildStudentCard({
    required String id,
    required String nombre,
    required String apellido,
    required String correo,
    required String carnet,
    required bool activo,
    required bool isMobile,
  }) {
    final nombreCompleto = '$nombre $apellido'.trim();

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFDDBB3),
            ),
            child: Center(
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFC6707),
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
                  nombreCompleto.isEmpty ? 'Sin nombre' : nombreCompleto,
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                Text(
                  correo,
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 11 : 12,
                    color: const Color(0xFF666666),
                  ),
                ),
                Text(
                  'Carnet: $carnet',
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 11 : 12,
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: activo ? const Color(0xFF4CAF50).withValues(alpha: 0.1) : const Color(0xFFF44336).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              activo ? 'Activo' : 'Inhabilitado',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: activo ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: const Color(0xFF666666), size: isMobile ? 20 : 24),
            onSelected: (value) => _handleStudentAction(value, id, nombreCompleto),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Color(0xFFFC6707), size: 18),
                    SizedBox(width: 8),
                    Text('Inhabilitar/Activar cuenta'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Eliminar cuenta', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleStudentAction(String action, String studentId, String nombre) async {
    if (action == 'toggle') {
      await _toggleStudentStatus(studentId, nombre);
    } else if (action == 'delete') {
      await _deleteStudent(studentId, nombre);
    }
  }

  Future<void> _toggleStudentStatus(String studentId, String nombre) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('estudiantes')
          .doc(studentId)
          .get();
      
      if (!doc.exists) return;
      
      final data = doc.data() as Map<String, dynamic>;
      final activo = data['activo'] as bool? ?? true;
      final nuevoEstado = !activo;
      
      final actionText = nuevoEstado ? 'habilitar' : 'inhabilitar';
      
      final confirm = await CustomConfirmDialog.show(
        context: context,
        title: '${nuevoEstado ? 'Habilitar' : 'Inhabilitar'} cuenta',
        message: '¿Estás seguro de que deseas $actionText la cuenta de "$nombre"?',
        confirmText: 'Confirmar',
        icon: nuevoEstado ? Icons.check_circle : Icons.block,
      );
      
      if (confirm == true) {
        await FirebaseFirestore.instance
            .collection('estudiantes')
            .doc(studentId)
            .update({'activo': nuevoEstado});
        
        _mostrarMensaje('Cuenta ${nuevoEstado ? 'habilitada' : 'inhabilitada'} correctamente');
        setState(() {});
      }
    } catch (e) {
      _mostrarMensaje('Error al cambiar el estado: $e');
    }
  }

  Future<void> _deleteStudent(String studentId, String nombre) async {
    try {
      final reservas = await FirebaseFirestore.instance
          .collection('reservas')
          .where('estudianteId', isEqualTo: studentId)
          .get();
      
      final estadosActivos = ['solicitado', 'aceptado', 'verificandoPago', 'pagado'];
      final tieneReservasActivas = reservas.docs.any((doc) {
        final estado = doc.data()['estadoActual'] as String? ?? '';
        return estadosActivos.contains(estado);
      });
      
      if (tieneReservasActivas) {
        _mostrarMensaje(
          'No se puede eliminar al estudiante porque tiene reservas activas. '
          'Espere a que finalicen sus viajes.'
        );
        return;
      }
      
      final confirm = await CustomConfirmDialog.show(
        context: context,
        title: 'Eliminar cuenta',
        message: '¿Estás seguro de que deseas eliminar permanentemente la cuenta de "$nombre"? Esta acción no se puede deshacer.',
        confirmText: 'Eliminar',
        icon: Icons.delete_forever,
      );
      
      if (confirm == true) {
        await FirebaseFirestore.instance
            .collection('estudiantes')
            .doc(studentId)
            .delete();
        
        _mostrarMensaje('Cuenta eliminada correctamente');
        setState(() {});
      }
    } catch (e) {
      _mostrarMensaje('Error al eliminar la cuenta: $e');
    }
  }
}