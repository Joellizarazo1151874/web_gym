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
    // Manejar leida que puede venir como int (0/1) o bool
    bool leidaValue = false;
    if (json['leida'] != null) {
      if (json['leida'] is int) {
        leidaValue = (json['leida'] as int) == 1;
      } else if (json['leida'] is bool) {
        leidaValue = json['leida'] as bool;
      }
    }
    
    return NotificationModel(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      tipo: json['tipo'] as String? ?? 'info',
      leida: leidaValue,
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

