import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../models/estado_reserva.dart';
import '../models/usuario.dart';
import '../services/reserva_service.dart';

class ReservaController extends ChangeNotifier {
  final ReservaService _reservaService = ReservaService();
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

  Future<bool> cambiarEstadoReserva(Reserva reserva, EstadoReserva nuevoEstado, Usuario actor) async {
    // Validaciones de máquina de estado (restricciones por rol)
    final bool esEstudiante = actor.isEstudiante;
    final bool esOperador = actor.isOperador;
    final EstadoReserva estadoActual = reserva.estadoActual;

    bool esTransicionValida = false;

    if (esEstudiante) {
      // Estudiante envía comprobante (Aceptado -> VerificandoPago)
      if (estadoActual == EstadoReserva.aceptado && nuevoEstado == EstadoReserva.verificandoPago) {
        esTransicionValida = true;
      }
    } else if (esOperador) {
      // Operador puede aceptar/rechazar solicitud
      if (estadoActual == EstadoReserva.solicitado && nuevoEstado == EstadoReserva.aceptado) {
        esTransicionValida = true;
      }
      // Operador puede aceptar comprobante de pago
      else if (estadoActual == EstadoReserva.verificandoPago && nuevoEstado == EstadoReserva.pagado) {
        esTransicionValida = true;
      }
      // Operador (o un cronjob) marca como disfrutado
      else if (estadoActual == EstadoReserva.pagado && nuevoEstado == EstadoReserva.disfrutado) {
        esTransicionValida = true;
      }
    }

    if (!esTransicionValida) {
      debugPrint('Transición no válida: $estadoActual -> $nuevoEstado por rol ${actor.rol}');
      return false;
    }

    _setLoading(true);
    try {
      await _reservaService.actualizarEstado(reserva.id, nuevoEstado);
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error actualizando reserva: $e');
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

  Stream<List<Reserva>> obtenerMisReservasEstudiante(String estudianteId) {
    return _reservaService.obtenerReservasEstudiante(estudianteId);
  }

  Stream<List<Reserva>> obtenerReservasDeMisPaquetes(List<String> misPaquetesIds) {
    return _reservaService.obtenerReservasPorPaquetes(misPaquetesIds);
  }
}
