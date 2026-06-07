// Tarjeta de destino para el catalogo del estudiante
// Ruta: lib/views/student/widgets/destination_card.dart
//
// CAMBIO: el campo imagenUrl ahora puede ser un string Base64 con prefijo
// 'data:image/jpeg;base64,...' o una URL normal. El widget detecta cual es
// y usa Image.memory() para Base64 o Image.network() para URLs normales.

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
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;

  const DestinationCard({
    super.key,
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.precio,
    required this.duracion,
    required this.imagenUrl,
    required this.isOffer,
    required this.onTap,
    this.onFavoriteTap,
  });

  // Devuelve true si imagenUrl es un Base64 embebido, false si es URL normal
  bool get _esBase64 => imagenUrl.startsWith('data:image');

  // Convierte el string Base64 a bytes para Image.memory()
  Uint8List get _bytesBase64 {
    // Eliminar el prefijo 'data:image/jpeg;base64,' y decodificar
    final base64String = imagenUrl.split(',').last;
    return base64Decode(base64String);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zona de imagen
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                child: _buildImagen(),
              ),
            ),
            // Zona de texto y acciones
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Color(0xFF888888)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          duracion,
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF888888)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF888888)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ubicacion,
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF888888)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${precio.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          if (onFavoriteTap != null)
                            IconButton(
                              onPressed: onFavoriteTap,
                              icon: Icon(Icons.favorite_border, color: primaryColor, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: onTap,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Ver mas',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construye el widget de imagen segun si es Base64 o URL normal
  Widget _buildImagen() {
    // Placeholder cuando no hay imagen
    if (imagenUrl.isEmpty) {
      return _placeholder();
    }

    // Base64 embebido: usar Image.memory()
    if (_esBase64) {
      try {
        return Image.memory(
          _bytesBase64,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (_) {
        return _placeholder();
      }
    }

    // URL normal (http/https): usar Image.network()
    return Image.network(
      imagenUrl,
      height: 140,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  // Widget que se muestra cuando no hay imagen o falla la carga
  Widget _placeholder() {
    return Container(
      height: 140,
      color: const Color(0xFFFDDBB3),
      child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
    );
  }
}