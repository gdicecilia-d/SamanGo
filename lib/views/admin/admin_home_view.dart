// Dashboard del administrador con métricas reales traídas de Firestore
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../auth/login_view.dart';
import '../shared/app_header.dart';
import '../shared/widgets/custom_dialog.dart';
import 'admin_edit_profile_view.dart';
import 'admin_management_view.dart';
import 'admin_reports_view.dart';
import 'admin_users_view.dart';

/// Paleta de colores del módulo admin, centralizada para no repetir
/// literales de color por todo el archivo.
class _Palette {
  static const primary = Color(0xFFFC6707);
  static const primaryLight = Color(0xFFFDDBB3);
  static const textDark = Color(0xFF333333);
  static const textGrey = Color(0xFF666666);
  static const textLight = Color(0xFF888888);
  static const textFaint = Color(0xFF999999);
  static const border = Color(0xFFE0E0E0);
  static const cardBg = Color(0xFFF8F8F8);

  static const categoryColors = [
    Color(0xFFFC6707),
    Color(0xFFFFB74D),
    Color(0xFFFF8A65),
    Color(0xFFFFAB91),
  ];
}

/// Estilos de texto reutilizables (Google Fonts Outfit) para no repetir
/// los mismos parámetros en cada Text().
class _Styles {
  static TextStyle title(bool isMobile) => GoogleFonts.outfit(
        fontSize: isMobile ? 24 : 28,
        fontWeight: FontWeight.bold,
        color: _Palette.textDark,
      );

  static final subtitle = GoogleFonts.outfit(
    fontSize: 14,
    color: _Palette.textLight,
  );

  static final cardValue = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: _Palette.textDark,
  );

  static final cardLabel = GoogleFonts.outfit(
    fontSize: 14,
    color: _Palette.textLight,
  );

  static final sectionTitle = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: _Palette.textDark,
  );

  static final chartRowLabel = GoogleFonts.outfit(
    fontSize: 13,
    color: _Palette.textDark,
  );

  static final chartRowValue = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: _Palette.primary,
  );

  static final emptyState = GoogleFonts.outfit(
    fontSize: 13,
    color: _Palette.textFaint,
  );

  static final drawerName = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: _Palette.textDark,
  );

  static final drawerRole = GoogleFonts.outfit(
    fontSize: 12,
    color: _Palette.textGrey,
  );

  static TextStyle drawerItem(bool isActive) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        color: isActive ? _Palette.primary : _Palette.textDark,
      );

  static TextStyle footer(bool isMobile) => GoogleFonts.outfit(
        fontSize: isMobile ? 10 : 12,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      );
}

/// Entrada de menú: agrupa título, ícono y la vista a la que navega.
/// Un solo lugar para definir el menú del AppBar + Drawer + navegación.
class _MenuEntry {
  final String title;
  final IconData icon;
  final WidgetBuilder? viewBuilder; // null => se queda en el Dashboard

  const _MenuEntry(this.title, this.icon, [this.viewBuilder]);
}

/// Un item de métrica simple (tarjeta con ícono, valor y etiqueta).
class _MetricItem {
  final String label;
  final String value;
  final IconData icon;

