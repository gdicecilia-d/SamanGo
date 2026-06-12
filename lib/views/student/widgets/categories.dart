// Sección Explorar por Categorías 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../search_results_view.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final isLargeScreen = screenWidth > 1400;

    // Altura de las tarjetas 
    final double cardHeight = isMobile ? 140 : (isLargeScreen ? 220 : 160);
    
    // Tamaño del título
    final double titleFontSize = isMobile ? 22 : (isLargeScreen ? 32 : 26);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: Text(
            'Explorar por Categorías',
            style: GoogleFonts.outfit(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: isMobile
              ? Column(
                  children: [
                    _buildCategoryCard('Playas / Cayos', 'assets/images/playas_cayos.png', cardHeight, context),
                    const SizedBox(height: 16),
                    _buildCategoryCard('Montañas / Trekking', 'assets/images/montañas_trekking.png', cardHeight, context),
                    const SizedBox(height: 16),
                    _buildCategoryCard('Aventura / Ríos', 'assets/images/aventuras_rios.png', cardHeight, context),
                    const SizedBox(height: 16),
                    _buildCategoryCard('Cultura / Ciudades', 'assets/images/cultura_ciudades.png', cardHeight, context),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildCategoryCard('Playas / Cayos', 'assets/images/playas_cayos.png', cardHeight, context)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildCategoryCard('Montañas / Trekking', 'assets/images/montañas_trekking.png', cardHeight, context)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildCategoryCard('Aventura / Ríos', 'assets/images/aventuras_rios.png', cardHeight, context)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildCategoryCard('Cultura / Ciudades', 'assets/images/cultura_ciudades.png', cardHeight, context)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String title, String imagePath, double cardHeight, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1400;
    // Fuente más grande
    final double fontSize = isLargeScreen ? 22 : 18;
    
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
          height: cardHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}