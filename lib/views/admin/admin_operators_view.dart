import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/usuario.dart';
import '../../controllers/auth_controller.dart';
import '../shared/app_header.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'admin_home_view.dart';
import 'admin_users_view.dart';
import 'admin_management_view.dart';
import 'admin_reports_view.dart';
import 'admin_edit_profile_view.dart';
import 'dart:convert';

class AdminOperatorsView extends StatefulWidget {
  const AdminOperatorsView({super.key});

  @override
  State<AdminOperatorsView> createState() => _AdminOperatorsViewState();
}

class _AdminOperatorsViewState extends State<AdminOperatorsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _activeMenu = 'Usuarios';
  final List<String> _menuItems = ['Dashboard', 'Gestión', 'Usuarios', 'Reportes'];
  int _selectedTab = 0;

  void _handleMenuSelected(String menu) {
    if (menu == 'Dashboard') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeView()),
      );
    } else if (menu == 'Gestión') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminManagementView()),
      );
    } else if (menu == 'Reportes') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminReportsView()),
      );
    }
  }

  void _handleEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminEditProfileView()),
    );
  }

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

  Future<void> _toggleOperatorStatus(Usuario operador, String nombre) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('operadores')
          .doc(operador.id)
          .get();
      
      if (!doc.exists) return;
      
      final data = doc.data() as Map<String, dynamic>;
      final activo = data['activo'] as bool? ?? true;
      final nuevoEstado = !activo;
      
      final actionText = nuevoEstado ? 'habilitar' : 'inhabilitar';
      
      final confirm = await CustomConfirmDialog.show(
        context: context,
        title: '${nuevoEstado ? 'Habilitar' : 'Inhabilitar'} operador',
        message: '¿Estás seguro de que deseas $actionText al operador "$nombre"?',
        confirmText: 'Confirmar',
        icon: nuevoEstado ? Icons.check_circle : Icons.block,
      );
      
      if (confirm == true) {
        await FirebaseFirestore.instance
            .collection('operadores')
            .doc(operador.id)
            .update({'activo': nuevoEstado});
        
        if (!mounted) return;
        _mostrarMensaje('Operador ${nuevoEstado ? 'habilitado' : 'inhabilitado'} correctamente');
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error al cambiar el estado: $e');
    }
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
            top: isMobile ? 130 : 100,
            right: 16,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _volver,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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
                  GestureDetector(
                    onTap: _handleEditProfile,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFC6707), width: 2),
                      ),
                      child: ClipOval(
                        child: user?.fotoBase64 != null && user!.fotoBase64!.isNotEmpty
                            ? Image.memory(
                                base64Decode(user.fotoBase64!),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const CircleAvatar(
                                backgroundColor: Color(0xFFFDDBB3),
                                child: Icon(Icons.admin_panel_settings, color: Color(0xFFFC6707), size: 28),
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Administrar Operadores',
            style: GoogleFonts.outfit(
              fontSize: 24,
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
                _buildTab('Pendientes', 0, true),
                _buildTab('Aprobados', 1, true),
                _buildTab('Rechazados', 2, true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildOperatorsList(true),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Administrar Operadores',
            style: GoogleFonts.outfit(
              fontSize: 28,
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
                _buildTab('Pendientes', 0, false),
                _buildTab('Aprobados', 1, false),
                _buildTab('Rechazados', 2, false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildOperatorsList(false),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index, bool isMobile) {
    final isSelected = _selectedTab == index;
    
    return Expanded(
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
                fontSize: isMobile ? 12 : 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF666666),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorsList(bool isMobile) {
    String filtroEstado;
    if (_selectedTab == 0) {
      filtroEstado = 'pendiente';
    } else if (_selectedTab == 1) {
      filtroEstado = 'aprobado';
    } else {
      filtroEstado = 'rechazado';
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('operadores').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFC6707)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.outfit(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        
        final operadoresFiltrados = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['estado'] == filtroEstado;
        }).toList();

        if (operadoresFiltrados.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedTab == 0 ? Icons.pending_actions : (_selectedTab == 1 ? Icons.check_circle : Icons.cancel),
                  size: 48,
                  color: const Color(0xFFCCCCCC),
                ),
                const SizedBox(height: 12),
                Text(
                  'No hay operadores con este estado',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: operadoresFiltrados.length,
          itemBuilder: (context, index) {
            final doc = operadoresFiltrados[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final operadorObj = Usuario.fromMap(doc.id, data);
            final nombre = data['nombre'] ?? 'Sin nombre';
            final empresa = data['empresa'] ?? 'Sin empresa';
            final bool activo = data['activo'] as bool? ?? true;

            return _buildOperatorCard(
              operadorObj: operadorObj,
              data: data,
              nombre: nombre,
              empresa: empresa,
              activo: activo,
              isMobile: isMobile,
            );
          },
        );
      },
    );
  }

  Widget _buildOperatorCard({
    required Usuario operadorObj,
    required Map<String, dynamic> data,
    required String nombre,
    required String empresa,
    required bool activo,
    required bool isMobile,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        title: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFDDBB3),
              ),
              child: Center(
                child: Text(
                  empresa.isNotEmpty ? empresa[0].toUpperCase() : '?',
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
                    empresa,
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  Text(
                    'Representante: $nombre',
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 11 : 12,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  Text(
                    data['correo'] ?? 'Sin correo',
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 11 : 12,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedTab == 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activo ? const Color(0xFF4CAF50).withOpacity(0.1) : const Color(0xFFF44336).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activo ? 'Activo' : 'Inactivo',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: activo ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _toggleOperatorStatus(operadorObj, nombre),
                icon: Icon(
                  activo ? Icons.block : Icons.check_circle,
                  color: activo ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
                  size: 24,
                ),
                tooltip: activo ? 'Inhabilitar' : 'Activar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
            if (_selectedTab == 0) ...[
              IconButton(
                onPressed: () async {
                  final error = await Provider.of<AuthController>(context, listen: false)
                      .approveOperator(operadorObj);
                  if (error != null) {
                    _mostrarMensaje(error);
                  } else {
                    _mostrarMensaje('Operador aprobado correctamente');
                  }
                },
                icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
                tooltip: 'Aprobar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                onPressed: () async {
                  final error = await Provider.of<AuthController>(context, listen: false)
                      .rejectOperator(operadorObj);
                  if (error != null) {
                    _mostrarMensaje(error);
                  } else {
                    _mostrarMensaje('Operador rechazado');
                  }
                },
                icon: const Icon(Icons.cancel, color: Color(0xFFF44336), size: 24),
                tooltip: 'Rechazar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
            if (_selectedTab == 2) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Rechazado',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF44336),
                  ),
                ),
              ),
            ],
          ],
        ),
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _buildInfoRow('Teléfono:', data['telefono'] ?? 'Sin teléfono', isMobile),
          _buildInfoRow('RIF:', data['rif'] ?? 'Sin RIF', isMobile),
          _buildInfoRow('Descripción:', data['descripcion'] ?? 'Sin descripción', isMobile),
          _buildLicenciaRow(data['licenciaUrl'], isMobile),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 80 : 100,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 11 : 12,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenciaRow(String? url, bool isMobile) {
    if (url == null || url.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: isMobile ? 80 : 100,
              child: Text(
                'Licencia:',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF666666),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'No hay documento',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 11 : 12,
                  color: const Color(0xFF999999),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 80 : 100,
            child: Text(
              'Licencia:',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _verLicencia(url, isMobile),
                child: Text(
                  'Ver documento cargado',
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 11 : 12,
                    color: const Color(0xFFFC6707),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _verLicencia(String url, bool isMobile) {
    if (url.isEmpty) {
      _mostrarMensaje('Este operador no tiene licencia cargada.');
      return;
    }
    try {
      if (url.startsWith('data:image')) {
        final base64String = url.split(',').last;
        final bytes = base64Decode(base64String);
        showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: const Text('Licencia de Turismo'),
                  backgroundColor: const Color(0xFFFC6707),
                  foregroundColor: Colors.white,
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    height: isMobile ? 300 : 500,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        _mostrarMensaje('Formato de licencia no soportado o inválido.');
      }
    } catch (e) {
      _mostrarMensaje('Error al abrir la licencia.');
    }
  }
}