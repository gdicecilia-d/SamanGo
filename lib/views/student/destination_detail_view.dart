import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../shared/app_header.dart';
import 'favorites_view.dart';
import 'student_home_view.dart';
import 'checkout_view.dart';
import 'my_trips_view.dart';
import 'edit_profile_view.dart';
import '../../controllers/favoritos_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'notifications_view.dart';

class DestinationDetailView extends StatefulWidget {
  final String destinoId;

  const DestinationDetailView({super.key, required this.destinoId});

  @override
  State<DestinationDetailView> createState() => _DestinationDetailViewState();
}

class _DestinationDetailViewState extends State<DestinationDetailView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<DocumentSnapshot> _destinoFuture;

  @override
  void initState() {
    super.initState();
    _cargarDestino();
  }

  void _cargarDestino() {
    _destinoFuture = FirebaseFirestore.instance
        .collection('destinos')
        .doc(widget.destinoId)
        .get();
  }

  Future<void> _toggleFavorito(String docId) async {
    final favoritosController = Provider.of<FavoritosController>(context, listen: false);
    
    try {
      await favoritosController.toggleFavorito(docId);
      
      if (mounted) {
        final esFavorito = favoritosController.esFavorito(docId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(esFavorito ? 'Añadido a favoritos' : 'Eliminado de favoritos'),
            backgroundColor: const Color(0xFFFC6707),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar favoritos'),
            backgroundColor: Color(0xFFFC6707),
          ),
        );
      }
    }
  }

  void _handleEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileView()),
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

  bool _esBase64(String url) {
    return url.startsWith('data:image');
  }

  Uint8List _decodificarBase64(String url) {
    final base64String = url.split(',').last;
    return base64Decode(base64String);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final isLargeScreen = screenWidth > 1400;
    
    final double titleFontSize = isMobile ? 24 : (isLargeScreen ? 44 : 32);
    final double subtitleFontSize = isMobile ? 14 : (isLargeScreen ? 20 : 16);
    final double sectionFontSize = isMobile ? 18 : (isLargeScreen ? 26 : 20);
    final double buttonFontSize = isMobile ? 16 : (isLargeScreen ? 22 : 16);
    final double buttonPaddingVertical = isMobile ? 14 : (isLargeScreen ? 20 : 14);
    final double priceFontSize = isMobile ? 36 : (isLargeScreen ? 56 : 42);
    final double paddingHorizontal = isMobile ? 16 : (isLargeScreen ? 48 : 24);
    final double cardPadding = isMobile ? 24 : (isLargeScreen ? 40 : 28);
    final double iconSize = isMobile ? 28 : (isLargeScreen ? 44 : 32);
    final double backButtonSize = isLargeScreen ? 20 : 16;
    final double backButtonTop = isMobile ? 80 : (isLargeScreen ? 100 : 80);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer() : null,
      body: FutureBuilder<DocumentSnapshot>(
        future: _destinoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFC6707)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Destino no encontrado'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          final nombre = data['nombre'] ?? 'Sin título';
          final ubicacion = data['ubicacion'] ?? '';
          final precio = (data['precio'] ?? 0).toDouble();
          final duracion = data['duracion'] ?? 'Full Day';
          final descripcion = data['descripcion'] ?? '';
          final requisitos = data['requisitos'] ?? '';
          final incluye = data['incluye'] ?? '';
          final noIncluye = data['noIncluye'] ?? '';
          final transporte = data['transporte'] ?? '';
          final alojamiento = data['alojamiento'] ?? '';
          final imagenPortada = data['imagen'] ?? '';
          final imagenesReferencia = List<String>.from(data['imagenesReferencia'] ?? []);
          final isOffer = data['isOffer'] ?? false;
          final operadorNombre = data['operadorNombre'] ?? 'Operador';
          final operadorEmpresa = data['operadorEmpresa'] ?? '';
          final calificacionPromedio = (data['calificacionPromedio'] as num?)?.toDouble() ?? 0.0;
          final totalResenas = (data['totalResenas'] as num?)?.toInt() ?? 0;

          final primaryColor = isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image: imagenPortada.isNotEmpty
                      ? DecorationImage(
                          image: _esBase64(imagenPortada)
                              ? MemoryImage(_decodificarBase64(imagenPortada))
                              : NetworkImage(imagenPortada) as ImageProvider,
                          fit: BoxFit.cover,
                          opacity: 0.3,
                        )
                      : null,
                  color: const Color(0xFFF5F5F5),
                ),
              ),
              Column(
                children: [
                  AppHeader(
                    activeMenu: '',
                    onMenuSelected: (menu) {
                      if (menu == 'Inicio') {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const StudentHomeView()),
                          (route) => false,
                        );
                      } else if (menu == 'Favoritos') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FavoritesView()),
                        );
                      } else if (menu == 'Mis Viajes') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyTripsView()),
                        );
                      }
                    },
                    onEditProfile: _handleEditProfile,
                    onLogout: _handleLogout,
                    menuItems: const ['Inicio', 'Mis Viajes', 'Favoritos'],
                    isMobile: isMobile,
                    onMenuTap: isMobile ? _openDrawer : null,
                  ),
                  Expanded(
                    child: isMobile
                        ? _buildMobileLayout(
                            widget.destinoId,
                            nombre,
                            ubicacion,
                            precio,
                            duracion,
                            descripcion,
                            requisitos,
                            incluye,
                            noIncluye,
                            transporte,
                            alojamiento,
                            imagenesReferencia,
                            imagenPortada,
                            operadorNombre,
                            operadorEmpresa,
                            primaryColor,
                            titleFontSize,
                            subtitleFontSize,
                            sectionFontSize,
                            buttonFontSize,
                            buttonPaddingVertical,
                            priceFontSize,
                            paddingHorizontal,
                            cardPadding,
                            iconSize,
                            data,
                            calificacionPromedio,
                            totalResenas,
                          )
                        : _buildDesktopLayout(
                            widget.destinoId,
                            nombre,
                            ubicacion,
                            precio,
                            duracion,
                            descripcion,
                            requisitos,
                            incluye,
                            noIncluye,
                            transporte,
                            alojamiento,
                            imagenesReferencia,
                            imagenPortada,
                            operadorNombre,
                            operadorEmpresa,
                            primaryColor,
                            titleFontSize,
                            subtitleFontSize,
                            sectionFontSize,
                            buttonFontSize,
                            buttonPaddingVertical,
                            priceFontSize,
                            paddingHorizontal,
                            cardPadding,
                            iconSize,
                            isLargeScreen,
                            data,
                            calificacionPromedio,
                            totalResenas,
                          ),
                  ),
                ],
              ),
              Positioned(
                top: backButtonTop,
                right: 24,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          Icon(Icons.arrow_back, color: primaryColor, size: backButtonSize),
                          const SizedBox(width: 4),
                          Text(
                            'Volver',
                            style: GoogleFonts.outfit(
                              fontSize: backButtonSize,
                              color: primaryColor,
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
          );
        },
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
                                child: Icon(Icons.person, color: Color(0xFFFC6707), size: 28),
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDrawerItem('Inicio', Icons.home_outlined, () {
                      Navigator.pop(context);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentHomeView()),
                        (route) => false,
                      );
                    }),
                    _buildDrawerItem('Mis Viajes', Icons.airplane_ticket_outlined, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyTripsView()),
                      );
                    }),
                    _buildDrawerItem('Favoritos', Icons.favorite_border, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FavoritesView()),
                      );
                    }),
                    _buildDrawerItem('Notificaciones', Icons.notifications_outlined, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsView()),
                      );
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
                  _handleLogout();
                }),
              ],
            ),
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
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF333333),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildMobileLayout(
    String destinoId,
    String nombre,
    String ubicacion,
    double precio,
    String duracion,
    String descripcion,
    String requisitos,
    String incluye,
    String noIncluye,
    String transporte,
    String alojamiento,
    List<String> imagenesReferencia,
    String imagenPortada,
    String operadorNombre,
    String operadorEmpresa,
    Color primaryColor,
    double titleFontSize,
    double subtitleFontSize,
    double sectionFontSize,
    double buttonFontSize,
    double buttonPaddingVertical,
    double priceFontSize,
    double paddingHorizontal,
    double cardPadding,
    double iconSize,
    Map<String, dynamic> destinoData,
    double calificacionPromedio,
    int totalResenas,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(paddingHorizontal),
      child: Column(
        children: [
          _buildContentCard(
            destinoId: destinoId,
            nombre: nombre,
            ubicacion: ubicacion,
            precio: precio,
            duracion: duracion,
            descripcion: descripcion,
            requisitos: requisitos,
            incluye: incluye,
            noIncluye: noIncluye,
            transporte: transporte,
            alojamiento: alojamiento,
            imagenesReferencia: imagenesReferencia,
            imagenPortada: imagenPortada,
            operadorNombre: operadorNombre,
            operadorEmpresa: operadorEmpresa,
            primaryColor: primaryColor,
            titleFontSize: titleFontSize,
            subtitleFontSize: subtitleFontSize,
            sectionFontSize: sectionFontSize,
            priceFontSize: priceFontSize,
            cardPadding: cardPadding,
            iconSize: iconSize,
            isMobile: true,
            calificacionPromedio: calificacionPromedio,
            totalResenas: totalResenas,
          ),
          const SizedBox(height: 16),
          _buildConversionCard(
            primaryColor, 
            precio, 
            priceFontSize, 
            sectionFontSize, 
            buttonFontSize, 
            buttonPaddingVertical,
            false,
            destinoData,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    String destinoId,
    String nombre,
    String ubicacion,
    double precio,
    String duracion,
    String descripcion,
    String requisitos,
    String incluye,
    String noIncluye,
    String transporte,
    String alojamiento,
    List<String> imagenesReferencia,
    String imagenPortada,
    String operadorNombre,
    String operadorEmpresa,
    Color primaryColor,
    double titleFontSize,
    double subtitleFontSize,
    double sectionFontSize,
    double buttonFontSize,
    double buttonPaddingVertical,
    double priceFontSize,
    double paddingHorizontal,
    double cardPadding,
    double iconSize,
    bool isLargeScreen,
    Map<String, dynamic> destinoData,
    double calificacionPromedio,
    int totalResenas,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(paddingHorizontal),
            child: _buildContentCard(
              destinoId: destinoId,
              nombre: nombre,
              ubicacion: ubicacion,
              precio: precio,
              duracion: duracion,
              descripcion: descripcion,
              requisitos: requisitos,
              incluye: incluye,
              noIncluye: noIncluye,
              transporte: transporte,
              alojamiento: alojamiento,
              imagenesReferencia: imagenesReferencia,
              imagenPortada: imagenPortada,
              operadorNombre: operadorNombre,
              operadorEmpresa: operadorEmpresa,
              primaryColor: primaryColor,
              titleFontSize: titleFontSize,
              subtitleFontSize: subtitleFontSize,
              sectionFontSize: sectionFontSize,
              priceFontSize: priceFontSize,
              cardPadding: cardPadding,
              iconSize: iconSize,
              isMobile: false,
              calificacionPromedio: calificacionPromedio,
              totalResenas: totalResenas,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsets.only(top: paddingHorizontal, right: paddingHorizontal, bottom: paddingHorizontal),
            child: _buildConversionCard(
              primaryColor, 
              precio, 
              priceFontSize, 
              sectionFontSize, 
              buttonFontSize, 
              buttonPaddingVertical,
              isLargeScreen,
              destinoData,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard({
    required String destinoId,
    required String nombre,
    required String ubicacion,
    required double precio,
    required String duracion,
    required String descripcion,
    required String requisitos,
    required String incluye,
    required String noIncluye,
    required String transporte,
    required String alojamiento,
    required List<String> imagenesReferencia,
    required String imagenPortada,
    required String operadorNombre,
    required String operadorEmpresa,
    required Color primaryColor,
    required double titleFontSize,
    required double subtitleFontSize,
    required double sectionFontSize,
    required double priceFontSize,
    required double cardPadding,
    required double iconSize,
    required bool isMobile,
    required double calificacionPromedio,
    required int totalResenas,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        nombre,
                        style: GoogleFonts.outfit(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ),
                    Consumer<FavoritosController>(
                      builder: (context, favoritosController, child) {
                        final esFavorito = favoritosController.esFavorito(destinoId);
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _toggleFavorito(destinoId),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                esFavorito ? Icons.favorite : Icons.favorite_border,
                                color: primaryColor,
                                size: iconSize,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: subtitleFontSize - 2, color: const Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Text(
                      duracion,
                      style: GoogleFonts.outfit(
                        fontSize: subtitleFontSize - 2,
                        color: const Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: subtitleFontSize - 2, color: const Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ubicacion,
                        style: GoogleFonts.outfit(
                          fontSize: subtitleFontSize - 2,
                          color: const Color(0xFF888888),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (totalResenas > 0)
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: const Color(0xFFFFC107)),
                      const SizedBox(width: 6),
                      Text(
                        calificacionPromedio.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          fontSize: subtitleFontSize - 2,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFC107),
                        ),
                      ),
                      Text(
                        ' ($totalResenas reseñas)',
                        style: GoogleFonts.outfit(
                          fontSize: subtitleFontSize - 4,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Sin reseñas aún',
                    style: GoogleFonts.outfit(
                      fontSize: subtitleFontSize - 2,
                      color: const Color(0xFF888888),
                    ),
                  ),
              ],
            ),
          ),
          if (imagenesReferencia.isNotEmpty || imagenPortada.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: cardPadding),
              child: _buildImageGallery(imagenesReferencia, imagenPortada),
            ),
            const SizedBox(height: 24),
          ],
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Qué incluye? ✈️',
                  style: GoogleFonts.outfit(
                    fontSize: sectionFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                _buildBulletPoint('Transporte:', transporte, subtitleFontSize),
                _buildBulletPoint('Alojamiento:', alojamiento, subtitleFontSize),
                if (incluye.isNotEmpty && incluye != 'No especificado')
                  _buildBulletPoint('Servicios:', incluye, subtitleFontSize),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información Importante 💡',
                  style: GoogleFonts.outfit(
                    fontSize: sectionFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                if (descripcion.isNotEmpty)
                  _buildBulletPoint('Descripción:', descripcion, subtitleFontSize, isLongText: true),
                if (requisitos.isNotEmpty)
                  _buildBulletPoint('Requisitos:', requisitos, subtitleFontSize),
                if (noIncluye.isNotEmpty)
                  _buildBulletPoint('No incluye:', noIncluye, subtitleFontSize),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFDDBB3),
                        ),
                        child: Icon(Icons.business_center, color: primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Operado por: $operadorNombre',
                              style: GoogleFonts.outfit(
                                fontSize: subtitleFontSize - 2,
                                color: const Color(0xFF666666),
                              ),
                            ),
                            Text(
                              operadorEmpresa,
                              style: GoogleFonts.outfit(
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> imagenesReferencia, String imagenPortada) {
    final List<String> imagenes = imagenesReferencia.isNotEmpty 
        ? imagenesReferencia 
        : (imagenPortada.isNotEmpty ? [imagenPortada] : []);
    
    if (imagenes.isEmpty) return const SizedBox.shrink();
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1400;
    final double imageSize = isLargeScreen ? 200.0 : 120.0;
    
    return SizedBox(
      height: imageSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imagenes.length > 3 ? 3 : imagenes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final imagen = imagenes[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(imagen, width: imageSize, height: imageSize),
          );
        },
      ),
    );
  }

  Widget _buildImage(String url, {double width = 120, double height = 120}) {
    if (url.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFFDDBB3),
        child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
      );
    }

    if (_esBase64(url)) {
      try {
        return Image.memory(
          _decodificarBase64(url),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: const Color(0xFFFDDBB3),
            child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
          ),
        );
      } catch (_) {
        return Container(
          width: width,
          height: height,
          color: const Color(0xFFFDDBB3),
          child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
        );
      }
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFFFDDBB3),
        child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
      ),
    );
  }

  Widget _buildBulletPoint(String label, String value, double fontSize, {bool isLongText = false}) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.outfit(
              fontSize: fontSize - 2,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFC6707),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(fontSize: fontSize - 2, color: const Color(0xFF555555)),
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionCard(
    Color primaryColor, 
    double precio, 
    double priceFontSize, 
    double sectionFontSize, 
    double buttonFontSize, 
    double buttonPaddingVertical,
    bool isLargeScreen,
    Map<String, dynamic> destinoData,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: isLargeScreen ? 800 : 600,
      ),
      padding: EdgeInsets.all(isLargeScreen ? 32 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '\$${precio.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(
                fontSize: priceFontSize,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'por persona',
              style: GoogleFonts.outfit(
                fontSize: sectionFontSize - 6,
                color: const Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 16),
            _buildResenasSectionPanel(widget.destinoId, sectionFontSize, primaryColor),
            const SizedBox(height: 24),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 24),
            _buildActionButton(primaryColor, buttonFontSize, buttonPaddingVertical, destinoData),
          ],
        ),
      ),
    );
  }

  Widget _buildResenasSectionPanel(String destinoId, double sectionFontSize, Color primaryColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('resenas')
          .where('paqueteId', isEqualTo: destinoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: Color(0xFFFC6707)),
            ),
          );
        }

        if (snapshot.hasError) {
          print('Error en StreamBuilder de reseñas: ${snapshot.error}');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Reseñas',
                  style: GoogleFonts.outfit(
                    fontSize: sectionFontSize - 4,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.wifi_off, size: 32, color: primaryColor),
                    const SizedBox(height: 8),
                    Text(
                      'Error de conexión',
                      style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                    ),
                    Text(
                      'Intenta nuevamente más tarde',
                      style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Reseñas',
                  style: GoogleFonts.outfit(
                    fontSize: sectionFontSize - 4,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.star_border, size: 32, color: Color(0xFFCCCCCC)),
                    SizedBox(height: 8),
                    Text(
                      'No hay reseñas aún',
                      style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sé el primero en comentar',
                      style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final resenas = snapshot.data!.docs;
        
        final resenasOrdenadas = List<QueryDocumentSnapshot>.from(resenas);
        resenasOrdenadas.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final fechaA = dataA['fechaPublicacion'] as Timestamp?;
          final fechaB = dataB['fechaPublicacion'] as Timestamp?;
          if (fechaA == null && fechaB == null) return 0;
          if (fechaA == null) return 1;
          if (fechaB == null) return -1;
          return fechaB.toDate().compareTo(fechaA.toDate());
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Reseñas',
                style: GoogleFonts.outfit(
                  fontSize: sectionFontSize - 4,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...resenasOrdenadas.take(3).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final calificacion = (data['calificacion'] as num?)?.toDouble() ?? 0.0;
              final comentarios = data['comentarios'] ?? '';
              final calificacionRedondeada = calificacion.round();
              
              String nombreEstudiante = 'Usuario';
              String apellidoEstudiante = '';
              
              if (data['nombreEstudiante'] != null && data['nombreEstudiante'].toString().isNotEmpty) {
                nombreEstudiante = data['nombreEstudiante'].toString();
              }
              if (data['apellidoEstudiante'] != null && data['apellidoEstudiante'].toString().isNotEmpty) {
                apellidoEstudiante = data['apellidoEstudiante'].toString();
              }
              
              final nombreCompleto = apellidoEstudiante.isNotEmpty 
                  ? '$nombreEstudiante $apellidoEstudiante'
                  : nombreEstudiante;
              
              final estudianteId = data['estudianteId']?.toString() ?? '';
              
              Widget buildReviewCard(String finalName) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          final bool isFilled = index < calificacionRedondeada;
                          return Icon(
                            isFilled ? Icons.star : Icons.star_border,
                            size: 14,
                            color: const Color(0xFFFFC107),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        finalName,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      if (comentarios.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          comentarios.length > 80 
                              ? '${comentarios.substring(0, 80)}...' 
                              : comentarios,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF555555),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                );
              }

              if (nombreCompleto != 'Usuario' || estudianteId.isEmpty) {
                return buildReviewCard(nombreCompleto);
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('estudiantes').doc(estudianteId).get(),
                builder: (context, studentSnap) {
                  String asyncName = 'Usuario';
                  if (studentSnap.hasData && studentSnap.data!.exists) {
                    final studentData = studentSnap.data!.data() as Map<String, dynamic>;
                    final nom = studentData['nombre']?.toString() ?? '';
                    final ape = studentData['apellido']?.toString() ?? '';
                    if (nom.isNotEmpty) {
                      asyncName = ape.isNotEmpty ? '$nom $ape' : nom;
                    }
                  }
                  return buildReviewCard(asyncName);
                },
              );
            }),
            if (resenas.length > 3) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => _mostrarTodasLasResenas(resenasOrdenadas, primaryColor),
                  child: Text(
                    'Ver más reseñas (${resenas.length - 3})',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _mostrarTodasLasResenas(List<QueryDocumentSnapshot> resenas, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Todas las reseñas',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: resenas.length,
                  itemBuilder: (context, index) {
                    final data = resenas[index].data() as Map<String, dynamic>;
                    final calificacion = (data['calificacion'] as num?)?.toDouble() ?? 0.0;
                    final comentarios = data['comentarios'] ?? '';
                    final fecha = (data['fechaPublicacion'] as Timestamp?)?.toDate();
                    final calificacionRedondeada = calificacion.round();
                    
                    String nombreEstudiante = 'Usuario';
                    String apellidoEstudiante = '';
                    
                    if (data['nombreEstudiante'] != null && data['nombreEstudiante'].toString().isNotEmpty) {
                      nombreEstudiante = data['nombreEstudiante'].toString();
                    }
                    if (data['apellidoEstudiante'] != null && data['apellidoEstudiante'].toString().isNotEmpty) {
                      apellidoEstudiante = data['apellidoEstudiante'].toString();
                    }
                    
                    final nombreCompleto = apellidoEstudiante.isNotEmpty 
                        ? '$nombreEstudiante $apellidoEstudiante'
                        : nombreEstudiante;
                    
                    final estudianteId = data['estudianteId']?.toString() ?? '';
                    
                    Widget buildModalReviewCard(String finalName) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  final bool isFilled = index < calificacionRedondeada;
                                  return Icon(
                                    isFilled ? Icons.star : Icons.star_border,
                                    size: 16,
                                    color: const Color(0xFFFFC107),
                                  );
                                }),
                                const SizedBox(width: 8),
                                if (fecha != null)
                                  Text(
                                    '${fecha.day}/${fecha.month}/${fecha.year}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: const Color(0xFF888888),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              finalName,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                            if (comentarios.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                comentarios,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    if (nombreCompleto != 'Usuario' || estudianteId.isEmpty) {
                      return buildModalReviewCard(nombreCompleto);
                    }

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('estudiantes').doc(estudianteId).get(),
                      builder: (context, studentSnap) {
                        String asyncName = 'Usuario';
                        if (studentSnap.hasData && studentSnap.data!.exists) {
                          final studentData = studentSnap.data!.data() as Map<String, dynamic>;
                          final nom = studentData['nombre']?.toString() ?? '';
                          final ape = studentData['apellido']?.toString() ?? '';
                          if (nom.isNotEmpty) {
                            asyncName = ape.isNotEmpty ? '$nom $ape' : nom;
                          }
                        }
                        return buildModalReviewCard(asyncName);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(Color primaryColor, double fontSize, double paddingVertical, Map<String, dynamic>? destinoData) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: destinoData != null ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckoutView(
                destinoId: widget.destinoId,
                destinoData: destinoData,
              ),
            ),
          );
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: paddingVertical),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          '¡Quiero ir!',
          style: GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}