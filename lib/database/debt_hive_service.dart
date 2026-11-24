import 'package:flutter/foundation.dart';
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
    } catch (e) {
      debugPrint('❌ Error al inicializar Debt Hive: $e');
    }
  }

  static Box<Debt> getDebtsBox() => Hive.box<Debt>(debtsBox);

  static Box<DebtInstallment> getInstallmentsBox() =>
      Hive.box<DebtInstallment>(installmentsBox);

  static Box getSettingsBox() => Hive.box(settingsBox);
}