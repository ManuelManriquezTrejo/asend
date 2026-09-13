class Goal {
  int id;
  String nombre;
  int saldo;
  DateTime createdAt;
  DateTime? deletedAt;

  Goal({
    required this.id,
    required this.nombre,
    this.saldo = 0,
    required this.createdAt,
    this.deletedAt,
  });
}
