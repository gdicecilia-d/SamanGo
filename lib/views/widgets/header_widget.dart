import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String selectedMenu;
  final Function(String) onMenuSelected;
  final VoidCallback onLoginPressed;
  final VoidCallback onRegisterPressed;
  final bool isMobile;

  const HeaderWidget({
    super.key,
    required this.selectedMenu,
    required this.onMenuSelected,
    required this.onLoginPressed,
    required this.onRegisterPressed,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo SamanGo
          Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 52,
                height: 52,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/Nombre.png',
                height: 28,
                fit: BoxFit.contain,
              ),
            ],
          ),

          // Enlaces de navegación (Ocultos en móvil, se muestra menú en Drawer)
          if (!isMobile)
            Row(
              children: [
                _buildNavLink('Inicio'),
                const SizedBox(width: 24),
                _buildNavLink('Sobre Nosotros'),
                const SizedBox(width: 24),
                _buildNavLink('Destinos'),
                const SizedBox(width: 24),
                _buildNavLink('Contacto'),
              ],
            ),

          // Botones de acción
          if (!isMobile)
            Row(
              children: [
                // Iniciar Sesión (Bordeado)
                OutlinedButton(
                  onPressed: onLoginPressed,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFC6707), width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Iniciar Sesión',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFC6707),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Registrarse (Relleno)
                ElevatedButton(
                  onPressed: onRegisterPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC6707),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Registrarse',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            )
          else
            // Icono del Drawer para móvil
            IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFFFC6707), size: 28),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String title) {
    final isSelected = selectedMenu == title;
    return InkWell(
      onTap: () => onMenuSelected(title),
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFFFC6707) : const Color(0xFF555555),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(height: 4),
            Container(
              width: 16,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFFFC6707),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(66);
}

// Pintor personalizado para recrear el árbol de la UNIMET estilo tecnológico / neuronal del logo de SamanGo
class SamanTreePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFC6707)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFFFC6707)
      ..style = PaintingStyle.fill;

    // Dibujar base del tronco
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.95)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.7,
        size.width * 0.5,
        size.height * 0.55,
      );
    canvas.drawPath(path, paint);

    // Dibujar raíces estilizadas
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.95)
        ..quadraticBezierTo(size.width * 0.35, size.height * 0.98, size.width * 0.2, size.height * 0.95),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.95)
        ..quadraticBezierTo(size.width * 0.65, size.height * 0.98, size.width * 0.8, size.height * 0.95),
      paint,
    );

    // Rama central principal
    _drawBranch(canvas, paint, fillPaint,
        start: Offset(size.width * 0.5, size.height * 0.55),
        control: Offset(size.width * 0.5, size.height * 0.35),
        end: Offset(size.width * 0.5, size.height * 0.15));

    // Ramas izquierdas
    _drawBranch(canvas, paint, fillPaint,
        start: Offset(size.width * 0.5, size.height * 0.55),
        control: Offset(size.width * 0.35, size.height * 0.48),
        end: Offset(size.width * 0.22, size.height * 0.35));

    _drawBranch(canvas, paint, fillPaint,
        start: Offset(size.width * 0.5, size.height * 0.5),
        control: Offset(size.width * 0.25, size.height * 0.35),
        end: Offset(size.width * 0.12, size.height * 0.22));

    _drawBranch(canvas, paint, fillPaint,
        start: Offset(size.width * 0.5, size.height * 0.45),
        control: Offset(size.width * 0.35, size.height * 0.25),
        end: Offset(size.width * 0.28, size.height * 0.12));

    // Ramas derechas
    _drawBranch(canvas, paint, fillPaint,
        start: Offset(size.width * 0.5, size.height * 0.55),
        control: Offset(size.width * 0.65, size.height * 0.48),
        end: Offset(size.width * 0.78, size.height * 0.35));

    _drawBranch(canvas, paint, fillPaint,
        start: Offset(size.width * 0.5, size.height * 0.5),
        control: Offset(size.width * 0.75, size.height * 0.35),
        end: Offset(size.width * 0.88, size.height * 0.22));

    _drawBranch(canvas, paint, fillPaint,
        start: Offset(size.width * 0.5, size.height * 0.45),
        control: Offset(size.width * 0.65, size.height * 0.25),
        end: Offset(size.width * 0.72, size.height * 0.12));

    // Dibujar conexiones y nodos intermedios de red
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.55), 3, fillPaint);
  }

  void _drawBranch(Canvas canvas, Paint paint, Paint fillPaint,
      {required Offset start, required Offset control, required Offset end}) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);
    // Dibujar nodo terminal (círculo)
    canvas.drawCircle(end, 3.5, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
