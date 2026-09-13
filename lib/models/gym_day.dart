/// Un día de rutina: "A Bíceps", "Pierna", "Push".
/// El nombre es libre y no está atado a un día de la semana.
class GymDay {
  int id;
  String nombre;
  int orden; // Posición en la lista de días
  DateTime createdAt;
  DateTime? deletedAt;

  GymDay({
    required this.id,
    required this.nombre,
    required this.orden,
    required this.createdAt,
    this.deletedAt,
  });
}
