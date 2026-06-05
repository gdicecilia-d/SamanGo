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
    required String carnet,
    required String fechaNacimiento,
  }) async {
    _setLoading(true);
    try {
      _usuarioActual = await _authService.registerStudent(
        email: email,
        password: password,
        nombre: nombre,
        carnet: carnet,
        fechaNacimientoText: fechaNacimiento,
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
        fechaNacimientoText: fechaNacimiento,
      );
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _usuarioActual = null;
    _setLoading(false);
  }

  // Recargar usuario (por ejemplo, después de actualizar la foto de perfil)
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
