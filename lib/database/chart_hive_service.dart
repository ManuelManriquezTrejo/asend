import 'package:flutter/foundation.dart';
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
    } catch (e) {
      debugPrint('❌ Error al inicializar Chart Hive: $e');
    }
  }

  static Box<ChartLineColor> getLineColorsBox() =>
      Hive.box<ChartLineColor>(lineColorsBox);
}