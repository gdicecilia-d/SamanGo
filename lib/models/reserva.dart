// Modelo Reserva
// Relaciona un Estudiante con un Paquete Turístico
import 'estado_reserva.dart';

class Reserva {
  final String id;
  final String estudianteId;
  final String paqueteId;
  final EstadoReserva estadoActual;

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

  Reserva copyWith({EstadoReserva? estadoActual}) {
    return Reserva(
      id: id,
      estudianteId: estudianteId,
      paqueteId: paqueteId,
      estadoActual: estadoActual ?? this.estadoActual,
    );
  }
}
