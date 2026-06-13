import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/reserva.dart';
import '../../controllers/reserva_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/notificacion_service.dart';
import '../shared/app_header.dart';
import 'student_home_view.dart';
import 'my_trips_view.dart';
import 'favorites_view.dart';
import 'edit_profile_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'dart:convert';

class PaymentView extends StatefulWidget {
  final Reserva reserva;
  final Map<String, dynamic> destinoData;

  const PaymentView({super.key, required this.reserva, required this.destinoData});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  bool _procesando = false;
  bool _pagoExitoso = false;

  bool get _isOffer => widget.destinoData['isOffer'] ?? false;
  Color get _primaryColor => _isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);
  Color get _primaryLight => _primaryColor.withOpacity(0.1);

  String get _formattedFecha {
    final fecha = widget.reserva.fechaInicio;
    if (fecha == null) return 'Fecha no seleccionada';
    final meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return '${fecha.day} de ${meses[fecha.month - 1]}, ${fecha.year}';
  }

  Future<void> _realizarPago() async {
    setState(() {
      _procesando = true;
    });

    final auth = Provider.of<AuthController>(context, listen: false);
    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final usuario = auth.usuarioActual;

    await Future.delayed(const Duration(seconds: 2));

    const String comprobanteMockUrl = 'https://ejemplo.com/comprobante/12345.pdf';

    final exito = await reservaCtrl.subirComprobanteYVerificar(
      widget.reserva,
      comprobanteMockUrl,
      auth.usuarioActual!,
    );

    if (exito && mounted) {
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
        _procesando = false;
      });
    } else if (mounted) {
      setState(() {
        _procesando = false;
      });
      _mostrarMensaje('Error al procesar el pago. Intenta nuevamente.');
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: _primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleMenuSelected(String menu) {
    if (menu == 'Inicio') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomeView()),
        (route) => false,
      );
    } else if (menu == 'Mis Viajes') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyTripsView()),
      );
    } else if (menu == 'Favoritos') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FavoritesView()),
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
      title: 'Cerrar Sesión',
      message: '¿Estás seguro de que deseas cerrar sesión?',
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo difuminado con la imagen del destino
          if (!_pagoExitoso)
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
                onMenuTap: null,
              ),
              Expanded(
                child: _pagoExitoso
                    ? _buildSuccessScreen(isMobile, isLargeScreen)
                    : _buildPaymentScreen(isMobile, isLargeScreen),
              ),
            ],
          ),
          // Botón volver flotante
          if (!_pagoExitoso)
            Positioned(
              top: isMobile ? 80 : 100,
              right: 24,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _volver,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        Icon(Icons.arrow_back, color: _primaryColor, size: isLargeScreen ? 20 : 16),
                        const SizedBox(width: 4),
                        Text(
                          'Volver',
                          style: GoogleFonts.outfit(
                            fontSize: isLargeScreen ? 16 : 14,
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

  Widget _buildPaymentScreen(bool isMobile, bool isLargeScreen) {
    final paddingHorizontal = isMobile ? 16.0 : (isLargeScreen ? 48.0 : 24.0);
    final cardPadding = isMobile ? 20.0 : (isLargeScreen ? 40.0 : 28.0);
    final titleFontSize = isMobile ? 24.0 : (isLargeScreen ? 32.0 : 28.0);
    final subtitleFontSize = isMobile ? 14.0 : (isLargeScreen ? 18.0 : 16.0);
    final sectionFontSize = isMobile ? 18.0 : (isLargeScreen ? 22.0 : 20.0);
    final buttonFontSize = isMobile ? 16.0 : (isLargeScreen ? 20.0 : 18.0);
    final buttonPaddingVertical = isMobile ? 14.0 : (isLargeScreen ? 20.0 : 16.0);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(paddingHorizontal),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 1200 : (isMobile ? double.infinity : 900),
          ),
          child: Column(
            children: [
              // Título
              Text(
                'Finalizar Pago',
                style: GoogleFonts.outfit(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.destinoData['nombre'] ?? 'Destino',
                style: GoogleFonts.outfit(
                  fontSize: subtitleFontSize,
                  color: const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 24),
              
              // Tarjeta principal
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isMobile
                    ? _buildMobileContent(cardPadding, sectionFontSize, subtitleFontSize, buttonFontSize, buttonPaddingVertical)
                    : _buildDesktopContent(cardPadding, sectionFontSize, subtitleFontSize, buttonFontSize, buttonPaddingVertical, isLargeScreen),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileContent(double cardPadding, double sectionFontSize, double subtitleFontSize, double buttonFontSize, double buttonPaddingVertical) {
    return Column(
      children: [
        // Resumen del Viaje
        Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen del Viaje',
                style: GoogleFonts.outfit(
                  fontSize: sectionFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              _buildImageDestino(),
              const SizedBox(height: 16),
              _buildInfoRow('Destino', widget.destinoData['ubicacion'] ?? widget.destinoData['nombre'] ?? 'No especificado'),
              const SizedBox(height: 12),
              _buildInfoRow('Fecha', _formattedFecha),
              const SizedBox(height: 12),
              _buildInfoRow('Precio Total', '\$${widget.reserva.totalGeneral.toStringAsFixed(2)}', isTotal: true),
            ],
          ),
        ),
        // Divisor
        Container(height: 1, color: const Color(0xFFE0E0E0)),
        // Método de Pago
        Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Método de Pago',
                style: GoogleFonts.outfit(
                  fontSize: sectionFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              _buildPaypalOption(),
              const SizedBox(height: 20),
              Text(
                'El pago se procesará de forma inmediata a través de la plataforma de PayPal',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: subtitleFontSize - 2,
                  color: const Color(0xFF888888),
                ),
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: const Color(0xFFE0E0E0)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _procesando ? null : _realizarPago,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: buttonPaddingVertical),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _procesando
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Pagar',
                          style: GoogleFonts.outfit(
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Una vez verificado el pago por el sistema, podrás descargar tu ticket para el viaje.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopContent(double cardPadding, double sectionFontSize, double subtitleFontSize, double buttonFontSize, double buttonPaddingVertical, bool isLargeScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel izquierdo - Resumen
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen del Viaje',
                  style: GoogleFonts.outfit(
                    fontSize: sectionFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 16),
                _buildImageDestino(),
                const SizedBox(height: 20),
                _buildInfoRow('Destino', widget.destinoData['ubicacion'] ?? widget.destinoData['nombre'] ?? 'No especificado'),
                const SizedBox(height: 12),
                _buildInfoRow('Fecha', _formattedFecha),
                const SizedBox(height: 12),
                _buildInfoRow('Precio Total', '\$${widget.reserva.totalGeneral.toStringAsFixed(2)}', isTotal: true),
              ],
            ),
          ),
        ),
        // Divisor vertical
        Container(
          width: 1,
          height: isLargeScreen ? 450 : 380,
          color: _primaryColor,
        ),
        // Panel derecho - Método de Pago
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Método de Pago',
                  style: GoogleFonts.outfit(
                    fontSize: sectionFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 20),
                _buildPaypalOption(),
                const SizedBox(height: 24),
                Text(
                  'El pago se procesará de forma inmediata a través de la plataforma de PayPal',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: subtitleFontSize - 2,
                    color: const Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 24),
                Container(height: 1, color: const Color(0xFFE0E0E0)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _procesando ? null : _realizarPago,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: buttonPaddingVertical),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _procesando
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Pagar',
                            style: GoogleFonts.outfit(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Una vez verificado el pago por el sistema, podrás descargar tu ticket para el viaje.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageDestino() {
    final imagenUrl = widget.destinoData['imagen'] ?? '';
    final imageHeight = 140.0;
    
    if (imagenUrl.isEmpty) {
      return Container(
        height: imageHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFDDBB3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.image, size: 50, color: _primaryColor),
      );
    }
    
    if (imagenUrl.startsWith('data:image')) {
      try {
        final base64String = imagenUrl.split(',').last;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            base64Decode(base64String),
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return Container(
          height: imageHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFDDBB3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.image, size: 50, color: _primaryColor),
        );
      }
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imagenUrl,
        height: imageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: imageHeight,
          width: double.infinity,
          color: const Color(0xFFFDDBB3),
          child: Icon(Icons.image, size: 50, color: _primaryColor),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _primaryColor,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildPaypalOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor, width: 1.5),
      ),
      child: Row(
        children: [
          // Radio button naranja
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _primaryColor, width: 2),
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Logo PayPal
          Container(
            width: 80,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF013088),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'PayPal',
                style: GoogleFonts.outfit(
                  fontSize: 16,
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(bool isMobile, bool isLargeScreen) {
    final paddingHorizontal = isMobile ? 16.0 : (isLargeScreen ? 48.0 : 24.0);
    final titleFontSize = isMobile ? 24.0 : (isLargeScreen ? 32.0 : 28.0);
    
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(paddingHorizontal),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 500 : (isMobile ? double.infinity : 450),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 32 : 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo PayPal
                Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF013088),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'PayPal',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Ícono de éxito
                Container(
                  width: isMobile ? 80 : 100,
                  height: isMobile ? 80 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryColor,
                  ),
                  child: Icon(
                    Icons.check,
                    size: isMobile ? 40 : 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Transacción Exitosa',
                  style: GoogleFonts.outfit(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _irAMisViajes,
                    child: Text(
                      'Ir a mis viajes',
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                        decoration: TextDecoration.underline,
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
}