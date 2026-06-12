import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../controllers/reserva_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/reserva.dart';
import '../../models/estado_reserva.dart';
import '../shared/app_header.dart';
import 'student_home_view.dart';
import 'my_trips_view.dart';
import 'favorites_view.dart';
import 'edit_profile_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';

class CheckoutView extends StatefulWidget {
  final String destinoId;
  final Map<String, dynamic> destinoData;

  const CheckoutView({
    super.key,
    required this.destinoId,
    required this.destinoData,
  });

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  int _numeroPersonas = 1;
  final List<String> _extrasSeleccionados = [];
  final List<Map<String, String>> _acompanantes = [];
  
  DateTime _fechaPublicacion = DateTime.now();
  List<DateTime> _fechasDisponibles = [];
  
  late ImageProvider? _backgroundImage;
  late ImageProvider? _paqueteImagen;

  final List<Map<String, dynamic>> _extrasDisponibles = [
    {'nombre': 'Full Day Cayo de Agua', 'precio': 45.0},
    {'nombre': 'Kit de Snorkeling Profesional', 'precio': 15.0},
    {'nombre': 'Seguro de Viaje Básico', 'precio': 10.0},
    {'nombre': 'Transporte VIP al Puerto', 'precio': 20.0},
  ];

  bool get _isOffer => widget.destinoData['isOffer'] ?? false;
  Color get _primaryColor => _isOffer ? const Color(0xFF9C27B0) : const Color(0xFFFC6707);
  Color get _primaryLight => _isOffer ? const Color(0xFF9C27B0).withOpacity(0.1) : const Color(0xFFFC6707).withOpacity(0.1);

  @override
  void initState() {
    super.initState();
    _inicializarFechas();
    _cargarImagenes();
    _actualizarAcompanantes();
  }

  void _inicializarFechas() {
    if (widget.destinoData['fechaPublicacion'] != null) {
      _fechaPublicacion = DateTime.parse(widget.destinoData['fechaPublicacion']);
    }
    
    _fechasDisponibles = [];
    for (int i = 0; i < 30; i++) {
      _fechasDisponibles.add(_fechaPublicacion.add(Duration(days: i + 1)));
    }
  }

  void _cargarImagenes() {
    final imagenPortada = widget.destinoData['imagen'] ?? '';
    if (imagenPortada.isNotEmpty) {
      if (imagenPortada.startsWith('data:image')) {
        try {
          final base64String = imagenPortada.split(',').last;
          _backgroundImage = MemoryImage(base64Decode(base64String));
        } catch (_) {
          _backgroundImage = null;
        }
      } else {
        _backgroundImage = NetworkImage(imagenPortada);
      }
    }
    
    final imagenesReferencia = widget.destinoData['imagenesReferencia'] ?? [];
    if (imagenesReferencia.isNotEmpty && imagenesReferencia[0].isNotEmpty) {
      final img = imagenesReferencia[0];
      if (img.startsWith('data:image')) {
        try {
          final base64String = img.split(',').last;
          _paqueteImagen = MemoryImage(base64Decode(base64String));
        } catch (_) {
          _paqueteImagen = null;
        }
      } else {
        _paqueteImagen = NetworkImage(img);
      }
    } else if (imagenPortada.isNotEmpty) {
      if (imagenPortada.startsWith('data:image')) {
        try {
          final base64String = imagenPortada.split(',').last;
          _paqueteImagen = MemoryImage(base64Decode(base64String));
        } catch (_) {
          _paqueteImagen = null;
        }
      } else {
        _paqueteImagen = NetworkImage(imagenPortada);
      }
    }
  }

  void _actualizarAcompanantes() {
    final cantidadNecesaria = _numeroPersonas - 1;
    while (_acompanantes.length < cantidadNecesaria) {
      _acompanantes.add({'nombre': '', 'carnet': ''});
    }
    while (_acompanantes.length > cantidadNecesaria) {
      _acompanantes.removeLast();
    }
  }

  bool get _acompanantesValidos {
    if (_numeroPersonas <= 1) return true;
    for (var a in _acompanantes) {
      if (a['nombre']?.trim().isEmpty ?? true) return false;
      if (a['carnet']?.trim().isEmpty ?? true) return false;
    }
    return true;
  }

  bool _esFechaDisponible(DateTime date) {
    return _fechasDisponibles.any((fecha) => 
      fecha.year == date.year && fecha.month == date.month && fecha.day == date.day);
  }

