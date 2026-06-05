import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../student/widgets/student_header.dart'; // We can reuse the header or create an operator one later
import '../../widgets/custom_dialog.dart';
import '../auth/login_view.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import 'operator_edit_profile_view.dart';

class OperatorHomeView extends StatefulWidget {
  const OperatorHomeView({super.key});

  @override
  State<OperatorHomeView> createState() => _OperatorHomeViewState();
}

class _OperatorHomeViewState extends State<OperatorHomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _handleMenuSelected(String menu, BuildContext context) {
    if (menu == 'Mis Paquetes') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mis Paquetes - Próximamente'), backgroundColor: Color(0xFFFC6707)),
      );
    } else if (menu == 'Reservas') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservas - Próximamente'), backgroundColor: Color(0xFFFC6707)),
      );
    }
  }

  void _handleEditProfile(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const OperatorEditProfileView()));
  }

  void _handleLogout(BuildContext context) async {
    await Provider.of<AuthController>(context, listen: false).logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;
    final auth = Provider.of<AuthController>(context);
    final nombreCompleto = auth.usuarioActual?.nombre ?? 'Operador';
    final primerNombre = nombreCompleto.split(' ').first;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          UserHeader(
            activeMenu: 'Inicio',
            onMenuSelected: (menu) => _handleMenuSelected(menu, context),
            onEditProfile: () => _handleEditProfile(context),
            onLogout: () => _handleLogout(context),
            menuItems: const ['Inicio', 'Mis Paquetes', 'Reservas'],
            isMobile: isMobile,
            onNotificationsTap: null,
            onMenuTap: isMobile ? _openDrawer : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                        children: [
                          const TextSpan(text: '¡Hola '),
                          TextSpan(text: primerNombre, style: const TextStyle(color: Color(0xFFFC6707))),
                          const TextSpan(text: '! Gestione sus viajes y reservas.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Contenido de operador
                  Center(child: Text('Panel de control del Operador', style: GoogleFonts.outfit(fontSize: 18))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
