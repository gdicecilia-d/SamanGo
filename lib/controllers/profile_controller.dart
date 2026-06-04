import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';
import '../services/storage_service.dart';

class ProfileController extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<bool> updateProfileImage(String uid, Uint8List fileBytes, String extension) async {
    _setLoading(true);
    try {
      String url = await _storageService.uploadProfileImage(
        uid: uid,
        fileBytes: fileBytes,
        extension: extension,
      );
      
      // Actualizar la URL de la imagen en Firestore
      await _db.collection('users').doc(uid).update({'fotoUrl': url});
      
      _setLoading(false);
      return true;
    } catch (e) {
      print('Error al subir imagen: $e');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
