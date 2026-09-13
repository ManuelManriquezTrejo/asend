import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/fund.dart';
import 'package:asend/models/fund_account.dart';

class FundService {
  static const String fundsBoxName = 'funds';
  static const String fundAccountsBoxName = 'fund_accounts';

  // Agregar un nuevo fondo
  static Future<void> addFund({required String name}) async {
    var fundsBox = Hive.box(fundsBoxName);

    // El ID es el índice + 1
    int newId = fundsBox.length + 1;

    // Crear objeto Fund
    Fund fund = Fund(id: newId, name: name, createdAt: DateTime.now());

    // Guardar en Hive usando el ID como key
    await fundsBox.put(newId, fund);
  }

  // Obtener todos los fondos ACTIVOS (no eliminados)
  static List<Fund> getAllFunds() {
    var fundsBox = Hive.box(fundsBoxName);

    if (fundsBox.isEmpty) {
      return [];
    }

    List<Fund> funds = [];
    for (int i = 1; i <= fundsBox.length; i++) {
      var fund = fundsBox.get(i);
      // Solo mostrar si NO está eliminado
      if (fund != null && fund.deletedAt == null) {
        funds.add(fund);
      }
    }
    return funds;
  }

  // Obtener un fondo por ID
  static Fund? getFundById(int id) {
    var fundsBox = Hive.box(fundsBoxName);
    return fundsBox.get(id);
  }

  // Agregar una relación fondo-cuenta con porcentaje
  static Future<void> addFundAccount({
    required int fundId,
    required int accountId,
    required double percentage,
  }) async {
    var fundAccountsBox = Hive.box(fundAccountsBoxName);

    // El ID es el índice + 1
    int newId = fundAccountsBox.length + 1;

    // Crear objeto FundAccount
    FundAccount fundAccount = FundAccount(
      id: newId,
      fundId: fundId,
      accountId: accountId,
      percentage: percentage,
    );

    // Guardar en Hive
    await fundAccountsBox.put(newId, fundAccount);
  }

  // Obtener todas las relaciones fondo-cuenta para un fondo específico
  static List<FundAccount> getFundAccountsByFundId(int fundId) {
    var fundAccountsBox = Hive.box(fundAccountsBoxName);

    if (fundAccountsBox.isEmpty) {
      return [];
    }

    List<FundAccount> fundAccounts = [];
    for (int i = 1; i <= fundAccountsBox.length; i++) {
      var fundAccount = fundAccountsBox.get(i);
      if (fundAccount != null && fundAccount.fundId == fundId) {
        fundAccounts.add(fundAccount);
      }
    }
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
    var fundAccountsBox = Hive.box(fundAccountsBoxName);

    // Borrar las relaciones antiguas de este fondo
    List<int> keysToDelete = [];
    for (int i = 1; i <= fundAccountsBox.length; i++) {
      var fundAccount = fundAccountsBox.get(i);
      if (fundAccount != null && fundAccount.fundId == fundId) {
        keysToDelete.add(i);
      }
    }

    for (int key in keysToDelete) {
      await fundAccountsBox.delete(key);
    }

    // Agregar las nuevas relaciones
    for (var item in accountPercentages) {
      await addFundAccount(
        fundId: fundId,
        accountId: item['accountId'],
        percentage: item['percentage'],
      );
    }
  }

  // Marcar un fondo como eliminado (soft delete)
  static Future<void> deleteFund(int fundId) async {
    var fundsBox = Hive.box(fundsBoxName);
    Fund? fund = fundsBox.get(fundId);

    if (fund != null) {
      Fund deletedFund = Fund(
        id: fund.id,
        name: fund.name,
        createdAt: fund.createdAt,
        deletedAt: DateTime.now(), // ← Marca como eliminado
      );

      await fundsBox.put(fundId, deletedFund);
    }
  }
}
