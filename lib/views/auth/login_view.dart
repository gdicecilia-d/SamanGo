// Pag de iniciar sesión 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_base_view.dart';
import 'forgot_password_view.dart';
import 'select_role_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return AuthBaseView(
      bottomText: '¿No tienes cuenta? ',
      bottomLinkText: 'Regístrate Aquí',
      onBottomLinkTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SelectRoleView()),
        );
      },
      formContent: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Iniciar Sesión',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 32),

          // Campo Correo
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
          const SizedBox(height: 16),

          // Campo Contraseña
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Contraseña',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Ingrese su contraseña',
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
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF999999),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Link olvidé contraseña
          Align(
            alignment: Alignment.centerRight,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordView()),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: Colors.transparent,
                ),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botón Iniciar Sesión
          SizedBox(
            width: double.infinity,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton(
                onPressed: () {
                  print('Iniciar Sesión - Conectar con Firebase');
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
                  'Iniciar Sesión',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Botón Google
          SizedBox(
            width: double.infinity,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: OutlinedButton(
                onPressed: () {
                  print('Continuar con Google - Conectar con Firebase');
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDDBB3),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/google_logo.png',
                      height: 20,
                      width: 20,
                      errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Continuar con Google',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}