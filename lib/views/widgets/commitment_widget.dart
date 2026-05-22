import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/commitment_model.dart';

class CommitmentWidget extends StatelessWidget {
  final List<CommitmentModel> commitments;
  final bool isMobile;

  const CommitmentWidget({
    super.key,
    required this.commitments,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Text(
          'Nuestro Compromiso',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 18),
        // Layout Responsivo para las Tarjetas
        if (isMobile)
          Column(
            children: commitments.map((c) => _buildCard(c, isMobile: true)).toList(),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: commitments
                .map((c) => Expanded(child: _buildCard(c, isMobile: false)))
                .toList(),
          ),
      ],
    );
  }

  // Constructor individual para cada una de las tarjetas Misión, Visión y Objetivo
  Widget _buildCard(CommitmentModel commitment, {required bool isMobile}) {
    return Container(
      margin: EdgeInsets.only(
        bottom: isMobile ? 12 : 0,
        right: !isMobile && commitment != commitments.last ? 16 : 0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: commitment.backgroundColor, // #FDDBB3
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono decorativo sutil según el tipo
          Icon(
            _getIconForTitle(commitment.title),
            color: commitment.titleColor,
            size: 26,
          ),
          const SizedBox(height: 10),
          // Título de la tarjeta (Misión/Visión/Objetivo)
          Text(
            commitment.title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: commitment.titleColor, // #FC6707
            ),
          ),
          const SizedBox(height: 12),
          // Contenido de la tarjeta
          Text(
            commitment.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4A4A4A),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'misión':
        return Icons.rocket_launch_rounded;
      case 'visión':
        return Icons.visibility_rounded;
      case 'objetivo':
        return Icons.track_changes_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}
