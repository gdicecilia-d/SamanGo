import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notificacion.dart';

class NotificacionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Escucha las notificaciones de un usuario en tiempo real
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

  // Marca una notificación como leída para quitar el badge
  Future<void> marcarComoLeida(String userId, String notificacionId, {String collection = 'estudiantes'}) async {
    await _db
        .collection(collection)
        .doc(userId)
        .collection('notificaciones')
        .doc(notificacionId)
        .update({'leida': true});
  }

  // Elimina una notificación del historial del usuario
  Future<void> eliminarNotificacion(String userId, String notificacionId, {String collection = 'estudiantes'}) async {
    await _db
        .collection(collection)
        .doc(userId)
        .collection('notificaciones')
        .doc(notificacionId)
        .delete();
  }

  // Elimina todas las notificaciones de un usuario
  Future<void> eliminarTodasNotificaciones(String userId, {String collection = 'estudiantes'}) async {
    try {
      final snapshot = await _db
          .collection(collection)
          .doc(userId)
          .collection('notificaciones')
          .get();
          
      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error al eliminar todas las notificaciones: $e');
    }
  }

  // Elimina los tips que tengan más de 24 horas de antigüedad
  Future<void> limpiarTipsAntiguos(String userId, {String collection = 'estudiantes'}) async {
    final hace24Horas = DateTime.now().subtract(const Duration(hours: 24));
    
    try {
      final snapshot = await _db
          .collection(collection)
          .doc(userId)
          .collection('notificaciones')
          .where('tipo', isEqualTo: 'tip')
          .get();
          
      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        final fecha = (doc.data()['fechaCreacion'] as Timestamp?)?.toDate();
        if (fecha != null && fecha.isBefore(hace24Horas)) {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
    } catch (e) {
      print('Error al limpiar tips antiguos: $e');
    }
  }

  // Notificaciones del operador

  Future<void> notificarNuevaSolicitud({
    required String operadorId,
    required String estudianteNombre,
    required String estudianteApellido,
    required String estudianteCarnet,
    required String nombrePaquete,
    required String reservaId,
  }) async {
    final mensaje = '$estudianteNombre $estudianteApellido (Carnet: $estudianteCarnet) ha solicitado cupo para el paquete "$nombrePaquete".';

    await _crearNotificacion(
      coleccion: 'operadores',
      userId: operadorId,
      titulo: '🆕 Nueva solicitud de cupo',
      mensaje: mensaje,
      tipo: 'nueva_solicitud',
      idPaquete: reservaId,
    );
  }

  Future<void> notificarCancelacion({
    required String operadorId,
    required String estudianteNombre,
    required String estudianteApellido,
    required String estudianteCarnet,
    required String nombrePaquete,
  }) async {
    final mensaje = '$estudianteNombre $estudianteApellido (Carnet: $estudianteCarnet) ha cancelado su solicitud para el paquete "$nombrePaquete".';

    await _crearNotificacion(
      coleccion: 'operadores',
      userId: operadorId,
      titulo: '❌ Solicitud cancelada',
      mensaje: mensaje,
      tipo: 'cancelacion',
    );
  }


  Future<void> notificarPagoRecibido({
    required String operadorId,
    required String estudianteNombre,
    required String estudianteApellido,
    required String estudianteCarnet,
    required String nombrePaquete,
  }) async {
    final mensaje = '$estudianteNombre $estudianteApellido (Carnet: $estudianteCarnet) ha enviado el comprobante de pago para "$nombrePaquete". Revísalo en la pestaña Pagos.';

    await _crearNotificacion(
      coleccion: 'operadores',
      userId: operadorId,
      titulo: '💰 Comprobante de pago recibido',
      mensaje: mensaje,
      tipo: 'pago_recibido',
    );
  }

  Future<void> notificarCambioFecha({
    required String operadorId,
    required String estudianteNombre,
    required String estudianteApellido,
    required String estudianteCarnet,
    required String nombrePaquete,
    required DateTime nuevaFecha,
  }) async {
    final fechaStr = '${nuevaFecha.day}/${nuevaFecha.month}/${nuevaFecha.year}';
    final mensaje = '$estudianteNombre $estudianteApellido (Carnet: $estudianteCarnet) modificó la fecha del paquete "$nombrePaquete" al $fechaStr.';

    await _crearNotificacion(
      coleccion: 'operadores',
      userId: operadorId,
      titulo: '📅 Fecha de reserva modificada',
      mensaje: mensaje,
      tipo: 'cambio_fecha',
    );
  }

  // Notificaciones para el estudiante

  Future<void> notificarSolicitudAceptada({
    required String estudianteId,
    required String nombrePaquete,
    required String reservaId,
  }) async {
    final mensaje = '¡Buenas noticias! Tu solicitud para "$nombrePaquete" fue aceptada. Puedes proceder al pago desde "Mis Viajes".';

    await _crearNotificacion(
      coleccion: 'estudiantes',
      userId: estudianteId,
      titulo: '✅ Solicitud aceptada',
      mensaje: mensaje,
      tipo: 'solicitud_aceptada',
      idPaquete: reservaId,
    );
  }


  Future<void> notificarSolicitudRechazada({
    required String estudianteId,
    required String nombrePaquete,
    String? motivo,
  }) async {
    final motivoTexto = motivo != null && motivo.isNotEmpty ? ' Motivo: $motivo.' : '';
    final mensaje = 'Tu solicitud para "$nombrePaquete" fue rechazada.$motivoTexto';

    await _crearNotificacion(
      coleccion: 'estudiantes',
      userId: estudianteId,
      titulo: '❌ Solicitud rechazada',
      mensaje: mensaje,
      tipo: 'solicitud_rechazada',
    );
  }

  Future<void> notificarPagoConfirmado({
    required String estudianteId,
    required String nombrePaquete,
    required String reservaId,
  }) async {
    final mensaje = 'Tu pago para "$nombrePaquete" fue confirmado. ¡Tu cupo está asegurado!';

    await _crearNotificacion(
      coleccion: 'estudiantes',
      userId: estudianteId,
      titulo: '🎉 Pago confirmado',
      mensaje: mensaje,
      tipo: 'pago_confirmado',
      idPaquete: reservaId,
    );
  }

  Future<void> notificarPagoRechazado({
    required String estudianteId,
    required String nombrePaquete,
    String? motivo,
  }) async {
    final motivoTexto = motivo != null && motivo.isNotEmpty ? ' Motivo: $motivo.' : '';
    final mensaje = 'Tu comprobante para "$nombrePaquete" fue rechazado.$motivoTexto Sube uno nuevo desde "Mis Viajes".';

    await _crearNotificacion(
      coleccion: 'estudiantes',
      userId: estudianteId,
      titulo: '⚠️ Comprobante rechazado',
      mensaje: mensaje,
      tipo: 'pago_rechazado',
    );
  }

  // Notificaciones generales 

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

    if (count > 0) await batch.commit();
  }

  // Avisa a todos los estudiantes que hay un nuevo paquete disponible
  Future<void> notificarNuevoPaquete({
    required String nombrePaquete,
    required String idPaquete,
  }) async {
    await notificarAEstudiantes(
      titulo: '🎉 ¡Nuevo destino disponible!',
      mensaje: 'Se publicó "$nombrePaquete". ¡No te lo pierdas!',
      idPaquete: idPaquete,
      tipo: 'paquete',
    );
  }

  // Helper privado 

  // Crea el documento de notificación en Firestore.
  // Todos los métodos públicos lo usan para no repetir la misma lógica.
  Future<void> _crearNotificacion({
    required String coleccion,
    required String userId,
    required String titulo,
    required String mensaje,
    required String tipo,
    String? idPaquete,
  }) async {
    final notifRef = _db.collection(coleccion).doc(userId).collection('notificaciones').doc();

    final notificacion = Notificacion(
      id: notifRef.id,
      titulo: titulo,
      mensaje: mensaje,
      fechaCreacion: DateTime.now(),
      leida: false,
      tipo: tipo,
      idPaquete: idPaquete,
    );

    await notifRef.set(notificacion.toMap());
  }
}