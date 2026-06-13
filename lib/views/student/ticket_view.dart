import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import '../../models/reserva.dart';
import '../../controllers/auth_controller.dart';
import '../shared/app_header.dart';
import 'student_home_view.dart';
import 'my_trips_view.dart';
import 'favorites_view.dart';
import 'edit_profile_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';

class TicketView extends StatefulWidget {
  final Reserva reserva;
  final Map<String, dynamic> destinoData;

  const TicketView({super.key, required this.reserva, required this.destinoData});

  @override
  State<TicketView> createState() => _TicketViewState();
}

class _TicketViewState extends State<TicketView> {
  final GlobalKey _ticketKey = GlobalKey();
  bool _isDownloading = false;

  bool get _isOffer => widget.destinoData['isOffer'] ?? false;
  Color get _primaryColor => _isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);
  Color get _primaryLight => _primaryColor.withOpacity(0.1);

  // Generar ID de transacción único basado en la reserva
  String get _transactionId {
    final id = widget.reserva.id;
    if (id.isEmpty) return '#SG-${DateTime.now().year}-${DateTime.now().month}${DateTime.now().day}01';
    final shortId = id.length > 8 ? id.substring(id.length - 8) : id;
    return '#SG-$shortId'.toUpperCase();
  }

  String get _formattedFecha {
    final fecha = widget.reserva.fechaInicio;
    if (fecha == null) return 'Fecha no seleccionada';
    final meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return '${fecha.day} de ${meses[fecha.month - 1]}, ${fecha.year}';
  }

  String get _horaSalida {
    // Hora por defecto, en un sistema real vendría de la BD
    return '06:30 AM';
  }

  String get _puntoEncuentro {
    return 'Universidad Metropolitana';
  }

  Future<void> _descargarTicket() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final RenderRepaintBoundary boundary = _ticketKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/ticket_${widget.reserva.id}.png';
      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'image/png')],
        text: 'Aquí está tu ticket de viaje para ${widget.destinoData['nombre'] ?? 'SamanGo'}',
      );

      _mostrarMensaje('Ticket listo para compartir');
    } catch (e) {
      _mostrarMensaje('Error al generar el ticket');
    } finally {
      setState(() {
        _isDownloading = false;
      });
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isLargeScreen ? 1000 : (isMobile ? double.infinity : 800),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título y botón volver
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ticket de Viaje',
                                      style: GoogleFonts.outfit(
                                        fontSize: isMobile ? 24 : (isLargeScreen ? 32 : 28),
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF333333),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.destinoData['nombre'] ?? 'Destino',
                                      style: GoogleFonts.outfit(
                                        fontSize: isMobile ? 14 : (isLargeScreen ? 18 : 16),
                                        color: const Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _volver,
                                    child: Text(
                                      'Volver',
                                      style: GoogleFonts.outfit(
                                        fontSize: isLargeScreen ? 16 : 14,
                                        color: _primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Ticket (contenido a capturar)
                          RepaintBoundary(
                            key: _ticketKey,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: isMobile
                                  ? _buildMobileTicket(isLargeScreen)
                                  : _buildDesktopTicket(isLargeScreen),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Botón de descarga
                          Center(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: OutlinedButton(
                                onPressed: _isDownloading ? null : _descargarTicket,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: _primaryColor, width: 2),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 32 : 48,
                                    vertical: isMobile ? 12 : 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                ),
                                child: _isDownloading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _primaryColor,
                                        ),
                                      )
                                    : Text(
                                        'Descargar Archivo',
                                        style: GoogleFonts.outfit(
                                          fontSize: isMobile ? 14 : 16,
                                          fontWeight: FontWeight.bold,
                                          color: _primaryColor,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTicket(bool isLargeScreen) {
    final imageWidth = isLargeScreen ? 280.0 : 240.0;
    final imageHeight = isLargeScreen ? 320.0 : 280.0;
    final contentPadding = isLargeScreen ? 28.0 : 20.0;
    final titleFontSize = isLargeScreen ? 20.0 : 18.0;
    const labelFontSize = 13.0;
    const valueFontSize = 15.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen izquierda
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
          child: _buildImageDestino(width: imageWidth, height: imageHeight),
        ),
        // Contenido derecho
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(contentPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ID de transacción
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _transactionId,
                    style: GoogleFonts.outfit(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Nombre:', _getNombreCompleto(), labelFontSize, valueFontSize),
                const SizedBox(height: 12),
                _buildInfoRow('Carnet Unimet:', _getCarnet(), labelFontSize, valueFontSize),
                const SizedBox(height: 12),
                _buildInfoRow('Destino:', _getDestinoCompleto(), labelFontSize, valueFontSize),
                const SizedBox(height: 12),
                _buildInfoRow('Fecha:', _formattedFecha, labelFontSize, valueFontSize),
                const SizedBox(height: 12),
                _buildInfoRow('Hora de Salida:', _horaSalida, labelFontSize, valueFontSize),
                const SizedBox(height: 12),
                _buildInfoRow('Punto de Encuentro:', _puntoEncuentro, labelFontSize, valueFontSize),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTicket(bool isLargeScreen) {
    final imageHeight = 180.0;
    final contentPadding = 20.0;
    final titleFontSize = 18.0;
    const labelFontSize = 13.0;
    const valueFontSize = 15.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: _buildImageDestino(width: double.infinity, height: imageHeight),
        ),
        // Contenido
        Padding(
          padding: EdgeInsets.all(contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ID de transacción
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _transactionId,
                  style: GoogleFonts.outfit(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Nombre:', _getNombreCompleto(), labelFontSize, valueFontSize),
              const SizedBox(height: 12),
              _buildInfoRow('Carnet Unimet:', _getCarnet(), labelFontSize, valueFontSize),
              const SizedBox(height: 12),
              _buildInfoRow('Destino:', _getDestinoCompleto(), labelFontSize, valueFontSize),
              const SizedBox(height: 12),
              _buildInfoRow('Fecha:', _formattedFecha, labelFontSize, valueFontSize),
              const SizedBox(height: 12),
              _buildInfoRow('Hora de Salida:', _horaSalida, labelFontSize, valueFontSize),
              const SizedBox(height: 12),
              _buildInfoRow('Punto de Encuentro:', _puntoEncuentro, labelFontSize, valueFontSize),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, double labelSize, double valueSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: valueSize,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  String _getNombreCompleto() {
    final auth = Provider.of<AuthController>(context, listen: false);
    final usuario = auth.usuarioActual;
    if (usuario != null) {
      return '${usuario.nombre} ${usuario.apellido ?? ''}'.trim();
    }
    return widget.reserva.nombreEstudiante.isNotEmpty 
        ? '${widget.reserva.nombreEstudiante} ${widget.reserva.apellidoEstudiante}'.trim()
        : 'No disponible';
  }

  String _getCarnet() {
    final auth = Provider.of<AuthController>(context, listen: false);
    final usuario = auth.usuarioActual;
    if (usuario != null && usuario.carnet != null && usuario.carnet!.isNotEmpty) {
      return usuario.carnet!;
    }
    return widget.reserva.carnetEstudiante.isNotEmpty 
        ? widget.reserva.carnetEstudiante
        : 'No disponible';
  }

  String _getDestinoCompleto() {
    final nombre = widget.destinoData['nombre'] ?? 'Destino';
    final ubicacion = widget.destinoData['ubicacion'] ?? '';
    if (ubicacion.isNotEmpty && ubicacion != nombre) {
      return '$ubicacion - $nombre';
    }
    return nombre;
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

  Widget _buildImageDestino({required double width, required double height}) {
    final imagenUrl = widget.destinoData['imagen'] ?? '';
    
    if (imagenUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFFDDBB3),
        child: Icon(Icons.image, size: 50, color: _primaryColor),
      );
    }
    
    if (imagenUrl.startsWith('data:image')) {
      try {
        final base64String = imagenUrl.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: const Color(0xFFFDDBB3),
            child: Icon(Icons.image, size: 50, color: _primaryColor),
          ),
        );
      } catch (_) {
        return Container(
          width: width,
          height: height,
          color: const Color(0xFFFDDBB3),
          child: Icon(Icons.image, size: 50, color: _primaryColor),
        );
      }
    }
    
    return Image.network(
      imagenUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFFFDDBB3),
        child: Icon(Icons.image, size: 50, color: _primaryColor),
      ),
    );
  }
}