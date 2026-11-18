import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/debt.dart';
import 'package:asend/models/debt_adapter.dart';
import 'package:asend/models/debt_installment.dart';
import 'package:asend/models/debt_installment_adapter.dart';

class DebtHiveService {
  static const String debtsBox = 'debts';
  static const String installmentsBox = 'debt_installments';

  /// Valores sueltos de Deuda, como la última cuenta usada para pagar.
  /// Guarda tipos simples, así que no necesita adapter.
  static const String settingsBox = 'debt_settings';

  static Future<void> initializeDebtHive() async {
    try {
      Hive.registerAdapter(DebtAdapter());
      Hive.registerAdapter(DebtInstallmentAdapter());

      // 🧨 BORRAR DATOS - descomentar, correr UNA vez y volver a comentar
      // await Hive.deleteBoxFromDisk(debtsBox);
      // await Hive.deleteBoxFromDisk(installmentsBox);
      // await Hive.deleteBoxFromDisk(settingsBox);

      await Hive.openBox<Debt>(debtsBox);
      await Hive.openBox<DebtInstallment>(installmentsBox);
      await Hive.openBox(settingsBox);

      print('✅ Debt Hive inicializado');
    } catch (e) {
      print('❌ Error al inicializar Debt Hive: $e');
    }
  }

  static Box<Debt> getDebtsBox() => Hive.box<Debt>(debtsBox);

  static Box<DebtInstallment> getInstallmentsBox() =>
      Hive.box<DebtInstallment>(installmentsBox);

  static Box getSettingsBox() => Hive.box(settingsBox);

  /// Ver todos los datos de Deuda
  static void printAllData() {
    String f(DateTime? d) => d == null
        ? '—'
        : d.toIso8601String().split('.')[0].replaceFirst('T', ' ');

    print('\n\n========== 💳 DEUDA - BASE DE DATOS ==========');

    final deudas = getDebtsBox();
    print('\n📌 TABLA: Debt (${deudas.length} registros)');

    if (deudas.isEmpty) {
      print('  ❌ Sin deudas');
    } else {
      final lista = deudas.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      for (final d in lista) {
        print(
          '  ${d.deletedAt == null ? "💳" : "🗑"} '
          '─────────────────────────',
        );
        print('     id          : ${d.id}');
        print('     nombre      : ${d.nombre}');
        print('     tipo        : ${d.tipo}');
        print('     monto       : ${d.monto}');
        print('     diaPago     : ${d.diaPago}');
        print('     diasLimite  : ${d.diasLimite}');
        print('     fechaInicio : ${f(d.fechaInicio)}');
        print('     meses       : ${d.meses}');
        print('     createdAt   : ${f(d.createdAt)}');
        print('     deletedAt   : ${f(d.deletedAt)}');
      }
    }

    final cuotas = getInstallmentsBox();
    print('\n📌 TABLA: DebtInstallment (${cuotas.length} registros)');

    if (cuotas.isEmpty) {
      print('  ❌ Sin mensualidades');
    } else {
      final lista = cuotas.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      for (final c in lista) {
        final icono = c.deletedAt != null
            ? '🗑'
            : c.pagadoAt != null
            ? '✅'
            : '⏳';
        print('  $icono ─────────────────────────');
        print('     id          : ${c.id}');
        print('     debtId      : ${c.debtId}');
        print('     numero      : ${c.numero}');
        print('     monto       : ${c.monto}');
        print('     fechaPago   : ${f(c.fechaPago)}');
        print('     fechaLimite : ${f(c.fechaLimite)}');
        print('     pagadoAt    : ${f(c.pagadoAt)}');
        print('     accountId   : ${c.accountId ?? "—"}');
        print('     deletedAt   : ${f(c.deletedAt)}');
      }
    }

    print('\n📌 Última cuenta usada: '
        '${getSettingsBox().get('ultimaCuentaId') ?? "—"}');

    print('\n==========================================\n');
  }
}