// Tarjeta de destino para el catálogo del estudiante
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DestinationCard extends StatelessWidget {
  final String id;
  final String nombre;
  final String ubicacion;
  final double precio;
  final String duracion;
  final String imagenUrl;
  final bool isOffer;
  final int cuposDisponibles;
  final VoidCallback onTap;

  const DestinationCard({
    super.key,
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.precio,
    required this.duracion,
    required this.imagenUrl,
    required this.isOffer,
    required this.cuposDisponibles,
    required this.onTap,
  });

  bool get _esBase64 => imagenUrl.startsWith('data:image');

  Uint8List get _bytesBase64 {
    final base64String = imagenUrl.split(',').last;
    return base64Decode(base64String);
  }

  Color get _primaryColor => isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);
  
  Color get _cuposColor {
    if (cuposDisponibles <= 0) return const Color(0xFFF44336);
    if (cuposDisponibles <= 5) return const Color(0xFFFF9800);
    return const Color(0xFF4CAF50);
  }

  String get _cuposTexto {
    if (cuposDisponibles <= 0) return 'Completo';
    if (cuposDisponibles <= 5) return 'Últimos $cuposDisponibles';
    return '$cuposDisponibles cupos';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    double cardWidth;
    double imageHeight;
    
    if (screenWidth < 600) {
      // Teléfono móvil
      cardWidth = 210;
      imageHeight = 115;
    } else if (screenWidth < 1200) {
      // Pantallas medianas
      cardWidth = 250;
      imageHeight = 145;
    } else {
      // Pantallas grandes 
      cardWidth = 300;
      imageHeight = 175;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                height: imageHeight,
                width: cardWidth,
                child: _buildImagen(cardWidth, imageHeight),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nombre,
                    style: GoogleFonts.outfit(
                      fontSize: screenWidth > 1200 ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Duración
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 13, color: const Color(0xFF888888)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          duracion,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF888888),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Ubicación
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 13, color: const Color(0xFF888888)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          ubicacion,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF888888),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Precio y cupos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${precio.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: screenWidth > 1200 ? 19 : 17,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _cuposColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _cuposTexto,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _cuposColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Botón "Ver más"
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onTap,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Ver más',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: _primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagen(double cardWidth, double imageHeight) {
    if (imagenUrl.isEmpty) {
      return Container(
        width: cardWidth,
        height: imageHeight,
        color: const Color(0xFFFDDBB3),
        child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
      );
    }

    if (_esBase64) {
      try {
        return Image.memory(
          _bytesBase64,
          width: cardWidth,
          height: imageHeight,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: cardWidth,
            height: imageHeight,
            color: const Color(0xFFFDDBB3),
            child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
          ),
        );
      } catch (_) {
        return Container(
          width: cardWidth,
          height: imageHeight,
          color: const Color(0xFFFDDBB3),
          child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
        );
      }
    }

    return Image.network(
      imagenUrl,
      width: cardWidth,
      height: imageHeight,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: cardWidth,
        height: imageHeight,
        color: const Color(0xFFFDDBB3),
        child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
      ),
    );
  }
}