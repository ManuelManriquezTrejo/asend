import 'package:asend/bank/services/account_service.dart';
import 'package:asend/cashout/services/cash_out_config_service.dart';
import 'package:asend/database/store_hive_service.dart';
import 'package:asend/models/purchase.dart';

/// Toda la lógica de Tienda.
/// El dinero sale de la cuenta que recibe los pagos (cuentaRecibeId
/// de CashOut), vía AccountService.aplicarMovimiento, para que todo
/// quede registrado en AccountHistory.
///
/// Los métodos que mueven dinero devuelven String?:
///   null  = todo salió bien
///   texto = mensaje de error listo para mostrar en una alerta
class PurchaseService {
  // ─────────────────────────────────────────────
  // LECTURA
  // ─────────────────────────────────────────────

  /// Todas las compras activas, de la más reciente a la más vieja.
  static List<Purchase> getTodas() {
    final compras = StoreHiveService.getPurchasesBox().values
        .where((p) => p.deletedAt == null)
        .toList();
    compras.sort((a, b) => b.fecha.compareTo(a.fecha));
    return compras;
  }

  /// Compras de un mes calendario concreto (del día 1 al último día).
  /// No acumula meses anteriores.
  static List<Purchase> getDelMes(int anio, int mes) {
    return getTodas()
        .where((p) => p.fecha.year == anio && p.fecha.month == mes)
        .toList();
  }

  /// Compras del mes actual.
  static List<Purchase> getDelMesActual() {
    final hoy = DateTime.now();
    return getDelMes(hoy.year, hoy.month);
  }

  /// Total de un mes concreto.
  static int getTotalDelMes(int anio, int mes) {
    int total = 0;
    for (final p in getDelMes(anio, mes)) {
      total += p.precio;
    }
    return total;
  }

  /// Total del mes actual.
  static int getTotalDelMesActual() {
    final hoy = DateTime.now();
    return getTotalDelMes(hoy.year, hoy.month);
  }

  /// Lista de meses para el historial, del más reciente al más viejo.
  /// Va desde la primera compra registrada hasta el mes actual,
  /// SIN saltarse meses: los que no tuvieron compras salen en 0.
  static List<({int anio, int mes, int total})> getMeses() {
    final compras = getTodas();
    final hoy = DateTime.now();

    // Sin compras: solo el mes actual en cero
    if (compras.isEmpty) {
      return [(anio: hoy.year, mes: hoy.month, total: 0)];
    }

    // La lista viene ordenada de reciente a vieja, así que la primera
    // compra de todas es la última del arreglo.
    final primera = compras.last.fecha;

    final meses = <({int anio, int mes, int total})>[];

    int anio = hoy.year;
    int mes = hoy.month;

    while (anio > primera.year ||
        (anio == primera.year && mes >= primera.month)) {
      meses.add((anio: anio, mes: mes, total: getTotalDelMes(anio, mes)));

      mes--;
      if (mes == 0) {
        mes = 12;
        anio--;
      }
    }

    return meses;
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
  // ESCRITURA
  // ─────────────────────────────────────────────

  /// Registra una compra y descuenta el precio de la cuenta.
  /// Si no hay saldo, no se registra nada.
  static Future<String?> agregar({
    required String nombre,
    required int precio,
    String? nota,
  }) async {
    if (precio <= 0) return 'El precio debe ser mayor a 0';

    final cuentaId = _getCuentaId();
    if (cuentaId == null) return _sinCuenta;

    // Primero el dinero: si falla, no queda una compra huérfana
    final ok = await AccountService.aplicarMovimiento(
      accountId: cuentaId,
      monto: -precio.toDouble(),
      concepto: 'Compra: $nombre',
    );

    if (!ok) return 'Saldo insuficiente en la cuenta';

    final box = StoreHiveService.getPurchasesBox();

    // Buscar el máximo real, nunca values.last.id ni box.length + 1
    int nuevoId = 1;
    for (final p in box.values) {
      if (p.id >= nuevoId) nuevoId = p.id + 1;
    }

    await box.put(
      nuevoId,
      Purchase(
        id: nuevoId,
        nombre: nombre,
        precio: precio,
        nota: nota,
        fecha: DateTime.now(),
      ),
    );

    return null;
  }

  /// Edita nombre, precio o nota.
  /// Si el precio sube, descuenta la diferencia; si baja, la devuelve.
  /// Si no hay saldo para el aumento, no cambia nada.
  static Future<String?> editar({
    required int purchaseId,
    required String nombre,
    required int precio,
    String? nota,
  }) async {
    if (precio <= 0) return 'El precio debe ser mayor a 0';

    final box = StoreHiveService.getPurchasesBox();
    final compra = box.get(purchaseId);
    if (compra == null || compra.deletedAt != null) {
      return 'La compra ya no existe';
    }

    final diferencia = precio - compra.precio;

    // Solo se toca la cuenta si el precio cambió
    if (diferencia != 0) {
      final cuentaId = _getCuentaId();
      if (cuentaId == null) return _sinCuenta;

      final ok = await AccountService.aplicarMovimiento(
        accountId: cuentaId,
        monto: -diferencia.toDouble(), // sube = sale más, baja = regresa
        concepto: 'Ajuste de compra: $nombre',
        referenciaId: compra.id,
      );

      if (!ok) return 'Saldo insuficiente para aumentar el precio';
    }

    compra.nombre = nombre;
    compra.precio = precio;
    compra.nota = nota;
    await box.put(compra.id, compra);

    return null;
  }

  /// Soft delete. Devuelve el precio completo a la cuenta.
  /// Si la devolución falla, no se borra.
  static Future<String?> eliminar(int purchaseId) async {
    final box = StoreHiveService.getPurchasesBox();
    final compra = box.get(purchaseId);
    if (compra == null || compra.deletedAt != null) {
      return 'La compra ya no existe';
    }

    final cuentaId = _getCuentaId();
    if (cuentaId == null) return _sinCuenta;

    final ok = await AccountService.aplicarMovimiento(
      accountId: cuentaId,
      monto: compra.precio.toDouble(), // entra
      concepto: 'Compra eliminada: ${compra.nombre}',
      referenciaId: compra.id,
    );

    if (!ok) return 'No se pudo devolver el dinero a la cuenta';

    compra.deletedAt = DateTime.now();
    await box.put(compra.id, compra);

    return null;
  }

  static const String _sinCuenta =
      'Primero selecciona la cuenta que recibe, en Pagos';
}
