class Account {
  final int id;
  String name;
  double balance;
  final DateTime createdAt;
  DateTime? deletedAt; //fecha de eliminación (null = activo)
  Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.createdAt,
    this.deletedAt,
  });
}
