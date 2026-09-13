class DailyRoutineHabit {
  final int id;
  String nombre;
  String tipo; // "nota" o "hora"
  double valor;
  double prioridad;
  final DateTime createdAt;
  int currentStreak;
  int maxStreak;
  DateTime? maxStreakStartDate;
  DateTime? maxStreakEndDate;
  int secondMaxStreak;
  double minToKeepStreak;
  DateTime? deletedAt;

  DailyRoutineHabit({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.valor,
    required this.prioridad,
    required this.createdAt,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.maxStreakStartDate,
    this.maxStreakEndDate,
    this.secondMaxStreak = 0,
    required this.minToKeepStreak,
    this.deletedAt,
  });
}
