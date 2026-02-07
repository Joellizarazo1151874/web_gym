class PostModel {
  final int id;
  final int usuarioId;
  final String usuarioNombre;
  final String contenido;
  final String? usuarioFoto;
  final String? imagenUrl;
  final String creadoEn;
  final String? hace;
  final int likesCount;
  final bool likedByCurrent;

  PostModel({
    required this.id,
    required this.usuarioId,
    required this.usuarioNombre,
    this.usuarioFoto,
    required this.contenido,
    required this.imagenUrl,
    required this.creadoEn,
    required this.hace,
    required this.likesCount,
    required this.likedByCurrent,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      usuarioId: json['usuario_id'] is int
          ? json['usuario_id']
          : int.parse(json['usuario_id'].toString()),
      usuarioNombre: json['usuario_nombre']?.toString() ??
          '${json['nombre'] ?? ''} ${json['apellido'] ?? ''}'.trim(),
      usuarioFoto: json['usuario_foto']?.toString(),
      contenido: json['contenido']?.toString() ?? '',
      imagenUrl: json['imagen_url']?.toString(),
      creadoEn: json['creado_en']?.toString() ?? '',
      hace: json['hace']?.toString(),
      likesCount: json['likes_count'] is int
          ? json['likes_count']
          : int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      likedByCurrent: json['liked_by_current'] == true ||
          json['liked_by_current'] == 1 ||
          json['liked_by_current'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'usuario_nombre': usuarioNombre,
      'contenido': contenido,
      'imagen_url': imagenUrl,
      'creado_en': creadoEn,
      'hace': hace,
      'likes_count': likesCount,
      'liked_by_current': likedByCurrent,
    };
  }
}

