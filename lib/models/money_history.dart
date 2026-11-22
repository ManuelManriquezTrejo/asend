/// Registro de cada movimiento en un [MoneyAccount], igual que
/// AccountHistory para las cuentas. Si un saldo no cuadra, se puede
/// recorrer y ver en qué movimiento cambió.
class MoneyHistory {
  final int id;
  final int moneyId; // MoneyAccount afectado
  final double monto; // positivo = entra, negativo = sale
  final double saldoAntes;
  final double saldoDespues;
  final String concepto; // "Ingreso", "Compra: ...", etc.
  final int? referenciaId; // id de la compra, pago o fondo que lo originó
  final DateTime fecha;

  MoneyHistory({
    required this.id,
    required this.moneyId,
    required this.monto,
    required this.saldoAntes,
    required this.saldoDespues,
    required this.concepto,
    this.referenciaId,
    required this.fecha,
  });
}