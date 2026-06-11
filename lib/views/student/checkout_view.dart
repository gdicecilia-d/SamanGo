import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../controllers/reserva_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/reserva.dart';
import '../../models/estado_reserva.dart';
import 'student_home_view.dart';

class CheckoutView extends StatefulWidget {
  final String destinoId;
  final Map<String, dynamic> destinoData;

  const CheckoutView({
    super.key,
    required this.destinoId,
    required this.destinoData,
  });

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  DateTime? _fechaSeleccionada;
  int _numeroPersonas = 1;
  List<Map<String, String>> _acompanantes = [];
  final List<Map<String, dynamic>> _extrasDisponibles = [
    {'nombre': 'Comida y Snacks', 'precio': 15.0},
    {'nombre': 'Seguro de Viaje VIP', 'precio': 10.0},
    {'nombre': 'Guía Fotográfico', 'precio': 25.0},
  ];
  final List<String> _extrasSeleccionados = [];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Iniciar con un acompañante vacío si es más de 1
  }

  void _actualizarPersonas(int cambio) {
    setState(() {
      final nuevoNumero = _numeroPersonas + cambio;
      if (nuevoNumero >= 1 && nuevoNumero <= 10) {
        _numeroPersonas = nuevoNumero;
        
        // Ajustar lista de acompañantes
        final numAcompanantesNecesarios = _numeroPersonas - 1;
        
        if (_acompanantes.length < numAcompanantesNecesarios) {
          final faltantes = numAcompanantesNecesarios - _acompanantes.length;
          for (var i = 0; i < faltantes; i++) {
            _acompanantes.add({'nombre': '', 'dni': ''});
          }
        } else if (_acompanantes.length > numAcompanantesNecesarios) {
          _acompanantes = _acompanantes.sublist(0, numAcompanantesNecesarios);
        }
      }
    });
  }

  double get _subtotal {
    final precioPersona = (widget.destinoData['precio'] ?? 0.0).toDouble();
    return precioPersona * _numeroPersonas;
  }

  double get _costoExtras {
    double costo = 0;
    for (final extraNombre in _extrasSeleccionados) {
      final extraInfo = _extrasDisponibles.firstWhere((e) => e['nombre'] == extraNombre);
      costo += extraInfo['precio'] * _numeroPersonas; // El extra es por persona
    }
    return costo;
  }

  double get _totalGeneral => _subtotal + _costoExtras;

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFC6707),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _enviarSolicitud() async {
    if (_fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una fecha para tu viaje.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_numeroPersonas > 1 && !_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa los datos de tus acompañantes.'), backgroundColor: Colors.red),
      );
      return;
    }

    _formKey.currentState?.save();

    final auth = Provider.of<AuthController>(context, listen: false);
    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final userId = auth.usuarioActual?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para reservar.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Convertir lista de strings dinámicos a Map<String, dynamic>
    final acompanantesFinales = _acompanantes.map((e) => {
      'nombre': e['nombre'],
      'dni': e['dni'],
    }).toList();

    final nuevaReserva = Reserva(
      id: '',
      estudianteId: userId,
      paqueteId: widget.destinoId,
      estadoActual: EstadoReserva.solicitado,
      fechaInicio: _fechaSeleccionada,
      fechaFin: _fechaSeleccionada!.add(const Duration(days: 1)), // Asumiendo viaje de 1 día base, en el futuro sacar de destinoData
      numeroPersonas: _numeroPersonas,
      datosAcompanantes: acompanantesFinales,
      extrasSeleccionados: _extrasSeleccionados,
      subtotal: _subtotal,
      totalGeneral: _totalGeneral,
    );

    final exito = await reservaCtrl.crearReserva(nuevaReserva);

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Solicitud enviada con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      // Regresar al Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomeView()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hubo un error al enviar tu solicitud.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text('Configura tu aventura', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFC6707),
        elevation: 1,
      ),
      body: Consumer<ReservaController>(
        builder: (context, reservaCtrl, child) {
          if (reservaCtrl.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFC6707)));
          }

          final content = isMobile
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildConfiguracion(),
                    const SizedBox(height: 24),
                    _buildResumen(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: _buildConfiguracion(),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: _buildResumen(),
                      ),
                    ),
                  ],
                );

          return Form(
            key: _formKey,
            child: content,
          );
        },
      ),
    );
  }

  Widget _buildConfiguracion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.destinoData['nombre'] ?? 'Destino',
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
        ),
        const SizedBox(height: 24),

        // 1. Fecha
        _buildSectionTitle('1. ¿Cuándo viajas?'),
        const SizedBox(height: 12),
        InkWell(
          onTap: _seleccionarFecha,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFFFC6707)),
                const SizedBox(width: 12),
                Text(
                  _fechaSeleccionada == null
                      ? 'Selecciona una fecha disponible'
                      : '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: _fechaSeleccionada == null ? const Color(0xFF999999) : const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // 2. Personas
        _buildSectionTitle('2. ¿Quiénes van?'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Número de personas', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _numeroPersonas > 1 ? () => _actualizarPersonas(-1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFFFC6707),
                      ),
                      Text('$_numeroPersonas', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: _numeroPersonas < 10 ? () => _actualizarPersonas(1) : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFFFC6707),
                      ),
                    ],
                  ),
                ],
              ),
              
              if (_acompanantes.isNotEmpty) ...[
                const Divider(height: 24),
                Text('Datos de Acompañantes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                ...List.generate(_acompanantes.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Nombre completo',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                            onSaved: (val) => _acompanantes[index]['nombre'] = val ?? '',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Cédula / Pasaporte',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                            onSaved: (val) => _acompanantes[index]['dni'] = val ?? '',
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 3. Extras
        _buildSectionTitle('3. Personaliza tu experiencia'),
        const SizedBox(height: 12),
        ..._extrasDisponibles.map((extra) {
          final isSelected = _extrasSeleccionados.contains(extra['nombre']);
          return CheckboxListTile(
            title: Text(extra['nombre'], style: GoogleFonts.outfit(fontSize: 16)),
            subtitle: Text('+\$${extra['precio']} por persona', style: GoogleFonts.outfit(color: const Color(0xFF888888))),
            value: isSelected,
            activeColor: const Color(0xFFFC6707),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _extrasSeleccionados.add(extra['nombre']);
                } else {
                  _extrasSeleccionados.remove(extra['nombre']);
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  Widget _buildResumen() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen de tu Reserva', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(height: 32),
          
          _buildResumenRow('Paquete', widget.destinoData['nombre'] ?? 'Destino'),
          const SizedBox(height: 12),
          _buildResumenRow('Fecha', _fechaSeleccionada != null ? '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}' : 'No seleccionada'),
          const SizedBox(height: 12),
          _buildResumenRow('Personas', '$_numeroPersonas'),
          
          const Divider(height: 32),
          _buildResumenRow('Subtotal', '\$${_subtotal.toStringAsFixed(2)}', isBold: true),
          
          if (_extrasSeleccionados.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._extrasSeleccionados.map((extra) {
              final precioExtra = _extrasDisponibles.firstWhere((e) => e['nombre'] == extra)['precio'] * _numeroPersonas;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildResumenRow(extra, '+\$${precioExtra.toStringAsFixed(2)}', color: const Color(0xFF888888)),
              );
            }),
          ],
          
          const Divider(height: 32),
          _buildResumenRow('Total General', '\$${_totalGeneral.toStringAsFixed(2)}', isBold: true, fontSize: 22, color: const Color(0xFFFC6707)),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4ED),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFFC6707), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Al hacer clic, crearás una solicitud para que el operador verifique cupos. Podrás pagar una vez sea confirmada.',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFFC6707)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enviarSolicitud,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC6707),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Solicitar', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF333333)),
    );
  }

  Widget _buildResumenRow(String label, String value, {bool isBold = false, double fontSize = 16, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? const Color(0xFF333333),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? const Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}
