/// Puntos de magia que dio una misión al completarse. Se guarda el
/// nombre porque la misión se archiva al completarla.
class MissionMagicPoint {
  final int id;
  final int missionId;
  final String nombre;
  final int puntos;
  final DateTime fecha;
  DateTime? deletedAt;

  MissionMagicPoint({
    required this.id,
    required this.missionId,
    required this.nombre,
    required this.puntos,
    required this.fecha,
    this.deletedAt,
  });
}
