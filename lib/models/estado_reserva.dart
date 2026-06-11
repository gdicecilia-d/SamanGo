// Enumeracion de estados de reserva
// Flujo: Solicitado → Aceptado → Pagado → Disfrutado
enum EstadoReserva {
  solicitado,
  aceptado,
  verificandoPago,
  pagado,
  disfrutado,
}

extension EstadoReservaExtension on EstadoReserva {
  String toMap() => name;

  String get label {
    switch (this) {
      case EstadoReserva.solicitado:
        return 'Solicitado';
      case EstadoReserva.aceptado:
        return 'Aceptado (Listo para Pagar)';
      case EstadoReserva.verificandoPago:
        return 'Verificando Pago';
      case EstadoReserva.pagado:
        return 'Pagado (Próximo Viaje)';
      case EstadoReserva.disfrutado:
        return 'Disfrutado';
    }
  }
}

EstadoReserva estadoReservaFromString(String value) {
  return EstadoReserva.values.firstWhere(
    (e) => e.name == value.toLowerCase(),
    orElse: () => EstadoReserva.solicitado,
  );
}
