class ChatModel {
  final int id;
  final String nombre;
  final bool esGrupal;
  final String creadoEn;
  final String? ultimoMensaje;
  final String? ultimoMensajeEn;
  final String? ultimoRemitente;
  final int unreadCount;

  ChatModel({
    required this.id,
    required this.nombre,
    required this.esGrupal,
    required this.creadoEn,
    required this.ultimoMensaje,
    required this.ultimoMensajeEn,
    required this.ultimoRemitente,
    required this.unreadCount,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre']?.toString() ?? 'Chat',
      esGrupal: json['es_grupal'] == true ||
          json['es_grupal'] == 1 ||
          json['es_grupal'] == '1',
      creadoEn: json['creado_en']?.toString() ?? '',
      ultimoMensaje: json['ultimo_mensaje']?.toString(),
      ultimoMensajeEn: json['ultimo_mensaje_en']?.toString(),
      ultimoRemitente: json['ultimo_remitente']?.toString(),
      unreadCount: json['unread_count'] is int
          ? json['unread_count']
          : int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
    );
  }
}