  int get _maxDiasSeleccionables {
    final duracion = widget.destinoData['duracion'] ?? 'Full Day';
    if (duracion == 'Full Day') return 1;
    final match = RegExp(r'(\d+)').firstMatch(duracion);
    if (match != null) {
      final noches = int.parse(match.group(1)!);
      return noches + 1;
    }
    return 1;
  }

  bool _esFullDay() {
    final duracion = widget.destinoData['duracion'] ?? 'Full Day';
    return duracion == 'Full Day' || !duracion.contains('noches');
  }

  void _seleccionarFecha(DateTime fecha) {
    setState(() {
      if (_esFullDay()) {
        _fechaInicio = fecha;
        _fechaFin = fecha;
      } else {
        if (_fechaInicio == null || (_fechaFin != null && _fechaInicio != null)) {
          _fechaInicio = fecha;
          _fechaFin = null;
        } else if (_fechaInicio != null && _fechaFin == null) {
          if (fecha.isAfter(_fechaInicio!)) {
            final diasRango = fecha.difference(_fechaInicio!).inDays + 1;
            if (diasRango <= _maxDiasSeleccionables) {
              _fechaFin = fecha;
            } else {
              _fechaInicio = fecha;
              _fechaFin = null;
            }
          } else {
            _fechaInicio = fecha;
            _fechaFin = null;
          }
        }
      }
    });
  }

  bool _isFechaSeleccionada(DateTime fecha) {
    if (_esFullDay()) {
      return _fechaInicio != null && 
             _fechaInicio!.day == fecha.day &&
             _fechaInicio!.month == fecha.month;
    } else {
      if (_fechaInicio == null) return false;
      if (_fechaFin == null) {
        return _fechaInicio!.day == fecha.day && _fechaInicio!.month == fecha.month;
      }
      return fecha.isAfter(_fechaInicio!.subtract(const Duration(days: 1))) &&
             fecha.isBefore(_fechaFin!.add(const Duration(days: 1)));
    }
  }

  bool _isFechaEnRango(DateTime fecha) {
    if (_esFullDay()) return false;
    if (_fechaInicio == null || _fechaFin == null) return false;
    return fecha.isAfter(_fechaInicio!) && fecha.isBefore(_fechaFin!);
  }

  double get _subtotal {
    final precioPersona = (widget.destinoData['precio'] ?? 0.0).toDouble();
    return precioPersona * _numeroPersonas;
  }

  double get _costoExtras {
    double costo = 0;
    for (final extraNombre in _extrasSeleccionados) {
      final extraInfo = _extrasDisponibles.firstWhere((e) => e['nombre'] == extraNombre);
      costo += (extraInfo['precio'] as double) * _numeroPersonas;
    }
    return costo;
  }

  double get _totalGeneral => _subtotal + _costoExtras;

