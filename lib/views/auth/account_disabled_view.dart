// Pantalla que se muestra cuando una cuenta ha sido inhabilitada
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    setState(() => _enviando = true);

    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final usuario = auth.usuarioActual;

      if (usuario == null) {
        _mostrarMensaje('Error: No se pudo identificar al usuario');
        setState(() => _enviando = false);
        return;
      }

      await FirebaseFirestore.instance.collection('reportes').add({
        'estudiante': usuario.nombre,
        'tour': 'Apelación de cuenta',
        'tipo_alerta': 'Apelación',
        'estado': 'amarillo',
        'mensaje': mensaje,
        'fecha': FieldValue.serverTimestamp(),
        'usuarioId': usuario.id,
        'correo': usuario.correo,
      });

      _mostrarMensaje('Apelación enviada correctamente. Será revisada por el administrador.');
      
      await auth.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    } catch (e) {
      _mostrarMensaje('Error al enviar la apelación: $e');
      setState(() => _enviando = false);
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFFC6707),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _volverAlLogin() async {
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono de bloqueo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF44336).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.block,
                    color: const Color(0xFFF44336),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                // Título
                Text(
                  'Cuenta Inhabilitada',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 16),
                // Mensaje
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
                // Campo para apelación
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
                // Botón enviar apelación
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
                // Botón volver al login
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