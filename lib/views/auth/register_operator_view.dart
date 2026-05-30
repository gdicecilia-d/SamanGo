// registro operador
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/licencia_controller.dart';
import 'auth_base_view.dart';
import 'login_view.dart';
import 'select_role_view.dart';

class RegisterOperatorView extends StatefulWidget {
  const RegisterOperatorView({super.key});

  @override
  State<RegisterOperatorView> createState() => _RegisterOperatorViewState();
}

class _RegisterOperatorViewState extends State<RegisterOperatorView> {
  bool _obscurePassword = true;
  bool _acceptTerms = false;

  @override
  Widget build(BuildContext context) {
    // LicenciaController es LOCAL a esta pantalla (ChangeNotifierProvider local)
    return ChangeNotifierProvider(
      create: (_) => LicenciaController(),
      child: Consumer<LicenciaController>(
        builder: (context, licenciaCtrl, _) {
          return AuthBaseView(
      onBackPressed: () {
        Navigator.pop(context); // Vuelve a SelectRoleView
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

            // Nombre de la Empresa
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nombre de la Empresa',
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
                hintText: 'Ej: RutaVzla',
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

            // R.I.F.
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'R.I.F.',
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
                hintText: 'Ej: J-XXXXXXXX-X',
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

            // Representante Legal
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Representante Legal',
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
                hintText: 'Ej: Juan Miguel Moreira',
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

            // Número de Teléfono
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Número de Teléfono',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Ej: +58 412-XXXXXXX',
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

            // Email
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Email',
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
                hintText: 'ejemplo@rutas.com',
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

            // Descripción Servicios
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Descripción Servicios',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Tipos de tours u ofertas',
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

            // Subir Licencia de Turismo — conectado a Firebase Storage real
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Subir Licencia de Turismo',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: licenciaCtrl.isUploading
                  ? null
                  : () {
                      final auth = context.read<AuthController>();
                      licenciaCtrl.pickAndUploadLicencia(auth);
                    },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      licenciaCtrl.isUploading ? Icons.cloud_upload : Icons.upload_file,
                      color: const Color(0xFFFC6707),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        licenciaCtrl.selectedFileName ?? 'Seleccionar Archivos',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Barra de progreso y mensajes de estado
            if (licenciaCtrl.isUploading) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: licenciaCtrl.uploadProgress,
                  backgroundColor: const Color(0xFFFFDDBB),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFC6707)),
                  minHeight: 6,
                ),
              ),
            ],
            if (licenciaCtrl.successMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  licenciaCtrl.successMessage!,
                  style: GoogleFonts.outfit(color: Colors.green.shade700, fontSize: 12),
                ),
              ),
            if (licenciaCtrl.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  licenciaCtrl.errorMessage!,
                  style: GoogleFonts.outfit(color: Colors.red.shade700, fontSize: 12),
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

            // Botón Solicitar Registro
            SizedBox(
              width: double.infinity,
              child: MouseRegion(
                cursor: _acceptTerms ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: ElevatedButton(
                  onPressed: _acceptTerms
                      ? () {
                          _showSuccessDialog(context);
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
                    'Solicitar Registro',
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
      ),
          );
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFC6707),
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                '¡Solicitud Enviada!',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
            ],
          ),
          content: Text(
            'Se ha enviado tu solicitud de registro.\nTe llegará un correo con los datos de inicio de sesión una vez sea aprobada.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Volver a Iniciar Sesión',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}