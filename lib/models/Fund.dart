class Fund {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime? deletedAt;

  Fund({
    required this.id,
    required this.name,
    required this.createdAt,
    this.deletedAt,
  });
}
