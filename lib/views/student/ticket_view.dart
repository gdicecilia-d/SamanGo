import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/reserva.dart';
import '../../controllers/auth_controller.dart';
import '../shared/app_header.dart';
import 'student_home_view.dart';
import 'my_trips_view.dart';
import 'favorites_view.dart';
import 'edit_profile_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'notifications_view.dart';

class TicketView extends StatefulWidget {
  final Reserva reserva;
  final Map<String, dynamic> destinoData;

  const TicketView({super.key, required this.reserva, required this.destinoData});

  @override
  State<TicketView> createState() => _TicketViewState();
}

class _TicketViewState extends State<TicketView> {
  final GlobalKey _ticketKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDownloading = false;

  bool get _isOffer => widget.destinoData['isOffer'] ?? false;
  Color get _primaryColor => _isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);

  String get _transactionId {
    final id = widget.reserva.id;
    if (id.isEmpty) return '#SG-${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}01';
    final shortId = id.length > 8 ? id.substring(id.length - 8) : id;
    return '#SG-$shortId'.toUpperCase();
  }

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

  // Obtener datos del destino 
  String get _horaSalida => widget.destinoData['horaSalida'] ?? '06:30 AM';
  String get _puntoEncuentro => widget.destinoData['puntoEncuentro'] ?? 'Universidad Metropolitana';

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
      return '$nombre - $ubicacion';
    }
    return nombre;
  }

  Future<void> _descargarTicket() async {
    setState(() => _isDownloading = true);

    try {
      pw.ImageProvider? destinationImage;
      final String imagenUrl = widget.destinoData['imagen'] ?? '';
      if (imagenUrl.isNotEmpty) {
        try {
          if (imagenUrl.startsWith('data:image')) {
            final base64String = imagenUrl.split(',').last;
            final bytes = base64Decode(base64String);
            destinationImage = pw.MemoryImage(bytes);
          } else {
            destinationImage = await networkImage(imagenUrl);
          }
        } catch (e) {
          print('Error loading image for PDF: $e');
        }
      }

      pw.Font? iconFont;
      try {
        iconFont = await PdfGoogleFonts.materialIcons();
      } catch (e) {
        print('Error loading icon font: $e');
      }

      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            pw.Widget buildInfoRow(String label, String value) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 15),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 140,
                      child: pw.Text(
                        label,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                          color: const PdfColor.fromInt(0xFFE65C00),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        value,
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: const PdfColor.fromInt(0xFF333333),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  widget.destinoData['nombre'] ?? 'SamanGo',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 32,
                    color: const PdfColor.fromInt(0xFF333333),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    if (iconFont != null) ...[
                      pw.Icon(const pw.IconData(0xe192), font: iconFont, color: const PdfColor.fromInt(0xFF888888), size: 14),
                      pw.SizedBox(width: 4),
                    ],
                    pw.Text(
                      'Full Day',
                      style: pw.TextStyle(fontSize: 12, color: const PdfColor.fromInt(0xFF888888)),
                    ),
                    pw.SizedBox(width: 20),
                    if (iconFont != null) ...[
                      pw.Icon(const pw.IconData(0xe0c8), font: iconFont, color: const PdfColor.fromInt(0xFF888888), size: 14),
                      pw.SizedBox(width: 4),
                    ],
                    pw.Text(
                      widget.destinoData['ubicacion'] ?? 'No disponible',
                      style: pw.TextStyle(fontSize: 12, color: const PdfColor.fromInt(0xFF888888)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(color: const PdfColor.fromInt(0xFFE0E0E0)),
                pw.SizedBox(height: 30),
                
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (destinationImage != null)
                      pw.Container(
                        width: 250,
                        height: 300,
                        decoration: pw.BoxDecoration(
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
                          image: pw.DecorationImage(
                            image: destinationImage!,
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      pw.Container(
                        width: 250,
                        height: 300,
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFEEEEEE),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
                        ),
                        child: pw.Center(
                          child: pw.Text('Sin imagen', style: pw.TextStyle(color: const PdfColor.fromInt(0xFF888888))),
                        ),
                      ),
                      
                    pw.SizedBox(width: 40),
                    
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          buildInfoRow('N° Transacción:', _transactionId.isEmpty ? 'N/A' : _transactionId),
                          buildInfoRow('Pasajero:', _getNombreCompleto()),
                          buildInfoRow('Carnet:', _getCarnet()),
                          buildInfoRow('Fecha:', _formattedFecha),
                          buildInfoRow('Hora salida:', _horaSalida),
                          buildInfoRow('Punto encuentro:', _puntoEncuentro),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final String fileName = 'ticket_${widget.reserva.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (kIsWeb) {
        await Share.shareXFiles(
          [XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName)],
          text: '🎫 Ticket de viaje - ${widget.destinoData['nombre'] ?? 'SamanGo'}',
        );
      } else {
        final directory = await getTemporaryDirectory();
        final String filePath = '${directory.path}/$fileName';
        final File file = File(filePath);
        await file.writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(filePath, mimeType: 'application/pdf')],
          text: '🎫 Ticket de viaje - ${widget.destinoData['nombre'] ?? 'SamanGo'}',
        );
      }

      _mostrarMensaje('Ticket descargado exitosamente');
    } catch (e) {
      print('Error al generar ticket: $e');
      _mostrarMensaje('Error al generar el ticket en PDF');
    } finally {
      setState(() => _isDownloading = false);
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
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTripsView()));
    } else if (menu == 'Favoritos') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesView()));
    } else if (menu == 'Notificaciones') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsView()));
    }
  }

  void _handleEditProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileView()));
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
      }
    });
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();
  void _volver() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final isLargeScreen = screenWidth > 1400;
    final double backButtonTop = isMobile ? 80 : 100;
    final double backButtonSize = isLargeScreen ? 20 : 16;
    
    double cardWidth;
    double imageWidth;
    double imageHeight;
    double titleFontSize;
    double infoFontSize;
    double paddingSize;
    
    if (isMobile) {
      cardWidth = double.infinity;
      imageWidth = double.infinity;
      imageHeight = 200;
      titleFontSize = 24;
      infoFontSize = 13;
      paddingSize = 20;
    } else if (isLargeScreen) {
      cardWidth = 1100.0;
      imageWidth = 280;
      imageHeight = 350;
      titleFontSize = 36;
      infoFontSize = 16;
      paddingSize = 32;
    } else {
      cardWidth = 900.0;
      imageWidth = 220;
      imageHeight = 280;
      titleFontSize = 32;
      infoFontSize = 15;
      paddingSize = 28;
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
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 40,
                      vertical: isMobile ? 16 : 24,
                    ),
                    child: RepaintBoundary(
                      key: _ticketKey,
                      child: Container(
                        width: cardWidth,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
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
                                    widget.destinoData['nombre'] ?? 'Destino',
                                    style: GoogleFonts.outfit(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 8 : 12),
                                  Wrap(
                                    spacing: 20,
                                    runSpacing: 8,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.access_time, size: isMobile ? 14 : 18, color: const Color(0xFF888888)),
                                          const SizedBox(width: 6),
                                          Text(
                                            widget.destinoData['duracion'] ?? 'Full Day',
                                            style: GoogleFonts.outfit(
                                              fontSize: isMobile ? 13 : 15,
                                              color: const Color(0xFF888888),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.location_on, size: isMobile ? 14 : 18, color: const Color(0xFF888888)),
                                          const SizedBox(width: 6),
                                          Text(
                                            widget.destinoData['ubicacion'] ?? '',
                                            style: GoogleFonts.outfit(
                                              fontSize: isMobile ? 13 : 15,
                                              color: const Color(0xFF888888),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            Divider(height: 1, thickness: 1, color: const Color(0xFFE0E0E0)),
                            
                            Padding(
                              padding: EdgeInsets.all(paddingSize),
                              child: isMobile
                                  ? Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: _buildImageDestino(
                                            width: imageWidth,
                                            height: imageHeight,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        _buildInfoRow('N° Transacción:', _transactionId, isMobile, infoFontSize),
                                        const SizedBox(height: 14),
                                        _buildInfoRow('Pasajero:', _getNombreCompleto(), isMobile, infoFontSize),
                                        const SizedBox(height: 14),
                                        _buildInfoRow('Carnet:', _getCarnet(), isMobile, infoFontSize),
                                        const SizedBox(height: 14),
                                        _buildInfoRow('Fecha:', _formattedFecha, isMobile, infoFontSize),
                                        const SizedBox(height: 14),
                                        _buildInfoRow('Hora salida:', _horaSalida, isMobile, infoFontSize),
                                        const SizedBox(height: 14),
                                        _buildInfoRow('Punto encuentro:', _puntoEncuentro, isMobile, infoFontSize),
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: _buildImageDestino(
                                            width: imageWidth,
                                            height: imageHeight,
                                          ),
                                        ),
                                        const SizedBox(width: 32),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildInfoRow('N° Transacción:', _transactionId, isMobile, infoFontSize),
                                              const SizedBox(height: 16),
                                              _buildInfoRow('Pasajero:', _getNombreCompleto(), isMobile, infoFontSize),
                                              const SizedBox(height: 16),
                                              _buildInfoRow('Carnet:', _getCarnet(), isMobile, infoFontSize),
                                              const SizedBox(height: 16),
                                              _buildInfoRow('Fecha:', _formattedFecha, isMobile, infoFontSize),
                                              const SizedBox(height: 16),
                                              _buildInfoRow('Hora salida:', _horaSalida, isMobile, infoFontSize),
                                              const SizedBox(height: 16),
                                              _buildInfoRow('Punto encuentro:', _puntoEncuentro, isMobile, infoFontSize),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            
                            Divider(height: 1, thickness: 1, color: const Color(0xFFE0E0E0)),
                            
                            Padding(
                              padding: EdgeInsets.all(paddingSize),
                              child: Column(
                                children: [
                                  Center(
                                    child: Text(
                                      'Presenta este ticket el día del viaje',
                                      style: GoogleFonts.outfit(
                                        fontSize: isMobile ? 11 : 13,
                                        color: const Color(0xFF888888),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 20 : 24),
                                  Center(
                                    child: SizedBox(
                                      width: isMobile ? (screenWidth < 380 ? double.infinity : 240) : 280,
                                      child: OutlinedButton.icon(
                                        onPressed: _isDownloading ? null : _descargarTicket,
                                        icon: _isDownloading
                                            ? SizedBox(
                                                width: isMobile ? 18 : 22,
                                                height: isMobile ? 18 : 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: _primaryColor,
                                                ),
                                              )
                                            : Icon(Icons.download, size: isMobile ? 18 : 22, color: _primaryColor),
                                        label: Text(
                                          _isDownloading ? 'Generando...' : 'Descargar Archivo',
                                          style: GoogleFonts.outfit(
                                            fontSize: isMobile ? 13 : 15,
                                            fontWeight: FontWeight.w600,
                                            color: _primaryColor,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: _primaryColor, width: 1.5),
                                          padding: EdgeInsets.symmetric(
                                            vertical: isMobile ? 12 : 14,
                                            horizontal: isMobile ? 20 : 24,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(40),
                                          ),
                                        ),
                                      ),
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
              ),
            ],
          ),
          Positioned(
            top: backButtonTop,
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
                      Icon(Icons.arrow_back, color: _primaryColor, size: backButtonSize),
                      const SizedBox(width: 4),
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
                _buildDrawerItem('Cerrar Sesión', Icons.logout_outlined, () {
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
    final isActive = title == 'Notificaciones';
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFC6707)),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? const Color(0xFFFC6707) : const Color(0xFF333333),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow(String label, String value, bool isMobile, double fontSize) {
    final labelWidth = isMobile ? 110.0 : 140.0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageDestino({required double width, required double height}) {
    final imagenUrl = widget.destinoData['imagen'] ?? '';
    
    if (imagenUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFFDDBB3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.image, size: width * 0.25, color: _primaryColor),
      );
    }
    
    if (imagenUrl.startsWith('data:image')) {
      try {
        final base64String = imagenUrl.split(',').last;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            base64Decode(base64String),
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: width,
              height: height,
              color: const Color(0xFFFDDBB3),
              child: Icon(Icons.image, size: width * 0.25, color: _primaryColor),
            ),
          ),
        );
      } catch (_) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFFDDBB3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.image, size: width * 0.25, color: _primaryColor),
        );
      }
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        imagenUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF5F5F5),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _primaryColor,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: const Color(0xFFFDDBB3),
          child: Icon(Icons.image, size: width * 0.25, color: _primaryColor),
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