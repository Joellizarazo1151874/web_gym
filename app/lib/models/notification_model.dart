class NotificationModel {
  final int id;
  final String titulo;
  final String mensaje;
  final String tipo;
  final bool leida;
  final String fecha;
  final String? fechaLeida;

  NotificationModel({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.fecha,
    this.fechaLeida,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      tipo: json['tipo'] as String? ?? 'info',
      leida: (json['leida'] as int? ?? 0) == 1 || (json['leida'] as bool? ?? false),
      fecha: json['fecha'] as String,
      fechaLeida: json['fecha_leida'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'leida': leida ? 1 : 0,
      'fecha': fecha,
      'fecha_leida': fechaLeida,
    };
  }
}

