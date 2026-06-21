import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';
import 'login_view.dart';

class AccountDisabledView extends StatefulWidget {
  const AccountDisabledView({super.key});

  @override
  State<AccountDisabledView> createState() => _AccountDisabledViewState();
}

class _AccountDisabledViewState extends State<AccountDisabledView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _apelacionController = TextEditingController();
  bool _enviando = false;
  bool _cargando = false;
  String? _userId;
  String? _userEmail;
  String? _userName;
  String? _userRol;
  bool _usuarioEncontrado = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _cargarUsuarioActual();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _apelacionController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    setState(() {
      _emailError = null;
      _usuarioEncontrado = false;
      _userId = null;
      _userName = null;
      _userEmail = null;
      _userRol = null;
    });
  }

  Future<void> _cargarUsuarioActual() async {
    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final usuario = auth.usuarioActual;
      
      if (usuario != null && usuario.id.isNotEmpty) {
        setState(() {
          _emailController.text = usuario.correo;
          _userId = usuario.id;
          _userName = usuario.nombre;
          _userEmail = usuario.correo;
          _userRol = usuario.rol;
          _usuarioEncontrado = true;
        });
        return;
      }

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final email = firebaseUser.email;
        if (email != null && email.isNotEmpty) {
          setState(() {
            _emailController.text = email;
          });
          
          final uid = firebaseUser.uid;
          
          final estudianteDoc = await FirebaseFirestore.instance
              .collection('estudiantes')
              .doc(uid)
              .get();
          
          if (estudianteDoc.exists) {
            final data = estudianteDoc.data() as Map<String, dynamic>?;
            setState(() {
              _userId = uid;
              _userEmail = email;
              _userName = data?['nombre'] ?? 'Usuario';
              _userRol = 'estudiante';
              _usuarioEncontrado = true;
            });
            return;
          }
          
          final operadorDoc = await FirebaseFirestore.instance
              .collection('operadores')
              .doc(uid)
              .get();
          
          if (operadorDoc.exists) {
            final data = operadorDoc.data() as Map<String, dynamic>?;
            setState(() {
              _userId = uid;
              _userEmail = email;
              _userName = data?['nombre'] ?? 'Usuario';
              _userRol = 'operador';
              _usuarioEncontrado = true;
            });
            return;
          }
          
          final adminDoc = await FirebaseFirestore.instance
              .collection('administradores')
              .doc(uid)
              .get();
          
          if (adminDoc.exists) {
            final data = adminDoc.data() as Map<String, dynamic>?;
            setState(() {
              _userId = uid;
              _userEmail = email;
              _userName = data?['nombre'] ?? 'Usuario';
              _userRol = 'administrador';
              _usuarioEncontrado = true;
            });
            return;
          }
        }
      }
    } catch (e) {
      print('Error cargando usuario actual: $e');
    }
  }

  Future<void> _buscarUsuarioPorEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Ingresa un correo electrónico';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _emailError = null;
    });

    try {
      final db = FirebaseFirestore.instance;
      String? encontradoId;
      String? encontradoNombre;
      String? encontradoEmail;
      String? encontradoRol;

      final estudiantes = await db
          .collection('estudiantes')
          .where('correo', isEqualTo: email)
          .limit(1)
          .get();

      if (estudiantes.docs.isNotEmpty) {
        final data = estudiantes.docs.first.data();
        encontradoId = estudiantes.docs.first.id;
        encontradoNombre = data['nombre'] ?? 'Usuario';
        encontradoEmail = data['correo'] ?? email;
        encontradoRol = 'estudiante';
      }

      if (encontradoId == null) {
        final operadores = await db
            .collection('operadores')
            .where('correo', isEqualTo: email)
            .limit(1)
            .get();

        if (operadores.docs.isNotEmpty) {
          final data = operadores.docs.first.data();
          encontradoId = operadores.docs.first.id;
          encontradoNombre = data['nombre'] ?? 'Usuario';
          encontradoEmail = data['correo'] ?? email;
          encontradoRol = 'operador';
        }
      }

      if (encontradoId == null) {
        final admins = await db
            .collection('administradores')
            .where('correo', isEqualTo: email)
            .limit(1)
            .get();

        if (admins.docs.isNotEmpty) {
          final data = admins.docs.first.data();
          encontradoId = admins.docs.first.id;
          encontradoNombre = data['nombre'] ?? 'Usuario';
          encontradoEmail = data['correo'] ?? email;
          encontradoRol = 'administrador';
        }
      }

      if (encontradoId != null) {
        setState(() {
          _userId = encontradoId;
          _userName = encontradoNombre;
          _userEmail = encontradoEmail;
          _userRol = encontradoRol;
          _usuarioEncontrado = true;
          _cargando = false;
        });
      } else {
        setState(() {
          _emailError = 'No se encontró ningún usuario con ese correo';
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _emailError = 'Error al buscar el usuario';
        _cargando = false;
      });
    }
  }

  Future<void> _enviarApelacion() async {
    final mensaje = _apelacionController.text.trim();
    if (mensaje.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, escribe un mensaje de apelación'),
          backgroundColor: Color(0xFFFC6707),
        ),
      );
      return;
    }

    if (_userId == null || _userId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero verifica tu correo electrónico'),
          backgroundColor: Color(0xFFFC6707),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final nombre = _userName ?? 'Usuario';

      await FirebaseFirestore.instance.collection('reportes').add({
        'estudiante': nombre,
        'tour': 'Apelación de cuenta',
        'tipo_alerta': 'Apelación',
        'estado': 'amarillo',
        'mensaje': mensaje,
        'fecha': FieldValue.serverTimestamp(),
        'usuarioId': _userId,
        'correo': _userEmail ?? '',
        'rol': _userRol ?? '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apelación enviada correctamente. Será revisada por el administrador.'),
          backgroundColor: Color(0xFFFC6707),
        ),
      );
      
      final auth = Provider.of<AuthController>(context, listen: false);
      await auth.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar la apelación: $e'),
          backgroundColor: Color(0xFFFC6707),
        ),
      );
      setState(() => _enviando = false);
    }
  }

  void _volverAlLogin() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    await auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Container(
            width: isMobile ? double.infinity : 500,
            padding: EdgeInsets.all(isMobile ? 24 : 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC6707).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.block,
                    color: const Color(0xFFFC6707),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Cuenta Inhabilitada',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu cuenta ha sido inhabilitada por un administrador. '
                  'Para enviar una apelación, primero verifica tu correo electrónico.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _emailError != null ? const Color(0xFFFC6707) : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Ingresa tu correo electrónico',
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 14,
                              color: const Color(0xFF999999),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: _cargando
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFFC6707),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF333333),
                          ),
                          onSubmitted: (_) => _buscarUsuarioPorEmail(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _cargando ? null : _buscarUsuarioPorEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC6707),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Verificar',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_emailError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _emailError!,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFFFC6707),
                        ),
                      ),
                    ),
                  ),
                if (_usuarioEncontrado)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFC6707).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFC6707),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: const Color(0xFFFC6707),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Usuario verificado: $_userName (${_userRol ?? 'usuario'})',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _apelacionController,
                    maxLines: 4,
                    enabled: _usuarioEncontrado,
                    decoration: InputDecoration(
                      hintText: _usuarioEncontrado
                          ? 'Escribe tu apelación aquí...'
                          : 'Primero verifica tu correo',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF999999),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: _usuarioEncontrado ? const Color(0xFF333333) : const Color(0xFF999999),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (!_usuarioEncontrado || _enviando) ? null : _enviarApelacion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC6707),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _enviando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Enviar apelación',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _volverAlLogin,
                  child: Text(
                    'Volver al inicio',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFFFC6707),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}