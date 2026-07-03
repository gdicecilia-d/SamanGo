import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../controllers/auth_controller.dart';
import '../auth/login_view.dart';
import '../shared/app_header.dart';
import '../shared/widgets/custom_dialog.dart';
import 'admin_edit_profile_view.dart';
import 'admin_home_view.dart';
import 'admin_reports_view.dart';
import 'admin_users_view.dart';

/// Paleta y estilos compartidos del módulo admin.
/// Nota: esta clase ya se repite en admin_home_view.dart — cuando terminemos
/// los demás archivos, vale la pena moverla a un solo lugar
/// (p. ej. views/shared/admin_theme.dart) para no mantener dos copias.
class _Palette {
  static const primary = Color(0xFFFC6707);
  static const primaryLight = Color(0xFFFDDBB3);
  static const textDark = Color(0xFF333333);
  static const textGrey = Color(0xFF666666);
  static const textFaint = Color(0xFF999999);
  static const border = Color(0xFFE0E0E0);
  static const green = Color(0xFF4CAF50);
  static const red = Color(0xFFF44336);
}

class _Styles {
  static TextStyle title(bool isMobile) => GoogleFonts.outfit(
        fontSize: isMobile ? 24 : 28,
        fontWeight: FontWeight.bold,
        color: _Palette.textDark,
      );

  static TextStyle sectionTitle(bool isMobile) => GoogleFonts.outfit(
        fontSize: isMobile ? 16 : 20,
        fontWeight: FontWeight.bold,
        color: _Palette.textDark,
      );

  static final emptyState = GoogleFonts.outfit(
    fontSize: 14,
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
}

/// Entrada de menú: título, ícono y la vista a la que navega.
/// [replace] indica si la navegación debe reemplazar la pantalla actual
/// (usado para "Dashboard", que vive fuera de esta pila de navegación).
class _MenuEntry {
  final String title;
  final IconData icon;
  final WidgetBuilder? viewBuilder;
  final bool replace;

  const _MenuEntry(this.title, this.icon, [this.viewBuilder, this.replace = false]);
}

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

  Future<void> agregar({
    required String categoria,
    required bool activo,
    int? capacidad,
  }) {
    final data = <String, dynamic>{
      'categoria': categoria,
      'activo': activo,
      'fechaCreacion': FieldValue.serverTimestamp(),
    };
    if (capacidad != null) data['capacidad'] = capacidad;
    return _ref.add(data);
  }

  Future<void> actualizar(
    String id, {
    required String categoria,
    required bool activo,
    int? capacidad,
  }) {
    final data = <String, dynamic>{'categoria': categoria, 'activo': activo};
    if (capacidad != null) data['capacidad'] = capacidad;
    return _ref.doc(id).update(data);
  }

  Future<void> toggleActivo(String id, bool nuevoEstado) {
    return _ref.doc(id).update({'activo': nuevoEstado});
  }

  Future<void> eliminar(String id) => _ref.doc(id).delete();
}

