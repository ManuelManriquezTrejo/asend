import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/mission_adapter.dart';
import 'package:asend/models/mission_history_adapter.dart';
import 'package:asend/models/mission.dart';
import 'package:asend/models/mission_history.dart';

class MissionHiveService {
  static const String missionBox = 'missions';
  static const String missionHistoryBox = 'mission_history';

  static Future<void> initializeMissionHive() async {
    try {
      Hive.registerAdapter(MissionAdapter());
      Hive.registerAdapter(MissionHistoryAdapter());

      // 🧨 TEMPORAL - Se agregó el campo taken, cambió el formato binario.
      // Corre UNA vez y vuelve a comentar.
      //await Hive.deleteBoxFromDisk(missionBox);
      //await Hive.deleteBoxFromDisk(missionHistoryBox);

      await Hive.openBox<Mission>(missionBox);
      await Hive.openBox<MissionHistory>(missionHistoryBox);
    } catch (e) {
      debugPrint('❌ Error al inicializar Misiones Hive: $e');
    }
  }

  static Box<Mission> getMissionBox() => Hive.box<Mission>(missionBox);

  static Box<MissionHistory> getMissionHistoryBox() =>
      Hive.box<MissionHistory>(missionHistoryBox);
}