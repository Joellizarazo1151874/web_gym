class ChatMessageModel {
  final int id;
  final int chatId;
  final int remitenteId;
  final String remitenteNombre;
  final String mensaje;
  final String? imagenUrl;
  final String creadoEn;
  final bool leido;

  ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.remitenteId,
    required this.remitenteNombre,
    required this.mensaje,
    this.imagenUrl,
    required this.creadoEn,
    required this.leido,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      chatId:
          json['chat_id'] is int ? json['chat_id'] : int.parse(json['chat_id'].toString()),
      remitenteId: json['remitente_id'] is int
          ? json['remitente_id']
          : int.parse(json['remitente_id'].toString()),
      remitenteNombre: json['remitente_nombre']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      imagenUrl: json['imagen_url']?.toString(),
      creadoEn: json['creado_en']?.toString() ?? '',
      leido: json['leido'] == true ||
          json['leido'] == 1 ||
          json['leido'] == '1',
    );
  }
}

