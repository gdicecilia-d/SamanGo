// lib/models/reserva_model.dart
// Clase: Reserva — diagrama de clases Hito 1 SamanGo
// Atributos del diagrama: id, estudianteId, paqueteId, estadoActual
// Métodos del diagrama: simularPago(), actualizarEstado() — en ReservaController

import 'estado_reserva.dart';

class Reserva {
  final String id;                  // +id del diagrama
  final String estudianteId;        // +estudianteId — uid del Estudiante
  final String paqueteId;           // +paqueteId — id del PaqueteTuristico
  final EstadoReserva estadoActual; // +estadoActual — enum EstadoReserva

  const Reserva({
    required this.id,
    required this.estudianteId,
    required this.paqueteId,
    required this.estadoActual,
  });

  factory Reserva.fromMap(String id, Map<String, dynamic> map) {
    return Reserva(
      id: id,
      estudianteId: map['estudianteId'] as String? ?? '',
      paqueteId: map['paqueteId'] as String? ?? '',
      estadoActual: estadoReservaFromString(
        map['estadoActual'] as String? ?? 'solicitado',
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'estudianteId': estudianteId,
      'paqueteId': paqueteId,
      'estadoActual': estadoActual.toMap(),
    };
  }

  // +simularPago() → transición aceptado → pagado (implementado en ReservaController)
  // +actualizarEstado() → actualiza estadoActual en Firestore (implementado en ReservaController)

  Reserva copyWith({EstadoReserva? estadoActual}) {
    return Reserva(
      id: id,
      estudianteId: estudianteId,
      paqueteId: paqueteId,
      estadoActual: estadoActual ?? this.estadoActual,
    );
  }
}
