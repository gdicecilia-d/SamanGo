import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyA6s76jsIfHS5bFrCYrHqdu-Zr3BMK5lqQ",
      authDomain: "samango.firebaseapp.com",
      projectId: "samango",
      storageBucket: "samango.firebasestorage.app",
      messagingSenderId: "724873215169",
      appId: "1:724873215169:web:63a02db7860e5ef0c36840",
    );
  }
}