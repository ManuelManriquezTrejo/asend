/// Una magia del personaje. Sube de rango con los puntos de magia que
/// se le asignan, con su propia tabla de rangos.
class Magic {
  final int id;
  String nombre;

  /// Clave de la plantilla de la que salió ('sombra', 'fuego'…), o
  /// vacía si el usuario la creó desde cero.
  final String plantilla;

  /// Puntos de magia asignados.
  int puntos;

  /// Puntos acumulados para llegar a E, D, C, B, A, S y SS.
  List<int> umbrales;

  int orden;
  final DateTime createdAt;
  DateTime? deletedAt;

  Magic({
    required this.id,
    required this.nombre,
    this.plantilla = '',
    this.puntos = 0,
    required this.umbrales,
    required this.orden,
    required this.createdAt,
    this.deletedAt,
  });
}
