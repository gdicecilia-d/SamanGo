import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notificacion.dart';

class NotificacionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtener stream de notificaciones de un estudiante
  Stream<List<Notificacion>> streamNotificaciones(String estudianteId) {
    return _db
        .collection('estudiantes')
        .doc(estudianteId)
        .collection('notificaciones')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Notificacion.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Marcar como leída
  Future<void> marcarComoLeida(String estudianteId, String notificacionId) async {
    await _db
        .collection('estudiantes')
        .doc(estudianteId)
        .collection('notificaciones')
        .doc(notificacionId)
        .update({'leida': true});
  }

  // Eliminar notificación
  Future<void> eliminarNotificacion(String estudianteId, String notificacionId) async {
    await _db
        .collection('estudiantes')
        .doc(estudianteId)
        .collection('notificaciones')
        .doc(notificacionId)
        .delete();
  }

  // Enviar notificación a todos los estudiantes (Batch)
  Future<void> notificarNuevoPaquete({
    required String titulo,
    required String mensaje,
    required String idPaquete,
  }) async {
    final estudiantesQuery = await _db.collection('estudiantes').get();
    
    // Firestore permite hasta 500 escrituras por batch
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
        tipo: 'paquete',
        idPaquete: idPaquete,
      );
      
      batch.set(notifRef, notificacion.toMap());
      count++;

      // Ejecutar si llegamos al límite de Firebase
      if (count == 500) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }
}
