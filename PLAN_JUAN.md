# PLAN_JUAN.md — Especificación Técnica de Implementación v3.0
## Proyecto: SamanGo | Responsable: Juan
### Módulos: 2 (Gestión de Estado de Autenticación) y 7 (Subida de Archivos a Firebase Storage)
### Basado en: Diagrama de Clases oficial — Hito 1 · Sistemas de Información

---

> **VERSIÓN 3.0 — POST-MERGE con rama de compañeros (origin/main)**
> El análisis de esta versión parte del código **actual del repositorio**, incluyendo los
> archivos de autenticación (`lib/views/auth/`) y la configuración real de Firebase
> (`lib/firebase_options.dart`) aportados por el equipo.

---

## DIAGRAMA DE CLASES — HITO 1 (referencia oficial)

```
┌──────────────────────┐        1..*  ┌──────────────────────┐       *   ┌───────────────────────────┐        ┌────────────────────┐
│       Usuario        │─────crea────►│   PaqueteTuristico   │─contiene─►│        Reserva            │──────► │   EstadoReserva    │
│──────────────────────│              │──────────────────────│           │───────────────────────────│  <<e>> │────────────────────│
│ +id                  │   1          │ +id                  │    1      │ +id                       │        │ Solicitado         │
│ +nombre              │              │ +vendedorId          │           │ +estudianteId             │        │ Aceptado           │
│ +correo        │              │ +precio              │           │ +paqueteId                │        │ Pagado             │
│ +rol                 │              │ +capacidad           │           │ +estadoActual             │        │ Disfrutado         │
│──────────────────────│              │ +locacion            │           │───────────────────────────│        └────────────────────┘
│ +modificarPerfil()   │              │──────────────────────│           │ +simularPago()            │
└──────────────────────┘              │ +publicar()          │           │ +actualizarEstado()       │
          │ 1                         └──────────────────────┘           └───────────────────────────┘
          │
       registra
          │
          ▼ *
┌──────────────────────┐
│     LogAuditoria     │
│──────────────────────│
│ +id                  │
│ +accionRealizada     │
│ +fechaHora           │
└──────────────────────┘
```

---

## ANÁLISIS DEL ESTADO ACTUAL (post-merge)

### Lo que ya existe (NO tocar)

| Archivo | Estado | Descripción |
|---|---|---|
| `lib/firebase_options.dart` | ✅ REAL | Credenciales reales del proyecto Firebase "samango" |
| `lib/main.dart` | ✅ Listo | Firebase inicializado con `DefaultFirebaseOptions.currentPlatform` |
| `lib/views/auth/login_view.dart` | ✅ UI lista | Diseño completo. Botón llama `print()` — **FALTA conectar Firebase** |
| `lib/views/auth/register_operator_view.dart` | ✅ UI lista | Formulario completo incluyendo el widget de "Subir Licencia". **FALTA toda la lógica** |
| `lib/views/auth/register_student_view.dart` | ✅ UI lista | Formulario completo. **FALTA lógica** |
| `lib/views/auth/select_role_view.dart` | ✅ UI lista | Selección de rol. Sin lógica pendiente para Juan |
| `lib/views/auth/forgot_password_view.dart` | ✅ UI lista | Vista de recuperar contraseña. Sin lógica para Juan |
| `lib/views/auth/auth_base_view.dart` | ✅ UI lista | Layout base compartido por todas las pantallas auth |
| `lib/views/widgets/header_widget.dart` | ⚠️ MODIFICAR | Muestra botones estáticos — debe reaccionar al estado de sesión |
| `lib/controllers/home_controller.dart` | ✅ Listo | Ya navega a `LoginView` y `SelectRoleView` correctamente |
| `lib/models/` | ⚠️ INCOMPLETO | Solo hay modelos UI estáticos — faltan los 5 modelos del diagrama |

### Dependencias disponibles en pubspec.yaml

