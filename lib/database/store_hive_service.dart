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

      print('✅ Store Hive inicializado');
    } catch (e) {
      print('❌ Error al inicializar Store Hive: $e');
    }
  }

  static Box<Purchase> getPurchasesBox() => Hive.box<Purchase>(purchasesBox);

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
        print(
          '  ${p.deletedAt == null ? "🛍" : "🗑"} '
          '─────────────────────────',
        );
        print('     id        : ${p.id}');
        print('     nombre    : ${p.nombre}');
        print('     precio    : ${p.precio}');
        print('     nota      : ${p.nota ?? "—"}');
        print('     fecha     : ${f(p.fecha)}');
        print('     deletedAt : ${f(p.deletedAt)}');

        if (p.deletedAt == null) {
          totalGastado += p.precio;
        }
      }
      print('\n  💸 TOTAL GASTADO (histórico): $totalGastado');
    }

    print('\n==========================================\n');
  }
}
