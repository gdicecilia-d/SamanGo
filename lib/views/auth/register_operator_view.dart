// Pantalla de registro de operador turístico
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/validators.dart';
import 'auth_base_view.dart';
import 'login_view.dart';
import 'select_role_view.dart';

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

  // Form key para validación global
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Variables de estado
  bool _obscurePassword = true;
  bool _acceptTerms = false;
  bool _isUploading = false;
  String? _selectedFileName;
  String? _uploadError;

  // Selección de teléfono
  String _selectedTelefonoPrefijo = '412';
  final List<String> _telefonoOpciones = ['212', '412', '414', '416', '424', '426'];

  // Selección de RIF
  String _selectedRifLetra = 'J';
  final List<String> _rifOpciones = ['J', 'V', 'E', 'G', 'P'];

  // Validar todo el formulario y archivo
  bool get _isFormValid {
    return _formKey.currentState?.validate() == true &&
        FormValidators.validarArchivo(_selectedFileName) == null &&
        _acceptTerms;
  }

  // Seleccionar archivo
  Future<void> _pickFile() async {
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
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
    if (_formKey.currentState!.validate()) {
      if (FormValidators.validarArchivo(_selectedFileName) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes subir la licencia de turismo'),
            backgroundColor: Color(0xFFFC6707),
          ),
        );
        return;
      }
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes aceptar los términos y condiciones'),
            backgroundColor: Color(0xFFFC6707),
          ),
        );
        return;
      }
      _showSuccessDialog(context);
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
        child: Form(
          key: _formKey,
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
              _buildTextField(_empresaController, 'Ej: RutaVzla', FormValidators.validarEmpresa),
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
                      _rifNumeroController,
                      'Ej: 123456789',
                      FormValidators.validarRifNumero,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Representante Legal
              _buildLabel('Representante Legal'),
              _buildTextField(_representanteController, 'Ej: Juan Miguel Moreira', FormValidators.validarRepresentante),
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
                      _telefonoNumeroController,
                      '1234567',
                      FormValidators.validarTelefonoNumero,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email
              _buildLabel('Email'),
              _buildTextField(_emailController, 'ejemplo@rutas.com', FormValidators.validarEmail,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),

              // Contraseña
              _buildLabel('Contraseña'),
              _buildPasswordField(),
              const SizedBox(height: 16),

              // Descripción Servicios
              _buildLabel('Descripción Servicios'),
              _buildTextField(_descripcionController, 'Tipos de tours u ofertas', FormValidators.validarDescripcion,
                  maxLines: 2),
              const SizedBox(height: 16),

              // Subir Licencia
              _buildLabel('Subir Licencia de Turismo'),
              _buildFilePicker(),
              const SizedBox(height: 16),

              // Checkbox Términos
              _buildTermsCheckbox(),
              const SizedBox(height: 24),

              // Botón Solicitar Registro
              _buildSubmitButton(),
            ],
          ),
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

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    String? Function(String?) validator, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: _inputDecoration(hint),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      validator: FormValidators.validarPassword,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Ingrese su contraseña',
        hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
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
      onChanged: (_) => setState(() {}),
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
    final hasError = FormValidators.validarArchivo(_selectedFileName) != null && !_isUploading;
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
                      color: hasError ? Colors.red : const Color(0xFF666666),
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
              FormValidators.validarArchivo(_selectedFileName)!,
              style: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptTerms,
            onChanged: (value) => setState(() => _acceptTerms = value ?? false),
            activeColor: const Color(0xFFFC6707),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'He leído y acepto los Términos de Servicio y la Política de Privacidad',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF666666)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFC6707),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text('Solicitar Registro', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
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