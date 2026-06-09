import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notificacion.dart';
import '../services/notificacion_service.dart';

class NotificacionController extends ChangeNotifier {
  final NotificacionService _service = NotificacionService();
  StreamSubscription<List<Notificacion>>? _subscription;
  String? _estudianteId;
  String _collectionName = 'estudiantes';
  
  List<Notificacion> _notificaciones = [];
  List<Notificacion> get notificaciones => _notificaciones;

  int get noLeidasCount => _notificaciones.where((n) => !n.leida).length;

  // Iniciar escucha
  void listenToNotificaciones(String userId, {String collectionName = 'estudiantes'}) {
    _estudianteId = userId;
    _collectionName = collectionName;
    _subscription?.cancel();
    _subscription = _service.streamNotificaciones(userId, collection: collectionName).listen((data) {
      _notificaciones = data;
      notifyListeners();
    });
  }

  // Marcar leída
  Future<void> marcarComoLeida(String notificacionId) async {
    if (_estudianteId == null) return;
    try {
      // Optimistic update
      final index = _notificaciones.indexWhere((n) => n.id == notificacionId);
      if (index != -1) {
        _notificaciones[index] = Notificacion(
          id: _notificaciones[index].id,
          titulo: _notificaciones[index].titulo,
          mensaje: _notificaciones[index].mensaje,
          fechaCreacion: _notificaciones[index].fechaCreacion,
          leida: true,
          tipo: _notificaciones[index].tipo,
          idPaquete: _notificaciones[index].idPaquete,
        );
        notifyListeners();
      }
      await _service.marcarComoLeida(_estudianteId!, notificacionId, collection: _collectionName);
    } catch (e) {
      print('Error al marcar leída: $e');
    }
  }

  // Detener escucha
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
