import 'package:flutter/foundation.dart';
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
    } catch (e) {
      debugPrint('❌ Error al inicializar Body Hive: $e');
    }
  }

  static Box<BodyZone> getZonesBox() => Hive.box<BodyZone>(zonesBox);

  static Box<BodyMeasurement> getMeasurementsBox() =>
      Hive.box<BodyMeasurement>(measurementsBox);
}