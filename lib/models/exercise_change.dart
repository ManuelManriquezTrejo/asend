/// Historial de configuración de un ejercicio.
/// Se crea una entrada al crearlo y otra cada vez que cambia
/// peso, series o reps con el lápiz. Guarda la configuración
/// completa, no solo lo que cambió, para poder dibujar la
/// gráfica de peso sin reconstruir nada.
class ExerciseChange {
  int id;
  int ejercicioId;
  double peso;
  String unidadPeso;
  int series;
  int reps;
  DateTime fecha;
  DateTime createdAt;
  DateTime? deletedAt;

  ExerciseChange({
    required this.id,
    required this.ejercicioId,
    required this.peso,
    required this.unidadPeso,
    required this.series,
    required this.reps,
    required this.fecha,
    required this.createdAt,
    this.deletedAt,
  });
}
