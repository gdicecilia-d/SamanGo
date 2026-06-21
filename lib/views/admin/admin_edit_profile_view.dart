// Pantalla de editar perfil del administrador
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/app_header.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../../controllers/auth_controller.dart';
import '../../services/storage_service.dart';
import '../auth/login_view.dart';
import 'admin_home_view.dart';
import 'admin_management_view.dart';
import 'admin_users_view.dart';
import 'admin_reports_view.dart';
import '../../models/usuario.dart';

class AdminEditProfileView extends StatefulWidget {
  const AdminEditProfileView({super.key});

  @override
  State<AdminEditProfileView> createState() => _AdminEditProfileViewState();
}

class _AdminEditProfileViewState extends State<AdminEditProfileView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StorageService _storageService = StorageService();
  
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  
  bool _isHoveringFoto = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final user = auth.usuarioActual;
    if (user != null) {
      setState(() {
        _nombreController.text = user.nombre;
        _correoController.text = user.correo;
      });
    }
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
      setState(() => _isLoading = true);
      
      final auth = Provider.of<AuthController>(context, listen: false);
      final userId = auth.usuarioActual?.id ?? '';
      
      try {
        await FirebaseFirestore.instance.collection('administradores').doc(userId).update({
          'nombre': _nombreController.text,
        });
        
        await auth.reloadUser();
        
        _mostrarMensaje('Perfil actualizado correctamente');
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        _mostrarMensaje('Error al actualizar el perfil');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _actualizarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final ext = image.name.split('.').last.toLowerCase();
      if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
        setState(() => _isLoading = true);
        final bytes = await image.readAsBytes();
        final auth = Provider.of<AuthController>(context, listen: false);
        final userId = auth.usuarioActual?.id ?? '';
        
        final base64Image = _storageService.imageToBase64(bytes);
        final success = await auth.updateProfileImage(userId, base64Image);
        
        if (success) {
          await auth.reloadUser();
          await _cargarDatosUsuario();
          _mostrarMensaje('Foto actualizada exitosamente');
        } else {
          _mostrarMensaje('Error al actualizar la foto');
        }
        setState(() => _isLoading = false);
      } else {
        _mostrarMensaje('Solo se permiten formatos PNG y JPG/JPEG');
      }
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
    } else if (menu == 'Usuarios') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminUsersView()),
      );
    } else if (menu == 'Reportes') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminReportsView()),
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

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isMobile) {
      return _buildMobileLayout(user, isLandscape);
    }

    return _buildDesktopLayout(user);
  }

  Widget _buildMobileLayout(Usuario user, bool isLandscape) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: _buildDrawer(),
      body: Column(
        children: [
          AppHeader(
            activeMenu: 'Perfil',
            onMenuSelected: _handleMenuSelected,
            onEditProfile: () {},
            onLogout: _handleCerrarSesion,
            menuItems: const ['Dashboard', 'Gestión', 'Usuarios', 'Reportes'],
            isMobile: true,
            onMenuTap: _openDrawer,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  _buildAvatarSectionMobile(user),
                  const SizedBox(height: 24),
                  _buildFormSectionMobile(user),
                  const SizedBox(height: 32),
                  _buildButtonsSectionMobile(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSectionMobile(Usuario user) {
    return Column(
      children: [
        GestureDetector(
          onTap: _actualizarFoto,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFC6707), width: 3),
            ),
            child: ClipOval(
              child: user.fotoBase64 != null && user.fotoBase64!.isNotEmpty
                  ? Image.memory(
                      base64Decode(user.fotoBase64!),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : Container(
                      color: const Color(0xFFFDDBB3),
                      child: const Icon(Icons.admin_panel_settings, color: Color(0xFFFC6707), size: 50),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHoveringFoto = true),
          onExit: (_) => setState(() => _isHoveringFoto = false),
          child: GestureDetector(
            onTap: _actualizarFoto,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _isHoveringFoto ? const Color(0xFFFC6707).withOpacity(0.1) : Colors.transparent,
              ),
              child: Text(
                'Actualizar foto',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFFC6707),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSectionMobile(Usuario user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        children: [
          _buildDisabledFieldMobile('Nombre Completo', value: user.nombre),
          const SizedBox(height: 16),
          _buildDisabledFieldMobile('Rol', value: 'Administrador'),
          const SizedBox(height: 16),
          _buildDisabledFieldMobile('Correo Electrónico', value: user.correo),
          const SizedBox(height: 16),
          _buildEditableFieldMobile('Nombre Completo (editable)', _nombreController),
        ],
      ),
    );
  }

  Widget _buildDisabledFieldMobile(String label, {required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF666666))),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: Text(value.isEmpty ? '---' : value, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
        ),
      ],
    );
  }

  Widget _buildEditableFieldMobile(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF666666))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Ingrese $label',
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildButtonsSectionMobile() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 130,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _guardarCambios,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC6707),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Actualizar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 130,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDDBB3),
              foregroundColor: const Color(0xFFFC6707),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: const Text('Descartar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(Usuario user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1400;
    final double containerWidth = isLargeScreen ? 1000 : 800;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: null,
      body: Column(
        children: [
          AppHeader(
            activeMenu: 'Perfil',
            onMenuSelected: _handleMenuSelected,
            onEditProfile: () {},
            onLogout: _handleCerrarSesion,
            menuItems: const ['Dashboard', 'Gestión', 'Usuarios', 'Reportes'],
            isMobile: false,
            onMenuTap: null,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: Center(
                child: Container(
                  width: containerWidth,
                  padding: const EdgeInsets.all(32),
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
                          fontSize: isLargeScreen ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAvatarSectionDesktop(user),
                          const SizedBox(width: 48),
                          Expanded(child: _buildFormSectionDesktop(user)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: Color(0xFFE0E0E0)),
                      const SizedBox(height: 24),
                      _buildButtonsSectionDesktop(),
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

  Widget _buildAvatarSectionDesktop(Usuario user) {
    return Column(
      children: [
        GestureDetector(
          onTap: _actualizarFoto,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFC6707), width: 3)),
            child: ClipOval(
              child: user.fotoBase64 != null && user.fotoBase64!.isNotEmpty
                  ? Image.memory(base64Decode(user.fotoBase64!), width: 120, height: 120, fit: BoxFit.cover, gaplessPlayback: true)
                  : Container(color: const Color(0xFFFDDBB3), child: const Icon(Icons.admin_panel_settings, color: Color(0xFFFC6707), size: 60)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHoveringFoto = true),
          onExit: (_) => setState(() => _isHoveringFoto = false),
          child: GestureDetector(
            onTap: _actualizarFoto,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: _isHoveringFoto ? const Color(0xFFFC6707).withOpacity(0.1) : Colors.transparent),
              child: Text('Actualizar foto', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFFC6707))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSectionDesktop(Usuario user) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDisabledFieldDesktop('Nombre Completo', value: user.nombre)),
            const SizedBox(width: 16),
            Expanded(child: _buildDisabledFieldDesktop('Rol', value: 'Administrador')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDisabledFieldDesktop('Correo Electrónico', value: user.correo)),
            const SizedBox(width: 16),
            Expanded(child: _buildEditableFieldDesktop('Nombre (editable)', _nombreController)),
          ],
        ),
      ],
    );
  }

  Widget _buildDisabledFieldDesktop(String label, {required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF666666))),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFE0E0E0), width: 1)),
          child: Text(value.isEmpty ? '---' : value, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF333333))),
        ),
      ],
    );
  }

  Widget _buildEditableFieldDesktop(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF666666))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.outfit(fontSize: 14),
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

  Widget _buildButtonsSectionDesktop() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1400;
    final double buttonWidth = isLargeScreen ? 220 : 180;
    final double fontSize = isLargeScreen ? 18 : 16;
    final double paddingVertical = isLargeScreen ? 16 : 14;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: buttonWidth,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _guardarCambios,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC6707),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: paddingVertical),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Actualizar', style: GoogleFonts.outfit(fontSize: fontSize, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: buttonWidth,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDDBB3),
              foregroundColor: const Color(0xFFFC6707),
              padding: EdgeInsets.symmetric(vertical: paddingVertical),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: Text('Descartar', style: GoogleFonts.outfit(fontSize: fontSize, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
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
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminHomeView()),
                      );
                    },
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
                          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
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
                      _handleMenuSelected('Reportes');
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                _buildDrawerItem('Cerrar Sesión', Icons.logout_outlined, () {
                  Navigator.pop(context);
                  _handleCerrarSesion();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    final isActive = title == 'Perfil';
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
}