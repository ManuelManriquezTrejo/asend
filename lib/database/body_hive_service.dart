import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/body_measurement.dart';
import 'package:asend/models/body_measurement_adapter.dart';
import 'package:asend/models/body_zone.dart';
import 'package:asend/models/body_zone_adapter.dart';

class BodyHiveService {
  static const String zonesBox = 'body_zones';
  static const String measurementsBox = 'body_measurements';

  static Future<void> initializeBodyHive() async {
    try {
      Hive.registerAdapter(BodyZoneAdapter());
      Hive.registerAdapter(BodyMeasurementAdapter());

      // 🧨 BORRAR DATOS - descomentar, correr UNA vez y volver a comentar
      // await Hive.deleteBoxFromDisk(zonesBox);
      // await Hive.deleteBoxFromDisk(measurementsBox);

      await Hive.openBox<BodyZone>(zonesBox);
      await Hive.openBox<BodyMeasurement>(measurementsBox);

      print('✅ Body Hive inicializado');
    } catch (e) {
      print('❌ Error al inicializar Body Hive: $e');
    }
  }

  static Box<BodyZone> getZonesBox() => Hive.box<BodyZone>(zonesBox);

  static Box<BodyMeasurement> getMeasurementsBox() =>
      Hive.box<BodyMeasurement>(measurementsBox);

  /// Ver todos los datos de Medidas
  static void printAllData() {
    String f(DateTime? d) => d == null
        ? '—'
        : d.toIso8601String().split('.')[0].replaceFirst('T', ' ');

    print('\n\n========== 📏 MEDIDAS - BASE DE DATOS ==========');

    final zonas = getZonesBox();
    print('\n📌 TABLA: BodyZone (${zonas.length} registros)');

    if (zonas.isEmpty) {
      print('  ❌ Sin zonas');
    } else {
      final lista = zonas.values.toList()
        ..sort((a, b) => a.orden.compareTo(b.orden));

      for (final z in lista) {
        print(
          '  ${z.deletedAt == null ? "📏" : "🗑"} '
          '─────────────────────────',
        );
        print('     id        : ${z.id}');
        print('     nombre    : ${z.nombre}');
        print('     unidad    : ${z.unidad}');
        print('     orden     : ${z.orden}');
        print('     createdAt : ${f(z.createdAt)}');
        print('     deletedAt : ${f(z.deletedAt)}');
      }
    }

    final medidas = getMeasurementsBox();
    print('\n📌 TABLA: BodyMeasurement (${medidas.length} registros)');

    if (medidas.isEmpty) {
      print('  ❌ Sin mediciones');
    } else {
      final lista = medidas.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      for (final m in lista) {
        print(
          '  ${m.deletedAt == null ? "📊" : "🗑"} '
          '─────────────────────────',
        );
        print('     id        : ${m.id}');
        print('     zonaId    : ${m.zonaId}');
        print('     valor     : ${m.valor} ${m.unidadSnapshot}');
        print('     fecha     : ${f(m.fecha)}');
        print('     createdAt : ${f(m.createdAt)}');
        print('     deletedAt : ${f(m.deletedAt)}');
      }
    }

    print('\n==========================================\n');
  }
}
