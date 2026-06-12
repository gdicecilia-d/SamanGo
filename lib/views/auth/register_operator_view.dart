// Pantalla de registro de operador turístico
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'auth_base_view.dart';
import 'login_view.dart';
import 'select_role_view.dart';
import '../../models/validators.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/responsive.dart';
import '../student/terms_view.dart';

class RegisterOperatorView extends StatefulWidget {
  const RegisterOperatorView({super.key});

  @override
  State<RegisterOperatorView> createState() => _RegisterOperatorViewState();
}

class _RegisterOperatorViewState extends State<RegisterOperatorView> {
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _rifNumeroController = TextEditingController();
  final TextEditingController _representanteController = TextEditingController();
  final TextEditingController _telefonoNumeroController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  bool _acceptTerms = false;
  bool _showErrors = false;
  bool _isUploading = false;
  String? _selectedFileName;
  String? _uploadError;

  String _selectedTelefonoPrefijo = '412';
  final List<String> _telefonoOpciones = ['212', '412', '414', '416', '424', '426'];

  String _selectedRifLetra = 'J';
  final List<String> _rifOpciones = ['J', 'V', 'E', 'G', 'P'];

  Uint8List? _selectedFileBytes;

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
        _descripcionController.text.isNotEmpty &&
        _descripcionController.text.length >= 10 &&
        _selectedFileName != null;
  }

  Future<void> _pickFile() async {
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
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
          _selectedFileBytes = file.bytes;
          _isUploading = false;
        });
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Error al seleccionar imagen';
        _isUploading = false;
      });
    }
  }

  void _submitForm() async {
    setState(() {
      _showErrors = true;
    });
    if (!_isFormValid || !_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!_acceptTerms 
              ? 'Debes aceptar los Términos y Condiciones' 
              : 'Por favor completa todos los campos correctamente'),
          backgroundColor: const Color(0xFFFC6707),
        ),
      );
      return;
    }

    final nombreCompleto = _representanteController.text;
    final telefonoCompleto = '0$_selectedTelefonoPrefijo${_telefonoNumeroController.text}';
    final rifCompleto = '$_selectedRifLetra${_rifNumeroController.text}';

    final errorMessage = await Provider.of<AuthController>(context, listen: false).registerOperator(
      email: _emailController.text,
      nombre: nombreCompleto,
      empresa: _empresaController.text,
      rif: rifCompleto,
      telefono: telefonoCompleto,
      descripcion: _descripcionController.text,
      fileBytes: _selectedFileBytes,
    );

    if (!mounted) return;

    if (errorMessage == null) {
      _showSuccessDialog(context);
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
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tus datos para unirte a la comunidad',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 24),

              _buildMobileLabel('Nombre de la Empresa'),
              _buildMobileTextField(
                controller: _empresaController,
                hint: 'Ej: RutaVzla',
                errorText: (_showErrors || _empresaController.text.isNotEmpty) && _empresaController.text.length < 3
                    ? 'Mínimo 3 caracteres'
                    : null,
              ),
              const SizedBox(height: 16),

              _buildMobileLabel('R.I.F.'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMobileRifDropdown(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMobileTextField(
                      controller: _rifNumeroController,
                      hint: 'Ej: 123456789',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      errorText: (_showErrors || _rifNumeroController.text.isNotEmpty) && 
                          !RegExp(r'^\d{8,9}$').hasMatch(_rifNumeroController.text)
                          ? 'Debe tener entre 8 y 9 dígitos'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildMobileLabel('Representante Legal'),
              _buildMobileTextField(
                controller: _representanteController,
                hint: 'Ej: Juan Miguel Moreira',
                errorText: (_showErrors || _representanteController.text.isNotEmpty) && 
                    _representanteController.text.length < 5
                    ? 'Mínimo 5 caracteres'
                    : null,
              ),
              const SizedBox(height: 16),

              _buildMobileLabel('Número de Teléfono'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildMobilePrefijoFijo(),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMobileTelefonoDropdown()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMobileTextField(
                    controller: _telefonoNumeroController,
                    hint: '1234567',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    errorText: (_showErrors || _telefonoNumeroController.text.isNotEmpty) && 
                        !RegExp(r'^\d{7}$').hasMatch(_telefonoNumeroController.text)
                        ? 'Debe tener 7 dígitos'
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildMobileLabel('Email'),
              _buildMobileTextField(
                controller: _emailController,
                hint: 'ejemplo@rutas.com',
                keyboardType: TextInputType.emailAddress,
                errorText: (_showErrors || _emailController.text.isNotEmpty)
                    ? FormValidators.validarEmail(_emailController.text)
                    : null,
              ),
              const SizedBox(height: 16),

              _buildMobileLabel('Descripción Servicios'),
              _buildMobileTextField(
                controller: _descripcionController,
                hint: 'Tipos de tours u ofertas',
                maxLines: 2,
                errorText: (_showErrors || _descripcionController.text.isNotEmpty) && 
                    _descripcionController.text.length < 10
                    ? 'Mínimo 10 caracteres'
                    : null,
              ),
              const SizedBox(height: 16),

              _buildMobileLabel('Subir Licencia de Turismo'),
              _buildMobileFilePicker(),
              const SizedBox(height: 16),

              _buildMobileTermsCheckbox(),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _submitForm,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFC6707),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    'Solicitar Registro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            ),
            SizedBox(height: Responsive.height(context, 8)),
            Text(
              'Ingresa tus datos para unirte a la comunidad',
              style: GoogleFonts.outfit(
                fontSize: Responsive.fontSize(context, 14),
                fontWeight: FontWeight.w400,
                color: const Color(0xFF666666),
              ),
            ),
            SizedBox(height: Responsive.height(context, 28)),

            _buildLabel(context, 'Nombre de la Empresa'),
            _buildTextField(context,
              controller: _empresaController,
              hint: 'Ej: RutaVzla',
              errorText: (_showErrors || _empresaController.text.isNotEmpty) && _empresaController.text.length < 3
                  ? 'Mínimo 3 caracteres'
                  : null,
            ),
            SizedBox(height: Responsive.height(context, 16)),

            _buildLabel(context, 'R.I.F.'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRifDropdown(context),
                SizedBox(width: Responsive.width(context, 12)),
                Expanded(
                  child: _buildTextField(context,
                    controller: _rifNumeroController,
                    hint: 'Ej: 123456789',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    errorText: (_showErrors || _rifNumeroController.text.isNotEmpty) && 
                        !RegExp(r'^\d{8,9}$').hasMatch(_rifNumeroController.text)
                        ? 'Debe tener entre 8 y 9 dígitos'
                        : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.height(context, 16)),

            _buildLabel(context, 'Representante Legal'),
            _buildTextField(context,
              controller: _representanteController,
              hint: 'Ej: Juan Miguel Moreira',
              errorText: (_showErrors || _representanteController.text.isNotEmpty) && 
                  _representanteController.text.length < 5
                  ? 'Mínimo 5 caracteres'
                  : null,
            ),
            SizedBox(height: Responsive.height(context, 16)),

            _buildLabel(context, 'Número de Teléfono'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildPrefijoFijo(context),
                    SizedBox(width: Responsive.width(context, 12)),
                    Expanded(child: _buildTelefonoDropdown(context)),
                  ],
                ),
                SizedBox(height: Responsive.height(context, 12)),
                _buildTextField(context,
                  controller: _telefonoNumeroController,
                  hint: '1234567',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  errorText: (_showErrors || _telefonoNumeroController.text.isNotEmpty) && 
                      !RegExp(r'^\d{7}$').hasMatch(_telefonoNumeroController.text)
                      ? 'Debe tener 7 dígitos'
                      : null,
                ),
              ],
            ),
            SizedBox(height: Responsive.height(context, 16)),

            _buildLabel(context, 'Email'),
            _buildTextField(context,
              controller: _emailController,
              hint: 'ejemplo@rutas.com',
              keyboardType: TextInputType.emailAddress,
              errorText: (_showErrors || _emailController.text.isNotEmpty)
                  ? FormValidators.validarEmail(_emailController.text)
                  : null,
            ),
            SizedBox(height: Responsive.height(context, 16)),

            _buildLabel(context, 'Descripción Servicios'),
            _buildTextField(context,
              controller: _descripcionController,
              hint: 'Tipos de tours u ofertas',
              maxLines: 2,
              errorText: (_showErrors || _descripcionController.text.isNotEmpty) && 
                  _descripcionController.text.length < 10
                  ? 'Mínimo 10 caracteres'
                  : null,
            ),
            SizedBox(height: Responsive.height(context, 16)),

            _buildLabel(context, 'Subir Licencia de Turismo'),
            _buildFilePicker(context),
            SizedBox(height: Responsive.height(context, 16)),

            _buildTermsCheckbox(context),
            SizedBox(height: Responsive.height(context, 24)),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _submitForm,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFC6707),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: Responsive.padding(context, 16)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12))),
                ),
                child: Text('Solicitar Registro', style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cell
  
  Widget _buildMobileLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildMobileTextField({
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
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
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
          ),
        ),
      ],
    );
  }

  Widget _buildMobileRifDropdown() {
    return Container(
      width: 70,
      height: 54,
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonFormField<String>(
        value: _selectedRifLetra,
        items: _rifOpciones.map((letra) {
          return DropdownMenuItem(value: letra, child: Text(letra, style: const TextStyle(fontSize: 16)));
        }).toList(),
        onChanged: (value) => setState(() => _selectedRifLetra = value!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildMobilePrefijoFijo() {
    return Container(
      width: 60,
      height: 54,
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
      child: const Center(
        child: Text('+58', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildMobileTelefonoDropdown() {
    return Container(
      height: 54,
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonFormField<String>(
        value: _selectedTelefonoPrefijo,
        items: _telefonoOpciones.map((prefijo) {
          return DropdownMenuItem(value: prefijo, child: Text(prefijo, style: const TextStyle(fontSize: 16)));
        }).toList(),
        onChanged: (value) => setState(() => _selectedTelefonoPrefijo = value!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        isExpanded: true,
      ),
    );
  }

  Widget _buildMobileFilePicker() {
    final hasError = _selectedFileName == null && _showErrors;
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
                    _isUploading ? 'Subiendo...' : (_selectedFileName ?? 'Seleccionar imagen'),
                    style: TextStyle(
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
            child: Text(_uploadError!, style: const TextStyle(color: Color(0xFFFC6707), fontSize: 12)),
          ),
        if (hasError && _uploadError == null)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Debes subir una imagen de la licencia de turismo (JPG, PNG)',
              style: TextStyle(color: Color(0xFFFC6707), fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileTermsCheckbox() {
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
    );
  }

  // Computadora 

  Widget _buildLabel(BuildContext context, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: Responsive.fontSize(context, 14),
          fontWeight: FontWeight.w500,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, {
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
          style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 14)),
          decoration: InputDecoration(
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
          ),
        ),
      ],
    );
  }

  Widget _buildRifDropdown(BuildContext context) {
    return Container(
      width: Responsive.width(context, 80),
      height: Responsive.height(context, 54),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(Responsive.padding(context, 12))),
      child: DropdownButtonFormField<String>(
        value: _selectedRifLetra,
        items: _rifOpciones.map((letra) {
          return DropdownMenuItem(value: letra, child: Text(letra, style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 16))));
        }).toList(),
        onChanged: (value) => setState(() => _selectedRifLetra = value!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildPrefijoFijo(BuildContext context) {
    return Container(
      width: Responsive.width(context, 70),
      height: Responsive.height(context, 54),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(Responsive.padding(context, 12))),
      child: Center(
        child: Text('+58', style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildTelefonoDropdown(BuildContext context) {
    return Container(
      height: Responsive.height(context, 54),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(Responsive.padding(context, 12))),
      child: DropdownButtonFormField<String>(
        value: _selectedTelefonoPrefijo,
        items: _telefonoOpciones.map((prefijo) {
          return DropdownMenuItem(value: prefijo, child: Text(prefijo, style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 16))));
        }).toList(),
        onChanged: (value) => setState(() => _selectedTelefonoPrefijo = value!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        isExpanded: true,
      ),
    );
  }

  Widget _buildFilePicker(BuildContext context) {
    final hasError = _selectedFileName == null && _showErrors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _isUploading ? null : _pickFile,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 16), vertical: Responsive.padding(context, 16)),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(Responsive.padding(context, 12)),
              border: Border.all(
                color: hasError ? const Color(0xFFFC6707) : const Color(0xFFE0E0E0),
                width: hasError ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(_isUploading ? Icons.cloud_upload : Icons.upload_file, color: const Color(0xFFFC6707), size: Responsive.width(context, 20)),
                SizedBox(width: Responsive.width(context, 12)),
                Expanded(
                  child: Text(
                    _isUploading ? 'Subiendo...' : (_selectedFileName ?? 'Seleccionar imagen'),
                    style: GoogleFonts.outfit(
                      fontSize: Responsive.fontSize(context, 14),
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
            padding: EdgeInsets.only(top: Responsive.height(context, 6)),
            child: Text(_uploadError!, style: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: Responsive.fontSize(context, 12))),
          ),
        if (hasError && _uploadError == null)
          Padding(
            padding: EdgeInsets.only(top: Responsive.height(context, 6)),
            child: Text(
              'Debes subir una imagen de la licencia de turismo (JPG, PNG)',
              style: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: Responsive.fontSize(context, 12)),
            ),
          ),
      ],
    );
  }

  Widget _buildTermsCheckbox(BuildContext context) {
    return Row(
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
              SizedBox(height: Responsive.height(context, 16)),
              Text('¡Solicitud Enviada!', style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 22), fontWeight: FontWeight.bold, color: const Color(0xFF333333))),
            ],
          ),
          content: Text(
            'Se ha enviado tu solicitud de registro.\nTe llegará un correo con los datos de inicio de sesión una vez sea aprobada.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 14), color: const Color(0xFF666666)),
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
                  padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 32), vertical: Responsive.padding(context, 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12))),
                ),
                child: Text('Volver a Iniciar Sesión', style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 14), fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      },
    );
  }
}