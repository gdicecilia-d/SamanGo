import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notificacion.dart';

class NotificacionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Notificacion>> streamNotificaciones(String userId, {String collection = 'estudiantes'}) {
    return _db
        .collection(collection)
        .doc(userId)
        .collection('notificaciones')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Notificacion.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> marcarComoLeida(String userId, String notificacionId, {String collection = 'estudiantes'}) async {
    await _db
        .collection(collection)
        .doc(userId)
        .collection('notificaciones')
        .doc(notificacionId)
        .update({'leida': true});
  }

  Future<void> eliminarNotificacion(String userId, String notificacionId, {String collection = 'estudiantes'}) async {
    await _db
        .collection(collection)
        .doc(userId)
        .collection('notificaciones')
        .doc(notificacionId)
        .delete();
  }

  // Notificar Nueva Solicitud 
  Future<void> notificarNuevaSolicitud({
    required String operadorId,
    required String estudianteNombre,
    required String estudianteApellido,
    required String estudianteCarnet,
    required String nombrePaquete,
    required String reservaId,
  }) async {
    final mensaje = '📋 $estudianteNombre $estudianteApellido (Carnet: $estudianteCarnet) ha solicitado cupo para el paquete "$nombrePaquete".';
    
    final notifRef = _db
        .collection('operadores')
        .doc(operadorId)
        .collection('notificaciones')
        .doc();
    
    final notificacion = Notificacion(
      id: notifRef.id,
      titulo: '🆕 Nueva solicitud de cupo',
      mensaje: mensaje,
      fechaCreacion: DateTime.now(),
      leida: false,
      tipo: 'nueva_solicitud',
      idPaquete: reservaId,
    );
    
    await notifRef.set(notificacion.toMap());
  }

  // Notificar Cancelación 
  Future<void> notificarCancelacion({
    required String operadorId,
    required String estudianteNombre,
    required String estudianteApellido,
    required String estudianteCarnet,
    required String nombrePaquete,
  }) async {
    final mensaje = '❌ $estudianteNombre $estudianteApellido (Carnet: $estudianteCarnet) ha cancelado su solicitud para el paquete "$nombrePaquete".';
    
    final notifRef = _db
        .collection('operadores')
        .doc(operadorId)
        .collection('notificaciones')
        .doc();
    
    final notificacion = Notificacion(
      id: notifRef.id,
      titulo: '❌ Solicitud cancelada',
      mensaje: mensaje,
      fechaCreacion: DateTime.now(),
      leida: false,
      tipo: 'cancelacion',
      idPaquete: null,
    );
    
    await notifRef.set(notificacion.toMap());
  }

  // Notificar Pago Recibido 
  Future<void> notificarPagoRecibido({
    required String operadorId,
    required String estudianteNombre,
    required String estudianteApellido,
    required String estudianteCarnet,
    required String nombrePaquete,
  }) async {
    final mensaje = '💵 $estudianteNombre $estudianteApellido (Carnet: $estudianteCarnet) ha realizado el pago para el paquete "$nombrePaquete". El cupo está ahora confirmado.';
    
    final notifRef = _db
        .collection('operadores')
        .doc(operadorId)
        .collection('notificaciones')
        .doc();
    
    final notificacion = Notificacion(
      id: notifRef.id,
      titulo: '💰 Pago confirmado',
      mensaje: mensaje,
      fechaCreacion: DateTime.now(),
      leida: false,
      tipo: 'pago_recibido',
      idPaquete: null,
    );
    
    await notifRef.set(notificacion.toMap());
  }

  // Notificar Cambio de Fecha 
  Future<void> notificarCambioFecha({
    required String operadorId,
    required String estudianteNombre,
    required String estudianteApellido,
    required String estudianteCarnet,
    required String nombrePaquete,
    required DateTime nuevaFecha,
  }) async {
    final fechaStr = '${nuevaFecha.day}/${nuevaFecha.month}/${nuevaFecha.year}';
    final mensaje = '📅 $estudianteNombre $estudianteApellido (Carnet: $estudianteCarnet) ha modificado la fecha del paquete "$nombrePaquete" para el $fechaStr.';
    
    final notifRef = _db
        .collection('operadores')
        .doc(operadorId)
        .collection('notificaciones')
        .doc();
    
    final notificacion = Notificacion(
      id: notifRef.id,
      titulo: '📅 Fecha modificada',
      mensaje: mensaje,
      fechaCreacion: DateTime.now(),
      leida: false,
      tipo: 'cambio_fecha',
      idPaquete: null,
    );
    
    await notifRef.set(notificacion.toMap());
  }

  // Notificar a estudiantes (general)
  Future<void> notificarAEstudiantes({
    required String titulo,
    required String mensaje,
    String? idPaquete,
    String tipo = 'general',
  }) async {
    final estudiantesQuery = await _db.collection('estudiantes').get();
    
    if (estudiantesQuery.docs.isEmpty) return;
    
    WriteBatch batch = _db.batch();
    int count = 0;

    for (var doc in estudiantesQuery.docs) {
      final notifRef = doc.reference.collection('notificaciones').doc();
      final notificacion = Notificacion(
        id: notifRef.id,
        titulo: titulo,
        mensaje: mensaje,
        fechaCreacion: DateTime.now(),
        leida: false,
        tipo: tipo,
        idPaquete: idPaquete,
      );
      
      batch.set(notifRef, notificacion.toMap());
      count++;

      if (count >= 490) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  // Notificar nuevo paquete a estudiantes
  Future<void> notificarNuevoPaquete({
    required String nombrePaquete,
    required String idPaquete,
  }) async {
    await notificarAEstudiantes(
      titulo: '🎉 ¡Nuevo destino disponible!',
      mensaje: 'Se ha publicado "$nombrePaquete". ¡No te lo pierdas!',
      idPaquete: idPaquete,
      tipo: 'paquete',
    );
  }
}