// olvidar clave
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_base_view.dart';
import 'login_view.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthBaseView(
      bottomText: '',
      bottomLinkText: null,
      onBottomLinkTap: null,
      formContent: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '¿Olvidaste tu Contraseña?',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Ingresa tu correo institucional UNIMET y te enviaremos un enlace para restablecerla',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Campo Correo Institucional
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Correo Institucional',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'ejemplo@correo.unimet.edu.ve',
              hintStyle: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF999999),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 24),

          // Botón Enviar Enlace
          SizedBox(
            width: double.infinity,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Conectar con Firebase Auth - reset password
                  print('Enviar enlace de restablecimiento');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Se ha enviado un enlace a tu correo'),
                      backgroundColor: Color(0xFFFC6707),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC6707),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Enviar Enlace',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Link Volver a Iniciar Sesión
          Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginView()),
                    (route) => false,
                  );
                },
                child: Text(
                  'Volver a Iniciar Sesión',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFFFC6707),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}