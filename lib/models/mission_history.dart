/// Registro de una misión principal completada.
/// Las submisiones no se guardan: son solo control visual.
class MissionHistory {
  final int id;
  final int missionId;
  final String nombre; // copia del nombre al completar
  final double valorSnapshot; // pago vigente al completar
  final DateTime completedAt;
  DateTime? deletedAt;

  MissionHistory({
    required this.id,
    required this.missionId,
    required this.nombre,
    required this.valorSnapshot,
    required this.completedAt,
    this.deletedAt,
  });
}
