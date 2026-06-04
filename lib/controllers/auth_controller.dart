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
  Future<bool> registerStudent({
    required String email,
    required String password,
    required String nombre,
    required String carnet,
  }) async {
    _setLoading(true);
    _usuarioActual = await _authService.registerStudent(
      email: email,
      password: password,
      nombre: nombre,
      carnet: carnet,
    );
    _setLoading(false);
    return _usuarioActual != null;
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _usuarioActual = null;
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
