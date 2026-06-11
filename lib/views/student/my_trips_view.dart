import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/reserva_controller.dart';
import '../../models/reserva.dart';
import '../../models/estado_reserva.dart';
import '../shared/app_header.dart';
import 'student_home_view.dart';
import 'favorites_view.dart';
import 'edit_profile_view.dart';
import 'payment_view.dart';
import 'ticket_view.dart';
import 'review_view.dart';
import '../../views/shared/widgets/custom_dialog.dart';
import '../auth/login_view.dart';

class MyTripsView extends StatefulWidget {
  const MyTripsView({super.key});

  @override
  State<MyTripsView> createState() => _MyTripsViewState();
}

class _MyTripsViewState extends State<MyTripsView> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> _menuItems = ['Inicio', 'Mis Viajes', 'Favoritos'];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleMenuSelected(String menu) {
    if (menu == 'Inicio') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomeView()),
        (route) => false,
      );
    } else if (menu == 'Favoritos') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FavoritesView()),
      );
    }
  }

  void _handleEditProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileView()));
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
      }
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final auth = Provider.of<AuthController>(context);
    final userId = auth.usuarioActual?.id ?? '';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9F9F9),
      endDrawer: isMobile ? _buildDrawer() : null,
      body: Column(
        children: [
          AppHeader(
            activeMenu: 'Mis Viajes',
            onMenuSelected: _handleMenuSelected,
            onEditProfile: _handleEditProfile,
            onLogout: _handleLogout,
            menuItems: _menuItems,
            isMobile: isMobile,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFC6707),
              unselectedLabelColor: const Color(0xFF888888),
              indicatorColor: const Color(0xFFFC6707),
              isScrollable: isMobile,
              tabs: const [
                Tab(text: 'Solicitudes'),
                Tab(text: 'Listos para Pagar'),
                Tab(text: 'Próximos Viajes'),
                Tab(text: 'Disfrutados'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Reserva>>(
              stream: Provider.of<ReservaController>(context, listen: false).obtenerMisReservasEstudiante(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFC6707)));
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar tus viajes.'));
                }

                final reservas = snapshot.data ?? [];

                final solicitudes = reservas.where((r) => r.estadoActual == EstadoReserva.solicitado).toList();
                final listosParaPagar = reservas.where((r) => r.estadoActual == EstadoReserva.aceptado || r.estadoActual == EstadoReserva.verificandoPago).toList();
                final proximos = reservas.where((r) => r.estadoActual == EstadoReserva.pagado).toList();
                final disfrutados = reservas.where((r) => r.estadoActual == EstadoReserva.disfrutado).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListaReservas(solicitudes, 'No tienes solicitudes pendientes.'),
                    _buildListaReservas(listosParaPagar, 'No tienes viajes pendientes por pago.'),
                    _buildListaReservas(proximos, 'No tienes viajes próximos.'),
                    _buildListaReservas(disfrutados, 'Aún no has disfrutado de ningún viaje.'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaReservas(List<Reserva> reservas, String emptyMessage) {
    if (reservas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flight_takeoff, size: 80, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.outfit(fontSize: 18, color: const Color(0xFF999999)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: reservas.length,
      itemBuilder: (context, index) {
        final reserva = reservas[index];
        return _buildReservaCard(reserva);
      },
    );
  }

  Widget _buildReservaCard(Reserva reserva) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('destinos').doc(reserva.paqueteId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final destino = snapshot.data!.data() as Map<String, dynamic>?;
        if (destino == null) return const SizedBox();

        String statusText = '';
        Color statusColor = Colors.grey;

        if (reserva.estadoActual == EstadoReserva.solicitado) {
          statusText = 'Solicitado';
          statusColor = Colors.orange;
        } else if (reserva.estadoActual == EstadoReserva.aceptado) {
          statusText = 'Listo para Pagar';
          statusColor = Colors.green;
        } else if (reserva.estadoActual == EstadoReserva.verificandoPago) {
          statusText = 'Verificando Pago';
          statusColor = Colors.amber;
        } else if (reserva.estadoActual == EstadoReserva.pagado) {
          statusText = 'Confirmado';
          statusColor = Colors.blue;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      destino['nombre'] ?? 'Destino',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: GoogleFonts.outfit(color: statusColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Fecha: ${reserva.fechaInicio?.day}/${reserva.fechaInicio?.month}/${reserva.fechaInicio?.year}'),
                Text('Personas: ${reserva.numeroPersonas}'),
                Text('Total: \$${reserva.totalGeneral.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildBotonesAccion(reserva, destino),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBotonesAccion(Reserva reserva, Map<String, dynamic> destinoData) {
    if (reserva.estadoActual == EstadoReserva.solicitado) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancelando...')));
              // Cancel logic
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Cancelar solicitud'),
          ),
        ],
      );
    } else if (reserva.estadoActual == EstadoReserva.aceptado) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {},
            child: const Text('Cancelar', style: TextStyle(color: Colors.purple)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PaymentView(reserva: reserva, destinoData: destinoData)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Pagar'),
          ),
        ],
      );
    } else if (reserva.estadoActual == EstadoReserva.pagado) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {},
            child: const Text('Modificar', style: TextStyle(color: Colors.purple)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TicketView(reserva: reserva, destinoData: destinoData)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text('Ver Ticket'),
          ),
        ],
      );
    } else if (reserva.estadoActual == EstadoReserva.disfrutado) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReviewView(reserva: reserva, destinoData: destinoData)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC6707), foregroundColor: Colors.white),
            child: const Text('Reseña'),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFFC6707)),
            child: Text('SamanGo', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
              _handleMenuSelected('Inicio');
            },
          ),
          ListTile(
            title: const Text('Mis Viajes', style: TextStyle(color: Color(0xFFFC6707), fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Favoritos'),
            onTap: () {
              Navigator.pop(context);
              _handleMenuSelected('Favoritos');
            },
          ),
        ],
      ),
    );
  }
}
