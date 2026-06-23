import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/reserva_controller.dart';
import '../../models/reserva.dart';
import '../../models/estado_reserva.dart';
import '../shared/app_header.dart';
import 'student_home_view.dart';
import 'favorites_view.dart';
import 'edit_profile_view.dart';
import 'payment_view.dart';
import 'ticket_view.dart';
import 'review_view.dart';
import 'widgets/horizontal_scroll_section.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'notifications_view.dart';
import '../../services/notificacion_service.dart';

const Color rosaVivo = Color(0xFFFF2C97);

class MyTripsView extends StatefulWidget {
  const MyTripsView({super.key});

  @override
  State<MyTripsView> createState() => _MyTripsViewState();
}

class _MyTripsViewState extends State<MyTripsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> _menuItems = ['Inicio', 'Mis Viajes', 'Favoritos'];
  int _refreshKey = 0;

  void _handleMenuSelected(String menu) {
    if (menu == 'Inicio') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomeView()),
        (route) => false,
      );
    } else if (menu == 'Favoritos') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FavoritesView()),
      );
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
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
      }
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFFC6707),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _cancelarReserva(Reserva reserva) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFC6707), size: 45),
            const SizedBox(height: 12),
            Text(
              'Confirmar Cancelación',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¿Estás seguro que deseas cancelar tu solicitud de cupo?',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC6707),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Sí, Cancelar',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDDBB3),
                      foregroundColor: const Color(0xFFFC6707),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: BorderSide.none,
                    ),
                    child: Text(
                      'No, Mantener',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        final destinoDoc = await FirebaseFirestore.instance
            .collection('destinos')
            .doc(reserva.paqueteId)
            .get();
        final destino = destinoDoc.data() as Map<String, dynamic>?;
        final operadorId = destino?['operadorId'];
        final nombrePaquete = destino?['nombre'] ?? 'un destino';

        final estudianteNombre = reserva.nombreEstudiante.isNotEmpty 
            ? reserva.nombreEstudiante 
            : 'Estudiante';
        final estudianteApellido = reserva.apellidoEstudiante.isNotEmpty 
            ? reserva.apellidoEstudiante 
            : '';
        final estudianteCarnet = reserva.carnetEstudiante.isNotEmpty 
            ? reserva.carnetEstudiante 
            : 'No disponible';

        await FirebaseFirestore.instance
            .collection('reservas')
            .doc(reserva.id)
            .delete();

        if (operadorId != null) {
          await NotificacionService().notificarCancelacion(
            operadorId: operadorId,
            estudianteNombre: estudianteNombre,
            estudianteApellido: estudianteApellido,
            estudianteCarnet: estudianteCarnet,
            nombrePaquete: nombrePaquete,
          );
        }

        setState(() {
          _refreshKey++;
        });
        
        _mostrarMensaje('Solicitud cancelada exitosamente');
      } catch (e) {
        _mostrarMensaje('Error al cancelar la solicitud');
      }
    }
  }

  Future<Set<DateTime>> _obtenerDiasDisponibles(String paqueteId) async {
    Set<DateTime> disponibles = {};
    DateTime hoy = DateTime.now();
    for (int i = 1; i <= 30; i++) {
      disponibles.add(hoy.add(Duration(days: i)));
    }
    return disponibles;
  }

  Future<void> _actualizarFechaReserva(Reserva reserva, DateTime nuevaFechaInicio, DateTime nuevaFechaFin) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservas')
          .doc(reserva.id)
          .update({
            'fechaInicio': Timestamp.fromDate(nuevaFechaInicio),
            'fechaFin': Timestamp.fromDate(nuevaFechaFin),
          });
      
      final destinoDoc = await FirebaseFirestore.instance
          .collection('destinos')
          .doc(reserva.paqueteId)
          .get();
      final destino = destinoDoc.data() as Map<String, dynamic>?;
      final operadorId = destino?['operadorId'];
      final usuario = Provider.of<AuthController>(context, listen: false).usuarioActual;
      
      if (operadorId != null && usuario != null) {
        await NotificacionService().notificarCambioFecha(
          operadorId: operadorId,
          estudianteNombre: usuario.nombre,
          estudianteApellido: usuario.apellido ?? '',
          estudianteCarnet: usuario.carnet ?? '',
          nombrePaquete: destino?['nombre'] ?? 'destino',
          nuevaFecha: nuevaFechaInicio,
        );
      }
      
      setState(() {
        _refreshKey++;
      });
      
      _mostrarMensaje('Fecha reprogramada para ${nuevaFechaInicio.day}/${nuevaFechaInicio.month}/${nuevaFechaInicio.year}');
    } catch (e) {
      _mostrarMensaje('Error al reprogramar la fecha');
    }
  }

  // NUEVO DIÁLOGO MODIFICAR FECHA - Estilo igual al de cancelar
  Future<void> _mostrarDialogoModificarFecha(Reserva reserva, Map<String, dynamic> destino, int duracionDias) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 380;
    
    DateTime? fechaInicioSeleccionada = reserva.fechaInicio;
    DateTime? fechaFinSeleccionada = reserva.fechaFin;
    String? errorMensaje;

    final duracionStr = destino['duracion'] ?? 'Full Day';
    final int diasRequeridos = duracionStr == 'Full Day' ? 1 : duracionDias;

    final bloquesDisponibles = _generarBloquesDisponibles(diasRequeridos);

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFFFC6707), size: 40),
                const SizedBox(height: 10),
                Text(
                  'Cambiar fecha',
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 17 : 19,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Selecciona una nueva fecha disponible',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Selector de bloques compacto
                Container(
                  constraints: BoxConstraints(
                    maxHeight: isMobile ? 200 : 240,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildSelectorBloques(
                      bloquesDisponibles,
                      fechaInicioSeleccionada,
                      fechaFinSeleccionada,
                      isMobile,
                      (inicio, fin) {
                        setStateDialog(() {
                          fechaInicioSeleccionada = inicio;
                          fechaFinSeleccionada = fin;
                          errorMensaje = null;
                        });
                      },
                    ),
                  ),
                ),
                
                if (errorMensaje != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMensaje!,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Botones - Mismo estilo que cancelar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (fechaInicioSeleccionada == null) {
                            setStateDialog(() {
                              errorMensaje = 'Selecciona una fecha';
                            });
                            return;
                          }
                          if (diasRequeridos > 1 && fechaFinSeleccionada == null) {
                            setStateDialog(() {
                              errorMensaje = 'Completa el rango de fechas';
                            });
                            return;
                          }
                          Navigator.pop(context);
                          _actualizarFechaReserva(
                            reserva,
                            fechaInicioSeleccionada!,
                            fechaFinSeleccionada ?? fechaInicioSeleccionada!.add(Duration(days: diasRequeridos - 1)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFC6707),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Reprogramar',
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 13 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDDBB3),
                          foregroundColor: const Color(0xFFFC6707),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: BorderSide.none,
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 13 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectorBloques(
    List<Map<String, dynamic>> bloques,
    DateTime? fechaSeleccionada,
    DateTime? fechaFinSeleccionada,
    bool isMobile,
    Function(DateTime, DateTime) onSelected,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: bloques.map((bloque) {
        final inicio = bloque['fechaInicio'] as DateTime;
        final fin = bloque['fechaFin'] as DateTime;
        final label = bloque['label'] as String;
        final dias = bloque['dias'] as int;
        
        final isSeleccionado = fechaSeleccionada != null &&
            fechaFinSeleccionada != null &&
            fechaSeleccionada.year == inicio.year &&
            fechaSeleccionada.month == inicio.month &&
            fechaSeleccionada.day == inicio.day &&
            fechaFinSeleccionada.year == fin.year &&
            fechaFinSeleccionada.month == fin.month &&
            fechaFinSeleccionada.day == fin.day;
        
        return GestureDetector(
          onTap: () => onSelected(inicio, fin),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSeleccionado ? const Color(0xFFFC6707) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSeleccionado ? const Color(0xFFFC6707) : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: isSeleccionado ? Colors.white : const Color(0xFFFC6707),
                      size: isMobile ? 16 : 18,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: isSeleccionado ? Colors.white : const Color(0xFF333333),
                          ),
                        ),
                        Text(
                          '$dias día${dias > 1 ? 's' : ''}',
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 10 : 11,
                            color: isSeleccionado ? Colors.white.withOpacity(0.8) : const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isSeleccionado)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _generarBloquesDisponibles(int diasRequeridos) {
    final bloques = <Map<String, dynamic>>[];
    final hoy = DateTime.now();
    final fechaInicio = hoy.add(const Duration(days: 7));
    
    if (diasRequeridos == 1) {
      int sabadosEncontrados = 0;
      DateTime fecha = fechaInicio;
      while (sabadosEncontrados < 3 && fecha.difference(hoy).inDays <= 60) {
        if (fecha.weekday == 6) {
          bloques.add({
            'fechaInicio': DateTime(fecha.year, fecha.month, fecha.day),
            'fechaFin': DateTime(fecha.year, fecha.month, fecha.day),
            'label': '${fecha.day}/${fecha.month}',
            'dias': 1,
          });
          sabadosEncontrados++;
        }
        fecha = fecha.add(const Duration(days: 1));
      }
    } else {
      int bloquesGenerados = 0;
      DateTime fecha = fechaInicio;
      while (bloquesGenerados < 3 && fecha.difference(hoy).inDays <= 60) {
        List<int> diasSalida;
        if (diasRequeridos == 2) {
          diasSalida = [5, 6];
        } else if (diasRequeridos == 3) {
          diasSalida = [5, 6];
        } else if (diasRequeridos == 4) {
          diasSalida = [4, 5];
        } else {
          diasSalida = [5, 6];
        }
        
        if (diasSalida.contains(fecha.weekday)) {
          final fechaFin = fecha.add(Duration(days: diasRequeridos - 1));
          bloques.add({
            'fechaInicio': DateTime(fecha.year, fecha.month, fecha.day),
            'fechaFin': DateTime(fechaFin.year, fechaFin.month, fechaFin.day),
            'label': '${fecha.day}/${fecha.month} - ${fechaFin.day}/${fechaFin.month}',
            'dias': diasRequeridos,
          });
          bloquesGenerados++;
        }
        fecha = fecha.add(const Duration(days: 1));
      }
    }
    return bloques;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final auth = Provider.of<AuthController>(context);
    final userId = auth.usuarioActual?.id ?? '';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer() : null,
      body: Column(
        children: [
          AppHeader(
            activeMenu: 'Mis Viajes',
            onMenuSelected: _handleMenuSelected,
            onEditProfile: _handleEditProfile,
            onLogout: _handleLogout,
            menuItems: _menuItems,
            isMobile: isMobile,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(
            child: isMobile
                ? _buildMobileLayout(userId)
                : _buildDesktopLayout(userId),
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
                            ? Image.memory(
                                base64Decode(user.fotoBase64!),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
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
                        Text(
                          user?.nombre ?? 'Estudiante',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                        ),
                        Text(
                          user?.apellido ?? '',
                          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF666666)),
                        ),
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
                    }),
                    _buildDrawerItem('Favoritos', Icons.favorite_border, () {
                      Navigator.pop(context);
                      _handleMenuSelected('Favoritos');
                    }),
                    _buildDrawerItem('Notificaciones', Icons.notifications_outlined, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsView()),
                      );
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
    final isActive = title == 'Mis Viajes';
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

  Widget _buildMobileLayout(String userId) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Mis Viajes',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildReservasContent(userId, isMobile: true),
          const SizedBox(height: 40),
          _buildFooter(true),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(String userId) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Mis Viajes',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildReservasContent(userId, isMobile: false),
                  const SizedBox(height: 40),
                  _buildFooter(false),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 320,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildEstadosPanel(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReservasContent(String userId, {required bool isMobile}) {
    final screenWidth = MediaQuery.of(context).size.width;
    double cardWidth;
    double imageHeight;
    
    if (screenWidth < 600) {
      cardWidth = 210;
      imageHeight = 115;
    } else if (screenWidth < 1200) {
      cardWidth = 250;
      imageHeight = 145;
    } else {
      cardWidth = 300;
      imageHeight = 175;
    }

    return StreamBuilder<List<Reserva>>(
      key: ValueKey(_refreshKey),
      stream: Provider.of<ReservaController>(context, listen: false).obtenerMisReservasEstudiante(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFC6707)));
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar tus viajes.'));
        }

        final reservas = snapshot.data ?? [];
        
        final solicitudes = reservas.where((r) => r.estadoActual == EstadoReserva.solicitado).toList();
        final listosParaPagar = reservas.where((r) => r.estadoActual == EstadoReserva.aceptado).toList();
        final proximos = reservas.where((r) => r.estadoActual == EstadoReserva.pagado).toList();
        final disfrutados = reservas.where((r) => r.estadoActual == EstadoReserva.disfrutado).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: Text(
                'Solicitudes Pendientes',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (solicitudes.isEmpty)
              _buildEmptyStateCard(
                'No tienes solicitudes pendientes',
                'Tus solicitudes aparecerán aquí mientras esperan confirmación',
                isMobile,
              )
            else
              HorizontalScrollSection(
                title: '',
                showTitle: false,
                children: solicitudes.map((r) => _buildReservaCard(r, isMobile, cardWidth, imageHeight)).toList(),
              ),
            const SizedBox(height: 32),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: Text(
                'Listos para Pagar',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (listosParaPagar.isEmpty)
              _buildEmptyStateCard(
                'No tienes viajes listos para pagar',
                'Cuando un operador confirme tu solicitud, aparecerá aquí',
                isMobile,
              )
            else
              HorizontalScrollSection(
                title: '',
                showTitle: false,
                children: listosParaPagar.map((r) => _buildReservaCard(r, isMobile, cardWidth, imageHeight)).toList(),
              ),
            const SizedBox(height: 32),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: Text(
                'Próximos Viajes',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (proximos.isEmpty)
              _buildEmptyStateCard(
                'No tienes próximos viajes',
                'Cuando pagues un viaje, aparecerá aquí',
                isMobile,
              )
            else
              HorizontalScrollSection(
                title: '',
                showTitle: false,
                children: proximos.map((r) => _buildReservaCard(r, isMobile, cardWidth, imageHeight)).toList(),
              ),
            const SizedBox(height: 32),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: Text(
                'Viajes Disfrutados',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (disfrutados.isEmpty)
              _buildEmptyStateCard(
                'No has disfrutado viajes aún',
                'Tus experiencias pasadas aparecerán aquí',
                isMobile,
              )
            else
              HorizontalScrollSection(
                title: '',
                showTitle: false,
                children: disfrutados.map((r) => _buildReservaCard(r, isMobile, cardWidth, imageHeight)).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyStateCard(String title, String subtitle, bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: const Color(0xFFCCCCCC)),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFFCCCCCC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservaCard(Reserva reserva, bool isMobile, double cardWidth, double imageHeight) {
    return FutureBuilder<DocumentSnapshot>(
      key: ValueKey('${reserva.id}_${_refreshKey}'),
      future: FirebaseFirestore.instance.collection('destinos').doc(reserva.paqueteId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: cardWidth,
            height: imageHeight + 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        final destino = snapshot.data!.data() as Map<String, dynamic>?;
        if (destino == null) return const SizedBox.shrink();

        final estado = reserva.estadoActual;
        String estadoTexto;
        Color estadoColor;
        
        int duracionDias = 1;
        final duracionStr = destino['duracion'] ?? 'Full Day';
        if (duracionStr != 'Full Day') {
          final match = RegExp(r'(\d+)').firstMatch(duracionStr);
          if (match != null) {
            duracionDias = int.parse(match.group(1)!) + 1;
          }
        }
        
        switch (estado) {
          case EstadoReserva.solicitado:
            estadoTexto = 'Solicitado';
            estadoColor = const Color(0xFFFC6707);
            break;
          case EstadoReserva.aceptado:
            estadoTexto = 'Pagar';
            estadoColor = const Color(0xFF4CAF50);
            break;
          case EstadoReserva.pagado:
            estadoTexto = 'Pagado';
            estadoColor = const Color(0xFF2196F3);
            break;
          case EstadoReserva.disfrutado:
            estadoTexto = 'Disfrutado';
            estadoColor = rosaVivo;
            break;
          default:
            estadoTexto = 'Solicitado';
            estadoColor = const Color(0xFFFC6707);
        }
        
        return Container(
          width: cardWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: _buildImage(
                  destino['imagen'] ?? '',
                  width: cardWidth,
                  height: imageHeight,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destino['nombre'] ?? 'Destino',
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: isMobile ? 12 : 14, color: const Color(0xFF888888)),
                        const SizedBox(width: 4),
                        Text(
                          duracionStr,
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 11 : 12,
                            color: const Color(0xFF888888),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.location_on, size: isMobile ? 12 : 14, color: const Color(0xFF888888)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            destino['ubicacion'] ?? '',
                            style: GoogleFonts.outfit(
                              fontSize: isMobile ? 11 : 12,
                              color: const Color(0xFF888888),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (estado == EstadoReserva.pagado)
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TicketView(
                                      reserva: reserva,
                                      destinoData: destino,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Ver ticket',
                                style: GoogleFonts.outfit(
                                  fontSize: isMobile ? 12 : 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2196F3),
                                ),
                              ),
                            ),
                          ),
                        if (estado != EstadoReserva.pagado) const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: estadoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: (estado == EstadoReserva.aceptado)
                              ? MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PaymentView(
                                            reserva: reserva,
                                            destinoData: destino,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      estadoTexto,
                                      style: GoogleFonts.outfit(
                                        fontSize: isMobile ? 11 : 12,
                                        fontWeight: FontWeight.bold,
                                        color: estadoColor,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  estadoTexto,
                                  style: GoogleFonts.outfit(
                                    fontSize: isMobile ? 11 : 12,
                                    fontWeight: FontWeight.bold,
                                    color: estadoColor,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildBotonAccion(reserva, destino, estado, isMobile, duracionDias),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBotonAccion(Reserva reserva, Map<String, dynamic> destino, EstadoReserva estado, bool isMobile, int duracionDias) {
    if (estado == EstadoReserva.solicitado) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _cancelarReserva(reserva),
          child: Text(
            'Cancelar Solicitud',
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF9C27B0),
            ),
          ),
        ),
      );
    } else if (estado == EstadoReserva.aceptado) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _cancelarReserva(reserva),
          child: Text(
            'Cancelar Solicitud',
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF9C27B0),
            ),
          ),
        ),
      );
    } else if (estado == EstadoReserva.pagado) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _mostrarDialogoModificarFecha(reserva, destino, duracionDias),
          child: Text(
            'Modificar reserva',
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF9C27B0),
            ),
          ),
        ),
      );
    } else if (estado == EstadoReserva.disfrutado) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewView(
                  reserva: reserva,
                  destinoData: destino,
                ),
              ),
            );
          },
          child: Text(
            'Reseña',
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.bold,
              color: rosaVivo,
            ),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildImage(String url, {double width = 300, double height = 175}) {
    if (url.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFFDDBB3),
        child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
      );
    }

    if (url.startsWith('data:image')) {
      try {
        final base64String = url.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: const Color(0xFFFDDBB3),
            child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
          ),
        );
      } catch (_) {
        return Container(
          width: width,
          height: height,
          color: const Color(0xFFFDDBB3),
          child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
        );
      }
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFFFDDBB3),
        child: const Icon(Icons.image, color: Color(0xFFFC6707), size: 40),
      ),
    );
  }

  Widget _buildEstadosPanel() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFFC6707),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Center(
              child: Text(
                'Estados de tu Viaje',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEstadoItem(
                  titulo: 'Solicitado',
                  descripcion: 'Tu solicitud ha sido enviada con éxito.\nEspera la confirmación de disponibilidad del operador.',
                  color: const Color(0xFFFC6707),
                ),
                const Divider(height: 24, thickness: 1, color: Color(0xFFF0F0F0)),
                _buildEstadoItem(
                  titulo: 'Aceptado / Pagar',
                  descripcion: '¡Cupos confirmados!\nRealiza tu pago con PayPal para asegurar tu lugar en la lista.',
                  color: const Color(0xFF4CAF50),
                ),
                const Divider(height: 24, thickness: 1, color: Color(0xFFF0F0F0)),
                _buildEstadoItem(
                  titulo: 'Pagado',
                  descripcion: 'Pago verificado correctamente.\nYa puedes descargar tu ticket o código QR para presentar el día del viaje.',
                  color: const Color(0xFF2196F3),
                ),
                const Divider(height: 24, thickness: 1, color: Color(0xFFF0F0F0)),
                _buildEstadoItem(
                  titulo: 'Disfrutado / Reseña',
                  descripcion: '¡Esperamos que hayas tenido un excelente viaje!\n¡Comparte tu experiencia con la comunidad!',
                  color: rosaVivo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoItem({
    required String titulo,
    required String descripcion,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          descripcion,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: const Color(0xFF666666),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
      margin: const EdgeInsets.only(top: 40),
      decoration: const BoxDecoration(
        color: Color(0xFFFC6707),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Center(
        child: Text(
          '© 2026 SamanGo. Todos los derechos reservados. Comunidad UNIMET.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 10 : 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

