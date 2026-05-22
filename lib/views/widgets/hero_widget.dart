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
      return Column(
        children: [
          _buildLeftHero(context, height: 320),
          const SizedBox(height: 16),
          _buildRightHero(context, height: 260),
        ],
      );
    }

    return SizedBox(
      height: 420,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bloque Izquierdo (El Ávila) - 60% de ancho aprox
          Expanded(
            flex: 6,
            child: _buildLeftHero(context),
          ),
          const SizedBox(width: 16),
          // Bloque Derecho (Campus UNIMET) - 40% de ancho aprox
          Expanded(
            flex: 4,
            child: _buildRightHero(context),
          ),
        ],
      ),
    );
  }

  // Constructor del bloque izquierdo con fondo de El Ávila
  Widget _buildLeftHero(BuildContext context, {double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/images/el_avila.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Tu próximo destino está\na un clic del campus',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 26 : 38,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.15,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'La primera plataforma de viajes exclusiva para la comunidad UNIMET.\nExplora Venezuela con seguridad y presupuesto estudiantil.',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 13 : 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
                height: 1.35,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onStartAdventurePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC6707),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                '¡Empieza tu aventura!',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Constructor del bloque derecho con la foto del campus UNIMET
  Widget _buildRightHero(BuildContext context, {double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/images/unimet_campus.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.4),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
