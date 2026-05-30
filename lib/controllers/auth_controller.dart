// lib/controllers/auth_controller.dart
// Controlador global de autenticación — patrón Observer (ChangeNotifier) del Hito 2
// Gestiona: estado de sesión, persistencia Web, login, logout y auditoría

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_model.dart';
import '../models/log_auditoria_model.dart';

class AuthController extends ChangeNotifier {
  // ─── Instancias Firebase (lazy y seguras) ────────────────────────────────
  FirebaseAuth? get _auth =>
      Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _db =>
      Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

  // ─── Estado interno ───────────────────────────────────────────────────────
  Usuario _currentUser = Usuario.empty;
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters públicos ─────────────────────────────────────────────────────
  Usuario get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser.isNotEmpty;

  // ─── Clave SharedPreferences para persistencia Web ───────────────────────
  static const String _kUidKey = 'samango_logged_uid';

  // =========================================================================
  // tryAutoLogin — Restaura sesión al recargar la página (Flutter Web)
  // Flujo: lee UID local → verifica Firebase Auth token → carga Firestore
  // =========================================================================
  Future<void> tryAutoLogin() async {
    if (_auth == null) return;
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString(_kUidKey);
    if (savedUid == null || savedUid.isEmpty) return;

    final firebaseUser = _auth!.currentUser;
    if (firebaseUser == null || firebaseUser.uid != savedUid) {
      await prefs.remove(_kUidKey);
      return;
    }
    await _cargarUsuarioDeFirestore(savedUid);
  }

  // =========================================================================
  // login — Autentica con email/contraseña usando Firebase Auth real
  //
  // Retorna: null si fue exitoso, String con el mensaje de error si falló.
  // =========================================================================
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      if (_auth == null) {
        _setLoading(false);
        _errorMessage = 'Firebase no está inicializado.';
        notifyListeners();
        return _errorMessage;
      }

      final credential = await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // Persistir UID en localStorage (SharedPreferences en Web)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUidKey, uid);

      // Cargar datos del Usuario desde Firestore
      await _cargarUsuarioDeFirestore(uid);

      // Registrar auditoría (relación: Usuario registra LogAuditoria — Hito 1)
      await _registrarLog(uid: uid, accion: 'login');

      _setLoading(false);
      return null; // null = éxito

    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _errorMessage = _traducirErrorFirebase(e.code);
      notifyListeners();
      return _errorMessage;
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Error inesperado. Intenta de nuevo.';
      notifyListeners();
      return _errorMessage;
    }
  }

  // =========================================================================
  // logout — Cierra sesión y limpia todo el estado global
  // =========================================================================
  Future<void> logout() async {
    final uid = _currentUser.id;

    if (_auth != null) await _auth!.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUidKey);

    if (uid.isNotEmpty) {
      await _registrarLog(uid: uid, accion: 'logout');
    }

    _currentUser = Usuario.empty;
    _errorMessage = null;
    notifyListeners();
  }

  // =========================================================================
  // updateUserLocally — Actualiza el Usuario en memoria sin ir a Firestore.
  // Lo usa LicenciaController (Módulo 7) para reflejar el nuevo licenciaUrl.
  // Implementa el patrón Observer: notifica a los widgets dependientes.
  // =========================================================================
  void updateUserLocally(Usuario updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  // ─── Métodos privados ─────────────────────────────────────────────────────

  Future<void> _cargarUsuarioDeFirestore(String uid) async {
    if (_db == null || _auth == null) return;
    final docRef = _db!.collection('users').doc(uid);
    final snapshot = await docRef.get();

    if (snapshot.exists && snapshot.data() != null) {
      _currentUser = Usuario.fromMap(uid, snapshot.data()!);
    } else {
      // Crear documento inicial con datos básicos de Firebase Auth
      final firebaseUser = _auth!.currentUser;
      _currentUser = Usuario(
        id: uid,
        nombre: firebaseUser?.displayName ?? 'Usuario SamanGo',
        correo: firebaseUser?.email ?? '',
        rol: 'estudiante',
      );
      await docRef.set(_currentUser.toMap());
    }
    notifyListeners();
  }

  /// Registra una acción en la colección 'logs' de Firestore
  /// Implementa la relación: Usuario (1) registra (*) LogAuditoria del diagrama
  Future<void> _registrarLog({
    required String uid,
    required String accion,
  }) async {
    if (_db == null) return;
    try {
      await _db!.collection('logs').add(
        LogAuditoria(
          id: '',
          accionRealizada: accion,
          fechaHora: DateTime.now(),
          usuarioId: uid,
        ).toMap(),
      );
    } catch (_) {
      // El fallo de auditoría nunca interrumpe el flujo principal
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Traduce códigos de error de Firebase Auth a mensajes en español
  String _traducirErrorFirebase(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return 'Error de autenticación ($code).';
    }
  }
}