```yaml
firebase_core: ^4.9.0    ✅ Disponible
firebase_auth: ^6.5.1    ✅ Disponible
cloud_firestore: ^6.4.1  ✅ Disponible
firebase_storage:        ❌ FALTA — necesaria para Módulo 7
file_picker:             ❌ FALTA — necesaria para seleccionar PDF en Web
provider:                ❌ FALTA — necesaria para estado global
shared_preferences:      ❌ FALTA — necesaria para persistencia Web
```

### Diferencia crítica respecto a versiones anteriores del plan
- **Firebase YA está configurado con credenciales reales** (`firebase_options.dart`).
- **Las pantallas de auth YA existen** — solo falta conectarles la lógica.
- El botón de "Iniciar Sesión" en `login_view.dart` actualmente solo hace `print()`.
- El área de "Subir Licencia" en `register_operator_view.dart` solo hace `print()`.
- **NO hay `Provider` ni ningún gestor de estado global** — `main.dart` llama directamente a `HomeView()`.

---

## MÓDULO 2 — GESTIÓN DE ESTADO DE AUTENTICACIÓN

### Objetivo
Conectar la pantalla `LoginView` existente con Firebase Auth real, guardar el `UsuarioModel`
en estado global usando `Provider`, persistir la sesión en Flutter Web con `shared_preferences`,
y actualizar el `HeaderWidget` para que refleje si hay sesión activa o no.

---

### PASO 2.1 — Agregar dependencias faltantes al pubspec.yaml

**Archivo a modificar**: `pubspec.yaml`

Agregar dentro de `dependencies:`, sin eliminar lo existente:

```yaml
  # --- Gestión de estado global ---
  provider: ^6.1.2

  # --- Persistencia de sesión Web (localStorage) ---
  shared_preferences: ^2.3.2

  # --- Firebase Storage (para Módulo 7) ---
  firebase_storage: ^13.4.1

  # --- Selección de archivos en Web (PDF/imagen) ---
  file_picker: ^8.3.7
```

Ejecutar en terminal:
```bash
flutter pub get
```

---

### PASO 2.2 — Crear los modelos del Diagrama de Clases

**NINGUNO de los 5 modelos del diagrama de clases existe actualmente.**
Todos se crean como archivos nuevos en `lib/models/`.

#### PASO 2.2.1 — `lib/models/estado_reserva.dart` [NUEVO]

```dart
// Enum EstadoReserva — valores exactos del diagrama Hito 1
enum EstadoReserva {
  solicitado,  // reserva recién creada
  aceptado,    // Operador aprobó
  pagado,      // pago completado
  disfrutado,  // viaje completado
}

extension EstadoReservaExtension on EstadoReserva {
  String toMap() => name;

  String get label {
    switch (this) {
      case EstadoReserva.solicitado: return 'Solicitado';
      case EstadoReserva.aceptado:   return 'Aceptado';
      case EstadoReserva.pagado:     return 'Pagado';
      case EstadoReserva.disfrutado: return 'Disfrutado';
    }
  }
}

EstadoReserva estadoReservaFromString(String value) {
  return EstadoReserva.values.firstWhere(
    (e) => e.name == value.toLowerCase(),
    orElse: () => EstadoReserva.solicitado,
  );
}
```

#### PASO 2.2.2 — `lib/models/usuario_model.dart` [NUEVO]

Atributos exactos del diagrama: `id`, `nombre`, `correo`, `rol`.
Método exacto del diagrama: `modificarPerfil()`.
Se agrega `licenciaUrl` como extensión propia del Módulo 7.

