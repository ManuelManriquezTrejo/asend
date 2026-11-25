/// Puntos que ganó una estadística en un día ya cerrado. Una vez
/// guardados no cambian, aunque después se edite el vínculo o el factor.
class StatPoint {
  final int id;
  final int statId;

  /// Día lógico del que salieron los puntos.
  final DateTime fecha;

  /// Suma del día con los decimales ya quitados.
  final int puntos;

  final DateTime createdAt;
  DateTime? deletedAt;

  StatPoint({
    required this.id,
    required this.statId,
    required this.fecha,
    required this.puntos,
    required this.createdAt,
    this.deletedAt,
  });
}
