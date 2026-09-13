import 'package:asend/models/cash_out.dart';
import 'package:asend/models/habit_history.dart';
import 'package:asend/database/cash_out_hive_service.dart';
import 'package:asend/database/routine_hive_service.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/cashout/services/cash_out_config_service.dart';

class CashOutService {
  /// Siguiente id disponible (máximo real, no el último insertado)
  static int _nextId() {
    final box = CashOutHiveService.getCashOutBox();
    int next = 1;
    for (final c in box.values) {
      if (c.id >= next) next = c.id + 1;
    }
    return next;
  }

  /// Pago de un registro individual del historial.
  /// hora: valorSnapshot × horas
  /// nota: valorSnapshot × (nota / 10)  → el 11 paga 10% extra
  /// Devuelve decimales: se truncan solo al sumar el total del día.
  static double calcularPagoRegistro(HabitHistory r) {
    if (r.value <= 0) return 0.0;
    if (r.tipoSnapshot == 'hora') {
      return r.valorSnapshot * r.value;
    }
    return r.valorSnapshot * (r.value / 10);
  }

  /// ¿Ya existe un pago de rutina para esa fecha?
  static bool existePagoDiario(DateTime fecha) {
    final box = CashOutHiveService.getCashOutBox();
    return box.values.any(
      (c) =>
          c.origen == 'rutina' &&
          c.deletedAt == null &&
          c.fecha.isAtSameMomentAs(fecha),
    );
  }

  /// Genera el pago del día sumando todos los registros de esa fecha.
  /// Los decimales se acumulan en el cálculo y se truncan al final.
  /// Si no hay ningún registro ese día, no crea nada.
  static Future<void> generarPagoDiario(DateTime fecha) async {
    if (existePagoDiario(fecha)) return;

    final historyBox = RoutineHiveService.getHabitHistoryBox();
    final registros = historyBox.values
        .where(
          (r) => r.deletedAt == null && r.recordDate.isAtSameMomentAs(fecha),
        )
        .toList();

    // Sin hábitos registrados ese día = no se genera nada
    if (registros.isEmpty) return;

    double total = 0.0;
    for (final r in registros) {
      total += calcularPagoRegistro(r);
    }

    // Truncar: los decimales se consideran despreciables
    final cantidad = total.floor();

    final box = CashOutHiveService.getCashOutBox();
    await box.add(
      CashOut(
        id: _nextId(),
        fecha: fecha,
        nombre: 'Pago diario',
        cantidad: cantidad,
        origen: 'rutina',
        createdAt: DateTime.now(),
      ),
    );

    print(
      '💰 Pago diario generado: ${fecha.toIso8601String().split('T')[0]} '
      '= $cantidad (de ${total.toStringAsFixed(2)})',
    );
  }

  /// Genera el pago de una misión completada
  static Future<void> generarPagoMision({
    required String nombre,
    required double valor,
  }) async {
    final box = CashOutHiveService.getCashOutBox();
    final ahora = DateTime.now();

    await box.add(
      CashOut(
        id: _nextId(),
        fecha: DateTime(ahora.year, ahora.month, ahora.day),
        nombre: nombre,
        cantidad: valor.floor(),
        origen: 'mision',
        createdAt: ahora,
      ),
    );

    print('💰 Pago de misión generado: $nombre = ${valor.floor()}');
  }

  /// Pagos pendientes, más antiguos primero
  static List<CashOut> getPendientes() {
    final box = CashOutHiveService.getCashOutBox();
    final list =
        box.values.where((c) => c.deletedAt == null && !c.pagado).toList()
          ..sort((a, b) => a.fecha.compareTo(b.fecha));
    return list;
  }

  /// Suma de todos los pendientes
  static int getTotalPendiente() {
    int total = 0;
    for (final c in getPendientes()) {
      total += c.cantidad;
    }
    return total;
  }

  /// Guardar cambios de un pago usando su clave real de Hive
  static Future<void> savePago(CashOut pago) async {
    final box = CashOutHiveService.getCashOutBox();
    for (final k in box.keys) {
      if (box.get(k)?.id == pago.id) {
        await box.put(k, pago);
        return;
      }
    }
  }

  /// Resultado de intentar cobrar
  /// ok = se aplicó; el mensaje explica el fallo si no
  static Future<({bool ok, String mensaje})> cobrar(CashOut pago) async {
    final config = CashOutConfigService.getConfigSync();

    if (config?.cuentaPagaId == null || config?.cuentaRecibeId == null) {
      return (ok: false, mensaje: 'Selecciona ambas cuentas primero');
    }

    final paga = AccountService.getAccountById(config!.cuentaPagaId!);
    final recibe = AccountService.getAccountById(config.cuentaRecibeId!);

    if (paga == null || recibe == null) {
      return (ok: false, mensaje: 'Alguna cuenta ya no existe');
    }

    if (paga.id == recibe.id) {
      return (ok: false, mensaje: 'Las cuentas deben ser distintas');
    }

    final monto = pago.cantidad.toDouble();

    if (paga.balance < monto) {
      return (
        ok: false,
        mensaje:
            'Saldo insuficiente en ${paga.name} '
            '(tiene ${paga.balance}, se necesitan $monto)',
      );
    }

    // Descontar primero; si falla, no se abona nada
    final salida = await AccountService.aplicarMovimiento(
      accountId: paga.id,
      monto: -monto,
      concepto: 'Pago: ${pago.nombre}',
      referenciaId: pago.id,
    );
    if (!salida) {
      return (ok: false, mensaje: 'No se pudo descontar de ${paga.name}');
    }

    // Abonar sin distribuir entre fondos
    await AccountService.aplicarMovimiento(
      accountId: recibe.id,
      monto: monto,
      concepto: 'Cobro: ${pago.nombre}',
      referenciaId: pago.id,
    );

    pago.pagado = true;
    pago.pagadoAt = DateTime.now();
    await savePago(pago);

    print(
      '💵 Cobrado: ${pago.nombre} = ${pago.cantidad} '
      '(${paga.name} → ${recibe.name})',
    );

    return (ok: true, mensaje: 'Cobrado ${pago.cantidad}');
  }

  /// Cobrar todos los pendientes. Se detiene al primer fallo.
  static Future<({int cobrados, String mensaje})> cobrarTodo() async {
    final pendientes = getPendientes();
    if (pendientes.isEmpty) {
      return (cobrados: 0, mensaje: 'No hay pagos pendientes');
    }

    int cobrados = 0;
    for (final p in pendientes) {
      final r = await cobrar(p);
      if (!r.ok) {
        return (
          cobrados: cobrados,
          mensaje: cobrados == 0
              ? r.mensaje
              : 'Se cobraron $cobrados. Luego: ${r.mensaje}',
        );
      }
      cobrados++;
    }

    return (cobrados: cobrados, mensaje: 'Se cobraron $cobrados pagos');
  }

  /// Soft delete de un pago pendiente
  static Future<void> eliminarPago(CashOut pago) async {
    pago.deletedAt = DateTime.now();
    await savePago(pago);
    print('🗑 Pago eliminado: ${pago.nombre}');
  }
}