  const _MetricItem(this.label, this.value, this.icon);
}

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const String _dashboardTitle = 'Dashboard';
  String _activeMenu = _dashboardTitle;

  static const List<String> _categoriasValidas = [
    'Playas / Cayos',
    'Montañas / Trekking',
    'Aventura / Ríos',
    'Cultura / Ciudades',
  ];

  static final List<_MenuEntry> _menu = [
    const _MenuEntry(_dashboardTitle, Icons.dashboard_outlined),
    _MenuEntry('Gestión', Icons.settings_outlined,
        (_) => const AdminManagementView()),
    _MenuEntry('Usuarios', Icons.people_outline,
        (_) => const AdminUsersView()),
    _MenuEntry('Reportes', Icons.bar_chart_outlined,
        (_) => const AdminReportsView()),
  ];

  // --- Estado de métricas ---
  int _totalOperadores = 0;
  int _totalEstudiantes = 0;
  int _totalDestinos = 0;
  int _totalReservas = 0;
  double _totalIngresos = 0;
  bool _cargando = true;

  List<MapEntry<String, int>> _topDestinos = [];
  Map<String, int> _destinosPorCategoria = {
    for (final cat in _categoriasValidas) cat: 0,
  };

  @override
  void initState() {
    super.initState();
    _cargarMetricas();
  }

  // ---------------------------------------------------------------------
  // Carga de datos
  // ---------------------------------------------------------------------

  Future<void> _cargarMetricas() async {
    try {
      final db = FirebaseFirestore.instance;

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

      final destinosInfo = _procesarDestinos(db, destinosSnap.docs);
      final reservasInfo = _procesarReservas(reservasSnap.docs, destinosInfo.nombrePorDestino);

      if (!mounted) return;
      setState(() {
        _totalEstudiantes = estudiantesSnap.docs.length;
        _totalOperadores = operadoresSnap.docs.length;
        _totalDestinos = destinosInfo.destinosActivos;
        _totalReservas = reservasSnap.docs.length;
        _totalIngresos = reservasInfo.ingresos;
        _topDestinos = reservasInfo.top5;
        _destinosPorCategoria = destinosInfo.conteoCategoria;
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Recorre los destinos: cuenta activos, agrupa por categoría y
  /// renueva automáticamente las fechas de publicación/inicio vencidas.
  _DestinosInfo _procesarDestinos(
    FirebaseFirestore db,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final nombrePorDestino = <String, String>{};
    final conteoCategoria = {for (final cat in _categoriasValidas) cat: 0};
    int destinosActivos = 0;

    final now = DateTime.now();
    final nuevaFecha = now.add(const Duration(days: 7));

    for (final doc in docs) {
      final data = doc.data();
      final activo = data['activo'] as bool? ?? false;
      final nombre = data['nombre'] as String? ?? 'Sin nombre';
      final categoria = data['categoria'] as String? ?? '';

      nombrePorDestino[doc.id] = nombre;
      if (activo) destinosActivos++;
      if (conteoCategoria.containsKey(categoria)) {
        conteoCategoria[categoria] = conteoCategoria[categoria]! + 1;
      }

      final updates = _fechasVencidasAActualizar(data, now, nuevaFecha);
      if (updates.isNotEmpty) {
        db.collection('destinos').doc(doc.id).update(updates);
      }
    }

    return _DestinosInfo(nombrePorDestino, conteoCategoria, destinosActivos);
  }

  /// Revisa `fechaPublicacion` y `fechaInicio`; si ya vencieron, arma un
  /// mapa de campos a actualizar con la nueva fecha.
  Map<String, dynamic> _fechasVencidasAActualizar(
    Map<String, dynamic> data,
    DateTime now,
    DateTime nuevaFecha,
  ) {
    final updates = <String, dynamic>{};

    for (final campo in ['fechaPublicacion', 'fechaInicio']) {
      final raw = data[campo];
      if (raw == null) continue;
      final fecha = DateTime.tryParse(raw.toString());
      if (fecha != null && fecha.isBefore(now)) {
        updates[campo] = nuevaFecha.toIso8601String();
      }
    }

    return updates;
  }

  /// Suma ingresos confirmados y calcula el top 5 de destinos con más
  /// reservas.
  _ReservasInfo _procesarReservas(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Map<String, String> nombrePorDestino,
  ) {
    double ingresos = 0;
    final reservasPorDestino = <String, int>{};

    for (final doc in docs) {
      final data = doc.data();
      final estado = data['estadoActual'] as String? ?? '';
      final paqueteId = data['paqueteId'] as String? ?? '';

      if (estado == 'pagado' || estado == 'disfrutado') {
        ingresos += (data['totalGeneral'] as num? ?? 0).toDouble();
      }
      if (paqueteId.isNotEmpty) {
        reservasPorDestino[paqueteId] = (reservasPorDestino[paqueteId] ?? 0) + 1;
      }
    }

    final ordenados = reservasPorDestino.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = ordenados.take(5).map((entry) {
      final nombre = nombrePorDestino[entry.key] ?? 'Destino eliminado';
      return MapEntry(nombre, entry.value);
    }).toList();

    return _ReservasInfo(ingresos, top5);
  }

  // ---------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------

  void _handleMenuSelected(String menuTitle) {
    final entry = _menu.firstWhere((e) => e.title == menuTitle);
    final builder = entry.viewBuilder;
    if (builder == null) return; // Dashboard: no navega a ningún lado

    Navigator.push(context, MaterialPageRoute(builder: builder));
  }

  void _handleEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminEditProfileView()),
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
      if (confirm != true) return;

      await Provider.of<AuthController>(context, listen: false).logout();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    });
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 850;

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
            menuItems: _menu.map((e) => e.title).toList(),
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

  // --- Drawer (menú lateral en móvil) ---

  Widget _buildDrawer() {
    final user = Provider.of<AuthController>(context).usuarioActual;
    final tieneFoto = user?.fotoBase64 != null && user!.fotoBase64!.isNotEmpty;

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
                        border: Border.all(color: _Palette.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: tieneFoto
                            ? Image.memory(
                                base64Decode(user!.fotoBase64!),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const CircleAvatar(
                                backgroundColor: _Palette.primaryLight,
                                child: Icon(Icons.admin_panel_settings,
                                    color: _Palette.primary, size: 28),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.nombre ?? 'Administrador',
                            style: _Styles.drawerName),
                        Text('Administrador', style: _Styles.drawerRole),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: _Palette.border),
            for (final entry in _menu)
              _buildDrawerItem(entry.title, entry.icon, () {
                Navigator.pop(context);
                if (entry.title != _dashboardTitle) {
                  _handleMenuSelected(entry.title);
                }
              }),
            const Spacer(),
            const Divider(height: 1, color: _Palette.border),
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
      leading: Icon(icon, color: _Palette.primary),
      title: Text(title, style: _Styles.drawerItem(isActive)),
      onTap: onTap,
    );
  }

  // --- Layouts ---

  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildMetricsContent(isMobile: true),
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

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5),
              ),
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildMetricsContent(isMobile: false),
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
        _buildCampusPanel(),
      ],
    );
  }

  Widget _buildCampusPanel() {
    return Container(
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
          color: _Palette.primaryLight,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 48, color: _Palette.primary),
                SizedBox(height: 8),
                Text('Imagen del Campus'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Contenido de métricas ---

  Widget _buildMetricsContent({required bool isMobile}) {
    final totalUsuarios = _totalEstudiantes + _totalOperadores;

    final metricItems = [
      _MetricItem('Total Usuarios', '$totalUsuarios', Icons.people),
      _MetricItem('Operadores', '$_totalOperadores', Icons.business),
      _MetricItem('Estudiantes', '$_totalEstudiantes', Icons.school),
      _MetricItem('Destinos Activos', '$_totalDestinos', Icons.tour),
      _MetricItem('Reservas', '$_totalReservas', Icons.receipt),
      _MetricItem(
        'Ingresos Confirmados',
        '\$${_totalIngresos.toStringAsFixed(2)}',
        Icons.attach_money,
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dashboard de Métricas', style: _Styles.title(isMobile)),
              IconButton(
                onPressed: () {
                  setState(() => _cargando = true);
                  _cargarMetricas();
                },
                icon: const Icon(Icons.refresh, color: _Palette.primary),
                tooltip: 'Actualizar métricas',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Datos en tiempo real de la plataforma SamanGo',
              style: _Styles.subtitle),
          const SizedBox(height: 24),
          _buildMetricsGrid(metricItems, perRow: isMobile ? 2 : 3),
          const SizedBox(height: 32),
          if (isMobile) ...[
            _buildTopDestinosChart(),
            const SizedBox(height: 24),
            _buildCategoriaChart(),
            const SizedBox(height: 16),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTopDestinosChart()),
                const SizedBox(width: 16),
                Expanded(child: _buildCategoriaChart()),
              ],
            ),
        ],
      ),
    );
  }

  /// Arma una grilla de tarjetas de métricas agrupadas en filas de
  /// [perRow] elementos, evitando repetir el layout para mobile/desktop.
  Widget _buildMetricsGrid(List<_MetricItem> items, {required int perRow}) {
    final spacing = perRow == 2 ? 12.0 : 16.0;
    final rows = <Widget>[];

    for (var i = 0; i < items.length; i += perRow) {
      final rowItems = items.skip(i).take(perRow).toList();
      rows.add(
        Row(
          children: [
            for (var j = 0; j < rowItems.length; j++) ...[
              if (j > 0) SizedBox(width: spacing),
              Expanded(child: _buildMetricCard(rowItems[j])),
            ],
          ],
        ),
      );
      if (i + perRow < items.length) rows.add(SizedBox(height: spacing));
    }

    return Column(children: rows);
  }

  Widget _buildMetricCard(_MetricItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.border, width: 1),
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
              color: _Palette.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: _Palette.primary, size: 24),
          ),
          const SizedBox(height: 12),
          _cargando
              ? const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _Palette.primary),
                )
              : Text(item.value, style: _Styles.cardValue),
          const SizedBox(height: 4),
          Text(item.label, style: _Styles.cardLabel),
        ],
      ),
    );
  }

  // --- Gráficos ---

  Widget _buildTopDestinosChart() {
    return _ChartCard(
      title: 'Destinos más populares',
      isLoading: _cargando,
      isEmpty: _topDestinos.isEmpty,
      emptyMessage: 'Aún no hay reservas registradas',
      child: Column(children: _buildBarrasDestinos()),
    );
  }

  List<Widget> _buildBarrasDestinos() {
    if (_topDestinos.isEmpty) return [];
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
                    style: _Styles.chartRowLabel,
                  ),
                ),
                Text('${entry.value}', style: _Styles.chartRowValue),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: proporcion,
                minHeight: 10,
                backgroundColor: _Palette.border,
                color: _Palette.primary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildCategoriaChart() {
    final total = _destinosPorCategoria.values.fold<int>(0, (a, b) => a + b);
    final entries = _destinosPorCategoria.entries.toList();

    return _ChartCard(
      title: 'Destinos por categoría',
      isLoading: _cargando,
      isEmpty: total == 0,
      emptyMessage: 'Aún no hay destinos registrados',
      child: Column(
        children: [
          SizedBox(
            height: 160,
            width: 160,
            child: CustomPaint(
              painter: _PieChartPainter(
                valores: _destinosPorCategoria.values.toList(),
                colores: _Palette.categoryColors,
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _Palette.categoryColors[i % _Palette.categoryColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entries[i].key,
                      overflow: TextOverflow.ellipsis,
                      style: _Styles.chartRowLabel,
                    ),
                  ),
                  Text('${entries[i].value}', style: _Styles.chartRowValue),
                ],
              ),
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
        color: _Palette.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Center(
        child: Text(
          '© 2026 SamanGo. Todos los derechos reservados. Comunidad UNIMET.',
          textAlign: TextAlign.center,
          style: _Styles.footer(isMobile),
        ),
      ),
    );
  }
}

/// Contenedor genérico para las tarjetas de gráficos: maneja los 3 estados
/// (cargando / vacío / con datos) para no repetirlos en cada gráfico.
class _ChartCard extends StatelessWidget {
  final String title;
  final bool isLoading;
  final bool isEmpty;
  final String emptyMessage;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.isLoading,
    required this.isEmpty,
    required this.emptyMessage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Palette.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _Styles.sectionTitle),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: _Palette.primary),
              ),
            )
          else if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(emptyMessage, style: _Styles.emptyState),
            )
          else
            child,
        ],
      ),
    );
  }
}

