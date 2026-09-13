/// Guarda qué cuentas usa CashOut para pagar y recibir.
/// Solo existe un registro (id = 1); persiste entre sesiones.
class CashOutConfig {
  final int id;
  int? cuentaPagaId; // de dónde sale el dinero
  int? cuentaRecibeId; // a dónde entra

  CashOutConfig({this.id = 1, this.cuentaPagaId, this.cuentaRecibeId});
}
