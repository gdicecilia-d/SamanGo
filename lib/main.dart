import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase con credenciales reales del proyecto "samango"
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    // ChangeNotifierProvider inyecta el AuthController en toda la app
    // Patrón Observer (Hito 2): todos los widgets que escuchen se reconstruyen al cambiar el estado
    ChangeNotifierProvider(
      create: (_) => AuthController()..tryAutoLogin(),
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
