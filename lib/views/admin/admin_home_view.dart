// Dashboard del administrador con métricas reales traídas de Firestore
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../shared/app_header.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'admin_users_view.dart';
import 'admin_edit_profile_view.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeMenu = 'Dashboard';
  final List<String> _menuItems = [
    'Dashboard',
    'Gestión',
    'Usuarios',
    'Reportes'
  ];

  // Categorías válidas de destinos (no inventar otras, "Selva" no existe)
  static const List<String> _categoriasValidas = [
    'Playas / Cayos',
    'Montañas / Trekking',
    'Aventura / Ríos',
    'Cultura / Ciudades',
  ];

  // Métricas cargadas desde Firestore
  int _totalOperadores = 0;
  int _totalEstudiantes = 0;
  int _totalDestinos = 0;
  int _totalReservas = 0;
  double _totalIngresos = 0;
  bool _cargando = true;

  // Datos para el gráfico de destinos más populares: nombre -> cantidad de reservas
  List<MapEntry<String, int>> _topDestinos = [];

  // Datos para el gráfico de distribución por categoría: categoría -> cantidad de destinos
  Map<String, int> _destinosPorCategoria = {
    for (final cat in _categoriasValidas) cat: 0,
  };

  @override
  void initState() {
    super.initState();
    _cargarMetricas();
  }

  // Trae los conteos reales desde Firestore para mostrar en las tarjetas y los gráficos
  Future<void> _cargarMetricas() async {
    try {
      final db = FirebaseFirestore.instance;

      // Consultamos en paralelo para ser más rápidos
      final results = await Future.wait([
        db.collection('estudiantes').get(),
        db.collection('operadores').get(),
        db.collection('destinos').get(),
        db.collection('reservas').get(),
      ]);

      final estudiantesSnap = results[0];
      final operadoresSnap = results[1];
      final destinosSnap = results[2];
      final reservasSnap = results[3];

      // Armamos un mapa destinoId -> nombre y destinoId -> categoria para usarlo en los gráficos
      final Map<String, String> nombrePorDestino = {};
      int destinosActivos = 0;
      final Map<String, int> conteoCategoria = {
        for (final cat in _categoriasValidas) cat: 0,
      };

      for (final doc in destinosSnap.docs) {
        final data = doc.data();
        final activo = data['activo'] as bool? ?? false;
        final nombre = data['nombre'] as String? ?? 'Sin nombre';
        final categoria = data['categoria'] as String? ?? '';

        nombrePorDestino[doc.id] = nombre;

        if (activo) destinosActivos++;

        // Solo contamos categorías que conocemos (no inventamos categorías nuevas)
        if (conteoCategoria.containsKey(categoria)) {
          conteoCategoria[categoria] = conteoCategoria[categoria]! + 1;
        }
      }

      // Sumamos el totalGeneral de las reservas pagadas/disfrutadas
      // y contamos cuántas reservas tiene cada destino para el top 5
      double ingresos = 0;
      final Map<String, int> reservasPorDestino = {};

      for (final doc in reservasSnap.docs) {
        final data = doc.data();
        final estado = data['estadoActual'] as String? ?? '';
        final paqueteId = data['paqueteId'] as String? ?? '';

        if (estado == 'pagado' || estado == 'disfrutado') {
          ingresos += (data['totalGeneral'] as num? ?? 0).toDouble();
        }

        if (paqueteId.isNotEmpty) {
          reservasPorDestino[paqueteId] =
              (reservasPorDestino[paqueteId] ?? 0) + 1;
        }
      }

      // Ordenamos los destinos por cantidad de reservas y tomamos los 5 primeros
      final destinosOrdenados = reservasPorDestino.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final top5 = destinosOrdenados.take(5).map((entry) {
        final nombre = nombrePorDestino[entry.key] ?? 'Destino eliminado';
        return MapEntry(nombre, entry.value);
      }).toList();

      if (mounted) {
        setState(() {
          _totalEstudiantes = estudiantesSnap.docs.length;
          _totalOperadores = operadoresSnap.docs.length;
          _totalDestinos = destinosActivos;
          _totalReservas = reservasSnap.docs.length;
          _totalIngresos = ingresos;
          _topDestinos = top5;
          _destinosPorCategoria = conteoCategoria;
          _cargando = false;
        });
      }
    } catch (e) {
      // Si falla la carga, simplemente dejamos los valores en 0
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Navegar

  void _handleMenuSelected(String menu) {
    if (menu == 'Usuarios') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AdminUsersView()));
    } else if (menu == 'Gestión') {
      _mostrarMensaje('Gestión - Próximamente');
    } else if (menu == 'Reportes') {
      _mostrarMensaje('Reportes - Próximamente');
    }
  }

  void _handleEditProfile() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AdminEditProfileView()));
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

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje),
      backgroundColor: const Color(0xFFFC6707),
      duration: const Duration(seconds: 2),
    ));
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  // Build

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
            activeMenu: _activeMenu,
            onMenuSelected: _handleMenuSelected,
            onEditProfile: _handleEditProfile,
            onLogout: _handleLogout,
            menuItems: _menuItems,
            isMobile: isMobile,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(
            child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final user = Provider.of<AuthController>(context).usuarioActual;

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
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFFC6707), width: 2),
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFFFDDBB3),
                      child: Icon(Icons.admin_panel_settings,
                          color: Color(0xFFFC6707), size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nombre ?? 'Administrador',
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF333333)),
                        ),
                        Text('Administrador',
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: const Color(0xFF666666))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            _buildDrawerItem('Dashboard', Icons.dashboard_outlined, () {
              Navigator.pop(context);
            }),
            _buildDrawerItem('Gestión', Icons.settings_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Gestión');
            }),
            _buildDrawerItem('Usuarios', Icons.people_outline, () {
              Navigator.pop(context);
              _handleMenuSelected('Usuarios');
            }),
            _buildDrawerItem('Reportes', Icons.bar_chart_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Reportes');
            }),
            const Spacer(),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            _buildDrawerItem('Cerrar Sesión', Icons.logout_outlined, () {
              Navigator.pop(context);
              _handleLogout();
            }),
            const SizedBox(height: 24),
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

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildMetricsContent(isMobile: true),
          _buildFooter(true),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildMetricsContent(isMobile: false),
                _buildFooter(false),
              ],
            ),
          ),
        ),
        // Imagen decorativa lateral del campus
        Container(
          width: 320,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5),
            ),
          ),
          child: Image.asset(
            'assets/images/campus_admin.png',
            width: 320,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFFDDBB3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 48, color: Color(0xFFFC6707)),
                    SizedBox(height: 8),
                    Text('Imagen del Campus'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsContent({required bool isMobile}) {
    // Total de usuarios = estudiantes + operadores
    final totalUsuarios = _totalEstudiantes + _totalOperadores;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dashboard de Métricas',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              // Botón para refrescar todas las métricas manualmente
              IconButton(
                onPressed: () {
                  setState(() => _cargando = true);
                  _cargarMetricas();
                },
                icon: const Icon(Icons.refresh, color: Color(0xFFFC6707)),
                tooltip: 'Actualizar métricas',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Datos en tiempo real de la plataforma SamanGo',
            style:
                GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF888888)),
          ),
          const SizedBox(height: 24),

          // Tarjetas de métricas
          if (isMobile) ...[
            _buildMetricCard(
                'Total Usuarios', '$totalUsuarios', Icons.people),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildMetricCard('Operadores',
                        '$_totalOperadores', Icons.business)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildMetricCard('Estudiantes',
                        '$_totalEstudiantes', Icons.school)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildMetricCard('Destinos Activos',
                        '$_totalDestinos', Icons.tour)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildMetricCard(
                        'Reservas', '$_totalReservas', Icons.receipt)),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricCard(
                'Ingresos Confirmados',
                '\$${_totalIngresos.toStringAsFixed(2)}',
                Icons.attach_money),
          ] else ...[
            Row(
              children: [
                Expanded(
                    child: _buildMetricCard('Total Usuarios',
                        '$totalUsuarios', Icons.people)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildMetricCard('Operadores',
                        '$_totalOperadores', Icons.business)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildMetricCard('Estudiantes',
                        '$_totalEstudiantes', Icons.school)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildMetricCard('Destinos Activos',
                        '$_totalDestinos', Icons.tour)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildMetricCard(
                        'Reservas', '$_totalReservas', Icons.receipt)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildMetricCard(
                        'Ingresos Confirmados',
                        '\$${_totalIngresos.toStringAsFixed(2)}',
                        Icons.attach_money)),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // Sección de gráficos: destinos populares y distribución por categoría
          if (isMobile) ...[
            _buildTopDestinosChart(),
            const SizedBox(height: 24),
            _buildCategoriaChart(),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTopDestinosChart()),
                const SizedBox(width: 16),
                Expanded(child: _buildCategoriaChart()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Tarjeta individual de métrica. Muestra un spinner mientras carga.
  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFC6707).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFFC6707), size: 24),
          ),
          const SizedBox(height: 12),
          // Mostramos el spinner mientras se cargan los datos
          _cargando
              ? const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFFC6707)),
                )
              : Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            title,
            style:
                GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  // Gráfico de barras horizontales: top 5 destinos con más reservas
  Widget _buildTopDestinosChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Destinos más populares',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          if (_cargando)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: Color(0xFFFC6707)),
              ),
            )
          else if (_topDestinos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Aún no hay reservas registradas',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: const Color(0xFF999999)),
              ),
            )
          else
            // El máximo nos sirve para escalar las barras de forma proporcional
            ..._buildBarrasDestinos(),
        ],
      ),
    );
  }

  List<Widget> _buildBarrasDestinos() {
    final maxCantidad = _topDestinos.first.value;

    return _topDestinos.map((entry) {
      final proporcion = maxCantidad == 0 ? 0.0 : entry.value / maxCantidad;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: const Color(0xFF333333)),
                  ),
                ),
                Text(
                  '${entry.value}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFC6707),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: proporcion,
                minHeight: 10,
                backgroundColor: const Color(0xFFE0E0E0),
                color: const Color(0xFFFC6707),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Colores fijos para cada categoría en el gráfico de torta (mismo orden que _categoriasValidas)
  static const List<Color> _coloresCategorias = [
    Color(0xFFFC6707), // Playas / Cayos
    Color(0xFFFDDBB3), // Montañas / Trekking
    Color(0xFF4CAF50), // Aventura / Ríos
    Color(0xFF2196F3), // Cultura / Ciudades
  ];

  // Gráfico de distribución de destinos por categoría (tipo rueda / torta)
  Widget _buildCategoriaChart() {
    final total = _destinosPorCategoria.values.fold<int>(0, (a, b) => a + b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Destinos por categoría',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          if (_cargando)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: Color(0xFFFC6707)),
              ),
            )
          else if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Aún no hay destinos registrados',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: const Color(0xFF999999)),
              ),
            )
          else
            Column(
              children: [
                // La rueda con los porcentajes calculados a partir de Firestore
                SizedBox(
                  height: 160,
                  width: 160,
                  child: CustomPaint(
                    painter: _PieChartPainter(
                      valores: _destinosPorCategoria.values.toList(),
                      colores: _coloresCategorias,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Leyenda con el nombre, cantidad y color de cada categoría
                ..._destinosPorCategoria.entries.toList().asMap().entries.map(
                  (item) {
                    final index = item.key;
                    final entry = item.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _coloresCategorias[index],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: const Color(0xFF333333)),
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFC6707),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
      padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
      margin: EdgeInsets.only(top: isMobile ? 16 : 32),
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

// Dibuja el gráfico de torta (rueda) a partir de los valores reales de Firestore.
// No usa ninguna librería externa, solo CustomPainter nativo de Flutter.
class _PieChartPainter extends CustomPainter {
  final List<int> valores;
  final List<Color> colores;

  _PieChartPainter({required this.valores, required this.colores});

  @override
  void paint(Canvas canvas, Size size) {
    final total = valores.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    double anguloInicial = -90 * (3.141592653589793 / 180); // empieza arriba

    for (int i = 0; i < valores.length; i++) {
      final valor = valores[i];
      if (valor == 0) continue;

      final porcentaje = valor / total;
      final anguloBarrido = porcentaje * 2 * 3.141592653589793;

      final paint = Paint()
        ..color = colores[i % colores.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, anguloInicial, anguloBarrido, true, paint);
      anguloInicial += anguloBarrido;
    }

    // Círculo blanco en el centro para dar el efecto de "donut"
    final centro = Offset(size.width / 2, size.height / 2);
    final radioInterno = size.width * 0.28;
    canvas.drawCircle(centro, radioInterno, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.valores != valores || oldDelegate.colores != colores;
  }
}