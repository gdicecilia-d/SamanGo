import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notificacion.dart';

class NotificacionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtener stream de notificaciones
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

  // Marcar como leída
  Future<void> marcarComoLeida(String userId, String notificacionId, {String collection = 'estudiantes'}) async {
    await _db
        .collection(collection)
        .doc(userId)
        .collection('notificaciones')
        .doc(notificacionId)
        .update({'leida': true});
  }

  // Eliminar notificación
  Future<void> eliminarNotificacion(String userId, String notificacionId, {String collection = 'estudiantes'}) async {
    await _db
        .collection(collection)
        .doc(userId)
        .collection('notificaciones')
        .doc(notificacionId)
        .delete();
  }

  // Enviar notificación a un operador específico
  Future<void> notificarOperador({
    required String operadorId,
    required String titulo,
    required String mensaje,
    String? idPaquete,
  }) async {
    final notifRef = _db
        .collection('operadores')
        .doc(operadorId)
        .collection('notificaciones')
        .doc();
    
    final notificacion = Notificacion(
      id: notifRef.id,
      titulo: titulo,
      mensaje: mensaje,
      fechaCreacion: DateTime.now(),
      leida: false,
      tipo: 'alerta_operador',
      idPaquete: idPaquete,
    );
    
    await notifRef.set(notificacion.toMap());
  }

  // Enviar notificación a todos los estudiantes (Batch)
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

  // Enviar notificación de nuevo paquete a todos los estudiantes
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