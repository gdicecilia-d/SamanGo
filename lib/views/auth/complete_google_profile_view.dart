import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'auth_base_view.dart';
import '../../models/validators.dart';
import '../../controllers/auth_controller.dart';
import '../student/student_home_view.dart';
import 'login_view.dart';
import '../../utils/responsive.dart';

class CompleteGoogleProfileView extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CompleteGoogleProfileView({super.key, required this.userData});

  @override
  State<CompleteGoogleProfileView> createState() => _CompleteGoogleProfileViewState();
}

class _CompleteGoogleProfileViewState extends State<CompleteGoogleProfileView> {
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _carnetController = TextEditingController();
  
  DateTime? _selectedFechaNacimiento;
  bool _isLoading = false;
  bool _acceptTerms = false;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    if (widget.userData['displayName'] != null && widget.userData['displayName'].isNotEmpty) {
      final names = widget.userData['displayName'].split(' ');
      if (names.isNotEmpty) _nombresController.text = names[0];
      if (names.length > 1) _apellidosController.text = names.sublist(1).join(' ');
    }
  }

  String get _fechaNacimientoTexto {
    if (_selectedFechaNacimiento == null) return '';
    return "${_selectedFechaNacimiento!.day.toString().padLeft(2, '0')}/"
        "${_selectedFechaNacimiento!.month.toString().padLeft(2, '0')}/"
        "${_selectedFechaNacimiento!.year}";
  }

  bool get _isFormValid {
    return _nombresController.text.isNotEmpty &&
        _nombresController.text.length >= 3 &&
        _apellidosController.text.isNotEmpty &&
        _apellidosController.text.length >= 3 &&
        FormValidators.validarCarnet(_carnetController.text) == null &&
        _selectedFechaNacimiento != null &&
        _acceptTerms;
  }

  void _mostrarMensaje(String mensaje, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFFC6707),
        duration: const Duration(seconds: 2),
      ),
    );
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

  Future<void> _submitForm() async {
    setState(() {
      _showErrors = true;
    });
    
    if (!_isFormValid) {
      _mostrarMensaje('Por favor completa todos los campos correctamente', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authController = Provider.of<AuthController>(context, listen: false);
    final error = await authController.completeGoogleProfile(
      uid: widget.userData['uid'],
      email: widget.userData['email'],
      nombre: _nombresController.text.trim(),
      apellido: _apellidosController.text.trim(),
      carnet: _carnetController.text.trim(),
      fechaNacimiento: _fechaNacimientoTexto,
      photoUrl: widget.userData['photoUrl'],
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error == null) {
      _mostrarMensaje('Perfil completado exitosamente', isError: false);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomeView()),
      );
    } else {
      _mostrarMensaje(error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    // Cell 
    if (isMobile) {
      return AuthBaseView(
        onBackPressed: () {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
        },
        formContent: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Completa tu perfil',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tus datos para continuar',
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
                  errorText: (_showErrors && _carnetController.text.isNotEmpty)
                      ? FormValidators.validarCarnet(_carnetController.text)
                      : null,
                ),
              ),
              const SizedBox(height: 24),

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
                            title: const Text('Términos y Condiciones'),
                            content: const SingleChildScrollView(
                              child: Text('Términos y condiciones de SamanGo...'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cerrar', style: TextStyle(color: Color(0xFFFC6707))),
                              ),
                            ],
                          ),
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
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC6707),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
      },
      formContent: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Completa tu perfil',
              style: GoogleFonts.outfit(
                fontSize: Responsive.fontSize(context, 24),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.height(context, 8)),
            Text(
              'Ingresa tus datos para continuar',
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
                          errorText: (_showErrors && _nombresController.text.isEmpty) ||
                              (_nombresController.text.isNotEmpty && _nombresController.text.length < 3)
                              ? 'Mínimo 3 caracteres'
                              : null,
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
                errorText: (_showErrors && _carnetController.text.isNotEmpty)
                    ? FormValidators.validarCarnet(_carnetController.text)
                    : null,
              ),
            ),
            SizedBox(height: Responsive.height(context, 24)),

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
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Términos y Condiciones', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          content: SingleChildScrollView(
                            child: Text('Términos y condiciones de SamanGo...', style: GoogleFonts.outfit()),
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
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC6707),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: Responsive.padding(context, 16)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12))),
                ),
                child: _isLoading
                    ? SizedBox(height: Responsive.height(context, 20), width: Responsive.width(context, 20), child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Continuar', style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.bold, color: Colors.white)),
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

  // Computadora - código original intacto
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