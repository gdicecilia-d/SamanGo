// Vista principal del Home que implementa el patrón Template Method y Observer 
import 'package:flutter/material.dart';
import '../controllers/home_controller.dart';
import 'widgets/base_scaffold.dart';
import 'widgets/hero_widget.dart';
import 'widgets/commitment_widget.dart';
import 'widgets/features_widget.dart';
import 'widgets/destinations_widget.dart';
import 'widgets/contact_widget.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 850;

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
              body: Column(
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
            );
          },
        );
      },
    );
  }
}