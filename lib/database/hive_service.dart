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

    // Crear 4 tablas vacías si no existen
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
  /// Imprime solo cuentas y relaciones fondo-cuenta, para revisar
  /// por qué un fondo no reparte.
  static void printFondos() {
    print('\n===== FONDOS Y CUENTAS =====');

    var accountsBox = Hive.box('accounts');
    print('\nCUENTAS:');
    for (final key in accountsBox.keys) {
      final a = accountsBox.get(key);
      if (a != null) {
        print('  key $key | id ${a.id} | ${a.name} | saldo ${a.balance} '
            '| eliminada: ${a.deletedAt != null}');
      }
    }

    var fundsBox = Hive.box('funds');
    print('\nFONDOS:');
    for (final key in fundsBox.keys) {
      final f = fundsBox.get(key);
      if (f != null) {
        print('  key $key | id ${f.id} | ${f.name} '
            '| eliminado: ${f.deletedAt != null}');
      }
    }

    var fundAccountsBox = Hive.box('fund_accounts');
    print('\nRELACIONES FONDO-CUENTA:');
    for (final key in fundAccountsBox.keys) {
      final fa = fundAccountsBox.get(key);
      if (fa != null) {
        print('  key $key | id ${fa.id} | fondo ${fa.fundId} '
            '→ cuenta ${fa.accountId} | ${fa.percentage}%');
      }
    }

    print('\n============================\n');
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
