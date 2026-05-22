import 'package:flutter/material.dart';
import '../models/commitment_model.dart';
import '../models/feature_model.dart';

class HomeController {
  // Estado del menú de navegación seleccionado
  String _selectedMenu = 'Inicio';
  
  // Getter para el menú seleccionado
  String get selectedMenu => _selectedMenu;

  // Lista de compromisos (Misión, Visión, Objetivo)
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

  // Lista de propuestas de valor (Checklist)
  final List<FeatureModel> features = const [
    FeatureModel(title: 'Exclusividad institucional'),
    FeatureModel(title: 'Precios low-cost'),
    FeatureModel(title: 'Seguridad con operadores verificados'),
    FeatureModel(title: 'Transparencia en cada reserva'),
  ];

  // Eventos y Acciones
  void selectMenuItem(String menu, VoidCallback onUpdate) {
    _selectedMenu = menu;
    onUpdate();
  }

  void handleLogin(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Iniciar Sesión presionado - SamanGo'),
        backgroundColor: Color(0xFFFC6707),
      ),
    );
  }

  void handleRegister(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registrarse presionado - SamanGo'),
        backgroundColor: Color(0xFFFC6707),
      ),
    );
  }

  void handleStartAdventure(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Empieza tu aventura! presionado - ¡Comienza tu viaje UNIMET!'),
        backgroundColor: Color(0xFFFC6707),
      ),
    );
  }
}
