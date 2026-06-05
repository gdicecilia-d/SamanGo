// Pantalla de registro de operador turístico
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_base_view.dart';
import 'login_view.dart';
import 'select_role_view.dart';
import '../../models/validators.dart';

class RegisterOperatorView extends StatefulWidget {
  const RegisterOperatorView({super.key});

  @override
  State<RegisterOperatorView> createState() => _RegisterOperatorViewState();
}

class _RegisterOperatorViewState extends State<RegisterOperatorView> {
  // Controladores de texto
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _rifNumeroController = TextEditingController();
  final TextEditingController _representanteController = TextEditingController();
  final TextEditingController _telefonoNumeroController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  // Variables de estado
  bool _obscurePassword = true;
  bool _acceptTerms = false;
  bool _showErrors = false;
  final TextEditingController _fechaNacimientoController = TextEditingController();
  bool _isUploading = false;
  String? _selectedFileName;
  String? _uploadError;

  // Selección de teléfono
  String _selectedTelefonoPrefijo = '412';
  final List<String> _telefonoOpciones = ['212', '412', '414', '416', '424', '426'];

  // Selección de RIF
  String _selectedRifLetra = 'J';
  final List<String> _rifOpciones = ['J', 'V', 'E', 'G', 'P'];

  bool get _isFormValid {
    return _empresaController.text.isNotEmpty &&
        _empresaController.text.length >= 3 &&
        _rifNumeroController.text.isNotEmpty &&
        RegExp(r'^\d{8,9}$').hasMatch(_rifNumeroController.text) &&
        _representanteController.text.isNotEmpty &&
        _representanteController.text.length >= 5 &&
        _telefonoNumeroController.text.isNotEmpty &&
        RegExp(r'^\d{7}$').hasMatch(_telefonoNumeroController.text) &&
        FormValidators.validarEmail(_emailController.text) == null &&
        FormValidators.validarPassword(_passwordController.text) == null &&
        _descripcionController.text.isNotEmpty &&
        _descripcionController.text.length >= 10 &&
        _selectedFileName != null &&
        _fechaNacimientoController.text.isNotEmpty;
  }

  // Seleccionar archivo
  Future<void> _pickFile() async {
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          setState(() {
            _uploadError = 'El archivo supera el límite de 5 MB';
            _isUploading = false;
          });
          return;
        }

