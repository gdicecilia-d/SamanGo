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
    required String nombre,
    required String empresa,
    required String rif,
    required String telefono,
    required String descripcion,
    required String fechaNacimiento,
  }) async {
    _setLoading(true);
    try {
      // El operador se registra pero no se guarda como _usuarioActual ni hace login automático
      await _authService.registerOperator(
        email: email,
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

  // Aprobar Operador (Admin)
  Future<String?> approveOperator(Usuario operador) async {
    _setLoading(true);
    try {
      await _authService.approveOperator(operador);
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  // Rechazar Operador (Admin)
  Future<String?> rejectOperator(Usuario operador) async {
    _setLoading(true);
    try {
      await _authService.rejectOperator(operador);
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  // Recuperar Contraseña
  Future<String?> recoverPassword(String email) async {
    _setLoading(true);
    try {
      final exists = await _authService.checkEmailExists(email);
      if (!exists) {
        _setLoading(false);
        return 'El correo ingresado no está registrado en el sistema';
      }
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return null; // Éxito
    } catch (e) {
      _setLoading(false);
      return 'Ocurrió un error al intentar enviar el correo.';
    }
  }

  // Update Student Profile
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

  // Update Profile Image
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