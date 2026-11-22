import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/bank/services/money_service.dart';
import 'package:asend/database/money_hive_service.dart';
import 'package:asend/models/fund.dart';
import 'package:asend/models/fund_account.dart';
import 'package:asend/models/fund_money.dart';

class FundService {
  static const String fundsBoxName = 'funds';
  static const String fundAccountsBoxName = 'fund_accounts';

  /// Siguiente ID libre de una caja: uno más que la llave entera más alta.
  /// Contar por longitud repite IDs cuando alguna llave ya fue borrada.
  static int _siguienteId(Box box) {
    int nuevo = 1;
    for (final key in box.keys) {
      if (key is int && key >= nuevo) nuevo = key + 1;
    }
    return nuevo;
  }

  // Agregar un nuevo fondo
  static Future<void> addFund({required String name}) async {
    var fundsBox = Hive.box(fundsBoxName);

    int newId = _siguienteId(fundsBox);

    Fund fund = Fund(id: newId, name: name, createdAt: DateTime.now());

    await fundsBox.put(newId, fund);
  }

  // Obtener todos los fondos ACTIVOS (no eliminados)
  static List<Fund> getAllFunds() {
    var fundsBox = Hive.box(fundsBoxName);

    // Iterar sobre los valores reales, no de 1 a length.
    // Con un hueco en las llaves, el bucle por índice deja fuera
    // todo lo que está después del hueco.
    final funds = <Fund>[];
    for (final value in fundsBox.values) {
      if (value is Fund && value.deletedAt == null) {
        funds.add(value);
      }
    }
    funds.sort((a, b) => a.id.compareTo(b.id));
    return funds;
  }

  // Obtener un fondo por ID
  static Fund? getFundById(int id) {
    var fundsBox = Hive.box(fundsBoxName);
    final value = fundsBox.get(id);
    return value is Fund ? value : null;
  }

  // Agregar una relación fondo-cuenta con porcentaje
  static Future<void> addFundAccount({
    required int fundId,
    required int accountId,
    required double percentage,
  }) async {
    var fundAccountsBox = Hive.box(fundAccountsBoxName);

    int newId = _siguienteId(fundAccountsBox);

    FundAccount fundAccount = FundAccount(
      id: newId,
      fundId: fundId,
      accountId: accountId,
      percentage: percentage,
    );

    await fundAccountsBox.put(newId, fundAccount);
  }

  // Obtener todas las relaciones fondo-cuenta para un fondo específico
  static List<FundAccount> getFundAccountsByFundId(int fundId) {
    var fundAccountsBox = Hive.box(fundAccountsBoxName);

    final fundAccounts = <FundAccount>[];
    for (final value in fundAccountsBox.values) {
      if (value is FundAccount && value.fundId == fundId) {
        fundAccounts.add(value);
      }
    }
    fundAccounts.sort((a, b) => a.id.compareTo(b.id));
    return fundAccounts;
  }

  // ── Reparto a Dinero ───────────────────────────────────

  /// Partes del fondo que van a elementos de Dinero.
  static List<FundMoney> getFundMoneyByFundId(int fundId) {
    final lista = MoneyHiveService.getFundMoneyBox().values
        .where((fm) => fm.fundId == fundId)
        .toList();
    lista.sort((a, b) => a.id.compareTo(b.id));
    return lista;
  }

  /// Reemplaza el reparto a Dinero de un fondo.
  /// [porcentajes] = {moneyId: porcentaje}.
  static Future<void> guardarRepartoDinero({
    required int fundId,
    required Map<int, double> porcentajes,
  }) async {
    await _borrarDineroDeFondo(fundId);

    final box = MoneyHiveService.getFundMoneyBox();
    for (final entrada in porcentajes.entries) {
      final nuevoId = _siguienteId(box);
      await box.put(
        nuevoId,
        FundMoney(
          id: nuevoId,
          fundId: fundId,
          moneyId: entrada.key,
          percentage: entrada.value,
        ),
      );
    }
  }

  static Future<void> _borrarDineroDeFondo(int fundId) async {
    final box = MoneyHiveService.getFundMoneyBox();
    final llaves = box.keys
        .where((k) => box.get(k)?.fundId == fundId)
        .toList();
    for (final k in llaves) {
      await box.delete(k);
    }
  }

  // ── Crear con cuentas y Dinero ─────────────────────────

  /// Crea un fondo con su reparto a Cuentas y a Dinero.
  /// Cada mapa es {id: porcentaje} y debe sumar 100.
  static Future<void> crearFondo({
    required String nombre,
    required Map<int, double> cuentas,
    required Map<int, double> dineros,
  }) async {
    final fundsBox = Hive.box(fundsBoxName);
    final fundId = _siguienteId(fundsBox);

    await fundsBox.put(
      fundId,
      Fund(id: fundId, name: nombre, createdAt: DateTime.now()),
    );

    for (final entrada in cuentas.entries) {
      await addFundAccount(
        fundId: fundId,
        accountId: entrada.key,
        percentage: entrada.value,
      );
    }
    await guardarRepartoDinero(fundId: fundId, porcentajes: dineros);
  }

