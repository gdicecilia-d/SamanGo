// Sección de destinos turísticos 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/destination_model.dart';
import '../../utils/responsive.dart';

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
    // Cell 
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nuestros Destinos Favoritos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: destinations.map((destination) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                        child: Image.asset(
                          destination.imageAsset,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 160,
                            width: double.infinity,
                            color: const Color(0xFFFC6707),
                            child: const Icon(Icons.image, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF333333),
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
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888888),
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
            }).toList(),
          ),
        ],
      );
    }

    // Computadora
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = isMobile ? Responsive.padding(context, 32) : Responsive.padding(context, 80);
    final availableWidth = screenWidth - padding;
    final cardsPerRow = isMobile ? 1 : 3;
    final cardWidth = (availableWidth - (cardsPerRow - 1) * Responsive.padding(context, 20)) / cardsPerRow;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nuestros Destinos Favoritos',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? Responsive.fontSize(context, 22) : Responsive.fontSize(context, 28),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        SizedBox(height: Responsive.height(context, 28)),
        if (isMobile)
          Column(
            children: destinations.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: entry.key != destinations.length - 1 ? Responsive.padding(context, 20) : 0),
                child: _buildDestinationCard(context, entry.value, cardWidth),
              );
            }).toList(),
          )
        else
          Wrap(
            spacing: Responsive.padding(context, 20),
            runSpacing: Responsive.padding(context, 24),
            children: destinations.map((dest) => _buildDestinationCard(context, dest, cardWidth)).toList(),
          ),
      ],
    );
  }

  Widget _buildDestinationCard(BuildContext context, DestinationModel destination, double cardWidth) {
    final imageHeight = cardWidth * 0.75;
    
    return SizedBox(
      width: cardWidth,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Responsive.padding(context, 14)),
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
                height: imageHeight,
                width: cardWidth,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: imageHeight,
                  width: cardWidth,
                  color: const Color(0xFFFC6707),
                  child: const Icon(Icons.image, color: Colors.white, size: 40),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    destination.name,
                    style: GoogleFonts.outfit(
                      fontSize: Responsive.fontSize(context, 15),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF333333),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Responsive.height(context, 6)),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFFFC6707)),
                      SizedBox(width: Responsive.padding(context, 4)),
                      Expanded(
                        child: Text(
                          destination.location,
                          style: GoogleFonts.outfit(
                            fontSize: Responsive.fontSize(context, 12),
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