        setState(() {
          _selectedFileName = file.name;
          _isUploading = false;
        });
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Error al seleccionar archivo';
        _isUploading = false;
      });
    }
  }

  void _submitForm() {
    setState(() {
      _showErrors = true;
    });
    if (!_isFormValid || !_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!_acceptTerms ? 'Debes aceptar los Términos y Condiciones' : 'Por favor completa todos los campos correctamente'),
          backgroundColor: const Color(0xFFFC6707),
        ),
      );
      return;
    }
    _showSuccessDialog(context);
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
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa tus datos para unirte a la comunidad',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF666666)),
            ),
            const SizedBox(height: 28),

            // Nombre de la Empresa
            _buildLabel('Nombre de la Empresa'),
            _buildTextField(
              controller: _empresaController,
              hint: 'Ej: RutaVzla',
              errorText: (_showErrors || _empresaController.text.isNotEmpty) && _empresaController.text.length < 3
                  ? 'Mínimo 3 caracteres'
                  : null,
            ),
            const SizedBox(height: 16),

            // R.I.F. con dropdown
            _buildLabel('R.I.F.'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRifDropdown(),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _rifNumeroController,
                    hint: 'Ej: 123456789',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    errorText: (_showErrors || _rifNumeroController.text.isNotEmpty) && !RegExp(r'^\d{8,9}$').hasMatch(_rifNumeroController.text)
                        ? 'Debe tener entre 8 y 9 dígitos'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Representante Legal
            _buildLabel('Representante Legal'),
            _buildTextField(
              controller: _representanteController,
              hint: 'Ej: Juan Miguel Moreira',
              errorText: (_showErrors || _representanteController.text.isNotEmpty) && _representanteController.text.length < 5
                  ? 'Mínimo 5 caracteres'
                  : null,
            ),
            const SizedBox(height: 16),

            // Número de Teléfono
            _buildLabel('Número de Teléfono'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPrefijoFijo(),
                const SizedBox(width: 8),
                _buildTelefonoDropdown(),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    controller: _telefonoNumeroController,
                    hint: '1234567',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    errorText: (_showErrors || _telefonoNumeroController.text.isNotEmpty) && !RegExp(r'^\d{7}$').hasMatch(_telefonoNumeroController.text)
                        ? 'Debe tener 7 dígitos'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email
            _buildLabel('Email'),
            _buildTextField(
              controller: _emailController,
              hint: 'ejemplo@rutas.com',
              keyboardType: TextInputType.emailAddress,
              errorText: (_showErrors || _emailController.text.isNotEmpty)
                  ? FormValidators.validarEmail(_emailController.text)
                  : null,
            ),
            const SizedBox(height: 16),

            // Contraseña
            _buildLabel('Contraseña'),
            _buildPasswordField(),
            const SizedBox(height: 16),

            // Fecha de Nacimiento
            _buildLabel('Fecha de Nacimiento'),
            _buildTextField(
              controller: _fechaNacimientoController,
              hint: 'Ej: 12/05/2000',
              errorText: (_showErrors && _fechaNacimientoController.text.isEmpty)
                  ? 'La fecha de nacimiento es obligatoria'
                  : null,
            ),
            const SizedBox(height: 16),

            // Descripción Servicios
            _buildLabel('Descripción Servicios'),
            _buildTextField(
              controller: _descripcionController,
              hint: 'Tipos de tours u ofertas',
              maxLines: 2,
              errorText: (_showErrors || _descripcionController.text.isNotEmpty) && _descripcionController.text.length < 10
                  ? 'Mínimo 10 caracteres'
                  : null,
            ),
            const SizedBox(height: 16),

            // Subir Licencia
            _buildLabel('Subir Licencia de Turismo'),
            _buildFilePicker(),
            const SizedBox(height: 16),

            // Checkbox Términos
            _buildTermsCheckbox(),
            const SizedBox(height: 24),

            // Botón Solicitar Registro
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _passwordController.text.isNotEmpty ? _submitForm : null,
                style: TextButton.styleFrom(
                  backgroundColor: _passwordController.text.isNotEmpty ? const Color(0xFFFC6707) : const Color(0xFFFDDBB3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Solicitar Registro', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF333333)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: GoogleFonts.outfit(fontSize: 14),
          decoration: InputDecoration(
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
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    final errorText = (_showErrors || _passwordController.text.isNotEmpty)
        ? FormValidators.validarPassword(_passwordController.text)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passwordController,
          onChanged: (_) => setState(() {}),
          obscureText: _obscurePassword,
          style: GoogleFonts.outfit(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Ingrese su contraseña (mínimo 6 caracteres)',
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
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF999999)),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRifDropdown() {
    return Container(
      width: 80,
      height: 54,
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonFormField<String>(
        value: _selectedRifLetra,
        items: _rifOpciones.map((letra) {
          return DropdownMenuItem(value: letra, child: Text(letra, style: GoogleFonts.outfit(fontSize: 16)));
        }).toList(),
        onChanged: (value) => setState(() => _selectedRifLetra = value!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildPrefijoFijo() {
    return Container(
      width: 70,
      height: 54,
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
      child: const Center(
        child: Text('+58', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildTelefonoDropdown() {
    return Container(
      width: 85,
      height: 54,
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonFormField<String>(
        value: _selectedTelefonoPrefijo,
        items: _telefonoOpciones.map((prefijo) {
          return DropdownMenuItem(value: prefijo, child: Text(prefijo, style: GoogleFonts.outfit(fontSize: 16)));
        }).toList(),
        onChanged: (value) => setState(() => _selectedTelefonoPrefijo = value!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildFilePicker() {
    final hasError = _selectedFileName == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _isUploading ? null : _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError ? const Color(0xFFFC6707) : const Color(0xFFE0E0E0),
                width: hasError ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(_isUploading ? Icons.cloud_upload : Icons.upload_file, color: const Color(0xFFFC6707), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isUploading ? 'Subiendo...' : (_selectedFileName ?? 'Seleccionar Archivos'),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: hasError ? const Color(0xFFFC6707) : const Color(0xFF666666),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_uploadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_uploadError!, style: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: 12)),
          ),
        if (hasError && _uploadError == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Debes subir la licencia de turismo',
              style: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
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
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFFFC6707), size: 60),
              const SizedBox(height: 16),
              Text('¡Solicitud Enviada!', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF333333))),
            ],
          ),
          content: Text(
            'Se ha enviado tu solicitud de registro.\nTe llegará un correo con los datos de inicio de sesión una vez sea aprobada.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF666666)),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginView()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC6707),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Volver a Iniciar Sesión', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      },
    );
  }
}