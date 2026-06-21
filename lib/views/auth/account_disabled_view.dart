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
  final TextEditingController _apelacionController = TextEditingController();
  bool _enviando = false;
  String? _userId;
  String? _userEmail;
  String? _userName;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _apelacionController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    setState(() => _cargando = true);
    
    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      
      if (auth.usuarioActual != null && auth.usuarioActual!.id.isNotEmpty) {
        final usuario = auth.usuarioActual!;
        setState(() {
          _userId = usuario.id;
          _userEmail = usuario.correo;
          _userName = usuario.nombre;
          _cargando = false;
        });
        return;
      }

      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      if (firebaseUser != null) {
        final uid = firebaseUser.uid;
        final email = firebaseUser.email;
        
        final estudianteDoc = await FirebaseFirestore.instance
            .collection('estudiantes')
            .doc(uid)
            .get();
        
        if (estudianteDoc.exists) {
          final data = estudianteDoc.data() as Map<String, dynamic>?;
          setState(() {
            _userId = uid;
            _userEmail = email ?? data?['correo'] ?? '';
            _userName = data?['nombre'] ?? 'Usuario';
            _cargando = false;
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
            _userEmail = email ?? data?['correo'] ?? '';
            _userName = data?['nombre'] ?? 'Usuario';
            _cargando = false;
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
            _userEmail = email ?? data?['correo'] ?? '';
            _userName = data?['nombre'] ?? 'Usuario';
            _cargando = false;
          });
          return;
        }
        
        setState(() {
          _userId = uid;
          _userEmail = email ?? '';
          _userName = 'Usuario';
          _cargando = false;
        });
      } else {
        setState(() {
          _userId = 'usuario_desconocido_${DateTime.now().millisecondsSinceEpoch}';
          _userEmail = '';
          _userName = 'Usuario';
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _userId = 'usuario_desconocido_${DateTime.now().millisecondsSinceEpoch}';
        _userEmail = '';
        _userName = 'Usuario';
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
          content: Text('No se pudo identificar al usuario. Cerrando sesión...'),
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
            child: _cargando
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: Color(0xFFFC6707)),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.block,
                          color: const Color(0xFFFF9800),
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
                        'No puedes acceder a la plataforma en este momento. '
                        'Si consideras que se trata de un error, puedes enviar una '
                        'apelación para que tu caso sea revisado.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _apelacionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Escribe tu apelación aquí...',
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 14,
                              color: const Color(0xFF999999),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _enviando ? null : _enviarApelacion,
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