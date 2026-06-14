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

  // ── NOTIFICACIONES AL OPERADOR ───────────────────────────────────────────
  // Se disparan cuando el estudiante realiza una acción sobre su reserva.

  // El estudiante solicitó un cupo: el operador debe revisarlo en "Solicitudes"
  Future<void> notificarNuevaSolicitud({
    required String operadorId,
    required String estudianteNombre,
    required String estudianteApellido,
    required String estudianteCarnet,
    required String nombrePaquete,
    required String reservaId,
  }) async {
    final mensaje = '📋 $estudianteNombre $estudianteApellido (Carnet: $estudianteCarnet) ha solicitado cupo para el paquete "$nombrePaquete".';

    await _crearNotificacion(
      coleccion: 'operadores',
      userId: operadorId,
      titulo: '🆕 Nueva solicitud de cupo',
      mensaje: mensaje,
      tipo: 'nueva_solicitud',
      idPaquete: reservaId,
    );
  }

  // El estudiante canceló antes de ser procesado: el cupo queda libre
  Future<void> notificarCancelacion({
    required String operadorId,
    required String estudianteNombre,
    required String estudianteApellido,
    required String estudianteCarnet,
    required String nombrePaquete,
  }) async {
    final mensaje = '❌ $estudianteNombre $estudianteApellido (Carnet: $estudianteCarnet) ha cancelado su solicitud para el paquete "$nombrePaquete".';

    await _crearNotificacion(
      coleccion: 'operadores',
      userId: operadorId,
      titulo: '❌ Solicitud cancelada',
      mensaje: mensaje,
      tipo: 'cancelacion',
    );
  }

  // El estudiante subió el comprobante: el operador debe verificarlo en "Pagos"
  Future<void> notificarPagoRecibido({
    required String operadorId,
    required String estudianteNombre,
    required String estudianteApellido,
    required String estudianteCarnet,
    required String nombrePaquete,
  }) async {
    final mensaje = '💵 $estudianteNombre $estudianteApellido (Carnet: $estudianteCarnet) ha enviado el comprobante de pago para "$nombrePaquete". Revísalo en la pestaña Pagos.';

    await _crearNotificacion(
      coleccion: 'operadores',
      userId: operadorId,
      titulo: '💰 Comprobante de pago recibido',
      mensaje: mensaje,
      tipo: 'pago_recibido',
    );
  }

  // El estudiante cambió la fecha de su reserva pagada: el operador debe ajustar su logística
  Future<void> notificarCambioFecha({
    required String operadorId,
    required String estudianteNombre,
    required String estudianteApellido,
    required String estudianteCarnet,
    required String nombrePaquete,
    required DateTime nuevaFecha,
  }) async {
    final fechaStr = '${nuevaFecha.day}/${nuevaFecha.month}/${nuevaFecha.year}';
    final mensaje = '📅 $estudianteNombre $estudianteApellido (Carnet: $estudianteCarnet) modificó la fecha del paquete "$nombrePaquete" al $fechaStr.';

    await _crearNotificacion(
      coleccion: 'operadores',
      userId: operadorId,
      titulo: '📅 Fecha de reserva modificada',
      mensaje: mensaje,
      tipo: 'cambio_fecha',
    );
  }

  // ── NOTIFICACIONES AL ESTUDIANTE ─────────────────────────────────────────
  // Se disparan cuando el operador toma una decisión sobre la reserva.

  // El operador aceptó la solicitud: el estudiante ya puede pagar
  Future<void> notificarSolicitudAceptada({
    required String estudianteId,
    required String nombrePaquete,
    required String reservaId,
  }) async {
    final mensaje = '✅ ¡Buenas noticias! Tu solicitud para "$nombrePaquete" fue aceptada. Puedes proceder al pago desde "Mis Viajes".';

    await _crearNotificacion(
      coleccion: 'estudiantes',
      userId: estudianteId,
      titulo: '✅ Solicitud aceptada',
      mensaje: mensaje,
      tipo: 'solicitud_aceptada',
      idPaquete: reservaId,
    );
  }

  // El operador rechazó la solicitud: se incluye el motivo si fue proporcionado
  Future<void> notificarSolicitudRechazada({
    required String estudianteId,
    required String nombrePaquete,
    String? motivo,
  }) async {
    final motivoTexto = motivo != null && motivo.isNotEmpty ? ' Motivo: $motivo.' : '';
    final mensaje = '❌ Tu solicitud para "$nombrePaquete" fue rechazada.$motivoTexto';

    await _crearNotificacion(
      coleccion: 'estudiantes',
      userId: estudianteId,
      titulo: '❌ Solicitud rechazada',
      mensaje: mensaje,
      tipo: 'solicitud_rechazada',
    );
  }

  // El operador confirmó el pago: el cupo queda asegurado
  Future<void> notificarPagoConfirmado({
    required String estudianteId,
    required String nombrePaquete,
    required String reservaId,
  }) async {
    final mensaje = '🎉 Tu pago para "$nombrePaquete" fue confirmado. ¡Tu cupo está asegurado!';

    await _crearNotificacion(
      coleccion: 'estudiantes',
      userId: estudianteId,
      titulo: '🎉 Pago confirmado',
      mensaje: mensaje,
      tipo: 'pago_confirmado',
      idPaquete: reservaId,
    );
  }

  // El operador rechazó el comprobante: el estudiante debe subir uno nuevo
  Future<void> notificarPagoRechazado({
    required String estudianteId,
    required String nombrePaquete,
    String? motivo,
  }) async {
    final motivoTexto = motivo != null && motivo.isNotEmpty ? ' Motivo: $motivo.' : '';
    final mensaje = '⚠️ Tu comprobante para "$nombrePaquete" fue rechazado.$motivoTexto Sube uno nuevo desde "Mis Viajes".';

    await _crearNotificacion(
      coleccion: 'estudiantes',
      userId: estudianteId,
      titulo: '⚠️ Comprobante rechazado',
      mensaje: mensaje,
      tipo: 'pago_rechazado',
    );
  }

  // ── NOTIFICACIONES MASIVAS ───────────────────────────────────────────────

  // Envía una notificación a todos los estudiantes.
  // Usa WriteBatch en grupos de 490 para no superar el límite de 500 de Firestore.
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

  // ── HELPER PRIVADO ───────────────────────────────────────────────────────

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