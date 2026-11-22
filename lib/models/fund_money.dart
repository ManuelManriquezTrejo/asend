/// Parte de un fondo que va a un elemento de Dinero, igual que
/// FundAccount para las cuentas. Los porcentajes de un fondo suman 100
/// en Cuentas y, aparte, 100 en Dinero.
class FundMoney {
  final int id;
  final int fundId;
  final int moneyId;
  final double percentage;

  FundMoney({
    required this.id,
    required this.fundId,
    required this.moneyId,
    required this.percentage,
  });
}