// registro de estudiantes
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_base_view.dart';
import 'login_view.dart';
import 'select_role_view.dart';

class RegisterStudentView extends StatefulWidget {
  const RegisterStudentView({super.key});

  @override
  State<RegisterStudentView> createState() => _RegisterStudentViewState();
}

class _RegisterStudentViewState extends State<RegisterStudentView> {
  bool _obscurePassword = true;
  bool _acceptTerms = false;

  @override
  Widget build(BuildContext context) {
    return AuthBaseView(
      onBackPressed: () {
        Navigator.pop(context); // Simple: vuelve a la pantalla anterior
      },
      bottomText: '¿Ya tienes cuenta? ',
      bottomLinkText: 'Inicia Sesión',
      onBottomLinkTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      },
      formContent: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Crea tu Cuenta',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa tus datos para unirte a la comunidad',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Campo Nombre Completo
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Nombre Completo',
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
              hintText: 'Ej: Juan Davíd Pérez Díaz',
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

          // Campo Número de Carnet
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Número de Carnet Unimet',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ej: 2025123456',
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
            keyboardType: TextInputType.emailAddress,
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
          const SizedBox(height: 16),

          // Checkbox Términos y Condiciones
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptTerms = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFFFC6707),
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'He leído y acepto los Términos de Servicio y la Política de Privacidad',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botón Registrarse
          SizedBox(
            width: double.infinity,
            child: MouseRegion(
              cursor: _acceptTerms ? SystemMouseCursors.click : SystemMouseCursors.basic,
              child: ElevatedButton(
                onPressed: _acceptTerms
                    ? () {
                        print('Registrar Estudiante');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Registro exitoso. Ahora inicia sesión.'),
                            backgroundColor: Color(0xFFFC6707),
                          ),
                        );
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginView()),
                          (route) => false,
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC6707),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: const Color(0xFFFDDBB3),
                ),
                child: Text(
                  'Registrarse',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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