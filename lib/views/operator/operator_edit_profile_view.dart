import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../student/widgets/student_header.dart'; // We can reuse the header
import '../../widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'operator_home_view.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import 'package:image_picker/image_picker.dart';

class OperatorEditProfileView extends StatefulWidget {
  const OperatorEditProfileView({super.key});

  @override
  State<OperatorEditProfileView> createState() => _OperatorEditProfileViewState();
}

class _OperatorEditProfileViewState extends State<OperatorEditProfileView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with current user data if possible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final user = auth.usuarioActual;
      if (user != null) {
        _emailController.text = user.correo;
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

  Future<void> _guardarCambios() async {
    final confirmar = await CustomConfirmDialog.show(
      context: context,
      title: 'Confirmar cambios',
      message: '¿Estás seguro de que deseas guardar los cambios?',
      confirmText: 'Guardar',
    );

    if (confirmar == true) {
      _mostrarMensaje('Perfil de operador actualizado correctamente');
      if (!mounted) return;
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
    ).then((confirm) async {
      if (confirm == true) {
        await Provider.of<AuthController>(context, listen: false).logout();
        if (!mounted) return;
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
        MaterialPageRoute(builder: (_) => const OperatorHomeView()),
      );
    } else if (menu == 'Mis Paquetes') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mis Paquetes - Próximamente'), backgroundColor: Color(0xFFFC6707)),
      );
    } else if (menu == 'Reservas') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservas - Próximamente'), backgroundColor: Color(0xFFFC6707)),
      );
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final auth = Provider.of<AuthController>(context);
    final user = auth.usuarioActual;
    final nombre = user?.nombre ?? 'Operador';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          UserHeader(
            activeMenu: 'Perfil',
            onMenuSelected: (menu) => _handleMenuSelected(menu, context),
            onEditProfile: () {},
            onLogout: _handleCerrarSesion,
            menuItems: const ['Inicio', 'Mis Paquetes', 'Reservas'],
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
                        'Perfil de Operador',
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
                            _buildAvatarSection(user?.id ?? ''),
                            const SizedBox(height: 24),
                            _buildFormSection(nombre),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAvatarSection(user?.id ?? ''),
                            const SizedBox(width: 48),
                            Expanded(child: _buildFormSection(nombre)),
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

  Widget _buildAvatarSection(String userId) {
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
            child: Icon(Icons.business_center, color: Color(0xFFFC6707), size: 50),
          ),
        ),
        const SizedBox(height: 12),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                final ext = image.name.split('.').last.toLowerCase();
                if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
                  final bytes = await image.readAsBytes();
                  final profileController = Provider.of<ProfileController>(context, listen: false);
                  
                  _mostrarMensaje('Subiendo foto...');
                  final success = await profileController.updateProfileImage(userId, bytes, ext);
                  
                  if (success) {
                    _mostrarMensaje('Logo actualizado exitosamente');
                  } else {
                    _mostrarMensaje('Hubo un error al actualizar el logo');
                  }
                } else {
                  _mostrarMensaje('Solo se permiten formatos PNG y JPG/JPEG');
                }
              }
            },
            child: Text(
              'Actualizar logo',
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

  Widget _buildFormSection(String nombre) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDisabledField('Nombre Completo', value: nombre)),
            const SizedBox(width: 16),
            Expanded(child: _buildEditableField('Empresa / Agencia', _empresaController)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDisabledField('Tipo de Usuario', value: 'Operador Turístico')),
            const SizedBox(width: 16),
            Expanded(child: _buildEditableField('Número de Teléfono', _telefonoController)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildEditableField('Correo de Contacto', _emailController)),
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

  Widget _buildDisabledField(String label, {String? value}) {
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
          child: Text(value ?? '---', style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999))),
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
