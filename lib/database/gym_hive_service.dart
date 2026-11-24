import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/exercise_change.dart';
import 'package:asend/models/exercise_change_adapter.dart';
import 'package:asend/models/gym_day.dart';
import 'package:asend/models/gym_day_adapter.dart';
import 'package:asend/models/gym_exercise.dart';
import 'package:asend/models/gym_exercise_adapter.dart';
import 'package:asend/models/gym_session_log.dart';
import 'package:asend/models/gym_session_log_adapter.dart';
import 'package:asend/models/gym_session_set.dart';
import 'package:asend/models/gym_session_set_adapter.dart';

class GymHiveService {
  static const String daysBox = 'gym_days';
  static const String exercisesBox = 'gym_exercises';
  static const String changesBox = 'gym_exercise_changes';
  static const String setsBox = 'gym_session_sets';
  static const String logsBox = 'gym_session_logs';

  static Future<void> initializeGymHive() async {
    try {
      Hive.registerAdapter(GymDayAdapter());
      Hive.registerAdapter(GymExerciseAdapter());
      Hive.registerAdapter(ExerciseChangeAdapter());
      Hive.registerAdapter(GymSessionSetAdapter());
      Hive.registerAdapter(GymSessionLogAdapter());

      // 🧨 BORRAR DATOS - descomentar, correr UNA vez y volver a comentar
      // await Hive.deleteBoxFromDisk(daysBox);
      // await Hive.deleteBoxFromDisk(exercisesBox);
      // await Hive.deleteBoxFromDisk(changesBox);
      // await Hive.deleteBoxFromDisk(setsBox);
      // await Hive.deleteBoxFromDisk(logsBox);

      await Hive.openBox<GymDay>(daysBox);
      await Hive.openBox<GymExercise>(exercisesBox);
      await Hive.openBox<ExerciseChange>(changesBox);
      await Hive.openBox<GymSessionSet>(setsBox);
      await Hive.openBox<GymSessionLog>(logsBox);
    } catch (e) {
      debugPrint('❌ Error al inicializar Gym Hive: $e');
    }
  }

  static Box<GymDay> getDaysBox() => Hive.box<GymDay>(daysBox);

  static Box<GymExercise> getExercisesBox() =>
      Hive.box<GymExercise>(exercisesBox);

  static Box<ExerciseChange> getChangesBox() =>
      Hive.box<ExerciseChange>(changesBox);

  static Box<GymSessionSet> getSetsBox() => Hive.box<GymSessionSet>(setsBox);

  static Box<GymSessionLog> getLogsBox() => Hive.box<GymSessionLog>(logsBox);
}