```dart
class UsuarioModel {
  final String id;            // +id del diagrama
  final String nombre;        // +nombre del diagrama
  final String correo;  // +correo del diagrama
  final String rol;           // +rol: 'estudiante' | 'operador' | 'admin'
  final String? licenciaUrl;  // extensión para Módulo 7

  const UsuarioModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.licenciaUrl,
  });

  factory UsuarioModel.fromMap(String uid, Map<String, dynamic> map) {
    return UsuarioModel(
      id: uid,
      nombre: map['nombre'] as String? ?? '',
      correo: map['correo'] as String? ?? '',
      rol: map['rol'] as String? ?? 'estudiante',
      licenciaUrl: map['licenciaUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'correo': correo,
    'rol': rol,
    if (licenciaUrl != null) 'licenciaUrl': licenciaUrl,
  };

  static const empty = UsuarioModel(id: '', nombre: '', correo: '', rol: '');
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;
  bool get isOperador => rol == 'operador';

  // +modificarPerfil() del diagrama — retorna copia con campos actualizados
  UsuarioModel modificarPerfil({String? nombre, String? licenciaUrl}) {
    return UsuarioModel(
      id: id,
      nombre: nombre ?? this.nombre,
      correo: correo,
      rol: rol,
      licenciaUrl: licenciaUrl ?? this.licenciaUrl,
    );
  }

  UsuarioModel copyWith({String? id, String? nombre, String? correo, String? rol, String? licenciaUrl}) {
    return UsuarioModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      licenciaUrl: licenciaUrl ?? this.licenciaUrl,
    );
  }
}
```

#### PASO 2.2.3 — `lib/models/log_auditoria_model.dart` [NUEVO]

```dart
// Relación del diagrama: Usuario (1) registra (*) LogAuditoria
class LogAuditoriaModel {
  final String id;
  final String accionRealizada;  // 'login' | 'logout' | 'upload_licencia'
  final DateTime fechaHora;
  final String usuarioId;        // FK hacia Usuario

  const LogAuditoriaModel({
    required this.id,
    required this.accionRealizada,
    required this.fechaHora,
    required this.usuarioId,
  });

  factory LogAuditoriaModel.fromMap(String id, Map<String, dynamic> map) {
    return LogAuditoriaModel(
      id: id,
      accionRealizada: map['accionRealizada'] as String? ?? '',
      fechaHora: DateTime.tryParse(map['fechaHora'] as String? ?? '') ?? DateTime.now(),
      usuarioId: map['usuarioId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'accionRealizada': accionRealizada,
    'fechaHora': fechaHora.toIso8601String(),
    'usuarioId': usuarioId,
  };
}
```

#### PASO 2.2.4 — `lib/models/paquete_turistico_model.dart` [NUEVO — skeleton]

```dart
// Atributos del diagrama: id, vendedorId, precio, capacidad, locacion
// Método del diagrama: publicar() — se implementa en su controlador
class PaqueteTuristicoModel {
  final String id;
  final String vendedorId;
  final double precio;
  final int capacidad;
  final String locacion;

  const PaqueteTuristicoModel({
    required this.id,
    required this.vendedorId,
    required this.precio,
    required this.capacidad,
    required this.locacion,
  });

  factory PaqueteTuristicoModel.fromMap(String id, Map<String, dynamic> map) {
    return PaqueteTuristicoModel(
      id: id,
      vendedorId: map['vendedorId'] as String? ?? '',
      precio: (map['precio'] as num?)?.toDouble() ?? 0.0,
      capacidad: map['capacidad'] as int? ?? 0,
      locacion: map['locacion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'vendedorId': vendedorId,
    'precio': precio,
    'capacidad': capacidad,
    'locacion': locacion,
  };
}
```

#### PASO 2.2.5 — `lib/models/reserva_model.dart` [NUEVO — skeleton]

```dart
import 'estado_reserva.dart';

// Atributos del diagrama: id, estudianteId, paqueteId, estadoActual
// Métodos del diagrama: simularPago(), actualizarEstado() — en su controlador
class ReservaModel {
  final String id;
  final String estudianteId;
  final String paqueteId;
  final EstadoReserva estadoActual;

  const ReservaModel({
    required this.id,
    required this.estudianteId,
    required this.paqueteId,
    required this.estadoActual,
  });

  factory ReservaModel.fromMap(String id, Map<String, dynamic> map) {
    return ReservaModel(
      id: id,
      estudianteId: map['estudianteId'] as String? ?? '',
      paqueteId: map['paqueteId'] as String? ?? '',
      estadoActual: estadoReservaFromString(map['estadoActual'] as String? ?? 'solicitado'),
    );
  }

  Map<String, dynamic> toMap() => {
    'estudianteId': estudianteId,
    'paqueteId': paqueteId,
    'estadoActual': estadoActual.toMap(),
  };

  ReservaModel copyWith({EstadoReserva? estadoActual}) {
    return ReservaModel(id: id, estudianteId: estudianteId, paqueteId: paqueteId,
        estadoActual: estadoActual ?? this.estadoActual);
  }
}
```

