// Pantalla que muestra los resultados de la búsqueda
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchResultsView extends StatefulWidget {
  // Filtros que llegan desde el buscador
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

  // Consulta Firestore y aplica los filtros seleccionados
  Future<List<Map<String, dynamic>>> _buscarDestinos() async {
    Query query = FirebaseFirestore.instance.collection('destinos');

    // Filtra por transporte si el usuario eligió uno específico
    if (widget.transporte != null && widget.transporte != 'Todos') {
      query = query.where('transporte', isEqualTo: widget.transporte);
    }

    // Filtra por alojamiento si el usuario eligió uno específico
    if (widget.alojamiento != null && widget.alojamiento != 'Todos') {
      query = query.where('alojamiento', isEqualTo: widget.alojamiento);
    }

    // Trae los documentos de Firestore
    final snapshot = await query.get();
    final todos = snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    }).toList();

    // Filtra por texto del destino (busca en nombre y ubicación)
    final texto = widget.destino.toLowerCase().trim();
    final filtrados = texto.isEmpty
        ? todos
        : todos.where((d) {
            final nombre = (d['nombre'] ?? '').toString().toLowerCase();
            final ubicacion = (d['ubicacion'] ?? '').toString().toLowerCase();
            return nombre.contains(texto) || ubicacion.contains(texto);
          }).toList();

    // Aplica el filtro de presupuesto si fue seleccionado
    if (widget.presupuesto != null && widget.presupuesto != 'Todos') {
      return _filtrarPorPresupuesto(filtrados, widget.presupuesto!);
    }

    return filtrados;
  }

  // Filtra la lista por rango de precio
  List<Map<String, dynamic>> _filtrarPorPresupuesto(
    List<Map<String, dynamic>> lista,
    String rango,
  ) {
    double min = 0;
    double max = double.infinity;

    // Asigna el rango según la opción elegida
    if (rango == '\$0 - \$50') { min = 0; max = 50; }
    else if (rango == '\$50 - \$100') { min = 50; max = 100; }
    else if (rango == '\$100 - \$200') { min = 100; max = 200; }
    else if (rango == '\$200+') { min = 200; max = double.infinity; }

    return lista.where((d) {
      final precio = (d['precio'] ?? 0).toDouble();
      return precio >= min && precio <= max;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Botón para volver a la pantalla anterior
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Resultados',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chips que muestran los filtros activos
          _buildFiltrosActivos(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _buscarDestinos(),
              builder: (context, snapshot) {
                // Mientras carga muestra un indicador
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFC6707)),
                  );
                }
                // Si hubo un error lo muestra
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar resultados',
                      style: GoogleFonts.outfit(color: Colors.red),
                    ),
                  );
                }
                final resultados = snapshot.data ?? [];
                // Si no hay resultados muestra un mensaje
                if (resultados.isEmpty) {
                  return _buildSinResultados();
                }
                // Si hay resultados los muestra en lista
                return _buildListaResultados(resultados);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Muestra chips naranjas con cada filtro que el usuario aplicó
  Widget _buildFiltrosActivos() {
    final filtros = <String>[];
    if (widget.destino.isNotEmpty) filtros.add(widget.destino);
    if (widget.transporte != null && widget.transporte != 'Todos') filtros.add(widget.transporte!);
    if (widget.presupuesto != null && widget.presupuesto != 'Todos') filtros.add(widget.presupuesto!);
    if (widget.alojamiento != null && widget.alojamiento != 'Todos') filtros.add(widget.alojamiento!);

    // Si no hay filtros no muestra nada
    if (filtros.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: filtros.map((f) => Chip(
          label: Text(f, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white)),
          backgroundColor: const Color(0xFFFC6707),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        )).toList(),
      ),
    );
  }

  // Mensaje cuando no hay destinos que coincidan con la búsqueda
  Widget _buildSinResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 16),
          Text(
            'No encontramos destinos\ncon esos filtros',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  // Lista scrolleable con todas las tarjetas de resultados
  Widget _buildListaResultados(List<Map<String, dynamic>> resultados) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: resultados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildResultCard(resultados[index]);
      },
    );
  }

  // Tarjeta individual con la info de cada destino
  Widget _buildResultCard(Map<String, dynamic> destino) {
    // Saca los datos del documento de Firestore
    final imagen = destino['imagen'] ?? '';
    final nombre = destino['nombre'] ?? 'Sin nombre';
    final ubicacion = destino['ubicacion'] ?? '';
    final precio = (destino['precio'] ?? 0).toDouble();
    final transporte = destino['transporte'] ?? '';
    final alojamiento = destino['alojamiento'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Imagen del destino a la izquierda
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: imagen.isNotEmpty
                ? Image.network(
                    imagen,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImagenPlaceholder(),
                  )
                : _buildImagenPlaceholder(),
          ),
          // Información del destino a la derecha
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del destino
                  Text(
                    nombre,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Ubicación con ícono de pin
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFFFC6707)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          ubicacion,
                          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF888888)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Tags de transporte y alojamiento
                  Wrap(
                    spacing: 6,
                    children: [
                      if (transporte.isNotEmpty) _buildTag(transporte, Icons.directions_bus_outlined),
                      if (alojamiento.isNotEmpty) _buildTag(alojamiento, Icons.bed_outlined),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Precio y botón ver más
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${precio.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFC6707),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Ver más',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFFFC6707),
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  // Cuadro gris que aparece cuando un destino no tiene imagen
  Widget _buildImagenPlaceholder() {
    return Container(
      width: 110,
      height: 110,
      color: const Color(0xFFFDDBB3),
      child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 32),
    );
  }

  // Tag pequeño con ícono para mostrar transporte o alojamiento
  Widget _buildTag(String texto, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFFC6707)),
          const SizedBox(width: 3),
          Text(
            texto,
            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFFFC6707)),
          ),
        ],
      ),
    );
  }
}