// ===========================================================================
// Widgets reutilizables de UI
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

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
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
        labelStyle: GoogleFonts.outfit(fontSize: 14, color: _Palette.textGrey),
        hintStyle: GoogleFonts.outfit(fontSize: 14, color: _Palette.textFaint),
        border: _border(_Palette.border),
        enabledBorder: _border(_Palette.border),
        focusedBorder: _border(_Palette.primary, width: 1.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

/// Diálogo genérico de agregar/editar para cualquier catálogo
/// (hospedajes, transportes...). Cuando [hasCapacidad] es true, muestra
/// también el campo de capacidad.
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
  late final TextEditingController _categoriaController =
      TextEditingController(text: widget.initialCategoria);
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

    final capacidad = widget.hasCapacidad
        ? int.tryParse(_capacidadController.text.trim())
        : null;

    final shouldClose = await widget.onSubmit(
      _categoriaController.text.trim(),
      capacidad,
      _activo,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    if (shouldClose) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: _Palette.primary, size: 40),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _Palette.textDark,
              ),
            ),
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
            Row(
              children: [
                Text('Activo',
                    style: GoogleFonts.outfit(fontSize: 16, color: _Palette.textDark)),
                const Spacer(),
                Switch(
                  value: _activo,
                  onChanged: (value) => setState(() => _activo = value),
                  activeColor: _Palette.primary,
                ),
              ],
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
                      backgroundColor: _Palette.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(widget.submitLabel,
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                      foregroundColor: _Palette.textGrey,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      side: BorderSide.none,
                    ),
                    child: Text('Cancelar',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
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

/// Badge de estado (Activo/Inactivo) que además actúa como botón para
/// alternar el estado al tocarlo.
class _StatusPill extends StatelessWidget {
  final bool activo;
  final bool isMobile;
  final VoidCallback onTap;

  const _StatusPill({required this.activo, required this.isMobile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = activo ? _Palette.green : _Palette.red;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            SizedBox(width: isMobile ? 2 : 4),
            Text(
              activo ? 'Activo' : 'Inactivo',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 9 : 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de una tabla de catálogo. Si [capacidad] es null, esa columna no
/// se muestra (caso de hospedajes, que no tienen capacidad).
class _CatalogRow extends StatelessWidget {
  final int index;
  final String categoria;
  final int? capacidad;
  final bool activo;
  final bool isMobile;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CatalogRow({
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
    final nombreStyle = GoogleFonts.outfit(
      fontWeight: FontWeight.w500,
      color: _Palette.textDark,
      fontSize: isMobile ? 13 : 14,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
      child: Row(
        children: [
          Text(
            '${index + 1}',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w500,
              color: _Palette.textGrey,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 16),
          Expanded(
            flex: capacidad != null ? 2 : 1,
            child: Text(categoria, style: nombreStyle),
          ),
          if (capacidad != null)
            Expanded(flex: 1, child: Text('$capacidad', style: nombreStyle)),
          _StatusPill(activo: activo, isMobile: isMobile, onTap: onToggle),
          SizedBox(width: isMobile ? 4 : 8),
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit, color: _Palette.primary, size: isMobile ? 16 : 18),
            tooltip: 'Editar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete, color: _Palette.red, size: isMobile ? 16 : 18),
            tooltip: 'Eliminar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: const Color(0xFFCCCCCC)),
            const SizedBox(height: 12),
            Text(message, style: _Styles.emptyState),
          ],
        ),
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

  static final List<_MenuEntry> _menu = [
    _MenuEntry('Dashboard', Icons.dashboard_outlined, (_) => const AdminHomeView(), true),
    const _MenuEntry(_activeMenu, Icons.settings_outlined), // vista actual
    _MenuEntry('Usuarios', Icons.people_outline, (_) => const AdminUsersView()),
    _MenuEntry('Reportes', Icons.bar_chart_outlined, (_) => const AdminReportsView()),
  ];

  static const _hospedajesRepo = _CatalogRepository('hospedajes');
  static const _transportesRepo = _CatalogRepository('transportes');

  // --- Navegación y acciones comunes ---

  void _handleMenuSelected(String menuTitle) {
    final entry = _menu.firstWhere((e) => e.title == menuTitle);
    final builder = entry.viewBuilder;
    if (builder == null) return; // ya estamos en esta vista

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
      backgroundColor: _Palette.primary,
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
        icon: isEditing ? Icons.edit : Icons.add_circle,
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
              await repo.actualizar(editingId,
                  categoria: categoria, activo: activo, capacidad: capacidad);
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

  Future<void> _confirmDelete(
    _CatalogRepository repo,
    String id,
    String categoria,
    String itemLabel,
  ) async {
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
          Expanded(child: isMobile ? _buildMobileLayout() : _buildDesktopLayout()),
        ],
      ),
    );
  }

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
                        Text(user?.nombre ?? 'Administrador', style: _Styles.drawerName),
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
                if (entry.title != _activeMenu) _handleMenuSelected(entry.title);
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

  Widget _buildMobileLayout() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Gestión de Tablas', style: _Styles.title(true)),
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
            Text('Gestión de Tablas', style: _Styles.title(false)),
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
      SizedBox(height: isMobile ? 32 : 32),
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
      SizedBox(height: isMobile ? 40 : 40),
    ];
  }

  /// Construye una tabla de catálogo completa: header con botón de agregar
  /// + lista en tiempo real desde Firestore. Sirve tanto para hospedajes
  /// como para transportes (u otro catálogo futuro con la misma forma).
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: _Styles.sectionTitle(isMobile)),
                ElevatedButton(
                  onPressed: () => _showFormDialog(
                    repo: repo,
                    itemLabel: itemLabel,
                    hasCapacidad: hasCapacidad,
                    categoriaHint: categoriaHint,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Palette.primary,
                    foregroundColor: Colors.white,
                    padding: isMobile
                        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                        : const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text('+ Añadir',
                      style: GoogleFonts.outfit(
                          fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.bold)),
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
                  child: Center(child: CircularProgressIndicator(color: _Palette.primary)),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return _EmptyState(icon: emptyIcon, message: emptyMessage);
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: _Palette.border),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final categoria = data['categoria'] as String? ?? 'Sin nombre';
                  final activo = data['activo'] as bool? ?? true;
                  final capacidad =
                      hasCapacidad ? (data['capacidad'] as num? ?? 0).toInt() : null;

                  return _CatalogRow(
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
                },
              );
            },
          ),
        ],
      ),
    );
  }
}