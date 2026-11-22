import 'package:asend/bank/services/account_service.dart';
import 'package:asend/bank/services/money_service.dart';
import 'package:asend/cashout/services/cash_out_config_service.dart';
import 'package:asend/database/store_hive_service.dart';
import 'package:asend/models/purchase.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Toda la lógica de Tienda.
/// Cada compra guarda de qué cuenta salió el dinero y con qué método de
/// pago (un elemento de Dinero). Los movimientos pasan por
/// AccountService.aplicarMovimiento y MoneyService.aplicarMovimiento
/// para que queden en AccountHistory y MoneyHistory.
///
/// Antes de mover dinero se valida TODO: si la cuenta o el Dinero no
/// alcanzan, no se mueve nada en ninguno de los dos.
///
/// Las compras de antes de Dinero tienen moneyId null: al editarlas o
/// eliminarlas solo se mueve la cuenta.
///
/// Eliminar una compra la borra de verdad de la caja, pero el cobro y
/// la devolución siguen en los historiales: la cadena de saldos nunca
/// se rompe.
///
/// Los métodos que mueven dinero devuelven String?:
///   null  = todo salió bien
///   texto = mensaje de error listo para mostrar en una alerta
class PurchaseService {
  // ─────────────────────────────────────────────
  // LECTURA BÁSICA
  // ─────────────────────────────────────────────

  /// Todas las compras, de la más reciente a la más vieja.
  /// La fecha incluye la hora, así que varias compras del mismo día
  /// quedan ordenadas por el momento en que se registraron.
  static List<Purchase> getTodas() {
    final compras = StoreHiveService.getPurchasesBox().values.toList();
    compras.sort((a, b) => b.fecha.compareTo(a.fecha));
    return compras;
  }

  /// Compras de un mes calendario concreto.
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

  /// Suma de precios de una lista de compras.
  static int getTotal(List<Purchase> compras) {
    int total = 0;
    for (final p in compras) {
      total += p.precio;
    }
    return total;
  }

  /// Total del mes actual.
  static int getTotalDelMesActual() {
    return getTotal(getDelMesActual());
  }

  /// Total gastado en el mes actual, desglosado por cuenta.
  /// Solo aparecen las cuentas que se usaron ese mes.
  static List<({int accountId, String nombre, int total})>
      getTotalesPorCuentaDelMesActual() {
    final porCuenta = <int, int>{};
    for (final p in getDelMesActual()) {
      porCuenta[p.accountId] = (porCuenta[p.accountId] ?? 0) + p.precio;
    }

    final lista = porCuenta.entries
        .map((e) => (
              accountId: e.key,
              nombre: AccountService.getAccountName(e.key),
              total: e.value,
            ))
        .toList();

    lista.sort((a, b) => b.total.compareTo(a.total));
    return lista;
  }

  // ─────────────────────────────────────────────
  // CUENTAS
  // ─────────────────────────────────────────────

  /// Clave en store_meta de la última cuenta usada en Tienda.
  static const String _claveUltimaCuenta = 'ultimaCuentaId';

  /// Cuenta que viene marcada al abrir el formulario de compra.
  /// Primero la última usada en Tienda; si no hay o fue eliminada, la
  /// receptora de Pagos; si tampoco, la primera cuenta activa de Banco.
  /// null si no hay ninguna.
  static int? getCuentaPreseleccionada() {
    final ultima = Hive.box(StoreHiveService.storeMetaBox).get(
      _claveUltimaCuenta,
    );
    if (ultima is int && AccountService.getAccountById(ultima) != null) {
      return ultima;
    }

    final recibeId = CashOutConfigService.getConfigSync()?.cuentaRecibeId;
    if (recibeId != null && AccountService.getAccountById(recibeId) != null) {
      return recibeId;
    }

    final cuentas = AccountService.getCuentasMovibles();    return cuentas.isEmpty ? null : cuentas.first.id;
  }

  /// Guarda la cuenta y el Dinero usados para que el siguiente
  /// formulario los traiga marcados.
  static Future<void> _recordarUsados(int accountId, int? moneyId) async {
    await Hive.box(StoreHiveService.storeMetaBox).put(
      _claveUltimaCuenta,
      accountId,
    );
    if (moneyId != null) {
      await MoneyService.setUltimoId(MoneyService.enTienda, moneyId);
    }
  }

  /// Saldo de una cuenta. null si no existe o fue eliminada.
  static double? getSaldoCuenta(int accountId) {
    return AccountService.getAccountById(accountId)?.balance;
  }

  // ─────────────────────────────────────────────
  // FILTROS DEL HISTORIAL
  // ─────────────────────────────────────────────

  /// Identificador de un día, en formato "2026-09-05".
  /// Se usa como clave del árbol de fechas y del filtro.
  static String claveDia(DateTime d) {
    final mes = d.month.toString().padLeft(2, '0');
    final dia = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mes-$dia';
  }

