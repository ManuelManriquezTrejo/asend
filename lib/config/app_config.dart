/// Configuración global de la app Asend
class AppConfig {
  // Hora de corte del día (4 AM)
  // Antes de esta hora = día anterior
  // Después = nuevo día
  static const int dailyCutoffHour = 4;

  // Calificación mínima para no romper racha (tipo "nota")
  static const double minNoteForStreak = 9.0;

  // Horas mínimas para no romper racha (tipo "hora")
  static const double minHoursForStreak = 1.0;
}
