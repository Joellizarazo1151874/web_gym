class SearchUserModel {
  final int id;
  final String nombreCompleto;
  final String email;

  SearchUserModel({
    required this.id,
    required this.nombreCompleto,
    required this.email,
  });

  factory SearchUserModel.fromJson(Map<String, dynamic> json) {
    return SearchUserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombreCompleto: json['nombre_completo']?.toString() ??
          '${json['nombre'] ?? ''} ${json['apellido'] ?? ''}'.trim(),
      email: json['email']?.toString() ?? '',
    );
  }
}

