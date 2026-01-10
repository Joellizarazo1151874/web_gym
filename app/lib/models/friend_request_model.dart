class FriendRequestModel {
  final int id;
  final int deUsuarioId;
  final int paraUsuarioId;
  final String nombreCompleto;
  final String email;
  final String estado;
  final String creadoEn;

  FriendRequestModel({
    required this.id,
    required this.deUsuarioId,
    required this.paraUsuarioId,
    required this.nombreCompleto,
    required this.email,
    required this.estado,
    required this.creadoEn,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      deUsuarioId: json['de_usuario_id'] is int
          ? json['de_usuario_id']
          : int.parse(json['de_usuario_id'].toString()),
      paraUsuarioId: json['para_usuario_id'] is int
          ? json['para_usuario_id']
          : int.parse(json['para_usuario_id'].toString()),
      nombreCompleto: json['nombre_completo']?.toString() ??
          '${json['nombre'] ?? ''} ${json['apellido'] ?? ''}'.trim(),
      email: json['email']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'pendiente',
      creadoEn: json['creado_en']?.toString() ?? '',
    );
  }
}

