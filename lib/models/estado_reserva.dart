// Todos los estados posibles de una reserva en SamanGo.
// El flujo normal es:
// solicitado → aceptado → verificandoPago → pagado → disfrutado
// En cualquier punto puede ir a: rechazado o cancelado

enum EstadoReserva {
  solicitado,      // El estudiante envió la solicitud, espera respuesta del operador
  aceptado,        // El operador aceptó, el estudiante debe proceder al pago
  verificandoPago, // El estudiante subió el comprobante, el operador lo está revisando
  pagado,          // El operador confirmó el pago, el viaje está listo para realizarse
  disfrutado,      // El operador marcó el viaje como completado, el estudiante puede reseñar
  rechazado,       // El operador rechazó la solicitud o el comprobante de pago
  cancelado,       // El estudiante canceló la reserva
}

// Convierte el string guardado en Firestore al enum correspondiente.
// Si el valor no coincide con ninguno, devuelve "solicitado" por defecto.
EstadoReserva estadoReservaFromString(String value) {
  switch (value) {
    case 'solicitado':
      return EstadoReserva.solicitado;
    case 'aceptado':
      return EstadoReserva.aceptado;
    case 'verificandoPago':
      return EstadoReserva.verificandoPago;
    case 'pagado':
      return EstadoReserva.pagado;
    case 'disfrutado':
      return EstadoReserva.disfrutado;
    case 'rechazado':
      return EstadoReserva.rechazado;
    case 'cancelado':
      return EstadoReserva.cancelado;
    default:
      return EstadoReserva.solicitado;
  }
}

// Extensión para convertir el enum a string antes de guardarlo en Firestore
extension EstadoReservaExtension on EstadoReserva {
  // Devuelve el string exacto que se guarda en Firestore
  String toMap() {
    switch (this) {
      case EstadoReserva.solicitado:
        return 'solicitado';
      case EstadoReserva.aceptado:
        return 'aceptado';
      case EstadoReserva.verificandoPago:
        return 'verificandoPago';
      case EstadoReserva.pagado:
        return 'pagado';
      case EstadoReserva.disfrutado:
        return 'disfrutado';
      case EstadoReserva.rechazado:
        return 'rechazado';
      case EstadoReserva.cancelado:
        return 'cancelado';
    }
  }

  // Texto legible para mostrar en la UI
  String get label {
    switch (this) {
      case EstadoReserva.solicitado:
        return 'Solicitado';
      case EstadoReserva.aceptado:
        return 'Aceptado';
      case EstadoReserva.verificandoPago:
        return 'Verificando pago';
      case EstadoReserva.pagado:
        return 'Pagado';
      case EstadoReserva.disfrutado:
        return 'Disfrutado';
      case EstadoReserva.rechazado:
        return 'Rechazado';
      case EstadoReserva.cancelado:
        return 'Cancelado';
    }
  }

  // Color asociado a cada estado para mostrar en chips o badges
  int get colorValue {
    switch (this) {
      case EstadoReserva.solicitado:
        return 0xFFFF9800; // naranja
      case EstadoReserva.aceptado:
        return 0xFF2196F3; // azul
      case EstadoReserva.verificandoPago:
        return 0xFF9C27B0; // morado
      case EstadoReserva.pagado:
        return 0xFF4CAF50; // verde
      case EstadoReserva.disfrutado:
        return 0xFFFC6707; // naranja SamanGo
      case EstadoReserva.rechazado:
        return 0xFFF44336; // rojo
      case EstadoReserva.cancelado:
        return 0xFF9E9E9E; // gris
    }
  }
}