// Pantalla de detalle del destino
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../shared/app_header.dart';

class DestinationDetailView extends StatefulWidget {
  final String destinoId;

  const DestinationDetailView({super.key, required this.destinoId});

  @override
  State<DestinationDetailView> createState() => _DestinationDetailViewState();
}

class _DestinationDetailViewState extends State<DestinationDetailView> {
  late Future<DocumentSnapshot> _destinoFuture;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _destinoFuture = FirebaseFirestore.instance
        .collection('destinos')
        .doc(widget.destinoId)
        .get();
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
          final imagenesReferencia = List<String>.from(data['imagenesReferencia'] ?? []);
          final isOffer = data['isOffer'] ?? false;
          final operadorNombre = data['operadorNombre'] ?? 'Operador';
          final operadorEmpresa = data['operadorEmpresa'] ?? '';

          final primaryColor = isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);

          return Stack(
            children: [
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bloque de Título y Precio
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre,
                                      style: GoogleFonts.outfit(
                                        fontSize: isMobile ? 24 : 28,
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
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isFavorite = !_isFavorite;
                                      });
                                    },
                                    icon: Icon(
                                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                  Text(
                                    '\$${precio.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Layout de dos columnas
                          isMobile
                              ? Column(
                                  children: [
                                    _buildLeftColumn(
                                      imagenesReferencia,
                                      incluye,
                                      noIncluye,
                                      descripcion,
                                      requisitos,
                                      transporte,
                                      alojamiento,
                                      primaryColor,
                                    ),
                                    const SizedBox(height: 24),
                                    _buildRightColumn(
                                      operadorNombre,
                                      operadorEmpresa,
                                      primaryColor,
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: _buildLeftColumn(
                                        imagenesReferencia,
                                        incluye,
                                        noIncluye,
                                        descripcion,
                                        requisitos,
                                        transporte,
                                        alojamiento,
                                        primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      flex: 3,
                                      child: _buildRightColumn(
                                        operadorNombre,
                                        operadorEmpresa,
                                        primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
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
                    child: Text(
                      'Volver',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFFFC6707),
                        fontWeight: FontWeight.w500,
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

  Widget _buildLeftColumn(
    List<String> imagenesReferencia,
    String incluye,
    String noIncluye,
    String descripcion,
    String requisitos,
    String transporte,
    String alojamiento,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Galería de Imágenes de Referencia
          if (imagenesReferencia.isNotEmpty) ...[
            Text(
              'Galería',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imagenesReferencia.length > 3 ? 3 : imagenesReferencia.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imagenesReferencia[index],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: const Color(0xFFFDDBB3),
                        child: const Icon(Icons.image, color: Color(0xFFFC6707)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Sección ¿Qué incluye?
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
          const SizedBox(height: 16),

          // Sección Información Importante
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
        ],
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

  Widget _buildRightColumn(
    String operadorNombre,
    String operadorEmpresa,
    Color primaryColor,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Operador',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFDDBB3),
                    ),
                    child: const Icon(Icons.business_center, color: Color(0xFFFC6707), size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          operadorNombre,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        Text(
                          operadorEmpresa,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Reseñas',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'No hay reseñas aún',
                  style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de reserva - Próximamente'),
                  backgroundColor: Color(0xFFFC6707),
                ),
              );
            },
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
        ),
      ],
    );
  }
}