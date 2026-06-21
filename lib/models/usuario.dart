// Modelo Usuario (Estudiante, Operador o Administrador)
class Usuario {
  final String id;
  final String nombre;
  final String? apellido;
  final String correo;
  final String rol;
  final String? licenciaUrl;
  final String? carnet;
  final String? fotoBase64;
  final String? fotoUrl;
  final String? fechaNacimiento;
  final String? empresa;
  final String? rif;
  final String? representante;
  final String? telefono;
  final String? descripcion;
  final String? carrera;
  final String? estado;
  final bool activo;

  const Usuario({
    required this.id,
    required this.nombre,
    this.apellido,
    required this.correo,
    required this.rol,
    this.licenciaUrl,
    this.carnet,
    this.fotoBase64,
    this.fotoUrl,
    this.fechaNacimiento,
    this.empresa,
    this.rif,
    this.representante,
    this.telefono,
    this.descripcion,
    this.carrera,
    this.estado,
    this.activo = true,
  });

  factory Usuario.fromMap(String uid, Map<String, dynamic> map) {
    return Usuario(
      id: uid,
      nombre: map['nombre'] as String? ?? '',
      apellido: map['apellido'] as String?,
      correo: map['correo'] as String? ?? '',
      rol: map['rol'] as String? ?? 'estudiante',
      licenciaUrl: map['licenciaUrl'] as String?,
      carnet: map['carnet'] as String?,
      fotoBase64: map['fotoBase64'] as String?,
      fotoUrl: map['fotoUrl'] as String?,
      fechaNacimiento: map['fechaNacimiento'] as String?,
      empresa: map['empresa'] as String?,
      rif: map['rif'] as String?,
      representante: map['representante'] as String?,
      telefono: map['telefono'] as String?,
      descripcion: map['descripcion'] as String?,
      carrera: map['carrera'] as String?,
      estado: map['estado'] as String?,
      activo: map['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      if (apellido != null) 'apellido': apellido,
      'correo': correo,
      'rol': rol,
      if (licenciaUrl != null) 'licenciaUrl': licenciaUrl,
      if (carnet != null) 'carnet': carnet,
      if (fotoBase64 != null) 'fotoBase64': fotoBase64,
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
      if (fechaNacimiento != null) 'fechaNacimiento': fechaNacimiento,
      if (empresa != null) 'empresa': empresa,
      if (rif != null) 'rif': rif,
      if (representante != null) 'representante': representante,
      if (telefono != null) 'telefono': telefono,
      if (descripcion != null) 'descripcion': descripcion,
      if (carrera != null) 'carrera': carrera,
      if (estado != null) 'estado': estado,
      'activo': activo,
    };
  }

  static const empty = Usuario(id: '', nombre: '', correo: '', rol: '', activo: true);

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;
  bool get isEstudiante => rol == 'estudiante';
  bool get isOperador => rol == 'operador';
  bool get isAdmin => rol == 'admin';

  String get primerNombre => nombre.split(' ').first;
}