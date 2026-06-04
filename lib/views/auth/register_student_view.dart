// registro de estudiantes 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_base_view.dart';
import 'login_view.dart';
import 'select_role_view.dart';
import '../../models/validators.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class RegisterStudentView extends StatefulWidget {
  const RegisterStudentView({super.key});

  @override
  State<RegisterStudentView> createState() => _RegisterStudentViewState();
}

class _RegisterStudentViewState extends State<RegisterStudentView> {
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _carnetController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _acceptTerms = false;

  bool get _isFormValid {
    return FormValidators.validarNombre(_nombresController.text) == null &&
        FormValidators.validarNombre(_apellidosController.text) == null &&
        FormValidators.validarCarnet(_carnetController.text) == null &&
        FormValidators.validarCorreoUnimet(_emailController.text) == null &&
        FormValidators.validarPassword(_passwordController.text) == null &&
        _acceptTerms;
  }

  void _submitForm() async {
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos correctamente'),
          backgroundColor: Color(0xFFFC6707),
        ),
      );
      return;
    }

    final nombreCompleto = '${_nombresController.text} ${_apellidosController.text}';

    final success = await Provider.of<AuthController>(context, listen: false).registerStudent(
      email: _emailController.text,
      password: _passwordController.text,
      nombre: nombreCompleto,
      carnet: _carnetController.text,
    );

    if (!mounted) return;

    if (success) {
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error en el registro. Intenta nuevamente.'),
          backgroundColor: Color(0xFFFC6707),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBaseView(
      onBackPressed: () {
        Navigator.pop(context);
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

          // Nombres y Apellidos en la misma fila
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombres',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nombresController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: 'Ej: Juan David',
                        errorText: _nombresController.text.isNotEmpty 
                            ? FormValidators.validarNombre(_nombresController.text) 
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apellidos',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _apellidosController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: 'Ej: Pérez Díaz',
                        errorText: _apellidosController.text.isNotEmpty 
                            ? FormValidators.validarNombre(_apellidosController.text) 
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Número de Carnet
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
          TextFormField(
            controller: _carnetController,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: _inputDecoration(
              hint: 'Ej: 20251234567',
              errorText: _carnetController.text.isNotEmpty 
                  ? FormValidators.validarCarnet(_carnetController.text)
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Correo Institucional
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
          TextFormField(
            controller: _emailController,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: _inputDecoration(
              hint: 'ejemplo@correo.unimet.edu.ve',
              errorText: _emailController.text.isNotEmpty 
                  ? FormValidators.validarCorreoUnimet(_emailController.text)
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Contraseña
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
          TextFormField(
            controller: _passwordController,
            onChanged: (_) => setState(() {}),
            obscureText: _obscurePassword,
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ingrese su contraseña (mínimo 6 caracteres)',
              hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5)),
              errorStyle: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: 12),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF999999)),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          if (_passwordController.text.isNotEmpty && _passwordController.text.length < 6)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mínimo 6 caracteres',
                  style: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Checkbox Términos y Condiciones
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _acceptTerms ? const Color(0xFFFC6707) : const Color(0xFFFDDBB3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: _acceptTerms
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
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
            child: TextButton(
              onPressed: _isFormValid ? _submitForm : null,
              style: TextButton.styleFrom(
                backgroundColor: _isFormValid ? const Color(0xFFFC6707) : const Color(0xFFFDDBB3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Registrarse',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
      errorText: errorText,
      errorStyle: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5)),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}