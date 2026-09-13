/// Misión del Tablón. Puede ser principal (parentId == null) o
/// submisión (parentId apunta al id de la principal).
/// Solo las principales tienen valor y generan pago.
class Mission {
  final int id;
  int? parentId; // null = misión principal
  String nombre;
  double valor; // solo aplica a principales; en hijas queda en 0
  DateTime? fechaInicio;
  DateTime? fechaLimite;
  bool completed; // en hijas: progreso visual. En padres: no se usa
  bool taken; // solo principales: si está tomada, aparece en el main
  final DateTime createdAt;
  DateTime? deletedAt;

  Mission({
    required this.id,
    this.parentId,
    required this.nombre,
    this.valor = 0.0,
    this.fechaInicio,
    this.fechaLimite,
    this.completed = false,
    this.taken = false,
    required this.createdAt,
    this.deletedAt,
  });

  bool get esPrincipal => parentId == null;
}
