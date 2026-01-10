class ClassModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final int? instructorId;
  final String? instructorNombre;
  final String? instructorApellido;
  final int? capacidadMaxima;
  final int? duracionMinutos;
  final bool activo;
  final int totalHorarios;

  ClassModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.instructorId,
    this.instructorNombre,
    this.instructorApellido,
    this.capacidadMaxima,
    this.duracionMinutos,
    this.activo = true,
    this.totalHorarios = 0,
  });

  String get instructorCompleto {
    if (instructorNombre != null && instructorApellido != null) {
      return '$instructorNombre $instructorApellido';
    }
    return 'Sin asignar';
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      instructorId: json['instructor_id'] != null
          ? (json['instructor_id'] is int
              ? json['instructor_id']
              : int.tryParse(json['instructor_id'].toString()))
          : null,
      instructorNombre: json['instructor_nombre'] as String?,
      instructorApellido: json['instructor_apellido'] as String?,
      capacidadMaxima: json['capacidad_maxima'] != null
          ? (json['capacidad_maxima'] is int
              ? json['capacidad_maxima']
              : int.tryParse(json['capacidad_maxima'].toString()))
          : null,
      duracionMinutos: json['duracion_minutos'] != null
          ? (json['duracion_minutos'] is int
              ? json['duracion_minutos']
              : int.tryParse(json['duracion_minutos'].toString()))
          : null,
      activo: (json['activo'] as int? ?? json['activo'] as bool? ?? 1) == 1,
      totalHorarios: json['total_horarios'] is int
          ? json['total_horarios']
          : int.tryParse(json['total_horarios'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'instructor_id': instructorId,
      'instructor_nombre': instructorNombre,
      'instructor_apellido': instructorApellido,
      'capacidad_maxima': capacidadMaxima,
      'duracion_minutos': duracionMinutos,
      'activo': activo ? 1 : 0,
      'total_horarios': totalHorarios,
    };
  }
}

