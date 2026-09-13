class Birthday {
  int id;
  String nombre;
  int dia;
  int mes;
  int? anio;
  String? nota;
  DateTime createdAt;
  DateTime? deletedAt;

  Birthday({
    required this.id,
    required this.nombre,
    required this.dia,
    required this.mes,
    this.anio,
    this.nota,
    required this.createdAt,
    this.deletedAt,
  });
}
