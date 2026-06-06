// registro de estudiantes con date picker
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
  
  DateTime? _selectedFechaNacimiento;
  bool _obscurePassword = true;
  bool _acceptTerms = false;
  bool _showErrors = false;

  bool get _isFormValid {
    return _nombresController.text.isNotEmpty &&
        _nombresController.text.length >= 3 &&
        _apellidosController.text.isNotEmpty &&
        _apellidosController.text.length >= 3 &&
        FormValidators.validarCarnet(_carnetController.text) == null &&
        FormValidators.validarCorreoUnimet(_emailController.text) == null &&
        FormValidators.validarPassword(_passwordController.text) == null &&
        _selectedFechaNacimiento != null &&
        _acceptTerms;
  }

  String get _fechaNacimientoTexto {
    if (_selectedFechaNacimiento == null) return '';
    return "${_selectedFechaNacimiento!.day.toString().padLeft(2, '0')}/"
        "${_selectedFechaNacimiento!.month.toString().padLeft(2, '0')}/"
        "${_selectedFechaNacimiento!.year}";
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFC6707),
              onPrimary: Colors.white,
              onSurface: Color(0xFF333333),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedFechaNacimiento = picked;
      });
    }
  }

  void _submitForm() async {
    setState(() {
      _showErrors = true;
    });
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos correctamente'),
          backgroundColor: Color(0xFFFC6707),
        ),
      );
      return;
    }

    final errorMessage = await Provider.of<AuthController>(context, listen: false).registerStudent(
      email: _emailController.text,
      password: _passwordController.text,
      nombre: _nombresController.text,
      apellido: _apellidosController.text,
      carnet: _carnetController.text,
      fechaNacimiento: _fechaNacimientoTexto,
    );

    if (!mounted) return;

    if (errorMessage == null) {
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
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFFC6707),
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
      formContent: SingleChildScrollView(
        child: Column(
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

            // Nombres y Apellidos
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
                          errorText: (_showErrors && _nombresController.text.isEmpty) ||
                              (_nombresController.text.isNotEmpty && _nombresController.text.length < 3)
                              ? 'Mínimo 3 caracteres'
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
                          errorText: (_showErrors && _apellidosController.text.isEmpty) ||
                              (_apellidosController.text.isNotEmpty && _apellidosController.text.length < 3)
                              ? 'Mínimo 3 caracteres'
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fecha de Nacimiento (Date Picker)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Fecha de Nacimiento',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: (_showErrors && _selectedFechaNacimiento == null)
                      ? Border.all(color: const Color(0xFFFC6707), width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFFFC6707), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _fechaNacimientoTexto.isEmpty ? 'Selecciona tu fecha de nacimiento' : _fechaNacimientoTexto,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: _fechaNacimientoTexto.isEmpty 
                            ? const Color(0xFF999999) 
                            : const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showErrors && _selectedFechaNacimiento == null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'La fecha de nacimiento es obligatoria',
                    style: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: 12),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Carnet
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
                errorText: (_showErrors && _carnetController.text.isNotEmpty)
                    ? FormValidators.validarCarnet(_carnetController.text)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Correo
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
                errorText: (_showErrors && _emailController.text.isNotEmpty)
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
                hintText: 'Ingrese su contraseña (mínimo 8 caracteres)',
                hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
                errorText: (_showErrors && _passwordController.text.isNotEmpty)
                    ? FormValidators.validarPassword(_passwordController.text)
                    : null,
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
            const SizedBox(height: 16),

            // Checkbox Términos
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
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Términos y Condiciones', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          content: SingleChildScrollView(
                            child: Text('Aquí van los términos y condiciones de la aplicación...', style: GoogleFonts.outfit()),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cerrar', style: GoogleFonts.outfit(color: const Color(0xFFFC6707))),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text(
                      'He leído y acepto los Términos de Servicio y la Política de Privacidad',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
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
                onPressed: _submitForm,
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