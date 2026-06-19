import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/notificacion_controller.dart';
import '../../controllers/auth_controller.dart';
import '../shared/app_header.dart';
import 'destination_detail_view.dart';
import 'my_trips_view.dart';
import 'favorites_view.dart';
import 'student_home_view.dart';
import 'edit_profile_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> _menuItems = ['Inicio', 'Mis Viajes', 'Favoritos'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final notifCtrl = Provider.of<NotificacionController>(context, listen: false);
      if (auth.usuarioActual != null) {
        notifCtrl.listenToNotificaciones(auth.usuarioActual!.id);
      }
    });
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

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer() : null,
      body: Column(
        children: [
          AppHeader(
            activeMenu: '',
            onMenuSelected: _handleMenuSelected,
            onEditProfile: _handleEditProfile,
            onLogout: _handleLogout,
            menuItems: _menuItems,
            isMobile: isMobile,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(
            child: Consumer<NotificacionController>(
              builder: (context, notificacionController, child) {
                final notificaciones = notificacionController.notificaciones;
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notificaciones',
                        style: GoogleFonts.outfit(
                          fontSize: isMobile ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (notificaciones.isNotEmpty)
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                CustomConfirmDialog.show(
                                  context: context,
                                  title: 'Borrar todo',
                                  message: '¿Estás seguro de que deseas eliminar todas las notificaciones? Esta acción no se puede deshacer.',
                                  confirmText: 'Borrar',
                                  icon: Icons.delete_sweep,
                                ).then((confirm) {
                                  if (confirm == true) {
                                    notificacionController.eliminarTodasNotificaciones();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Se borraron de forma correcta',
                                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                                        ),
                                        backgroundColor: const Color(0xFFFC6707),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                });
                              },
                              child: Text(
                                'Borrar todo',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFC6707),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: notificaciones.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_none,
                                      size: 80,
                                      color: const Color(0xFFCCCCCC),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay notificaciones por el momento',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        color: const Color(0xFF999999),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: notificaciones.length,
                                itemBuilder: (context, index) {
                                  final notificacion = notificaciones[index];
                                  return _buildNotificationCard(
                                    notificacion.titulo,
                                    notificacion.mensaje,
                                    notificacion.fechaCreacion,
                                    notificacion.leida,
                                    notificacion.idPaquete,
                                    notificacion.id,
                                    notificacionController,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
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
                      _handleMenuSelected('Mis Viajes');
                    }),
                    _buildDrawerItem('Favoritos', Icons.favorite_border, () {
                      Navigator.pop(context);
                      _handleMenuSelected('Favoritos');
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
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFC6707)),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF333333)),
      ),
      onTap: onTap,
    );
  }

  Widget _buildNotificationCard(
    String titulo,
    String mensaje,
    DateTime fecha,
    bool leida,
    String? idPaquete,
    String notificacionId,
    NotificacionController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: leida ? Colors.white : const Color(0xFFFFF4ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!leida) {
              controller.marcarComoLeida(notificacionId);
            }
            if (idPaquete != null && idPaquete.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DestinationDetailView(destinoId: idPaquete),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC6707).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: const Color(0xFFFC6707),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: leida ? FontWeight.w500 : FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          final match = RegExp(r'"?([a-zA-Z0-9]{20})"?').firstMatch(mensaje);
                          final extractedId = match?.group(1);
                          final idToFetch = (idPaquete != null && idPaquete.isNotEmpty)
                              ? idPaquete
                              : extractedId;

                          return FutureBuilder<String?>(
                            future: idToFetch != null && idToFetch.isNotEmpty
                                ? controller.obtenerNombreRealDestino(idToFetch)
                                : null,
                            builder: (context, snapshot) {
                              String finalMensaje = mensaje;
                              if (snapshot.hasData && snapshot.data != null) {
                                final nombre = snapshot.data!;
                                if (nombre.isNotEmpty && idToFetch != null) {
                                  finalMensaje = mensaje.replaceAll(idToFetch, nombre);
                                }
                              }
                              return Text(
                                finalMensaje,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: const Color(0xFF666666),
                                ),
                              );
                            },
                          );
                        }
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatFecha(fecha),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    controller.eliminarNotificacion(notificacionId);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: const Color(0xFFCCCCCC),
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

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diferencia = now.difference(fecha);
    
    if (diferencia.inDays > 7) {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } else if (diferencia.inDays > 0) {
      return 'Hace ${diferencia.inDays} día${diferencia.inDays == 1 ? '' : 's'}';
    } else if (diferencia.inHours > 0) {
      return 'Hace ${diferencia.inHours} hora${diferencia.inHours == 1 ? '' : 's'}';
    } else if (diferencia.inMinutes > 0) {
      return 'Hace ${diferencia.inMinutes} minuto${diferencia.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Hace un momento';
    }
  }
}