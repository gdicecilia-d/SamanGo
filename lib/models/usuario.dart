// Modelo Usuario (Estudiante, Operador o Administrador)
class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final String? licenciaUrl;
  final String? carnet;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.licenciaUrl,
    this.carnet,
  });

  factory Usuario.fromMap(String uid, Map<String, dynamic> map) {
    return Usuario(
      id: uid,
      nombre: map['nombre'] as String? ?? '',
      correo: map['correo'] as String? ?? '',
      rol: map['rol'] as String? ?? 'estudiante',
      licenciaUrl: map['licenciaUrl'] as String?,
      carnet: map['carnet'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      if (licenciaUrl != null) 'licenciaUrl': licenciaUrl,
      if (carnet != null) 'carnet': carnet,
    };
  }

  static const empty = Usuario(id: '', nombre: '', correo: '', rol: '');

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;
  bool get isEstudiante => rol == 'estudiante';
  bool get isOperador => rol == 'operador';
  bool get isAdmin => rol == 'admin';
}
