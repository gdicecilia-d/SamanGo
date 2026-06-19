// Vista principal del Home
import 'package:flutter/material.dart';
import '../controllers/home_controller.dart';
import 'widgets/base_scaffold.dart';
import 'widgets/hero_widget.dart';
import 'widgets/commitment_widget.dart';
import 'widgets/features_widget.dart';
import 'widgets/destinations_widget.dart';
import 'widgets/contact_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeController _controller;
  String _activeMenu = 'Inicio';

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _verificarRetornoPayPalNativo();
  }

  void _verificarRetornoPayPalNativo() {
    try {
      final uri = Uri.base;
      if (uri.queryParameters['action'] == 'paypal_success' && uri.queryParameters['token'] != null) {
        final reservaId = uri.queryParameters['reservaId'];
        if (reservaId != null && reservaId.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Procesando pago... Puedes cerrar esta pestaña y volver a la principal.'), duration: Duration(seconds: 10)),
            );
            
            final comprobanteUrl = 'paypal_${DateTime.now().millisecondsSinceEpoch}_$reservaId';
            
            await FirebaseFirestore.instance.collection('reservas').doc(reservaId).update({
              'comprobanteUrl': comprobanteUrl,
              'estado': 'pagado',
              'fechaActualizacion': FieldValue.serverTimestamp(),
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Error en retorno de PayPal: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return BaseScaffold(
              isMobile: isMobile,
              onLoginPressed: () => _controller.handleLogin(context),
              onRegisterPressed: () => _controller.handleRegister(context),
              onMenuSelected: (menu) {
                setState(() {
                  _activeMenu = menu;
                });
                switch (menu) {
                  case 'Inicio':
                    _controller.scrollToSection(_controller.sectionInicioKey);
                    break;
                  case 'Sobre Nosotros':
                    _controller.scrollToSection(_controller.sectionSobreNosotrosKey);
                    break;
                  case 'Destinos':
                    _controller.scrollToSection(_controller.sectionDestinosKey);
                    break;
                  case 'Contacto':
                    _controller.scrollToSection(_controller.sectionContactoKey);
                    break;
                }
              },
              activeMenu: _activeMenu,
              body: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: (overscroll) {
                  overscroll.disallowIndicator();
                  return true;
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      key: _controller.sectionInicioKey,
                      child: HeroWidget(
                        isMobile: isMobile,
                        onStartAdventurePressed: () => _controller.handleStartAdventure(context),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      key: _controller.sectionSobreNosotrosKey,
                      child: isMobile
                          ? Column(
                              children: [
                                CommitmentWidget(commitments: _controller.commitments, isMobile: true),
                                const SizedBox(height: 32),
                                FeaturesWidget(features: _controller.features, isMobile: true),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 7, child: CommitmentWidget(commitments: _controller.commitments, isMobile: false)),
                                const SizedBox(width: 32),
                                Expanded(flex: 3, child: FeaturesWidget(features: _controller.features, isMobile: false)),
                              ],
                            ),
                    ),
                    const SizedBox(height: 64),
                    Container(
                      key: _controller.sectionDestinosKey,
                      child: DestinationsWidget(
                        destinations: _controller.destinations,
                        isMobile: isMobile,
                      ),
                    ),
                    const SizedBox(height: 64),
                    Container(
                      key: _controller.sectionContactoKey,
                      child: ContactWidget(isMobile: isMobile),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}