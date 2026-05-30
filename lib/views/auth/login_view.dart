// Pag de iniciar sesión
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import 'auth_base_view.dart';
import 'forgot_password_view.dart';
import 'select_role_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // La validación de los campos (validator:) es de Jesús.
    // Este método solo ejecuta el login si el formulario es válido.
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final error = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (error == null) {
      // Login exitoso → navegar al Home (el header ya reflejará el nombre)
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    // Si hay error, AuthController.errorMessage lo tiene → Consumer lo muestra
  }

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
      formContent: Form(
        key: _formKey,
        child: Column(
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

          // Campo Correo — alineado al atributo +correo del diagrama de clases
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
            keyboardType: TextInputType.emailAddress,
            // validator: — IMPLEMENTAR POR JESÚS
            // Validar: no vacío + termina en @correo.unimet.edu.ve
            decoration: InputDecoration(
              hintText: 'ejemplo@correo.unimet.edu.ve',
              hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF333333)),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            // validator: — IMPLEMENTAR POR JESÚS
            // Validar: no vacío + mínimo 6 caracteres
            decoration: InputDecoration(
              hintText: 'Ingrese su contraseña',
              hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF999999),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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

          // Mensaje de error del AuthController (patrón Observer)
          Consumer<AuthController>(
            builder: (context, auth, _) {
              if (auth.errorMessage != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    auth.errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Botón Iniciar Sesión — conectado a Firebase Auth real
          Consumer<AuthController>(
            builder: (context, auth, _) {
              return SizedBox(
                width: double.infinity,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC6707),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Iniciar Sesión',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              );
            },
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
      ),
    );
  }
}