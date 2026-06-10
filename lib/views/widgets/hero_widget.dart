// imágenes destacadas de la pag
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/responsive.dart';

class HeroWidget extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onStartAdventurePressed;

  const HeroWidget({
    super.key,
    required this.isMobile,
    required this.onStartAdventurePressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Altura dinámica
    final double heroHeight = (screenHeight * 0.45).clamp(350.0, 500.0);
    
    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            height: heroHeight,
            child: _buildLeftHero(context, showFullContent: true),
          ),
          Container(height: Responsive.height(context, 8), color: const Color(0xFFE0E0E0)),
          SizedBox(
            height: heroHeight * 0.8,
            child: _buildRightHeroMobile(context),
          ),
        ],
      );
    }
    return Column(
      children: [
        SizedBox(
          height: heroHeight,
          child: Row(
            children: [
              Expanded(flex: 6, child: _buildLeftHero(context, showFullContent: true)),
              Container(width: Responsive.width(context, 8), color: const Color(0xFFE0E0E0)),
              Expanded(flex: 4, child: _buildRightHeroDesktop(context)),
            ],
          ),
        ),
        Container(height: Responsive.height(context, 2), color: const Color(0xFFE0E0E0)),
      ],
    );
  }

  Widget _buildLeftHero(BuildContext context, {required bool showFullContent}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1200;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/el_avila.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.75),
              Colors.black.withOpacity(0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        padding: EdgeInsets.all(Responsive.padding(context, 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                'Tu próximo destino está a un clic del campus',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? Responsive.fontSize(context, 18) : (isSmallScreen ? Responsive.fontSize(context, 24) : Responsive.fontSize(context, 32)),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                  shadows: const [
                    Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 4),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
            ),
            SizedBox(height: Responsive.height(context, 8)),
            Flexible(
              child: Text(
                'La primera plataforma de viajes exclusiva para la comunidad UNIMET. Explora Venezuela con seguridad y presupuesto estudiantil.',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? Responsive.fontSize(context, 11) : (isSmallScreen ? Responsive.fontSize(context, 12) : Responsive.fontSize(context, 14)),
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.3,
                ),
                maxLines: isMobile ? 3 : 2,
                overflow: TextOverflow.visible,
              ),
            ),
            SizedBox(height: Responsive.height(context, 12)),
            SizedBox(
              width: isMobile ? double.infinity : null,
              child: ElevatedButton(
                onPressed: onStartAdventurePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC6707),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.padding(context, 16),
                    vertical: Responsive.padding(context, 10),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.padding(context, 10))),
                ),
                child: Text(
                  '¡Empieza tu aventura!',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: Responsive.fontSize(context, 13),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightHeroMobile(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/unimet_campus1.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }

  Widget _buildRightHeroDesktop(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1200;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/unimet_campus.png'),
          fit: BoxFit.cover,
          alignment: isSmallScreen ? Alignment.centerLeft : Alignment.center,
        ),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}