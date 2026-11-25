/// Vínculo de un hábito de Rutina con la estadística que alimenta.
/// Un hábito alimenta una sola estadística.
class StatLink {
  final int id;
  final int habitId;
  int statId;

  /// Puntos por cada 1 hora (hábito de hora) o por cada nota 10
  /// (hábito de nota). Acepta decimales.
  double factor;

  /// Día lógico en que se vinculó: solo cuentan registros desde aquí.
  final DateTime fechaVinculo;

  /// Última vez que se cambió la estadística o el factor.
  DateTime? fechaCambio;

  DateTime? deletedAt;

  StatLink({
    required this.id,
    required this.habitId,
    required this.statId,
    required this.factor,
    required this.fechaVinculo,
    this.fechaCambio,
    this.deletedAt,
  });
}
