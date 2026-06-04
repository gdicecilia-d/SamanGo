// Pantalla de editar perfil del estudiante
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/student_header.dart';
import '../../widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'student_home_view.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _carreraController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFFC6707),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _guardarCambios() async {
    final confirmar = await CustomConfirmDialog.show(
      context: context,
      title: 'Confirmar cambios',
      message: '¿Estás seguro de que deseas guardar los cambios?',
      confirmText: 'Guardar',
    );

    if (confirmar == true) {
      _mostrarMensaje('Perfil actualizado correctamente');
      Navigator.pop(context);
    }
  }

  void _handleCerrarSesion() {
    CustomConfirmDialog.show(
      context: context,
      title: 'Cerrar Sesión',
      message: '¿Estás seguro de que deseas cerrar sesión?',
      confirmText: 'Salir',
      icon: Icons.logout,
    ).then((confirm) {
      if (confirm == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      }
    });
  }

  void _handleMenuSelected(String menu, BuildContext context) {
    if (menu == 'Inicio') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomeView()),
      );
    } else if (menu == 'Mis Viajes') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mis Viajes - Próximamente'), backgroundColor: Color(0xFFFC6707)),
      );
    } else if (menu == 'Favoritos') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favoritos - Próximamente'), backgroundColor: Color(0xFFFC6707)),
      );
    } else if (menu == 'Notificaciones') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificaciones - Próximamente'), backgroundColor: Color(0xFFFC6707)),
      );
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Widget _buildDrawer(BuildContext context) {
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
                      child: Icon(Icons.person, color: Color(0xFFFC6707), size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Estudiante',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFFFC6707), size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            _buildDrawerItem('Inicio', Icons.home_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Inicio', context);
            }),
            _buildDrawerItem('Mis Viajes', Icons.airplane_ticket_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Mis Viajes', context);
            }),
            _buildDrawerItem('Favoritos', Icons.favorite_border, () {
              Navigator.pop(context);
              _handleMenuSelected('Favoritos', context);
            }),
            _buildDrawerItem('Notificaciones', Icons.notifications_none_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Notificaciones', context);
            }),
            const Spacer(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            _buildDrawerItem('Cerrar Sesión', Icons.logout_outlined, () {
              Navigator.pop(context);
              CustomConfirmDialog.show(
                context: context,
                title: 'Cerrar Sesión',
                message: '¿Estás seguro de que deseas cerrar sesión?',
                confirmText: 'Salir',
                icon: Icons.logout,
              ).then((confirm) {
                if (confirm == true) {
                  _handleCerrarSesion();
                }
              });
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFC6707)),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF333333)),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer(context) : null,
      body: Column(
        children: [
          UserHeader(
            activeMenu: 'Perfil',
            onMenuSelected: (menu) => _handleMenuSelected(menu, context),
            onEditProfile: () {},
            onLogout: _handleCerrarSesion,
            menuItems: const ['Inicio', 'Mis Viajes', 'Favoritos'],
            isMobile: isMobile,
            onNotificationsTap: null,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
              child: Center(
                child: Container(
                  width: isMobile ? double.infinity : 900,
                  padding: EdgeInsets.all(isMobile ? (isLandscape ? 16 : 20) : 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editar Perfil',
                        style: GoogleFonts.outfit(
                          fontSize: isMobile ? 22 : 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (isMobile)
                        Column(
                          children: [
                            _buildAvatarSection(),
                            const SizedBox(height: 24),
                            _buildFormSection(),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAvatarSection(),
                            const SizedBox(width: 48),
                            Expanded(child: _buildFormSection()),
                          ],
                        ),
                      const SizedBox(height: 32),
                      const Divider(color: Color(0xFFE0E0E0)),
                      const SizedBox(height: 24),
                      _buildButtonsSection(),
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

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFC6707), width: 3),
          ),
          child: const CircleAvatar(
            backgroundColor: Color(0xFFFDDBB3),
            radius: 50,
            child: Icon(Icons.person, color: Color(0xFFFC6707), size: 50),
          ),
        ),
        const SizedBox(height: 12),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              _mostrarMensaje('Próximamente: subida de foto');
            },
            child: Text(
              'Actualizar foto',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFFC6707),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDisabledField('Nombres')),
            const SizedBox(width: 16),
            Expanded(child: _buildDisabledField('Apellidos')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDisabledField('Fecha de Nacimiento')),
            const SizedBox(width: 16),
            Expanded(child: _buildDisabledField('Carnet')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildEditableField('Correo Unimet', _emailController)),
            const SizedBox(width: 16),
            Expanded(child: _buildEditableField('Carrera', _carreraController)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildEditableField('Número de Teléfono', _telefonoController)),
            const SizedBox(width: 16),
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }

  Widget _buildButtonsSection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        SizedBox(
          width: 140,
          child: ElevatedButton(
            onPressed: _guardarCambios,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC6707),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text('Actualizar', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
        SizedBox(
          width: 140,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDDBB3),
              foregroundColor: const Color(0xFFFC6707),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: Text('Descartar', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF666666))),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: Text('---', style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999))),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF666666))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Ingrese $label',
            hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}