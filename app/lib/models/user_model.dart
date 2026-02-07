class UserModel {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String? telefono;
  final String? documento;
  final String? foto;
  final String? rol;
  final String? estado;

  final int asistenciasMes;
  final int rachaActual;

  UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.telefono,
    this.documento,
    this.foto,
    this.rol,
    this.estado,
    this.asistenciasMes = 0,
    this.rachaActual = 0,
  });

  String get nombreCompleto => '$nombre $apellido';
  
  bool get isActive => estado?.toLowerCase() == 'activo';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      email: json['email'] as String,
      telefono: json['telefono'] as String?,
      documento: json['documento'] as String?,
      foto: _parseUrl(json['foto'] as String?),
      rol: json['rol'] as String?,
      estado: json['estado'] as String?,
      asistenciasMes: json['asistencias_mes'] != null ? int.parse(json['asistencias_mes'].toString()) : 0,
      rachaActual: json['racha_actual'] != null ? int.parse(json['racha_actual'].toString()) : 0,
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
      'estado': estado,
      'asistencias_mes': asistenciasMes,
      'racha_actual': rachaActual,
    };
  }


  static String? _parseUrl(String? url) {
    if (url == null) return null;
    if (url.isEmpty) return null;
    
    // Si la URL contiene 'http' pero no empieza con él, extraer desde 'http'
    // Ejemplo bug: /uploads/usuarios/https://functionaltraining...
    if (url.contains('http') && !url.startsWith('http')) {
      final startIndex = url.indexOf('http');
      return url.substring(startIndex);
    }
    
    return url;
  }
}

