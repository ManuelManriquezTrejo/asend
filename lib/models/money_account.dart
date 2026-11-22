/// Un lugar real donde está el dinero: una cartera, una tarjeta de
/// débito, una app de banco. Lo crea el usuario en la tarjeta Dinero
/// de Banco. Es independiente de las cuentas ([Account]), que sirven
/// para organizar; los cuadres comparan unas contra otras.
class MoneyAccount {
  final int id;
  String name;
  String tipo; // 'efectivo' o 'digital'
  double balance;
  bool seleccionada; // Si entra en el total que se ve en Banco
  final DateTime createdAt;
  DateTime? deletedAt; // null = activa

  MoneyAccount({
    required this.id,
    required this.name,
    required this.tipo,
    required this.balance,
    this.seleccionada = true,
    required this.createdAt,
    this.deletedAt,
  });
}