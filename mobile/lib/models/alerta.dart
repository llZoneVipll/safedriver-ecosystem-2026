class Alerta {
  final int id;
  final String tipo;
  final String nivel;
  final double? valorBpm;
  final double? valorVelocidad;
  final String timestamp;
  final int conductorId;
  final int vehiculoId;

  Alerta({
    required this.id,
    required this.tipo,
    required this.nivel,
    this.valorBpm,
    this.valorVelocidad,
    required this.timestamp,
    required this.conductorId,
    required this.vehiculoId,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: json['id'],
      tipo: json['tipo'],
      nivel: json['nivel'],
      valorBpm: json['valor_bpm']?.toDouble(),
      valorVelocidad: json['valor_velocidad']?.toDouble(),
      timestamp: json['timestamp'] ?? '',
      conductorId: json['conductor_id'],
      vehiculoId: json['vehiculo_id'],
    );
  }
}