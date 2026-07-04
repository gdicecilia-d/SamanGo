import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../models/usuario.dart';
import '../auth/login_view.dart';
import 'admin_theme.dart';
import '../shared/app_header.dart';
import '../shared/widgets/custom_dialog.dart';
import 'admin_edit_profile_view.dart';
import 'admin_home_view.dart';
import 'admin_management_view.dart';
import 'admin_reports_view.dart';

/// Definición de cada pestaña: etiqueta visible, valor de `estado` en
/// Firestore, e ícono a mostrar cuando la lista está vacía.
class _OperatorTab {
  final String label;
  final String estado;
  final IconData emptyIcon;

  const _OperatorTab(this.label, this.estado, this.emptyIcon);
}

/// Botones/estado que se muestran en cada tarjeta según la pestaña activa.
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
            _RoundIconButton(icon: Icons.check, color: AdminPalette.success, tooltip: 'Aprobar', onTap: onApprove),
            const SizedBox(width: 6),
            _RoundIconButton(icon: Icons.close, color: AdminPalette.danger, tooltip: 'Rechazar', onTap: onReject),
          ],
        );
      case 1: // Aprobados
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onToggleActivo,
              child: AdminStatusBadge(
                label: activo ? 'Activo' : 'Inactivo',
                color: activo ? AdminPalette.success : AdminPalette.danger,
                icon: activo ? Icons.check_circle_outline : Icons.block,
              ),
            ),
          ],
        );
      default: // Rechazados
        return const AdminStatusBadge(label: 'Rechazado', color: AdminPalette.danger, icon: Icons.cancel_outlined);
    }
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: color, size: 18)),
        ),
      ),
    );
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

  static final List<AdminMenuEntry> _menu = [
    AdminMenuEntry('Dashboard', Icons.dashboard_outlined, (_) => const AdminHomeView()),
    AdminMenuEntry('Gestión', Icons.settings_outlined, (_) => const AdminManagementView()),
    const AdminMenuEntry(_activeMenu, Icons.people_outline), // vista actual
    AdminMenuEntry('Reportes', Icons.bar_chart_outlined, (_) => const AdminReportsView()),
  ];

  // --- Navegación y acciones comunes ---

  void _handleMenuSelected(String menuTitle) {
    final entry = _menu.firstWhere((e) => e.title == menuTitle);
    final builder = entry.viewBuilder;
    if (builder == null) return;
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
      backgroundColor: AdminPalette.primary,
      duration: const Duration(seconds: 2),
    ));
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();
  void _volver() => Navigator.pop(context);

  // --- Acciones sobre operadores ---

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
      await FirebaseFirestore.instance.collection('operadores').doc(operadorId).update({'activo': nuevoEstado});
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
      showDialog(context: context, builder: (_) => _LicenciaPreviewDialog(bytes: bytes, isMobile: isMobile));
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
              Expanded(child: _buildLayout(isMobile)),
            ],
          ),
          Positioned(top: isMobile ? 130 : 100, right: 16, child: AdminBackButton(onTap: _volver)),
        ],
      ),
    );
  }

  Widget _buildLayout(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(title: 'Administrar Operadores', isMobile: isMobile),
          const SizedBox(height: 16),
          AdminSegmentedTabs(
            labels: _tabs.map((t) => t.label).toList(),
            selectedIndex: _selectedTab,
            onChanged: (i) => setState(() => _selectedTab = i),
            isMobile: isMobile,
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildOperatorsList(isMobile)),
        ],
      ),
    );
  }

  Widget _buildOperatorsList(bool isMobile) {
    final tab = _tabs[_selectedTab];

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('operadores').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AdminPalette.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.outfit(color: Colors.red)));
        }

        final operadores =
            (snapshot.data?.docs ?? []).where((doc) => doc.data()['estado'] == tab.estado).toList();

        if (operadores.isEmpty) {
          return AdminEmptyState(icon: tab.emptyIcon, message: 'No hay operadores con este estado');
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: operadores.length,
          itemBuilder: (context, index) {
            final doc = operadores[index];
            final data = doc.data();
            return _buildOperatorCard(operador: Usuario.fromMap(doc.id, data), data: data, isMobile: isMobile);
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
      decoration: AdminPalette.card(radius: 18),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        title: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(gradient: AdminPalette.gradient, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  empresa.isNotEmpty ? empresa[0].toUpperCase() : '?',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(empresa,
                      style: GoogleFonts.outfit(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w600, color: AdminPalette.ink)),
                  Text('Representante: $nombre', style: GoogleFonts.outfit(fontSize: isMobile ? 11 : 12, color: AdminPalette.slate)),
                  Text(data['correo'] as String? ?? 'Sin correo',
                      style: GoogleFonts.outfit(fontSize: isMobile ? 11 : 12, color: AdminPalette.mist)),
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
          const Divider(color: AdminPalette.line),
          const SizedBox(height: 8),
          AdminInfoRow(
            label: 'Teléfono:',
            isMobile: isMobile,
            value: Text(data['telefono'] as String? ?? 'Sin teléfono', style: AdminStyles.infoValue(isMobile)),
          ),
          AdminInfoRow(
            label: 'RIF:',
            isMobile: isMobile,
            value: Text(data['rif'] as String? ?? 'Sin RIF', style: AdminStyles.infoValue(isMobile)),
          ),
          AdminInfoRow(
            label: 'Descripción:',
            isMobile: isMobile,
            value: Text(data['descripcion'] as String? ?? 'Sin descripción', style: AdminStyles.infoValue(isMobile)),
          ),
          AdminInfoRow(label: 'Licencia:', isMobile: isMobile, value: _buildLicenciaValue(licenciaUrl, isMobile)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLicenciaValue(String? url, bool isMobile) {
    if (url == null || url.isEmpty) {
      return Text('No hay documento', style: AdminStyles.infoValue(isMobile, color: AdminPalette.mist));
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _verLicencia(url, isMobile),
        child: Text(
          'Ver documento cargado',
          style: AdminStyles.infoValue(isMobile, color: AdminPalette.primary).copyWith(decoration: TextDecoration.underline),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AdminPalette.gradient),
            child: AppBar(
              title: const Text('Licencia de Turismo'),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))],
            ),
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