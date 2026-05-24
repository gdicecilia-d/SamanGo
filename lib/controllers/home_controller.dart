// Controlador principal del Home 
// Maneja el estado, la navegación por anclas y la lógica de negocio
import 'package:flutter/material.dart';
import '../models/commitment_model.dart';
import '../models/feature_model.dart';
import '../models/destination_model.dart';

class HomeController extends ChangeNotifier {
  // Keys para las secciones usadas para scroll
  final GlobalKey sectionInicioKey = GlobalKey();
  final GlobalKey sectionSobreNosotrosKey = GlobalKey();
  final GlobalKey sectionDestinosKey = GlobalKey();
  final GlobalKey sectionContactoKey = GlobalKey();

  // Datos
  final List<CommitmentModel> commitments = const [
    CommitmentModel(
      title: 'Misión',
      description: 'Desarrollar una plataforma centralizada para que la comunidad UNIMET gestione y reserve planes turísticos de bajo costo bajo un entorno seguro y exclusivo.',
    ),
    CommitmentModel(
      title: 'Visión',
      description: 'Crear un ecosistema digital colaborativo que garantice la transparencia, verificación y trazabilidad de los servicios turísticos ofrecidos a los estudiantes.',
    ),
    CommitmentModel(
      title: 'Objetivo',
      description: 'Implementar un sistema integral de gestión para la comercialización de rutas turísticas, integrando módulos de pago simulado, auditoría y análisis de tendencias.',
    ),
  ];

  final List<FeatureModel> features = const [
    FeatureModel(title: 'Exclusividad institucional'),
    FeatureModel(title: 'Precios low-cost'),
    FeatureModel(title: 'Seguridad con operadores verificados'),
    FeatureModel(title: 'Transparencia en cada reserva'),
  ];

  final List<DestinationModel> destinations = const [
    DestinationModel(name: 'Cayo Sombrero - Morrocoy', location: 'Falcón', imageAsset: 'assets/images/morrocoy.png'),
    DestinationModel(name: 'Colonia Tovar', location: 'Aragua', imageAsset: 'assets/images/colonia_tovar.png'),
    DestinationModel(name: 'Playa Grande - Choroni', location: 'Aragua', imageAsset: 'assets/images/choroni.png'),
    DestinationModel(name: 'Isla El Faro - Mochima', location: 'Anzoátegui', imageAsset: 'assets/images/mochima.png'),
    DestinationModel(name: 'Dunas de Coro - Médanos', location: 'Falcón', imageAsset: 'assets/images/medanos.png'),
    DestinationModel(name: 'Salto Ángel - Canaima', location: 'Bolívar', imageAsset: 'assets/images/canaima.png'),
  ];

  // Método para hacer scroll suave a una sección
  void scrollToSection(GlobalKey sectionKey) {
    final context = sectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // Acciones de botones
  void handleLogin(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Iniciar Sesión - Próximamente'),
        backgroundColor: Color(0xFFFC6707),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void handleRegister(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registrarse - Próximamente'),
        backgroundColor: Color(0xFFFC6707),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void handleStartAdventure(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Comienza tu viaje UNIMET!'),
        backgroundColor: Color(0xFFFC6707),
        duration: Duration(seconds: 2),
      ),
    );
  }
}