import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../models/estado_reserva.dart';
import '../models/usuario.dart';
import '../services/reserva_service.dart';
import '../services/notificacion_service.dart';

class ReservaController extends ChangeNotifier {
  final ReservaService _reservaService = ReservaService();
  final NotificacionService _notificacionService = NotificacionService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Crea una nueva reserva con estado inicial "solicitado"
  Future<bool> crearReserva(Reserva reserva) async {
    _setLoading(true);
    try {
      await _reservaService.crearReserva(reserva);
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error creando reserva: $e');
      _setLoading(false);
      return false;
    }
  }

  // Avanza el estado de una reserva si la transición es válida para el rol del actor.
  //
  // Flujo permitido:
  //   solicitado → aceptado          (operador acepta la solicitud)
  //   aceptado → verificandoPago     (estudiante sube el comprobante)
  //   verificandoPago → pagado       (operador confirma el pago)
  //   pagado → disfrutado            (operador marca el viaje como realizado)
  Future<bool> cambiarEstadoReserva(Reserva reserva, EstadoReserva nuevoEstado, Usuario actor) async {
    final EstadoReserva estadoActual = reserva.estadoActual;
    bool esTransicionValida = false;

    if (actor.isEstudiante) {
      // El estudiante solo puede enviar su comprobante una vez aceptada la solicitud
      if (estadoActual == EstadoReserva.aceptado && nuevoEstado == EstadoReserva.verificandoPago) {
        esTransicionValida = true;
      }
    } else if (actor.isOperador) {
      // El operador acepta la solicitud inicial
      if (estadoActual == EstadoReserva.solicitado && nuevoEstado == EstadoReserva.aceptado) {
        esTransicionValida = true;
      }
      // El operador confirma que el comprobante de pago es válido
      else if (estadoActual == EstadoReserva.verificandoPago && nuevoEstado == EstadoReserva.pagado) {
        esTransicionValida = true;
      }
      // El operador marca el viaje como completado
      else if (estadoActual == EstadoReserva.pagado && nuevoEstado == EstadoReserva.disfrutado) {
        esTransicionValida = true;
      }
    }

    if (!esTransicionValida) {
      debugPrint('Transición no válida: $estadoActual → $nuevoEstado por rol ${actor.rol}');
      return false;
    }

    _setLoading(true);
    try {
      await _reservaService.actualizarEstado(reserva.id, nuevoEstado);

      // Notificamos al estudiante cuando el operador toma una decisión
      if (actor.isOperador) {
        if (nuevoEstado == EstadoReserva.aceptado) {
          // Le avisamos que ya puede proceder al pago
          await _notificacionService.notificarSolicitudAceptada(
            estudianteId: reserva.estudianteId,
            nombrePaquete: reserva.paqueteId,
            reservaId: reserva.id,
          );
        } else if (nuevoEstado == EstadoReserva.pagado) {
          // Le confirmamos que su cupo está asegurado
          await _notificacionService.notificarPagoConfirmado(
            estudianteId: reserva.estudianteId,
            nombrePaquete: reserva.paqueteId,
            reservaId: reserva.id,
          );
        }
      }

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error cambiando estado de reserva: $e');
      _setLoading(false);
      return false;
    }
  }

  // El operador rechaza la solicitud de cupo.
  // Guarda el estado "rechazado" y notifica al estudiante con el motivo si lo hay.
  Future<bool> rechazarSolicitud(Reserva reserva, Usuario operador, {String? motivo}) async {
    if (!operador.isOperador || reserva.estadoActual != EstadoReserva.solicitado) {
      debugPrint('Rechazo no permitido: rol=${operador.rol}, estado=${reserva.estadoActual}');
      return false;
    }

    _setLoading(true);
    try {
      await _reservaService.actualizarEstado(reserva.id, EstadoReserva.rechazado);

      // Le avisamos al estudiante para que sepa que no fue aprobado
      await _notificacionService.notificarSolicitudRechazada(
        estudianteId: reserva.estudianteId,
        nombrePaquete: reserva.paqueteId,
        motivo: motivo,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error rechazando solicitud: $e');
      _setLoading(false);
      return false;
    }
  }

  // El operador rechaza el comprobante de pago.
  // La reserva vuelve a "aceptado" para que el estudiante pueda subir uno nuevo sin perder el cupo.
  Future<bool> rechazarPago(Reserva reserva, Usuario operador, {String? motivo}) async {
    if (!operador.isOperador || reserva.estadoActual != EstadoReserva.verificandoPago) {
      debugPrint('Rechazo de pago no permitido: rol=${operador.rol}, estado=${reserva.estadoActual}');
      return false;
    }

    _setLoading(true);
    try {
      // Regresamos a "aceptado" en lugar de "rechazado" para no perder el cupo
      await _reservaService.actualizarEstado(reserva.id, EstadoReserva.aceptado);

      // Le avisamos al estudiante que debe subir un comprobante válido
      await _notificacionService.notificarPagoRechazado(
        estudianteId: reserva.estudianteId,
        nombrePaquete: reserva.paqueteId,
        motivo: motivo,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error rechazando pago: $e');
      _setLoading(false);
      return false;
    }
  }

  // El estudiante sube el comprobante y la reserva pasa a "verificandoPago"
  Future<bool> subirComprobanteYVerificar(Reserva reserva, String comprobanteUrl, Usuario actor) async {
    if (!actor.isEstudiante || reserva.estadoActual != EstadoReserva.aceptado) {
      return false;
    }

    _setLoading(true);
    try {
      await _reservaService.subirComprobante(reserva.id, comprobanteUrl);
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error subiendo comprobante: $e');
      _setLoading(false);
      return false;
    }
  }

  // Escucha en tiempo real las reservas del estudiante autenticado
  Stream<List<Reserva>> obtenerMisReservasEstudiante(String estudianteId) {
    return _reservaService.obtenerReservasEstudiante(estudianteId);
  }

  // Escucha en tiempo real las reservas de los paquetes del operador autenticado
  Stream<List<Reserva>> obtenerReservasDeMisPaquetes(List<String> misPaquetesIds) {
    return _reservaService.obtenerReservasPorPaquetes(misPaquetesIds);
  }
}