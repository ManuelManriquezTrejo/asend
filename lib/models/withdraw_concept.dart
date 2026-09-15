/// Concepto elegible al retirar dinero de una cuenta desde Banco.
/// "Retiro" es el concepto por defecto: existe siempre, no se puede
/// editar ni borrar, y es el que aparece preseleccionado.
class WithdrawConcept {
  final int id;
  String nombre;
  final DateTime createdAt;
  DateTime? deletedAt; // fecha de eliminación (null = activo)

  WithdrawConcept({
    required this.id,
    required this.nombre,
    required this.createdAt,
    this.deletedAt,
  });
}