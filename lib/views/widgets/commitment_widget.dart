// Sección Misión, Visión, Objetivo 
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
        Text(
          'Nuestro Compromiso',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 18),
        if (isMobile)
          Column(
            children: commitments.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: entry.key != commitments.length - 1 ? 20 : 0),
                child: _buildCard(entry.value),
              );
            }).toList(),
          )
        else
          Row(
            children: commitments.map((c) => Expanded(child: _buildCard(c))).toList(),
          ),
      ],
    );
  }

  Widget _buildCard(CommitmentModel commitment) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: commitment.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(_getIconForTitle(commitment.title), color: commitment.titleColor, size: 26),
          const SizedBox(height: 10),
          Text(
            commitment.title,
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: commitment.titleColor),
          ),
          const SizedBox(height: 12),
          Text(
            commitment.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF4A4A4A), height: 1.45),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'misión': return Icons.rocket_launch_rounded;
      case 'visión': return Icons.visibility_rounded;
      case 'objetivo': return Icons.track_changes_rounded;
      default: return Icons.star_rounded;
    }
  }
}