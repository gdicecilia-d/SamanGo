// Pantalla de gestión de tablas maestras (Administrador)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../shared/app_header.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'admin_home_view.dart';
import 'admin_users_view.dart';
import 'admin_reports_view.dart';

class AdminManagementView extends StatefulWidget {
  const AdminManagementView({super.key});

  @override
  State<AdminManagementView> createState() => _AdminManagementViewState();
}

class _AdminManagementViewState extends State<AdminManagementView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _activeMenu = 'Gestión';
  final List<String> _menuItems = ['Dashboard', 'Gestión', 'Usuarios', 'Reportes'];

  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _capacidadController = TextEditingController();
  bool _activoSwitch = true;

  void _handleMenuSelected(String menu) {
    if (menu == 'Dashboard') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeView()),
      );
    } else if (menu == 'Usuarios') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminUsersView()),
      );
    } else if (menu == 'Reportes') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminReportsView()),
      );
    }
  }

  void _handleEditProfile() {}

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
        if (!mounted) return;
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

  void _volver() {
    Navigator.pop(context);
  }

  // ✅ CARGAR DATOS POR DEFECTO EN FIRESTORE
  Future<void> _cargarDatosPorDefecto() async {
    try {
      final db = FirebaseFirestore.instance;

      // ---------- HOSPEDAJES ----------
      final hospedajesData = [
        {'categoria': 'Hotel', 'activo': true},
        {'categoria': 'Posada', 'activo': true},
        {'categoria': 'Camping', 'activo': true},
        {'categoria': 'Eco lodge', 'activo': true},
        {'categoria': 'No incluye', 'activo': true},
      ];

      for (final data in hospedajesData) {
        final existing = await db
            .collection('hospedajes')
            .where('categoria', isEqualTo: data['categoria'])
            .get();
        
        if (existing.docs.isEmpty) {
          await db.collection('hospedajes').add({
            ...data,
            'fechaCreacion': FieldValue.serverTimestamp(),
          });
        }
      }

      // ---------- TRANSPORTES ----------
      final transportesData = [
        {'categoria': 'Bus', 'capacidad': 40, 'activo': true},
        {'categoria': 'Avión', 'capacidad': 150, 'activo': true},
        {'categoria': 'Barco', 'capacidad': 80, 'activo': true},
        {'categoria': '4x4', 'capacidad': 6, 'activo': true},
        {'categoria': 'Todos', 'capacidad': 0, 'activo': true},
      ];

      for (final data in transportesData) {
        final existing = await db
            .collection('transportes')
            .where('categoria', isEqualTo: data['categoria'])
            .get();
        
        if (existing.docs.isEmpty) {
          await db.collection('transportes').add({
            ...data,
            'fechaCreacion': FieldValue.serverTimestamp(),
          });
        }
      }

      _mostrarMensaje('✅ Datos cargados correctamente');
      setState(() {});
    } catch (e) {
      _mostrarMensaje('❌ Error al cargar datos: $e');
    }
  }

  // -------- HOSPEDAJES --------

  Future<void> _agregarHospedaje() async {
    final categoria = _categoriaController.text.trim();
    if (categoria.isEmpty) {
      _mostrarMensaje('Ingresa una categoría');
      return;
    }

    try {
      final existing = await FirebaseFirestore.instance
          .collection('hospedajes')
          .where('categoria', isEqualTo: categoria)
          .get();

      if (existing.docs.isNotEmpty) {
        _mostrarMensaje('La categoría "$categoria" ya existe');
        return;
      }

      await FirebaseFirestore.instance.collection('hospedajes').add({
        'categoria': categoria,
        'activo': _activoSwitch,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      _mostrarMensaje('Hospedaje agregado correctamente');
      _categoriaController.clear();
      _activoSwitch = true;
      Navigator.pop(context);
    } catch (e) {
      _mostrarMensaje('Error al agregar: $e');
    }
  }

  Future<void> _editarHospedaje(String id, String categoriaActual, bool activoActual) async {
    _categoriaController.text = categoriaActual;
    _activoSwitch = activoActual;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialog(
        titulo: 'Editar Hospedaje',
        onConfirm: () async {
          final nuevaCategoria = _categoriaController.text.trim();
          if (nuevaCategoria.isEmpty) {
            _mostrarMensaje('Ingresa una categoría');
            return;
          }

          try {
            final existing = await FirebaseFirestore.instance
                .collection('hospedajes')
                .where('categoria', isEqualTo: nuevaCategoria)
                .get();

            if (existing.docs.any((doc) => doc.id != id)) {
              _mostrarMensaje('La categoría "$nuevaCategoria" ya existe');
              return;
            }

            await FirebaseFirestore.instance
                .collection('hospedajes')
                .doc(id)
                .update({
              'categoria': nuevaCategoria,
              'activo': _activoSwitch,
            });

            _mostrarMensaje('Hospedaje actualizado correctamente');
            _categoriaController.clear();
            _activoSwitch = true;
            Navigator.pop(context);
          } catch (e) {
            _mostrarMensaje('Error al actualizar: $e');
          }
        },
        onCancel: () {
          _categoriaController.clear();
          _activoSwitch = true;
          Navigator.pop(context);
        },
        esEdicion: true,
      ),
    );
  }

  Future<void> _toggleHospedaje(String id, String categoria, bool activoActual) async {
    final nuevoEstado = !activoActual;
    final actionText = nuevoEstado ? 'activar' : 'inactivar';
    
    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: '${nuevoEstado ? 'Activar' : 'Inactivar'} hospedaje',
      message: '¿Estás seguro de que deseas $actionText "$categoria"?',
      confirmText: 'Confirmar',
      icon: nuevoEstado ? Icons.check_circle : Icons.block,
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('hospedajes')
            .doc(id)
            .update({'activo': nuevoEstado});
        _mostrarMensaje('Hospedaje ${nuevoEstado ? 'activado' : 'inactivado'} correctamente');
        setState(() {});
      } catch (e) {
        _mostrarMensaje('Error al cambiar el estado: $e');
      }
    }
  }

  Future<void> _eliminarHospedaje(String id, String categoria) async {
    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: 'Eliminar hospedaje',
      message: '¿Estás seguro de que deseas eliminar "$categoria"?',
      confirmText: 'Eliminar',
      icon: Icons.delete,
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('hospedajes')
            .doc(id)
            .delete();
        _mostrarMensaje('Hospedaje eliminado correctamente');
      } catch (e) {
        _mostrarMensaje('Error al eliminar: $e');
      }
    }
  }

  // -------- TRANSPORTES --------

  Future<void> _agregarTransporte() async {
    final categoria = _categoriaController.text.trim();
    final capacidad = int.tryParse(_capacidadController.text.trim());

    if (categoria.isEmpty) {
      _mostrarMensaje('Ingresa una categoría');
      return;
    }
    if (capacidad == null) {
      _mostrarMensaje('Ingresa una capacidad válida');
      return;
    }

    try {
      final existing = await FirebaseFirestore.instance
          .collection('transportes')
          .where('categoria', isEqualTo: categoria)
          .get();

      if (existing.docs.isNotEmpty) {
        _mostrarMensaje('La categoría "$categoria" ya existe');
        return;
      }

      await FirebaseFirestore.instance.collection('transportes').add({
        'categoria': categoria,
        'capacidad': capacidad,
        'activo': _activoSwitch,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      _mostrarMensaje('Transporte agregado correctamente');
      _categoriaController.clear();
      _capacidadController.clear();
      _activoSwitch = true;
      Navigator.pop(context);
    } catch (e) {
      _mostrarMensaje('Error al agregar: $e');
    }
  }

  Future<void> _editarTransporte(String id, String categoriaActual, int capacidadActual, bool activoActual) async {
    _categoriaController.text = categoriaActual;
    _capacidadController.text = capacidadActual.toString();
    _activoSwitch = activoActual;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialog(
        titulo: 'Editar Transporte',
        onConfirm: () async {
          final nuevaCategoria = _categoriaController.text.trim();
          final nuevaCapacidad = int.tryParse(_capacidadController.text.trim());

          if (nuevaCategoria.isEmpty) {
            _mostrarMensaje('Ingresa una categoría');
            return;
          }
          if (nuevaCapacidad == null) {
            _mostrarMensaje('Ingresa una capacidad válida');
            return;
          }

          try {
            final existing = await FirebaseFirestore.instance
                .collection('transportes')
                .where('categoria', isEqualTo: nuevaCategoria)
                .get();

            if (existing.docs.any((doc) => doc.id != id)) {
              _mostrarMensaje('La categoría "$nuevaCategoria" ya existe');
              return;
            }

            await FirebaseFirestore.instance
                .collection('transportes')
                .doc(id)
                .update({
              'categoria': nuevaCategoria,
              'capacidad': nuevaCapacidad,
              'activo': _activoSwitch,
            });

            _mostrarMensaje('Transporte actualizado correctamente');
            _categoriaController.clear();
            _capacidadController.clear();
            _activoSwitch = true;
            Navigator.pop(context);
          } catch (e) {
            _mostrarMensaje('Error al actualizar: $e');
          }
        },
        onCancel: () {
          _categoriaController.clear();
          _capacidadController.clear();
          _activoSwitch = true;
          Navigator.pop(context);
        },
        esEdicion: true,
        mostrarCapacidad: true,
      ),
    );
  }

  Future<void> _toggleTransporte(String id, String categoria, bool activoActual) async {
    final nuevoEstado = !activoActual;
    final actionText = nuevoEstado ? 'activar' : 'inactivar';
    
    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: '${nuevoEstado ? 'Activar' : 'Inactivar'} transporte',
      message: '¿Estás seguro de que deseas $actionText "$categoria"?',
      confirmText: 'Confirmar',
      icon: nuevoEstado ? Icons.check_circle : Icons.block,
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('transportes')
            .doc(id)
            .update({'activo': nuevoEstado});
        _mostrarMensaje('Transporte ${nuevoEstado ? 'activado' : 'inactivado'} correctamente');
        setState(() {});
      } catch (e) {
        _mostrarMensaje('Error al cambiar el estado: $e');
      }
    }
  }

  Future<void> _eliminarTransporte(String id, String categoria) async {
    final confirm = await CustomConfirmDialog.show(
      context: context,
      title: 'Eliminar transporte',
      message: '¿Estás seguro de que deseas eliminar "$categoria"?',
      confirmText: 'Eliminar',
      icon: Icons.delete,
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('transportes')
            .doc(id)
            .delete();
        _mostrarMensaje('Transporte eliminado correctamente');
      } catch (e) {
        _mostrarMensaje('Error al eliminar: $e');
      }
    }
  }

  // -------- DIÁLOGO --------

  Widget _buildDialog({
    required String titulo,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    bool esEdicion = false,
    bool mostrarCapacidad = false,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        titulo,
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF333333),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _categoriaController,
            decoration: InputDecoration(
              labelText: 'Categoría',
              hintText: 'Ej: Hotel, Bus, etc.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (mostrarCapacidad) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _capacidadController,
              decoration: InputDecoration(
                labelText: 'Capacidad',
                hintText: 'Ej: 40',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Activo',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: const Color(0xFF333333),
                ),
              ),
              const Spacer(),
              Switch(
                value: _activoSwitch,
                onChanged: (value) {
                  setState(() {
                    _activoSwitch = value;
                  });
                },
                activeColor: const Color(0xFFFC6707),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Cancelar',
            style: GoogleFonts.outfit(
              color: const Color(0xFF666666),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFC6707),
            foregroundColor: Colors.white,
          ),
          child: Text(
            esEdicion ? 'Actualizar' : 'Agregar',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

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
                menuItems: _menuItems,
                isMobile: isMobile,
                onMenuTap: isMobile ? _openDrawer : null,
              ),
              Expanded(
                child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
              ),
            ],
          ),
          Positioned(
            top: isMobile ? 80 : 100,
            right: 24,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _volver,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, color: const Color(0xFFFC6707), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Volver',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
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
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFC6707), width: 2),
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFFFDDBB3),
                      child: Icon(Icons.admin_panel_settings, color: Color(0xFFFC6707), size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nombre ?? 'Administrador',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                        ),
                        Text(
                          'Administrador',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            _buildDrawerItem('Dashboard', Icons.dashboard_outlined, () {
              Navigator.pop(context);
              _handleMenuSelected('Dashboard');
            }),
            _buildDrawerItem('Gestión', Icons.settings_outlined, () {
              Navigator.pop(context);
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
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
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

  // ✅ MÓVIL - CON SCROLL
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: _buildContent(isMobile: true),
    );
  }

  // ✅ ESCRITORIO - CON SCROLL
  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: _buildContent(isMobile: false),
    );
  }

  Widget _buildContent({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ TÍTULO CON BOTÓN PARA CARGAR DATOS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gestión de Tablas',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            // ✅ BOTÓN PARA CARGAR DATOS POR DEFECTO
            ElevatedButton.icon(
              onPressed: _cargarDatosPorDefecto,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Cargar datos por defecto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC6707),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // ✅ HOSPEDAJES
        _buildTablaHospedajes(isMobile),
        const SizedBox(height: 32),
        // ✅ TRANSPORTES
        _buildTablaTransportes(isMobile),
        const SizedBox(height: 40),
      ],
    );
  }

  // -------- TABLA HOSPEDAJES --------

  Widget _buildTablaHospedajes(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tipos de Hospedaje',
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _categoriaController.clear();
                    _activoSwitch = true;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => _buildDialog(
                        titulo: 'Agregar Hospedaje',
                        onConfirm: _agregarHospedaje,
                        onCancel: () {
                          _categoriaController.clear();
                          _activoSwitch = true;
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC6707),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('+ Añadir'),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('hospedajes')
                .orderBy('fechaCreacion', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFFC6707))),
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
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.hotel_outlined, size: 48, color: const Color(0xFFCCCCCC)),
                        const SizedBox(height: 12),
                        Text(
                          'No hay hospedajes registrados',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF999999),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Presiona "Cargar datos por defecto" para crear los iniciales',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFFCCCCCC),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final categoria = data['categoria'] ?? 'Sin nombre';
                  final activo = data['activo'] as bool? ?? true;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          '${index + 1}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            categoria,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _toggleHospedaje(doc.id, categoria, activo),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: activo ? const Color(0xFF4CAF50).withValues(alpha: 0.15) : const Color(0xFFF44336).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: activo ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  activo ? 'Activo' : 'Inactivo',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: activo ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _editarHospedaje(doc.id, categoria, activo),
                          icon: const Icon(Icons.edit, color: Color(0xFFFC6707), size: 18),
                          tooltip: 'Editar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          onPressed: () => _eliminarHospedaje(doc.id, categoria),
                          icon: const Icon(Icons.delete, color: Color(0xFFF44336), size: 18),
                          tooltip: 'Eliminar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // -------- TABLA TRANSPORTES --------

  Widget _buildTablaTransportes(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tipos de Transporte',
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _categoriaController.clear();
                    _capacidadController.clear();
                    _activoSwitch = true;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => _buildDialog(
                        titulo: 'Agregar Transporte',
                        onConfirm: _agregarTransporte,
                        onCancel: () {
                          _categoriaController.clear();
                          _capacidadController.clear();
                          _activoSwitch = true;
                          Navigator.pop(context);
                        },
                        mostrarCapacidad: true,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC6707),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('+ Añadir'),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transportes')
                .orderBy('fechaCreacion', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFFC6707))),
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
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.directions_bus_outlined, size: 48, color: const Color(0xFFCCCCCC)),
                        const SizedBox(height: 12),
                        Text(
                          'No hay transportes registrados',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF999999),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Presiona "Cargar datos por defecto" para crear los iniciales',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFFCCCCCC),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final categoria = data['categoria'] ?? 'Sin nombre';
                  final capacidad = data['capacidad'] ?? 0;
                  final activo = data['activo'] as bool? ?? true;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          '${index + 1}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Text(
                            categoria,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '$capacidad',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _toggleTransporte(doc.id, categoria, activo),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: activo ? const Color(0xFF4CAF50).withValues(alpha: 0.15) : const Color(0xFFF44336).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: activo ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  activo ? 'Activo' : 'Inactivo',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: activo ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _editarTransporte(doc.id, categoria, capacidad, activo),
                          icon: const Icon(Icons.edit, color: Color(0xFFFC6707), size: 18),
                          tooltip: 'Editar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          onPressed: () => _eliminarTransporte(doc.id, categoria),
                          icon: const Icon(Icons.delete, color: Color(0xFFF44336), size: 18),
                          tooltip: 'Eliminar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
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