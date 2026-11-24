import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/cash_out_adapter.dart';
import 'package:asend/models/cash_out_config_adapter.dart';
import 'package:asend/models/cash_out.dart';
import 'package:asend/models/cash_out_config.dart';

class CashOutHiveService {
  static const String cashOutBox = 'cash_out';
  static const String cashOutConfigBox = 'cash_out_config';

  static Future<void> initializeCashOutHive() async {
    try {
      Hive.registerAdapter(CashOutAdapter());
      Hive.registerAdapter(CashOutConfigAdapter());

      // 🧨 BORRAR DATOS - descomentar, correr UNA vez y volver a comentar
      //await Hive.deleteBoxFromDisk(cashOutBox);
      //await Hive.deleteBoxFromDisk(cashOutConfigBox);

      await Hive.openBox<CashOut>(cashOutBox);
      await Hive.openBox<CashOutConfig>(cashOutConfigBox);
    } catch (e) {
      debugPrint('❌ Error al inicializar CashOut Hive: $e');
    }
  }

  static Box<CashOut> getCashOutBox() => Hive.box<CashOut>(cashOutBox);

  static Box<CashOutConfig> getConfigBox() =>
      Hive.box<CashOutConfig>(cashOutConfigBox);
}