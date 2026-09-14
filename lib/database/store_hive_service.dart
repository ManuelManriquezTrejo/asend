import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/purchase.dart';
import 'package:asend/models/purchase_adapter.dart';

class StoreHiveService {
  static const String purchasesBox = 'purchases';

  static Future<void> initializeStoreHive() async {
    try {
      Hive.registerAdapter(PurchaseAdapter());

      // 🧨 BORRAR DATOS - descomentar, correr UNA vez y volver a comentar
      // await Hive.deleteBoxFromDisk(purchasesBox);

      await Hive.openBox<Purchase>(purchasesBox);
      await Hive.openBox(storeMetaBox);

      print('✅ Store Hive inicializado');
    } catch (e) {
      print('❌ Error al inicializar Store Hive: $e');
    }
  }

  static Box<Purchase> getPurchasesBox() => Hive.box<Purchase>(purchasesBox);

  /// Caja aparte para el último id usado.
  /// Vive separada porque purchasesBox está tipada como Box<Purchase>
  /// y no acepta guardar un int suelto.
  static const String storeMetaBox = 'store_meta';
  static const String _lastIdKey = 'lastPurchaseId';

  /// Siguiente id de compra. Nunca se recicla, aunque se borren compras.
  static Future<int> nextPurchaseId() async {
    final box = Hive.box(storeMetaBox);
    final ultimo = box.get(_lastIdKey, defaultValue: 0) as int;
    final nuevo = ultimo + 1;
    await box.put(_lastIdKey, nuevo);
    return nuevo;
  }

  /// Ver todos los datos de Tienda
  static void printAllData() {
    String f(DateTime? d) => d == null
        ? '—'
        : d.toIso8601String().split('.')[0].replaceFirst('T', ' ');

    print('\n\n========== 🛒 TIENDA - BASE DE DATOS ==========');

    final box = getPurchasesBox();
    print('\n📌 TABLA: Purchase (${box.length} registros)');

    if (box.isEmpty) {
      print('  ❌ Sin compras');
    } else {
      final compras = box.values.toList()
        ..sort((a, b) => a.fecha.compareTo(b.fecha));

      int totalGastado = 0;
      for (final p in compras) {
        print('  🛍 ─────────────────────────');
        print('     id        : ${p.id}');
        print('     nombre    : ${p.nombre}');
        print('     precio    : ${p.precio}');
        print('     nota      : ${p.nota ?? "—"}');
        print('     cuentaId  : ${p.accountId}');
        print('     fecha     : ${f(p.fecha)}');

        totalGastado += p.precio;
      }
      print('\n  💸 TOTAL GASTADO (histórico): $totalGastado');
    }

    print('\n==========================================\n');
  }
}
