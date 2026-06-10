// Componente del encabezado con logo y menú de navegación
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/responsive.dart';

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
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.padding(context, 24),
        vertical: Responsive.padding(context, 12),
      ),
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
                    width: Responsive.width(context, 60),
                    height: Responsive.height(context, 60),
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: Responsive.padding(context, 4)),
                Padding(
                  padding: EdgeInsets.only(top: Responsive.padding(context, 8)),
                  child: Image.asset(
                    'assets/images/Nombre.png',
                    height: Responsive.height(context, 25),
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          // Menú desktop
          if (!widget.isMobile) ...[
            Row(
              children: [
                _buildNavLink('Inicio'),
                SizedBox(width: Responsive.padding(context, 28)),
                _buildNavLink('Sobre Nosotros'),
                SizedBox(width: Responsive.padding(context, 28)),
                _buildNavLink('Destinos'),
                SizedBox(width: Responsive.padding(context, 28)),
                _buildNavLink('Contacto'),
              ],
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: widget.onLoginPressed,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFC6707), width: 1.5),
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.padding(context, 20),
                      vertical: Responsive.padding(context, 12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Responsive.padding(context, 10)),
                    ),
                  ),
                  child: Text(
                    'Iniciar Sesión',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFC6707),
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.fontSize(context, 14),
                    ),
                  ),
                ),
                SizedBox(width: Responsive.padding(context, 12)),
                ElevatedButton(
                  onPressed: widget.onRegisterPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC6707),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.padding(context, 20),
                      vertical: Responsive.padding(context, 12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Responsive.padding(context, 10)),
                    ),
                  ),
                  child: Text(
                    'Registrarse',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.fontSize(context, 14),
                    ),
                  ),
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
              fontSize: Responsive.fontSize(context, 16),
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? const Color(0xFFFC6707) : const Color(0xFF555555),
            ),
          ),
          if (isActive) ...[
            SizedBox(height: Responsive.padding(context, 4)),
            Container(
              width: Responsive.width(context, 20),
              height: Responsive.height(context, 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFC6707),
                borderRadius: BorderRadius.circular(Responsive.padding(context, 2)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}