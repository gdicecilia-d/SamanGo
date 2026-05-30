// lib/services/storage_service.dart
// Servicio de Firebase Storage — encapsula la subida de archivos
// Ruta en Storage: /licencias/{uid}.{ext}

import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube la licencia de turismo del Operador a Firebase Storage.
  /// Usa el UID como nombre de archivo para sobreescribir si se vuelve a subir.
  ///
  /// Parámetros:
  ///   uid       — id del Usuario (campo +id del diagrama)
  ///   fileBytes — bytes del archivo (FilePicker con withData: true para Web)
  ///   fileName  — nombre original para extraer la extensión
  ///
  /// Retorna: URL de descarga del archivo subido
  Future<String> uploadLicencia({
    required String uid,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final extension = fileName.split('.').last.toLowerCase();
    final ref = _storage.ref().child('licencias/$uid.$extension');
    final metadata = SettableMetadata(contentType: _getContentType(extension));
    final uploadTask = await ref.putData(fileBytes, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'pdf':  return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      default:     return 'application/octet-stream';
    }
  }
}
