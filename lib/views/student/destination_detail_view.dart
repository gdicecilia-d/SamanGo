// Pantalla de detalle de un destino turistico
// Ruta: lib/views/student/destination_detail_view.dart
//
// Recibe el id del documento en la coleccion 'destinos' y lo carga
// en tiempo real con un StreamBuilder. Soporta imagenes como Base64
// (demo local sin Firebase Storage) o URLs normales.

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class DestinationDetailView extends StatelessWidget {
  final String destinoId;

  const DestinationDetailView({super.key, required this.destinoId});

  // Devuelve true si la cadena es un Base64 embebido
  bool _esBase64(String url) => url.startsWith('data:image');

  // Convierte el string Base64 a bytes
  Uint8List _bytesBase64(String url) {
    return base64Decode(url.split(',').last);
  }

  // Construye el widget de imagen segun si es Base64 o URL normal
  Widget _buildImagen(String url, {double height = 260}) {
    if (url.isEmpty) return _placeholder(height);

    if (_esBase64(url)) {
      try {
        return Image.memory(
          _bytesBase64(url),
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(height),
        );
      } catch (_) {
        return _placeholder(height);
      }
    }

    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(height),
    );
  }

  Widget _placeholder(double height) {
    return Container(
      height: height,
      color: const Color(0xFFFDDBB3),
      child: const Center(child: Icon(Icons.image, color: Color(0xFFFC6707), size: 60)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('destinos')
            .doc(destinoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFC6707)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildNotFound(context);
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final imagenes = List<String>.from(data['imagenesReferencia'] ?? []);
          final isOffer = data['isOffer'] as bool? ?? false;
          final primaryColor = isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);

          return isMobile
              ? _buildMobileLayout(context, data, imagenes, primaryColor)
              : _buildDesktopLayout(context, data, imagenes, primaryColor);
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, Map<String, dynamic> data, List<String> imagenes, Color primaryColor) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: primaryColor,
          leading: _buildBackButton(context),
          flexibleSpace: FlexibleSpaceBar(
            background: imagenes.isNotEmpty ? _buildImagen(imagenes.first) : _placeholder(260),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitulo(data, primaryColor),
                const SizedBox(height: 20),
                _buildInfoRow(data),
                const SizedBox(height: 20),
                if (imagenes.length > 1) ...[
                  _buildGaleria(imagenes),
                  const SizedBox(height: 20),
                ],
                _buildSeccion('Descripcion', data['descripcion'] ?? ''),
                const SizedBox(height: 16),
                _buildSeccion('Requisitos', data['requisitos'] ?? ''),
                const SizedBox(height: 16),
                _buildSeccion('Incluye', data['incluye'] ?? ''),
                const SizedBox(height: 16),
                _buildSeccion('No incluye', data['noIncluye'] ?? ''),
                const SizedBox(height: 16),
                _buildOperador(data),
                const SizedBox(height: 32),
                _buildBotonReserva(context, data, primaryColor),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Map<String, dynamic> data, List<String> imagenes, Color primaryColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
          ),
          child: Row(
            children: [
              _buildBackButton(context),
              const SizedBox(width: 16),
              Text(
                data['nombre'] ?? '',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      imagenes.isNotEmpty ? _buildImagen(imagenes.first, height: 380) : _placeholder(380),
                      if (imagenes.length > 1) ...[
                        const SizedBox(height: 12),
                        _buildGaleria(imagenes),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitulo(data, primaryColor),
                      const SizedBox(height: 20),
                      _buildInfoRow(data),
                      const SizedBox(height: 20),
                      _buildSeccion('Descripcion', data['descripcion'] ?? ''),
                      const SizedBox(height: 16),
                      _buildSeccion('Requisitos', data['requisitos'] ?? ''),
                      const SizedBox(height: 16),
                      _buildSeccion('Incluye', data['incluye'] ?? ''),
                      const SizedBox(height: 16),
                      _buildSeccion('No incluye', data['noIncluye'] ?? ''),
                      const SizedBox(height: 16),
                      _buildOperador(data),
                      const SizedBox(height: 32),
                      _buildBotonReserva(context, data, primaryColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Miniaturas de imagenes adicionales (saltando la portada en posicion 0)
  Widget _buildGaleria(List<String> imagenes) {
    final extras = imagenes.skip(1).toList();
    if (extras.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: extras.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 100,
              height: 80,
              child: _esBase64(extras[index])
                  ? Image.memory(
                      _bytesBase64(extras[index]),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(80),
                    )
                  : Image.network(
                      extras[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(80),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitulo(Map<String, dynamic> data, Color primaryColor) {
    final isOffer = data['isOffer'] as bool? ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isOffer)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF9C27B0), width: 1),
            ),
            child: Text(
              'Oferta Especial',
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF9C27B0), fontWeight: FontWeight.w600),
            ),
          ),
        Text(
          data['nombre'] ?? '',
          style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
        ),
        const SizedBox(height: 8),
        Text(
          '\$${(data['precio'] ?? 0).toStringAsFixed(0)} USD por persona',
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
        ),
      ],
    );
  }

  Widget _buildInfoRow(Map<String, dynamic> data) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildChip(Icons.location_on_outlined, data['ubicacion'] ?? ''),
        _buildChip(Icons.access_time_outlined, data['duracion'] ?? ''),
        _buildChip(Icons.directions_bus_outlined, data['transporte'] ?? ''),
        _buildChip(Icons.hotel_outlined, data['alojamiento'] ?? ''),
      ],
    );
  }

  Widget _buildChip(IconData icon, String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF888888)),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF555555))),
        ],
      ),
    );
  }

  Widget _buildSeccion(String titulo, String contenido) {
    if (contenido.isEmpty || contenido == 'No especificado') return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF333333))),
        const SizedBox(height: 4),
        Text(contenido, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF666666), height: 1.5)),
      ],
    );
  }

  Widget _buildOperador(Map<String, dynamic> data) {
    final empresa = data['operadorEmpresa'] as String? ?? '';
    final nombre = data['operadorNombre'] as String? ?? '';
    if (empresa.isEmpty && nombre.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFDDBB3)),
            child: const Icon(Icons.business, color: Color(0xFFFC6707), size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                empresa.isNotEmpty ? empresa : nombre,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
              ),
              Text('Operador verificado', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF888888))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonReserva(BuildContext context, Map<String, dynamic> data, Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _solicitarReserva(context, data),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        child: Text('Solicitar Reserva', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _solicitarReserva(BuildContext context, Map<String, dynamic> data) async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final estudianteId = auth.usuarioActual?.id ?? '';

    if (estudianteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesion para reservar'), backgroundColor: Color(0xFFFC6707)),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('reservas').add({
        'estudianteId': estudianteId,
        'paqueteId': destinoId,
        'operadorId': data['operadorId'] ?? '',
        'estadoActual': 'solicitado',
        'creadoEn': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva solicitada correctamente'), backgroundColor: Color(0xFF4CAF50)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al solicitar: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_off_outlined, size: 64, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 16),
          Text('Destino no disponible', style: GoogleFonts.outfit(fontSize: 18, color: const Color(0xFF999999))),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Volver', style: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.arrow_back, color: Color(0xFF333333), size: 20),
      ),
    );
  }
}