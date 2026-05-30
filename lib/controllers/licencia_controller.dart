// lib/controllers/licencia_controller.dart
// Controlador del flujo de subida de Licencia de Turismo
// Patrón Observer (ChangeNotifier) — Hito 2
// Implementa: Usuario.modificarPerfil() → Storage → Firestore → LogAuditoria

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/log_auditoria_model.dart';
import '../services/storage_service.dart';

class LicenciaController extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  String? _successMessage;
  String? _selectedFileName;

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get selectedFileName => _selectedFileName;

  // =========================================================================
  // pickAndUploadLicencia — Flujo completo de selección y subida
  //
  // 1. Valida rol == 'operador'
  // 2. FilePicker → selecciona PDF, JPG o PNG (withData: true para Web)
  // 3. Valida tamaño ≤ 5 MB
  // 4. StorageService.uploadLicencia() → /licencias/{uid}.{ext}
  // 5. Firestore: users/{uid}.update({'licenciaUrl': downloadUrl})
  // 6. AuthController.updateUserLocally(usuario.modificarPerfil(...))
  // 7. Registra LogAuditoria con acción 'upload_licencia'
  // =========================================================================
  Future<void> pickAndUploadLicencia(AuthController authController) async {
    _errorMessage = null;
    _successMessage = null;

    // Guardia de rol — solo Operadores pueden subir licencia
    if (!authController.currentUser.isOperador) {
      _errorMessage = 'Solo los Operadores pueden subir una licencia de turismo.';
      notifyListeners();
      return;
    }

    // Selección de archivo con FilePicker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true, // CRÍTICO para Flutter Web: carga bytes en memoria
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    // Validación de tamaño (5 MB máximo)
    if (file.size > 5 * 1024 * 1024) {
      _errorMessage = 'El archivo supera el límite de 5 MB.';
      notifyListeners();
      return;
    }

    if (file.bytes == null) {
      _errorMessage = 'No se pudieron leer los bytes del archivo.';
      notifyListeners();
      return;
    }

    _selectedFileName = file.name;
    _isUploading = true;
    _uploadProgress = 0.1;
    notifyListeners();

    try {
      final uid = authController.currentUser.id;

      // Paso 1: Subir a Firebase Storage
      _uploadProgress = 0.3;
      notifyListeners();

      final downloadUrl = await _storageService.uploadLicencia(
        uid: uid,
        fileBytes: file.bytes!,
        fileName: file.name,
      );

      _uploadProgress = 0.7;
      notifyListeners();

      // Paso 2: Persistir URL en Firestore
      await _db.collection('users').doc(uid).update({
        'licenciaUrl': downloadUrl,
      });

      _uploadProgress = 0.9;
      notifyListeners();

      // Paso 3: Actualizar Usuario en memoria usando +modificarPerfil() del diagrama
      final usuarioActualizado = authController.currentUser.modificarPerfil(
        licenciaUrl: downloadUrl,
      );
      authController.updateUserLocally(usuarioActualizado);

      // Paso 4: Registrar LogAuditoria
      await _db.collection('logs').add(
        LogAuditoria(
          id: '',
          accionRealizada: 'upload_licencia',
          fechaHora: DateTime.now(),
          usuarioId: uid,
        ).toMap(),
      );

      _uploadProgress = 1.0;
      _successMessage = '¡Licencia subida exitosamente!';
      _isUploading = false;
      notifyListeners();
    } catch (e) {
      _isUploading = false;
      _uploadProgress = 0.0;
      _errorMessage = 'Error al subir la licencia: ${e.toString()}';
      notifyListeners();
    }
  }

  void reset() {
    _isUploading = false;
    _uploadProgress = 0.0;
    _errorMessage = null;
    _successMessage = null;
    _selectedFileName = null;
    notifyListeners();
  }
}
