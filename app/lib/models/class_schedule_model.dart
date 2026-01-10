class ClassScheduleModel {
  final int id;
  final int claseId;
  final String claseNombre;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final bool activo;
  final int? capacidadMaxima;
  final int? duracionMinutos;
  final String? instructorNombre;
  final String? instructorApellido;

  ClassScheduleModel({
    required this.id,
    required this.claseId,
    required this.claseNombre,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    this.activo = true,
    this.capacidadMaxima,
    this.duracionMinutos,
    this.instructorNombre,
    this.instructorApellido,
  });

  String get diaNombre {
    switch (diaSemana) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Desconocido';
    }
  }

  String get instructorCompleto {
    if (instructorNombre != null && instructorApellido != null) {
      return '$instructorNombre $instructorApellido';
    }
    return 'Sin asignar';
  }

  // Convertir hora de formato "HH:MM:SS" o "HH:MM" a TimeOfDay
  String get horaInicioFormateada {
    if (horaInicio.length >= 5) {
      return horaInicio.substring(0, 5); // HH:MM
    }
    return horaInicio;
  }

  String get horaFinFormateada {
    if (horaFin.length >= 5) {
      return horaFin.substring(0, 5); // HH:MM
    }
    return horaFin;
  }

  static String _parseTime(dynamic timeValue) {
    if (timeValue == null) return '';
    if (timeValue is String) return timeValue;
    return timeValue.toString();
  }

  factory ClassScheduleModel.fromJson(Map<String, dynamic> json) {
    try {
      return ClassScheduleModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      claseId: json['clase_id'] is int
          ? json['clase_id']
          : int.tryParse(json['clase_id'].toString()) ?? 0,
      claseNombre: json['clase_nombre'] as String? ?? '',
      diaSemana: json['dia_semana'] is int
          ? json['dia_semana']
          : int.tryParse(json['dia_semana'].toString()) ?? 1,
      horaInicio: _parseTime(json['hora_inicio']),
      horaFin: _parseTime(json['hora_fin']),
      activo: (json['activo'] as int? ?? json['activo'] as bool? ?? 1) == 1,
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
      instructorNombre: json['instructor_nombre'] as String?,
      instructorApellido: json['instructor_apellido'] as String?,
      );
    } catch (e) {
      print('Error parseando ClassScheduleModel: $e');
      print('JSON recibido: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clase_id': claseId,
      'clase_nombre': claseNombre,
      'dia_semana': diaSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'activo': activo ? 1 : 0,
      'capacidad_maxima': capacidadMaxima,
      'duracion_minutos': duracionMinutos,
      'instructor_nombre': instructorNombre,
      'instructor_apellido': instructorApellido,
    };
  }
}

