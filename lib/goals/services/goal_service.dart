import 'package:asend/bank/services/account_service.dart';
import 'package:asend/cashout/services/cash_out_config_service.dart';
import 'package:asend/database/goal_hive_service.dart';
import 'package:asend/models/goal.dart';

/// Toda la lógica de Metas.
/// El dinero sale y entra SIEMPRE de la cuenta que recibe los pagos
/// (cuentaRecibeId de CashOut), vía AccountService.aplicarMovimiento,
/// para que todo movimiento quede registrado en AccountHistory.
///
/// Los métodos que mueven dinero devuelven String?:
///   null    = todo salió bien
///   texto   = mensaje de error listo para mostrar en una alerta
class GoalService {
  // ─────────────────────────────────────────────
  // LECTURA
  // ─────────────────────────────────────────────

  /// Metas activas, ordenadas por id (orden de creación).
  static List<Goal> getMetas() {
    final metas = GoalHiveService.getGoalsBox().values
        .where((g) => g.deletedAt == null)
        .toList();
    metas.sort((a, b) => a.id.compareTo(b.id));
    return metas;
  }

  /// Suma de todo lo apartado en metas activas.
  static int getTotalApartado() {
    int total = 0;
    for (final g in getMetas()) {
      total += g.saldo;
    }
    return total;
  }

  /// Id de la cuenta que recibe los pagos. null si aún no se elige.
  static int? _getCuentaId() {
    return CashOutConfigService.getConfigSync()?.cuentaRecibeId;
  }

  /// Saldo disponible en esa cuenta. null si no hay cuenta configurada.
  static double? getSaldoCuenta() {
    final cuentaId = _getCuentaId();
    if (cuentaId == null) return null;
    return AccountService.getAccountById(cuentaId)?.balance;
  }

  // ─────────────────────────────────────────────
  // CREAR Y ELIMINAR
  // ─────────────────────────────────────────────

  /// Crea una meta con saldo 0. No mueve dinero.
  static Future<void> agregarMeta(String nombre) async {
    final box = GoalHiveService.getGoalsBox();

    // Buscar el máximo real, nunca values.last.id ni box.length + 1
    int nuevoId = 1;
    for (final g in box.values) {
      if (g.id >= nuevoId) nuevoId = g.id + 1;
    }

    await box.put(
      nuevoId,
      Goal(id: nuevoId, nombre: nombre, createdAt: DateTime.now()),
    );
  }

  /// Soft delete. Si la meta tiene fondos, se devuelven a la cuenta
  /// ANTES de marcarla como borrada. Si la devolución falla, no se borra.
  static Future<String?> eliminarMeta(int goalId) async {
    final box = GoalHiveService.getGoalsBox();
    final meta = box.get(goalId);
    if (meta == null || meta.deletedAt != null) return 'La meta ya no existe';

    if (meta.saldo > 0) {
      final cuentaId = _getCuentaId();
      if (cuentaId == null) return _sinCuenta;

      final ok = await AccountService.aplicarMovimiento(
        accountId: cuentaId,
        monto: meta.saldo.toDouble(), // entra
        concepto: 'Meta eliminada: ${meta.nombre}',
        referenciaId: meta.id,
      );

      // Si no se pudo devolver el dinero, abortar: el dinero
      // no puede quedar atrapado en una meta borrada.
      if (!ok) return 'No se pudo devolver el dinero a la cuenta';

      meta.saldo = 0;
    }

    meta.deletedAt = DateTime.now();
    await box.put(meta.id, meta);
    return null;
  }

  // ─────────────────────────────────────────────
  // MOVIMIENTOS INDIVIDUALES
  // ─────────────────────────────────────────────

  /// Abona a una sola meta. Descuenta de la cuenta.
  static Future<String?> abonar(int goalId, int monto) async {
    if (monto <= 0) return 'El monto debe ser mayor a 0';

    final box = GoalHiveService.getGoalsBox();
    final meta = box.get(goalId);
    if (meta == null || meta.deletedAt != null) return 'La meta ya no existe';

    final cuentaId = _getCuentaId();
    if (cuentaId == null) return _sinCuenta;

    final ok = await AccountService.aplicarMovimiento(
      accountId: cuentaId,
      monto: -monto.toDouble(), // sale
      concepto: 'Abono a meta: ${meta.nombre}',
      referenciaId: meta.id,
    );

    if (!ok) return 'Saldo insuficiente en la cuenta';

    meta.saldo += monto;
    await box.put(meta.id, meta);
    return null;
  }

  /// Retira de una meta sin borrarla. El dinero vuelve a la cuenta.
  static Future<String?> retirar(int goalId, int monto) async {
    if (monto <= 0) return 'El monto debe ser mayor a 0';

    final box = GoalHiveService.getGoalsBox();
    final meta = box.get(goalId);
    if (meta == null || meta.deletedAt != null) return 'La meta ya no existe';

    if (monto > meta.saldo) {
      return 'La meta solo tiene ${meta.saldo}';
    }

    final cuentaId = _getCuentaId();
    if (cuentaId == null) return _sinCuenta;

    final ok = await AccountService.aplicarMovimiento(
      accountId: cuentaId,
      monto: monto.toDouble(), // entra
      concepto: 'Retiro de meta: ${meta.nombre}',
      referenciaId: meta.id,
    );

    if (!ok) return 'No se pudo devolver el dinero a la cuenta';

    meta.saldo -= monto;
    await box.put(meta.id, meta);
    return null;
  }

  // ─────────────────────────────────────────────
  // REPARTO EQUITATIVO
  // ─────────────────────────────────────────────

  /// Cuánto tocaría a cada meta con este monto. Solo cálculo,
  /// para mostrarlo en el diálogo de confirmación.
  static int calcularPorMeta(int monto) {
    final n = getMetas().length;
    if (n == 0) return 0;
    return monto ~/ n;
  }

  /// Reparte equitativamente entre todas las metas activas.
  /// Solo enteros; el sobrante nunca sale de la cuenta.
  static Future<String?> repartir(int monto) async {
    if (monto <= 0) return 'El monto debe ser mayor a 0';

    final metas = getMetas();
    if (metas.isEmpty) return 'No hay metas registradas';

    final porMeta = monto ~/ metas.length;
    if (porMeta == 0) {
      return 'El monto es muy bajo, no alcanza a repartir '
          'entre ${metas.length} metas';
    }

    final repartido = porMeta * metas.length;

    final cuentaId = _getCuentaId();
    if (cuentaId == null) return _sinCuenta;

    // Un solo movimiento por el total repartido.
    // El sobrante nunca se descuenta, así que no hay que devolverlo.
    final ok = await AccountService.aplicarMovimiento(
      accountId: cuentaId,
      monto: -repartido.toDouble(),
      concepto: 'Reparto a metas ($porMeta c/u)',
    );

    if (!ok) return 'Saldo insuficiente en la cuenta';

    final box = GoalHiveService.getGoalsBox();
    for (final meta in metas) {
      meta.saldo += porMeta;
      await box.put(meta.id, meta);
    }

    return null;
  }

  static const String _sinCuenta =
      'Primero selecciona la cuenta que recibe, en Pagos';
}
