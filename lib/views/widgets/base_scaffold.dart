import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'header_widget.dart';
import '../../utils/responsive.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final bool isMobile;
  final VoidCallback onLoginPressed;
  final VoidCallback onRegisterPressed;
  final Function(String) onMenuSelected;
  final String activeMenu;

  const BaseScaffold({
    super.key,
    required this.body,
    required this.isMobile,
    required this.onLoginPressed,
    required this.onRegisterPressed,
    required this.onMenuSelected,
    required this.activeMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: HeaderWidget(
            isMobile: isMobile,
            onLoginPressed: onLoginPressed,
            onRegisterPressed: onRegisterPressed,
            onMenuSelected: onMenuSelected,
            activeMenu: activeMenu,
          ),
        ),
      ),
      endDrawer: isMobile ? _buildMobileDrawer(context) : null,
      body: SafeArea(
        child: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (overscroll) {
            overscroll.disallowIndicator();
            return true;
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? Responsive.padding(context, 16) : Responsive.padding(context, 40)),
            child: Column(
              children: [
                body,
                SizedBox(height: Responsive.padding(context, 48)),
                // Footer con diseño condicional
                isMobile ? _buildMobileFooter() : _buildDesktopFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Cell 
  Widget _buildMobileFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFC6707),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: const Center(
        child: Text(
          '© 2026 SamanGo. Todos los derechos reservados. Comunidad UNIMET.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Computadora 
  Widget _buildDesktopFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: Responsive.padding(context, 20)),
      decoration: const BoxDecoration(
        color: Color(0xFFFC6707),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Center(
        child: Text(
          '© 2026 SamanGo. Todos los derechos reservados. Comunidad UNIMET.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: Responsive.fontSize(context, 12),
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.75,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo en el drawer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Transform.scale(
                    scale: 1.5,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 45,
                      height: 45,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Image.asset(
                      'assets/images/Nombre.png',
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
            // Menú items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem('Inicio', context),
                  _buildDrawerItem('Sobre Nosotros', context),
                  _buildDrawerItem('Destinos', context),
                  _buildDrawerItem('Contacto', context),
                  const SizedBox(height: 24),
                  // Botones de acción
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: onLoginPressed,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFC6707), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFC6707),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: onRegisterPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFC6707),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Registrarse',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, BuildContext context) {
    final isActive = activeMenu == title;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? const Color(0xFFFC6707) : const Color(0xFF333333),
        ),
      ),
      trailing: isActive
          ? const Icon(Icons.arrow_forward_ios, color: Color(0xFFFC6707), size: 18)
          : null,
      onTap: () {
        Navigator.pop(context);
        onMenuSelected(title);
      },
    );
  }
}