---

### PASO 2.3 — Crear el AuthController [NUEVO]

**Archivo nuevo**: `lib/controllers/auth_controller.dart`

Este controlador centraliza toda la lógica de autenticación. Es un `ChangeNotifier` que
el `Provider` en `main.dart` inyectará en toda la app.

**Responsabilidades**:
1. Exponer `currentUser` (tipo `UsuarioModel`) a toda la app
2. Método `login(email, password)` — llama a Firebase Auth real
3. Método `logout()` — cierra sesión y limpia estado
4. Método `tryAutoLogin()` — restaura sesión al recargar la página web
5. Método `updateUserLocally()` — usado por el LicenciaController del Módulo 7
6. Registrar `LogAuditoria` en Firestore en cada acción

**Estructura de imports necesarios**:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_model.dart';
import '../models/log_auditoria_model.dart';
```

**Getters públicos que debe exponer**:
```dart
UsuarioModel get currentUser     // UsuarioModel.empty si no hay sesión
bool get isLoading               // true mientras se procesa login/logout
String? get errorMessage         // null si no hay error
bool get isLoggedIn              // true si currentUser.isNotEmpty
```

**Método login() — flujo exacto**:
```
1. _setLoading(true)
2. FirebaseAuth.signInWithEmailAndPassword(email, password)
3. Guardar uid en SharedPreferences (clave: 'samango_logged_uid')
4. Leer documento 'users/{uid}' de Firestore
   → Si existe: cargar UsuarioModel.fromMap()
   → Si NO existe: crear documento con datos de FirebaseAuth.currentUser
5. _registrarLog(uid, 'login') → escribe en colección 'logs'
6. _setLoading(false) + notifyListeners()
7. Retornar null (éxito) o String con mensaje de error
```

**Método tryAutoLogin() — flujo exacto**:
```
1. Leer uid de SharedPreferences
2. Si no hay uid → return (no hacer nada)
3. Verificar FirebaseAuth.currentUser != null y uid coincide
4. Si coincide → _loadUserFromFirestore(uid)
5. Si no coincide → limpiar SharedPreferences
```

**Método logout() — flujo exacto**:
```
1. Guardar uid antes de limpiar
2. FirebaseAuth.signOut()
3. SharedPreferences.remove('samango_logged_uid')
4. _registrarLog(uid, 'logout')
5. _currentUser = UsuarioModel.empty
6. notifyListeners()
```

**Mapa de errores Firebase → español** (para `_mapFirebaseAuthError(code)`):
```
'user-not-found'        → 'No existe una cuenta con ese correo.'
'wrong-password'        → 'Contraseña incorrecta.'
'invalid-email'         → 'El correo no tiene un formato válido.'
'invalid-credential'    → 'Correo o contraseña incorrectos.'
'user-disabled'         → 'Esta cuenta ha sido deshabilitada.'
'too-many-requests'     → 'Demasiados intentos. Espera un momento.'
'network-request-failed'→ 'Sin conexión a internet.'
default                 → 'Error de autenticación ($code).'
```

---

### PASO 2.4 — Actualizar main.dart para inyectar el Provider

**Archivo a modificar**: `lib/main.dart`

Cambios mínimos y precisos. El `MaterialApp` y el tema no deben modificarse en absoluto.

**Agregar imports**:
```dart
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
```

**Envolver `SamanGoApp` en `ChangeNotifierProvider`**:
```dart
runApp(
  ChangeNotifierProvider(
    create: (_) => AuthController()..tryAutoLogin(),
    child: const SamanGoApp(),
  ),
);
```

El resto de `main.dart` (Firebase.initializeApp, tema, `home: const HomeView()`) permanece **intacto**.

---

### PASO 2.5 — Conectar LoginView con el AuthController

**Archivo a modificar**: `lib/views/auth/login_view.dart`

> ⚠️ RESTRICCIÓN: No modificar el diseño visual (colores, fuentes, layout). Solo agregar
> la lógica de conexión con Firebase. Los `TextFields` existentes deben convertirse en
> `TextFormField` para poder agregar `controllers` y que Jesús pueda agregar `validators`.

**Cambios requeridos**:

1. **Agregar imports**:
   ```dart
   import 'package:provider/provider.dart';
   import '../../controllers/auth_controller.dart';
   ```

2. **Agregar en `_LoginViewState`**:
   ```dart
   final _formKey = GlobalKey<FormState>();
   final _emailController = TextEditingController();
   final _passwordController = TextEditingController();
   ```

3. **Agregar `dispose()`**:
   ```dart
   @override
   void dispose() {
     _emailController.dispose();
     _passwordController.dispose();
     super.dispose();
   }
   ```

4. **Envolver el contenido del formulario en `Form(key: _formKey, ...)`**

5. **Convertir `TextField` de correo a `TextFormField`**:
   - Asignar `controller: _emailController`
   - Agregar comentario: `// validator: — IMPLEMENTAR POR JESÚS`

