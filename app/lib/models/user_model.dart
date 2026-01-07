class UserModel {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String? telefono;
  final String? documento;
  final String? foto;
  final String? rol;

  UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.telefono,
    this.documento,
    this.foto,
    this.rol,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      email: json['email'] as String,
      telefono: json['telefono'] as String?,
      documento: json['documento'] as String?,
      foto: json['foto'] as String?,
      rol: json['rol'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'documento': documento,
      'foto': foto,
      'rol': rol,
    };
  }
}

