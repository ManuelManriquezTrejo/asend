/// Una serie ya guardada en el historial, con la configuración
/// del ejercicio congelada al momento de entrenar. Cambiar el
/// peso después no altera lo que ya está aquí.
///
/// Una fila por serie: así el promedio de reps de un día sale
/// directo, sin listas dentro del registro.
class GymSessionLog {
  int id;
  int diaId;
  int ejercicioId;
  String nombreSnapshot; // Por si el ejercicio se elimina
  int numeroSerie;
  int? reps; // null = serie que quedó sin anotar
  double pesoSnapshot;
  String unidadSnapshot;
  int seriesSnapshot;
  int repsObjetivoSnapshot;
  DateTime fecha;
  DateTime createdAt;
  DateTime? deletedAt;

  GymSessionLog({
    required this.id,
    required this.diaId,
    required this.ejercicioId,
    required this.nombreSnapshot,
    required this.numeroSerie,
    this.reps,
    required this.pesoSnapshot,
    required this.unidadSnapshot,
    required this.seriesSnapshot,
    required this.repsObjetivoSnapshot,
    required this.fecha,
    required this.createdAt,
    this.deletedAt,
  });
}
