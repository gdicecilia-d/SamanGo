// lib/models/estado_reserva.dart
// Enum EstadoReserva — valores exactos del diagrama de clases Hito 1
// Estados: Solicitado, Aceptado, Pagado, Disfrutado

enum EstadoReserva {
  solicitado,  // reserva recién creada por el Estudiante
  aceptado,    // Operador aprobó la reserva
  pagado,      // Estudiante completó el pago (PayPal)
  disfrutado,  // viaje completado
}

extension EstadoReservaExtension on EstadoReserva {
  /// Convierte el enum a String para guardar en Firestore
  String toMap() => name;

  /// Etiqueta amigable en español para mostrar en UI
  String get label {
    switch (this) {
      case EstadoReserva.solicitado: return 'Solicitado';
      case EstadoReserva.aceptado:   return 'Aceptado';
      case EstadoReserva.pagado:     return 'Pagado';
      case EstadoReserva.disfrutado: return 'Disfrutado';
    }
  }
}

/// Convierte un String de Firestore al enum correspondiente
EstadoReserva estadoReservaFromString(String value) {
  return EstadoReserva.values.firstWhere(
    (e) => e.name == value.toLowerCase(),
    orElse: () => EstadoReserva.solicitado,
  );
}
