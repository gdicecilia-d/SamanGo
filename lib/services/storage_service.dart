// Servicio de Firebase Storage
// Sube archivos (licencias, imágenes de destinos) y devuelve la URL de descarga
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Sube la licencia de turismo del operador
  // uid: ID del usuario
  // fileBytes: bytes del archivo seleccionado
  // fileName: nombre original del archivo
  Future<String> uploadLicencia({
    required String uid,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final extension = fileName.split('.').last.toLowerCase();
    final ref = _storage.ref().child('licencias/$uid.$extension');
    final metadata = SettableMetadata(contentType: _getContentType(extension));
    await ref.putData(fileBytes, metadata);
    return await ref.getDownloadURL();
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}