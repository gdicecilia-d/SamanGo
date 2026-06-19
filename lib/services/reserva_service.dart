import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reserva.dart';
import '../models/estado_reserva.dart';

class ReservaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Reserva> crearReserva(Reserva reserva) async {
    final docRef = _firestore.collection('reservas').doc();
    
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

  Future<bool> descontarCupo(String paqueteId, {int cantidad = 1}) async {
    try {
      final destinoRef = _firestore.collection('destinos').doc(paqueteId);
      
      final doc = await destinoRef.get();
      if (!doc.exists) {
        return false;
      }
      
      final data = doc.data() as Map<String, dynamic>?;
      final cuposDisponibles = data?['cuposDisponibles'] as int? ?? 0;
      
      if (cuposDisponibles < cantidad) {
        return false;
      }
      
      await destinoRef.update({
        'cuposDisponibles': FieldValue.increment(-cantidad),
      });
      
      return true;
    } catch (e) {
      print('Error descontando cupo: $e');
      return false;
    }
  }

  Future<int> obtenerCuposDisponibles(String paqueteId) async {
    try {
      final doc = await _firestore.collection('destinos').doc(paqueteId).get();
      if (!doc.exists) return 0;
      final data = doc.data() as Map<String, dynamic>?;
      return data?['cuposDisponibles'] as int? ?? 0;
    } catch (e) {
      print('Error obteniendo cupos: $e');
      return 0;
    }
  }
  
  Future<void> subirComprobante(String reservaId, String comprobanteUrl) async {
    final EstadoReserva nuevoEstado = EstadoReserva.verificandoPago;

    await _firestore.collection('reservas').doc(reservaId).update({
      'comprobanteUrl': comprobanteUrl,
      'estadoActual': nuevoEstado.toMap(),
      'historial.${nuevoEstado.toMap()}': FieldValue.serverTimestamp(),
    });
  }

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

  Stream<List<Reserva>> obtenerReservasPorPaquetes(List<String> paquetesIds) {
    if (paquetesIds.isEmpty) return const Stream.empty();
    
    return _firestore
        .collection('reservas')
        .where('paqueteId', whereIn: paquetesIds.take(10).toList())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reserva.fromMap(doc.id, doc.data()))
            .toList());
  }
  
  Future<bool> verificarReservaEnMismaFecha(String estudianteId, DateTime inicio, DateTime fin) async {
    try {
      final reservas = await _firestore
          .collection('reservas')
          .where('estudianteId', isEqualTo: estudianteId)
          .where('estadoActual', whereIn: ['solicitado', 'aceptado', 'pagado'])
          .get();

      for (final doc in reservas.docs) {
        final data = doc.data();
        final reservaInicio = (data['fechaInicio'] as Timestamp).toDate();
        final reservaFin = (data['fechaFin'] as Timestamp).toDate();
        
        if (!(fin.isBefore(reservaInicio) || inicio.isAfter(reservaFin))) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error verificando reservas: $e');
      return false;
    }
  }

  Future<String> obtenerNombreDestino(String destinoId) async {
    try {
      final doc = await _firestore.collection('destinos').doc(destinoId).get();
      return doc.data()?['nombre'] ?? 'otro viaje';
    } catch (e) {
      return 'otro viaje';
    }
  }

  Future<bool> restaurarCupo(String paqueteId, {int cantidad = 1}) async {
    try {
      final destinoRef = _firestore.collection('destinos').doc(paqueteId);
      
      final doc = await destinoRef.get();
      if (!doc.exists) {
        return false;
      }
      
      await destinoRef.update({
        'cuposDisponibles': FieldValue.increment(cantidad),
      });
      
      return true;
    } catch (e) {
      print('Error restaurando cupo: $e');
      return false;
    }
  }
}