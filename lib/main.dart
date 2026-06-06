import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/profile_controller.dart';
import 'views/home_view.dart';

// FUNCIÓN PARA CREAR OPERADOR 
Future<void> crearOperadorPrueba() async {
  try {
    // Intentar crear el usuario 
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: 'operador@samango.com',
      password: 'Operador2026',
    );
    
    String uid = userCredential.user!.uid;
    
    // Crear documento en Firestore 
    await FirebaseFirestore.instance.collection('operadores').doc(uid).set({
      'uid': uid,
      'nombre': 'Carlos Mendoza',
      'empresa': 'EcoRutas Venezuela',
      'correo': 'operador@samango.com',
      'rol': 'operador',
      'rif': 'J-40789234-5',
      'telefono': '04141234567',  
      'descripcion': 'Ofrecemos tours ecológicos y accesibles para toda la comunidad UNIMET.',
      'estado': 'aprobado',
      'licenciaUrl': '',
      'fotoUrl': '',
    });
    
  } catch (e) {
    // Si el usuario ya existe, no hace nada
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
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