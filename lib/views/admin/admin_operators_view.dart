import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../models/usuario.dart';
import '../auth/login_view.dart';
import '../shared/app_header.dart';
import '../shared/widgets/custom_dialog.dart';
import 'admin_edit_profile_view.dart';
import 'admin_home_view.dart';
import 'admin_management_view.dart';
import 'admin_reports_view.dart';

/// Paleta y estilos compartidos del módulo admin.
/// (Igual que en los otros archivos admin_*.dart — candidata a moverse a
/// un solo archivo de tema compartido cuando terminemos todos.)
class _Palette {
  static const primary = Color(0xFFFC6707);
  static const primaryLight = Color(0xFFFDDBB3);
  static const textDark = Color(0xFF333333);
  static const textGrey = Color(0xFF666666);
  static const textLight = Color(0xFF888888);
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

  static final drawerName = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: _Palette.textDark,
  );

  static final drawerRole = GoogleFonts.outfit(fontSize: 12, color: _Palette.textGrey);

  static TextStyle drawerItem(bool isActive) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        color: isActive ? _Palette.primary : _Palette.textDark,
      );

  static TextStyle infoLabel(bool isMobile) => GoogleFonts.outfit(
        fontSize: isMobile ? 11 : 12,
        fontWeight: FontWeight.w600,
        color: _Palette.textGrey,
      );

  static TextStyle infoValue(bool isMobile, {Color? color}) => GoogleFonts.outfit(
        fontSize: isMobile ? 11 : 12,
        color: color ?? _Palette.textDark,
      );
}

class _MenuEntry {
  final String title;
  final IconData icon;
  final WidgetBuilder? viewBuilder;

  const _MenuEntry(this.title, this.icon, [this.viewBuilder]);
}

/// Definición de cada pestaña: etiqueta visible, valor de `estado` en
/// Firestore, e ícono a mostrar cuando la lista está vacía.
class _OperatorTab {
  final String label;
  final String estado;
  final IconData emptyIcon;

  const _OperatorTab(this.label, this.estado, this.emptyIcon);
}

// ===========================================================================
// Widgets reutilizables
// ===========================================================================

/// Badge de estado (Activo / Inactivo / Rechazado, etc.).
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

/// Fila "label: valor" reutilizada en toda la info expandida de la tarjeta.
class _InfoRow extends StatelessWidget {
  final String label;
  final bool isMobile;
  final Widget value;

  const _InfoRow({required this.label, required this.isMobile, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: isMobile ? 80 : 100, child: Text(label, style: _Styles.infoLabel(isMobile))),
          Expanded(child: value),
        ],
      ),
    );
  }
}

/// Botones/estado que se muestran en cada tarjeta según la pestaña activa:
/// Pendientes -> aprobar/rechazar; Aprobados -> badge + activar/inhabilitar;
/// Rechazados -> solo badge.
class _OperatorActions extends StatelessWidget {
  final int tabIndex;
  final bool activo;
  final VoidCallback onToggleActivo;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _OperatorActions({
    required this.tabIndex,
    required this.activo,
    required this.onToggleActivo,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    switch (tabIndex) {
      case 0: // Pendientes
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onApprove,
              icon: const Icon(Icons.check_circle, color: _Palette.green, size: 24),
              tooltip: 'Aprobar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              onPressed: onReject,
              icon: const Icon(Icons.cancel, color: _Palette.red, size: 24),
              tooltip: 'Rechazar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        );
      case 1: // Aprobados
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBadge(label: activo ? 'Activo' : 'Inactivo', color: activo ? _Palette.green : _Palette.red),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onToggleActivo,
              icon: Icon(activo ? Icons.block : Icons.check_circle,
                  color: activo ? _Palette.red : _Palette.green, size: 24),
              tooltip: activo ? 'Inhabilitar' : 'Activar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        );
      default: // Rechazados
        return const _StatusBadge(label: 'Rechazado', color: _Palette.red);
    }
  }
}

// ===========================================================================
// Vista principal
// ===========================================================================

class AdminOperatorsView extends StatefulWidget {
  const AdminOperatorsView({super.key});

  @override
  State<AdminOperatorsView> createState() => _AdminOperatorsViewState();
}

class _AdminOperatorsViewState extends State<AdminOperatorsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const String _activeMenu = 'Usuarios';
  int _selectedTab = 0;

