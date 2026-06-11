// Pantalla de detalle del destino
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
import '../../controllers/favoritos_controller.dart';

class DestinationDetailView extends StatefulWidget {
  final String destinoId;

  const DestinationDetailView({super.key, required this.destinoId});

  @override
  State<DestinationDetailView> createState() => _DestinationDetailViewState();
}

class _DestinationDetailViewState extends State<DestinationDetailView> {
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    
    // Tamaños responsivos
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
      backgroundColor: Colors.white,
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

          final primaryColor = isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);

          return Stack(
            children: [
              // Fondo con la imagen de portada
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mis Viajes - Próximamente'),
                            backgroundColor: Color(0xFFFC6707),
                          ),
                        );
                      }
                    },
                    onEditProfile: () {},
                    onLogout: () {},
                    menuItems: const ['Inicio', 'Mis Viajes', 'Favoritos'],
                    isMobile: isMobile,
                    onMenuTap: null,
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
                          ),
                  ),
                ],
              ),
              // Botón volver flotante sobre la foto
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
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(paddingHorizontal),
      child: Column(
        children: [
          _buildContentCard(
            destinoId,
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
            priceFontSize,
            cardPadding,
            iconSize,
            isMobile: true,
          ),
          const SizedBox(height: 16),
          _buildActionButton(primaryColor, buttonFontSize, buttonPaddingVertical),
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
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(paddingHorizontal),
            child: _buildContentCard(
              destinoId,
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
              priceFontSize,
              cardPadding,
              iconSize,
              isMobile: false,
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(
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
    double priceFontSize,
    double cardPadding,
    double iconSize, {
    required bool isMobile,
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
  ) {
    return Container(
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
          Text(
            'Reseñas',
            style: GoogleFonts.outfit(
              fontSize: sectionFontSize - 4,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 24),
          _buildActionButton(primaryColor, buttonFontSize, buttonPaddingVertical, data),
        ],
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