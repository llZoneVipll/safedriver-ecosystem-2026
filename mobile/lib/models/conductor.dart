class Conductor {
  final int id;
  final String nombre;
  final String licencia;

  Conductor({
    required this.id,
    required this.nombre,
    required this.licencia,
  });

  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      id: json['id'],
      nombre: json['nombre'],
      licencia: json['licencia'],
    );
  }
}