  static const List<_OperatorTab> _tabs = [
    _OperatorTab('Pendientes', 'pendiente', Icons.pending_actions),
    _OperatorTab('Aprobados', 'aprobado', Icons.check_circle),
    _OperatorTab('Rechazados', 'rechazado', Icons.cancel),
  ];

  static final List<_MenuEntry> _menu = [
    _MenuEntry('Dashboard', Icons.dashboard_outlined, (_) => const AdminHomeView()),
    _MenuEntry('Gestión', Icons.settings_outlined, (_) => const AdminManagementView()),
    const _MenuEntry(_activeMenu, Icons.people_outline), // vista actual
    _MenuEntry('Reportes', Icons.bar_chart_outlined, (_) => const AdminReportsView()),
  ];

  // --- Navegación y acciones comunes ---

  void _handleMenuSelected(String menuTitle) {
    final entry = _menu.firstWhere((e) => e.title == menuTitle);
    final builder = entry.viewBuilder;
    if (builder == null) return; // ya estamos en esta vista
    Navigator.pushReplacement(context, MaterialPageRoute(builder: builder));
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

  void _volver() => Navigator.pop(context);

  // --- Acciones sobre operadores ---

  /// Recibe [activoActual] directamente (ya lo tenemos disponible en la
  /// tarjeta) en vez de volver a consultar Firestore solo para leerlo.
  Future<void> _toggleOperatorStatus(String operadorId, String nombre, bool activoActual) async {
    final nuevoEstado = !activoActual;
    final accion = nuevoEstado ? 'habilitar' : 'inhabilitar';

    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: '${nuevoEstado ? 'Habilitar' : 'Inhabilitar'} operador',
      message: '¿Estás seguro de que deseas $accion al operador "$nombre"?',
      confirmText: 'Confirmar',
      icon: nuevoEstado ? Icons.check_circle : Icons.block,
    );
    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('operadores')
          .doc(operadorId)
          .update({'activo': nuevoEstado});
      if (!mounted) return;
      _mostrarMensaje('Operador ${nuevoEstado ? 'habilitado' : 'inhabilitado'} correctamente');
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error al cambiar el estado: $e');
    }
  }

  Future<void> _aprobarOperador(Usuario operador) async {
    final error = await Provider.of<AuthController>(context, listen: false).approveOperator(operador);
    _mostrarMensaje(error ?? 'Operador aprobado correctamente');
  }

  Future<void> _rechazarOperador(Usuario operador) async {
    final error = await Provider.of<AuthController>(context, listen: false).rejectOperator(operador);
    _mostrarMensaje(error ?? 'Operador rechazado');
  }

  void _verLicencia(String url, bool isMobile) {
    if (url.isEmpty) {
      _mostrarMensaje('Este operador no tiene licencia cargada.');
      return;
    }
    if (!url.startsWith('data:image')) {
      _mostrarMensaje('Formato de licencia no soportado o inválido.');
      return;
    }

    try {
      final bytes = base64Decode(url.split(',').last);
      showDialog(
        context: context,
        builder: (_) => _LicenciaPreviewDialog(bytes: bytes, isMobile: isMobile),
      );
    } catch (_) {
      _mostrarMensaje('Error al abrir la licencia.');
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
      body: Stack(
        children: [
          Column(
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
          Positioned(
            top: isMobile ? 130 : 100,
            right: 16,
            child: _buildVolverButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildVolverButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _volver,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, color: _Palette.primary, size: 16),
              const SizedBox(width: 4),
              Text('Volver',
                  style: GoogleFonts.outfit(fontSize: 16, color: _Palette.primary, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
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
                            ? Image.memory(base64Decode(user!.fotoBase64!),
                                width: 50, height: 50, fit: BoxFit.cover)
                            : const CircleAvatar(
                                backgroundColor: _Palette.primaryLight,
                                child: Icon(Icons.admin_panel_settings, color: _Palette.primary, size: 28),
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

  Widget _buildMobileLayout() => _buildLayout(isMobile: true);
  Widget _buildDesktopLayout() => _buildLayout(isMobile: false);

  Widget _buildLayout({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24).copyWith(top: isMobile ? 16 : 16, bottom: isMobile ? 16 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) const SizedBox(height: 0),
          Text('Administrar Operadores', style: _Styles.title(isMobile)),
          const SizedBox(height: 16),
          _buildTabBar(isMobile),
          const SizedBox(height: 16),
          Expanded(child: _buildOperatorsList(isMobile)),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isMobile) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++) _buildTab(i, isMobile),
        ],
      ),
    );
  }

  Widget _buildTab(int index, bool isMobile) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
          decoration: BoxDecoration(
            color: isSelected ? _Palette.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              _tabs[index].label,
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 12 : 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : _Palette.textGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorsList(bool isMobile) {
    final tab = _tabs[_selectedTab];

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('operadores').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _Palette.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: GoogleFonts.outfit(color: Colors.red)),
          );
        }

        final operadores =
            (snapshot.data?.docs ?? []).where((doc) => doc.data()['estado'] == tab.estado).toList();

        if (operadores.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tab.emptyIcon, size: 48, color: const Color(0xFFCCCCCC)),
                const SizedBox(height: 12),
                Text('No hay operadores con este estado',
                    style: GoogleFonts.outfit(fontSize: 14, color: _Palette.textFaint)),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: operadores.length,
          itemBuilder: (context, index) {
            final doc = operadores[index];
            final data = doc.data();
            return _buildOperatorCard(
              operador: Usuario.fromMap(doc.id, data),
              data: data,
              isMobile: isMobile,
            );
          },
        );
      },
    );
  }

  Widget _buildOperatorCard({
    required Usuario operador,
    required Map<String, dynamic> data,
    required bool isMobile,
  }) {
    final nombre = data['nombre'] as String? ?? 'Sin nombre';
    final empresa = data['empresa'] as String? ?? 'Sin empresa';
    final activo = data['activo'] as bool? ?? true;
    final licenciaUrl = data['licenciaUrl'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.border, width: 1),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        title: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: _Palette.primaryLight),
              child: Center(
                child: Text(
                  empresa.isNotEmpty ? empresa[0].toUpperCase() : '?',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: _Palette.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(empresa,
                      style: GoogleFonts.outfit(
                          fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w600, color: _Palette.textDark)),
                  Text('Representante: $nombre',
                      style: GoogleFonts.outfit(fontSize: isMobile ? 11 : 12, color: _Palette.textGrey)),
                  Text(data['correo'] as String? ?? 'Sin correo',
                      style: GoogleFonts.outfit(fontSize: isMobile ? 11 : 12, color: _Palette.textLight)),
                ],
              ),
            ),
            _OperatorActions(
              tabIndex: _selectedTab,
              activo: activo,
              onToggleActivo: () => _toggleOperatorStatus(operador.id, nombre, activo),
              onApprove: () => _aprobarOperador(operador),
              onReject: () => _rechazarOperador(operador),
            ),
          ],
        ),
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Teléfono:',
            isMobile: isMobile,
            value: Text(data['telefono'] as String? ?? 'Sin teléfono', style: _Styles.infoValue(isMobile)),
          ),
          _InfoRow(
            label: 'RIF:',
            isMobile: isMobile,
            value: Text(data['rif'] as String? ?? 'Sin RIF', style: _Styles.infoValue(isMobile)),
          ),
          _InfoRow(
            label: 'Descripción:',
            isMobile: isMobile,
            value: Text(data['descripcion'] as String? ?? 'Sin descripción', style: _Styles.infoValue(isMobile)),
          ),
          _InfoRow(
            label: 'Licencia:',
            isMobile: isMobile,
            value: _buildLicenciaValue(licenciaUrl, isMobile),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLicenciaValue(String? url, bool isMobile) {
    if (url == null || url.isEmpty) {
      return Text('No hay documento', style: _Styles.infoValue(isMobile, color: _Palette.textFaint));
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _verLicencia(url, isMobile),
        child: Text(
          'Ver documento cargado',
          style: _Styles.infoValue(isMobile, color: _Palette.primary)
              .copyWith(decoration: TextDecoration.underline),
        ),
      ),
    );
  }
}

/// Diálogo simple para previsualizar la imagen de la licencia de turismo.
class _LicenciaPreviewDialog extends StatelessWidget {
  final Uint8List bytes;
  final bool isMobile;

  const _LicenciaPreviewDialog({required this.bytes, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: const Text('Licencia de Turismo'),
            backgroundColor: _Palette.primary,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Image.memory(bytes, fit: BoxFit.contain, height: isMobile ? 300 : 500, width: double.infinity),
          ),
        ],
      ),
    );
  }
}