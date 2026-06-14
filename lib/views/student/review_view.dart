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

  const ReviewView(
      {super.key, required this.reserva, required this.destinoData});

  @override
  State<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<ReviewView> {
  int _rating = 0;
  final TextEditingController _comentariosController = TextEditingController();
  bool? _coincidioServicio = true;
  final TextEditingController _detalleProblemaController =
      TextEditingController();
  bool _enviando = false;

  bool get _isOffer => widget.destinoData['isOffer'] ?? false;
  Color get _primaryColor =>
      _isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);
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

  // ── PUNTO 8: PUBLICAR RESEÑA Y ACTUALIZAR CALIFICACIÓN DEL OPERADOR ──────

  Future<void> _publicarResena() async {
    if (_rating == 0) {
      _mostrarMensaje('Por favor, selecciona una calificación');
      return;
    }

    if (_coincidioServicio == false &&
        _detalleProblemaController.text.trim().isEmpty) {
      _mostrarMensaje('Por favor, detalla qué no coincidió con lo prometido');
      return;
    }

    setState(() => _enviando = true);

    try {
      final db = FirebaseFirestore.instance;
      final operadorId = widget.destinoData['operadorId'] ?? '';

      // 1. Guardamos la reseña en la colección "resenas"
      await db.collection('resenas').add({
        'reservaId': widget.reserva.id,
        'estudianteId': widget.reserva.estudianteId,
        'paqueteId': widget.reserva.paqueteId,
        'operadorId': operadorId,
        'calificacion': _rating,
        'comentarios': _comentariosController.text.trim(),
        'coincidioPrometido': _coincidioServicio,
        'detalleProblema': _coincidioServicio == false
            ? _detalleProblemaController.text.trim()
            : null,
        'fechaPublicacion': FieldValue.serverTimestamp(),
      });

      // 2. Recalculamos el promedio leyendo todas las reseñas del operador.
      //    Esto mantiene la calificación siempre exacta aunque se borren reseñas.
      if (operadorId.isNotEmpty) {
        await _actualizarCalificacionOperador(operadorId);
      }

      if (mounted) {
        _mostrarMensaje('¡Reseña publicada con éxito!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensaje('Error al publicar la reseña');
        setState(() => _enviando = false);
      }
    }
  }

  // Lee todas las reseñas del operador y guarda el nuevo promedio en su perfil.
  // Usamos una transacción para que el conteo y promedio sean siempre consistentes.
  Future<void> _actualizarCalificacionOperador(String operadorId) async {
    final db = FirebaseFirestore.instance;

    // Traemos todas las reseñas de este operador
    final resenas = await db
        .collection('resenas')
        .where('operadorId', isEqualTo: operadorId)
        .get();

    if (resenas.docs.isEmpty) return;

    // Calculamos el promedio de todas las calificaciones
    final total = resenas.docs.fold<int>(
        0, (sum, doc) => sum + ((doc['calificacion'] as num?)?.toInt() ?? 0));
    final promedio = total / resenas.docs.length;

    // Guardamos el promedio y la cantidad de reseñas en el documento del operador.
    // Estos campos se usan en las tarjetas de destino para mostrar las estrellas.
    await db.collection('usuarios').doc(operadorId).update({
      'calificacionPromedio': double.parse(promedio.toStringAsFixed(1)),
      'totalResenas': resenas.docs.length,
    });
  }

  // ── NAVEGACIÓN ────────────────────────────────────────────────────────────

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
    }
  }

  void _handleEditProfile() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const EditProfileView()));
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
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginView()));
      }
    });
  }

  void _volver() => Navigator.pop(context);

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final isLargeScreen = screenWidth > 1400;

    // Tamaños responsivos para el botón
    final double buttonPaddingVertical = isMobile ? 14 : (isLargeScreen ? 18 : 16);
    final double buttonFontSize = isMobile ? 14 : (isLargeScreen ? 16 : 15);

    return Scaffold(
      backgroundColor: Colors.white,
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
                onMenuTap: null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24, vertical: 16),
                  child: Column(
                    children: [
                      // Encabezado con título y botón volver
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cuéntanos tu Experiencia',
                                  style: GoogleFonts.outfit(
                                    fontSize: isMobile
                                        ? 22
                                        : (isLargeScreen ? 32 : 28),
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '¡Esperamos que hayas disfrutado tu viaje!',
                                  style: GoogleFonts.outfit(
                                    fontSize: isMobile
                                        ? 13
                                        : (isLargeScreen ? 16 : 14),
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

                      // Tarjeta principal del formulario
                      Container(
                        padding: EdgeInsets.all(isMobile ? 20 : 28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sección de estrellas
                            _buildSectionLabel('Tu calificación'),
                            const SizedBox(height: 12),
                            _buildStarRating(),
                            const SizedBox(height: 24),

                            // ¿El servicio coincidió con lo prometido?
                            _buildSectionLabel(
                                '¿El servicio coincidió con lo prometido?'),
                            const SizedBox(height: 12),
                            _buildCheckboxOptions(),
                            const SizedBox(height: 24),

                            // Comentarios libres
                            _buildSectionLabel('Comentarios (opcional)'),
                            const SizedBox(height: 12),
                            _buildTextArea(
                              controller: _comentariosController,
                              hint:
                                  '¿Qué fue lo que más te gustó? ¿Algún consejo para otros Unimetanos?',
                              maxLines: 4,
                            ),

                            // Campo extra para detallar el problema si hubo alguno
                            if (_coincidioServicio == false) ...[
                              const SizedBox(height: 16),
                              _buildSectionLabel('Detalla el inconveniente'),
                              const SizedBox(height: 12),
                              _buildTextArea(
                                controller: _detalleProblemaController,
                                hint:
                                    'Por favor, describe qué no coincidió...',
                                maxLines: 3,
                              ),
                            ],

                            const SizedBox(height: 28),

                            // Botón publicar
                            Center(
                              child: SizedBox(
                                width: 200,
                                child: ElevatedButton(
                                  onPressed:
                                      _enviando ? null : _publicarResena,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                        vertical: buttonPaddingVertical),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: _enviando
                                      ? const SizedBox(
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
                      const SizedBox(height: 32),
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

  // ── WIDGETS AUXILIARES ────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF333333),
      ),
    );
  }

  Widget _buildTextArea(
      {required TextEditingController controller,
      required String hint,
      int maxLines = 4}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
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
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  // Fila de 5 estrellas interactivas
  Widget _buildStarRating() {
    return Row(
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => setState(() => _rating = index + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              index < _rating ? Icons.star : Icons.star_border,
              color: _primaryColor,
              size: 36,
            ),
          ),
        );
      }),
    );
  }

  // Opciones "Sí / No" para si el servicio cumplió lo prometido
  Widget _buildCheckboxOptions() {
    return Row(
      children: [
        _buildOpcion('Sí', true),
        const SizedBox(width: 24),
        _buildOpcion('No', false),
      ],
    );
  }

  Widget _buildOpcion(String label, bool value) {
    final selected = _coincidioServicio == value;
    return GestureDetector(
      onTap: () => setState(() => _coincidioServicio = value),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: selected ? _primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _primaryColor, width: 2),
            ),
            child: selected
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333)),
          ),
        ],
      ),
    );
  }

  // Imagen de fondo semitransparente del destino (base64 o URL)
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