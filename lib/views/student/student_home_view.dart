// Pantalla principal del estudiante después de iniciar sesión
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/student_header.dart';
import 'widgets/search_bar.dart';
import 'widgets/recommendations.dart';
import 'widgets/categories.dart';
import 'widgets/offers.dart';
import 'widgets/notifications_panel.dart';
import 'widgets/trending_chart.dart';

class StudentHomeView extends StatelessWidget {
  const StudentHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const StudentHeader(),
          Expanded(
            child: Row(
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
                        // Saludo
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF333333),
                              ),
                              children: const [
                                TextSpan(text: '¡Hola '),
                                TextSpan(
                                  text: 'Estudiante',
                                  style: TextStyle(color: Color(0xFFFC6707)),
                                ),
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
                        const SizedBox(height: 16),
                        const NotificationsPanel(),
                        const SizedBox(height: 24),
                        const TrendingChart(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFFC6707),
        child: const Icon(Icons.help_outline, color: Colors.white),
      ),
    );
  }
}