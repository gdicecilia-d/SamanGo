// Gráfico de destinos más buscados (estructura vacía)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrendingChart extends StatelessWidget {
  const TrendingChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Destinos más buscados',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'No hay datos disponibles',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF999999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}