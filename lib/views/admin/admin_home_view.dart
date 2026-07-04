// Dashboard del administrador con métricas reales traídas de Firestore
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import 'admin_theme.dart';
import '../shared/app_header.dart';
import '../shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'admin_edit_profile_view.dart';
import 'admin_management_view.dart';
import 'admin_reports_view.dart';
import 'admin_users_view.dart';

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

  static final List<AdminMenuEntry> _menu = [
    const AdminMenuEntry(_dashboardTitle, Icons.dashboard_outlined),
    AdminMenuEntry('Gestión', Icons.settings_outlined, (_) => const AdminManagementView()),
    AdminMenuEntry('Usuarios', Icons.people_outline, (_) => const AdminUsersView()),
    AdminMenuEntry('Reportes', Icons.bar_chart_outlined, (_) => const AdminReportsView()),
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEditProfileView()));
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
    });
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 850;
    final user = Provider.of<AuthController>(context).usuarioActual;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: isMobile
          ? AdminDrawer(
              menu: _menu,
              activeMenu: _activeMenu,
              userName: user?.nombre,
              userFotoBase64: user?.fotoBase64,
              onEditProfile: _handleEditProfile,
              onLogout: _handleLogout,
              onMenuSelected: _handleMenuSelected,
            )
          : null,
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
          Expanded(child: isMobile ? _buildMobileLayout() : _buildDesktopLayout()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(children: [const SizedBox(height: 16), _buildMetricsContent(isMobile: true)]),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(children: [const Spacer(), _buildFooter(true)]),
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
              border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5)),
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(children: [const SizedBox(height: 16), _buildMetricsContent(isMobile: false)]),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(children: [const Spacer(), _buildFooter(false)]),
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
        border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5)),
      ),
      child: Image.asset(
        'assets/images/campus_admin.png',
        width: 320,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AdminPalette.primaryLight,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 48, color: AdminPalette.primary),
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
      _MetricItem('Ingresos Confirmados', '\$${_totalIngresos.toStringAsFixed(2)}', Icons.attach_money),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'Dashboard de Métricas',
            isMobile: isMobile,
            trailing: _buildRefreshButton(),
          ),
          const SizedBox(height: 8),
          Text('Datos en tiempo real de la plataforma SamanGo', style: AdminStyles.subtitle),
          const SizedBox(height: 24),
          _buildMetricsGrid(metricItems, perRow: isMobile ? 2 : 3),
          const SizedBox(height: 32),
          if (isMobile) ...[
            _buildTopDestinosChart(),
            const SizedBox(height: 24),
            _buildCategoriaChart(),
            const SizedBox(height: 16),
          ] else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildTopDestinosChart()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCategoriaChart()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Material(
      color: AdminPalette.cloud,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          setState(() => _cargando = true);
          _cargarMetricas();
        },
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.refresh_rounded, color: AdminPalette.primary, size: 20),
        ),
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
              Expanded(child: _buildMetricCard(rowItems[j], colorIndex: i + j)),
            ],
          ],
        ),
      );
      if (i + perRow < items.length) rows.add(SizedBox(height: spacing));
    }

    return Column(children: rows);
  }

  Widget _buildMetricCard(_MetricItem item, {required int colorIndex}) {
    final accent = AdminPalette.chartColors[colorIndex % AdminPalette.chartColors.length];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminPalette.line, width: 1),
        boxShadow: [AdminPalette.softShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: accent.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(item.icon, color: accent, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _cargando
              ? SizedBox(
                  height: 26,
                  width: 26,
                  child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                )
              : Text(item.value, style: AdminStyles.cardValue),
          const SizedBox(height: 4),
          Text(item.label, style: AdminStyles.cardLabel),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(height: 3, color: accent.withOpacity(0.85)),
          ),
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
      emptyIcon: Icons.map_outlined,
      emptyMessage: 'Aún no hay reservas registradas',
      child: _TopDestinosRanking(destinos: _topDestinos),
    );
  }

  Widget _buildCategoriaChart() {
    final total = _destinosPorCategoria.values.fold<int>(0, (a, b) => a + b);

    return _ChartCard(
      title: 'Destinos por categoría',
      isLoading: _cargando,
      isEmpty: total == 0,
      emptyIcon: Icons.donut_large_outlined,
      emptyMessage: 'Aún no hay destinos registrados',
      child: _CategoryDonut(data: _destinosPorCategoria),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
      decoration: const BoxDecoration(
        gradient: AdminPalette.gradient,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Center(
        child: Text(
          '© 2026 SamanGo. Todos los derechos reservados. Comunidad UNIMET.',
          textAlign: TextAlign.center,
          style: AdminStyles.footer(isMobile),
        ),
      ),
    );
  }
}

// ===========================================================================
// Widgets de soporte (gráficos y contenedores)
// ===========================================================================

/// Contenedor genérico para las tarjetas de gráficos: maneja los 3 estados
/// (cargando / vacío / con datos) para no repetirlos en cada gráfico.
class _ChartCard extends StatelessWidget {
  final String title;
  final bool isLoading;
  final bool isEmpty;
  final IconData emptyIcon;
  final String emptyMessage;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.isLoading,
    required this.isEmpty,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AdminPalette.cloud, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AdminStyles.cardTitle),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AdminPalette.primary),
              ),
            )
          else if (isEmpty)
            AdminEmptyState(icon: emptyIcon, message: emptyMessage, padding: const EdgeInsets.symmetric(vertical: 16))
          else
            child,
        ],
      ),
    );
  }
}

