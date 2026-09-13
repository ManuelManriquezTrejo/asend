import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/account_adapter.dart';
import 'package:asend/models/fund_adapter.dart';
import 'package:asend/models/fund_account_adapter.dart';
import 'package:asend/models/account_history_adapter.dart';
import 'package:asend/models/account_history.dart';

class HiveService {
  // Nombres de las tablas
  static const String accountsBox = 'accounts';
  static const String fundsBox = 'funds';
  static const String fundAccountsBox = 'fund_accounts';
  static const String accountHistoryBox = 'account_history';

  // Inicializar Hive y crear las tablas
  static Future<void> initializeHive() async {
    await Hive.initFlutter();

    // Registrar adapters
    Hive.registerAdapter(AccountAdapter());
    Hive.registerAdapter(FundAdapter());
    Hive.registerAdapter(FundAccountAdapter());
    Hive.registerAdapter(AccountHistoryAdapter());

    // BORRAR DATOS
    //await Hive.deleteBoxFromDisk(accountsBox);
    //await Hive.deleteBoxFromDisk(fundsBox);
    //await Hive.deleteBoxFromDisk(fundAccountsBox);
    //await Hive.deleteBoxFromDisk(accountHistoryBox);

    // Crear 4 tablas vacías si no existen
    await Hive.openBox(accountsBox);
    await Hive.openBox(fundsBox);
    await Hive.openBox(fundAccountsBox);
    await Hive.openBox<AccountHistory>(accountHistoryBox);
  }

  // Obtener caja de historial de movimientos
  static Box<AccountHistory> getAccountHistoryBox() {
    return Hive.box<AccountHistory>(accountHistoryBox);
  }

  // Función para ver qué hay en la base de datos
  static void printAllData() {
    print('\n\n========== 📊 BASE DE DATOS ASEND ==========');

    // Cuentas
    var accountsBox = Hive.box('accounts');
    print('\n💰 CUENTAS (${accountsBox.length}):');
    if (accountsBox.isEmpty) {
      print('  ❌ Sin cuentas');
    } else {
      for (int i = 1; i <= accountsBox.length; i++) {
        var account = accountsBox.get(i);
        if (account != null) {
          print('  ✓ ID $i: ${account.name} | Saldo: \$${account.balance}');
        }
      }
    }

    // Fondos
    var fundsBox = Hive.box('funds');
    print('\n🎯 FONDOS (${fundsBox.length}):');
    if (fundsBox.isEmpty) {
      print('  ❌ Sin fondos');
    } else {
      for (int i = 1; i <= fundsBox.length; i++) {
        var fund = fundsBox.get(i);
        if (fund != null) {
          print('  ✓ ID $i: ${fund.name}');
        }
      }
    }

    // Relaciones Fondo-Cuenta
    var fundAccountsBox = Hive.box('fund_accounts');
    print('\n🔗 RELACIONES FONDO-CUENTA (${fundAccountsBox.length}):');
    if (fundAccountsBox.isEmpty) {
      print('  ❌ Sin relaciones');
    } else {
      for (int i = 1; i <= fundAccountsBox.length; i++) {
        var fa = fundAccountsBox.get(i);
        if (fa != null) {
          print(
            '  ✓ ID $i: Fondo ${fa.fundId} → Cuenta ${fa.accountId} (${fa.percentage.toStringAsFixed(1)}%)',
          );
        }
      }
    }

    // Historial de movimientos
    var historyBox = getAccountHistoryBox();
    print('\n📒 HISTORIAL DE MOVIMIENTOS (${historyBox.length}):');
    if (historyBox.isEmpty) {
      print('  ❌ Sin movimientos');
    } else {
      for (final h in historyBox.values) {
        final signo = h.monto >= 0 ? '+' : '';
        print(
          '  ${h.deletedAt == null ? "✓" : "🗑"} ID ${h.id}: '
          'Cuenta ${h.accountId} | $signo${h.monto} | '
          '${h.saldoAntes} → ${h.saldoDespues} | ${h.concepto}',
        );
      }
    }

    print('\n==========================================\n');
  }
}
