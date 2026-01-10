class ContactModel {
  final int solicitudId;
  final int contactoId;
  final String nombre;
  final String apellido;
  final String email;
  final String? apodoContacto;
  final String nombreMostrar;
  final String nombreReal;
  final String amigosDesde;

  ContactModel({
    required this.solicitudId,
    required this.contactoId,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.apodoContacto,
    required this.nombreMostrar,
    required this.nombreReal,
    required this.amigosDesde,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      solicitudId: json['solicitud_id'] is int
          ? json['solicitud_id']
          : int.parse(json['solicitud_id'].toString()),
      contactoId: json['contacto_id'] is int
          ? json['contacto_id']
          : int.parse(json['contacto_id'].toString()),
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      apodoContacto: json['apodo_contacto']?.toString(),
      nombreMostrar: json['nombre_mostrar']?.toString() ?? '',
      nombreReal: json['nombre_real']?.toString() ?? '',
      amigosDesde: json['amigos_desde']?.toString() ?? '',
    );
  }
}
