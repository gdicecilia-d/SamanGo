import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  Usuario? _usuarioActual;
  bool _isLoading = false;

  Usuario? get usuarioActual => _usuarioActual;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _usuarioActual != null && _usuarioActual!.isNotEmpty;

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _usuarioActual = await _authService.loginWithEmail(email, password);
    _setLoading(false);
    return _usuarioActual != null;
  }

  // Register Student
  Future<String?> registerStudent({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String carnet,
    required String fechaNacimiento,
  }) async {
    _setLoading(true);
    try {
      _usuarioActual = await _authService.registerStudent(
        email: email,
        password: password,
        nombre: nombre,
        apellido: apellido,
        carnet: carnet,
        fechaNacimiento: fechaNacimiento,
      );
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  // Register Operator
  Future<String?> registerOperator({
    required String email,
    required String password,
    required String nombre,
    required String empresa,
    required String rif,
    required String telefono,
    required String descripcion,
    required String fechaNacimiento,
  }) async {
    _setLoading(true);
    try {
      _usuarioActual = await _authService.registerOperator(
        email: email,
        password: password,
        nombre: nombre,
        empresa: empresa,
        rif: rif,
        telefono: telefono,
        descripcion: descripcion,
        fechaNacimiento: fechaNacimiento,
      );
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  // Update Student Profile (carrera y teléfono)
  Future<bool> updateStudentProfile({
    required String carrera,
    required String telefono,
  }) async {
    if (_usuarioActual == null) return false;
    
    _setLoading(true);
    try {
      await _authService.updateStudentProfile(
        uid: _usuarioActual!.id,
        carrera: carrera,
        telefono: telefono,
      );
      _usuarioActual = await _authService.cargarUsuarioDeFirestore(_usuarioActual!.id);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // Update Profile Image (Base64)
  Future<bool> updateProfileImage(String uid, String base64Image) async {
    _setLoading(true);
    try {
      final success = await _authService.updateProfileImage(uid, base64Image);
      if (success) {
        _usuarioActual = await _authService.cargarUsuarioDeFirestore(uid);
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _usuarioActual = null;
    _setLoading(false);
  }

  // Recargar usuario
  Future<void> reloadUser() async {
    if (_usuarioActual != null) {
      final updatedUser = await _authService.cargarUsuarioDeFirestore(_usuarioActual!.id);
      if (updatedUser != null) {
        _usuarioActual = updatedUser;
        notifyListeners();
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}