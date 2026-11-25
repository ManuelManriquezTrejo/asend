/// Una estadística del personaje (Mana, Fuerza, HP, Agilidad…).
/// Sus puntos no se guardan aquí: son la suma de sus StatPoint.
class Stat {
  final int id;
  String nombre;

  /// La estadística que alimenta los puntos de magia. Solo hay una y
  /// no se puede eliminar.
  final bool esMana;

  int orden;

  /// Puntos acumulados para llegar a E, D, C, B, A, S y SS.
  List<int> umbrales;

  bool mostrarBarra;
  bool mostrarRango;

  /// 'progreso' (cuánto falta para el siguiente rango) o 'datos'
  /// (cantidad actual contra el máximo, se resta y suma a mano).
  String tipoBarra;

  /// Lo que se ha restado en la barra de datos. Lo actual es
  /// puntos − gastado, así al ganar puntos sube el máximo y lo actual.
  double gastado;

  final DateTime createdAt;
  DateTime? deletedAt;

  Stat({
    required this.id,
    required this.nombre,
    this.esMana = false,
    required this.orden,
    required this.umbrales,
    this.mostrarBarra = true,
    this.mostrarRango = true,
    this.tipoBarra = 'progreso',
    this.gastado = 0,
    required this.createdAt,
    this.deletedAt,
  });
}
