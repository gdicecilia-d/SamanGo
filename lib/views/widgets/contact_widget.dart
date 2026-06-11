// Sección de contacto con redes sociales y datos de contacto
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/responsive.dart';

class ContactWidget extends StatelessWidget {
  final bool isMobile;

  const ContactWidget({
    super.key,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    // Cell 
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contáctanos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFC6707),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMobileContactItem(Icons.camera_alt, '@SamanGo_Unimet'),
                const SizedBox(height: 16),
                _buildMobileContactItem(Icons.phone, '+58 412-1234567'),
                const SizedBox(height: 16),
                _buildMobileContactItem(Icons.email, 'soporte@samango.unimet.edu.ve'),
              ],
            ),
          ),
        ],
      );
    }

    // Computadora 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contáctanos',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? Responsive.fontSize(context, 22) : Responsive.fontSize(context, 28),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        SizedBox(height: Responsive.height(context, 20)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(Responsive.padding(context, 32)),
          decoration: BoxDecoration(
            color: const Color(0xFFFC6707),
            borderRadius: BorderRadius.circular(Responsive.padding(context, 16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContactItem(context, Icons.camera_alt, '@SamanGo_Unimet'),
              SizedBox(height: Responsive.height(context, 20)),
              _buildContactItem(context, Icons.phone, '+58 412-1234567'),
              SizedBox(height: Responsive.height(context, 20)),
              _buildContactItem(context, Icons.email, 'soporte@samango.unimet.edu.ve'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: Responsive.width(context, 24)),
        SizedBox(width: Responsive.padding(context, 12)),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: Responsive.fontSize(context, 16),
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}