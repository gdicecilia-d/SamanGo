// Pantalla que muestra los resultados de la búsqueda
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../shared/app_header.dart';
import 'widgets/destination_card.dart';
import 'widgets/horizontal_scroll_section.dart';
import 'widgets/student_footer.dart';
import 'destination_detail_view.dart';
import 'favorites_view.dart';
import 'edit_profile_view.dart';
import 'student_home_view.dart';
import 'my_trips_view.dart';
import '../../controllers/auth_controller.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'notifications_view.dart';

class SearchResultsView extends StatefulWidget {
  final String destino;
  final String? transporte;
  final String? presupuesto;
  final String? alojamiento;
  final String? categoria;

  const SearchResultsView({
    super.key,
    required this.destino,
    this.transporte,
    this.presupuesto,
    this.alojamiento,
    this.categoria,
  });

  @override
  State<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<SearchResultsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> _menuItems = ['Inicio', 'Mis Viajes', 'Favoritos'];

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
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
      }
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<List<QueryDocumentSnapshot>> _buscarDestinos() async {
    Query query = FirebaseFirestore.instance.collection('destinos');
    
    query = query.where('activo', isEqualTo: true);
    
    if (widget.transporte != null && widget.transporte != 'Todos') {
      query = query.where('transporte', isEqualTo: widget.transporte);
    }
    
    if (widget.alojamiento != null && widget.alojamiento != 'Todos') {
      query = query.where('alojamiento', isEqualTo: widget.alojamiento);
    }
    
    if (widget.categoria != null && widget.categoria!.isNotEmpty) {
      query = query.where('categoria', isEqualTo: widget.categoria);
    }
    
    final snapshot = await query.get();
    var resultados = snapshot.docs;
    
    final texto = widget.destino.toLowerCase().trim();
    if (texto.isNotEmpty) {
      resultados = resultados.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final nombre = (data['nombre'] ?? '').toString().toLowerCase();
        final ubicacion = (data['ubicacion'] ?? '').toString().toLowerCase();
        return nombre.contains(texto) || ubicacion.contains(texto);
      }).toList();
    }
    
    if (widget.presupuesto != null && widget.presupuesto != 'Todos') {
      double min = 0;
      double max = double.infinity;
      
      if (widget.presupuesto == '\$0 - \$50') { min = 0; max = 50; }
      else if (widget.presupuesto == '\$50 - \$100') { min = 50; max = 100; }
      else if (widget.presupuesto == '\$100 - \$200') { min = 100; max = 200; }
      else if (widget.presupuesto == '\$200+') { min = 200; max = double.infinity; }
      
      resultados = resultados.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final precio = (data['precio'] ?? 0).toDouble();
        return precio >= min && precio <= max;
      }).toList();
    }
    
    return resultados;
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
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: _buscarDestinos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFC6707)),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar resultados',
                      style: GoogleFonts.outfit(color: Colors.red),
                    ),
                  );
                }
                
                final resultados = snapshot.data ?? [];
                
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Resultados de búsqueda',
                            style: GoogleFonts.outfit(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF333333),
                            ),
                          ),
                          if (!isMobile)
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color(0xFFFC6707),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_back,
                                        color: const Color(0xFFFC6707),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Volver',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: const Color(0xFFFC6707),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    if (isMobile)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xFFFC6707),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      color: const Color(0xFFFC6707),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Volver',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: const Color(0xFFFC6707),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    if (_getFiltrosActivos().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _getFiltrosActivos().map((filtro) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFC6707).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFC6707), width: 0.5),
                              ),
                              child: Text(
                                filtro,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFFFC6707),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    Expanded(
                      child: resultados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_off, size: 64, color: Color(0xFFCCCCCC)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No encontramos destinos\ncon esos filtros',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      color: const Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  HorizontalScrollSection(
                                    title: '',
                                    showTitle: false,
                                    children: resultados.map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      final isOffer = data['isOffer'] == true;
                                      
                                      return DestinationCard(
                                        id: doc.id,
                                        nombre: data['nombre'] ?? 'Sin título',
                                        ubicacion: data['ubicacion'] ?? '',
                                        precio: (data['precio'] ?? 0).toDouble(),
                                        duracion: data['duracion'] ?? 'Full Day',
                                        imagenUrl: data['imagen'] ?? '',
                                        isOffer: isOffer,
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
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
          StudentFooter(isMobile: isMobile),
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
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentHomeView()),
                        (route) => false,
                      );
                    }),
                    _buildDrawerItem('Mis Viajes', Icons.airplane_ticket_outlined, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyTripsView()),
                      );
                    }),
                    _buildDrawerItem('Favoritos', Icons.favorite_border, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FavoritesView()),
                      );
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

  List<String> _getFiltrosActivos() {
    final filtros = <String>[];
    if (widget.destino.isNotEmpty) filtros.add('Destino: ${widget.destino}');
    if (widget.transporte != null && widget.transporte != 'Todos') filtros.add('Transporte: ${widget.transporte}');
    if (widget.presupuesto != null && widget.presupuesto != 'Todos') filtros.add('Presupuesto: ${widget.presupuesto}');
    if (widget.alojamiento != null && widget.alojamiento != 'Todos') filtros.add('Alojamiento: ${widget.alojamiento}');
    if (widget.categoria != null && widget.categoria!.isNotEmpty) filtros.add('Categoría: ${widget.categoria}');
    return filtros;
  }
}