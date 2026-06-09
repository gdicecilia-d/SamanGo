// Pantalla de editar perfil del operador
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
import 'operator_home_view.dart';
import '../../models/usuario.dart';

class OperatorEditProfileView extends StatefulWidget {
  const OperatorEditProfileView({super.key});

  @override
  State<OperatorEditProfileView> createState() => _OperatorEditProfileViewState();
}

class _OperatorEditProfileViewState extends State<OperatorEditProfileView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StorageService _storageService = StorageService();
  
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _representanteController = TextEditingController();
  final TextEditingController _rifController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _servicioController = TextEditingController();
  final TextEditingController _telefonoNumeroController = TextEditingController();
  
  String _selectedTelefonoPrefijo = '0412';
  final List<String> _telefonoOpciones = ['0412', '0414', '0416', '0424', '0426', '0212'];
  
  bool _isHoveringFoto = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _empresaController.dispose();
    _representanteController.dispose();
    _rifController.dispose();
    _correoController.dispose();
    _servicioController.dispose();
    _telefonoNumeroController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final user = auth.usuarioActual;
    if (user != null) {
      setState(() {
        _empresaController.text = user.empresa ?? '';
        _representanteController.text = user.nombre;
        _rifController.text = user.rif ?? '';
        _correoController.text = user.correo;
        _servicioController.text = user.descripcion ?? '';
        
        // Parsear teléfono existente - formato esperado: 04121234567 (11 dígitos)
        if (user.telefono != null && user.telefono!.isNotEmpty) {
          String telefono = user.telefono!;
          telefono = telefono.replaceAll(RegExp(r'[^\d]'), '');
          
          if (telefono.length == 11) {
            _selectedTelefonoPrefijo = telefono.substring(0, 4);
            _telefonoNumeroController.text = telefono.substring(4, 11);
          } else if (telefono.length == 10) {
            _selectedTelefonoPrefijo = '0${telefono.substring(0, 3)}';
            _telefonoNumeroController.text = telefono.substring(3, 10);
          } else if (telefono.length == 7) {
            _telefonoNumeroController.text = telefono;
          }
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
      
      final auth = Provider.of<AuthController>(context, listen: false);
      final userId = auth.usuarioActual?.id ?? '';
      
      final telefonoCompleto = _telefonoNumeroController.text.isNotEmpty 
          ? '$_selectedTelefonoPrefijo${_telefonoNumeroController.text}'
          : '';
      
      try {
        final Map<String, dynamic> updates = {
          'descripcion': _servicioController.text,
        };
        if (telefonoCompleto.isNotEmpty) {
          updates['telefono'] = telefonoCompleto;
        }
        
        await FirebaseFirestore.instance.collection('operadores').doc(userId).update(updates);
        
        await auth.reloadUser();
        
        _mostrarMensaje('Perfil actualizado correctamente');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OperatorHomeView()),
        );
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
          _mostrarMensaje('Logo actualizado exitosamente');
        } else {
          _mostrarMensaje('Error al actualizar el logo');
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
        MaterialPageRoute(builder: (_) => const OperatorHomeView()),
      );
    } else if (menu == 'Publicar') {
      Navigator.pop(context);
    } else if (menu == 'Solicitudes') {
      _mostrarMensaje('Solicitudes - Próximamente');
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
            menuItems: const ['Inicio', 'Publicar', 'Solicitudes'],
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
                              child: const Icon(Icons.business_center, color: Color(0xFFFC6707), size: 28),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nombre ?? 'Operador',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                        ),
                        Text(
                          user?.empresa ?? '',
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
            _buildDrawerItem('Publicar', Icons.add_box_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Publicar');
            }),
            _buildDrawerItem('Solicitudes', Icons.receipt_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Solicitudes');
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
                      child: const Icon(Icons.business_center, color: Color(0xFFFC6707), size: 50),
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
                'Actualizar logo',
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
            Expanded(child: _buildDisabledField('Nombre de la Empresa', _empresaController.text)),
            const SizedBox(width: 16),
            Expanded(child: _buildDisabledField('Representante Legal', _representanteController.text)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDisabledField('RIF', _rifController.text)),
            const SizedBox(width: 16),
            Expanded(child: _buildDisabledField('Correo Electrónico', _correoController.text)),
          ],
        ),
        const SizedBox(height: 16),
        _buildEditableField('Descripción del Servicio', _servicioController, maxLines: 3),
        const SizedBox(height: 16),
        _buildTelefonoField(),
      ],
    );
  }

  Widget _buildDisabledField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF666666),
          ),
        ),
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
            value.isEmpty ? 'No registrado' : value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.outfit(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Ingrese $label',
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
              width: 100,
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
        const SizedBox(width: 16),
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
}