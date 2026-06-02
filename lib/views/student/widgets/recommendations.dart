// Sección de destinos recomendados
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecommendationsSection extends StatelessWidget {
  const RecommendationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recomendados para ti',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                RecommendationCard(
                  imageAsset: 'assets/images/choroni.png',
                  title: 'Full Day Choroni',
                  location: 'Playa Grande',
                  price: 25,
                ),
                SizedBox(width: 16),
                RecommendationCard(
                  imageAsset: 'assets/images/merida.png',
                  title: 'Escape de Montaña',
                  location: 'Mérida - Pico Humboldt',
                  price: 180,
                ),
                SizedBox(width: 16),
                RecommendationCard(
                  imageAsset: 'assets/images/medanos.png',
                  title: 'Tour de Dunas',
                  location: 'Médanos de Coro',
                  price: 65,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecommendationCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String location;
  final double price;

  const RecommendationCard({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.location,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.asset(
              imageAsset,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 140,
                color: const Color(0xFFFDDBB3),
                child: const Icon(Icons.image, color: Color(0xFFFC6707)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFC6707),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Ver más',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFFFC6707),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}