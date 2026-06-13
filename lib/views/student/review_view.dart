import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/reserva.dart';
import '../../controllers/auth_controller.dart';
import '../shared/app_header.dart';
import 'student_home_view.dart';
import 'my_trips_view.dart';
import 'favorites_view.dart';
import 'edit_profile_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';

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

  bool get _isOffer => widget.destinoData['isOffer'] ?? false;
  Color get _primaryColor => _isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);
  Color get _primaryLight => _primaryColor.withOpacity(0.1);

  @override
  void dispose() {
    _comentariosController.dispose();
    _detalleProblemaController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: _primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _publicarResena() async {
    if (_rating == 0) {
      _mostrarMensaje('Por favor, selecciona una calificación');
      return;
    }

    if (_coincidioServicio == false && _detalleProblemaController.text.trim().isEmpty) {
      _mostrarMensaje('Por favor, detalla qué no coincidió con lo prometido');
      return;
    }

    setState(() {
      _enviando = true;
    });

    try {
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

      if (mounted) {
        _mostrarMensaje('¡Reseña publicada con éxito!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensaje('Error al publicar la reseña');
        setState(() {
          _enviando = false;
        });
      }
    }
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
                  child: Column(
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
                                  'Cuéntanos tu Experiencia',
                                  style: GoogleFonts.outfit(
                                    fontSize: isMobile ? 22 : (isLargeScreen ? 32 : 28),
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '¡Esperamos que hayas disfrutado tu viaje!',
                                  style: GoogleFonts.outfit(
                                    fontSize: isMobile ? 13 : (isLargeScreen ? 16 : 14),
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
                      // Tarjeta principal
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: isLargeScreen ? 900 : (isMobile ? double.infinity : 700),
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
                        child: isMobile
                            ? _buildMobileContent(isLargeScreen)
                            : _buildDesktopContent(isLargeScreen),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent(bool isLargeScreen) {
    final contentPadding = isLargeScreen ? 32.0 : 24.0;
    final titleFontSize = isLargeScreen ? 20.0 : 18.0;
    final labelFontSize = isLargeScreen ? 16.0 : 15.0;
    final buttonPaddingVertical = isLargeScreen ? 16.0 : 14.0;
    final buttonFontSize = isLargeScreen ? 18.0 : 16.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(contentPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna izquierda - Puntuación
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Puntuación General',
                      style: GoogleFonts.outfit(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStarRating(),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Columna derecha - Validación de Servicio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Validación de Servicio',
                      style: GoogleFonts.outfit(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¿El servicio y el costo final coincidieron con lo prometido en la app?',
                      style: GoogleFonts.outfit(
                        fontSize: labelFontSize - 2,
                        color: const Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCheckboxOptions(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0xFFE0E0E0)),
        // Sección Comentarios
        Padding(
          padding: EdgeInsets.all(contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comentarios',
                style: GoogleFonts.outfit(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _comentariosController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '¿Qué fue lo que más te gustó? ¿Algún consejo para otros Unimetanos?',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF999999),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _primaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              if (_coincidioServicio == false) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _detalleProblemaController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Por favor, detalla los inconvenientes para poder ayudarte...',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF999999),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _primaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Botón Publicar (flotante sobre el borde)
        Transform.translate(
          offset: const Offset(0, 20),
          child: SizedBox(
            width: isLargeScreen ? 250 : 200,
            child: ElevatedButton(
              onPressed: _enviando ? null : _publicarResena,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: buttonPaddingVertical),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                elevation: 4,
              ),
              child: _enviando
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Publicar',
                      style: GoogleFonts.outfit(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildMobileContent(bool isLargeScreen) {
    final contentPadding = 20.0;
    final titleFontSize = 18.0;
    final labelFontSize = 15.0;
    final buttonPaddingVertical = 14.0;
    final buttonFontSize = 16.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Puntuación General',
                style: GoogleFonts.outfit(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              _buildStarRating(),
              const SizedBox(height: 24),
              Text(
                'Validación de Servicio',
                style: GoogleFonts.outfit(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¿El servicio y el costo final coincidieron con lo prometido en la app?',
                style: GoogleFonts.outfit(
                  fontSize: labelFontSize - 2,
                  color: const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 12),
              _buildCheckboxOptions(),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0xFFE0E0E0)),
        Padding(
          padding: EdgeInsets.all(contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comentarios',
                style: GoogleFonts.outfit(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _comentariosController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '¿Qué fue lo que más te gustó? ¿Algún consejo para otros Unimetanos?',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF999999),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _primaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              if (_coincidioServicio == false) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _detalleProblemaController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Por favor, detalla los inconvenientes para poder ayudarte...',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF999999),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _primaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Transform.translate(
          offset: const Offset(0, 20),
          child: SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _enviando ? null : _publicarResena,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: buttonPaddingVertical),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                elevation: 4,
              ),
              child: _enviando
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Publicar',
                      style: GoogleFonts.outfit(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = index + 1;
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              index < _rating ? Icons.star : Icons.star_border,
              color: _primaryColor,
              size: 32,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCheckboxOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _coincidioServicio = true;
                });
              },
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _coincidioServicio == true ? _primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _primaryColor, width: 2),
                    ),
                    child: _coincidioServicio == true
                        ? Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sí',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: () {
                setState(() {
                  _coincidioServicio = false;
                });
              },
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _coincidioServicio == false ? _primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _primaryColor, width: 2),
                    ),
                    child: _coincidioServicio == false
                        ? Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_coincidioServicio == false)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Por favor, detalla los inconvenientes en el cuadro de comentarios para poder ayudarte.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF888888),
              ),
            ),
          ),
      ],
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