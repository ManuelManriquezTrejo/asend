import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/account_adapter.dart';
import 'package:asend/models/fund_adapter.dart';
import 'package:asend/models/fund_account_adapter.dart';
import 'package:asend/models/account_history_adapter.dart';
import 'package:asend/models/account_history.dart';
import 'package:asend/models/withdraw_concept_adapter.dart';
import 'package:asend/models/withdraw_concept.dart';

class HiveService {
  // Nombres de las tablas
  static const String accountsBox = 'accounts';
  static const String fundsBox = 'funds';
  static const String fundAccountsBox = 'fund_accounts';
  static const String accountHistoryBox = 'account_history';
  static const String withdrawConceptsBox = 'withdraw_concepts';

  // Inicializar Hive y crear las tablas
  static Future<void> initializeHive() async {
    await Hive.initFlutter();

    // Registrar adapters
    Hive.registerAdapter(AccountAdapter());
    Hive.registerAdapter(FundAdapter());
    Hive.registerAdapter(FundAccountAdapter());
    Hive.registerAdapter(AccountHistoryAdapter());
    Hive.registerAdapter(WithdrawConceptAdapter());
    // BORRAR DATOS
    //await Hive.deleteBoxFromDisk(accountsBox);
    //await Hive.deleteBoxFromDisk(fundsBox);
    //await Hive.deleteBoxFromDisk(fundAccountsBox);
    //await Hive.deleteBoxFromDisk(accountHistoryBox);

    // Crear las tablas vacías si no existen
    await Hive.openBox(accountsBox);
    await Hive.openBox(fundsBox);
    await Hive.openBox(fundAccountsBox);
    await Hive.openBox<AccountHistory>(accountHistoryBox);
    await Hive.openBox<WithdrawConcept>(withdrawConceptsBox);
  }

  // Obtener caja de historial de movimientos
  static Box<AccountHistory> getAccountHistoryBox() {
    return Hive.box<AccountHistory>(accountHistoryBox);
  }

  // Obtener caja de conceptos de retiro
  static Box<WithdrawConcept> getWithdrawConceptsBox() {
    return Hive.box<WithdrawConcept>(withdrawConceptsBox);
  }
}