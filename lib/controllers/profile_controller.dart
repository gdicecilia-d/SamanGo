// Controlador de perfil para subida de fotos
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import '../models/usuario.dart';

class ProfileController extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Actualizar foto de perfil usando Base64 
  Future<bool> updateProfileImage(String uid, String base64Image) async {
    _setLoading(true);
    try {
      // Actualizar la URL de la imagen en Firestore
      await _db.collection('users').doc(uid).update({'fotoBase64': base64Image});
      _setLoading(false);
      return true;
    } catch (e) {
      print('Error al subir imagen: $e');
      _setLoading(false);
      return false;
    }
  }

  // Obtener la foto de perfil en Base64
  Future<String?> getProfileImage(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['fotoBase64'] as String?;
      }
      return null;
    } catch (e) {
      print('Error al obtener foto: $e');
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}