/// Una compra registrada en Tienda.
/// El dinero sale de la cuenta indicada en accountId.
/// No hay soft delete: eliminar una compra la borra de verdad,
/// y la devolución del dinero queda registrada en AccountHistory.
class Purchase {
  int id;
  String nombre;
  int precio;
  String? nota;
  int accountId; // cuenta de la que salió el dinero
  DateTime fecha; // incluye la hora, para ordenar compras del mismo día

  Purchase({
    required this.id,
    required this.nombre,
    required this.precio,
    this.nota,
    required this.accountId,
    required this.fecha,
  });
}