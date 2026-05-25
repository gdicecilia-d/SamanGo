// seleccionar si es estudiante u operador 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_base_view.dart';
import 'register_student_view.dart';
import 'register_operator_view.dart';
import 'login_view.dart';

class SelectRoleView extends StatefulWidget {
  const SelectRoleView({super.key});

  @override
  State<SelectRoleView> createState() => _SelectRoleViewState();
}

class _SelectRoleViewState extends State<SelectRoleView> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return AuthBaseView(
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
            '¿Eres Estudiante u Operador?',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Selecciona tu perfil para personalizar tu experiencia',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Opción Estudiante
          _buildRoleCard(
            title: 'Soy Estudiante Unimet',
            description: 'Busco ofertas exclusivas para estudiantes.',
            imageAsset: 'assets/images/estudiante.png',
            isSelected: _selectedRole == 'student',
            onTap: () {
              setState(() {
                _selectedRole = 'student';
              });
            },
          ),
          const SizedBox(height: 20),

          // Opción Operador
          _buildRoleCard(
            title: 'Soy Operador Turístico',
            description: 'Quiero ofrecer mis servicios y experiencias a la comunidad.',
            imageAsset: 'assets/images/operador.png',
            isSelected: _selectedRole == 'operator',
            onTap: () {
              setState(() {
                _selectedRole = 'operator';
              });
            },
          ),
          const SizedBox(height: 32),

          // Botón Continuar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedRole != null
                  ? () {
                      if (_selectedRole == 'student') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterStudentView()),
                        );
                      } else if (_selectedRole == 'operator') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterOperatorView()),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedRole != null
                    ? const Color(0xFFFC6707)  
                    : const Color(0xFFFDDBB3), 
                foregroundColor: Colors.white, 
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: const Color(0xFFFDDBB3), 
              ),
              child: Text(
                'Continuar',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required String imageAsset,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFC6707) : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Imagen circular
            ClipOval(
              child: Image.asset(
                imageAsset,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}