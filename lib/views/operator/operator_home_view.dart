import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../shared/app_header.dart';
import 'operator_edit_profile_view.dart';
import 'operator_publish_view.dart';
import 'requests_view.dart';
import 'widgets/operator_destination_card.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import '../../controllers/notificacion_controller.dart';
import '../student/widgets/notifications_panel.dart';
import '../student/widgets/horizontal_scroll_section.dart';
import 'operator_notifications_view.dart';

class OperatorHomeView extends StatefulWidget {
  const OperatorHomeView({super.key});

  @override
  State<OperatorHomeView> createState() => _OperatorHomeViewState();
}

class _OperatorHomeViewState extends State<OperatorHomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeMenu = 'Inicio';
  final List<String> _menuItems = ['Inicio', 'Publicar', 'Solicitudes'];
  int _refreshKey = 0;

  int _totalPublicaciones = 0;
  int _totalReservas = 0;
  double _calificacionPromedio = 0;
  int _totalResenas = 0;
  bool _cargandoMetricas = true;
  Map<String, dynamic>? _operadorData;
  bool _cargandoOperador = true;
  String _operadorId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthController>(context, listen: false);
      final notifCtrl = Provider.of<NotificacionController>(context, listen: false);
      if (auth.usuarioActual != null) {
        _operadorId = auth.usuarioActual!.id;
        notifCtrl.listenToNotificaciones(
          _operadorId,
          collectionName: 'operadores',
        );
        _cargarDatosOperador(_operadorId);
        _cargarMetricasOperador(_operadorId);
      }
    });
  }

  Future<void> _cargarDatosOperador(String operadorId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('operadores')
          .doc(operadorId)
          .get();
      
      if (doc.exists && mounted) {
        setState(() {
          _operadorData = doc.data() as Map<String, dynamic>?;
          _cargandoOperador = false;
        });
      } else {
        final auth = Provider.of<AuthController>(context, listen: false);
        final user = auth.usuarioActual;
        if (user != null && mounted) {
          setState(() {
            _operadorData = {
              'nombre': user.nombre,
              'empresa': user.empresa ?? 'Operador',
              'correo': user.correo,
            };
            _cargandoOperador = false;
          });
        } else {
          setState(() {
            _cargandoOperador = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _cargandoOperador = false;
      });
    }
  }

  Future<void> _cargarMetricasOperador(String operadorId) async {
    setState(() {
      _cargandoMetricas = true;
    });

    try {
      final db = FirebaseFirestore.instance;

      final destinosSnap = await db
          .collection('destinos')
          .where('operadorId', isEqualTo: operadorId)
          .get();

      final reservasSnap = await db
          .collection('reservas')
          .where('operadorId', isEqualTo: operadorId)
          .get();

      final operadorDoc = await db
          .collection('operadores')
          .doc(operadorId)
          .get();

      final operadorData = operadorDoc.data() as Map<String, dynamic>? ?? {};
      final calificacion = (operadorData['calificacionPromedio'] as num? ?? 0).toDouble();
      final totalResenas = (operadorData['totalResenas'] as num? ?? 0).toInt();

      if (mounted) {
        setState(() {
          _totalPublicaciones = destinosSnap.docs.length;
          _totalReservas = reservasSnap.docs.length;
          _calificacionPromedio = calificacion;
          _totalResenas = totalResenas;
          _cargandoMetricas = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargandoMetricas = false);
    }
  }

  Future<void> _refrescarMetricas() async {
    if (_operadorId.isNotEmpty) {
      await _cargarMetricasOperador(_operadorId);
      setState(() => _refreshKey++);
      _mostrarMensaje('Métricas actualizadas');
    }
  }

  void _handleMenuSelected(String menu) {
    if (menu == 'Publicar') {
      setState(() => _activeMenu = menu);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const OperatorPublishView())).then((_) {
        setState(() {
          _activeMenu = 'Inicio';
          _refreshKey++;
        });
        _cargarMetricasOperador(_operadorId);
      });
    } else if (menu == 'Solicitudes') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const OperatorRequestsView()));
    } else if (menu == 'Inicio') {
      setState(() => _activeMenu = menu);
    }
  }

  void _handleEditProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const OperatorEditProfileView()));
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

  void _mostrarMensaje(String mensaje, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color ?? const Color(0xFFFC6707),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _verificarYeliminarPublicacion(String id, String nombre) async {
    try {
      final reservas = await FirebaseFirestore.instance
          .collection('reservas')
          .where('paqueteId', isEqualTo: id)
          .where('estadoActual', whereIn: ['aceptado', 'verificandoPago', 'pagado', 'disfrutado'])
          .get();

      if (reservas.docs.isNotEmpty) {
        _mostrarMensaje(
          'No puedes eliminar este paquete porque ya hay solicitudes aceptadas.',
        );
        return;
      }

      final confirm = await CustomConfirmDialog.show(
        context: context,
        title: 'Eliminar publicación',
        message: '¿Estás seguro de que deseas eliminar "$nombre"? Esta acción no se puede deshacer.',
        confirmText: 'Eliminar',
        icon: Icons.delete,
      );

      if (confirm == true) {
        await FirebaseFirestore.instance.collection('destinos').doc(id).delete();
        _mostrarMensaje('Publicación eliminada');
        setState(() => _refreshKey++);
        _cargarMetricasOperador(_operadorId);
      }
    } catch (e) {
      _mostrarMensaje('Error al verificar o eliminar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    
    final String empresa = _operadorData?['empresa'] ?? 'Operador';
    final String nombreOperador = _operadorData?['nombre'] ?? 'Operador';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: isMobile ? _buildDrawer() : null,
      body: Column(
        children: [
          AppHeader(
            activeMenu: _activeMenu,
            onMenuSelected: _handleMenuSelected,
            onEditProfile: _handleEditProfile,
            onLogout: _handleLogout,
            menuItems: _menuItems,
            isMobile: isMobile,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(
            child: isMobile
                ? _buildMobileLayout(_operadorId, empresa, nombreOperador)
                : _buildDesktopLayout(_operadorId, empresa, nombreOperador),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(String operadorId, String empresa, String nombreOperador) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                    children: [
                      const TextSpan(text: '¡Hola '),
                      TextSpan(text: nombreOperador, style: const TextStyle(color: Color(0xFFFC6707))),
                      const TextSpan(text: '! Revisa el estado de tus servicios'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildMainContent(isMobile: true, operadorId: operadorId),
              const SizedBox(height: 16),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const Spacer(),
              _buildFooter(true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(String operadorId, String empresa, String nombreOperador) {
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
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF333333),
                            ),
                            children: [
                              const TextSpan(text: '¡Hola '),
                              TextSpan(text: nombreOperador, style: const TextStyle(color: Color(0xFFFC6707))),
                              const TextSpan(text: '! Revisa el estado de tus servicios'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildMainContent(isMobile: false, operadorId: operadorId),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      const Spacer(),
                      _buildFooter(false),
                    ],
                  ),
                ),
              ],
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
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    final String nombreDrawer = _operadorData?['nombre'] ?? 'Operador';
    final String empresaDrawer = _operadorData?['empresa'] ?? '';
    final String fotoBase64 = _operadorData?['fotoBase64'] ?? '';

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
                        child: fotoBase64.isNotEmpty
                            ? Image.memory(
                                base64Decode(fotoBase64),
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
                          nombreDrawer,
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                        ),
                        Text(
                          empresaDrawer,
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
                    _buildDrawerItem('Publicar', Icons.add_box_outlined, () {
                      Navigator.pop(context);
                      _handleMenuSelected('Publicar');
                    }),
                    _buildDrawerItem('Solicitudes', Icons.receipt_outlined, () {
                      Navigator.pop(context);
                      _handleMenuSelected('Solicitudes');
                    }),
                    _buildDrawerItem('Notificaciones', Icons.notifications_outlined, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OperatorNotificationsView()),
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

  Widget _buildMainContent({required bool isMobile, required String operadorId}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tu Resumen',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 24 : 30,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              IconButton(
                onPressed: _refrescarMetricas,
                icon: const Icon(Icons.refresh, color: Color(0xFFFC6707)),
                tooltip: 'Actualizar métricas',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: isMobile ? 170 : 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final metrics = [
                {
                  'titulo': 'Publicaciones',
                  'valor': '$_totalPublicaciones',
                  'icono': Icons.tour_outlined,
                  'color': const Color(0xFFFC6707),
                },
                {
                  'titulo': 'Calificación',
                  'valor': _calificacionPromedio > 0
                      ? '${_calificacionPromedio.toStringAsFixed(1)} ★'
                      : 'Sin reseñas',
                  'icono': Icons.star_outline,
                  'color': Colors.amber,
                  'subtitulo': _totalResenas > 0 ? '$_totalResenas reseñas' : null,
                },
              ];
              final m = metrics[index];
              return _buildMetricaTarjeta(
                titulo: m['titulo'] as String,
                valor: m['valor'] as String,
                icono: m['icono'] as IconData,
                color: m['color'] as Color,
                subtitulo: m['subtitulo'] as String?,
                isMobile: isMobile,
              );
            },
          ),
        ),

        const SizedBox(height: 40),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: Text(
            'Tus Publicaciones',
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 24 : 30,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          key: ValueKey('operator_publications_$_refreshKey'),
          stream: FirebaseFirestore.instance
              .collection('destinos')
              .where('operadorId', isEqualTo: operadorId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(color: Color(0xFFFC6707)),
                ),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFF44336)),
                      const SizedBox(height: 12),
                      Text(
                        'Error al cargar las publicaciones',
                        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
                      ),
                    ],
                  ),
                ),
              );
            }

            final destinos = snapshot.data?.docs ?? [];

            if (destinos.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFCCCCCC)),
                      const SizedBox(height: 12),
                      Text(
                        'No tienes publicaciones aún',
                        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF999999)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Presiona "Publicar" para crear tu primer paquete',
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFCCCCCC)),
                      ),
                    ],
                  ),
                ),
              );
            }

            final cards = destinos.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return OperatorDestinationCard(
                id: doc.id,
                nombre: data['nombre'] ?? 'Sin título',
                ubicacion: data['ubicacion'] ?? '',
                precio: (data['precio'] ?? 0).toDouble(),
                duracion: data['duracion'] ?? 'Full Day',
                imagenUrl: data['imagen'] ?? '',
                isOffer: data['isOffer'] == true,
                activo: data['activo'] == true,
                cuposTotales: data['cuposTotales'] ?? 0,
                cuposDisponibles: data['cuposDisponibles'] ?? 0,
                onDelete: () => _verificarYeliminarPublicacion(
                  doc.id,
                  data['nombre'] ?? 'este destino',
                ),
              );
            }).toList();

            return HorizontalScrollSection(
              title: '',
              showTitle: false,
              children: cards,
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMetricaTarjeta({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
    String? subtitulo,
    required bool isMobile,
  }) {
    final size = isMobile ? 170.0 : 200.0;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icono, color: color, size: isMobile ? 28 : 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cargandoMetricas
                  ? SizedBox(
                      height: isMobile ? 24 : 28,
                      width: isMobile ? 24 : 28,
                      child: CircularProgressIndicator(strokeWidth: 2, color: color),
                    )
                  : Text(
                      valor,
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
              Text(
                titulo,
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 13 : 15,
                  color: const Color(0xFF888888),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitulo != null)
                Text(
                  subtitulo,
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 11 : 13,
                    color: const Color(0xFFAAAAAA),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
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