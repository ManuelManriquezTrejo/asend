import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/goal.dart';
import 'package:asend/models/goal_adapter.dart';

class GoalHiveService {
  static const String goalsBox = 'goals';

  static Future<void> initializeGoalHive() async {
    try {
      Hive.registerAdapter(GoalAdapter());

      // 🧨 BORRAR DATOS - descomentar, correr UNA vez y volver a comentar
      // await Hive.deleteBoxFromDisk(goalsBox);

      await Hive.openBox<Goal>(goalsBox);
    } catch (e) {
      debugPrint('❌ Error al inicializar Goals Hive: $e');
    }
  }

  static Box<Goal> getGoalsBox() => Hive.box<Goal>(goalsBox);
}