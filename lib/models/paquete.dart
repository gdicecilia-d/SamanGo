// Modelo Paquete Turístico
// Creado y gestionado por Operadores
class PaqueteTuristico {
  final String id;
  final String vendedorId;
  final double precio;
  final int capacidad;
  final String locacion;

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
}
