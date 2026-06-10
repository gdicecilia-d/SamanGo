// Ejecutar con 'flutter run -d chrome --web-port=5000' 
// ya que Google Sign-In requiere este puerto fijo autorizado 
// para evitar bloqueos de seguridad locales

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/notificacion_controller.dart';
import 'views/home_view.dart';
import 'services/tips_notificacion_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Iniciar el envío automático de tips 
  await TipsNotificacionService.iniciarTipsAutomaticos();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => NotificacionController()),
      ],
      child: const SamanGoApp(),
    ),
  );
}

class SamanGoApp extends StatelessWidget {
  const SamanGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SamanGo - Comunidad UNIMET',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFC6707),
          primary: const Color(0xFFFC6707),
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      home: const HomeView(),
    );
  }
}