import 'package:cloud_firestore/cloud_firestore.dart';

class Notificacion {
  final String id;
  final String titulo;
  final String mensaje;
  final DateTime fechaCreacion;
  final bool leida;
  final String tipo; // 'global', 'personal', 'paquete'
  final String? idPaquete;

  Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.fechaCreacion,
    this.leida = false,
    required this.tipo,
    this.idPaquete,
  });

  factory Notificacion.fromMap(String id, Map<String, dynamic> data) {
    return Notificacion(
      id: id,
      titulo: data['titulo'] ?? '',
      mensaje: data['mensaje'] ?? '',
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      leida: data['leida'] ?? false,
      tipo: data['tipo'] ?? 'personal',
      idPaquete: data['idPaquete'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'mensaje': mensaje,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'leida': leida,
      'tipo': tipo,
      'idPaquete': idPaquete,
    };
  }
}
