// Buscador multicriterio con imagen de fondo
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/imagen_buscador.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            children: [
              _buildSearchField('Destino', Icons.location_on_outlined),
              _buildDivider(),
              _buildSearchField('Transporte', Icons.directions_bus_outlined),
              _buildDivider(),
              _buildSearchField('Presupuesto', Icons.attach_money_outlined),
              _buildDivider(),
              _buildSearchField('Alojamiento', Icons.bed_outlined),
              Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFC6707),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white, size: 22),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(String hint, IconData icon) {
    return Expanded(
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF999999)),
          prefixIcon: Icon(icon, color: const Color(0xFFFC6707), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFFC6707),
    );
  }
}