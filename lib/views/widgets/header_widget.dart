// Componente del encabezado con logo y menú de navegación
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderWidget extends StatefulWidget {
  final bool isMobile;
  final VoidCallback onLoginPressed;
  final VoidCallback onRegisterPressed;
  final Function(String) onMenuSelected;
  final String activeMenu;

  const HeaderWidget({
    super.key,
    required this.isMobile,
    required this.onLoginPressed,
    required this.onRegisterPressed,
    required this.onMenuSelected,
    required this.activeMenu,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          InkWell(
            onTap: () => widget.onMenuSelected('Inicio'),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.5,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset(
                  'assets/images/Nombre.png',
                  height: 25,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          // Menú desktop
          if (!widget.isMobile) ...[
            Row(
              children: [
                _buildNavLink('Inicio'),
                const SizedBox(width: 28),
                _buildNavLink('Sobre Nosotros'),
                const SizedBox(width: 28),
                _buildNavLink('Destinos'),
                const SizedBox(width: 28),
                _buildNavLink('Contacto'),
              ],
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: widget.onLoginPressed,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFC6707), width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Iniciar Sesión',
                    style: GoogleFonts.outfit(color: const Color(0xFFFC6707), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: widget.onRegisterPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC6707),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Registrarse', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
          // Menú móvil
          if (widget.isMobile)
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
    final isActive = widget.activeMenu == title;
    return InkWell(
      onTap: () => widget.onMenuSelected(title),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? const Color(0xFFFC6707) : const Color(0xFF555555),
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Container(
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFFC6707),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}