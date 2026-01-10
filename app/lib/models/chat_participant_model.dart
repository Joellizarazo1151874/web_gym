class ChatParticipantModel {
  final int id;
  final String nombreCompleto;
  final String email;

  ChatParticipantModel({
    required this.id,
    required this.nombreCompleto,
    required this.email,
  });

  factory ChatParticipantModel.fromJson(Map<String, dynamic> json) {
    return ChatParticipantModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombreCompleto: json['nombre_completo']?.toString() ??
          '${json['nombre'] ?? ''} ${json['apellido'] ?? ''}'.trim(),
      email: json['email']?.toString() ?? '',
    );
  }
}

