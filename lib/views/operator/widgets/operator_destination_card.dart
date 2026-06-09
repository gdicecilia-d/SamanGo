// Tarjeta de destino para el operador
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OperatorDestinationCard extends StatelessWidget {
  final String id;
  final String nombre;
  final String ubicacion;
  final double precio;
  final String duracion;
  final String imagenUrl;
  final bool isOffer;
  final bool activo;
  final int cuposTotales;
  final int cuposDisponibles;
  final VoidCallback onDelete;

  const OperatorDestinationCard({
    super.key,
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.precio,
    required this.duracion,
    required this.imagenUrl,
    required this.isOffer,
    required this.activo,
    required this.cuposTotales,
    required this.cuposDisponibles,
    required this.onDelete,
  });

  bool get _esBase64 => imagenUrl.startsWith('data:image');

  Uint8List get _bytesBase64 {
    final base64String = imagenUrl.split(',').last;
    return base64Decode(base64String);
  }

  Color get _estadoColor => activo ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
  String get _estadoTexto => activo ? 'Activo' : 'Inactivo';

  int get _cuposReservados => cuposTotales - cuposDisponibles;

  double _getImageHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 400 ? 100 : 120;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final imageHeight = _getImageHeight(context);

    return Container(
      width: isSmallScreen ? double.infinity : 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: _buildImagen(imageHeight),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nombre,
                  style: GoogleFonts.outfit(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        duracion,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF888888),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ubicacion,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF888888),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${precio.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF666666),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _estadoColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _estadoTexto,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _estadoColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFC6707).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFFC6707),
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isOffer)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9C27B0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Oferta',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF9C27B0),
                                ),
                              ),
                            ),
                          if (isOffer) const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFC6707).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Cupos: $_cuposReservados/$cuposTotales',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFC6707),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagen(double imageHeight) {
    if (imagenUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: imageHeight,
        color: const Color(0xFFFDDBB3),
        child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
      );
    }

    if (_esBase64) {
      try {
        return Image.memory(
          _bytesBase64,
          width: double.infinity,
          height: imageHeight,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: double.infinity,
            height: imageHeight,
            color: const Color(0xFFFDDBB3),
            child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
          ),
        );
      } catch (_) {
        return Container(
          width: double.infinity,
          height: imageHeight,
          color: const Color(0xFFFDDBB3),
          child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
        );
      }
    }

    return Image.network(
      imagenUrl,
      width: double.infinity,
      height: imageHeight,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: double.infinity,
        height: imageHeight,
        color: const Color(0xFFFDDBB3),
        child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
      ),
    );
  }
}