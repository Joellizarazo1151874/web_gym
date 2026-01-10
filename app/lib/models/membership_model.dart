class MembershipModel {
  final int id;
  final String planNombre;
  final String fechaInicio;
  final String fechaFin;
  final String estado;
  final int diasRestantes;

  MembershipModel({
    required this.id,
    required this.planNombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.diasRestantes,
  });

  bool get isActive => estado == 'activa' && diasRestantes > 0;
  bool get isExpiringSoon => diasRestantes <= 7 && diasRestantes > 0;

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    try {
      return MembershipModel(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
        planNombre: json['plan_nombre'] as String? ?? json['plan'] as String? ?? 'Sin plan',
        fechaInicio: json['fecha_inicio']?.toString() ?? '',
        fechaFin: json['fecha_fin']?.toString() ?? '',
        estado: json['estado']?.toString().toLowerCase() ?? 'inactiva',
        diasRestantes: json['dias_restantes'] is int 
            ? json['dias_restantes'] 
            : int.tryParse(json['dias_restantes'].toString()) ?? 0,
      );
    } catch (e) {
      print('Error parsing MembershipModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_nombre': planNombre,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'estado': estado,
      'dias_restantes': diasRestantes,
    };
  }
}

