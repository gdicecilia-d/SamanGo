// Punto de entrada principal
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SamanGoApp());
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFC6707), primary: const Color(0xFFFC6707)),
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      home: const HomeView(),
    );
  }
}