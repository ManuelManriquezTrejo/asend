/// El color que el usuario eligió para una línea de las gráficas.
///
/// La clave identifica la línea entre todos los módulos, porque los ids
/// se repiten entre tablas: el ejercicio 3 de Gym y la zona 3 de Medidas
/// son distintos. Formato: "modulo:id", por ejemplo "gym_peso:3",
/// "medidas:3", "rutina:7". Pagos usa solo "pagos" porque es una línea única.
class ChartLineColor {
  final int id;
  String clave;
  int color; // Valor ARGB del Color de Flutter
  final DateTime createdAt;
  DateTime? deletedAt;

  ChartLineColor({
    required this.id,
    required this.clave,
    required this.color,
    required this.createdAt,
    this.deletedAt,
  });
}