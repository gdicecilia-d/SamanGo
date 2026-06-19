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
import 'notifications_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';


class StarRatingWidget extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final double starSize;
  final Color primaryColor;

  const StarRatingWidget({
    super.key,
    required this.initialRating,
    required this.onRatingChanged,
    required this.starSize,
    required this.primaryColor,
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final isSelected = index < _rating;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _rating = index + 1;
              });
              widget.onRatingChanged(_rating);
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                isSelected ? Icons.star : Icons.star_border,
                color: widget.primaryColor,
                size: widget.starSize,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class ServiceCheckboxWidget extends StatefulWidget {
  final String label;
  final bool initialValue;
  final ValueChanged<bool> onChanged;
  final bool isMobile;
  final Color primaryColor;

  const ServiceCheckboxWidget({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    required this.isMobile,
    required this.primaryColor,
  });

  @override
  State<ServiceCheckboxWidget> createState() => _ServiceCheckboxWidgetState();
}

class _ServiceCheckboxWidgetState extends State<ServiceCheckboxWidget> {
  late bool _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.initialValue;
  }

  @override
  void didUpdateWidget(ServiceCheckboxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _isSelected = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.isMobile ? 14.0 : 15.0;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (!_isSelected) {
            setState(() {
              _isSelected = true;
            });
            widget.onChanged(widget.initialValue);
          }
        },
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _isSelected ? widget.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: widget.primaryColor, width: 2),
              ),
              child: _isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: GoogleFonts.outfit(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class CustomTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool isMobile;
  final Color primaryColor;

  const CustomTextArea({
    super.key,
    required this.controller,
    required this.hint,
    required this.maxLines,
    required this.isMobile,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.outfit(fontSize: isMobile ? 14 : 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          fontSize: isMobile ? 14 : 15,
          color: const Color(0xFF999999),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}


// Review
class ReviewView extends StatefulWidget {
  final Reserva reserva;
  final Map<String, dynamic> destinoData;

  const ReviewView(
      {super.key, required this.reserva, required this.destinoData});

  @override
  State<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<ReviewView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _enviando = false;
  bool _yaResenado = false;
  
  // Variables de estado
  int _rating = 0;
  bool _coincidioServicio = true;
  final TextEditingController _comentariosController = TextEditingController();
  final TextEditingController _detalleProblemaController = TextEditingController();

  bool get _isOffer => widget.destinoData['isOffer'] ?? false;
  Color get _primaryColor =>
      _isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);

  @override
  void initState() {
    super.initState();
    _verificarSiYaResenado();
  }

  @override
  void dispose() {
    _comentariosController.dispose();
    _detalleProblemaController.dispose();
    super.dispose();
  }

  Future<void> _verificarSiYaResenado() async {
    try {
      final resenas = await FirebaseFirestore.instance
          .collection('resenas')
          .where('reservaId', isEqualTo: widget.reserva.id)
          .get();
      
      if (mounted) {
        setState(() {
          _yaResenado = resenas.docs.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error verificando reseña: $e');
    }
  }

  void _mostrarMensaje(String mensaje, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : _primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _publicarResena() async {
    // Validaciones
    if (_rating == 0) {
      _mostrarMensaje('Por favor, selecciona una calificacion', isError: true);
      return;
    }

    if (_coincidioServicio == false && _detalleProblemaController.text.trim().isEmpty) {
      _mostrarMensaje('Por favor, detalla que no coincidio con lo prometido', isError: true);
      return;
    }

    setState(() => _enviando = true);

    try {
      final db = FirebaseFirestore.instance;
      
      // Obtener el operadorId del destino
      String operadorId = widget.destinoData['operadorId'] ?? '';
      
      // Si no tiene operadorId, intentar obtenerlo de la coleccion destinos
      if (operadorId.isEmpty) {
        try {
          final destinoDoc = await db
              .collection('destinos')
              .doc(widget.reserva.paqueteId)
              .get();
          if (destinoDoc.exists) {
            operadorId = destinoDoc.data()?['operadorId'] ?? '';
          }
        } catch (e) {
          print('Error obteniendo operadorId: $e');
        }
      }

      final authController = Provider.of<AuthController>(context, listen: false);
      final usuario = authController.usuarioActual;

      // Crear la resena
      final Map<String, dynamic> resenaData = {
        'reservaId': widget.reserva.id,
        'estudianteId': widget.reserva.estudianteId,
        'nombreEstudiante': widget.reserva.nombreEstudiante.isNotEmpty ? widget.reserva.nombreEstudiante : (usuario?.nombre ?? 'Usuario'),
        'apellidoEstudiante': widget.reserva.apellidoEstudiante.isNotEmpty ? widget.reserva.apellidoEstudiante : (usuario?.apellido ?? ''),
        'paqueteId': widget.reserva.paqueteId,
        'operadorId': operadorId,
        'calificacion': _rating,
        'comentarios': _comentariosController.text.trim(),
        'coincidioPrometido': _coincidioServicio,
        'detalleProblema': _coincidioServicio == false ? _detalleProblemaController.text.trim() : null,
        'fechaPublicacion': FieldValue.serverTimestamp(),
      };

      print('Guardando resena: $resenaData');
      
      await db.collection('resenas').add(resenaData);

      // Actualizar la puntuación del paquete 
      await _actualizarCalificacionDestino(widget.reserva.paqueteId);

      // Actualizar calificacion del operador si existe
      if (operadorId.isNotEmpty) {
        await _actualizarCalificacionOperador(operadorId);
      }

      if (mounted) {
        setState(() {
          _yaResenado = true;
        });
        _mostrarMensaje('¡Reseña publicada con exito!');
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error al publicar reseña: $e');
      if (mounted) {
        _mostrarMensaje('Error al publicar la reseña: ${e.toString()}', isError: true);
        setState(() => _enviando = false);
      }
    }
  }

  Future<void> _actualizarCalificacionDestino(String paqueteId) async {
    try {
      final db = FirebaseFirestore.instance;
      
      // Obtener todas las resenas de este paquete
      final resenas = await db
          .collection('resenas')
          .where('paqueteId', isEqualTo: paqueteId)
          .get();

      if (resenas.docs.isEmpty) return;

      // Calcular promedio
      int total = 0;
      for (final doc in resenas.docs) {
        total += (doc['calificacion'] as num?)?.toInt() ?? 0;
      }
      final promedio = total / resenas.docs.length;

      // Actualizar el destino
      await db.collection('destinos').doc(paqueteId).update({
        'calificacionPromedio': double.parse(promedio.toStringAsFixed(1)),
        'totalResenas': resenas.docs.length,
      });
      
      print('Calificacion actualizada para destino $paqueteId: ${promedio.toStringAsFixed(1)}');
    } catch (e) {
      print('Error al actualizar calificacion del destino: $e');
    }
  }

  Future<void> _actualizarCalificacionOperador(String operadorId) async {
    try {
      final db = FirebaseFirestore.instance;

      // Obtener todas las resenas del operador
      final resenas = await db
          .collection('resenas')
          .where('operadorId', isEqualTo: operadorId)
          .get();

      if (resenas.docs.isEmpty) return;

      // Calcular promedio
      int total = 0;
      for (final doc in resenas.docs) {
        total += (doc['calificacion'] as num?)?.toInt() ?? 0;
      }
      final promedio = total / resenas.docs.length;

      // Actualizar en la coleccion de usuarios
      await db.collection('usuarios').doc(operadorId).set({
        'calificacionPromedio': double.parse(promedio.toStringAsFixed(1)),
        'totalResenas': resenas.docs.length,
      }, SetOptions(merge: true));
      
      // Tambien actualizar en operadores si existe
      final operadorDoc = await db.collection('operadores').doc(operadorId).get();
      if (operadorDoc.exists) {
        await db.collection('operadores').doc(operadorId).update({
          'calificacionPromedio': double.parse(promedio.toStringAsFixed(1)),
          'totalResenas': resenas.docs.length,
        });
      }
      
      print('Calificacion actualizada para operador $operadorId: ${promedio.toStringAsFixed(1)}');
    } catch (e) {
      print('Error al actualizar calificacion del operador: $e');
    }
  }

  void _handleMenuSelected(String menu) {
    if (menu == 'Inicio') {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const StudentHomeView()),
          (route) => false);
    } else if (menu == 'Mis Viajes') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MyTripsView()));
    } else if (menu == 'Favoritos') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const FavoritesView()));
    } else if (menu == 'Notificaciones') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const NotificationsView()));
    }
  }

  void _handleEditProfile() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const EditProfileView()));
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
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginView()));
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
    
    // Tamanos responsivos
    double cardWidth;
    double titleFontSize;
    double sectionFontSize;
    double paddingSize;
    double buttonWidth;
    double buttonFontSize;
    double buttonPaddingVertical;
    double starSize;
    
    if (isMobile) {
      cardWidth = double.infinity;
      titleFontSize = 24;
      sectionFontSize = 18;
      paddingSize = 20;
      buttonWidth = double.infinity;
      buttonFontSize = 14;
      buttonPaddingVertical = 12;
      starSize = 36;
    } else if (isLargeScreen) {
      cardWidth = 900.0;
      titleFontSize = 34;
      sectionFontSize = 24;
      paddingSize = 36;
      buttonWidth = 300.0;
      buttonFontSize = 16;
      buttonPaddingVertical = 15;
      starSize = 48;
    } else {
      cardWidth = 750.0;
      titleFontSize = 30;
      sectionFontSize = 22;
      paddingSize = 30;
      buttonWidth = 280.0;
      buttonFontSize = 15;
      buttonPaddingVertical = 14;
      starSize = 44;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer() : null,
      body: Stack(
        children: [
          // Fondo con imagen del destino semitransparente
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
                    child: Container(
                      width: cardWidth,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titulo 
                          Padding(
                            padding: EdgeInsets.all(paddingSize),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cuentanos tu Experiencia',
                                  style: GoogleFonts.outfit(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_yaResenado)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: _primaryColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Ya has reseñado este viaje',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: _primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (!_yaResenado)
                                  Text(
                                    '¡Esperamos que hayas disfrutado tu viaje!',
                                    style: GoogleFonts.outfit(
                                      fontSize: isMobile ? 13 : 15,
                                      color: const Color(0xFF666666),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                          
                          if (_yaResenado)
                            Padding(
                              padding: EdgeInsets.all(paddingSize),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.check_circle, 
                                      size: 64, 
                                      color: _primaryColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Ya has publicado tu reseña para este viaje',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF333333),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Gracias por compartir tu experiencia con la comunidad',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: const Color(0xFF666666),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: _volver,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: Text(
                                        'Volver',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (!_yaResenado)
                            // Formulario
                            Padding(
                              padding: EdgeInsets.all(paddingSize),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Seccion de estrellas
                                  Text(
                                    'Tu calificacion',
                                    style: GoogleFonts.outfit(
                                      fontSize: sectionFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  StarRatingWidget(
                                    initialRating: _rating,
                                    onRatingChanged: (newRating) {
                                      _rating = newRating;
                                    },
                                    starSize: starSize,
                                    primaryColor: _primaryColor,
                                  ),
                                  const SizedBox(height: 24),

                                  // ¿El servicio coincidio con lo prometido?
                                  Text(
                                    '¿El servicio coincidio con lo prometido?',
                                    style: GoogleFonts.outfit(
                                      fontSize: sectionFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      ServiceCheckboxWidget(
                                        label: 'Si',
                                        initialValue: _coincidioServicio == true,
                                        onChanged: (value) {
                                          setState(() {
                                            _coincidioServicio = true;
                                          });
                                        },
                                        isMobile: isMobile,
                                        primaryColor: _primaryColor,
                                      ),
                                      const SizedBox(width: 24),
                                      ServiceCheckboxWidget(
                                        label: 'No',
                                        initialValue: _coincidioServicio == false,
                                        onChanged: (value) {
                                          setState(() {
                                            _coincidioServicio = false;
                                          });
                                        },
                                        isMobile: isMobile,
                                        primaryColor: _primaryColor,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Comentarios libres
                                  Text(
                                    'Comentarios (opcional)',
                                    style: GoogleFonts.outfit(
                                      fontSize: sectionFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  CustomTextArea(
                                    controller: _comentariosController,
                                    hint: '¿Que fue lo que mas te gusto? ¿Algun consejo para otros Unimetanos?',
                                    maxLines: 4,
                                    isMobile: isMobile,
                                    primaryColor: _primaryColor,
                                  ),

                                  // Campo extra para detallar el problema si hubo alguno
                                  if (!_coincidioServicio) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      'Detalla el inconveniente',
                                      style: GoogleFonts.outfit(
                                        fontSize: sectionFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF333333),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    CustomTextArea(
                                      controller: _detalleProblemaController,
                                      hint: 'Por favor, describe que no coincidio...',
                                      maxLines: 3,
                                      isMobile: isMobile,
                                      primaryColor: _primaryColor,
                                    ),
                                  ],

                                  const SizedBox(height: 32),

                                  // Boton publicar
                                  Center(
                                    child: SizedBox(
                                      width: buttonWidth,
                                      child: ElevatedButton(
                                        onPressed: _enviando ? null : _publicarResena,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(vertical: buttonPaddingVertical),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(40),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: _enviando
                                            ? SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white),
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
          // Boton volver flotante
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