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
import '../../utils/responsive.dart';
import '../student/terms_view.dart';

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

  // Helper para obtener error de nombre
  String? _getNombreError() {
    if (!_showErrors) return null;
    if (_nombresController.text.isEmpty) return 'El nombre es obligatorio';
    if (_nombresController.text.length < 3) return 'Mínimo 3 caracteres';
    if (RegExp(r'[0-9]').hasMatch(_nombresController.text)) return 'No puede contener números';
    return null;
  }

  // Helper para obtener error de apellido
  String? _getApellidoError() {
    if (!_showErrors) return null;
    if (_apellidosController.text.isEmpty) return 'El apellido es obligatorio';
    if (_apellidosController.text.length < 3) return 'Mínimo 3 caracteres';
    if (RegExp(r'[0-9]').hasMatch(_apellidosController.text)) return 'No puede contener números';
    return null;
  }

  // Helper para obtener error de carnet
  String? _getCarnetError() {
    if (!_showErrors) return null;
    if (_carnetController.text.isEmpty) return 'El carnet es obligatorio';
    return FormValidators.validarCarnet(_carnetController.text);
  }

  // Helper para obtener error de email
  String? _getEmailError() {
    if (!_showErrors) return null;
    if (_emailController.text.isEmpty) return 'El correo es obligatorio';
    return FormValidators.validarCorreoUnimet(_emailController.text);
  }

  // Helper para obtener error de contraseña
  String? _getPasswordError() {
    if (!_showErrors) return null;
    if (_passwordController.text.isEmpty) return 'La contraseña es obligatoria';
    return FormValidators.validarPassword(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    // Cell 
    if (isMobile) {
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
              const Text(
                'Crea tu Cuenta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tus datos para unirte a la comunidad',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nombres',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nombresController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 14),
                          decoration: _mobileInputDecoration(
                            hint: 'Ej: Juan David',
                            errorText: _getNombreError(),
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
                        const Text(
                          'Apellidos',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _apellidosController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 14),
                          decoration: _mobileInputDecoration(
                            hint: 'Ej: Pérez Díaz',
                            errorText: _getApellidoError(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fecha de Nacimiento',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
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
                        style: TextStyle(
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
                const Padding(
                  padding: EdgeInsets.only(top: 4, left: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'La fecha de nacimiento es obligatoria',
                      style: TextStyle(color: Color(0xFFFC6707), fontSize: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Número de Carnet Unimet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _carnetController,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 14),
                decoration: _mobileInputDecoration(
                  hint: 'Ej: 20251234567',
                  errorText: _getCarnetError(),
                ),
              ),
              const SizedBox(height: 16),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Correo Institucional',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14),
                decoration: _mobileInputDecoration(
                  hint: 'ejemplo@correo.unimet.edu.ve',
                  errorText: _getEmailError(),
                ),
              ),
              const SizedBox(height: 16),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Contraseña',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                onChanged: (_) => setState(() {}),
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ingrese su contraseña (mínimo 8 caracteres)',
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  errorText: _getPasswordError(),
                  errorStyle: const TextStyle(color: Color(0xFFFC6707), fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5)),
                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5)),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TermsView()),
                        );
                      },
                      child: const Text(
                        'He leído y acepto los Términos de Servicio y la Política de Privacidad',
                        style: TextStyle(
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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC6707),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Computadora 
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
                fontSize: Responsive.fontSize(context, 24),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.height(context, 8)),
            Text(
              'Ingresa tus datos para unirte a la comunidad',
              style: GoogleFonts.outfit(
                fontSize: Responsive.fontSize(context, 14),
                fontWeight: FontWeight.w400,
                color: const Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.height(context, 28)),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nombres',
                        style: GoogleFonts.outfit(
                          fontSize: Responsive.fontSize(context, 14),
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: Responsive.height(context, 8)),
                      TextFormField(
                        controller: _nombresController,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 14)),
                        decoration: _inputDecoration(context,
                          hint: 'Ej: Juan David',
                          errorText: _getNombreError(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Responsive.width(context, 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apellidos',
                        style: GoogleFonts.outfit(
                          fontSize: Responsive.fontSize(context, 14),
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: Responsive.height(context, 8)),
                      TextFormField(
                        controller: _apellidosController,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 14)),
                        decoration: _inputDecoration(context,
                          hint: 'Ej: Pérez Díaz',
                          errorText: _getApellidoError(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.height(context, 16)),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Fecha de Nacimiento',
                style: GoogleFonts.outfit(
                  fontSize: Responsive.fontSize(context, 14),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            SizedBox(height: Responsive.height(context, 8)),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 16), vertical: Responsive.padding(context, 16)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(Responsive.padding(context, 12)),
                  border: (_showErrors && _selectedFechaNacimiento == null)
                      ? Border.all(color: const Color(0xFFFC6707), width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFFFC6707), size: 20),
                    SizedBox(width: Responsive.width(context, 12)),
                    Text(
                      _fechaNacimientoTexto.isEmpty ? 'Selecciona tu fecha de nacimiento' : _fechaNacimientoTexto,
                      style: GoogleFonts.outfit(
                        fontSize: Responsive.fontSize(context, 14),
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
                padding: EdgeInsets.only(top: Responsive.height(context, 4), left: Responsive.padding(context, 16)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'La fecha de nacimiento es obligatoria',
                    style: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: Responsive.fontSize(context, 12)),
                  ),
                ),
              ),
            SizedBox(height: Responsive.height(context, 16)),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Número de Carnet Unimet',
                style: GoogleFonts.outfit(
                  fontSize: Responsive.fontSize(context, 14),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            SizedBox(height: Responsive.height(context, 8)),
            TextFormField(
              controller: _carnetController,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 14)),
              decoration: _inputDecoration(context,
                hint: 'Ej: 20251234567',
                errorText: _getCarnetError(),
              ),
            ),
            SizedBox(height: Responsive.height(context, 16)),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Correo Institucional',
                style: GoogleFonts.outfit(
                  fontSize: Responsive.fontSize(context, 14),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            SizedBox(height: Responsive.height(context, 8)),
            TextFormField(
              controller: _emailController,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 14)),
              decoration: _inputDecoration(context,
                hint: 'ejemplo@correo.unimet.edu.ve',
                errorText: _getEmailError(),
              ),
            ),
            SizedBox(height: Responsive.height(context, 16)),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Contraseña',
                style: GoogleFonts.outfit(
                  fontSize: Responsive.fontSize(context, 14),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            SizedBox(height: Responsive.height(context, 8)),
            TextFormField(
              controller: _passwordController,
              onChanged: (_) => setState(() {}),
              obscureText: _obscurePassword,
              style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 14)),
              decoration: InputDecoration(
                hintText: 'Ingrese su contraseña (mínimo 8 caracteres)',
                hintStyle: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 14), color: const Color(0xFF999999)),
                errorText: _getPasswordError(),
                errorStyle: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: Responsive.fontSize(context, 12)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12)), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12)), borderSide: const BorderSide(color: Colors.transparent)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12)), borderSide: BorderSide.none),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12)), borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5)),
                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12)), borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 16), vertical: Responsive.padding(context, 16)),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF999999)),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            SizedBox(height: Responsive.height(context, 16)),

            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                  child: Container(
                    width: Responsive.width(context, 22),
                    height: Responsive.height(context, 22),
                    decoration: BoxDecoration(
                      color: _acceptTerms ? const Color(0xFFFC6707) : const Color(0xFFFDDBB3),
                      borderRadius: BorderRadius.circular(Responsive.padding(context, 4)),
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: _acceptTerms
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                SizedBox(width: Responsive.width(context, 8)),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsView()),
                      );
                    },
                    child: Text(
                      'He leído y acepto los Términos de Servicio y la Política de Privacidad',
                      style: GoogleFonts.outfit(
                        fontSize: Responsive.fontSize(context, 12),
                        fontWeight: FontWeight.w400,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.height(context, 24)),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC6707),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: Responsive.padding(context, 16)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12))),
                ),
                child: Text(
                  'Registrarse',
                  style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cell 
  InputDecoration _mobileInputDecoration({required String hint, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
      errorText: errorText,
      errorStyle: const TextStyle(color: Color(0xFFFC6707), fontSize: 12),
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

  // Computadora
  InputDecoration _inputDecoration(BuildContext context, {required String hint, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 14), color: const Color(0xFF999999)),
      errorText: errorText,
      errorStyle: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: Responsive.fontSize(context, 12)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12)), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12)), borderSide: const BorderSide(color: Colors.transparent)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12)), borderSide: BorderSide.none),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12)), borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12)), borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5)),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 16), vertical: Responsive.padding(context, 16)),
    );
  }
}