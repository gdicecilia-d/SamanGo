// Ejecutar con 'flutter run -d chrome --web-port=5000' 
// ya que Google Sign-In requiere este puerto fijo autorizado 
// para evitar bloqueos de seguridad locales

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/notificacion_controller.dart';
import 'controllers/favoritos_controller.dart';
import 'controllers/reserva_controller.dart';
import 'views/home_view.dart';
import 'views/student/payment_view.dart';
import 'views/student/my_trips_view.dart';
import 'services/tips_notificacion_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => NotificacionController()),
        ChangeNotifierProvider(create: (_) => ReservaController()),
        ChangeNotifierProxyProvider<AuthController, FavoritosController>(
          create: (_) => FavoritosController(),
          update: (_, auth, favoritosController) =>
              favoritosController!..updateUsuario(auth.usuarioActual?.id ?? ''),
        ),
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