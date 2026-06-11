import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/reserva.dart';

class ReviewView extends StatefulWidget {
  final Reserva reserva;
  final Map<String, dynamic> destinoData;

  const ReviewView({super.key, required this.reserva, required this.destinoData});

  @override
  State<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<ReviewView> {
  int _rating = 0;
  final TextEditingController _comentariosController = TextEditingController();
  bool? _coincidioServicio = true;
  final TextEditingController _detalleProblemaController = TextEditingController();
  bool _enviando = false;

  Future<void> _publicarResena() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una calificación (estrellas).'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_coincidioServicio == false && _detalleProblemaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, detalla qué no coincidió con lo prometido.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _enviando = true;
    });

    try {
      // Guardar la reseña en una colección dedicada (o dentro del destino)
      await FirebaseFirestore.instance.collection('resenas').add({
        'reservaId': widget.reserva.id,
        'estudianteId': widget.reserva.estudianteId,
        'paqueteId': widget.reserva.paqueteId,
        'operadorId': widget.destinoData['operadorId'] ?? '',
        'calificacion': _rating,
        'comentarios': _comentariosController.text.trim(),
        'coincidioPrometido': _coincidioServicio,
        'detalleProblema': _coincidioServicio == false ? _detalleProblemaController.text.trim() : null,
        'fechaPublicacion': FieldValue.serverTimestamp(),
      });

      // Opcional: Marcar la reserva como "reseñada" para ocultar el botón después,
      // aquí lo mantendremos simple.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Reseña publicada con éxito!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al publicar la reseña.'), backgroundColor: Colors.red),
        );
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _comentariosController.dispose();
    _detalleProblemaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text('Cuéntanos tu experiencia', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFC6707),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu viaje a ${widget.destinoData['nombre']}',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
              ),
              const SizedBox(height: 8),
              Text(
                '¿Qué tal estuvo tu experiencia?',
                style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF888888)),
              ),
              const SizedBox(height: 32),

              // 1. Puntuación (Estrellas)
              Center(
                child: Column(
                  children: [
                    Text('Calificación General', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFFD700),
                            size: 40,
                          ),
                          onPressed: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const Divider(height: 48),

              // 2. Comentarios
              Text('Déjanos tus comentarios (Opcional)', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _comentariosController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '¿Qué fue lo que más te gustó? ¿Algo por mejorar?',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFC6707))),
                ),
              ),
              const Divider(height: 48),

              // 3. Validación de servicio
              Text('Validación del Servicio', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text(
                '¿El servicio y el costo final coincidieron con lo prometido en la app?',
                style: GoogleFonts.outfit(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _coincidioServicio,
                    activeColor: const Color(0xFFFC6707),
                    onChanged: (val) {
                      setState(() {
                        _coincidioServicio = val;
                      });
                    },
                  ),
                  const Text('Sí, todo correcto'),
                  const SizedBox(width: 24),
                  Radio<bool>(
                    value: false,
                    groupValue: _coincidioServicio,
                    activeColor: const Color(0xFFFC6707),
                    onChanged: (val) {
                      setState(() {
                        _coincidioServicio = val;
                      });
                    },
                  ),
                  const Text('No'),
                ],
              ),
              
              if (_coincidioServicio == false) ...[
                const SizedBox(height: 16),
                Text('Por favor, detalla lo ocurrido:', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _detalleProblemaController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Me cobraron un extra no mencionado, o el servicio no era el mismo...',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                  ),
                ),
              ],
              const SizedBox(height: 48),

              // 4. Botón Publicar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _publicarResena,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC6707),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _enviando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Publicar Reseña', style: GoogleFonts.outfit(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
