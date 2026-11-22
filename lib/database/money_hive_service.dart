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

      print('✅ Money Hive inicializado');
    } catch (e) {
      print('❌ Error al inicializar Money Hive: $e');
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

  /// Ver todos los datos de Dinero
  static void printAllData() {
    String f(DateTime? d) => d == null
        ? '—'
        : d.toIso8601String().split('.')[0].replaceFirst('T', ' ');

    print('\n\n========== 💵 DINERO - BASE DE DATOS ==========');

    final cuentas = getAccountsBox();
    print('\n📌 TABLA: MoneyAccount (${cuentas.length} registros)');

    if (cuentas.isEmpty) {
      print('  ❌ Sin registros');
    } else {
      final lista = cuentas.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      for (final m in lista) {
        print(
          '  ${m.deletedAt == null ? "💵" : "🗑"} '
          '─────────────────────────',
        );
        print('     id           : ${m.id}');
        print('     name         : ${m.name}');
        print('     tipo         : ${m.tipo}');
        print('     balance      : ${m.balance}');
        print('     seleccionada : ${m.seleccionada}');
        print('     createdAt    : ${f(m.createdAt)}');
        print('     deletedAt    : ${f(m.deletedAt)}');
      }
    }

    final historial = getHistoryBox();
    print('\n📌 TABLA: MoneyHistory (${historial.length} registros)');

    if (historial.isEmpty) {
      print('  ❌ Sin movimientos');
    } else {
      final lista = historial.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      for (final h in lista) {
        print(
          '  ${h.monto >= 0 ? "➕" : "➖"} #${h.id} · moneyId ${h.moneyId} · '
          '${h.monto} (${h.saldoAntes} → ${h.saldoDespues}) · '
          '${h.concepto} · ref ${h.referenciaId ?? "—"} · ${f(h.fecha)}',
        );
      }
    }

    final cuadres = getReconciliationsBox();
    print('\n📌 TABLA: Reconciliation (${cuadres.length} registros)');

    if (cuadres.isEmpty) {
      print('  ❌ Sin cuadres');
    } else {
      final lista = cuadres.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      for (final c in lista) {
        print(
          '  ${c.deletedAt == null ? "⚖️" : "🗑"} #${c.id} ${c.nombre} · '
          'cuentas ${c.accountIds} · dinero ${c.moneyIds} · '
          'eliminado ${f(c.deletedAt)}',
        );
      }
    }

    final repartos = getFundMoneyBox();
    print('\n📌 TABLA: FundMoney (${repartos.length} registros)');

    if (repartos.isEmpty) {
      print('  ❌ Sin repartos a Dinero');
    } else {
      final lista = repartos.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      for (final r in lista) {
        print(
          '  💸 #${r.id} · fondo ${r.fundId} → dinero ${r.moneyId} · '
          '${r.percentage}%',
        );
      }
    }

    print('\n==========================================\n');
  }
}