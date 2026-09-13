/// Una medición de una zona en un día.
/// [unidadSnapshot] congela la unidad que tenía la zona al medir,
/// para que cambiarla después no altere los registros viejos.
class BodyMeasurement {
  int id;
  int zonaId;
  double valor;
  String unidadSnapshot;
  DateTime fecha; // Día al que pertenece, con corte de las 4 AM
  DateTime createdAt;
  DateTime? deletedAt;

  BodyMeasurement({
    required this.id,
    required this.zonaId,
    required this.valor,
    required this.unidadSnapshot,
    required this.fecha,
    required this.createdAt,
    this.deletedAt,
  });
}
