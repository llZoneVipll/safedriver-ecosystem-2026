class Vehiculo {
  final int id;
  final String placa;
  final String modelo;
  final int conductorId;

  Vehiculo({
    required this.id,
    required this.placa,
    required this.modelo,
    required this.conductorId,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id'],
      placa: json['placa'],
      modelo: json['modelo'],
      conductorId: json['conductor_id'],
    );
  }
}
