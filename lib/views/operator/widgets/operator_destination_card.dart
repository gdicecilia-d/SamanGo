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

  Color get _estadoColor {
    if (isOffer) return const Color(0xFF9C27B0);
    return activo ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
  }
  
  String get _estadoTexto => activo ? 'Activo' : 'Inactivo';

  int get _cuposReservados => cuposTotales - cuposDisponibles;
  
  Color get _primaryColor => isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    double cardWidth;
    double imageHeight;
    
    if (screenWidth < 600) {
      cardWidth = 200;
      imageHeight = 100;
    } else if (screenWidth < 1200) {
      cardWidth = 230;
      imageHeight = 130;
    } else {
      cardWidth = 260;
      imageHeight = 150;
    }

    return Container(
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
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nombre,
                  style: GoogleFonts.outfit(
                    fontSize: screenWidth > 1200 ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: screenWidth < 600 ? 11 : 13, color: const Color(0xFF888888)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        duracion,
                        style: GoogleFonts.outfit(
                          fontSize: screenWidth < 600 ? 10 : 12,
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
                    Icon(Icons.location_on, size: screenWidth < 600 ? 11 : 13, color: const Color(0xFF888888)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        ubicacion,
                        style: GoogleFonts.outfit(
                          fontSize: screenWidth < 600 ? 10 : 12,
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
                        fontSize: screenWidth > 1200 ? 17 : 15,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
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
                          fontSize: screenWidth < 600 ? 9 : 11,
                          fontWeight: FontWeight.w600,
                          color: _estadoColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: _primaryColor,
                            size: screenWidth < 600 ? 14 : 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$_cuposReservados/$cuposTotales ocupados',
                                style: GoogleFonts.outfit(
                                  fontSize: screenWidth < 600 ? 9 : 11,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 80,
                                height: 4,
                                child: LinearProgressIndicator(
                                  value: cuposTotales > 0 ? _cuposReservados / cuposTotales : 0,
                                  backgroundColor: _primaryColor.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
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

  Widget _buildImagen(double cardWidth, double imageHeight) {
    if (imagenUrl.isEmpty) {
      return Container(
        width: cardWidth,
        height: imageHeight,
        color: const Color(0xFFFDDBB3),
        child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 30),
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
            child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 30),
          ),
        );
      } catch (_) {
        return Container(
          width: cardWidth,
          height: imageHeight,
          color: const Color(0xFFFDDBB3),
          child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 30),
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
        child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 30),
      ),
    );
  }
}