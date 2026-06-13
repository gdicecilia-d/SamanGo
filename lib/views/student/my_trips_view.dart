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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
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

  Future<void> _mostrarDialogoModificarFecha(Reserva reserva, Map<String, dynamic> destino, int duracionDias) async {
    DateTime? fechaInicioSeleccionada = reserva.fechaInicio;
    String? errorMensaje;
    
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFFFC6707), size: 45),
                const SizedBox(height: 12),
                Text(
                  'Cambio de fecha de viaje',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Este cupo ya ha sido pagado. Recuerda que no se realizan reembolsos de dinero, pero puedes modificar la fecha de tu viaje sin costo adicional.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 300,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: _buildCalendarioSelector(
                    fechaInicioSeleccionada,
                    duracionDias,
                    (fechaInicio) {
                      setStateDialog(() {
                        fechaInicioSeleccionada = fechaInicio;
                        errorMensaje = null;
                      });
                    },
                  ),
                ),
                if (errorMensaje != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorMensaje!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (fechaInicioSeleccionada == null) {
                            setStateDialog(() {
                              errorMensaje = 'Debes seleccionar una fecha de inicio';
                            });
                            return;
                          }
                          final fechaInicio = fechaInicioSeleccionada!;
                          final fechaFin = fechaInicio.add(Duration(days: duracionDias - 1));
                          final ultimoDiaMes = DateTime(fechaInicio.year, fechaInicio.month + 1, 0);
                          if (fechaFin.isAfter(ultimoDiaMes)) {
                            setStateDialog(() {
                              errorMensaje = 'La fecha seleccionada no permite el viaje completo de $duracionDias días. Elige una fecha más temprana.';
                            });
                            return;
                          }
                          Navigator.pop(context);
                          _actualizarFechaReserva(reserva, fechaInicio, fechaFin);
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
                          'Reprogramar fecha',
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
          );
        },
      ),
    );
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
      
      _mostrarMensaje('Fecha reprogramada para ${nuevaFechaInicio.day}/${nuevaFechaInicio.month}/${nuevaFechaInicio.year} - ${nuevaFechaFin.day}/${nuevaFechaFin.month}/${nuevaFechaFin.year}');
    } catch (e) {
      _mostrarMensaje('Error al reprogramar la fecha');
    }
  }

  Widget _buildCalendarioSelector(
    DateTime? fechaInicioSeleccionada, 
    int duracionDias,
    Function(DateTime) onFechaSeleccionada
  ) {
    DateTime _mesActual = DateTime.now();
    
    return StatefulBuilder(
      builder: (context, setStateCal) {
        final monthNames = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
        
        final firstDayOfMonth = DateTime(_mesActual.year, _mesActual.month, 1);
        final daysInMonth = DateTime(_mesActual.year, _mesActual.month + 1, 0).day;
        final firstWeekday = firstDayOfMonth.weekday;
        int startOffset = firstWeekday == 7 ? 0 : firstWeekday;
        
        void cambiarMes(int delta) {
          setStateCal(() {
            _mesActual = DateTime(_mesActual.year, _mesActual.month + delta, 1);
          });
        }
        
        bool esRangoValido(DateTime fechaInicio) {
          final fechaFin = fechaInicio.add(Duration(days: duracionDias - 1));
          final ultimoDiaMes = DateTime(_mesActual.year, _mesActual.month + 1, 0);
          if (fechaFin.year > _mesActual.year) return false;
          if (fechaFin.month > _mesActual.month) return false;
          if (fechaFin.day > ultimoDiaMes.day) return false;
          return true;
        }
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => cambiarMes(-1),
                  icon: const Icon(Icons.chevron_left, color: Color(0xFFFC6707)),
                ),
                Text(
                  '${monthNames[_mesActual.month - 1]} ${_mesActual.year}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                IconButton(
                  onPressed: () => cambiarMes(1),
                  icon: const Icon(Icons.chevron_right, color: Color(0xFFFC6707)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final dayNumber = index - startOffset + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) return Container();
                
                final fecha = DateTime(_mesActual.year, _mesActual.month, dayNumber);
                final hoy = DateTime.now();
                final esPasado = fecha.isBefore(hoy) && !fecha.isAtSameMomentAs(hoy);
                final rangoCompletoValido = esRangoValido(fecha);
                final esSeleccionada = fechaInicioSeleccionada != null && 
                    fechaInicioSeleccionada.day == dayNumber &&
                    fechaInicioSeleccionada.month == _mesActual.month;
                
                Color bgColor = Colors.transparent;
                Color textColor = const Color(0xFF333333);
                
                if (esPasado) {
                  textColor = const Color(0xFFCCCCCC);
                } else if (esSeleccionada) {
                  bgColor = const Color(0xFFFC6707);
                  textColor = Colors.white;
                } else if (rangoCompletoValido && !esPasado) {
                  bgColor = const Color(0xFFE8F5E9);
                  textColor = const Color(0xFF2E7D32);
                } else {
                  textColor = const Color(0xFFCCCCCC);
                }
                
                return GestureDetector(
                  onTap: (rangoCompletoValido && !esPasado) ? () {
                    onFechaSeleccionada(fecha);
                  } : null,
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
            const SizedBox(height: 10),
            Text(
              '⚠️ El viaje dura EXACTAMENTE $duracionDias días.\nSolo puedes seleccionar fechas que permitan el viaje completo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: const Color(0xFF888888),
              ),
            ),
          ],
        );
      },
    );
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: estadoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estadoTexto,
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 11 : 12,
                            fontWeight: FontWeight.bold,
                            color: estadoColor,
                          ),
                        ),
                      ),
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
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          MouseRegion(
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
          ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ElevatedButton(
              onPressed: () {
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 6 : 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Pagar',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (estado == EstadoReserva.pagado) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          MouseRegion(
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
          ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ElevatedButton(
              onPressed: () {
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 6 : 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Ver Ticket',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (estado == EstadoReserva.disfrutado) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ElevatedButton(
          onPressed: () {
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
          style: ElevatedButton.styleFrom(
            backgroundColor: rosaVivo,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 6 : 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            'Reseña',
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.bold,
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