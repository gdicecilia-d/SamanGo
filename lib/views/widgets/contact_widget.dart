// Sección de contacto con redes sociales y datos de contacto
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactWidget extends StatelessWidget {
  final bool isMobile;

  const ContactWidget({
    super.key,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contáctanos',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFFFC6707),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Alineado a la izquierda
            children: [
              _buildContactItem(Icons.camera_alt, '@SamanGo_Unimet'),
              const SizedBox(height: 20),
              _buildContactItem(Icons.phone, '+58 412-1234567'),
              const SizedBox(height: 20),
              _buildContactItem(Icons.email, 'soporte@samango.unimet.edu.ve'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min, 
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}