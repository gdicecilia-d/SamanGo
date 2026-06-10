// Pantalla de iniciar sesión
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'auth_base_view.dart';
import 'forgot_password_view.dart';
import 'select_role_view.dart';
import '../student/student_home_view.dart';
import '../operator/operator_home_view.dart';
import '../admin/admin_home_view.dart';
import '../../controllers/auth_controller.dart';
import 'complete_google_profile_view.dart';
import '../../utils/responsive.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authController = Provider.of<AuthController>(context, listen: false);
    final result = await authController.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result == true) {
      final usuario = authController.usuarioActual!;
      if (usuario.isEstudiante) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeView()),
        );
      } else if (usuario.isOperador) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OperatorHomeView()),
        );
      } else if (usuario.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeView()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeView()),
        );
      }
    } else if (result is Map && result['isNewUser'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompleteGoogleProfileView(
            userData: result as Map<String, dynamic>,
          ),
        ),
      );
    } else if (result is String) {
      _mostrarMensaje(result, isError: true);
    } else if (result == null) {
      _mostrarMensaje('Inicio de sesión cancelado', isError: true);
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor completa todos los campos';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authController = Provider.of<AuthController>(context, listen: false);
    final success = await authController.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      final usuario = authController.usuarioActual!;
      if (usuario.isEstudiante) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeView()),
        );
      } else if (usuario.isOperador) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OperatorHomeView()),
        );
      } else if (usuario.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeView()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeView()),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Correo o contraseña incorrectos';
      });
      _mostrarMensaje('Correo o contraseña incorrectos', isError: true);
    }
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
      formContent: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Iniciar Sesión',
            style: GoogleFonts.outfit(
              fontSize: Responsive.fontSize(context, 28),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          SizedBox(height: Responsive.height(context, 32)),

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
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'ejemplo@correo.unimet.edu.ve',
              hintStyle: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 14), color: const Color(0xFF999999)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.padding(context, 12)),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.padding(context, 12)),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.padding(context, 12)),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.padding(context, 12)),
                borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.padding(context, 12)),
                borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5),
              ),
              errorStyle: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: Responsive.fontSize(context, 12)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 16), vertical: Responsive.padding(context, 16)),
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
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Ingrese su contraseña',
              hintStyle: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 14), color: const Color(0xFF999999)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.padding(context, 12)),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.padding(context, 12)),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.padding(context, 12)),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.padding(context, 12)),
                borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.padding(context, 12)),
                borderSide: const BorderSide(color: Color(0xFFFC6707), width: 1.5),
              ),
              errorStyle: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: Responsive.fontSize(context, 12)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 16), vertical: Responsive.padding(context, 16)),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF999999)),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          SizedBox(height: Responsive.height(context, 8)),

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
                    fontSize: Responsive.fontSize(context, 13),
                    color: const Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: Responsive.height(context, 24)),

          if (_errorMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: Responsive.padding(context, 12)),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontSize: Responsive.fontSize(context, 13)),
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFC6707),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: Responsive.padding(context, 16)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12))),
              ),
              child: _isLoading
                  ? SizedBox(height: Responsive.height(context, 20), width: Responsive.width(context, 20), child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Iniciar Sesión', style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(height: Responsive.height(context, 12)),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _handleGoogleSignIn,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFDDBB3),
                side: BorderSide.none,
                padding: EdgeInsets.symmetric(vertical: Responsive.padding(context, 16)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 12))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png',
                    height: Responsive.height(context, 20),
                    width: Responsive.width(context, 20),
                    errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 20),
                  ),
                  SizedBox(width: Responsive.padding(context, 12)),
                  Text(
                    'Continuar con Google',
                    style: GoogleFonts.outfit(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}