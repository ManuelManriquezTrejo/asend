import 'package:asend/database/hive_service.dart';
import 'package:asend/models/withdraw_concept.dart';

/// Conceptos que se pueden elegir al retirar dinero desde Banco.
///
/// "Retiro" es el concepto por defecto: se crea solo la primera vez
/// que se abre la lista, tiene id 1 y no se puede editar ni borrar.
/// Siempre es el primero de la lista y el que viene preseleccionado.
///
/// Borrar un concepto no toca los retiros ya hechos: el texto que se
/// eligió en su momento quedó escrito en AccountHistory.
class WithdrawConceptService {
  /// Id reservado para "Retiro". Nunca se borra ni se edita.
  static const int idPorDefecto = 1;

  /// Texto del concepto por defecto.
  static const String nombrePorDefecto = 'Retiro';

  /// Crea "Retiro" si la caja todavía no lo tiene.
  /// Se llama antes de cualquier lectura para que la lista nunca
  /// aparezca vacía.
  static Future<void> asegurarPorDefecto() async {
    final box = HiveService.getWithdrawConceptsBox();

    for (final c in box.values) {
      if (c.id == idPorDefecto) return;
    }

    await box.put(
      idPorDefecto,
      WithdrawConcept(
        id: idPorDefecto,
        nombre: nombrePorDefecto,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Conceptos activos, con "Retiro" siempre al principio.
  static List<WithdrawConcept> getAll() {
    final box = HiveService.getWithdrawConceptsBox();

    final conceptos = <WithdrawConcept>[];
    for (final c in box.values) {
      if (c.deletedAt == null) conceptos.add(c);
    }

    conceptos.sort((a, b) {
      if (a.id == idPorDefecto) return -1;
      if (b.id == idPorDefecto) return 1;
      return a.id.compareTo(b.id);
    });

    return conceptos;
  }

  /// Concepto activo por id, o null si no existe o ya se borró.
  static WithdrawConcept? getById(int id) {
    final box = HiveService.getWithdrawConceptsBox();
    final c = box.get(id);
    if (c != null && c.deletedAt == null) return c;
    return null;
  }

  /// Crea un concepto nuevo.
  /// Devuelve null si salió bien, o el mensaje de error para la alerta.
  static Future<String?> crear(String nombre) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return 'Escribe un nombre';

    if (_existeNombre(limpio, null)) return 'Ya existe ese concepto';

    final box = HiveService.getWithdrawConceptsBox();

    int nuevoId = 1;
    for (final key in box.keys) {
      if (key is int && key >= nuevoId) nuevoId = key + 1;
    }

    await box.put(
      nuevoId,
      WithdrawConcept(
        id: nuevoId,
        nombre: limpio,
        createdAt: DateTime.now(),
      ),
    );

    return null;
  }

  /// Cambia el nombre de un concepto.
  /// Los retiros viejos conservan el texto que tenían.
  static Future<String?> editar({
    required int id,
    required String nombre,
  }) async {
    if (id == idPorDefecto) return 'El concepto "Retiro" no se puede editar';

    final limpio = nombre.trim();
    if (limpio.isEmpty) return 'Escribe un nombre';

    if (_existeNombre(limpio, id)) return 'Ya existe ese concepto';

    final box = HiveService.getWithdrawConceptsBox();
    final c = box.get(id);
    if (c == null || c.deletedAt != null) return 'Ese concepto ya no existe';

    c.nombre = limpio;
    await box.put(id, c);

    return null;
  }

  /// Marca un concepto como eliminado.
  static Future<String?> eliminar(int id) async {
    if (id == idPorDefecto) return 'El concepto "Retiro" no se puede borrar';

    final box = HiveService.getWithdrawConceptsBox();
    final c = box.get(id);
    if (c == null || c.deletedAt != null) return 'Ese concepto ya no existe';

    c.deletedAt = DateTime.now();
    await box.put(id, c);

    return null;
  }

  /// True si ya hay un concepto activo con ese nombre.
  /// [ignorarId] deja fuera al concepto que se está editando, para que
  /// no choque consigo mismo.
  static bool _existeNombre(String nombre, int? ignorarId) {
    final buscado = nombre.toLowerCase();
    for (final c in getAll()) {
      if (c.id == ignorarId) continue;
      if (c.nombre.toLowerCase() == buscado) return true;
    }
    return false;
  }
}