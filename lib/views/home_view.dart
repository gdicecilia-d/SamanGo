import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/home_controller.dart';
import 'widgets/header_widget.dart';
import 'widgets/hero_widget.dart';
import 'widgets/commitment_widget.dart';
import 'widgets/features_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Instanciamos el controlador
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos LayoutBuilder para determinar de forma reactiva el tipo de dispositivo
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 850;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5), // Color de fondo #F5F5F5
          // Encabezado fijado en la parte superior
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(66),
            child: HeaderWidget(
              selectedMenu: _controller.selectedMenu,
              onMenuSelected: (menu) {
                _controller.selectMenuItem(menu, () {
                  setState(() {});
                });
              },
              onLoginPressed: () => _controller.handleLogin(context),
              onRegisterPressed: () => _controller.handleRegister(context),
              isMobile: isMobile,
            ),
          ),
          // Drawer para móviles
          endDrawer: isMobile ? _buildMobileDrawer(context) : null,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sección Hero
                  HeroWidget(
                    isMobile: isMobile,
                    onStartAdventurePressed: () => _controller.handleStartAdventure(context),
                  ),
                  SizedBox(height: isMobile ? 32 : 48),
                  
                  // Sección inferior (Compromisos + Beneficios) responsiva
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CommitmentWidget(
                          commitments: _controller.commitments,
                          isMobile: true,
                        ),
                        const SizedBox(height: 16),
                        FeaturesWidget(
                          features: _controller.features,
                          isMobile: true,
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lado Izquierdo (Misión, Visión, Objetivo) - 70%
                        Expanded(
                          flex: 7,
                          child: CommitmentWidget(
                            commitments: _controller.commitments,
                            isMobile: false,
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Lado Derecho (Value Proposition Checklist) - 30%
                        Expanded(
                          flex: 3,
                          child: FeaturesWidget(
                            features: _controller.features,
                            isMobile: false,
                          ),
                        ),
                      ],
                    ),
                  
                  // Footer decorativo sutil
                  const SizedBox(height: 48),
                  const Divider(color: Color(0xFFE0E0E0), height: 1),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '© 2026 SamanGo. Todos los derechos reservados. Comunidad UNIMET.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF888888),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Constructor del menú lateral (Drawer) para móviles
  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Cabecera del drawer con el logo
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/images/Nombre.png',
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Opciones de menú
            _buildDrawerItem('Inicio', context),
            _buildDrawerItem('Sobre Nosotros', context),
            _buildDrawerItem('Destinos', context),
            _buildDrawerItem('Contacto', context),
            
            const Spacer(),
            
            // Botones de acción en la parte inferior del Drawer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _controller.handleLogin(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFC6707), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Iniciar Sesión',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFC6707),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _controller.handleRegister(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC6707),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Registrarse',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, BuildContext context) {
    final isSelected = _controller.selectedMenu == title;
    return ListTile(
      leading: Icon(
        _getMenuIcon(title),
        color: isSelected ? const Color(0xFFFC6707) : const Color(0xFF777777),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? const Color(0xFFFC6707) : const Color(0xFF333333),
          fontSize: 16,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFC6707), size: 14)
          : null,
      onTap: () {
        Navigator.pop(context);
        _controller.selectMenuItem(title, () {
          setState(() {});
        });
      },
    );
  }

  IconData _getMenuIcon(String title) {
    switch (title) {
      case 'Inicio':
        return Icons.home_rounded;
      case 'Sobre Nosotros':
        return Icons.info_rounded;
      case 'Destinos':
        return Icons.explore_rounded;
      case 'Contacto':
        return Icons.mail_rounded;
      default:
        return Icons.link_rounded;
    }
  }
}