  /// Reemplaza el reparto a Cuentas y a Dinero de un fondo existente.
  static Future<void> modificarFondo({
    required int fundId,
    required Map<int, double> cuentas,
    required Map<int, double> dineros,
  }) async {
    await updateFundAccountPercentages(
      fundId: fundId,
      accountPercentages: cuentas.entries
          .map((e) => {'accountId': e.key, 'percentage': e.value})
          .toList(),
    );
    await guardarRepartoDinero(fundId: fundId, porcentajes: dineros);
  }

  // ── Fondos con problema ────────────────────────────────

  /// Relaciones del fondo que apuntan a cuentas ya eliminadas de Banco.
  /// Abonar a ese fondo perdería esa parte del dinero.
  static List<FundAccount> getCuentasEliminadas(int fundId) {
    return getFundAccountsByFundId(fundId)
        .where((fa) => AccountService.getAccountById(fa.accountId) == null)
        .toList();
  }

  /// True si el fondo reparte a alguna cuenta eliminada.
  static bool tieneCuentaEliminada(int fundId) =>
      getCuentasEliminadas(fundId).isNotEmpty;

  /// Repartos a Dinero que apuntan a elementos ya eliminados.
  static List<FundMoney> getDineroEliminado(int fundId) {
    return getFundMoneyByFundId(fundId)
        .where((fm) => MoneyService.getById(fm.moneyId) == null)
        .toList();
  }

  /// Qué le falta al fondo para poder abonarle, o null si está bien.
  /// Los fondos creados antes de Dinero no tienen reparto a Dinero.
  static String? motivoProblema(int fundId) {
    final cuentas = getCuentasEliminadas(fundId);
    if (cuentas.isNotEmpty) {
      final nombres = cuentas
          .map((fa) => AccountService.getAccountName(fa.accountId))
          .join(', ');
      return 'Reparte a cuentas que ya no existen: $nombres';
    }

    if (getFundMoneyByFundId(fundId).isEmpty) {
      return 'Todavía no reparte a Dinero';
    }

    final dineros = getDineroEliminado(fundId);
    if (dineros.isNotEmpty) {
      final nombres = dineros
          .map((fm) => MoneyService.getName(fm.moneyId))
          .join(', ');
      return 'Reparte a Dinero que ya no existe: $nombres';
    }
    return null;
  }

  /// True si el fondo no se puede abonar hasta modificarlo.
  static bool tieneProblema(int fundId) => motivoProblema(fundId) != null;

  /// True si algún fondo activo necesita revisión. Enciende el punto
  /// rojo del botón de Fondos.
  static bool hayFondosConProblema() =>
      getAllFunds().any((f) => tieneProblema(f.id));

  // Actualizar los porcentajes de un fondo (reemplaza los antiguos)
  static Future<void> updateFundAccountPercentages({
    required int fundId,
    required List<Map<String, dynamic>> accountPercentages,
    // accountPercentages = [
    //   {'accountId': 1, 'percentage': 50.0},
    //   {'accountId': 2, 'percentage': 50.0},
    // ]
  }) async {
    await _borrarRelacionesDeFondo(fundId);

    for (var item in accountPercentages) {
      await addFundAccount(
        fundId: fundId,
        accountId: item['accountId'],
        percentage: item['percentage'],
      );
    }
  }

  /// Borra de la caja las relaciones fondo-cuenta de un fondo.
  /// Recorre las llaves reales para no depender del orden ni de la longitud.
  static Future<void> _borrarRelacionesDeFondo(int fundId) async {
    var fundAccountsBox = Hive.box(fundAccountsBoxName);

    final llaves = <dynamic>[];
    for (final key in fundAccountsBox.keys) {
      final value = fundAccountsBox.get(key);
      if (value is FundAccount && value.fundId == fundId) {
        llaves.add(key);
      }
    }

    for (final key in llaves) {
      await fundAccountsBox.delete(key);
    }
  }
  /// Cambia el nombre de un fondo. Los abonos anteriores conservan en el
  /// historial el nombre que tenía el fondo cuando se hicieron.
  /// Devuelve null si salió bien, o el mensaje de error.
  static Future<String?> renombrarFondo({
    required int fundId,
    required String nombre,
  }) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return 'Escribe un nombre';

    final fondo = getFundById(fundId);
    if (fondo == null || fondo.deletedAt != null) {
      return 'Ese fondo ya no existe';
    }

    final repetido = getAllFunds().any(
      (f) =>
          f.id != fundId && f.name.trim().toLowerCase() == limpio.toLowerCase(),
    );
    if (repetido) return 'Ya existe un fondo con ese nombre';

    // Fund no permite cambiar sus campos: se guarda una copia con el
    // nombre nuevo bajo la misma llave, conservando id y fecha
    await Hive.box(fundsBoxName).put(
      fundId,
      Fund(id: fondo.id, name: limpio, createdAt: fondo.createdAt),
    );
    return null;
  }
  // Marcar un fondo como eliminado (soft delete)
  static Future<void> deleteFund(int fundId) async {
    var fundsBox = Hive.box(fundsBoxName);
    final value = fundsBox.get(fundId);

    if (value is Fund) {
      Fund deletedFund = Fund(
        id: value.id,
        name: value.name,
        createdAt: value.createdAt,
        deletedAt: DateTime.now(), // ← Marca como eliminado
      );

      await fundsBox.put(fundId, deletedFund);

      // El fondo ya no se usa, sus porcentajes tampoco
      await _borrarRelacionesDeFondo(fundId);
      await _borrarDineroDeFondo(fundId);
    }
  }
}