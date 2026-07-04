import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../auth/login_view.dart';
import 'admin_theme.dart';
import '../shared/app_header.dart';
import '../shared/widgets/custom_dialog.dart';
import 'admin_edit_profile_view.dart';
import 'admin_home_view.dart';
import 'admin_reports_view.dart';
import 'admin_users_view.dart';

// ===========================================================================
// Repositorio genérico para colecciones tipo "catálogo" (hospedajes,
// transportes, y cualquier otra con la forma categoria/activo/[capacidad]).
// ===========================================================================

class _CatalogRepository {
  final String collectionName;
  const _CatalogRepository(this.collectionName);

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection(collectionName);

  Stream<QuerySnapshot<Map<String, dynamic>>> streamOrdenado() {
    return _ref.orderBy('fechaCreacion', descending: true).snapshots();
  }

  Future<bool> categoriaExiste(String categoria, {String? excludeId}) async {
    final snapshot = await _ref.where('categoria', isEqualTo: categoria).get();
    return snapshot.docs.any((doc) => doc.id != excludeId);
  }

  Future<void> agregar({required String categoria, required bool activo, int? capacidad}) {
    final data = <String, dynamic>{
      'categoria': categoria,
      'activo': activo,
      'fechaCreacion': FieldValue.serverTimestamp(),
    };
    if (capacidad != null) data['capacidad'] = capacidad;
    return _ref.add(data);
  }

  Future<void> actualizar(String id, {required String categoria, required bool activo, int? capacidad}) {
    final data = <String, dynamic>{'categoria': categoria, 'activo': activo};
    if (capacidad != null) data['capacidad'] = capacidad;
    return _ref.doc(id).update(data);
  }

  Future<void> toggleActivo(String id, bool nuevoEstado) => _ref.doc(id).update({'activo': nuevoEstado});
  Future<void> eliminar(String id) => _ref.doc(id).delete();
}

// ===========================================================================
// Widgets de UI propios de esta vista
// ===========================================================================

