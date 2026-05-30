// lib/models/usuario_model.dart
// Clase: Usuario — diagrama de clases Hito 1 SamanGo
// Atributos del diagrama: id, nombre, correo, rol
// Método del diagrama: modificarPerfil()

class Usuario {
  final String id;        // +id del diagrama
  final String nombre;    // +nombre del diagrama
  final String correo;    // +correo del diagrama (@correo.unimet.edu.ve)
  final String rol;       // +rol del diagrama: 'estudiante' | 'operador' | 'admin'
  final String? licenciaUrl; // extensión para Módulo 7 (subida de licencia de turismo)

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.licenciaUrl,
  });

  // ─── Serialización Firestore ──────────────────────────────────────────────

  factory Usuario.fromMap(String uid, Map<String, dynamic> map) {
    return Usuario(
      id: uid,
      nombre: map['nombre'] as String? ?? '',
      correo: map['correo'] as String? ?? '',
      rol: map['rol'] as String? ?? 'estudiante',
      licenciaUrl: map['licenciaUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      if (licenciaUrl != null) 'licenciaUrl': licenciaUrl,
    };
  }

  // ─── Estado vacío (sin sesión activa) ─────────────────────────────────────

  static const empty = Usuario(id: '', nombre: '', correo: '', rol: '');

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Retorna true si el usuario es Operador (puede subir licencia)
  bool get isOperador => rol == 'operador';

  /// Retorna true si el correo es institucional UNIMET
  bool get correoInstitucionalValido =>
      correo.endsWith('@correo.unimet.edu.ve');

  // ─── +modificarPerfil() del diagrama de clases ───────────────────────────
  // Retorna una COPIA inmutable del objeto con los campos actualizados.
  // La escritura en Firestore la hace el AuthController.
  Usuario modificarPerfil({
    String? nombre,
    String? licenciaUrl,
  }) {
    return Usuario(
      id: id,
      nombre: nombre ?? this.nombre,
      correo: correo,
      rol: rol,
      licenciaUrl: licenciaUrl ?? this.licenciaUrl,
    );
  }

  Usuario copyWith({
    String? id,
    String? nombre,
    String? correo,
    String? rol,
    String? licenciaUrl,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      licenciaUrl: licenciaUrl ?? this.licenciaUrl,
    );
  }
}