6. **Convertir `TextField` de contraseña a `TextFormField`**:
   - Asignar `controller: _passwordController`
   - Agregar comentario: `// validator: — IMPLEMENTAR POR JESÚS`

7. **Reemplazar el `onPressed` del botón "Iniciar Sesión"** (actualmente hace `print()`):
   ```dart
   onPressed: () async {
     if (!_formKey.currentState!.validate()) return;
     final auth = context.read<AuthController>();
     final error = await auth.login(
       email: _emailController.text,
       password: _passwordController.text,
     );
     if (!mounted) return;
     if (error == null) {
       // Navegar según rol
       final rol = auth.currentUser.rol;
       if (rol == 'operador') {
         // TODO: Navigator a dashboard del operador (pantalla pendiente)
         // Por ahora: volver al Home
         Navigator.of(context).popUntil((route) => route.isFirst);
       } else {
         // TODO: Navigator a dashboard del estudiante (pantalla pendiente)
         Navigator.of(context).popUntil((route) => route.isFirst);
       }
     }
   }
   ```

8. **Agregar `Consumer<AuthController>` para mostrar el error y el indicador de carga**
   justo encima del botón "Iniciar Sesión":
   ```dart
   Consumer<AuthController>(
     builder: (context, auth, _) {
       return Column(
         children: [
           if (auth.errorMessage != null) ...[
             Text(
               auth.errorMessage!,
               style: GoogleFonts.outfit(color: Colors.red.shade700, fontSize: 13),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 12),
           ],
           // El botón existente cambia su onPressed + muestra CircularProgressIndicator
           // cuando auth.isLoading == true
         ],
       );
     },
   )
   ```

9. **El botón de Google** (actualmente hace `print()`) queda como está — no es tarea de Juan.

---

### PASO 2.6 — Actualizar HeaderWidget para reaccionar al estado de sesión

**Archivo a modificar**: `lib/views/widgets/header_widget.dart`

Cuando `AuthController.isLoggedIn == true`, el header reemplaza los botones
"Iniciar Sesión" / "Registrarse" por el nombre del usuario y un botón "Cerrar Sesión".
**El diseño visual de los botones se mantiene idéntico al original.**

**Agregar imports**:
```dart
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
```

**Reemplazar el `Row` de botones desktop (líneas 73-98 del archivo actual)**
con un `Consumer<AuthController>`:

