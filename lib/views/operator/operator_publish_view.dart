// Pantalla para publicar un nuevo tour 
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/app_header.dart';
import '../../services/storage_service.dart';
import '../../services/notificacion_service.dart';
import '../../controllers/auth_controller.dart';
import 'operator_home_view.dart';
import 'operator_edit_profile_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';

class OperatorPublishView extends StatefulWidget {
  const OperatorPublishView({super.key});

  @override
  State<OperatorPublishView> createState() => _OperatorPublishViewState();
}

class _OperatorPublishViewState extends State<OperatorPublishView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StorageService _storageService = StorageService();
  
  // Controladores de texto
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _cuposController = TextEditingController(); // NUEVO
  final TextEditingController _requisitosController = TextEditingController();
  final TextEditingController _noIncluyeController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _nochesController = TextEditingController();
  
  // Variables de selección
  String _transporteSeleccionado = 'Bus';
  String _alojamientoSeleccionado = 'Hotel';
  String _duracionSeleccionada = 'Full Day';
  String _selectedCategoria = 'Playas / Cayos';
  bool _isOffer = false;
  
  // Listas de opciones
  final List<String> _transportes = ['Bus', 'Avión', 'Barco', '4x4', 'Todos'];
  final List<String> _alojamientos = ['Hotel', 'Posada', 'Camping', 'Eco lodge', 'No incluye'];
  final List<String> _categorias = [
    'Playas / Cayos',
    'Montañas / Trekking',
    'Aventura / Ríos',
    'Cultura / Ciudades',
  ];
  
  // Checkboxes para Servicios incluidos
  bool _incluyeVuelos = false;
  bool _incluyeTraslados = false;
  bool _incluyeHospedaje = false;
  bool _incluyeComidas = false;
  
  // Imágenes - Usar Uint8List para Web
  Uint8List? _portadaImagenBytes;
  final List<Uint8List?> _referenciasImagenesBytes = [null, null, null];
  bool _isLoading = false;
  bool _isUploadingImages = false;
  
  // Variables para la UI
  bool _isHoveringPublicar = false;
  bool _isHoveringDescartar = false;
  bool _isHoveringVolver = false;
  bool _isHoveringPortada = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _ubicacionController.dispose();
    _precioController.dispose();
    _cuposController.dispose();
    _requisitosController.dispose();
    _noIncluyeController.dispose();
    _descripcionController.dispose();
    _nochesController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    // Validar cupos
    final cuposValidos = _cuposController.text.isNotEmpty &&
        int.tryParse(_cuposController.text) != null &&
        int.parse(_cuposController.text) > 0;
    
    return _tituloController.text.trim().isNotEmpty &&
        _ubicacionController.text.trim().isNotEmpty &&
        _precioController.text.trim().isNotEmpty &&
        cuposValidos &&
        _portadaImagenBytes != null &&
        (_duracionSeleccionada != 'Varias Noches' || _nochesController.text.trim().isNotEmpty);
  }

  Future<void> _seleccionarPortada() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _portadaImagenBytes = bytes;
      });
    }
  }

  Future<void> _seleccionarReferencia(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _referenciasImagenesBytes[index] = bytes;
      });
    }
  }

  String _getIncluyeTexto() {
    List<String> incluidos = [];
    if (_incluyeVuelos) incluidos.add('Vuelos');
    if (_incluyeTraslados) incluidos.add('Traslados');
    if (_incluyeHospedaje) incluidos.add('Hospedaje');
    if (_incluyeComidas) incluidos.add('Comidas');
    return incluidos.isEmpty ? 'No especificado' : incluidos.join(', ');
  }

  Future<void> _publicarTour() async {
    // Validaciones
    if (_tituloController.text.trim().isEmpty) {
      _mostrarMensaje('Por favor ingresa el título del tour');
      return;
    }
    if (_ubicacionController.text.trim().isEmpty) {
      _mostrarMensaje('Por favor ingresa la ubicación');
      return;
    }
    if (_precioController.text.trim().isEmpty) {
      _mostrarMensaje('Por favor ingresa el precio');
      return;
    }
    if (_cuposController.text.trim().isEmpty) {
      _mostrarMensaje('Por favor ingresa la cantidad de cupos disponibles');
      return;
    }
    final cupos = int.tryParse(_cuposController.text.trim());
    if (cupos == null || cupos <= 0) {
      _mostrarMensaje('Los cupos deben ser un número mayor a 0');
      return;
    }
    if (_portadaImagenBytes == null) {
      _mostrarMensaje('Por favor selecciona una imagen de portada');
      return;
    }
    if (_duracionSeleccionada == 'Varias Noches' && _nochesController.text.trim().isEmpty) {
      _mostrarMensaje('Por favor ingresa la cantidad de noches');
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploadingImages = true;
    });

    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final operadorId = auth.usuarioActual?.id ?? '';
      final operadorNombre = auth.usuarioActual?.nombre ?? 'Operador';
      final operadorEmpresa = auth.usuarioActual?.empresa ?? '';

      // Convertir portada a Base64 (comprimida)
      String portadaUrl = '';
      if (_portadaImagenBytes != null) {
        final comprimidos = _storageService.comprimirImagen(_portadaImagenBytes!);
        final base64 = _storageService.imageToBase64(comprimidos);
        portadaUrl = 'data:image/jpeg;base64,$base64';
      }

      // Convertir imágenes de referencia a Base64 (comprimidas)
      List<String> referenciasUrls = [];
      for (int i = 0; i < _referenciasImagenesBytes.length; i++) {
        if (_referenciasImagenesBytes[i] != null) {
          final comprimidos = _storageService.comprimirImagen(_referenciasImagenesBytes[i]!);
          final base64 = _storageService.imageToBase64(comprimidos);
          referenciasUrls.add('data:image/jpeg;base64,$base64');
        }
      }

      // Crear documento en Firestore - colección 'destinos'
      final nuevoDestino = {
        'nombre': _tituloController.text.trim(),
        'ubicacion': _ubicacionController.text.trim(),
        'precio': double.tryParse(_precioController.text.trim()) ?? 0.0,
        'cuposTotales': cupos,
        'cuposDisponibles': cupos,
        'transporte': _transporteSeleccionado,
        'alojamiento': _alojamientoSeleccionado,
        'categoria': _selectedCategoria,
        'imagen': portadaUrl,
        'imagenesReferencia': referenciasUrls,
        'isOffer': _isOffer,
        'descripcion': _descripcionController.text.trim(),
        'duracion': _duracionSeleccionada == 'Full Day' 
            ? 'Full Day' 
            : '${_nochesController.text.trim()} noches',
        'requisitos': _requisitosController.text.trim(),
        'incluye': _getIncluyeTexto(),
        'noIncluye': _noIncluyeController.text.trim(),
        'operadorId': operadorId,
        'operadorNombre': operadorNombre,
        'operadorEmpresa': operadorEmpresa,
        'fechaPublicacion': DateTime.now().toIso8601String(),
        'activo': true,
        'calificacionPromedio': 0.0,
        'totalResenas': 0,
      };

      final docRef = await FirebaseFirestore.instance.collection('destinos').add(nuevoDestino);

      // Generar notificación masiva de manera automática
      await NotificacionService().notificarNuevoPaquete(
        titulo: _isOffer ? '¡Nueva Oferta de Viaje!' : '¡Nuevo Destino Disponible!',
        mensaje: 'La empresa $operadorEmpresa acaba de publicar un viaje a ${_tituloController.text.trim()}. ¡Corre antes de que se agoten los cupos!',
        idPaquete: docRef.id,
      );

      setState(() => _isUploadingImages = false);
      _mostrarMensaje('¡Tour publicado exitosamente!');
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OperatorHomeView()),
      );
    } catch (e) {
      setState(() => _isUploadingImages = false);
      _mostrarMensaje('Error al publicar: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  void _handleMenuSelected(String menu, BuildContext context) {
    if (menu == 'Inicio') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OperatorHomeView()),
      );
    } else if (menu == 'Solicitudes') {
      _mostrarMensaje('Solicitudes - Próximamente');
    }
  }

  void _mostrarDialogoCerrarSesion(BuildContext context) {
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
      endDrawer: isMobile ? _buildDrawer(context) : null,
      body: Column(
        children: [
          AppHeader(
            activeMenu: 'Publicar',
            onMenuSelected: (menu) => _handleMenuSelected(menu, context),
            onEditProfile: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OperatorEditProfileView()),
              );
            },
            onLogout: () => _mostrarDialogoCerrarSesion(context),
            menuItems: const ['Inicio', 'Publicar', 'Solicitudes'],
            isMobile: isMobile,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFFC6707)),
                        SizedBox(height: 16),
                        Text('Publicando tour...'),
                      ],
                    ),
                  )
                : (isMobile ? _buildMobileLayout() : _buildDesktopLayout()),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
                      child: Icon(Icons.person, color: Color(0xFFFC6707), size: 28),
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
            _buildDrawerItem('Inicio', Icons.home_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Inicio', context);
            }),
            _buildDrawerItem('Publicar', Icons.add_box_outlined, () {
              Navigator.pop(context);
            }),
            _buildDrawerItem('Solicitudes', Icons.receipt_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Solicitudes', context);
            }),
            const Spacer(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            _buildDrawerItem('Cerrar Sesión', Icons.logout_outlined, () {
              Navigator.pop(context);
              _mostrarDialogoCerrarSesion(context);
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

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(isMobile: true),
          const SizedBox(height: 16),
          _buildFormContent(isMobile: true),
          const SizedBox(height: 24),
          _buildButtons(isMobile: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile: false),
          const SizedBox(height: 16),
          _buildFormContent(isMobile: false),
          const SizedBox(height: 24),
          _buildButtons(isMobile: false),
        ],
      ),
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Publicar Nuevo Tour',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHoveringVolver = true),
          onExit: (_) => setState(() => _isHoveringVolver = false),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              'Volver',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 14 : 16,
                color: const Color(0xFFFC6707),
                fontWeight: _isHoveringVolver ? FontWeight.bold : FontWeight.w500,
                decoration: _isHoveringVolver ? TextDecoration.underline : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent({required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: isMobile
          ? Column(
              children: [
                _buildImageSection(isMobile: true),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                _buildDetailsSection(isMobile: true),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildImageSection(isMobile: false)),
                const SizedBox(width: 24),
                Container(width: 1, height: 550, color: const Color(0xFFE0E0E0)),
                const SizedBox(width: 24),
                Expanded(child: _buildDetailsSection(isMobile: false)),
              ],
            ),
    );
  }

  Widget _buildImageSection({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Galería de Imágenes',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        // Imagen de Portada
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHoveringPortada = true),
          onExit: (_) => setState(() => _isHoveringPortada = false),
          child: GestureDetector(
            onTap: _seleccionarPortada,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: isMobile ? 180 : 220,
              decoration: BoxDecoration(
                color: _isHoveringPortada ? const Color(0xFFFDF5ED) : const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHoveringPortada ? const Color(0xFFFC6707) : const Color(0xFFE0E0E0),
                  width: _isHoveringPortada ? 2 : 1.5,
                ),
              ),
              child: _portadaImagenBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_portadaImagenBytes!, fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Cambiar imagen',
                                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: _isHoveringPortada ? const Color(0xFFFC6707) : const Color(0xFF999999),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Imagen de Portada',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isHoveringPortada ? const Color(0xFFFC6707) : const Color(0xFF666666),
                          ),
                        ),
                        Text(
                          'Sube o arrastra tu imagen de portada',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF999999)),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Imágenes de referencia
        Text(
          'Imágenes de referencia',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(3, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
                child: GestureDetector(
                  onTap: () => _seleccionarReferencia(index),
                  child: Container(
                    height: isMobile ? 80 : 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                    ),
                    child: _referenciasImagenesBytes[index] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(_referenciasImagenesBytes[index]!, fit: BoxFit.cover),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _referenciasImagenesBytes[index] = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Icon(Icons.add_photo_alternate_outlined, color: const Color(0xFF999999), size: 32),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDetailsSection({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles del Tour',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Título del Viaje', _tituloController, 'Ej: Aventura en Canaima')),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Ubicación', _ubicacionController, 'Ej: Bolívar, Venezuela')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDropdown('Transporte', _transportes, _transporteSeleccionado, (value) {
              setState(() => _transporteSeleccionado = value!);
            })),
            const SizedBox(width: 16),
            Expanded(child: _buildDropdown('Alojamiento', _alojamientos, _alojamientoSeleccionado, (value) {
              setState(() => _alojamientoSeleccionado = value!);
            })),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Precio (USD)', _precioController, 'Ej: 99', isNumber: true)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDropdown('Categoría', _categorias, _selectedCategoria, (value) {
              setState(() => _selectedCategoria = value!);
            })),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Cupos disponibles', _cuposController, 'Ej: 20', isNumber: true)),
            const SizedBox(width: 16),
            Expanded(child: Container()), // Espaciador
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField('Requisitos', _requisitosController, 'Ej: Pasaporte vigente, Vacunas...'),
        const SizedBox(height: 16),
        Text(
          'Duración',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF666666)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRadioButton('Full Day', 'Full Day', _duracionSeleccionada, (value) {
              setState(() => _duracionSeleccionada = value);
            }),
            const SizedBox(width: 24),
            _buildRadioButton('Varias Noches', 'Varias Noches', _duracionSeleccionada, (value) {
              setState(() => _duracionSeleccionada = value);
            }),
          ],
        ),
        if (_duracionSeleccionada == 'Varias Noches') ...[
          const SizedBox(height: 12),
          _buildTextField('Cantidad de noches', _nochesController, 'Ej: 3', isNumber: true, small: true),
        ],
        const SizedBox(height: 16),
        Text(
          'Servicios incluidos',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF666666)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _buildCheckbox('Vuelos', _incluyeVuelos, (value) => setState(() => _incluyeVuelos = value!)),
            _buildCheckbox('Traslados', _incluyeTraslados, (value) => setState(() => _incluyeTraslados = value!)),
            _buildCheckbox('Hospedaje', _incluyeHospedaje, (value) => setState(() => _incluyeHospedaje = value!)),
            _buildCheckbox('Comidas', _incluyeComidas, (value) => setState(() => _incluyeComidas = value!)),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextArea('No Incluye', _noIncluyeController, 'Ej: Bebidas alcohólicas, propinas...', maxLines: 2),
        const SizedBox(height: 16),
        _buildTextArea('Descripción Detallada', _descripcionController, 'Describe el itinerario, actividades...', maxLines: 4),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildCheckbox('Marcar como Oferta Especial', _isOffer, (value) => setState(() => _isOffer = value!)),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool isNumber = false, bool small = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF666666)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: GoogleFonts.outfit(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: small ? 10 : 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea(String label, TextEditingController controller, String hint, {int maxLines = 3}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF666666)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.outfit(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF666666)),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item, style: GoogleFonts.outfit(fontSize: 14)));
            }).toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFC6707)),
            isExpanded: true,
          ),
        ),
      ],
    );
  }

  Widget _buildRadioButton(String title, String value, String groupValue, Function(String) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: (v) => onChanged(v!),
          activeColor: const Color(0xFFFC6707),
        ),
        Text(title, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF333333))),
      ],
    );
  }

  Widget _buildCheckbox(String title, bool value, Function(bool?) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFC6707),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF333333))),
      ],
    );
  }

  Widget _buildButtons({required bool isMobile}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHoveringPublicar = true),
          onExit: (_) => setState(() => _isHoveringPublicar = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: _isUploadingImages ? null : _publicarTour,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC6707),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 32 : 48, vertical: isMobile ? 12 : 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: _isHoveringPublicar ? 4 : 0,
              ),
              child: _isUploadingImages
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Publicar', style: GoogleFonts.outfit(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHoveringDescartar = true),
          onExit: (_) => setState(() => _isHoveringDescartar = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDDBB3),
                foregroundColor: const Color(0xFFFC6707),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 32 : 48, vertical: isMobile ? 12 : 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: _isHoveringDescartar ? 2 : 0,
              ),
              child: Text('Descartar', style: GoogleFonts.outfit(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}