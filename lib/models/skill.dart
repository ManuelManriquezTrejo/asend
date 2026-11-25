/// Un nivel de una habilidad: desde qué rango se tiene, qué hace y
/// cuánto mana cuesta.
class SkillLevel {
  /// 0 = F … 7 = SS. −1 = sin rango (se tiene desde el inicio).
  int rango;
  String descripcion;
  String mana;

  SkillLevel({required this.rango, required this.descripcion, this.mana = ''});
}

/// Una habilidad. Si tiene [magicId], sus niveles se desbloquean con el
/// rango de esa magia; si no (magia única), con el rango general.
class Skill {
  final int id;
  String nombre;
  int? magicId;

  /// Ataque, Defensa, Apoyo o Aumento.
  String tipo;

  /// Aclaración general de la habilidad (lo que va entre paréntesis).
  String nota;

  /// Niveles de menor a mayor rango.
  List<SkillLevel> niveles;

  int orden;
  final DateTime createdAt;
  DateTime? deletedAt;

  Skill({
    required this.id,
    required this.nombre,
    this.magicId,
    required this.tipo,
    this.nota = '',
    required this.niveles,
    required this.orden,
    required this.createdAt,
    this.deletedAt,
  });
}
