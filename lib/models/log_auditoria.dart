// Modelo Log de Auditoría
// Registra acciones importantes de los usuarios
class LogAuditoria {
  final String id;
  final String accionRealizada;
  final DateTime fechaHora;
  final String usuarioId;

  const LogAuditoria({
    required this.id,
    required this.accionRealizada,
    required this.fechaHora,
    required this.usuarioId,
  });

  factory LogAuditoria.fromMap(String id, Map<String, dynamic> map) {
    return LogAuditoria(
      id: id,
      accionRealizada: map['accionRealizada'] as String? ?? '',
      fechaHora: DateTime.tryParse(map['fechaHora'] as String? ?? '') ?? DateTime.now(),
      usuarioId: map['usuarioId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accionRealizada': accionRealizada,
      'fechaHora': fechaHora.toIso8601String(),
      'usuarioId': usuarioId,
    };
  }
}