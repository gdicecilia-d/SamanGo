// Buscador multicriterio
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../search_results_view.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  // Controlador del campo de texto de destino
  final TextEditingController _destinoController = TextEditingController();

  // Valores seleccionados en los filtros
  String? _selectedTransporte;
  String? _selectedPresupuesto;
  String? _selectedAlojamiento;

  // Opciones de cada filtro
  final List<String> _transportes = ['Todos', 'Bus', 'Avión', 'Barco', '4x4'];
  final List<String> _presupuestos = ['Todos', '\$0 - \$50', '\$50 - \$100', '\$100 - \$200', '\$200+'];
  final List<String> _alojamientos = ['Todos', 'Hotel', 'Posada', 'Camping', 'Eco lodge'];

  // Abre la pantalla de resultados con los filtros que el usuario eligió
void _buscar() {
    final ctx = context;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(ctx, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => SearchResultsView(
            destino: _destinoController.text.trim(),
            transporte: _selectedTransporte,
            presupuesto: _selectedPresupuesto,
            alojamiento: _selectedAlojamiento,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    // Muestra el layout según el tamaño de pantalla
    if (isMobile) {
      return _buildMobileLayout();
    }
    return _buildDesktopLayout();
  }

  // Layout móvil: campos apilados uno debajo del otro
  Widget _buildMobileLayout() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Campo de texto para escribir el destino
          _buildMobileField('Destino', Icons.location_on_outlined, isDropdown: false),
          const SizedBox(height: 12),
          // Dropdown de transporte
          _buildMobileField('Transporte', Icons.directions_bus_outlined, options: _transportes),
          const SizedBox(height: 12),
          // Dropdown de presupuesto
          _buildMobileField('Presupuesto', Icons.attach_money_outlined, options: _presupuestos),
          const SizedBox(height: 12),
          // Dropdown de alojamiento
          _buildMobileField('Alojamiento', Icons.bed_outlined, options: _alojamientos),
          const SizedBox(height: 12),
          // Botón de búsqueda alineado a la derecha
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFC6707),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 24),
                onPressed: _buscar,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Crea un campo individual para el layout móvil
  // Si isDropdown es false, muestra un TextField; si es true, muestra un Dropdown
  Widget _buildMobileField(String hint, IconData icon, {List<String>? options, bool isDropdown = true}) {
    if (!isDropdown) {
      // Campo de texto libre para el destino
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

    // Dropdown con las opciones del filtro
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
          // Guarda el valor seleccionado según el filtro
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

  // Layout escritorio: todos los campos en una sola fila con imagen de fondo
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
              // Campo de destino
              _buildDesktopField('Destino', Icons.location_on_outlined, isDropdown: false),
              _buildDivider(),
              // Dropdown de transporte
              _buildDesktopField('Transporte', Icons.directions_bus_outlined, options: _transportes),
              _buildDivider(),
              // Dropdown de presupuesto
              _buildDesktopField('Presupuesto', Icons.attach_money_outlined, options: _presupuestos),
              _buildDivider(),
              // Dropdown de alojamiento
              _buildDesktopField('Alojamiento', Icons.bed_outlined, options: _alojamientos),
              // Botón de búsqueda
              Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFFC6707), shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white, size: 22),
                  onPressed: _buscar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Crea un campo individual para el layout escritorio
  Widget _buildDesktopField(String hint, IconData icon, {List<String>? options, bool isDropdown = true}) {
    if (!isDropdown) {
      // Campo de texto libre para el destino
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

    // Dropdown con las opciones del filtro
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
          // Guarda el valor seleccionado según el filtro
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

  // Devuelve el valor actual del dropdown según su nombre
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

  // Línea separadora entre campos del buscador en escritorio
  Widget _buildDivider() {
    return Container(width: 1, height: 30, color: const Color(0xFFFC6707));
  }
}