```dart
Consumer<AuthController>(
  builder: (context, auth, _) {
    if (auth.isLoggedIn) {
      // Usuario logueado: mostrar nombre + botón Cerrar Sesión
      return Row(
        children: [
          Text(
            'Hola, ${auth.currentUser.nombre}',
            style: GoogleFonts.outfit(
              color: const Color(0xFF333333),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: () => context.read<AuthController>().logout(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFC6707), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Cerrar Sesión',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFC6707),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }
    // Sin sesión: mantener EXACTAMENTE los botones originales
    return Row(
      children: [
        OutlinedButton(/* ... código original de Iniciar Sesión ... */),
        const SizedBox(width: 12),
        ElevatedButton(/* ... código original de Registrarse ... */),
      ],
    );
  },
),
```

---

### PASO 2.7 — Estructura de Firestore (referencia)

```
Firestore Database
├── users/                          → Clase: Usuario (diagrama)
│   └── {uid}/
│       ├── nombre: "Juan Pérez"
│       ├── correo: "juan@correo.unimet.edu.ve"
│       ├── rol: "estudiante" | "operador" | "admin"
│       └── licenciaUrl: null | "https://storage.googleapis.com/..."
│
├── paquetes/                       → Clase: PaqueteTuristico (diagrama)
├── reservas/                       → Clase: Reserva (diagrama)
└── logs/                           → Clase: LogAuditoria (diagrama)
    └── {logId}/
        ├── usuarioId: "{uid}"
        ├── accionRealizada: "login" | "logout" | "upload_licencia"
        └── fechaHora: "2026-05-30T18:00:00.000"
```

---

## MÓDULO 7 — SUBIDA DE ARCHIVOS A FIREBASE STORAGE

### Objetivo
Conectar el área "Subir Licencia de Turismo" **ya existente** en `register_operator_view.dart`
con Firebase Storage. El `GestureDetector` de esa sección actualmente hace `print('Seleccionar archivo')`.
Debe reemplazarse con la lógica real de selección, subida y guardado de URL.

> **IMPORTANTE**: La licencia se sube durante el REGISTRO del Operador. NO es una pantalla aparte.
> El widget que hay que modificar está dentro de `lib/views/auth/register_operator_view.dart`.

---

### PASO 7.1 — Crear el StorageService

**Archivo nuevo**: `lib/services/storage_service.dart`

```dart
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Ruta en Storage: /licencias/{uid}.{ext}
  // Si se vuelve a subir, sobreescribe el anterior (mismo nombre)
  Future<String> uploadLicencia({
    required String uid,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final extension = fileName.split('.').last.toLowerCase();
    final ref = _storage.ref().child('licencias/$uid.$extension');
    final metadata = SettableMetadata(contentType: _getContentType(extension));
    final uploadTask = await ref.putData(fileBytes, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'pdf':  return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      default:     return 'application/octet-stream';
    }
  }
}
```

---

### PASO 7.2 — Crear el LicenciaController

**Archivo nuevo**: `lib/controllers/licencia_controller.dart`

Este controlador es un `ChangeNotifier` LOCAL — se crea con `ChangeNotifierProvider`
directamente dentro del widget de registro, no en `main.dart`.

**Responsabilidades**:
1. Gestionar la selección de archivo via `FilePicker` (con `withData: true` para Flutter Web)
2. Validar tamaño máximo (5 MB) y tipos permitidos (pdf, jpg, jpeg, png)
3. Subir el archivo a Storage vía `StorageService`
4. Persistir la URL en Firestore (`users/{uid}/licenciaUrl`)
5. Llamar a `UsuarioModel.modificarPerfil()` para actualizar el estado local
6. Registrar `LogAuditoria` con acción `'upload_licencia'`

**Getters públicos**:
```dart
bool get isUploading
double get uploadProgress  // 0.0 a 1.0
String? get errorMessage
String? get successMessage
String? get selectedFileName
```

