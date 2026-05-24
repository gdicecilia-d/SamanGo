// Sección de destinos turísticos 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/destination_model.dart';

class DestinationsWidget extends StatelessWidget {
  final List<DestinationModel> destinations;
  final bool isMobile;

  const DestinationsWidget({
    super.key,
    required this.destinations,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = isMobile ? 32.0 : 80.0;
    final availableWidth = screenWidth - padding;
    final cardsPerRow = isMobile ? 1 : 3;
    final cardWidth = (availableWidth - (cardsPerRow - 1) * 20) / cardsPerRow;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nuestros Destinos Favoritos',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 28),
        if (isMobile)
          Column(
            children: destinations.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: entry.key != destinations.length - 1 ? 20 : 0),
                child: _buildDestinationCard(entry.value, cardWidth),
              );
            }).toList(),
          )
        else
          Wrap(
            spacing: 20,
            runSpacing: 24,
            children: destinations.map((dest) => _buildDestinationCard(dest, cardWidth)).toList(),
          ),
      ],
    );
  }

  Widget _buildDestinationCard(DestinationModel destination, double cardWidth) {
    return SizedBox(
      width: cardWidth,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: Image.asset(
                destination.imageAsset,
                height: cardWidth * 0.75,
                width: cardWidth,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: cardWidth * 0.75,
                  width: cardWidth,
                  color: const Color(0xFFFC6707),
                  child: const Icon(Icons.image, color: Colors.white, size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    destination.name,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF333333),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFFFC6707)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          destination.location,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF888888),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}