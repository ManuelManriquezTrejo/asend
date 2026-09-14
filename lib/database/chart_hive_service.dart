import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/chart_line_color.dart';
import 'package:asend/models/chart_line_color_adapter.dart';

class ChartHiveService {
  static const String lineColorsBox = 'chart_line_colors';

  static Future<void> initializeChartHive() async {
    try {
      Hive.registerAdapter(ChartLineColorAdapter());

      // 🧨 BORRAR DATOS - descomentar, correr UNA vez y volver a comentar
      // await Hive.deleteBoxFromDisk(lineColorsBox);

      await Hive.openBox<ChartLineColor>(lineColorsBox);

      print('✅ Chart Hive inicializado');
    } catch (e) {
      print('❌ Error al inicializar Chart Hive: $e');
    }
  }

  static Box<ChartLineColor> getLineColorsBox() =>
      Hive.box<ChartLineColor>(lineColorsBox);

  /// Ver todos los colores guardados de las gráficas
  static void printAllData() {
    String f(DateTime? d) => d == null
        ? '—'
        : d.toIso8601String().split('.')[0].replaceFirst('T', ' ');

    print('\n\n========== 📈 GRÁFICAS - BASE DE DATOS ==========');

    final colores = getLineColorsBox();
    print('\n📌 TABLA: ChartLineColor (${colores.length} registros)');

    if (colores.isEmpty) {
      print('  ❌ Sin colores guardados');
    } else {
      final lista = colores.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      for (final c in lista) {
        print(
          '  ${c.deletedAt == null ? "🎨" : "🗑"} '
          '─────────────────────────',
        );
        print('     id        : ${c.id}');
        print('     clave     : ${c.clave}');
        print('     color     : 0x${c.color.toRadixString(16).toUpperCase()}');
        print('     createdAt : ${f(c.createdAt)}');
        print('     deletedAt : ${f(c.deletedAt)}');
      }
    }

    print('\n==========================================\n');
  }
}