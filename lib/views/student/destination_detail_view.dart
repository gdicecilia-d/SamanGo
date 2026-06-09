// Pantalla de detalle del destino
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/app_header.dart';

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
    _destinoFuture = FirebaseFirestore.instance
        .collection('destinos')
        .doc(widget.destinoId)
        .get();
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
              // Fondo con imagen difuminada - MENOS BLANCO
              Container(
                decoration: BoxDecoration(
                  image: imagenPortada.isNotEmpty
                      ? DecorationImage(
                          image: _esBase64(imagenPortada)
                              ? MemoryImage(_decodificarBase64(imagenPortada))
                              : NetworkImage(imagenPortada) as ImageProvider,
                          fit: BoxFit.cover,
                          opacity: 0.4, // Antes 0.15
                        )
                      : null,
                  color: const Color(0xFFE8E8E8), // Antes F8F8F8
                ),
              ),
              Column(
                children: [
                  AppHeader(
                    activeMenu: '',
                    onMenuSelected: (menu) {
                      if (menu == 'Inicio') {
                        Navigator.pop(context);
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
                            data,
                          )
                        : _buildDesktopLayout(
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
                            data,
                          ),
                  ),
                ],
              ),
              // Botón Volver flotante
              Positioned(
                top: 80,
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
                          Icon(Icons.arrow_back, color: primaryColor, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Volver',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
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
    Map<String, dynamic> data,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildContentCard(
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
            isMobile: true,
          ),
          const SizedBox(height: 16),
          _buildActionButton(primaryColor, data),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
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
    Map<String, dynamic> data,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna Izquierda (70%) - Contenido Principal
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildContentCard(
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
              isMobile: false,
            ),
          ),
        ),
        // Columna Derecha (30%) - Caja Flotante de Conversión
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(top: 24, right: 24, bottom: 24),
            child: _buildConversionCard(primaryColor, precio, data),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(
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
    Color primaryColor, {
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
          // Título y Ubicación
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: const Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Text(
                      duracion,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 16, color: const Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ubicacion,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
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
          // Galería de Imágenes
          if (imagenesReferencia.isNotEmpty || imagenPortada.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildImageGallery(imagenesReferencia, imagenPortada),
            ),
            const SizedBox(height: 24),
          ],
          // Divider
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 24),
          // Incluye
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Qué incluye? ✈️',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                _buildBulletPoint('Transporte:', transporte),
                _buildBulletPoint('Alojamiento:', alojamiento),
                if (incluye.isNotEmpty && incluye != 'No especificado')
                  _buildBulletPoint('Servicios:', incluye),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 24),
          // Información Importante
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información Importante 💡',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                if (descripcion.isNotEmpty)
                  _buildBulletPoint('Descripción:', descripcion, isLongText: true),
                if (requisitos.isNotEmpty)
                  _buildBulletPoint('Requisitos:', requisitos),
                if (noIncluye.isNotEmpty)
                  _buildBulletPoint('No incluye:', noIncluye),
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
                                fontSize: 12,
                                color: const Color(0xFF666666),
                              ),
                            ),
                            Text(
                              operadorEmpresa,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
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
    
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imagenes.length > 3 ? 3 : imagenes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final imagen = imagenes[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(imagen, width: 120, height: 120),
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
        child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 32),
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
            child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 32),
          ),
        );
      } catch (_) {
        return Container(
          width: width,
          height: height,
          color: const Color(0xFFFDDBB3),
          child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 32),
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
        child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 32),
      ),
    );
  }

  Widget _buildBulletPoint(String label, String value, {bool isLongText = false}) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFC6707),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF555555)),
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

  Widget _buildConversionCard(Color primaryColor, double precio, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'por persona',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 16),
          Text(
            'Reseñas',
            style: GoogleFonts.outfit(
              fontSize: 18,
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
          _buildActionButton(primaryColor, data),
        ],
      ),
    );
  }

  Widget _buildActionButton(Color primaryColor, Map<String, dynamic> data) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _reservarDestino(widget.destinoId, data),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          '¡Quiero ir!',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _reservarDestino(String destinoId, Map<String, dynamic> data) async {
    final int cuposDisponibles = data['cuposDisponibles'] ?? 0;
    if (cuposDisponibles <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya no hay cupos disponibles'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final nuevoCupo = cuposDisponibles - 1;
      await FirebaseFirestore.instance.collection('destinos').doc(destinoId).update({
        'cuposDisponibles': nuevoCupo,
      });

      if (nuevoCupo == 0) {
        // Notificar al operador
        final operadorId = data['operadorId'];
        final nombrePaquete = data['nombre'] ?? 'un viaje';
        if (operadorId != null) {
          final notifRef = FirebaseFirestore.instance
              .collection('operadores')
              .doc(operadorId)
              .collection('notificaciones')
              .doc();
              
          await notifRef.set({
            'titulo': '¡Cupos Agotados!',
            'mensaje': 'Tu paquete "$nombrePaquete" se ha llenado por completo.',
            'fechaCreacion': FieldValue.serverTimestamp(),
            'leida': false,
            'tipo': 'alerta_operador',
            'idPaquete': destinoId,
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Reserva exitosa!'), backgroundColor: Colors.green),
      );
      
      // Recargar la vista
      if (mounted) {
        setState(() {
          _destinoFuture = FirebaseFirestore.instance.collection('destinos').doc(widget.destinoId).get();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reservar: $e'), backgroundColor: Colors.red),
      );
    }
  }
}