/// Un compromiso de pago registrado en Banco: una suscripción mensual,
/// un gasto a meses con tarjeta o un pago único.
///
/// Cada mensualidad vive en [DebtInstallment]. Aquí solo queda la regla
/// que las genera: cuánto, qué día del mes y cuántos días de margen
/// tiene la fecha límite.
class Debt {
  final int id;
  String nombre;
  String tipo; // 'recurrente', 'gasto' o 'unico'
  double monto; // Lo que se paga cada mes (en único, el pago completo)
  int diaPago; // Día del mes en que toca pagar
  int diasLimite; // Días entre la fecha de pago y la fecha límite
  DateTime fechaInicio; // Fecha de pago de la primera mensualidad
  int meses; // Solo en gasto: número de mensualidades
  final DateTime createdAt;
  DateTime? deletedAt; // Eliminado o suscripción cancelada

  Debt({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.monto,
    required this.diaPago,
    required this.diasLimite,
    required this.fechaInicio,
    this.meses = 0,
    required this.createdAt,
    this.deletedAt,
  });
}