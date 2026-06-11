import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener stream de favoritos de un usuario
  Stream<List<String>> obtenerFavoritosStream(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    return _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('favoritos')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Agregar un favorito
  Future<void> agregarFavorito(String userId, String destinoId) async {
    if (userId.isEmpty) return;
    await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('favoritos')
        .doc(destinoId)
        .set({'fechaAgregado': FieldValue.serverTimestamp()});
  }

  // Eliminar un favorito
  Future<void> eliminarFavorito(String userId, String destinoId) async {
    if (userId.isEmpty) return;
    await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('favoritos')
        .doc(destinoId)
        .delete();
  }
}
