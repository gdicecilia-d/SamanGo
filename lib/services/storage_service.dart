// Servicio de almacenamiento de imagenes
// Ruta: lib/services/storage_service.dart
//
// Para demo local: las imagenes se comprimen agresivamente y se guardan
// como Base64 en Firestore. No requiere Firebase Storage ni plan de pago.
// El flujo es: bytes -> comprimir a 400px / calidad 60 -> Base64 string -> Firestore
// Una imagen que pesaba 5MB queda en ~15KB como Base64, perfecta para Firestore.

import 'dart:typed_data';
import 'dart:convert';
import 'package:image/image.dart' as img;

class StorageService {

  // Comprime la imagen a 400px de ancho maximo y calidad 60.
  // Resultado tipico: imagen de 5MB -> ~15KB en Base64.
  Uint8List _comprimirParaDemo(Uint8List bytes) {
    final imagen = img.decodeImage(bytes);
    if (imagen == null) return bytes;

    // Redimensionar a maximo 400px de ancho (suficiente para las cards)
    final reducida = imagen.width > 400
        ? img.copyResize(imagen, width: 400)
        : imagen;

    // Calidad 60: se ve bien en pantalla pero pesa muy poco
    return Uint8List.fromList(img.encodeJpg(reducida, quality: 60));
  }

  // Convierte bytes a Base64
  String imageToBase64(Uint8List fileBytes) {
    return base64Encode(fileBytes);
  }

  // Convierte Base64 a Uint8List para mostrar con Image.memory()
  Uint8List base64ToImage(String base64String) {
    return base64Decode(base64String);
  }

  // Metodo principal que usan las pantallas de publicacion.
  // Comprime y devuelve el string Base64 listo para guardar en Firestore.
  // uid y fileName se mantienen por compatibilidad con el codigo existente.
  Future<String> uploadTourImage({
    required String uid,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final comprimidos = _comprimirParaDemo(bytes);
    // Prefijo data URI para que las DestinationCard lo muestren con Image.network()
    return 'data:image/jpeg;base64,${base64Encode(comprimidos)}';
  }

  // Mismo flujo para imagenes de referencia adicionales
  Future<String> uploadTourReferenceImage({
    required String uid,
    required String tourId,
    required int index,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final comprimidos = _comprimirParaDemo(bytes);
    return 'data:image/jpeg;base64,${base64Encode(comprimidos)}';
  }

  // Licencia - misma logica
  Future<String> uploadLicencia({
    required String uid,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final comprimidos = _comprimirParaDemo(fileBytes);
    return 'data:image/jpeg;base64,${base64Encode(comprimidos)}';
  }

  // Imagen de perfil - misma logica
  Future<String> uploadProfileImage({
    required String uid,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final comprimidos = _comprimirParaDemo(fileBytes);
    return 'data:image/jpeg;base64,${base64Encode(comprimidos)}';
  }
}