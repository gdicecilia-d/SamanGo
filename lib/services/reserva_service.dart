import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reserva.dart';
import '../models/estado_reserva.dart';

class ReservaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Reserva> crearReserva(Reserva reserva) async {
    final docRef = _firestore.collection('reservas').doc();
    
    // Configurar historial inicial
    final Map<String, dynamic> historialInicial = {
      EstadoReserva.solicitado.toMap(): FieldValue.serverTimestamp(),
    };
    
    final nuevaReserva = reserva.copyWith(
      historial: historialInicial,
    );

    await docRef.set(nuevaReserva.toMap());
    
    return nuevaReserva.copyWith(id: docRef.id);
  }

  Future<void> actualizarEstado(String reservaId, EstadoReserva nuevoEstado) async {
    await _firestore.collection('reservas').doc(reservaId).update({
      'estadoActual': nuevoEstado.toMap(),
      'historial.${nuevoEstado.toMap()}': FieldValue.serverTimestamp(),
    });
  }
  
  Future<void> subirComprobante(String reservaId, String comprobanteUrl) async {
    await _firestore.collection('reservas').doc(reservaId).update({
      'comprobanteUrl': comprobanteUrl,
      'estadoActual': EstadoReserva.verificandoPago.toMap(),
      'historial.${EstadoReserva.verificandoPago.toMap()}': FieldValue.serverTimestamp(),
    });
  }

  // Streams para obtener reservas de un estudiante
  Stream<List<Reserva>> obtenerReservasEstudiante(String estudianteId) {
    if (estudianteId.isEmpty) return const Stream.empty();
    return _firestore
        .collection('reservas')
        .where('estudianteId', isEqualTo: estudianteId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reserva.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Stream para obtener reservas de los paquetes de un operador
  Stream<List<Reserva>> obtenerReservasPorPaquetes(List<String> paquetesIds) {
    if (paquetesIds.isEmpty) return const Stream.empty();
    
    // Nota: Firestore limita el in (whereIn) a 10 elementos.
    // Para escalar, en un entorno real, se agruparía en chunks.
    return _firestore
        .collection('reservas')
        .where('paqueteId', whereIn: paquetesIds.take(10).toList())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reserva.fromMap(doc.id, doc.data()))
            .toList());
  }
}
