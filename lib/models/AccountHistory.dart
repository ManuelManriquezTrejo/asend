/// Registro de cada movimiento de dinero en una cuenta.
/// Sirve de auditoría: si un saldo no cuadra, se puede recorrer
/// el historial y ver exactamente en qué movimiento se rompió.
class AccountHistory {
  final int id;
  final int accountId; // cuenta afectada
  final double monto; // positivo = entra, negativo = sale
  final double saldoAntes;
  final double saldoDespues;
  final String concepto; // "Cobro CashOut", etc.
  final int? referenciaId; // id del CashOut que lo originó, si aplica
  final DateTime fecha;
  DateTime? deletedAt;

  AccountHistory({
    required this.id,
    required this.accountId,
    required this.monto,
    required this.saldoAntes,
    required this.saldoDespues,
    required this.concepto,
    this.referenciaId,
    required this.fecha,
    this.deletedAt,
  });
}
