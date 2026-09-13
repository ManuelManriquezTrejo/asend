/// Una zona del cuerpo que se mide (bíceps, cintura, peso...).
class BodyZone {
  int id;
  String nombre;
  String unidad; // cm, mm, in, kg, lb, %
  int orden; // Posición en la lista. Por ahora, orden de creación.
  DateTime createdAt;
  DateTime? deletedAt;

  BodyZone({
    required this.id,
    required this.nombre,
    required this.unidad,
    required this.orden,
    required this.createdAt,
    this.deletedAt,
  });
}
