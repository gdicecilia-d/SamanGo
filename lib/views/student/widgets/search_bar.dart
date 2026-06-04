// Buscador multicriterio 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _destinoController = TextEditingController();
  String? _selectedTransporte;
  String? _selectedPresupuesto;
  String? _selectedAlojamiento;

  final List<String> _transportes = ['Todos', 'Bus', 'Avión', 'Barco', '4x4'];
  final List<String> _presupuestos = ['Todos', '\$0 - \$50', '\$50 - \$100', '\$100 - \$200', '\$200+'];
  final List<String> _alojamientos = ['Todos', 'Hotel', 'Posada', 'Camping', 'Eco lodge'];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    if (isMobile) {
      return _buildMobileLayout();
    }
    return _buildDesktopLayout();
  }

  // Cell
  Widget _buildMobileLayout() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Destino
          _buildMobileField('Destino', Icons.location_on_outlined, isDropdown: false),
          const SizedBox(height: 12),
          // Transporte
          _buildMobileField('Transporte', Icons.directions_bus_outlined, options: _transportes),
          const SizedBox(height: 12),
          // Presupuesto
          _buildMobileField('Presupuesto', Icons.attach_money_outlined, options: _presupuestos),
          const SizedBox(height: 12),
          // Alojamiento
          _buildMobileField('Alojamiento', Icons.bed_outlined, options: _alojamientos),
          const SizedBox(height: 12),
          // Lupa (botón buscar)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFC6707),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 24),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileField(String hint, IconData icon, {List<String>? options, bool isDropdown = true}) {
    if (!isDropdown) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _destinoController,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
            prefixIcon: Icon(icon, color: const Color(0xFFFC6707), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
          prefixIcon: Icon(icon, color: const Color(0xFFFC6707), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        value: _getCurrentValue(hint),
        items: options!.map((option) {
          return DropdownMenuItem(value: option, child: Text(option, style: GoogleFonts.outfit(fontSize: 14)));
        }).toList(),
        onChanged: (value) {
          setState(() {
            if (hint == 'Transporte') _selectedTransporte = value;
            if (hint == 'Presupuesto') _selectedPresupuesto = value;
            if (hint == 'Alojamiento') _selectedAlojamiento = value;
          });
        },
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFC6707)),
      ),
    );
  }

  // Compu 
  Widget _buildDesktopLayout() {
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
              _buildDesktopField('Destino', Icons.location_on_outlined, isDropdown: false),
              _buildDivider(),
              _buildDesktopField('Transporte', Icons.directions_bus_outlined, options: _transportes),
              _buildDivider(),
              _buildDesktopField('Presupuesto', Icons.attach_money_outlined, options: _presupuestos),
              _buildDivider(),
              _buildDesktopField('Alojamiento', Icons.bed_outlined, options: _alojamientos),
              Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFFC6707), shape: BoxShape.circle),
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

  Widget _buildDesktopField(String hint, IconData icon, {List<String>? options, bool isDropdown = true}) {
    if (!isDropdown) {
      return Expanded(
        child: TextField(
          controller: _destinoController,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
            prefixIcon: Icon(icon, color: const Color(0xFFFC6707), size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          ),
        ),
      );
    }
    return Expanded(
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
          prefixIcon: Icon(icon, color: const Color(0xFFFC6707), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        ),
        value: _getCurrentValue(hint),
        items: options!.map((option) {
          return DropdownMenuItem(value: option, child: Text(option, style: GoogleFonts.outfit(fontSize: 14)));
        }).toList(),
        onChanged: (value) {
          setState(() {
            if (hint == 'Transporte') _selectedTransporte = value;
            if (hint == 'Presupuesto') _selectedPresupuesto = value;
            if (hint == 'Alojamiento') _selectedAlojamiento = value;
          });
        },
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFC6707)),
      ),
    );
  }

  String? _getCurrentValue(String hint) {
    switch (hint) {
      case 'Transporte':
        return _selectedTransporte;
      case 'Presupuesto':
        return _selectedPresupuesto;
      case 'Alojamiento':
        return _selectedAlojamiento;
      default:
        return null;
    }
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 30, color: const Color(0xFFFC6707));
  }
}