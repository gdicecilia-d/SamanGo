import 'package:cloud_firestore/cloud_firestore.dart';
import 'estado_reserva.dart';

class Reserva {
  final String id;
  final String estudianteId;
  final String paqueteId;
  final EstadoReserva estadoActual;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int numeroPersonas;
  final List<Map<String, dynamic>> datosAcompanantes;
  final List<String> extrasSeleccionados;
  final double subtotal;
  final double totalGeneral;
  final String? comprobanteUrl;
  final Map<String, dynamic> historial;
  
  // Campos del estudiante
  final String nombreEstudiante;
  final String apellidoEstudiante;
  final String carnetEstudiante;

  const Reserva({
    required this.id,
    required this.estudianteId,
    required this.paqueteId,
    required this.estadoActual,
    this.fechaInicio,
    this.fechaFin,
    this.numeroPersonas = 1,
    this.datosAcompanantes = const [],
    this.extrasSeleccionados = const [],
    this.subtotal = 0.0,
    this.totalGeneral = 0.0,
    this.comprobanteUrl,
    this.historial = const {},
    required this.nombreEstudiante,
    required this.apellidoEstudiante,
    required this.carnetEstudiante,
  });

  factory Reserva.fromMap(String id, Map<String, dynamic> map) {
    return Reserva(
      id: id,
      estudianteId: map['estudianteId'] as String? ?? '',
      paqueteId: map['paqueteId'] as String? ?? '',
      estadoActual: estadoReservaFromString(
        map['estadoActual'] as String? ?? 'solicitado',
      ),
      fechaInicio: map['fechaInicio'] != null ? (map['fechaInicio'] as Timestamp).toDate() : null,
      fechaFin: map['fechaFin'] != null ? (map['fechaFin'] as Timestamp).toDate() : null,
      numeroPersonas: map['numeroPersonas'] as int? ?? 1,
      datosAcompanantes: List<Map<String, dynamic>>.from(map['datosAcompanantes'] ?? []),
      extrasSeleccionados: List<String>.from(map['extrasSeleccionados'] ?? []),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      totalGeneral: (map['totalGeneral'] ?? 0.0).toDouble(),
      comprobanteUrl: map['comprobanteUrl'] as String?,
      historial: Map<String, dynamic>.from(map['historial'] ?? {}),
      nombreEstudiante: map['nombreEstudiante'] as String? ?? '',
      apellidoEstudiante: map['apellidoEstudiante'] as String? ?? '',
      carnetEstudiante: map['carnetEstudiante'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'estudianteId': estudianteId,
      'paqueteId': paqueteId,
      'estadoActual': estadoActual.toMap(),
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'numeroPersonas': numeroPersonas,
      'datosAcompanantes': datosAcompanantes,
      'extrasSeleccionados': extrasSeleccionados,
      'subtotal': subtotal,
      'totalGeneral': totalGeneral,
      if (comprobanteUrl != null) 'comprobanteUrl': comprobanteUrl,
      'historial': historial,
      'nombreEstudiante': nombreEstudiante,
      'apellidoEstudiante': apellidoEstudiante,
      'carnetEstudiante': carnetEstudiante,
    };
  }

  Reserva copyWith({
    String? id,
    EstadoReserva? estadoActual,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? numeroPersonas,
    List<Map<String, dynamic>>? datosAcompanantes,
    List<String>? extrasSeleccionados,
    double? subtotal,
    double? totalGeneral,
    String? comprobanteUrl,
    Map<String, dynamic>? historial,
    String? nombreEstudiante,
    String? apellidoEstudiante,
    String? carnetEstudiante,
  }) {
    return Reserva(
      id: id ?? this.id,
      estudianteId: estudianteId,
      paqueteId: paqueteId,
      estadoActual: estadoActual ?? this.estadoActual,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      numeroPersonas: numeroPersonas ?? this.numeroPersonas,
      datosAcompanantes: datosAcompanantes ?? this.datosAcompanantes,
      extrasSeleccionados: extrasSeleccionados ?? this.extrasSeleccionados,
      subtotal: subtotal ?? this.subtotal,
      totalGeneral: totalGeneral ?? this.totalGeneral,
      comprobanteUrl: comprobanteUrl ?? this.comprobanteUrl,
      historial: historial ?? this.historial,
      nombreEstudiante: nombreEstudiante ?? this.nombreEstudiante,
      apellidoEstudiante: apellidoEstudiante ?? this.apellidoEstudiante,
      carnetEstudiante: carnetEstudiante ?? this.carnetEstudiante,
    );
  }
}