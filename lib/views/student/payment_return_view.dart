import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../controllers/auth_controller.dart';
import '../../controllers/reserva_controller.dart';
import '../../models/reserva.dart';
import 'my_trips_view.dart';

class PaymentReturnView extends StatefulWidget {
  const PaymentReturnView({super.key});

  @override
  State<PaymentReturnView> createState() => _PaymentReturnViewState();
}

class _PaymentReturnViewState extends State<PaymentReturnView> {
  bool _procesando = true;
  String _mensaje = 'Verificando sesión y pago...';
  bool _exito = false;

  @override
  void initState() {
    super.initState();
    _procesarRetorno();
  }

  Future<void> _procesarRetorno() async {
    try {
      String reservaId = '';
      String action = '';

      if (kIsWeb) {
        final fragment = Uri.base.fragment;
        if (fragment.isNotEmpty && fragment.contains('?')) {
          final queryString = fragment.split('?').last;
          final params = Uri.splitQueryString(queryString);
          reservaId = params['reservaId'] ?? '';
          action = params['action'] ?? '';
        }
      } else {
        final uri = Uri.base;
        reservaId = uri.queryParameters['reservaId'] ?? '';
        action = uri.queryParameters['action'] ?? '';
      }

      print('ReservaId: $reservaId, Action: $action');

      if (action == 'paypal_cancel') {
        setState(() {
          _procesando = false;
          _mensaje = 'El pago fue cancelado en PayPal.';
        });
        return;
      }

      if (reservaId.isEmpty) {
        setState(() {
          _procesando = false;
          _mensaje = 'Error: No se encontró la reserva.';
        });
        return;
      }

      final auth = Provider.of<AuthController>(context, listen: false);
      int intentos = 0;
      while (auth.isLoading && intentos < 30) {
        await Future.delayed(const Duration(milliseconds: 200));
        intentos++;
      }

      if (!auth.isAuthenticated) {
        await auth.reloadUser();
        if (!auth.isAuthenticated) {
          setState(() {
            _procesando = false;
            _mensaje = 'Error: No se pudo restaurar la sesión. Por favor, inicia sesión nuevamente.';
          });
          return;
        }
      }

      final comprobanteUrl = 'paypal_${DateTime.now().millisecondsSinceEpoch}_$reservaId';

      final doc = await FirebaseFirestore.instance.collection('reservas').doc(reservaId).get();
      if (!doc.exists) {
        setState(() {
          _procesando = false;
          _mensaje = 'Error: La reserva no existe en la base de datos.';
        });
        return;
      }
      
      final data = doc.data();
      if (data == null) return;
      
      final reserva = Reserva.fromMap(doc.id, data);
      
      if (reserva.estadoActual.name == 'pagado') {
        setState(() {
          _procesando = false;
          _exito = true;
          _mensaje = 'Este pago ya fue confirmado anteriormente.';
        });
        return;
      }

      final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
      final usuarioActual = auth.usuarioActual;

      if (usuarioActual == null) {
        setState(() {
          _procesando = false;
          _mensaje = 'Error: Usuario no autenticado.';
        });
        return;
      }

      final subio = await reservaCtrl.subirComprobanteYVerificar(
        reserva,
        comprobanteUrl,
        usuarioActual,
      );

      if (subio) {
        setState(() {
          _procesando = false;
          _exito = true;
          _mensaje = '¡Pago registrado! En espera de verificación por el operador.';
        });
      } else {
        setState(() {
          _procesando = false;
          _mensaje = 'Error al verificar el comprobante con el servidor.';
        });
      }

    } catch (e) {
      print('Error en PaymentReturnView: $e');
      setState(() {
        _procesando = false;
        _mensaje = 'Error al confirmar pago: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final isSmallMobile = screenWidth < 380;
    
    double cardWidth = isMobile ? double.infinity : 600.0;
    double titleFontSize = isMobile ? 24 : 32;
    double paddingSize = isMobile ? 32 : 48;
    double iconSize = isMobile ? 80 : 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48, vertical: 24),
          child: Container(
            width: cardWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(paddingSize),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_procesando) ...[
                    const CircularProgressIndicator(color: Color(0xFFFC6707)),
                    const SizedBox(height: 24),
                    Text(
                      _mensaje,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (_exito) ...[
                    Container(
                      width: 120,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF013088),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'PayPal',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFC6707),
                      ),
                      child: Icon(
                        Icons.check,
                        size: iconSize * 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Transacción Exitosa',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _mensaje,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MyTripsView()), 
                            (route) => false
                          );
                        },
                        child: Text(
                          'Ir a mis viajes',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFC6707),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.error, color: Colors.red, size: 80),
                    const SizedBox(height: 24),
                    Text(
                      _mensaje,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MyTripsView()), 
                          (route) => false
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC6707),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Volver a Mis Viajes'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}