import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/feature_model.dart';

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
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 12 : 24,
        horizontal: isMobile ? 8 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En escritorio, agregamos un margen superior para alinearlo visualmente con las tarjetas
          if (!isMobile) const SizedBox(height: 38),
          ...features.map((feature) => _buildFeatureItem(feature)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(FeatureModel feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono de check circular naranja con check blanco
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFFC6707), // #FC6707
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 14),
          // Texto del beneficio
          Expanded(
            child: Text(
              feature.title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600, // Semibold
                color: const Color(0xFF2C2C2C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
