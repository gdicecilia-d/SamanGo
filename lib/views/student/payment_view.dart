import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/reserva.dart';
import '../../controllers/reserva_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/notificacion_service.dart';
import '../../services/paypal_service.dart';
import '../shared/app_header.dart';
import 'my_trips_view.dart';
import 'favorites_view.dart';
import 'edit_profile_view.dart';
import 'notifications_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'dart:convert';
import 'dart:html' as html;

class PaymentView extends StatefulWidget {
  final Reserva reserva;
  final Map<String, dynamic> destinoData;

  const PaymentView({super.key, required this.reserva, required this.destinoData});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _procesando = false;
  bool _pagoExitoso = false;
  
  final PayPalService _payPalService = PayPalService();

  bool get _isOffer => widget.destinoData['isOffer'] ?? false;
  Color get _primaryColor => _isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);
  Color get _primaryLight => _primaryColor.withOpacity(0.1);

  String get _formattedFecha {
    final inicio = widget.reserva.fechaInicio;
    final fin = widget.reserva.fechaFin;
    if (inicio == null) return 'Fecha no seleccionada';
    
    final meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    
    if (fin == null || inicio.year == fin.year && inicio.month == fin.month && inicio.day == fin.day) {
      return '${inicio.day} de ${meses[inicio.month - 1]}, ${inicio.year}';
    }
    
    return '${inicio.day} - ${fin.day} de ${meses[inicio.month - 1]}, ${inicio.year}';
  }

  @override
  void initState() {
    super.initState();
    _verificarRetornoPayPalWeb();
  }

  void _verificarRetornoPayPalWeb() {
    if (!kIsWeb) return;
    
    try {
      final url = html.window.location.href;
      
      if (url.contains('cancel') || url.contains('cancelled')) {
        html.window.localStorage.remove('paypal_pending');
        _mostrarMensaje('Pago cancelado. Puedes intentar nuevamente.');
        return;
      }
      
      if (url.contains('token=') && url.contains('PayerID=')) {
        _procesarPagoExitosoWeb();
      }
    } catch (e) {
      print('Error verificando retorno PayPal: $e');
    }
  }

  void _procesarPagoExitosoWeb() async {
    setState(() {
      _procesando = true;
    });

    final auth = Provider.of<AuthController>(context, listen: false);
    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);

    try {
      final pendingData = html.window.localStorage['paypal_pending'];
      html.window.localStorage.remove('paypal_pending');
      
      if (pendingData == null) {
        setState(() {
          _procesando = false;
        });
        return;
      }

      // Esperar a que el AuthController restaure la sesión de Firebase
      while (auth.isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await auth.reloadUser();
      final usuarioActual = auth.usuarioActual;
      
      if (usuarioActual == null) {
        setState(() {
          _procesando = false;
        });
        _mostrarMensaje('Error: Usuario no autenticado');
        return;
      }

      final comprobanteUrl = 'paypal_${DateTime.now().millisecondsSinceEpoch}_${widget.reserva.id}';

      final subio = await reservaCtrl.subirComprobanteYVerificar(
        widget.reserva,
        comprobanteUrl,
        usuarioActual,
      );

      if (subio && mounted) {
        final destinoDoc = await FirebaseFirestore.instance
            .collection('destinos')
            .doc(widget.reserva.paqueteId)
            .get();
        final destino = destinoDoc.data() as Map<String, dynamic>?;
        final operadorId = destino?['operadorId'];

        if (operadorId != null && usuarioActual != null) {
          await NotificacionService().notificarPagoRecibido(
            operadorId: operadorId,
            estudianteNombre: usuarioActual.nombre,
            estudianteApellido: usuarioActual.apellido ?? '',
            estudianteCarnet: usuarioActual.carnet ?? '',
            nombrePaquete: widget.destinoData['nombre'] ?? 'destino',
          );
        }
        
        html.window.history.replaceState(null, '', '/#/payment');

        setState(() {
          _pagoExitoso = true;
          _procesando = false;
        });

        _mostrarExitoYRedirigir();
      } else {
        setState(() {
          _procesando = false;
        });
        _mostrarMensaje('Error al verificar el pago');
      }
    } catch (e) {
      setState(() {
        _procesando = false;
      });
      _mostrarMensaje('Error al procesar el pago: ${e.toString()}');
    }
  }

  Future<void> _realizarPago() async {
    setState(() {
      _procesando = true;
    });

    final auth = Provider.of<AuthController>(context, listen: false);

    try {
      String currentUrl = 'http://localhost:5000/#/paypal_return';
      
      if (kIsWeb) {
        final fullUrl = Uri.base.toString();
        final uri = Uri.parse(fullUrl);
        currentUrl = '${uri.scheme}://${uri.host}:${uri.port}/#/paypal_return?reservaId=${widget.reserva.id}';
      }

      final exito = await _payPalService.processPayment(
        context: context,
        amount: widget.reserva.totalGeneral,
        currency: 'USD',
        description: 'Reserva: ${widget.destinoData['nombre']}',
        returnUrl: currentUrl,
        cancelUrl: kIsWeb ? '${Uri.parse(Uri.base.toString()).scheme}://${Uri.parse(Uri.base.toString()).host}:${Uri.parse(Uri.base.toString()).port}/#/paypal_return?action=paypal_cancel' : currentUrl,
        reservaId: widget.reserva.id,
        destinoId: widget.reserva.paqueteId,
        estudianteId: widget.reserva.estudianteId,
      );

      if (kIsWeb) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _procesando = false;
      });

      if (exito == true) {
        final comprobanteUrl = 'paypal_${DateTime.now().millisecondsSinceEpoch}_${widget.reserva.id}';

        final usuario = auth.usuarioActual;
        final reservaCtrl = Provider.of<ReservaController>(context, listen: false);

        if (usuario == null) {
          _mostrarMensaje('Error: Usuario no autenticado');
          return;
        }

        final subio = await reservaCtrl.subirComprobanteYVerificar(
          widget.reserva,
          comprobanteUrl,
          usuario,
        );

        if (subio && mounted) {
          final destinoDoc = await FirebaseFirestore.instance
              .collection('destinos')
              .doc(widget.reserva.paqueteId)
              .get();
          final destino = destinoDoc.data() as Map<String, dynamic>?;
          final operadorId = destino?['operadorId'];

          if (operadorId != null && usuario != null) {
            await NotificacionService().notificarPagoRecibido(
              operadorId: operadorId,
              estudianteNombre: usuario.nombre,
              estudianteApellido: usuario.apellido ?? '',
              estudianteCarnet: usuario.carnet ?? '',
              nombrePaquete: widget.destinoData['nombre'] ?? 'destino',
            );
          }

          setState(() {
            _pagoExitoso = true;
          });

          _mostrarExitoYRedirigir();
        } else {
          _mostrarMensaje('Error al verificar el pago');
        }
      } else if (exito == false) {
        _mostrarMensaje('Pago cancelado. Puedes intentar nuevamente.');
      } else {
        _mostrarMensaje('Error al procesar el pago');
      }
    } catch (e) {
      setState(() {
        _procesando = false;
      });
      _mostrarMensaje('Error al procesar el pago: ${e.toString()}');
    }
  }

  void _mostrarExitoYRedirigir() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pago exitoso. Tu reserva esta confirmada.'),
        backgroundColor: Color(0xFFFC6707),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MyTripsView()),
          (route) => false,
        );
      }
    });
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: _primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleMenuSelected(String menu) {
    if (menu == 'Inicio') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MyTripsView()),
        (route) => false,
      );
    } else if (menu == 'Favoritos') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FavoritesView()),
      );
    } else if (menu == 'Notificaciones') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsView()),
      );
    } else if (menu == 'Mis Viajes') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyTripsView()),
      );
    }
  }

  void _handleEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileView()),
    );
  }

  void _handleLogout() {
    CustomConfirmDialog.show(
      context: context,
      title: 'Cerrar Sesion',
      message: '¿Estas seguro de que deseas cerrar sesion?',
      confirmText: 'Salir',
      icon: Icons.logout,
    ).then((confirm) async {
      if (confirm == true) {
        await Provider.of<AuthController>(context, listen: false).logout();
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
        );
      }
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _irAMisViajes() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MyTripsView()),
      (route) => false,
    );
  }

  void _volver() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final isLargeScreen = screenWidth > 1400;
    final double backButtonTop = isMobile ? 80 : 100;
    final double backButtonSize = isLargeScreen ? 20 : 16;

    double cardWidth;
    double titleFontSize;
    double sectionFontSize;
    double paddingSize;
    double buttonWidth;
    double buttonFontSize;
    double buttonPaddingVertical;
    double imageHeight;
    double infoFontSize;
    double espacioEntreColumnas;
    
    if (isMobile) {
      cardWidth = double.infinity;
      titleFontSize = 24;
      sectionFontSize = 18;
      paddingSize = 20;
      buttonWidth = double.infinity;
      buttonFontSize = 14;
      buttonPaddingVertical = 12;
      imageHeight = 200;
      infoFontSize = 14;
      espacioEntreColumnas = 0;
    } else if (isLargeScreen) {
      cardWidth = 1200.0;
      titleFontSize = 42;
      sectionFontSize = 28;
      paddingSize = 48;
      buttonWidth = 350.0;
      buttonFontSize = 18;
      buttonPaddingVertical = 18;
      imageHeight = 320;
      infoFontSize = 18;
      espacioEntreColumnas = 60;
    } else {
      cardWidth = 1000.0;
      titleFontSize = 36;
      sectionFontSize = 24;
      paddingSize = 40;
      buttonWidth = 320.0;
      buttonFontSize = 16;
      buttonPaddingVertical = 16;
      imageHeight = 280;
      infoFontSize = 16;
      espacioEntreColumnas = 48;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer() : null,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: _getBackgroundImage(),
              color: const Color(0xFFF5F5F5),
            ),
          ),
          Column(
            children: [
              AppHeader(
                activeMenu: '',
                onMenuSelected: _handleMenuSelected,
                onEditProfile: _handleEditProfile,
                onLogout: _handleLogout,
                menuItems: const ['Inicio', 'Mis Viajes', 'Favoritos'],
                isMobile: isMobile,
                onMenuTap: isMobile ? _openDrawer : null,
              ),
              Expanded(
                child: _pagoExitoso
                    ? _buildSuccessScreen(isMobile, isLargeScreen)
                    : Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 48,
                            vertical: isMobile ? 16 : 32,
                          ),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(paddingSize),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Finalizar Pago',
                                        style: GoogleFonts.outfit(
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF333333),
                                        ),
                                      ),
                                      SizedBox(height: isMobile ? 8 : 12),
                                      Text(
                                        widget.destinoData['nombre'] ?? 'Destino',
                                        style: GoogleFonts.outfit(
                                          fontSize: isMobile ? 14 : infoFontSize - 2,
                                          color: const Color(0xFF666666),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                                
                                Padding(
                                  padding: EdgeInsets.all(paddingSize),
                                  child: isMobile
                                      ? Column(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: _buildImageDestino(imageHeight),
                                            ),
                                            const SizedBox(height: 20),
                                            _buildInfoRow('Destino:', widget.destinoData['ubicacion'] ?? widget.destinoData['nombre'] ?? 'No especificado', infoFontSize),
                                            const SizedBox(height: 12),
                                            _buildInfoRow('Fecha:', _formattedFecha, infoFontSize),
                                            const SizedBox(height: 12),
                                            _buildInfoRow('Precio Total:', '\$${widget.reserva.totalGeneral.toStringAsFixed(2)}', infoFontSize, isTotal: true),
                                            const SizedBox(height: 24),
                                            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                                            const SizedBox(height: 24),
                                            Text(
                                              'Metodo de Pago',
                                              style: GoogleFonts.outfit(
                                                fontSize: infoFontSize + 4,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF333333),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            _buildPaypalOption(infoFontSize),
                                            const SizedBox(height: 20),
                                            Text(
                                              'El pago se procesara de forma inmediata a traves de la plataforma de PayPal',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.outfit(
                                                fontSize: infoFontSize - 2,
                                                color: const Color(0xFF888888),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                                            const SizedBox(height: 24),
                                            Center(
                                              child: SizedBox(
                                                width: 240,
                                                child: ElevatedButton(
                                                  onPressed: _procesando ? null : _realizarPago,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: _primaryColor,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                  ),
                                                  child: _procesando
                                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                      : Text(
                                                          'Pagar',
                                                          style: GoogleFonts.outfit(
                                                            fontSize: infoFontSize,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Una vez verificado el pago por el sistema, podras descargar tu ticket para el viaje.',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.outfit(
                                                fontSize: infoFontSize - 3,
                                                color: const Color(0xFF999999),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(20),
                                                    child: _buildImageDestino(imageHeight),
                                                  ),
                                                  SizedBox(height: isLargeScreen ? 32 : 24),
                                                  Text(
                                                    'Resumen del Viaje',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: sectionFontSize,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF333333),
                                                    ),
                                                  ),
                                                  SizedBox(height: isLargeScreen ? 24 : 20),
                                                  _buildInfoRow('Destino:', widget.destinoData['ubicacion'] ?? widget.destinoData['nombre'] ?? 'No especificado', infoFontSize),
                                                  SizedBox(height: isLargeScreen ? 20 : 16),
                                                  _buildInfoRow('Fecha:', _formattedFecha, infoFontSize),
                                                  SizedBox(height: isLargeScreen ? 20 : 16),
                                                  _buildInfoRow('Precio Total:', '\$${widget.reserva.totalGeneral.toStringAsFixed(2)}', infoFontSize, isTotal: true),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: espacioEntreColumnas),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Metodo de Pago',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: sectionFontSize,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF333333),
                                                    ),
                                                  ),
                                                  SizedBox(height: isLargeScreen ? 24 : 20),
                                                  _buildPaypalOption(infoFontSize),
                                                  SizedBox(height: isLargeScreen ? 32 : 24),
                                                  Text(
                                                    'El pago se procesara de forma inmediata a traves de la plataforma de PayPal',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: infoFontSize - 2,
                                                      color: const Color(0xFF888888),
                                                    ),
                                                  ),
                                                  SizedBox(height: isLargeScreen ? 40 : 32),
                                                  const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                                                  SizedBox(height: isLargeScreen ? 32 : 24),
                                                  Center(
                                                    child: SizedBox(
                                                      width: buttonWidth,
                                                      child: ElevatedButton(
                                                        onPressed: _procesando ? null : _realizarPago,
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: _primaryColor,
                                                          foregroundColor: Colors.white,
                                                          padding: EdgeInsets.symmetric(vertical: buttonPaddingVertical),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(40),
                                                          ),
                                                        ),
                                                        child: _procesando
                                                            ? SizedBox(height: buttonFontSize, width: buttonFontSize, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                            : Text(
                                                                'Pagar',
                                                                style: GoogleFonts.outfit(
                                                                  fontSize: buttonFontSize,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: isLargeScreen ? 24 : 20),
                                                  Text(
                                                    'Una vez verificado el pago por el sistema, podras descargar tu ticket para el viaje.',
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: infoFontSize - 4,
                                                      color: const Color(0xFF999999),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          if (!_pagoExitoso)
            Positioned(
              top: backButtonTop,
              right: 24,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _volver,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, color: _primaryColor, size: backButtonSize),
                        const SizedBox(width: 6),
                        Text(
                          'Volver',
                          style: GoogleFonts.outfit(
                            fontSize: backButtonSize,
                            color: _primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final auth = Provider.of<AuthController>(context);
    final user = auth.usuarioActual;
    
    return Drawer(
      backgroundColor: Colors.white,
      width: 280,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _handleEditProfile,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFC6707), width: 2),
                      ),
                      child: ClipOval(
                        child: user?.fotoBase64 != null && user!.fotoBase64!.isNotEmpty
                            ? Image.memory(base64Decode(user.fotoBase64!), width: 50, height: 50, fit: BoxFit.cover)
                            : const CircleAvatar(
                                backgroundColor: Color(0xFFFDDBB3),
                                child: Icon(Icons.person, color: Color(0xFFFC6707), size: 28),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.nombre ?? 'Estudiante', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF333333))),
                        Text(user?.apellido ?? '', style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF666666))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDrawerItem('Inicio', Icons.home_outlined, () {
                      Navigator.pop(context);
                      _handleMenuSelected('Inicio');
                    }),
                    _buildDrawerItem('Mis Viajes', Icons.airplane_ticket_outlined, () {
                      Navigator.pop(context);
                      _handleMenuSelected('Mis Viajes');
                    }),
                    _buildDrawerItem('Favoritos', Icons.favorite_border, () {
                      Navigator.pop(context);
                      _handleMenuSelected('Favoritos');
                    }),
                    _buildDrawerItem('Notificaciones', Icons.notifications_outlined, () {
                      Navigator.pop(context);
                      _handleMenuSelected('Notificaciones');
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                _buildDrawerItem('Cerrar Sesion', Icons.logout_outlined, () {
                  Navigator.pop(context);
                  _handleLogout();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFC6707)),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF333333),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow(String label, String value, double fontSize, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: _primaryColor,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? _primaryColor : const Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildPaypalOption(double fontSize) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _primaryColor, width: 2),
            ),
            child: Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 90,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF013088),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'PayPal',
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pagar con PayPal',
              style: GoogleFonts.outfit(
                fontSize: fontSize - 2,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageDestino(double height) {
    final imagenUrl = widget.destinoData['imagen'] ?? '';
    
    if (imagenUrl.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFDDBB3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.image, size: height * 0.25, color: _primaryColor),
      );
    }
    
    if (imagenUrl.startsWith('data:image')) {
      try {
        final base64String = imagenUrl.split(',').last;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            base64Decode(base64String),
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFDDBB3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.image, size: height * 0.25, color: _primaryColor),
        );
      }
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        imagenUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            width: double.infinity,
            color: const Color(0xFFF5F5F5),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          height: height,
          width: double.infinity,
          color: const Color(0xFFFDDBB3),
          child: Icon(Icons.image, size: height * 0.25, color: _primaryColor),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(bool isMobile, bool isLargeScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 380;
    
    double cardWidth;
    double titleFontSize;
    double paddingSize;
    double iconSize;
    
    if (isMobile) {
      cardWidth = double.infinity;
      titleFontSize = 24;
      paddingSize = 32;
      iconSize = 80;
    } else if (isLargeScreen) {
      cardWidth = 700.0;
      titleFontSize = 38;
      paddingSize = 56;
      iconSize = 120;
    } else {
      cardWidth = 600.0;
      titleFontSize = 32;
      paddingSize = 48;
      iconSize = 100;
    }
    
    return Center(
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
                      style: GoogleFonts.outfit(
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryColor,
                  ),
                  child: Icon(
                    Icons.check,
                    size: iconSize * 0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Transaccion Exitosa',
                  style: GoogleFonts.outfit(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _irAMisViajes,
                    child: Text(
                      'Ir a mis viajes',
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DecorationImage? _getBackgroundImage() {
    final imagenUrl = widget.destinoData['imagen'] ?? '';
    if (imagenUrl.isEmpty) return null;
    
    if (imagenUrl.startsWith('data:image')) {
      try {
        final base64String = imagenUrl.split(',').last;
        return DecorationImage(
          image: MemoryImage(base64Decode(base64String)),
          fit: BoxFit.cover,
          opacity: 0.15,
        );
      } catch (_) {
        return null;
      }
    }
    
    return DecorationImage(
      image: NetworkImage(imagenUrl),
      fit: BoxFit.cover,
      opacity: 0.15,
    );
  }
}