/// Una mensualidad de un [Debt]: lo que toca pagar en una fecha.
///
/// Un gasto crea todas sus mensualidades al guardarse y un pago único
/// crea una. Las suscripciones se van creando conforme se necesitan,
/// porque no tienen fin.
class DebtInstallment {
  final int id;
  final int debtId;
  final int numero; // Posición dentro de su deuda: 0, 1, 2...
  double monto;
  DateTime fechaPago;
  DateTime fechaLimite; // Informativa, para las notificaciones futuras
  DateTime? pagadoAt; // null = pendiente
  int? accountId; // Cuenta con la que se pagó
  DateTime? deletedAt; // Eliminada sin pagar

  DebtInstallment({
    required this.id,
    required this.debtId,
    required this.numero,
    required this.monto,
    required this.fechaPago,
    required this.fechaLimite,
    this.pagadoAt,
    this.accountId,
    this.deletedAt,
  });
}