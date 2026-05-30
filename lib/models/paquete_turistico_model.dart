// lib/models/paquete_turistico_model.dart
// Clase: PaqueteTuristico — diagrama de clases Hito 1 SamanGo
// Atributos del diagrama: id, vendedorId, precio, capacidad, locacion
// Método del diagrama: publicar() — se implementa en su controlador

class PaqueteTuristico {
  final String id;          // +id del diagrama
  final String vendedorId;  // +vendedorId — uid del Operador
  final double precio;      // +precio del diagrama
  final int capacidad;      // +capacidad (cupos disponibles)
  final String locacion;    // +locacion del diagrama

  const PaqueteTuristico({
    required this.id,
    required this.vendedorId,
    required this.precio,
    required this.capacidad,
    required this.locacion,
  });

  factory PaqueteTuristico.fromMap(String id, Map<String, dynamic> map) {
    return PaqueteTuristico(
      id: id,
      vendedorId: map['vendedorId'] as String? ?? '',
      precio: (map['precio'] as num?)?.toDouble() ?? 0.0,
      capacidad: map['capacidad'] as int? ?? 0,
      locacion: map['locacion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendedorId': vendedorId,
      'precio': precio,
      'capacidad': capacidad,
      'locacion': locacion,
    };
  }

  // +publicar() del diagrama — implementado en PaqueteController
}
