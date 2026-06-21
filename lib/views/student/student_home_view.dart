// Home estudiante 
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/app_header.dart';
import '../../controllers/auth_controller.dart';
import 'edit_profile_view.dart';
import 'widgets/search_bar.dart';
import 'widgets/categories.dart';
import 'widgets/destination_card.dart';
import 'widgets/horizontal_scroll_section.dart';
import 'destination_detail_view.dart';
import 'favorites_view.dart';
import 'my_trips_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import '../../controllers/notificacion_controller.dart';
import 'widgets/notifications_panel.dart';
import 'notifications_view.dart';

class StudentHomeView extends StatefulWidget {
  const StudentHomeView({super.key});

  @override
  State<StudentHomeView> createState() => _StudentHomeViewState();
}

class _StudentHomeViewState extends State<StudentHomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeMenu = 'Inicio';
  final List<String> _menuItems = ['Inicio', 'Mis Viajes', 'Favoritos'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthController>(context, listen: false);
      final notifCtrl = Provider.of<NotificacionController>(context, listen: false);
      if (auth.usuarioActual != null) {
        notifCtrl.listenToNotificaciones(auth.usuarioActual!.id);
      }
    });
  }

  void _handleMenuSelected(String menu) {
    if (menu == 'Mis Viajes') {
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
    _mostrarDialogoCerrarSesion();
  }

  void _mostrarDialogoCerrarSesion() {
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

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFFC6707),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  bool _esOferta(dynamic isOfferValue) {
    if (isOfferValue == null) return false;
    if (isOfferValue is bool) return isOfferValue;
    if (isOfferValue is String) return isOfferValue.toLowerCase() == 'true';
    return false;
  }

  void _mostrarAyuda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFC6707).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.help_outline,
                color: const Color(0xFFFC6707),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Cómo funciona SamanGo?',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '1. Explora los destinos disponibles\n'
              '2. Selecciona tu viaje favorito\n'
              '3. Solicita cupos para tu fecha\n'
              '4. Espera la confirmación del operador\n'
              '5. Realiza el pago con PayPal\n'
              '6. ¡Disfruta tu viaje y califica!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF666666),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC6707),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Entendido',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final auth = Provider.of<AuthController>(context);
    final nombre = auth.usuarioActual?.nombre ?? 'Estudiante';
    final primerNombre = nombre.split(' ').first;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer() : null,
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarAyuda,
        backgroundColor: const Color(0xFFFC6707),
        child: const Icon(Icons.help_outline, color: Colors.white),
      ),
      body: Column(
        children: [
          AppHeader(
            activeMenu: 'Inicio',
            onMenuSelected: _handleMenuSelected,
            onEditProfile: _handleEditProfile,
            onLogout: _handleLogout,
            menuItems: _menuItems,
            isMobile: isMobile,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(
            child: isMobile 
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                              children: [
                                const TextSpan(text: '¡Hola '),
                                TextSpan(text: primerNombre, style: const TextStyle(color: Color(0xFFFC6707))),
                                const TextSpan(text: '! ¿A dónde quieres viajar hoy?'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildMainContent(isMobile: true),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildTrendingChart(isMobile: true),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  )
                : Row(
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
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                                      children: [
                                        const TextSpan(text: '¡Hola '),
                                        TextSpan(text: primerNombre, style: const TextStyle(color: Color(0xFFFC6707))),
                                        const TextSpan(text: '! ¿A dónde quieres viajar hoy?'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _buildMainContent(isMobile: false),
                                _buildFooter(false),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 320,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const NotificationsPanel(),
                              const SizedBox(height: 24),
                              _buildTrendingChart(isMobile: false),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ],
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
    final isActive = title == _activeMenu;
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

  Widget _buildMainContent({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: const SearchBarWidget(),
        ),
        const SizedBox(height: 32),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('destinos')
              .where('activo', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFFC6707))),
              );
            }
            
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }
            
            final todosDestinos = snapshot.data!.docs;
            final destinosNormales = todosDestinos.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return !_esOferta(data['isOffer']);
            }).toList();
            
            final cards = destinosNormales.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DestinationCard(
                id: doc.id,
                nombre: data['nombre'] ?? '',
                ubicacion: data['ubicacion'] ?? '',
                precio: (data['precio'] ?? 0).toDouble(),
                duracion: data['duracion'] ?? 'Full Day',
                imagenUrl: data['imagen'] ?? '',
                isOffer: false,
                calificacionPromedio: (data['calificacionPromedio'] as num?)?.toDouble() ?? 0.0,
                totalResenas: (data['totalResenas'] as num?)?.toInt() ?? 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DestinationDetailView(destinoId: doc.id),
                    ),
                  );
                },
              );
            }).toList();
            
            return HorizontalScrollSection(
              title: 'Destinos Disponibles',
              children: cards,
            );
          },
        ),

        const SizedBox(height: 32),

        const CategoriesSection(),

        const SizedBox(height: 32),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('destinos')
              .where('activo', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0))),
              );
            }
            
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }
            
            final todosDestinos = snapshot.data!.docs;
            final ofertas = todosDestinos.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _esOferta(data['isOffer']);
            }).toList();
            
            final cards = ofertas.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DestinationCard(
                id: doc.id,
                nombre: data['nombre'] ?? '',
                ubicacion: data['ubicacion'] ?? '',
                precio: (data['precio'] ?? 0).toDouble(),
                duracion: data['duracion'] ?? 'Full Day',
                imagenUrl: data['imagen'] ?? '',
                isOffer: true,
                calificacionPromedio: (data['calificacionPromedio'] as num?)?.toDouble() ?? 0.0,
                totalResenas: (data['totalResenas'] as num?)?.toInt() ?? 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DestinationDetailView(destinoId: doc.id),
                    ),
                  );
                },
              );
            }).toList();
            
            return HorizontalScrollSection(
              title: 'Ofertas Especiales',
              children: cards,
            );
          },
        ),
        
        // Eliminamos el gráfico de aquí, solo va afuera
      ],
    );
  }

  Widget _buildTrendingChart({required bool isMobile}) {
    return Container(
      width: isMobile ? double.infinity : 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Destinos más buscados',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendingChartContent(),
        ],
      ),
    );
  }

  Widget _buildTrendingChartContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('destinos')
          .where('activo', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFC6707)),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'Error al cargar destinos',
                style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        
        if (docs.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'No hay destinos disponibles',
                style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reservas')
              .snapshots(),
          builder: (context, reservasSnapshot) {
            if (reservasSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFC6707)),
                ),
              );
            }

            if (reservasSnapshot.hasError || !reservasSnapshot.hasData) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'Error al cargar reservas',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ),
              );
            }

            final reservasDocs = reservasSnapshot.data!.docs;
            
            Map<String, int> conteoReservas = {};
            
            for (final reservaDoc in reservasDocs) {
              final data = reservaDoc.data() as Map<String, dynamic>;
              final paqueteId = data['paqueteId'] as String?;
              if (paqueteId != null && paqueteId.isNotEmpty) {
                conteoReservas[paqueteId] = (conteoReservas[paqueteId] ?? 0) + 1;
              }
            }

            List<Map<String, dynamic>> destinosConReservas = [];

            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;
              final nombre = data['nombre'] ?? 'Sin nombre';
              final calificacion = (data['calificacionPromedio'] as num?)?.toDouble() ?? 0.0;
              final totalResenas = (data['totalResenas'] as num?)?.toInt() ?? 0;
              final cantidadReservas = conteoReservas[id] ?? 0;
              
              destinosConReservas.add({
                'id': id,
                'nombre': nombre,
                'calificacion': calificacion,
                'totalResenas': totalResenas,
                'reservas': cantidadReservas,
              });
            }

            destinosConReservas.sort((a, b) => b['reservas'].compareTo(a['reservas']));

            final topDestinos = destinosConReservas.take(5).toList();

            final totalReservas = topDestinos.fold<int>(0, (sum, d) => sum + (d['reservas'] as int));
            
            if (topDestinos.isEmpty || totalReservas == 0) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'Sin reservas aún',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ),
              );
            }

            final maxReservas = topDestinos.first['reservas'] as int;

            return Column(
              children: topDestinos.map((destino) {
                final nombre = destino['nombre'];
                final reservas = destino['reservas'] as int;
                final calificacion = destino['calificacion'] as double;
                final totalResenas = destino['totalResenas'] as int;
                final proporcion = maxReservas > 0 ? reservas / maxReservas : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              nombre,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              if (calificacion > 0) ...[
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: const Color(0xFFFFC107),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  calificacion.toStringAsFixed(1),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFFC107),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (totalResenas > 0)
                                Text(
                                  '($totalResenas)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: const Color(0xFF888888),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              Text(
                                '$reservas',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFC6707),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: proporcion,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE0E0E0),
                          color: const Color(0xFFFC6707),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
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