/// Ranking de los 5 destinos con más reservas. En vez de solo una medalla
/// numerada, el top 3 ahora luce un ícono de trofeo/podio y cada barra
/// muestra también el porcentaje relativo frente al destino líder.
class _TopDestinosRanking extends StatelessWidget {
  final List<MapEntry<String, int>> destinos;

  const _TopDestinosRanking({required this.destinos});

  @override
  Widget build(BuildContext context) {
    if (destinos.isEmpty) return const SizedBox.shrink();
    final maxCantidad = destinos.first.value;

    return Column(
      children: [
        for (var i = 0; i < destinos.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == destinos.length - 1 ? 0 : 16),
            child: _DestinoRow(
              rank: i + 1,
              nombre: destinos[i].key,
              cantidad: destinos[i].value,
              proporcion: maxCantidad == 0 ? 0.0 : destinos[i].value / maxCantidad,
            ),
          ),
      ],
    );
  }
}

class _DestinoRow extends StatelessWidget {
  final int rank;
  final String nombre;
  final int cantidad;
  final double proporcion;

  const _DestinoRow({required this.rank, required this.nombre, required this.cantidad, required this.proporcion});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _RankMedal(rank: rank),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(nombre, overflow: TextOverflow.ellipsis, style: AdminStyles.chartRowLabel),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$cantidad', style: AdminStyles.chartRowValue),
                      const SizedBox(width: 4),
                      Text('(${(proporcion * 100).round()}%)',
                          style: GoogleFonts.outfit(fontSize: 11, color: AdminPalette.mist)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Container(height: 10, color: Colors.white),
                    FractionallySizedBox(
                      widthFactor: proporcion.clamp(0.04, 1.0),
                      child: Container(height: 10, decoration: const BoxDecoration(gradient: AdminPalette.gradient)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Medalla/insignia de posición: el top 3 ahora muestra un ícono de
/// trofeo sobre un fondo en degradado con el color correspondiente
/// (oro/plata/bronce), en vez de solo un número dentro de un círculo.
class _RankMedal extends StatelessWidget {
  final int rank;

  const _RankMedal({required this.rank});

  static const _medals = {
    1: Color(0xFFF3B23B),
    2: Color(0xFFAEB6C2),
    3: Color(0xFFC98A54),
  };

  @override
  Widget build(BuildContext context) {
    final color = _medals[rank];

    if (color == null) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: Center(
          child: Text('$rank',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AdminPalette.slate)),
        ),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: const Center(
        child: Icon(Icons.emoji_events, size: 15, color: Colors.white),
      ),
    );
  }
}

/// Resumen de categorías: el total ahora se muestra como cifra
/// protagonista arriba, seguido de un medidor en forma de arco (media
/// luna) con un segmento por categoría, en vez del donut completo de
/// antes. La leyenda en píldoras se mantiene debajo.
class _CategoryDonut extends StatelessWidget {
  final Map<String, int> data;

  const _CategoryDonut({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (a, b) => a + b);
    final entries = data.entries.toList();

    return Column(
      children: [
        Text('$total', style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.bold, color: AdminPalette.ink)),
        Text('destinos registrados', style: GoogleFonts.outfit(fontSize: 12, color: AdminPalette.mist)),
        const SizedBox(height: 14),
        SizedBox(
          height: 108,
          width: 230,
          child: CustomPaint(
            size: const Size(230, 108),
            painter: _CategoryGaugePainter(valores: data.values.toList(), colores: AdminPalette.chartColors),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < entries.length; i++)
              _LegendChip(
                color: AdminPalette.chartColors[i % AdminPalette.chartColors.length],
                label: entries[i].key,
                value: entries[i].value,
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendChip({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 6),
          Text('$label ($value)', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AdminPalette.ink)),
        ],
      ),
    );
  }
}

/// Pinta un medidor en forma de media luna (arco de 180°): cada categoría
/// es un segmento con un pequeño espacio respecto al siguiente y puntas
/// redondeadas, igual que el donut anterior pero abierto en vez de
/// cerrado en círculo completo.
class _CategoryGaugePainter extends CustomPainter {
  final List<int> valores;
  final List<Color> colores;

  _CategoryGaugePainter({required this.valores, required this.colores});

  static const _gap = 0.05; // radianes de separación entre segmentos

  @override
  void paint(Canvas canvas, Size size) {
    final total = valores.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;

    final strokeWidth = size.width * 0.13;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, strokeWidth / 2 + radius * 0.02);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Arco de 180°: arranca apuntando a la izquierda (9 en punto) y
    // recorre por abajo hasta apuntar a la derecha (3 en punto).
    double anguloInicial = math.pi;

    for (var i = 0; i < valores.length; i++) {
      final valor = valores[i];
      final anguloCompleto = (valor / total) * math.pi;
      if (valor > 0) {
        final sweep = math.max(anguloCompleto - _gap, 0.0);
        final paint = Paint()
          ..color = colores[i % colores.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(rect, anguloInicial, sweep, false, paint);
      }
      anguloInicial += anguloCompleto;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryGaugePainter oldDelegate) {
    return oldDelegate.valores != valores || oldDelegate.colores != colores;
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