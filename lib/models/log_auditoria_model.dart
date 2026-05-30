// lib/models/log_auditoria_model.dart
// Clase: LogAuditoria — diagrama de clases Hito 1 SamanGo
// Atributos del diagrama: id, accionRealizada, fechaHora
// Relación del diagrama: Usuario (1) registra (*) LogAuditoria

class LogAuditoria {
  final String id;                // +id del diagrama
  final String accionRealizada;   // +accionRealizada: 'login' | 'logout' | 'upload_licencia'
  final DateTime fechaHora;       // +fechaHora del diagrama
  final String usuarioId;         // FK hacia Usuario (para la relación 'registra')

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
