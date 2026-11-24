import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/fund_money.dart';
import 'package:asend/models/fund_money_adapter.dart';
import 'package:asend/models/money_account.dart';
import 'package:asend/models/money_account_adapter.dart';
import 'package:asend/models/money_history.dart';
import 'package:asend/models/money_history_adapter.dart';
import 'package:asend/models/reconciliation.dart';
import 'package:asend/models/reconciliation_adapter.dart';

/// Cajas de Hive de la tarjeta Dinero de Banco, de los cuadres y del
/// reparto de los fondos a Dinero.
class MoneyHiveService {
  static const String accountsBox = 'money_accounts';
  static const String historyBox = 'money_history';
  static const String reconciliationsBox = 'reconciliations';
  static const String fundMoneyBox = 'fund_money';

  /// Valores sueltos de Dinero, como el último usado para pagar.
  /// Guarda tipos simples, así que no necesita adapter.
  static const String settingsBox = 'money_settings';

  static Future<void> initializeMoneyHive() async {
    try {
      Hive.registerAdapter(MoneyAccountAdapter());
      Hive.registerAdapter(MoneyHistoryAdapter());
      Hive.registerAdapter(ReconciliationAdapter());
      Hive.registerAdapter(FundMoneyAdapter());

      // 🧨 BORRAR DATOS - descomentar, correr UNA vez y volver a comentar
      // await Hive.deleteBoxFromDisk(accountsBox);
      // await Hive.deleteBoxFromDisk(historyBox);
      // await Hive.deleteBoxFromDisk(reconciliationsBox);
      // await Hive.deleteBoxFromDisk(fundMoneyBox);
      // await Hive.deleteBoxFromDisk(settingsBox);

      await Hive.openBox<MoneyAccount>(accountsBox);
      await Hive.openBox<MoneyHistory>(historyBox);
      await Hive.openBox<Reconciliation>(reconciliationsBox);
      await Hive.openBox<FundMoney>(fundMoneyBox);
      await Hive.openBox(settingsBox);
    } catch (e) {
      debugPrint('❌ Error al inicializar Money Hive: $e');
    }
  }

  static Box<MoneyAccount> getAccountsBox() =>
      Hive.box<MoneyAccount>(accountsBox);

  static Box<MoneyHistory> getHistoryBox() =>
      Hive.box<MoneyHistory>(historyBox);

  static Box<Reconciliation> getReconciliationsBox() =>
      Hive.box<Reconciliation>(reconciliationsBox);

  static Box<FundMoney> getFundMoneyBox() => Hive.box<FundMoney>(fundMoneyBox);

  static Box getSettingsBox() => Hive.box(settingsBox);
}