  /// Compras que pasan los filtros. Un filtro en null o vacío no filtra.
  static List<Purchase> getFiltradas({
    Set<int>? cuentas,
    Set<String>? dias,
  }) {
    return getTodas().where((p) {
      if (cuentas != null && cuentas.isNotEmpty) {
        if (!cuentas.contains(p.accountId)) return false;
      }
      if (dias != null && dias.isNotEmpty) {
        if (!dias.contains(claveDia(p.fecha))) return false;
      }
      return true;
    }).toList();
  }

  /// Cuentas que aparecen en el filtro de cuenta.
  /// Se calculan sobre el filtro de FECHA, nunca sobre el de cuenta:
  /// así elegir una cuenta no borra las demás opciones de la lista.
  static List<({int id, String nombre})> getCuentasDisponibles({
    Set<String>? dias,
  }) {
    final ids = <int>{};
    for (final p in getFiltradas(dias: dias)) {
      ids.add(p.accountId);
    }

    final lista = ids
        .map((id) => (id: id, nombre: AccountService.getAccountName(id)))
        .toList();

    lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  /// Árbol de fechas para el filtro: años, meses y días con compras.
  /// Se calcula sobre el filtro de CUENTA, nunca sobre el de fecha,
  /// por la misma razón que arriba. Ordenado de reciente a viejo.
  /// Los meses y días sin compras no aparecen.
  static List<({int anio, List<({int mes, List<int> dias})> meses})>
      getArbolFechas({Set<int>? cuentas}) {
    // anio -> mes -> días
    final mapa = <int, Map<int, Set<int>>>{};

    for (final p in getFiltradas(cuentas: cuentas)) {
      final porMes = mapa.putIfAbsent(p.fecha.year, () => {});
      final dias = porMes.putIfAbsent(p.fecha.month, () => {});
      dias.add(p.fecha.day);
    }

    final anios = mapa.keys.toList()..sort((a, b) => b.compareTo(a));

    return anios.map((anio) {
      final meses = mapa[anio]!.keys.toList()..sort((a, b) => b.compareTo(a));

      return (
        anio: anio,
        meses: meses.map((mes) {
          final dias = mapa[anio]![mes]!.toList()
            ..sort((a, b) => b.compareTo(a));
          return (mes: mes, dias: dias);
        }).toList(),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────
  // ESCRITURA
  // ─────────────────────────────────────────────

  /// Registra una compra: descuenta el precio de la cuenta y del
  /// método de pago. Si alguno no alcanza, no se registra nada.
  static Future<String?> agregar({
    required String nombre,
    required int precio,
    String? nota,
    required int accountId,
    required int moneyId,
  }) async {
    if (precio <= 0) return 'El precio debe ser mayor a 0';

    final cuenta = AccountService.getAccountById(accountId);
    if (cuenta == null) return 'Esa cuenta ya no existe';

    final dinero = MoneyService.getById(moneyId);
    if (dinero == null) return 'Ese método de pago ya no existe';

    // Validar los dos antes de mover cualquiera
    if (cuenta.balance < precio) return 'Saldo insuficiente en ${cuenta.name}';
    if (dinero.balance < precio) return 'Saldo insuficiente en ${dinero.name}';

    final nuevoId = await StoreHiveService.nextPurchaseId();

    await AccountService.aplicarMovimiento(
      accountId: accountId,
      monto: -precio.toDouble(),
      concepto: 'Compra: $nombre',
      referenciaId: nuevoId,
    );
    await MoneyService.aplicarMovimiento(
      moneyId: moneyId,
      monto: -precio.toDouble(),
      concepto: 'Compra: $nombre',
      referenciaId: nuevoId,
    );

    await StoreHiveService.getPurchasesBox().put(
      nuevoId,
      Purchase(
        id: nuevoId,
        nombre: nombre,
        precio: precio,
        nota: nota,
        accountId: accountId,
        fecha: DateTime.now(),
        moneyId: moneyId,
      ),
    );

    await _recordarUsados(accountId, moneyId);
    return null;
  }

  /// Edita nombre, precio, nota, cuenta o método de pago.
  ///
  /// Cuenta y método se tratan igual, cada uno por su lado:
  /// - si cambió, se cobra COMPLETO al nuevo y se devuelve al viejo;
  /// - si es el mismo, solo se mueve la diferencia de precio.
  ///
  /// Todo se valida antes de mover nada: si algo no alcanza o el
  /// original fue eliminado, la compra queda igual.
  ///
  /// En compras sin método (de antes de Dinero) se ignora [moneyId] y
  /// solo se mueve la cuenta.
  static Future<String?> editar({
    required int purchaseId,
    required String nombre,
    required int precio,
    String? nota,
    required int accountId,
    int? moneyId,
  }) async {
    if (precio <= 0) return 'El precio debe ser mayor a 0';

    final box = StoreHiveService.getPurchasesBox();
    final compra = box.get(purchaseId);
    if (compra == null) return 'La compra ya no existe';

    final conMetodo = compra.moneyId != null;

    // ── Validar cuenta ──
    final cuentaNueva = AccountService.getAccountById(accountId);
    if (cuentaNueva == null) return 'Esa cuenta ya no existe';

    final cambioCuenta = accountId != compra.accountId;
    if (cambioCuenta) {
      if (AccountService.getAccountById(compra.accountId) == null) {
        return 'La cuenta original fue eliminada, no se puede cambiar';
      }
      if (cuentaNueva.balance < precio) {
        return 'Saldo insuficiente en ${cuentaNueva.name}';
      }
    } else {
      final dif = precio - compra.precio;
      if (dif > 0 && cuentaNueva.balance < dif) {
        return 'Saldo insuficiente en ${cuentaNueva.name}';
      }
    }

    // ── Validar método de pago ──
    bool cambioMetodo = false;
    if (conMetodo) {
      if (moneyId == null) return 'Elige un método de pago';

      final dineroNuevo = MoneyService.getById(moneyId);
      if (dineroNuevo == null) return 'Ese método de pago ya no existe';

      cambioMetodo = moneyId != compra.moneyId;
      if (cambioMetodo) {
        if (MoneyService.getById(compra.moneyId!) == null) {
          return 'El método original fue eliminado, no se puede cambiar';
        }
        if (dineroNuevo.balance < precio) {
          return 'Saldo insuficiente en ${dineroNuevo.name}';
        }
      } else {
        final dif = precio - compra.precio;
        if (dif > 0 && dineroNuevo.balance < dif) {
          return 'Saldo insuficiente en ${dineroNuevo.name}';
        }
      }
    }

    // ── Mover cuenta ──
    if (cambioCuenta) {
      await AccountService.aplicarMovimiento(
        accountId: accountId,
        monto: -precio.toDouble(),
        concepto: 'Compra: $nombre',
        referenciaId: compra.id,
      );
      await AccountService.aplicarMovimiento(
        accountId: compra.accountId,
        monto: compra.precio.toDouble(),
        concepto: 'Compra movida a otra cuenta: ${compra.nombre}',
        referenciaId: compra.id,
      );
    } else if (precio != compra.precio) {
      await AccountService.aplicarMovimiento(
        accountId: accountId,
        monto: -(precio - compra.precio).toDouble(), // sube = sale más
        concepto: 'Ajuste de compra: $nombre',
        referenciaId: compra.id,
      );
    }

    // ── Mover método de pago ──
    if (conMetodo) {
      if (cambioMetodo) {
        await MoneyService.aplicarMovimiento(
          moneyId: moneyId!,
          monto: -precio.toDouble(),
          concepto: 'Compra: $nombre',
          referenciaId: compra.id,
        );
        await MoneyService.aplicarMovimiento(
          moneyId: compra.moneyId!,
          monto: compra.precio.toDouble(),
          concepto: 'Compra movida a otro método: ${compra.nombre}',
          referenciaId: compra.id,
        );
      } else if (precio != compra.precio) {
        await MoneyService.aplicarMovimiento(
          moneyId: moneyId!,
          monto: -(precio - compra.precio).toDouble(),
          concepto: 'Ajuste de compra: $nombre',
          referenciaId: compra.id,
        );
      }
    }

    compra.nombre = nombre;
    compra.precio = precio;
    compra.nota = nota;
    compra.accountId = accountId;
    if (conMetodo) compra.moneyId = moneyId;
    await box.put(compra.id, compra);

    await _recordarUsados(accountId, conMetodo ? moneyId : null);
    return null;
  }

  /// Borra la compra de verdad y devuelve el dinero a su cuenta y a su
  /// método de pago. Si alguno de los dos fue eliminado, no se borra
  /// nada.
  static Future<String?> eliminar(int purchaseId) async {
    final box = StoreHiveService.getPurchasesBox();
    final compra = box.get(purchaseId);
    if (compra == null) return 'La compra ya no existe';

    if (AccountService.getAccountById(compra.accountId) == null) {
      return 'La cuenta de esta compra fue eliminada, no se puede devolver';
    }
    final metodoId = compra.moneyId;
    if (metodoId != null && MoneyService.getById(metodoId) == null) {
      return 'El método de pago de esta compra fue eliminado, '
          'no se puede devolver';
    }

    await AccountService.aplicarMovimiento(
      accountId: compra.accountId,
      monto: compra.precio.toDouble(), // entra
      concepto: 'Compra eliminada: ${compra.nombre}',
      referenciaId: compra.id,
    );
    if (metodoId != null) {
      await MoneyService.aplicarMovimiento(
        moneyId: metodoId,
        monto: compra.precio.toDouble(),
        concepto: 'Compra eliminada: ${compra.nombre}',
        referenciaId: compra.id,
      );
    }

    await box.delete(compra.id);
    return null;
  }
}