  String get _textoPersonas {
    if (_numeroPersonas == 1) return 'Tú';
    if (_numeroPersonas == 2) return 'Tú + 1 amigo';
    return 'Tú + ${_numeroPersonas - 1} amigos';
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: _primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _enviarSolicitud() async {
    if (_fechaInicio == null) {
      _mostrarMensaje('Selecciona una fecha para tu viaje');
      return;
    }
    if (_numeroPersonas > 1 && !_acompanantesValidos) {
      _mostrarMensaje('Completa los datos de tus acompañantes');
      return;
    }

    final auth = Provider.of<AuthController>(context, listen: false);
    final reservaCtrl = Provider.of<ReservaController>(context, listen: false);
    final userId = auth.usuarioActual?.id;

    if (userId == null) return;

    final fechaFinCalculada = _fechaFin ?? _fechaInicio!;
    final fechaFinReal = fechaFinCalculada.add(const Duration(days: 1));

    final acompanantesFinales = _acompanantes.map((a) => {
      'nombre': a['nombre'],
      'carnet': a['carnet'],
    }).toList();

    final nuevaReserva = Reserva(
      id: '',
      estudianteId: userId,
      paqueteId: widget.destinoId,
      estadoActual: EstadoReserva.solicitado,
      fechaInicio: _fechaInicio,
      fechaFin: fechaFinReal,
      numeroPersonas: _numeroPersonas,
      datosAcompanantes: acompanantesFinales,
      extrasSeleccionados: _extrasSeleccionados,
      subtotal: _subtotal,
      totalGeneral: _totalGeneral,
    );

    final exito = await reservaCtrl.crearReserva(nuevaReserva);

    if (exito && mounted) {
      _mostrarMensaje('¡Solicitud enviada con éxito!');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomeView()),
        (route) => false,
      );
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final isLargeScreen = screenWidth > 1400;
    
    final double titleFontSize = isMobile ? 24 : (isLargeScreen ? 36 : 28);
    final double paddingHorizontal = isMobile ? 16 : (isLargeScreen ? 48 : 32);
    final double cardPadding = isMobile ? 16 : (isLargeScreen ? 28 : 24);
    final double sectionFontSize = isMobile ? 16 : (isLargeScreen ? 20 : 18);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: _backgroundImage != null
                  ? DecorationImage(
                      image: _backgroundImage!,
                      fit: BoxFit.cover,
                      opacity: 0.3,
                    )
                  : null,
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
                child: isMobile
                    ? _buildMobileLayout(titleFontSize, cardPadding, sectionFontSize)
                    : _buildDesktopLayout(titleFontSize, cardPadding, sectionFontSize, paddingHorizontal),
              ),
            ],
          ),
          Positioned(
            top: 80,
            right: 24,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
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
                      Icon(Icons.arrow_back, color: _primaryColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Volver',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
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

  Widget _buildMobileLayout(double titleFontSize, double cardPadding, double sectionFontSize) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildContentCard(titleFontSize, cardPadding, sectionFontSize),
          const SizedBox(height: 16),
          _buildResumenCard(cardPadding),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(double titleFontSize, double cardPadding, double sectionFontSize, double paddingHorizontal) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(paddingHorizontal),
            child: _buildContentCard(titleFontSize, cardPadding, sectionFontSize),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsets.only(top: paddingHorizontal, right: paddingHorizontal, bottom: paddingHorizontal),
            child: _buildResumenCard(cardPadding),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(double titleFontSize, double cardPadding, double sectionFontSize) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título, duración y ubicación
          Padding(
            padding: EdgeInsets.all(cardPadding),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: const Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Text(
                      widget.destinoData['duracion'] ?? 'Full Day',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 16, color: const Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.destinoData['ubicacion'] ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF888888),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 24),
          
          // FILA 1: ¿Cuándo viajas? (izquierda) + Personaliza tu experiencia (derecha)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cuándo viajas? 📅',
                        style: GoogleFonts.outfit(
                          fontSize: sectionFontSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCalendario(),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personaliza tu experiencia 🎁',
                        style: GoogleFonts.outfit(
                          fontSize: sectionFontSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._extrasDisponibles.map((extra) => _buildExtraCheckbox(extra)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // FILA 2: ¿Quiénes van? (izquierda) + Foto (derecha)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ¿Quiénes van? (izquierda)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Quiénes van? 👥',
                        style: GoogleFonts.outfit(
                          fontSize: sectionFontSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reserva para ti y tus amigos.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF888888),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSelectorPersonas(),
                      if (_numeroPersonas > 1) ...[
                        const SizedBox(height: 20),
                        ..._buildFormularioAcompanantes(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Foto del paquete (derecha)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _paqueteImagen != null
                        ? Image(
                            image: _paqueteImagen!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 200,
                            color: const Color(0xFFFDDBB3),
                            child: Icon(Icons.image, size: 50, color: _primaryColor),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCalendario() {
    final now = DateTime.now();
    final monthNames = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: _primaryColor, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Icon(Icons.chevron_left, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 20),
                Text(
                  '${monthNames[now.month - 1]} ${now.year}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {},
                  child: Icon(Icons.chevron_right, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['D', 'L', 'M', 'M', 'J', 'V', 'S'].map((dia) {
                    return Expanded(
                      child: Text(
                        dia,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.8,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: 35,
                  itemBuilder: (context, index) {
                    final firstDayOfMonth = DateTime(now.year, now.month, 1);
                    final firstWeekday = firstDayOfMonth.weekday;
                    int startOffset = firstWeekday == 7 ? 0 : firstWeekday;
                    
                    final dayNumber = index - startOffset + 1;
                    
                    if (dayNumber < 1 || dayNumber > DateTime(now.year, now.month + 1, 0).day) {
                      return Container();
                    }
                    
                    final fecha = DateTime(now.year, now.month, dayNumber);
                    final esDisponible = _esFechaDisponible(fecha);
                    final esSeleccionada = _isFechaSeleccionada(fecha);
                    final esEnRango = _isFechaEnRango(fecha);
                    
                    Color? bgColor;
                    Color textColor = const Color(0xFF333333);
                    
                    if (esSeleccionada) {
                      bgColor = _primaryColor;
                      textColor = Colors.white;
                    } else if (esEnRango) {
                      bgColor = _primaryColor.withOpacity(0.2);
                    } else if (esDisponible) {
                      bgColor = const Color(0xFFE8F5E9);
                      textColor = const Color(0xFF2E7D32);
                    } else {
                      textColor = const Color(0xFFCCCCCC);
                    }
                    
                    return GestureDetector(
                      onTap: esDisponible ? () => _seleccionarFecha(fecha) : null,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  _esFullDay() 
                      ? 'Selecciona tu día de viaje.\nLas fechas en verde están disponibles.'
                      : 'Selecciona tu rango de viaje (máximo $_maxDiasSeleccionables días).\nLas fechas en verde están disponibles.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorPersonas() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        border: Border.all(color: _primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _numeroPersonas > 1 ? () {
                setState(() {
                  _numeroPersonas--;
                  _actualizarAcompanantes();
                });
              } : null,
              icon: const Icon(Icons.remove, color: Color(0xFF666666), size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          Text(
            _textoPersonas,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF333333),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _numeroPersonas < 6 ? () {
                setState(() {
                  _numeroPersonas++;
                  _actualizarAcompanantes();
                });
              } : null,
              icon: const Icon(Icons.add, color: Color(0xFF666666), size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormularioAcompanantes() {
    final widgets = <Widget>[];
    for (int i = 0; i < _acompanantes.length; i++) {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDDBB3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Acompañante',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Nombre completo',
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: _primaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (value) {
                  setState(() {
                    _acompanantes[i]['nombre'] = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Cédula / Carnet',
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: _primaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (value) {
                  setState(() {
                    _acompanantes[i]['carnet'] = value;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildExtraCheckbox(Map<String, dynamic> extra) {
    final isSelected = _extrasSeleccionados.contains(extra['nombre']);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _extrasSeleccionados.remove(extra['nombre']);
          } else {
            _extrasSeleccionados.add(extra['nombre']);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isSelected ? _primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _primaryColor, width: 1.5),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    extra['nombre'],
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  Text(
                    '+\$${extra['precio']} por persona',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCard(double cardPadding) {
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Resumen de tu Reserva',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 12),
          _buildResumenRow('Paquete:', widget.destinoData['nombre'] ?? 'Destino'),
          const SizedBox(height: 8),
          _buildResumenRow('Fecha:', _getRangoFechasTexto()),
          const SizedBox(height: 8),
          _buildResumenRow('Personas:', '$_numeroPersonas (${_textoPersonas})'),
          const SizedBox(height: 16),
          _buildResumenRow('Subtotal (x$_numeroPersonas):', '\$${_subtotal.toStringAsFixed(2)}', bold: true),
          if (_extrasSeleccionados.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._extrasSeleccionados.map((extra) {
              final precioExtra = _extrasDisponibles.firstWhere((e) => e['nombre'] == extra)['precio'] * _numeroPersonas;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildResumenRow('  - $extra:', '+\$${precioExtra.toStringAsFixed(2)}', isExtra: true),
              );
            }),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 12),
          _buildResumenRow('Total General:', '\$${_totalGeneral.toStringAsFixed(2)}', bold: true, isTotal: true),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Al hacer clic, creará una solicitud para que el operador verifique cupos. Podrás pagar una vez sea confirmada.',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enviarSolicitud,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Solicitar',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRangoFechasTexto() {
    if (_fechaInicio == null) return 'No seleccionado';
    if (_fechaFin == null || _fechaInicio == _fechaFin) {
      return '${_fechaInicio!.day} de ${_getMes(_fechaInicio!.month)}';
    }
    return '${_fechaInicio!.day} - ${_fechaFin!.day} de ${_getMes(_fechaInicio!.month)} ${_fechaInicio!.year}';
  }

  String _getMes(int month) {
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return meses[month - 1];
  }

  Widget _buildResumenRow(String label, String value, {bool bold = false, bool isTotal = false, bool isExtra = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: isTotal ? 16 : (isExtra ? 12 : 13),
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: isExtra ? const Color(0xFF888888) : const Color(0xFF333333),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: isTotal ? 18 : (isExtra ? 12 : 13),
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? _primaryColor : const Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}