/// Resultado intermedio del procesamiento de destinos.
class _DestinosInfo {
  final Map<String, String> nombrePorDestino;
  final Map<String, int> conteoCategoria;
  final int destinosActivos;

  const _DestinosInfo(this.nombrePorDestino, this.conteoCategoria, this.destinosActivos);
}

/// Resultado intermedio del procesamiento de reservas.
class _ReservasInfo {
  final double ingresos;
  final List<MapEntry<String, int>> top5;

  const _ReservasInfo(this.ingresos, this.top5);
}

class _PieChartPainter extends CustomPainter {
  final List<int> valores;
  final List<Color> colores;

  _PieChartPainter({required this.valores, required this.colores});

  @override
  void paint(Canvas canvas, Size size) {
    final total = valores.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    double anguloInicial = -90 * (math.pi / 180);

    for (int i = 0; i < valores.length; i++) {
      final valor = valores[i];
      if (valor == 0) continue;

      final porcentaje = valor / total;
      final anguloBarrido = porcentaje * 2 * math.pi;

      final paint = Paint()
        ..color = colores[i % colores.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, anguloInicial, anguloBarrido, true, paint);
      anguloInicial += anguloBarrido;
    }

    final centro = Offset(size.width / 2, size.height / 2);
    final radioInterno = size.width * 0.28;
    canvas.drawCircle(centro, radioInterno, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.valores != valores || oldDelegate.colores != colores;
  }
}