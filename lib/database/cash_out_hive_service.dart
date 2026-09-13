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

      print('✅ CashOut Hive inicializado');
    } catch (e) {
      print('❌ Error al inicializar CashOut Hive: $e');
    }
  }

  static Box<CashOut> getCashOutBox() => Hive.box<CashOut>(cashOutBox);

  static Box<CashOutConfig> getConfigBox() =>
      Hive.box<CashOutConfig>(cashOutConfigBox);

  /// Ver todos los datos de CashOut
  static void printAllData() {
    String f(DateTime? d) => d == null
        ? '—'
        : d.toIso8601String().split('.')[0].replaceFirst('T', ' ');

    print('\n\n========== 💰 CASHOUT - BASE DE DATOS ==========');

    final box = getCashOutBox();
    print('\n📌 TABLA: CashOut (${box.length} registros)');
    if (box.isEmpty) {
      print('  ❌ Sin pagos');
    } else {
      final records = box.values.toList()
        ..sort((a, b) => a.fecha.compareTo(b.fecha));

      int totalPendiente = 0;
      for (final c in records) {
        print(
          '  ${c.deletedAt == null ? (c.pagado ? "💵" : "⏳") : "🗑"} '
          '─────────────────────────',
        );
        print('     id        : ${c.id}');
        print('     fecha     : ${f(c.fecha)}');
        print('     nombre    : ${c.nombre}');
        print('     cantidad  : ${c.cantidad}');
        print('     origen    : ${c.origen}');
        print('     pagado    : ${c.pagado}');
        print('     pagadoAt  : ${f(c.pagadoAt)}');
        print('     createdAt : ${f(c.createdAt)}');
        print('     deletedAt : ${f(c.deletedAt)}');

        if (!c.pagado && c.deletedAt == null) {
          totalPendiente += c.cantidad;
        }
      }
      print('\n  💸 TOTAL PENDIENTE: $totalPendiente');
    }

    final configBox = getConfigBox();
    print('\n⚙️  TABLA: CashOutConfig (${configBox.length} registros)');
    if (configBox.isEmpty) {
      print('  ❌ Sin configuración');
    } else {
      for (final c in configBox.values) {
        print('     cuentaPagaId   : ${c.cuentaPagaId ?? "— sin seleccionar"}');
        print(
          '     cuentaRecibeId : ${c.cuentaRecibeId ?? "— sin seleccionar"}',
        );
      }
    }

    print('\n==========================================\n');
  }
}
