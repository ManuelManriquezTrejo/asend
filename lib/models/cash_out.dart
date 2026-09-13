/// Registro de un pago pendiente o cobrado.
/// Se alimenta de dos orígenes: el cierre diario de Rutina
/// y cada misión completada del Tablón.
class CashOut {
  final int id;
  final DateTime fecha; // a qué día corresponde el pago
  final String nombre; // "Pago diario" o el nombre de la misión
  final int cantidad; // sin decimales: se truncan al calcular
  final String origen; // "rutina" o "mision"
  bool pagado; // false = pendiente
  DateTime? pagadoAt; // cuándo se cobró
  final DateTime createdAt;
  DateTime? deletedAt;

  CashOut({
    required this.id,
    required this.fecha,
    required this.nombre,
    required this.cantidad,
    required this.origen,
    this.pagado = false,
    this.pagadoAt,
    required this.createdAt,
    this.deletedAt,
  });
}
