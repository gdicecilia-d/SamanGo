import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<String> _obtenerNombrePaquete(String paqueteId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('destinos').doc(paqueteId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['nombre'] as String? ?? 'un destino';
      }
    } catch (e) {
      debugPrint('Error obteniendo nombre del paquete: $e');
    }
    return 'un destino';
  }

  Future<bool> _verificarCuposDisponibles(String paqueteId, int personasRequeridas) async {
    final cupos = await _reservaService.obtenerCuposDisponibles(paqueteId);
    return cupos >= personasRequeridas;
  }

  Future<bool> cambiarEstadoReserva(Reserva reserva, EstadoReserva nuevoEstado, Usuario actor) async {
    final EstadoReserva estadoActual = reserva.estadoActual;
    bool esTransicionValida = false;

    if (actor.isEstudiante) {
      if (estadoActual == EstadoReserva.aceptado && nuevoEstado == EstadoReserva.verificandoPago) {
        esTransicionValida = true;
      }
    } else if (actor.isOperador) {
      if (estadoActual == EstadoReserva.solicitado && nuevoEstado == EstadoReserva.aceptado) {
        esTransicionValida = true;
      } else if (estadoActual == EstadoReserva.verificandoPago && nuevoEstado == EstadoReserva.pagado) {
        esTransicionValida = true;
      } else if (estadoActual == EstadoReserva.pagado && nuevoEstado == EstadoReserva.disfrutado) {
        esTransicionValida = true;
      }
    }

    if (!esTransicionValida) {
      debugPrint('Transición no válida: $estadoActual → $nuevoEstado por rol ${actor.rol}');
      return false;
    }

    if (actor.isOperador && nuevoEstado == EstadoReserva.aceptado) {
      final hayCupos = await _verificarCuposDisponibles(reserva.paqueteId, reserva.numeroPersonas);
      if (!hayCupos) {
        debugPrint('No hay suficientes cupos para ${reserva.numeroPersonas} personas en el paquete ${reserva.paqueteId}');
        return false;
      }
    }

    _setLoading(true);
    try {
      if (actor.isOperador && nuevoEstado == EstadoReserva.aceptado) {
        final cupoDescontado = await _reservaService.descontarCupo(
          reserva.paqueteId,
          cantidad: reserva.numeroPersonas,
        );
        if (!cupoDescontado) {
          _setLoading(false);
          return false;
        }
      }

      await _reservaService.actualizarEstado(reserva.id, nuevoEstado);

      if (actor.isOperador) {
        final nombrePaquete = await _obtenerNombrePaquete(reserva.paqueteId);
        
        if (nuevoEstado == EstadoReserva.aceptado) {
          await _notificacionService.notificarSolicitudAceptada(
            estudianteId: reserva.estudianteId,
            nombrePaquete: nombrePaquete,
            reservaId: reserva.id,
          );
        } else if (nuevoEstado == EstadoReserva.pagado) {
          await _notificacionService.notificarPagoConfirmado(
            estudianteId: reserva.estudianteId,
            nombrePaquete: nombrePaquete,
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

  Future<bool> rechazarSolicitud(Reserva reserva, Usuario operador, {String? motivo}) async {
    if (!operador.isOperador || reserva.estadoActual != EstadoReserva.solicitado) {
      debugPrint('Rechazo no permitido: rol=${operador.rol}, estado=${reserva.estadoActual}');
      return false;
    }

    _setLoading(true);
    try {
      await _reservaService.actualizarEstado(reserva.id, EstadoReserva.rechazado);

      final nombrePaquete = await _obtenerNombrePaquete(reserva.paqueteId);

      await _notificacionService.notificarSolicitudRechazada(
        estudianteId: reserva.estudianteId,
        nombrePaquete: nombrePaquete,
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

  Future<bool> rechazarPago(Reserva reserva, Usuario operador, {String? motivo}) async {
    if (!operador.isOperador || reserva.estadoActual != EstadoReserva.verificandoPago) {
      debugPrint('Rechazo de pago no permitido: rol=${operador.rol}, estado=${reserva.estadoActual}');
      return false;
    }

    _setLoading(true);
    try {
      await _reservaService.actualizarEstado(reserva.id, EstadoReserva.aceptado);

      final nombrePaquete = await _obtenerNombrePaquete(reserva.paqueteId);

      await _notificacionService.notificarPagoRechazado(
        estudianteId: reserva.estudianteId,
        nombrePaquete: nombrePaquete,
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

  Future<int> obtenerCuposDisponibles(String paqueteId) async {
    return await _reservaService.obtenerCuposDisponibles(paqueteId);
  }

  Future<bool> cancelarReserva(Reserva reserva, Usuario estudiante) async {
    if (!estudiante.isEstudiante) return false;

    _setLoading(true);
    try {
      await _reservaService.actualizarEstado(reserva.id, EstadoReserva.cancelado);

      if (reserva.estadoActual == EstadoReserva.aceptado ||
          reserva.estadoActual == EstadoReserva.verificandoPago ||
          reserva.estadoActual == EstadoReserva.pagado) {
        await _reservaService.restaurarCupo(
          reserva.paqueteId,
          cantidad: reserva.numeroPersonas,
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error cancelando reserva: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> cancelarPorTimeout(Reserva reserva, Usuario operador) async {
    if (!operador.isOperador) return false;

    _setLoading(true);
    try {
      await _reservaService.actualizarEstado(reserva.id, EstadoReserva.cancelado);

      await _reservaService.restaurarCupo(
        reserva.paqueteId,
        cantidad: reserva.numeroPersonas,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error cancelando reserva por timeout: $e');
      _setLoading(false);
      return false;
    }
  }

  Stream<List<Reserva>> obtenerMisReservasEstudiante(String estudianteId) {
    return _reservaService.obtenerReservasEstudiante(estudianteId);
  }

  Stream<List<Reserva>> obtenerReservasDeMisPaquetes(List<String> misPaquetesIds) {
    return _reservaService.obtenerReservasPorPaquetes(misPaquetesIds);
  }
}