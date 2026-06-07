import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Credenciales de correo (Para entorno de desarrollo)
  // IMPORTANTE: En producción usar EmailJS o un backend real.
  final String _smtpEmail = 'samangounimet@gmail.com'; // Reemplazar
  final String _smtpPassword = 'tupassworddeaplicacion'; // Reemplazar por Contraseña de Aplicación de Google

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

  // Registra un nuevo operador (Solo base de datos)
  Future<Usuario> registerOperator({
    required String email,
    required String nombre,
    required String empresa,
    required String rif,
    required String telefono,
    required String descripcion,
    required String fechaNacimiento,
  }) async {
    try {
      final emailExists = await checkEmailExists(email);
      if (emailExists) {
        throw 'El correo ya está registrado en el sistema';
      }

      final docRef = _db.collection('operadores').doc();
      final uid = docRef.id;

      final usuario = Usuario(
        id: uid,
        nombre: nombre,
        correo: email.trim(),
        rol: 'operador',
        empresa: empresa,
        rif: rif,
        telefono: telefono,
        descripcion: descripcion,
        fechaNacimiento: fechaNacimiento,
        estado: 'pendiente',
      );
      await docRef.set(usuario.toMap());
      return usuario;
    } catch (e) {
      throw e.toString();
    }
  }

  // Aprobar Operador
  Future<void> approveOperator(Usuario operador) async {
    try {
      // 1. Generar contraseña aleatoria
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$';
      final rnd = Random.secure();
      final password = String.fromCharCodes(Iterable.generate(8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

      // 2. Crear usuario en Firebase Auth usando una app secundaria para no desloguear al Admin
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
      await tempApp.delete(); // Limpiamos la app secundaria

      // 3. Actualizar documento y moverlo al ID real de Auth si es necesario,
      // o simplemente actualizar el estado y guardar el authId.
      await _db.collection('operadores').doc(operador.id).update({
        'estado': 'aprobado',
        'authId': authUid,
      });

      // 4. Enviar correo electrónico
      await _sendEmail(
        to: operador.correo,
        subject: '¡Solicitud Aprobada! Bienvenido a SamanGo',
        html: '''
          <h2>¡Felicidades ${operador.nombre}!</h2>
          <p>Tu solicitud para la empresa <strong>${operador.empresa}</strong> ha sido aprobada.</p>
          <p>Tus credenciales de acceso son las siguientes:</p>
          <ul>
            <li><strong>Usuario:</strong> ${operador.correo}</li>
            <li><strong>Contraseña:</strong> \$password</li>
          </ul>
          <p>Te recomendamos cambiar tu contraseña al iniciar sesión por primera vez.</p>
          <br>
          <p>Saludos,<br>El equipo de SamanGo</p>
        ''',
      );
    } catch (e) {
      print('Error al aprobar operador: \$e');
      throw 'Error al procesar la aprobación: \$e';
    }
  }

  // Rechazar Operador
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

  // Utilidad para enviar correos SMTP
  Future<void> _sendEmail({required String to, required String subject, required String html}) async {
    final smtpServer = gmail(_smtpEmail, _smtpPassword);
    final message = Message()
      ..from = Address(_smtpEmail, 'SamanGo')
      ..recipients.add(to)
      ..subject = subject
      ..html = html;

    try {
      await send(message, smtpServer);
      print('Correo real enviado con éxito a $to');
    } catch (e) {
      print('Error enviando correo SMTP: $e');
    }
  }

  // Verificar si el correo existe
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

  // Actualizar perfil del estudiante
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

  // Actualizar foto de perfil
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
      print('Error al actualizar foto: \$e');
      return false;
    }
  }

  // Carga los datos del usuario desde Firestore
  Future<Usuario?> cargarUsuarioDeFirestore(String uid) async {
    try {
      // Intentar buscar por authId primero (para operadores)
      var operAuthQuery = await _db.collection('operadores').where('authId', isEqualTo: uid).limit(1).get();
      if (operAuthQuery.docs.isNotEmpty) {
        return Usuario.fromMap(operAuthQuery.docs.first.id, operAuthQuery.docs.first.data());
      }

      var doc = await _db.collection('estudiantes').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return Usuario.fromMap(uid, doc.data()!);
      }
      doc = await _db.collection('operadores').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return Usuario.fromMap(uid, doc.data()!);
      }
      doc = await _db.collection('administradores').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return Usuario.fromMap(uid, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error cargando usuario: \$e');
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