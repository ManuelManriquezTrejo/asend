class HabitHistory {
  final int id;
  final int habitId;
  final DateTime recordDate; // Fecha del día (2026-08-24 00:00)
  final DateTime recordedAt; // Cuándo registraste (2026-08-24 14:35)
  final double value; // Nota (0-11) O Horas (0-24)
  final String tipoSnapshot; // "nota" u "hora" al momento de registrar
  final double valorSnapshot; // el pago vigente ese día
  DateTime? deletedAt;

  HabitHistory({
    required this.id,
    required this.habitId,
    required this.recordDate,
    required this.recordedAt,
    required this.value,
    required this.tipoSnapshot,
    required this.valorSnapshot,
    this.deletedAt,
  });
}