**Método principal `pickAndUploadLicencia(AuthController authController)`**:
```
Flujo:
1. Validar rol == 'operador' (solo Operadores pueden subir licencia)
2. FilePicker.platform.pickFiles(type: FileType.custom,
      allowedExtensions: ['pdf','jpg','jpeg','png'],
      withData: true)  ← CRÍTICO para Flutter Web
3. Validar file.size <= 5 * 1024 * 1024 (5 MB)
4. Validar file.bytes != null
5. _isUploading = true + notifyListeners()
6. StorageService.uploadLicencia(uid, bytes, fileName) → downloadUrl
7. Firestore: db.collection('users').doc(uid).update({'licenciaUrl': downloadUrl})
8. authController.updateUserLocally(
     authController.currentUser.modificarPerfil(licenciaUrl: downloadUrl)
   )
9. Firestore: db.collection('logs').add(LogAuditoriaModel(...).toMap())
10. _successMessage = '¡Licencia subida exitosamente!'
11. _isUploading = false + notifyListeners()
```

---

### PASO 7.3 — Modificar RegisterOperatorView para usar el LicenciaController

**Archivo a modificar**: `lib/views/auth/register_operator_view.dart`

> ⚠️ RESTRICCIÓN: No modificar el diseño visual. Solo conectar la lógica al `GestureDetector`
> existente del área "Subir Licencia de Turismo".

**Cambios requeridos**:

1. **Agregar imports**:
   ```dart
   import 'package:provider/provider.dart';
   import '../../controllers/auth_controller.dart';
   import '../../controllers/licencia_controller.dart';
   ```

2. **Envolver el `AuthBaseView` en un `ChangeNotifierProvider<LicenciaController>`**:
   ```dart
   @override
   Widget build(BuildContext context) {
     return ChangeNotifierProvider(
       create: (_) => LicenciaController(),
       child: Consumer<LicenciaController>(
         builder: (context, licenciaCtrl, _) {
           return AuthBaseView(
             // ... mismo contenido actual ...
           );
         },
       ),
     );
   }
   ```

3. **Reemplazar el `onTap` del `GestureDetector` de "Subir Licencia"** (actualmente `print()`):
   ```dart
   onTap: licenciaCtrl.isUploading
     ? null
     : () {
         final auth = context.read<AuthController>();
         licenciaCtrl.pickAndUploadLicencia(auth);
       },
   ```

4. **Actualizar el texto del área de selección** para mostrar el nombre del archivo:
   ```dart
   Text(
     licenciaCtrl.selectedFileName ?? 'Seleccionar Archivos',
     style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF666666)),
   ),
   ```

5. **Agregar indicador visual de progreso** justo debajo del área de selección:
   ```dart
   if (licenciaCtrl.isUploading)
     LinearProgressIndicator(
       value: licenciaCtrl.uploadProgress,
       backgroundColor: const Color(0xFFFFDDBB),
       valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFC6707)),
     ),
   if (licenciaCtrl.successMessage != null)
     Text(licenciaCtrl.successMessage!,
       style: GoogleFonts.outfit(color: Colors.green.shade700, fontSize: 12)),
   if (licenciaCtrl.errorMessage != null)
     Text(licenciaCtrl.errorMessage!,
       style: GoogleFonts.outfit(color: Colors.red.shade700, fontSize: 12)),
   ```

6. **El botón "Solicitar Registro"** (`_showSuccessDialog`) permanece igual por ahora.
   La conexión completa del registro al backend es responsabilidad de quien maneje el
   formulario de Registro.

---

### PASO 7.4 — Estructura de Firebase Storage

```
Firebase Storage (proyecto: samango.firebasestorage.app)
└── licencias/
    ├── {uid_operador_1}.pdf     ← licencia en PDF
    ├── {uid_operador_2}.jpg     ← licencia en JPG
    └── {uid_operador_3}.png    ← licencia en PNG
```

