// Servicio de almacenamiento de imágenes
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Convierte imagen a Base64 para guardar en Firestore (funciona en Web)
  String imageToBase64(Uint8List fileBytes) {
    return base64Encode(fileBytes);
  }

  // Convierte Base64 a Uint8List para mostrar
  Uint8List base64ToImage(String base64String) {
    return base64Decode(base64String);
  }

  // Sube licencia a Firebase Storage
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

  // Sube imagen de perfil (Base64 se guarda en Firestore, no en Storage)
  // Este método es para cuando quieras guardar en Storage en lugar de Base64
  Future<String> uploadProfileImage({
    required String uid,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final extension = fileName.split('.').last.toLowerCase();
    final ref = _storage.ref().child('perfiles/$uid/profile.$extension');
    final metadata = SettableMetadata(contentType: _getContentType(extension));
    await ref.putData(fileBytes, metadata);
    return await ref.getDownloadURL();
  }

  // Sube imagen de tour a Firebase Storage
  Future<String> uploadTourImage({
    required String uid,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ref = _storage.ref().child('tours/$uid/$fileName');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  }

  // Sube imagen de referencia de tour
  Future<String> uploadTourReferenceImage({
    required String uid,
    required String tourId,
    required int index,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final extension = fileName.split('.').last.toLowerCase();
    final ref = _storage.ref().child('tours/$uid/$tourId/reference_$index.$extension');
    final metadata = SettableMetadata(contentType: _getContentType(extension));
    await ref.putData(bytes, metadata);
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