// imágenes destacadas de la pag
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    if (isMobile) {
      // MÓVIL: Columna
      return Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildLeftHero(showFullContent: true),
          ),
          // Bloque gris de separación (8px sólido)
          Container(height: 8, color: const Color(0xFFE0E0E0)),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildRightHeroMobile(),
          ),
        ],
      );
    }
    // Escritorio 
    return Column(
      children: [
        SizedBox(
          height: 420,
          child: Row(
            children: [
              Expanded(flex: 6, child: _buildLeftHero(showFullContent: true)),
              // Bloque gris de separación
              Container(width: 8, color: const Color(0xFFE0E0E0)),
              Expanded(flex: 4, child: _buildRightHeroDesktop()),
            ],
          ),
        ),
        // Línea gris horizontal debajo 
        Container(height: 2, color: const Color(0xFFE0E0E0)),
      ],
    );
  }

  Widget _buildLeftHero({required bool showFullContent}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/el_avila.png'),
          fit: BoxFit.cover,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                'Tu próximo destino está a un clic del campus',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 18 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                  shadows: [
                    const Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 4),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                'La primera plataforma de viajes exclusiva para la comunidad UNIMET. Explora Venezuela con seguridad y presupuesto estudiantil.',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 11 : 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.3,
                ),
                maxLines: isMobile ? 3 : 2,
                overflow: TextOverflow.visible,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: isMobile ? double.infinity : null,
              child: ElevatedButton(
                onPressed: onStartAdventurePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC6707),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  '¡Empieza tu aventura!',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Versión para cell 
  Widget _buildRightHeroMobile() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/unimet.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Versión para escritorio 
  Widget _buildRightHeroDesktop() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/unimet_campus.png'),
          fit: BoxFit.cover,
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