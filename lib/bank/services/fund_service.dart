import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/fund.dart';
import 'package:asend/models/fund_account.dart';

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
    }
  }
}