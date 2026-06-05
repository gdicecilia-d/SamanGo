// Modelo Usuario (Estudiante, Operador o Administrador)
import 'package:cloud_firestore/cloud_firestore.dart';
class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final String? licenciaUrl;
  final String? carnet;
  final String? fotoUrl;
  final String? fechaNacimiento;
  final String? empresa;
  final String? rif;
  final String? representante;
  final String? telefono;
  final String? descripcion;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.licenciaUrl,
    this.carnet,
    this.fotoUrl,
    this.fechaNacimiento,
    this.empresa,
    this.rif,
    this.representante,
    this.telefono,
    this.descripcion,
  });

  factory Usuario.fromMap(String uid, Map<String, dynamic> map) {
    return Usuario(
      id: uid,
      nombre: map['nombre'] as String? ?? '',
      correo: map['correo'] as String? ?? '',
      rol: map['rol'] as String? ?? 'estudiante',
      licenciaUrl: map['licenciaUrl'] as String?,
      carnet: map['carnet'] as String?,
      fotoUrl: map['fotoUrl'] as String?,
      fechaNacimiento: map['fechaNacimiento'] as String?,
      empresa: map['empresa'] as String?,
      rif: map['rif'] as String?,
      representante: map['representante'] as String?,
      telefono: map['telefono'] as String?,
      descripcion: map['descripcion'] as String?,
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
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
      if (fechaNacimiento != null) 'fechaNacimiento': fechaNacimiento,
      if (empresa != null) 'empresa': empresa,
      if (rif != null) 'rif': rif,
      if (representante != null) 'representante': representante,
      if (telefono != null) 'telefono': telefono,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }

  static const empty = Usuario(id: '', nombre: '', correo: '', rol: '');

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;
  bool get isEstudiante => rol == 'estudiante';
  bool get isOperador => rol == 'operador';
  bool get isAdmin => rol == 'admin';
}