**Reglas de seguridad de Storage (para configurar en consola Firebase)**:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /licencias/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.resource.size < 5 * 1024 * 1024
                   && (request.resource.contentType.matches('image/.*')
                       || request.resource.contentType == 'application/pdf');
    }
  }
}
```

---

## ESTRUCTURA DE ARCHIVOS RESULTANTE

```
lib/
├── main.dart                                   [MODIFICAR] — agregar Provider wrapper
├── firebase_options.dart                       [NO TOCAR] — credenciales reales ya configuradas
│
├── models/
│   ├── usuario_model.dart                      [NUEVO] ← clase Usuario del diagrama
│   ├── estado_reserva.dart                     [NUEVO] ← enum EstadoReserva del diagrama
│   ├── paquete_turistico_model.dart            [NUEVO] ← skeleton PaqueteTuristico
│   ├── reserva_model.dart                      [NUEVO] ← skeleton Reserva
│   ├── log_auditoria_model.dart                [NUEVO] ← clase LogAuditoria del diagrama
│   ├── commitment_model.dart                   [NO TOCAR]
│   ├── destination_model.dart                  [NO TOCAR]
│   └── feature_model.dart                      [NO TOCAR]
│
├── controllers/
│   ├── auth_controller.dart                    [NUEVO] ← estado global de autenticación
│   ├── licencia_controller.dart                [NUEVO] ← flujo de subida de licencia
│   └── home_controller.dart                    [NO TOCAR] — ya navega correctamente
│
├── services/
│   └── storage_service.dart                    [NUEVO] ← interacción con Firebase Storage
│
└── views/
    ├── home_view.dart                          [NO TOCAR]
    └── auth/
        ├── login_view.dart                     [MODIFICAR] ← conectar Firebase Auth
        ├── register_operator_view.dart         [MODIFICAR] ← conectar LicenciaController
        ├── auth_base_view.dart                 [NO TOCAR]
        ├── forgot_password_view.dart           [NO TOCAR]
        ├── register_student_view.dart          [NO TOCAR — responsabilidad de otro]
        └── select_role_view.dart               [NO TOCAR]
    └── widgets/
        ├── header_widget.dart                  [MODIFICAR] ← reaccionar al estado de sesión
        ├── base_scaffold.dart                  [NO TOCAR]
        ├── commitment_widget.dart              [NO TOCAR]
        ├── contact_widget.dart                 [NO TOCAR]
        ├── destinations_widget.dart            [NO TOCAR]
        ├── features_widget.dart                [NO TOCAR]
        └── hero_widget.dart                    [NO TOCAR]
```

---

## ORDEN DE IMPLEMENTACIÓN RECOMENDADO

| # | Archivo | Acción | Bloquea a |
|---|---|---|---|
| 1 | `pubspec.yaml` | Agregar 4 dependencias | Todo lo demás |
| 2 | `lib/models/estado_reserva.dart` | Crear | `reserva_model.dart` |
| 3 | `lib/models/usuario_model.dart` | Crear | `auth_controller.dart` |
| 4 | `lib/models/log_auditoria_model.dart` | Crear | `auth_controller.dart` |
| 5 | `lib/models/paquete_turistico_model.dart` | Crear | — |
| 6 | `lib/models/reserva_model.dart` | Crear | — |
| 7 | `lib/controllers/auth_controller.dart` | Crear | `main.dart`, `login_view.dart`, `header_widget.dart` |
| 8 | `lib/main.dart` | Modificar | Toda la UI |
| 9 | `lib/views/auth/login_view.dart` | Modificar | — |
| 10 | `lib/views/widgets/header_widget.dart` | Modificar | — |
| 11 | `lib/services/storage_service.dart` | Crear | `licencia_controller.dart` |
| 12 | `lib/controllers/licencia_controller.dart` | Crear | `register_operator_view.dart` |
| 13 | `lib/views/auth/register_operator_view.dart` | Modificar | — |

---

## NOTAS FINALES

- **Firebase está 100% configurado** con credenciales reales. No es necesario ejecutar `flutterfire configure`.
- Las **validaciones de formularios** (campos obligatorios, formato de correo, longitud de contraseña) son responsabilidad de **Jesús** — dejar comentarios `// validator: — IMPLEMENTAR POR JESÚS` en los TextFormFields.
- El **botón de Google** en `LoginView` no es tarea de Juan — dejarlo como está.
- El **flujo completo de Registro** (enviar datos a Firestore para Estudiante y Operador) tampoco es tarea de Juan — solo la parte de subida de licencia y el estado de sesión post-login.
