import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/home_view.dart';

void main() {
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
        // Color semilla naranja #FC6707
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFC6707),
          primary: const Color(0xFFFC6707),
          surface: const Color(0xFFF5F5F5),
        ),
        // Tipografía global de la aplicación usando Google Fonts
        textTheme: GoogleFonts.outfitTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const HomeView(),
    );
  }
}
