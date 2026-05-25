// Plantilla base para todas las pantallas usando Template Method
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'header_widget.dart';

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
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40),
            child: Column(
              children: [
                body,
                const SizedBox(height: 48),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
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
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.8, 
      child: SafeArea(
        child: SingleChildScrollView( 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const Divider(),
              _buildDrawerItem('Inicio', context),
              _buildDrawerItem('Sobre Nosotros', context),
              _buildDrawerItem('Destinos', context),
              _buildDrawerItem('Contacto', context),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    OutlinedButton(
                      onPressed: onLoginPressed,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFC6707), width: 1.5),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: Text('Iniciar Sesión', style: GoogleFonts.outfit(color: const Color(0xFFFC6707))),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: onRegisterPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC6707),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: Text('Registrarse', style: GoogleFonts.outfit(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, BuildContext context) {
    final isActive = activeMenu == title;
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? const Color(0xFFFC6707) : const Color(0xFF333333),
          fontSize: 16,
        ),
      ),
      trailing: isActive
          ? const Icon(Icons.arrow_forward_ios, color: Color(0xFFFC6707), size: 14)
          : null,
      onTap: () {
        Navigator.pop(context);
        onMenuSelected(title);
      },
    );
  }
}