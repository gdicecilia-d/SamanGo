// Pantalla que muestra los resultados de la búsqueda
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/app_header.dart';
import 'widgets/destination_card.dart';
import 'destination_detail_view.dart';

class SearchResultsView extends StatefulWidget {
  final String destino;
  final String? transporte;
  final String? presupuesto;
  final String? alojamiento;

  const SearchResultsView({
    super.key,
    required this.destino,
    this.transporte,
    this.presupuesto,
    this.alojamiento,
  });

  @override
  State<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<SearchResultsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> _menuItems = ['Inicio', 'Mis Viajes', 'Favoritos'];

  Future<List<QueryDocumentSnapshot>> _buscarDestinos() async {
    Query query = FirebaseFirestore.instance.collection('destinos');
    
    query = query.where('activo', isEqualTo: true);
    
    if (widget.transporte != null && widget.transporte != 'Todos') {
      query = query.where('transporte', isEqualTo: widget.transporte);
    }
    
    if (widget.alojamiento != null && widget.alojamiento != 'Todos') {
      query = query.where('alojamiento', isEqualTo: widget.alojamiento);
    }
    
    final snapshot = await query.get();
    var resultados = snapshot.docs;
    
    final texto = widget.destino.toLowerCase().trim();
    if (texto.isNotEmpty) {
      resultados = resultados.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final nombre = (data['nombre'] ?? '').toString().toLowerCase();
        final ubicacion = (data['ubicacion'] ?? '').toString().toLowerCase();
        return nombre.contains(texto) || ubicacion.contains(texto);
      }).toList();
    }
    
    if (widget.presupuesto != null && widget.presupuesto != 'Todos') {
      double min = 0;
      double max = double.infinity;
      
      if (widget.presupuesto == '\$0 - \$50') { min = 0; max = 50; }
      else if (widget.presupuesto == '\$50 - \$100') { min = 50; max = 100; }
      else if (widget.presupuesto == '\$100 - \$200') { min = 100; max = 200; }
      else if (widget.presupuesto == '\$200+') { min = 200; max = double.infinity; }
      
      resultados = resultados.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final precio = (data['precio'] ?? 0).toDouble();
        return precio >= min && precio <= max;
      }).toList();
    }
    
    return resultados;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AppHeader(
            activeMenu: '',
            onMenuSelected: (menu) {
              if (menu == 'Inicio') {
                Navigator.pop(context);
              } else if (menu == 'Mis Viajes') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mis Viajes - Próximamente'), backgroundColor: Color(0xFFFC6707)),
                );
              } else if (menu == 'Favoritos') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Favoritos - Próximamente'), backgroundColor: Color(0xFFFC6707)),
                );
              }
            },
            onEditProfile: () {},
            onLogout: () {},
            menuItems: _menuItems,
            isMobile: isMobile,
            onMenuTap: null,
          ),
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: _buscarDestinos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFC6707)),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar resultados',
                      style: GoogleFonts.outfit(color: Colors.red),
                    ),
                  );
                }
                
                final resultados = snapshot.data ?? [];
                
                return Column(
                  children: [
                    // Barra superior con título y botón volver
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Resultados de búsqueda',
                            style: GoogleFonts.outfit(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF333333),
                            ),
                          ),
                          MouseRegion(
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
                        ],
                      ),
                    ),
                    
                    // Filtros activos (chips)
                    if (_getFiltrosActivos().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _getFiltrosActivos().map((filtro) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFC6707).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFC6707), width: 0.5),
                              ),
                              child: Text(
                                filtro,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFFFC6707),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Lista de resultados - SIN padding exterior para que las tarjetas usen su propio tamaño
                    Expanded(
                      child: resultados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_off, size: 64, color: Color(0xFFCCCCCC)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No encontramos destinos\ncon esos filtros',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      color: const Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isMobile ? 2 : 4,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.99,
                              ),
                              itemCount: resultados.length,
                              itemBuilder: (context, index) {
                                final doc = resultados[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final isOffer = data['isOffer'] == true;
                                return DestinationCard(
                                  id: doc.id,
                                  nombre: data['nombre'] ?? 'Sin título',
                                  ubicacion: data['ubicacion'] ?? '',
                                  precio: (data['precio'] ?? 0).toDouble(),
                                  duracion: data['duracion'] ?? 'Full Day',
                                  imagenUrl: data['imagen'] ?? '',
                                  isOffer: isOffer,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DestinationDetailView(destinoId: doc.id),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getFiltrosActivos() {
    final filtros = <String>[];
    if (widget.destino.isNotEmpty) filtros.add('Destino: ${widget.destino}');
    if (widget.transporte != null && widget.transporte != 'Todos') filtros.add('Transporte: ${widget.transporte}');
    if (widget.presupuesto != null && widget.presupuesto != 'Todos') filtros.add('Presupuesto: ${widget.presupuesto}');
    if (widget.alojamiento != null && widget.alojamiento != 'Todos') filtros.add('Alojamiento: ${widget.alojamiento}');
    return filtros;
  }
}