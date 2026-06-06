// Servicio de autenticación con Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Inicia sesión con email y contraseña
  Future<Usuario?> loginWithEmail(String email, String password) async {
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
  Future<Usuario> registerStudent({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String carnet,
    required String fechaNacimiento,
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
        apellido: apellido,
        correo: email,
        rol: 'estudiante',
        carnet: carnet,
        fechaNacimiento: fechaNacimiento,
      );
      await _db.collection('estudiantes').doc(uid).set(usuario.toMap());
      return usuario;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'El correo ya está registrado';
      }
      throw 'Error en el registro. Intenta nuevamente.';
    }
  }

  // Registra un nuevo operador
  Future<Usuario> registerOperator({
    required String email,
    required String password,
    required String nombre,
    required String empresa,
    required String rif,
    required String telefono,
    required String descripcion,
    required String fechaNacimiento,
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
        rol: 'operador',
        empresa: empresa,
        rif: rif,
        telefono: telefono,
        descripcion: descripcion,
        fechaNacimiento: fechaNacimiento,
        estado: 'pendiente',
      );
      await _db.collection('operadores').doc(uid).set(usuario.toMap());
      return usuario;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'El correo ya está registrado';
      }
      throw 'Error en el registro. Intenta nuevamente.';
    }
  }

  // Actualizar perfil del estudiante (carrera y teléfono)
  Future<void> updateStudentProfile({
    required String uid,
    required String carrera,
    required String telefono,
  }) async {
    await _db.collection('estudiantes').doc(uid).update({
      'carrera': carrera,
      'telefono': telefono,
    });
  }

  // Actualizar foto de perfil (guarda Base64 en Firestore)
  Future<bool> updateProfileImage(String uid, String base64Image) async {
    try {
      var doc = await _db.collection('estudiantes').doc(uid).get();
      if (doc.exists) {
        await _db.collection('estudiantes').doc(uid).update({'fotoBase64': base64Image});
        return true;
      }
      doc = await _db.collection('operadores').doc(uid).get();
      if (doc.exists) {
        await _db.collection('operadores').doc(uid).update({'fotoBase64': base64Image});
        return true;
      }
      doc = await _db.collection('administradores').doc(uid).get();
      if (doc.exists) {
        await _db.collection('administradores').doc(uid).update({'fotoBase64': base64Image});
        return true;
      }
      return false;
    } catch (e) {
      print('Error al actualizar foto: $e');
      return false;
    }
  }

  // Carga los datos del usuario desde Firestore
  Future<Usuario?> cargarUsuarioDeFirestore(String uid) async {
    try {
      // Buscar en estudiantes
      var doc = await _db.collection('estudiantes').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return Usuario.fromMap(uid, doc.data()!);
      }
      // Buscar en operadores
      doc = await _db.collection('operadores').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return Usuario.fromMap(uid, doc.data()!);
      }
      // Buscar en administradores
      doc = await _db.collection('administradores').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return Usuario.fromMap(uid, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error cargando usuario: $e');
      return null;
    }
  }

  // Cierra sesión
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Enviar correo de restablecimiento
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}