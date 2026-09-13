/// Un ejercicio dentro de un día.
/// [peso] en 0 significa sin peso extra; acepta negativos para
/// fondos con banda de apoyo.
class GymExercise {
  int id;
  int diaId;
  String nombre;
  double peso;
  String unidadPeso; // kg o lb
  int series;
  int reps; // Reps objetivo: el 12 de un 4x12
  int orden; // Orden de realización dentro del día
  DateTime createdAt;
  DateTime? deletedAt;

  GymExercise({
    required this.id,
    required this.diaId,
    required this.nombre,
    required this.peso,
    required this.unidadPeso,
    required this.series,
    required this.reps,
    required this.orden,
    required this.createdAt,
    this.deletedAt,
  });
}
