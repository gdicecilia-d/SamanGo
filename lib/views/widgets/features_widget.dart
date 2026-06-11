// Lista de beneficios 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/feature_model.dart';
import '../../utils/responsive.dart';

class FeaturesWidget extends StatelessWidget {
  final List<FeatureModel> features;
  final bool isMobile;

  const FeaturesWidget({
    super.key,
    required this.features,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    // Cell 
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFFC6707), shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      );
    }

    // Computadora 
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? Responsive.padding(context, 12) : Responsive.padding(context, 24),
        horizontal: isMobile ? Responsive.padding(context, 8) : Responsive.padding(context, 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) SizedBox(height: Responsive.height(context, 38)),
          ...features.map((feature) => _buildFeatureItem(context, feature)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, FeatureModel feature) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.padding(context, 18)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.padding(context, 4)),
            decoration: const BoxDecoration(color: Color(0xFFFC6707), shape: BoxShape.circle),
            child: Icon(Icons.check, color: Colors.white, size: Responsive.width(context, 14)),
          ),
          SizedBox(width: Responsive.padding(context, 14)),
          Expanded(
            child: Text(
              feature.title,
              style: GoogleFonts.outfit(
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C2C2C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