/// Campo de texto con la decoración estándar de los formularios admin.
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.onChanged,
  });

  static OutlineInputBorder _border(Color color, {double width = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.outfit(fontSize: 14, color: AdminPalette.slate),
        hintStyle: GoogleFonts.outfit(fontSize: 14, color: AdminPalette.mist),
        border: _border(AdminPalette.line),
        enabledBorder: _border(AdminPalette.line),
        focusedBorder: _border(AdminPalette.primary, width: 1.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

/// Diálogo genérico de agregar/editar para cualquier catálogo. Cuando
/// [hasCapacidad] es true, muestra también el campo de capacidad.
///
/// [onSubmit] hace la validación + escritura en Firestore y devuelve
/// `true` si debe cerrarse el diálogo, o `false` si debe permanecer
/// abierto (por ejemplo, porque la categoría ya existe).
class _CatalogFormDialog extends StatefulWidget {
  final String title;
  final IconData icon;
  final String submitLabel;
  final String categoriaHint;
  final bool hasCapacidad;
  final String initialCategoria;
  final int? initialCapacidad;
  final bool initialActivo;
  final Future<bool> Function(String categoria, int? capacidad, bool activo) onSubmit;

  const _CatalogFormDialog({
    required this.title,
    required this.icon,
    required this.submitLabel,
    required this.categoriaHint,
    required this.hasCapacidad,
    required this.onSubmit,
    this.initialCategoria = '',
    this.initialCapacidad,
    this.initialActivo = true,
  });

  @override
  State<_CatalogFormDialog> createState() => _CatalogFormDialogState();
}

class _CatalogFormDialogState extends State<_CatalogFormDialog> {
  late final TextEditingController _categoriaController = TextEditingController(text: widget.initialCategoria);
  late final TextEditingController _capacidadController =
      TextEditingController(text: widget.initialCapacidad?.toString() ?? '');
  late bool _activo = widget.initialActivo;
  bool _submitting = false;

  @override
  void dispose() {
    _categoriaController.dispose();
    _capacidadController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final capacidad = widget.hasCapacidad ? int.tryParse(_capacidadController.text.trim()) : null;
    final shouldClose = await widget.onSubmit(_categoriaController.text.trim(), capacidad, _activo);

    if (!mounted) return;
    setState(() => _submitting = false);
    if (shouldClose) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(gradient: AdminPalette.gradient, shape: BoxShape.circle),
              child: Icon(widget.icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 12),
            Text(widget.title,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AdminPalette.ink)),
            const SizedBox(height: 16),
            _FormField(
              controller: _categoriaController,
              label: 'Categoría',
              hint: widget.categoriaHint,
              onChanged: (_) => setState(() {}),
            ),
            if (widget.hasCapacidad) ...[
              const SizedBox(height: 16),
              _FormField(
                controller: _capacidadController,
                label: 'Capacidad',
                hint: 'Ej: 40',
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AdminPalette.cloud, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Text('Activo', style: GoogleFonts.outfit(fontSize: 15, color: AdminPalette.ink)),
                  const Spacer(),
                  Switch(
                    value: _activo,
                    onChanged: (value) => setState(() => _activo = value),
                    activeColor: AdminPalette.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminPalette.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.submitLabel, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AdminPalette.cloud,
                      foregroundColor: AdminPalette.slate,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      side: BorderSide.none,
                    ),
                    child: Text('Cancelar', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de un ítem de catálogo (antes era una fila de ancho completo;
/// ahora es una tarjeta compacta que en desktop se acomoda en grilla y en
/// mobile se apila, para que la sección no se sienta como una sola lista
/// larga y vertical). El punto de color a la izquierda del nombre indica
/// el estado (verde=activo, rojo=inactivo).
class _CatalogCard extends StatelessWidget {
  final int index;
  final String categoria;
  final int? capacidad;
  final bool activo;
  final bool isMobile;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CatalogCard({
    required this.index,
    required this.categoria,
    required this.capacidad,
    required this.activo,
    required this.isMobile,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final estadoColor = activo ? AdminPalette.success : AdminPalette.danger;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminPalette.line),
        boxShadow: [AdminPalette.softShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: estadoColor)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  categoria,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AdminPalette.ink, fontSize: 14),
                ),
              ),
              Text('#${index + 1}', style: GoogleFonts.outfit(fontSize: 11, color: AdminPalette.mist)),
            ],
          ),
          if (capacidad != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.groups_outlined, size: 14, color: AdminPalette.slate),
                const SizedBox(width: 6),
                Text('Capacidad: $capacidad', style: GoogleFonts.outfit(fontSize: 12, color: AdminPalette.slate)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AdminStatusBadge(
                  label: activo ? 'Activo' : 'Inactivo',
                  color: estadoColor,
                  icon: activo ? Icons.check_circle_outline : Icons.block,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, color: AdminPalette.primary, size: 18),
                    tooltip: 'Editar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: AdminPalette.danger, size: 18),
                    tooltip: 'Eliminar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Vista principal
// ===========================================================================

class AdminManagementView extends StatefulWidget {
  const AdminManagementView({super.key});

  @override
  State<AdminManagementView> createState() => _AdminManagementViewState();
}

class _AdminManagementViewState extends State<AdminManagementView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const String _activeMenu = 'Gestión';

  static final List<AdminMenuEntry> _menu = [
    AdminMenuEntry('Dashboard', Icons.dashboard_outlined, (_) => const AdminHomeView(), true),
    const AdminMenuEntry(_activeMenu, Icons.settings_outlined), // vista actual
    AdminMenuEntry('Usuarios', Icons.people_outline, (_) => const AdminUsersView()),
    AdminMenuEntry('Reportes', Icons.bar_chart_outlined, (_) => const AdminReportsView()),
  ];

  static const _hospedajesRepo = _CatalogRepository('hospedajes');
  static const _transportesRepo = _CatalogRepository('transportes');

  // --- Navegación y acciones comunes ---

  void _handleMenuSelected(String menuTitle) {
    final entry = _menu.firstWhere((e) => e.title == menuTitle);
    final builder = entry.viewBuilder;
    if (builder == null) return;

    if (entry.replace) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: builder));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: builder));
    }
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
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
    });
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje),
      backgroundColor: AdminPalette.primary,
      duration: const Duration(seconds: 2),
    ));
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  // --- CRUD genérico de catálogos ---

  Future<void> _showFormDialog({
    required _CatalogRepository repo,
    required String itemLabel,
    required bool hasCapacidad,
    required String categoriaHint,
    String? editingId,
    String initialCategoria = '',
    int? initialCapacidad,
    bool initialActivo = true,
  }) {
    final isEditing = editingId != null;

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CatalogFormDialog(
        title: isEditing ? 'Editar $itemLabel' : 'Agregar $itemLabel',
        icon: isEditing ? Icons.edit : Icons.add,
        submitLabel: isEditing ? 'Actualizar' : 'Agregar',
        categoriaHint: categoriaHint,
        hasCapacidad: hasCapacidad,
        initialCategoria: initialCategoria,
        initialCapacidad: initialCapacidad,
        initialActivo: initialActivo,
        onSubmit: (categoria, capacidad, activo) async {
          if (categoria.isEmpty) {
            _mostrarMensaje('Ingresa una categoría');
            return false;
          }
          if (hasCapacidad && (capacidad == null || capacidad <= 0)) {
            _mostrarMensaje('Ingresa una capacidad válida mayor a 0');
            return false;
          }

          try {
            final existe = await repo.categoriaExiste(categoria, excludeId: editingId);
            if (existe) {
              _mostrarMensaje('La categoría "$categoria" ya existe');
              return false;
            }

            if (isEditing) {
              await repo.actualizar(editingId, categoria: categoria, activo: activo, capacidad: capacidad);
              _mostrarMensaje('$itemLabel actualizado correctamente');
            } else {
              await repo.agregar(categoria: categoria, activo: activo, capacidad: capacidad);
              _mostrarMensaje('$itemLabel agregado correctamente');
            }

            if (mounted) setState(() {});
            return true;
          } catch (e) {
            _mostrarMensaje('Error: $e');
            return false;
          }
        },
      ),
    );
  }

  Future<void> _confirmToggle(
    _CatalogRepository repo,
    String id,
    String categoria,
    bool activoActual,
    String itemLabel,
  ) async {
    final nuevoEstado = !activoActual;
    final accion = nuevoEstado ? 'Activar' : 'Inactivar';

    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: '$accion $itemLabel',
      message: '¿Estás seguro de que deseas ${accion.toLowerCase()} "$categoria"?',
      confirmText: 'Confirmar',
      icon: nuevoEstado ? Icons.check_circle : Icons.block,
    );
    if (confirm != true) return;

    try {
      await repo.toggleActivo(id, nuevoEstado);
      _mostrarMensaje('$itemLabel ${nuevoEstado ? 'activado' : 'inactivado'} correctamente');
      setState(() {});
    } catch (e) {
      _mostrarMensaje('Error al cambiar el estado: $e');
    }
  }

  Future<void> _confirmDelete(_CatalogRepository repo, String id, String categoria, String itemLabel) async {
    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: 'Eliminar $itemLabel',
      message: '¿Estás seguro de que deseas eliminar "$categoria"?',
      confirmText: 'Eliminar',
      icon: Icons.delete,
    );
    if (confirm != true) return;

    try {
      await repo.eliminar(id);
      _mostrarMensaje('$itemLabel eliminado correctamente');
    } catch (e) {
      _mostrarMensaje('Error al eliminar: $e');
    }
  }

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
          AdminFooter(isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          AdminSectionHeader(title: 'Gestión de Tablas', isMobile: true),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(children: _buildTables(isMobile: true)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionHeader(title: 'Gestión de Tablas', isMobile: false),
            const SizedBox(height: 24),
            ..._buildTables(isMobile: false),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTables({required bool isMobile}) {
    return [
      _buildCatalogTable(
        repo: _hospedajesRepo,
        titulo: 'Tipos de Hospedaje',
        itemLabel: 'Hospedaje',
        categoriaHint: 'Ej: Hotel, Posada, etc.',
        hasCapacidad: false,
        emptyIcon: Icons.hotel_outlined,
        emptyMessage: 'No hay hospedajes registrados',
        isMobile: isMobile,
      ),
      const SizedBox(height: 32),
      _buildCatalogTable(
        repo: _transportesRepo,
        titulo: 'Tipos de Transporte',
        itemLabel: 'Transporte',
        categoriaHint: 'Ej: Bus, Avión, etc.',
        hasCapacidad: true,
        emptyIcon: Icons.directions_bus_outlined,
        emptyMessage: 'No hay transportes registrados',
        isMobile: isMobile,
      ),
      const SizedBox(height: 40),
    ];
  }

  /// Construye una tabla de catálogo completa: header con botón de agregar
  /// + lista en tiempo real desde Firestore, mostrada como grilla de
  /// tarjetas en desktop y apilada en mobile.
  Widget _buildCatalogTable({
    required _CatalogRepository repo,
    required String titulo,
    required String itemLabel,
    required String categoriaHint,
    required bool hasCapacidad,
    required IconData emptyIcon,
    required String emptyMessage,
    required bool isMobile,
  }) {
    return Container(
      decoration: AdminPalette.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: const BoxDecoration(color: AdminPalette.cloud),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: AdminStyles.tableTitle(isMobile)),
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(
                    repo: repo,
                    itemLabel: itemLabel,
                    hasCapacidad: hasCapacidad,
                    categoriaHint: categoriaHint,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('Añadir', style: GoogleFonts.outfit(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminPalette.primary,
                    foregroundColor: Colors.white,
                    padding: isMobile
                        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                        : const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: repo.streamOrdenado(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: AdminPalette.primary)),
                );
              }
              if (snapshot.hasError) {
                return Padding(padding: const EdgeInsets.all(16), child: Center(child: Text('Error: ${snapshot.error}')));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return AdminEmptyState(icon: emptyIcon, message: emptyMessage);
              }

              return Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: _buildCardsFor(
                  docs: docs,
                  hasCapacidad: hasCapacidad,
                  isMobile: isMobile,
                  repo: repo,
                  itemLabel: itemLabel,
                  categoriaHint: categoriaHint,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// En mobile se apilan en una columna (una por fila, como antes). En
  /// desktop se acomodan en un `Wrap` de tarjetas de ancho fijo, así se
  /// leen varias por fila en vez de una única lista vertical larga.
  Widget _buildCardsFor({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required bool hasCapacidad,
    required bool isMobile,
    required _CatalogRepository repo,
    required String itemLabel,
    required String categoriaHint,
  }) {
    final cards = docs.asMap().entries.map((entry) {
      final index = entry.key;
      final doc = entry.value;
      final data = doc.data();
      final categoria = data['categoria'] as String? ?? 'Sin nombre';
      final activo = data['activo'] as bool? ?? true;
      final capacidad = hasCapacidad ? (data['capacidad'] as num? ?? 0).toInt() : null;

      return _CatalogCard(
        index: index,
        categoria: categoria,
        capacidad: capacidad,
        activo: activo,
        isMobile: isMobile,
        onToggle: () => _confirmToggle(repo, doc.id, categoria, activo, itemLabel),
        onEdit: () => _showFormDialog(
          repo: repo,
          itemLabel: itemLabel,
          hasCapacidad: hasCapacidad,
          categoriaHint: categoriaHint,
          editingId: doc.id,
          initialCategoria: categoria,
          initialCapacidad: capacidad,
          initialActivo: activo,
        ),
        onDelete: () => _confirmDelete(repo, doc.id, categoria, itemLabel),
      );
    }).toList();

    if (isMobile) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            cards[i],
          ],
        ],
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [for (final card in cards) SizedBox(width: 300, child: card)],
    );
  }
}