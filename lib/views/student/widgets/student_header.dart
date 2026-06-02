// Header del estudiante con logo, menú y avatar
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../edit_profile_view.dart';

class StudentHeader extends StatefulWidget {
  const StudentHeader({super.key});

  @override
  State<StudentHeader> createState() => _StudentHeaderState();
}

class _StudentHeaderState extends State<StudentHeader> {
  bool _showProfilePanel = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Fila principal del header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo
                InkWell(
                  onTap: () {},
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 1.5,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Image.asset(
                          'assets/images/Nombre.png',
                          height: 25,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                // Menú de navegación
                const SizedBox(width: 200),
                Row(
                  children: [
                    _buildNavLink('Inicio', true),
                    const SizedBox(width: 40), 
                    _buildNavLink('Mis Viajes', false),
                    const SizedBox(width: 40), 
                    _buildNavLink('Favoritos', false),
                  ],
                ),
                // Avatar del usuario
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showProfilePanel = !_showProfilePanel;
                    });
                  },
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFC6707), width: 2),
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFFFDDBB3),
                      child: Icon(Icons.person, color: Color(0xFFFC6707), size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Panel desplegable del perfil
          if (_showProfilePanel)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showProfilePanel = false;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileView()),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.settings_outlined, color: Color(0xFFFC6707), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Editar Perfil',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showProfilePanel = false;
                        });
                        // TODO: Cerrar sesión
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.logout_outlined, color: Color(0xFFFC6707), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Cerrar Sesión',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String title, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFFFC6707) : const Color(0xFF555555),
          ),
        ),
        if (isActive) ...[
          const SizedBox(height: 4),
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFFC6707),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }
}