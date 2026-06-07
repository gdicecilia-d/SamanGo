// Servicio de almacenamiento de imágenes
import 'dart:typed_data';
import 'dart:convert';
import 'package:image/image.dart' as img;

class StorageService {
  // Convierte imagen a Base64 para guardar en Firestore
  String imageToBase64(Uint8List fileBytes) {
    return base64Encode(fileBytes);
  }

  // Convierte Base64 a Uint8List para mostrar
  Uint8List base64ToImage(String base64String) {
    return base64Decode(base64String);
  }

  // Comprime la imagen a 400px de ancho maximo y calidad 60
  Uint8List comprimirImagen(Uint8List bytes) {
    final imagen = img.decodeImage(bytes);
    if (imagen == null) return bytes;

    // Redimensionar a maximo 400px de ancho
    final reducida = imagen.width > 400
        ? img.copyResize(imagen, width: 400)
        : imagen;

    // Calidad 60: se ve bien en pantalla pero pesa muy poco
    return Uint8List.fromList(img.encodeJpg(reducida, quality: 60));
  }

  // Sube imagen de tour a Firebase Storage (comprimida y convertida a Base64)
  Future<String> uploadTourImage({
    required String uid,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final comprimidos = comprimirImagen(bytes);
    final base64 = imageToBase64(comprimidos);
    return 'data:image/jpeg;base64,$base64';
  }

  // Sube imagen de referencia de tour
  Future<String> uploadTourReferenceImage({
    required String uid,
    required String tourId,
    required int index,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final comprimidos = comprimirImagen(bytes);
    final base64 = imageToBase64(comprimidos);
    return 'data:image/jpeg;base64,$base64';
  }

  // Sube licencia a Firebase Storage
  Future<String> uploadLicencia({
    required String uid,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final comprimidos = comprimirImagen(fileBytes);
    final base64 = imageToBase64(comprimidos);
    return 'data:image/jpeg;base64,$base64';
  }

  // Sube imagen de perfil
  Future<String> uploadProfileImage({
    required String uid,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final comprimidos = comprimirImagen(fileBytes);
    final base64 = imageToBase64(comprimidos);
    return 'data:image/jpeg;base64,$base64';
  }
}