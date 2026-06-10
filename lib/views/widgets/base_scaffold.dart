// Plantilla base para todas las pantallas usando Template Method
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
                Container(
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
                padding: EdgeInsets.all(Responsive.padding(context, 24)),
                child: Row(
                  children: [
                    Transform.scale(
                      scale: 1.5,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: Responsive.width(context, 45),
                        height: Responsive.height(context, 45),
                      ),
                    ),
                    SizedBox(width: Responsive.padding(context, 8)),
                    Padding(
                      padding: EdgeInsets.only(top: Responsive.padding(context, 8)),
                      child: Image.asset(
                        'assets/images/Nombre.png',
                        height: Responsive.height(context, 22),
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
              SizedBox(height: Responsive.padding(context, 24)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 24)),
                child: Column(
                  children: [
                    OutlinedButton(
                      onPressed: onLoginPressed,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFC6707), width: 1.5),
                        minimumSize: Size(double.infinity, Responsive.height(context, 45)),
                      ),
                      child: Text('Iniciar Sesión', style: GoogleFonts.outfit(color: const Color(0xFFFC6707))),
                    ),
                    SizedBox(height: Responsive.padding(context, 12)),
                    ElevatedButton(
                      onPressed: onRegisterPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC6707),
                        minimumSize: Size(double.infinity, Responsive.height(context, 45)),
                      ),
                      child: Text('Registrarse', style: GoogleFonts.outfit(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Responsive.padding(context, 24)),
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
          fontSize: Responsive.fontSize(context, 16),
        ),
      ),
      trailing: isActive
          ? Icon(Icons.arrow_forward_ios, color: const Color(0xFFFC6707), size: Responsive.width(context, 14))
          : null,
      onTap: () {
        Navigator.pop(context);
        onMenuSelected(title);
      },
    );
  }
}