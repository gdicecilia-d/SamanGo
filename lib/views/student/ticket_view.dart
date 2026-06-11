import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/reserva.dart';

class TicketView extends StatelessWidget {
  final Reserva reserva;
  final Map<String, dynamic> destinoData;

  const TicketView({super.key, required this.reserva, required this.destinoData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text('Ticket de Viaje', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFC6707),
        elevation: 1,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera del Ticket
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.flight_takeoff, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'SamanGo Boarding Pass',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ),
                
                // Línea punteada decorativa
                Row(
                  children: [
                    Container(width: 15, height: 30, decoration: const BoxDecoration(color: Color(0xFFF9F9F9), borderRadius: BorderRadius.horizontal(right: Radius.circular(15)))),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Flex(
                            direction: Axis.horizontal,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: List.generate(
                              (constraints.constrainWidth() / 10).floor(),
                              (index) => const SizedBox(width: 5, height: 1.5, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white54))),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(width: 15, height: 30, decoration: const BoxDecoration(color: Color(0xFFF9F9F9), borderRadius: BorderRadius.horizontal(left: Radius.circular(15)))),
                  ],
                ),
                
                // Cuerpo del Ticket
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DESTINO', style: GoogleFonts.outfit(color: const Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(destinoData['nombre'] ?? 'Desconocido', style: GoogleFonts.outfit(color: const Color(0xFF333333), fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('FECHA', style: GoogleFonts.outfit(color: const Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('${reserva.fechaInicio?.day}/${reserva.fechaInicio?.month}/${reserva.fechaInicio?.year}', style: GoogleFonts.outfit(color: const Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PASAJEROS', style: GoogleFonts.outfit(color: const Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('${reserva.numeroPersonas}', style: GoogleFonts.outfit(color: const Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Text('PUNTO DE ENCUENTRO', style: GoogleFonts.outfit(color: const Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(destinoData['ubicacion'] ?? 'Consultar con operador', style: GoogleFonts.outfit(color: const Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 24),
                      
                      // Código de barras simulado
                      Center(
                        child: Column(
                          children: [
                            Container(
                              height: 60,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/UPC-A-036000291452.svg/1200px-UPC-A-036000291452.svg.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('ID: ${reserva.id}', style: GoogleFonts.outfit(color: const Color(0xFF888888), fontSize: 10)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modificando reserva...')));
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.purple,
                                side: const BorderSide(color: Colors.purple),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Modificar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Descargando ticket...')));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Descargar'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
