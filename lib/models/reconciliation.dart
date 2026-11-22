/// Un cuadre: compara la suma de unas cuentas de Banco ([Account])
/// contra la suma de unos elementos de Dinero ([MoneyAccount]).
/// Si no son iguales, hay una diferencia que revisar.
class Reconciliation {
  final int id;
  String nombre;
  List<int> accountIds; // Cuentas que entran del lado de Cuentas
  List<int> moneyIds; // Elementos que entran del lado de Dinero
  final DateTime createdAt;
  DateTime? deletedAt; // null = activo

  Reconciliation({
    required this.id,
    required this.nombre,
    required this.accountIds,
    required this.moneyIds,
    required this.createdAt,
    this.deletedAt,
  });
}