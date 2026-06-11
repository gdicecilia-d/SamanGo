import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/reserva.dart';
import '../../controllers/reserva_controller.dart';
import '../../controllers/auth_controller.dart';

class PaymentView extends StatefulWidget {
  final Reserva reserva;
  final Map<String, dynamic> destinoData;

  const PaymentView({super.key, required this.reserva, required this.destinoData});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  String _metodoSeleccionado = 'PayPal';
  bool _procesando = false;

  Future<void> _realizarPago() async {
    setState(() {
      _procesando = true;
    });

    final auth = Provider.of<AuthController>(context, listen: false);
    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);

    // Simular un tiempo de procesamiento de pago o subida de comprobante
    await Future.delayed(const Duration(seconds: 2));

    // URL simulada del comprobante de pago
    const String comprobanteMockUrl = 'https://ejemplo.com/comprobante/12345.pdf';

    final exito = await reservaCtrl.subirComprobanteYVerificar(
      widget.reserva,
      comprobanteMockUrl,
      auth.usuarioActual!,
    );

    setState(() {
      _procesando = false;
    });

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago enviado a verificación. ¡Gracias!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Vuelve a Mis Viajes
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar el pago.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text('Finalizar Viaje', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFC6707),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen del Viaje', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF333333))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                children: [
                  _buildFila('Paquete', widget.destinoData['nombre'] ?? 'Destino'),
                  const Divider(height: 24),
                  _buildFila('Fecha', '${widget.reserva.fechaInicio?.day}/${widget.reserva.fechaInicio?.month}/${widget.reserva.fechaInicio?.year}'),
                  const Divider(height: 24),
                  _buildFila('Acompañantes', '${widget.reserva.numeroPersonas - 1} persona(s) extra'),
                  const Divider(height: 24),
                  _buildFila('Total a Pagar', '\$${widget.reserva.totalGeneral.toStringAsFixed(2)}', esTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Método de Pago', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF333333))),
            const SizedBox(height: 16),
            _buildOpcionPago('PayPal', Icons.paypal, 'paypal@ejemplo.com'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _procesando ? null : _realizarPago,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _procesando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Pagar \$${widget.reserva.totalGeneral.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFila(String label, String value, {bool esTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: esTotal ? 20 : 16,
            fontWeight: esTotal ? FontWeight.bold : FontWeight.w500,
            color: esTotal ? const Color(0xFF333333) : const Color(0xFF888888),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: esTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: esTotal ? Colors.green : const Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildOpcionPago(String nombre, IconData icono, String sub) {
    final isSelected = _metodoSeleccionado == nombre;
    return InkWell(
      onTap: () {
        setState(() {
          _metodoSeleccionado = nombre;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFC6707).withOpacity(0.05) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFFFC6707) : const Color(0xFFE0E0E0), width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icono, color: isSelected ? const Color(0xFFFC6707) : const Color(0xFF888888), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(sub, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF888888))),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFFC6707)),
          ],
        ),
      ),
    );
  }
}
