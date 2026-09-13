class Purchase {
  int id;
  String nombre;
  int precio;
  String? nota;
  DateTime fecha;
  DateTime? deletedAt;

  Purchase({
    required this.id,
    required this.nombre,
    required this.precio,
    this.nota,
    required this.fecha,
    this.deletedAt,
  });
}
