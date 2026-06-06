// Pantalla de editar perfil del estudiante
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
import 'student_home_view.dart';
import '../../models/usuario.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoNumeroController = TextEditingController();
  final StorageService _storageService = StorageService();

  String? _selectedCarrera;
  String _selectedTelefonoPrefijo = '0412';
  bool _isHoveringFoto = false;
  bool _isLoading = false;
  
  final List<String> _telefonoOpciones = ['0412', '0414', '0416', '0424', '0426', '0212'];
  
  final List<String> _carreras = [
    'Ingeniería Civil',
    'Ingeniería de Producción',
    'Ingeniería de Sistemas',
    'Ingeniería Eléctrica',
    'Ingeniería Mecánica',
    'Ingeniería Química',
    'TSU en Sistemas Inteligentes',
    'Administración',
    'Ciencias Administrativas',
    'Contaduría Pública',
    'Economía Empresarial',
    'Matemáticas Industriales',
    'Psicología',
    'Derecho',
    'Estudios Liberales',
    'Estudios Internacionales',
    'Educación',
    'Idiomas Modernos',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _telefonoNumeroController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final user = auth.usuarioActual;
    if (user != null) {
      setState(() {
        _emailController.text = user.correo;
        _selectedCarrera = user.carrera;
        if (user.telefono != null && user.telefono!.length >= 11) {
          _selectedTelefonoPrefijo = user.telefono!.substring(0, 4);
          _telefonoNumeroController.text = user.telefono!.substring(4);
        }
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
      
      final telefonoCompleto = _telefonoNumeroController.text.isNotEmpty 
          ? '$_selectedTelefonoPrefijo${_telefonoNumeroController.text}'
          : '';
      
      final success = await Provider.of<AuthController>(context, listen: false).updateStudentProfile(
        carrera: _selectedCarrera ?? '',
        telefono: telefonoCompleto,
      );
      
      if (success) {
        await Provider.of<AuthController>(context, listen: false).reloadUser();
        await _cargarDatosUsuario();
        _mostrarMensaje('Perfil actualizado correctamente');
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        _mostrarMensaje('Error al actualizar el perfil');
      }
      
      setState(() => _isLoading = false);
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
    if (menu == 'Inicio') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomeView()),
      );
    } else if (menu == 'Mis Viajes') {
      _mostrarMensaje('Mis Viajes - Próximamente');
    } else if (menu == 'Favoritos') {
      _mostrarMensaje('Favoritos - Próximamente');
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer() : null,
      body: Column(
        children: [
          AppHeader(
            activeMenu: 'Perfil',
            onMenuSelected: _handleMenuSelected,
            onEditProfile: () {},
            onLogout: _handleCerrarSesion,
            menuItems: const ['Inicio', 'Mis Viajes', 'Favoritos'],
            isMobile: isMobile,
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
                            _buildAvatarSection(user),
                            const SizedBox(height: 24),
                            _buildFormSection(user),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAvatarSection(user),
                            const SizedBox(width: 48),
                            Expanded(child: _buildFormSection(user)),
                          ],
                        ),
                      const SizedBox(height: 32),
                      const Divider(color: Color(0xFFE0E0E0)),
                      const SizedBox(height: 24),
                      _buildButtonsSection(isMobile),
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
                    child: ClipOval(
                      child: user?.fotoBase64 != null
                          ? Image.memory(
                              base64Decode(user!.fotoBase64!),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            )
                          : Container(
                              color: const Color(0xFFFDDBB3),
                              child: const Icon(Icons.person, color: Color(0xFFFC6707), size: 28),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nombre ?? 'Estudiante',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                        ),
                        Text(
                          user?.apellido ?? '',
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
            _buildDrawerItem('Inicio', Icons.home_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Inicio');
            }),
            _buildDrawerItem('Mis Viajes', Icons.airplane_ticket_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Mis Viajes');
            }),
            _buildDrawerItem('Favoritos', Icons.favorite_border, () {
              Navigator.pop(context);
              _handleMenuSelected('Favoritos');
            }),
            const Spacer(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            _buildDrawerItem('Cerrar Sesión', Icons.logout_outlined, () {
              Navigator.pop(context);
              _handleCerrarSesion();
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

  Widget _buildAvatarSection(Usuario user) {
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
              child: user.fotoBase64 != null
                  ? Image.memory(
                      base64Decode(user.fotoBase64!),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : Container(
                      color: const Color(0xFFFDDBB3),
                      child: const Icon(Icons.person, color: Color(0xFFFC6707), size: 50),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _isHoveringFoto ? const Color(0xFFFC6707).withOpacity(0.1) : Colors.transparent,
              ),
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
        ),
      ],
    );
  }

  Widget _buildFormSection(Usuario user) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDisabledField('Nombres', value: user.nombre)),
            const SizedBox(width: 16),
            Expanded(child: _buildDisabledField('Apellidos', value: user.apellido ?? '---')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDisabledField('Fecha de Nacimiento', value: user.fechaNacimiento ?? 'No registrada')),
            const SizedBox(width: 16),
            Expanded(child: _buildDisabledField('Carnet', value: user.carnet ?? 'No registrado')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDisabledField('Correo Unimet', value: user.correo)),
            const SizedBox(width: 16),
            Expanded(child: _buildCarreraDropdown()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTelefonoField()),
            const SizedBox(width: 16),
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }

  Widget _buildCarreraDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Carrera',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCarrera != null && _carreras.contains(_selectedCarrera) 
                ? _selectedCarrera 
                : null,
            hint: Text(
              'Selecciona tu carrera',
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
            ),
            items: _carreras.map((carrera) {
              return DropdownMenuItem(
                value: carrera,
                child: Text(carrera, style: GoogleFonts.outfit(fontSize: 14)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCarrera = value;
              });
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFC6707)),
          ),
        ),
      ],
    );
  }

  Widget _buildTelefonoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Número de Teléfono',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 85,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedTelefonoPrefijo,
                items: _telefonoOpciones.map((prefijo) {
                  return DropdownMenuItem(
                    value: prefijo,
                    child: Text(prefijo, style: GoogleFonts.outfit(fontSize: 16)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTelefonoPrefijo = value!;
                  });
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFC6707)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _telefonoNumeroController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7)
                ],
                style: GoogleFonts.outfit(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '1234567',
                  hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButtonsSection(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: isMobile ? 140 : 180,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _guardarCambios,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC6707),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Actualizar',
                    style: GoogleFonts.outfit(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        SizedBox(width: 16),
        SizedBox(
          width: isMobile ? 140 : 180,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDDBB3),
              foregroundColor: const Color(0xFFFC6707),
              padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: Text(
              'Descartar',
              style: GoogleFonts.outfit(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledField(String label, {required String value}) {
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
          child: Text(
            value.isEmpty ? '---' : value,
            style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF333333)),
          ),
        ),
      ],
    );
  }
}