import 'dart:math';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/usuario.dart';
import 'storage_service.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> getCurrentFirebaseUser() async {
    try {
      final user = await _auth.authStateChanges().firstWhere((u) => u != null).timeout(const Duration(seconds: 2));
      return user;
    } catch (e) {
      return _auth.currentUser;
    }
  }

  Future<dynamic> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        authProvider.setCustomParameters({'hd': 'correo.unimet.edu.ve'});
        userCredential = await _auth.signInWithPopup(authProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final email = userCredential.user!.email ?? '';
      if (!email.endsWith('@correo.unimet.edu.ve') && !email.endsWith('@unimet.edu.ve')) {
        await userCredential.user!.delete();
        return 'Solo se permiten correos institucionales de la UNIMET';
      }

      final uid = userCredential.user!.uid;

      Usuario? usuario = await cargarUsuarioDeFirestore(uid);

      if (usuario == null) {
        return {
          'isNewUser': true,
          'uid': uid,
          'email': email,
          'displayName': userCredential.user!.displayName ?? '',
          'photoUrl': userCredential.user!.photoURL,
        };
      }

      return usuario;
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'web-context-cancelled') {
        return null;
      }
      print('Error en Google Sign-In: $e');
      return e.toString();
    }
  }

  Future<Usuario> completeGoogleProfile({
    required String uid,
    required String email,
    required String nombre,
    required String apellido,
    required String carnet,
    required String fechaNacimiento,
    String? photoUrl,
  }) async {
    final usuario = Usuario(
      id: uid,
      nombre: nombre,
      apellido: apellido,
      correo: email,
      rol: 'estudiante',
      carnet: carnet,
      fechaNacimiento: fechaNacimiento,
      fotoUrl: photoUrl,
    );
    await _db.collection('estudiantes').doc(uid).set(usuario.toMap());
    return usuario;
  }

  Future<Usuario?> loginWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      
      final usuario = await cargarUsuarioDeFirestore(uid);
      
      return usuario;
    } on FirebaseAuthException catch (e) {
      print('Error de login Firebase: ${e.code}');
      return null;
    } catch (e) {
      print('Error de login: $e');
      return null;
    }
  }

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
        correo: email.trim(),
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

  Future<Usuario> registerOperator({
    required String email,
    required String nombre,
    required String empresa,
    required String rif,
    required String telefono,
    required String descripcion,
    Uint8List? fileBytes,
  }) async {
    try {
      final emailExists = await checkEmailExists(email);
      if (emailExists) {
        throw 'El correo ya está registrado en el sistema';
      }

      final docRef = _db.collection('operadores').doc();
      final uid = docRef.id;

      String? licenciaUrl;
      if (fileBytes != null) {
        licenciaUrl = await StorageService().uploadLicencia(
          uid: uid,
          fileBytes: fileBytes,
          fileName: 'licencia_operador_$uid',
        );
      }

      final usuario = Usuario(
        id: uid,
        nombre: nombre,
        correo: email.trim(),
        rol: 'operador',
        empresa: empresa,
        rif: rif,
        telefono: telefono,
        descripcion: descripcion,
        fechaNacimiento: '',
        estado: 'pendiente',
        licenciaUrl: licenciaUrl,
      );
      await docRef.set(usuario.toMap());
      return usuario;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> approveOperator(Usuario operador) async {
    try {
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$';
      final rnd = Random.secure();
      final password = String.fromCharCodes(Iterable.generate(8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'tempAuth',
        options: Firebase.app().options,
      );
      
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: operador.correo,
        password: password,
      );
      
      final authUid = credential.user!.uid;
      await tempApp.delete();

      await _db.collection('operadores').doc(operador.id).update({
        'estado': 'aprobado',
        'authId': authUid,
        'activo': true,
      });

      await _sendEmail(
        to: operador.correo,
        subject: '¡Solicitud Aprobada! Bienvenido a SamanGo',
        html: '''
          <h2>¡Felicidades ${operador.nombre}!</h2>
          <p>Tu solicitud para la empresa <strong>${operador.empresa}</strong> ha sido aprobada.</p>
          <p>Tus credenciales de acceso son las siguientes:</p>
          <ul>
            <li><strong>Usuario:</strong> ${operador.correo}</li>
            <li><strong>Contraseña:</strong> $password</li>
          </ul>
          <p>Te recomendamos cambiar tu contraseña al iniciar sesión por primera vez.</p>
          <br>
          <p>Saludos,<br>El equipo de SamanGo</p>
        ''',
      );
    } catch (e) {
      print('Error al aprobar operador: $e');
      throw 'Error al procesar la aprobación: $e';
    }
  }

  Future<void> rejectOperator(Usuario operador) async {
    try {
      await _db.collection('operadores').doc(operador.id).update({
        'estado': 'rechazado',
      });

      await _sendEmail(
        to: operador.correo,
        subject: 'Actualización sobre tu solicitud en SamanGo',
        html: '''
          <h2>Hola ${operador.nombre},</h2>
          <p>Lamentamos informarte que tu solicitud para registrar a la empresa <strong>${operador.empresa}</strong> ha sido rechazada tras nuestra revisión.</p>
          <p>Si consideras que ha sido un error, por favor contáctanos.</p>
          <br>
          <p>Saludos,<br>El equipo de SamanGo</p>
        ''',
      );
    } catch (e) {
      throw 'Error al rechazar operador: $e';
    }
  }

  Future<void> _sendEmail({required String to, required String subject, required String html}) async {
    const serviceId = 'service_g1qpjdb';
    const templateId = 'template_j16ut8g';
    const publicKey = 'q3Z-wi-zfV3BVRvzA';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'to_email': to,
            'subject': subject,
            'message_html': html,
          }
        }),
      );

      if (response.statusCode == 200) {
        print('Correo enviado con éxito a $to');
      } else {
        print('Error de EmailJS: ${response.body}');
      }
    } catch (e) {
      print('Error enviando correo HTTP: $e');
    }
  }

  Future<bool> checkEmailExists(String email) async {
    final queryEmail = email.trim();
    final estudiantes = await _db.collection('estudiantes').where('correo', isEqualTo: queryEmail).limit(1).get();
    if (estudiantes.docs.isNotEmpty) return true;
    
    final operadores = await _db.collection('operadores').where('correo', isEqualTo: queryEmail).limit(1).get();
    if (operadores.docs.isNotEmpty) return true;

    final admins = await _db.collection('administradores').where('correo', isEqualTo: queryEmail).limit(1).get();
    if (admins.docs.isNotEmpty) return true;

    return false;
  }

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

  Future<Usuario?> cargarUsuarioDeFirestore(String uid) async {
    try {
      var operAuthQuery = await _db.collection('operadores').where('authId', isEqualTo: uid).limit(1).get();
      if (operAuthQuery.docs.isNotEmpty) {
        return Usuario.fromMap(operAuthQuery.docs.first.id, operAuthQuery.docs.first.data());
      }

      var docOperador = await _db.collection('operadores').doc(uid).get();
      if (docOperador.exists && docOperador.data() != null) {
        return Usuario.fromMap(uid, docOperador.data()!);
      }

      var docAdmin = await _db.collection('administradores').doc(uid).get();
      if (docAdmin.exists && docAdmin.data() != null) {
        return Usuario.fromMap(uid, docAdmin.data()!);
      }

      var docEstudiante = await _db.collection('estudiantes').doc(uid).get();
      if (docEstudiante.exists && docEstudiante.data() != null) {
        return Usuario.fromMap(uid, docEstudiante.data()!);
      }
      
      return null;
    } catch (e) {
      print('Error cargando usuario: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}