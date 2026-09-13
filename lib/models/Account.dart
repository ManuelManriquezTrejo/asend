class Account {
  final int id;
  final String name;
  final double balance;
  final DateTime createdAt;
  final DateTime? deletedAt; //fecha de eliminación (null = activo)

  Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.createdAt,
    this.deletedAt,
  });
}
