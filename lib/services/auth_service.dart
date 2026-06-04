// Servicio de autenticación con Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Inicia sesión con email y contraseña
  Future<Usuario?> loginWithEmail(String email, String password) async {
    // --- BACKDOOR PARA PRUEBAS RÁPIDAS ---
    if (email.trim().toLowerCase() == 'admin' && password == '1234') {
      const dummyId = 'dummy_operator_123';
      final dummyUser = const Usuario(
        id: dummyId,
        nombre: 'Operador de Prueba',
        correo: 'admin@operador.com',
        rol: 'operador',
      );
      await _db.collection('users').doc(dummyId).set(dummyUser.toMap(), SetOptions(merge: true));
      return await cargarUsuarioDeFirestore(dummyId);
    }
    // --------------------------------------

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      return await cargarUsuarioDeFirestore(uid);
    } on FirebaseAuthException catch (e) {
      print('Error de login: ${e.code}');
      return null;
    }
  }

  // Registra un nuevo estudiante
  Future<Usuario?> registerStudent({
    required String email,
    required String password,
    required String nombre,
    required String carnet,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      final usuario = Usuario(
        id: uid,
        nombre: nombre,
        correo: email,
        rol: 'estudiante',
        carnet: carnet,
      );
      await _db.collection('users').doc(uid).set(usuario.toMap());
      return usuario;
    } on FirebaseAuthException catch (e) {
      print('Error de registro: ${e.code}');
      return null;
    }
  }

  // Carga los datos del usuario desde Firestore
  Future<Usuario?> cargarUsuarioDeFirestore(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return Usuario.fromMap(uid, doc.data()!);
      } else {
        // Si no existe el documento en Firestore, lo creamos automáticamente
        final user = _auth.currentUser;
        final nuevoUsuario = Usuario(
          id: uid,
          nombre: user?.displayName ?? 'Usuario',
          correo: user?.email ?? '',
          rol: 'estudiante',
        );
        await _db.collection('users').doc(uid).set(nuevoUsuario.toMap());
        return nuevoUsuario;
      }
    } catch (e) {
      print('Error cargando usuario: $e');
      return null;
    }
  }

  // Cierra sesión
  Future<void> logout() async {
    await _auth.signOut();
  }
}