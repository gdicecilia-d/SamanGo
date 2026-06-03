// Pantalla principal del estudiante - Responsive
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/student_header.dart';
import 'widgets/search_bar.dart';
import 'widgets/recommendations.dart';
import 'widgets/categories.dart';
import 'widgets/offers.dart';
import 'widgets/notifications_panel.dart';
import 'widgets/trending_chart.dart';
import '../auth/login_view.dart';
import 'edit_profile_view.dart';

class StudentHomeView extends StatelessWidget {
  const StudentHomeView({super.key});

  void _handleMenuSelected(String menu, BuildContext context) {
    if (menu == 'Mis Viajes') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mis Viajes - Próximamente'), backgroundColor: Color(0xFFFC6707)),
      );
    } else if (menu == 'Favoritos') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favoritos - Próximamente'), backgroundColor: Color(0xFFFC6707)),
      );
    }
  }

  void _handleEditProfile(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileView()));
  }

  void _handleLogout(BuildContext context) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header (igual para todos, pero en móvil se adapta)
          UserHeader(
            activeMenu: 'Inicio',
            onMenuSelected: (menu) => _handleMenuSelected(menu, context),
            onEditProfile: () => _handleEditProfile(context),
            onLogout: () => _handleLogout(context),
            menuItems: const ['Inicio', 'Mis Viajes', 'Favoritos'],
          ),
          Expanded(
            child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
          ),
        ],
      ),
    );
  }

  // Layout para móvil (vertical, todo en columna)
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                children: const [
                  TextSpan(text: '¡Hola '),
                  TextSpan(text: 'Estudiante', style: TextStyle(color: Color(0xFFFC6707))),
                  TextSpan(text: '! ¿A dónde quieres viajar hoy?'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SearchBarWidget(),
          const SizedBox(height: 24),
          const RecommendationsSection(),
          const SizedBox(height: 32),
          const CategoriesSection(),
          const SizedBox(height: 32),
          const OffersSection(),
          const SizedBox(height: 32),
          const NotificationsPanel(),
          const SizedBox(height: 24),
          const TrendingChart(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Layout para escritorio (fila con dos columnas)
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna principal (izquierda)
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                      children: const [
                        TextSpan(text: '¡Hola '),
                        TextSpan(text: 'Estudiante', style: TextStyle(color: Color(0xFFFC6707))),
                        TextSpan(text: '! ¿A dónde quieres viajar hoy?'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SearchBarWidget(),
                const SizedBox(height: 32),
                const RecommendationsSection(),
                const SizedBox(height: 48),
                const CategoriesSection(),
                const SizedBox(height: 48),
                const OffersSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        // Columna lateral (derecha)
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80),
                const NotificationsPanel(),
                const SizedBox(height: 24),
                const TrendingChart(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}