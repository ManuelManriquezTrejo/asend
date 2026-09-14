import 'package:asend/bank/services/account_service.dart';
import 'package:asend/cashout/services/cash_out_config_service.dart';
import 'package:asend/database/store_hive_service.dart';
import 'package:asend/models/purchase.dart';

/// Toda la lógica de Tienda.
/// Cada compra guarda de qué cuenta salió el dinero. Los movimientos
/// pasan por AccountService.aplicarMovimiento para que queden en
/// AccountHistory.
///
/// Eliminar una compra la borra de verdad de la caja, pero el cobro y
/// la devolución siguen en AccountHistory: la cadena de saldos de la
/// cuenta nunca se rompe.
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

  /// Cuenta que viene marcada al abrir el formulario de compra.
  /// Primero la receptora de Pagos; si no existe o fue eliminada,
  /// la primera cuenta activa de Banco. null si no hay ninguna.
  static int? getCuentaPreseleccionada() {
    final recibeId = CashOutConfigService.getConfigSync()?.cuentaRecibeId;
    if (recibeId != null && AccountService.getAccountById(recibeId) != null) {
      return recibeId;
    }

    final cuentas = AccountService.getAllAccounts();
    return cuentas.isEmpty ? null : cuentas.first.id;
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

  /// Registra una compra y descuenta el precio de la cuenta indicada.
  /// Si no hay saldo, no se registra nada.
  static Future<String?> agregar({
    required String nombre,
    required int precio,
    String? nota,
    required int accountId,
  }) async {
    if (precio <= 0) return 'El precio debe ser mayor a 0';

    final cuenta = AccountService.getAccountById(accountId);
    if (cuenta == null) return 'Esa cuenta ya no existe';

    final nuevoId = await StoreHiveService.nextPurchaseId();

    // Primero el dinero: si falla, no queda una compra huérfana
    final ok = await AccountService.aplicarMovimiento(
      accountId: accountId,
      monto: -precio.toDouble(),
      concepto: 'Compra: $nombre',
      referenciaId: nuevoId,
    );

    if (!ok) return 'Saldo insuficiente en ${cuenta.name}';

    await StoreHiveService.getPurchasesBox().put(
      nuevoId,
      Purchase(
        id: nuevoId,
        nombre: nombre,
        precio: precio,
        nota: nota,
        accountId: accountId,
        fecha: DateTime.now(),
      ),
    );

    return null;
  }

  /// Edita nombre, precio, nota o cuenta.
  ///
  /// Si cambia la cuenta, se cobra COMPLETO a la nueva antes de devolver
  /// nada a la vieja. Si la nueva no alcanza, no se toca absolutamente
  /// nada y la compra queda igual.
  ///
  /// Si la cuenta es la misma, solo se mueve la diferencia de precio.
  static Future<String?> editar({
    required int purchaseId,
    required String nombre,
    required int precio,
    String? nota,
    required int accountId,
  }) async {
    if (precio <= 0) return 'El precio debe ser mayor a 0';

    final box = StoreHiveService.getPurchasesBox();
    final compra = box.get(purchaseId);
    if (compra == null) return 'La compra ya no existe';

    final cuentaNueva = AccountService.getAccountById(accountId);
    if (cuentaNueva == null) return 'Esa cuenta ya no existe';

    final cambioDeCuenta = accountId != compra.accountId;

    if (cambioDeCuenta) {
      // La cuenta vieja tiene que poder recibir la devolución.
      // Si fue eliminada, mejor no mover nada.
      final cuentaVieja = AccountService.getAccountById(compra.accountId);
      if (cuentaVieja == null) {
        return 'La cuenta original fue eliminada, no se puede cambiar';
      }

      // Cobrar primero a la nueva
      final cobrada = await AccountService.aplicarMovimiento(
        accountId: accountId,
        monto: -precio.toDouble(),
        concepto: 'Compra: $nombre',
        referenciaId: compra.id,
      );

      if (!cobrada) return 'Saldo insuficiente en ${cuentaNueva.name}';

      // Ya cobrada, devolver a la vieja el precio anterior
      await AccountService.aplicarMovimiento(
        accountId: compra.accountId,
        monto: compra.precio.toDouble(),
        concepto: 'Compra movida a otra cuenta: ${compra.nombre}',
        referenciaId: compra.id,
      );
    } else {
      final diferencia = precio - compra.precio;

      if (diferencia != 0) {
        final ok = await AccountService.aplicarMovimiento(
          accountId: accountId,
          monto: -diferencia.toDouble(), // sube = sale más, baja = regresa
          concepto: 'Ajuste de compra: $nombre',
          referenciaId: compra.id,
        );

        if (!ok) return 'Saldo insuficiente en ${cuentaNueva.name}';
      }
    }

    compra.nombre = nombre;
    compra.precio = precio;
    compra.nota = nota;
    compra.accountId = accountId;
    await box.put(compra.id, compra);

    return null;
  }

  /// Borra la compra de verdad y devuelve el dinero a su cuenta.
  /// Si la devolución falla, no se borra nada.
  static Future<String?> eliminar(int purchaseId) async {
    final box = StoreHiveService.getPurchasesBox();
    final compra = box.get(purchaseId);
    if (compra == null) return 'La compra ya no existe';

    final cuenta = AccountService.getAccountById(compra.accountId);
    if (cuenta == null) {
      return 'La cuenta de esta compra fue eliminada, no se puede devolver';
    }

    final ok = await AccountService.aplicarMovimiento(
      accountId: compra.accountId,
      monto: compra.precio.toDouble(), // entra
      concepto: 'Compra eliminada: ${compra.nombre}',
      referenciaId: compra.id,
    );

    if (!ok) return 'No se pudo devolver el dinero a la cuenta';

    await box.delete(compra.id);

    return null;
  }
}