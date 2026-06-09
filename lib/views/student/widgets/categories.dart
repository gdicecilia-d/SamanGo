// Sección Explorar por Categorías - Responsive
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../search_results_view.dart';
import '../search_results_view.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: Text(
            'Explorar por Categorías',
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: isMobile
              ? Column(
                  children: [
                    _buildCategoryCard('Playas / Cayos', 'assets/images/playas_cayos.png', isMobile, context),
                    const SizedBox(height: 16),
                    _buildCategoryCard('Montañas / Trekking', 'assets/images/montañas_trekking.png', isMobile, context),
                    const SizedBox(height: 16),
                    _buildCategoryCard('Aventura / Ríos', 'assets/images/aventuras_rios.png', isMobile, context),
                    const SizedBox(height: 16),
                    _buildCategoryCard('Cultura / Ciudades', 'assets/images/cultura_ciudades.png', isMobile, context),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildCategoryCard('Playas / Cayos', 'assets/images/playas_cayos.png', isMobile, context)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCategoryCard('Montañas / Trekking', 'assets/images/montañas_trekking.png', isMobile, context)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCategoryCard('Aventura / Ríos', 'assets/images/aventuras_rios.png', isMobile, context)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCategoryCard('Cultura / Ciudades', 'assets/images/cultura_ciudades.png', isMobile, context)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String title, String imagePath, bool isMobile, BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SearchResultsView(
                destino: '',
                transporte: null,
                presupuesto: null,
                alojamiento: null,
                categoria: title,
              ),
            ),
          );
        },
        child: Container(
          height: isMobile ? 110 : 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}