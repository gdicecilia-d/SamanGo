// Sección Misión, Visión, Objetivo 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/commitment_model.dart';
import '../../utils/responsive.dart';

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
            fontSize: isMobile ? Responsive.fontSize(context, 22) : Responsive.fontSize(context, 28),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        SizedBox(height: Responsive.height(context, 18)),
        if (isMobile)
          Column(
            children: commitments.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: entry.key != commitments.length - 1 ? Responsive.padding(context, 20) : 0),
                child: Center(
                  child: _buildCard(context, entry.value, isMobile: true),
                ),
              );
            }).toList(),
          )
        else
          Row(
            children: commitments.map((c) => Expanded(child: _buildCard(context, c, isMobile: false))).toList(),
          ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, CommitmentModel commitment, {required bool isMobile}) {
    return Container(
      width: isMobile ? double.infinity : null,
      margin: isMobile ? EdgeInsets.zero : EdgeInsets.only(right: Responsive.padding(context, 16)),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.padding(context, 22),
        vertical: Responsive.padding(context, 24),
      ),
      decoration: BoxDecoration(
        color: commitment.backgroundColor,
        borderRadius: BorderRadius.circular(Responsive.padding(context, 16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(_getIconForTitle(commitment.title), color: commitment.titleColor, size: Responsive.width(context, 26)),
          SizedBox(height: Responsive.height(context, 10)),
          Text(
            commitment.title,
            style: GoogleFonts.outfit(
              fontSize: Responsive.fontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: commitment.titleColor,
            ),
          ),
          SizedBox(height: Responsive.height(context, 12)),
          Text(
            commitment.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: Responsive.fontSize(context, 14),
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
      case 'misión': return Icons.rocket_launch_rounded;
      case 'visión': return Icons.visibility_rounded;
      case 'objetivo': return Icons.track_changes_rounded;
      default: return Icons.star_rounded;
    }
  }
}