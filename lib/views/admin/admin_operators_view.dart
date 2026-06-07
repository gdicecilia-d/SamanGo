// Pantalla de gestión de operadores (Administrador)
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
import 'operator_card.dart';

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
  int _hoveredTab = -1;

  void _handleMenuSelected(String menu) {
    if (menu == 'Dashboard') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeView()),
      );
    } else if (menu == 'Gestión') {
      _mostrarMensaje('Gestión - Próximamente');
    } else if (menu == 'Reportes') {
      _mostrarMensaje('Reportes - Próximamente');
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
        if (!context.mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

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
            menuItems: _menuItems,
            isMobile: isMobile,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(
            child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
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
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                _buildOperatorsContent(isMobile: true),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        _buildFooter(true),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildHeader(),
                      _buildOperatorsContent(isMobile: false),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              _buildFooter(false),
            ],
          ),
        ),
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
          child: Image.asset(
            'assets/images/campus_admin.png',
            width: 320,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 320,
              color: const Color(0xFFFDDBB3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 48, color: Color(0xFFFC6707)),
                    SizedBox(height: 8),
                    Text('Imagen del Campus'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Administrar Operadores',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUsersView()),
                );
              },
              child: Text(
                'Volver',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFFFC6707),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorsContent({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _buildTab('Pendientes', 0, isMobile),
                _buildTab('Aprobados', 1, isMobile),
                _buildTab('Rechazados', 2, isMobile),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildOperatorsList(isMobile),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index, bool isMobile) {
    final isSelected = _selectedTab == index;
    final isHovered = _hoveredTab == index;
    
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredTab = index),
        onExit: (_) => setState(() => _hoveredTab = -1),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedTab = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFFFC6707) 
                  : (isHovered ? const Color(0xFFFC6707).withOpacity(0.2) : Colors.transparent),
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

  Widget _buildOperatorsList(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('operadores').snapshots(),
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
          return Center(child: Text('Error: \${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        
        String filtroEstado;
        if (_selectedTab == 0) {
          filtroEstado = 'pendiente';
        } else if (_selectedTab == 1) {
          filtroEstado = 'aprobado';
        } else {
          filtroEstado = 'rechazado';
        }

        final operadoresFiltrados = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['estado'] == filtroEstado;
        }).toList();

        if (operadoresFiltrados.isEmpty) {
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
                    _selectedTab == 0 ? Icons.pending_actions : (_selectedTab == 1 ? Icons.check_circle : Icons.cancel),
                    size: 48,
                    color: const Color(0xFFCCCCCC),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay operadores con este estado',
                    style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: operadoresFiltrados.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final doc = operadoresFiltrados[index];
            final data = doc.data() as Map<String, dynamic>;
            final operadorMap = {
              'id': doc.id,
              'nombre': data['nombre'] ?? 'Sin nombre',
              'empresa': data['empresa'] ?? 'Sin empresa',
              'correo': data['correo'] ?? 'Sin correo',
              'telefono': data['telefono'] ?? 'Sin teléfono',
              'rif': data['rif'] ?? 'Sin RIF',
              'descripcion': data['descripcion'] ?? 'Sin descripción',
              'fechaSolicitud': data['fechaNacimiento'] ?? 'N/A',
              'licenciaUrl': data['licenciaUrl'] ?? '',
            };
            
            final operadorObj = Usuario.fromMap(doc.id, data);

            return OperatorCard(
              operadorMap: operadorMap,
              operadorObj: operadorObj,
              selectedTab: _selectedTab,
              isMobile: isMobile,
              onMessage: _mostrarMensaje,
            );
          },
        );
      },
    );
  }

  Widget _buildFooter(bool isMobile) {
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
}