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
    return MembershipModel(
      id: json['id'] as int,
      planNombre: json['plan_nombre'] as String? ?? json['plan'] as String? ?? 'Sin plan',
      fechaInicio: json['fecha_inicio'] as String,
      fechaFin: json['fecha_fin'] as String,
      estado: json['estado'] as String,
      diasRestantes: json['dias_restantes'] as int? ?? 0,
    );
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

