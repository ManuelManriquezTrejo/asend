import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/magic.dart';
import 'package:asend/models/magic_adapter.dart';
import 'package:asend/models/mission_magic_point.dart';
import 'package:asend/models/mission_magic_point_adapter.dart';
import 'package:asend/models/skill.dart';
import 'package:asend/models/skill_adapter.dart';
import 'package:asend/models/stat.dart';
import 'package:asend/models/stat_adapter.dart';
import 'package:asend/models/stat_link.dart';
import 'package:asend/models/stat_link_adapter.dart';
import 'package:asend/models/stat_point.dart';
import 'package:asend/models/stat_point_adapter.dart';

/// Cajas de Hive del módulo Stats. Todas usan el id como clave.
class StatsHiveService {
  static const String statsBox = 'stats';
  static const String linksBox = 'stat_links';
  static const String pointsBox = 'stat_points';
  static const String magicsBox = 'magics';
  static const String skillsBox = 'skills';

  /// Puntos de magia que da cada misión: clave = id de la misión,
  /// valor = puntos. Guarda tipos simples, así que no necesita adapter.
  static const String missionRewardsBox = 'mission_rewards';

  /// Puntos de magia ya ganados por misiones completadas.
  static const String missionPointsBox = 'mission_magic_points';

  /// Valores sueltos de Stats: nombre del personaje y último día
  /// procesado. Guarda tipos simples, así que no necesita adapter.
  static const String settingsBox = 'stats_settings';

  static Future<void> initializeStatsHive() async {
    try {
      Hive.registerAdapter(StatAdapter());
      Hive.registerAdapter(StatLinkAdapter());
      Hive.registerAdapter(StatPointAdapter());
      Hive.registerAdapter(MagicAdapter());
      Hive.registerAdapter(SkillAdapter());
      Hive.registerAdapter(MissionMagicPointAdapter());

      // 🧨 BORRAR DATOS - descomentar, correr UNA vez y volver a comentar
      // await Hive.deleteBoxFromDisk(statsBox);
      // await Hive.deleteBoxFromDisk(linksBox);
      // await Hive.deleteBoxFromDisk(pointsBox);
      // await Hive.deleteBoxFromDisk(magicsBox);
      // await Hive.deleteBoxFromDisk(skillsBox);
      // await Hive.deleteBoxFromDisk(settingsBox);
      // await Hive.deleteBoxFromDisk(missionRewardsBox);
      // await Hive.deleteBoxFromDisk(missionPointsBox);

      await Hive.openBox<Stat>(statsBox);
      await Hive.openBox<StatLink>(linksBox);
      await Hive.openBox<StatPoint>(pointsBox);
      await Hive.openBox<Magic>(magicsBox);
      await Hive.openBox<Skill>(skillsBox);
      await Hive.openBox(settingsBox);
      await Hive.openBox(missionRewardsBox);
      await Hive.openBox<MissionMagicPoint>(missionPointsBox);
    } catch (e) {
      debugPrint('❌ Error al inicializar Stats Hive: $e');
    }
  }

  static Box<Stat> getStatsBox() => Hive.box<Stat>(statsBox);

  static Box<StatLink> getLinksBox() => Hive.box<StatLink>(linksBox);

  static Box<StatPoint> getPointsBox() => Hive.box<StatPoint>(pointsBox);

  static Box<Magic> getMagicsBox() => Hive.box<Magic>(magicsBox);

  static Box<Skill> getSkillsBox() => Hive.box<Skill>(skillsBox);

  static Box getSettingsBox() => Hive.box(settingsBox);

  static Box getMissionRewardsBox() => Hive.box(missionRewardsBox);

  static Box<MissionMagicPoint> getMissionPointsBox() =>
      Hive.box<MissionMagicPoint>(missionPointsBox);
}
