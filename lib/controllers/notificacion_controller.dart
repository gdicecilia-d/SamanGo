import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  void listenToNotificaciones(String userId, {String collectionName = 'estudiantes'}) {
    _estudianteId = userId;
    _collectionName = collectionName;
    _subscription?.cancel();
    
    // Limpiar tips que tengan más de 24 horas antes de suscribirse
    _service.limpiarTipsAntiguos(userId, collection: collectionName);
    
    _subscription = _service.streamNotificaciones(userId, collection: collectionName).listen((data) {
      _notificaciones = data;
      notifyListeners();
    });
  }

  Future<void> marcarComoLeida(String notificacionId) async {
    if (_estudianteId == null) return;
    try {
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

  Future<void> eliminarNotificacion(String notificacionId) async {
    if (_estudianteId == null) return;
    try {
      _notificaciones.removeWhere((n) => n.id == notificacionId);
      notifyListeners();
      await _service.eliminarNotificacion(_estudianteId!, notificacionId, collection: _collectionName);
    } catch (e) {
      print('Error al eliminar notificación: $e');
    }
  }

  Future<void> eliminarTodasNotificaciones() async {
    if (_estudianteId == null) return;
    try {
      _notificaciones.clear();
      notifyListeners();
      await _service.eliminarTodasNotificaciones(_estudianteId!, collection: _collectionName);
    } catch (e) {
      print('Error al eliminar todas las notificaciones: $e');
    }
  }

  Future<String?> obtenerNombreRealDestino(String id) async {
    try {
      final db = FirebaseFirestore.instance;
      // Intentar como destino
      final destinoDoc = await db.collection('destinos').doc(id).get();
      if (destinoDoc.exists) return destinoDoc.data()?['nombre'] as String?;
      
      // Si no existe, intentar como reserva
      final reservaDoc = await db.collection('reservas').doc(id).get();
      if (reservaDoc.exists) {
        final paqueteId = reservaDoc.data()?['paqueteId'] as String?;
        if (paqueteId != null) {
          final destDoc = await db.collection('destinos').doc(paqueteId).get();
          if (destDoc.exists) return destDoc.data()?['nombre'] as String?;
        }
      }
    } catch (e) {
      print('Error al obtener nombre real del destino: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
