// Menú desplegable del perfil 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../edit_profile_view.dart';

class ProfileMenu extends StatelessWidget {
  final VoidCallback onClose;

  const ProfileMenu({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            // Avatar grande
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFC6707), width: 2),
              ),
              child: const CircleAvatar(
                backgroundColor: Color(0xFFFDDBB3),
                child: Icon(Icons.person, color: Color(0xFFFC6707), size: 30),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Estudiante',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            const Divider(height: 24, thickness: 1, color: Color(0xFFE0E0E0)),
            // Opción Editar Perfil
            _buildMenuItem(
              icon: Icons.settings_outlined,
              label: 'Editar Perfil',
              onTap: () {
                onClose();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileView()),
                );
              },
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            // Opción Cerrar Sesión
            _buildMenuItem(
              icon: Icons.logout_outlined,
              label: 'Cerrar Sesión',
              onTap: () {
                onClose();
                // Cerrar sesión
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFC6707), size: 22),
      title: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF333333),
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}