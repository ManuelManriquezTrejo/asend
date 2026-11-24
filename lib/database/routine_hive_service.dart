import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/daily_routine_habit_adapter.dart';
import 'package:asend/models/habit_history_adapter.dart';
import 'package:asend/models/daily_routine_habit.dart';
import 'package:asend/models/habit_history.dart';

class RoutineHiveService {
  // Nombres de las tablas de Rutina
  static const String dailyRoutineHabitBox = 'daily_routine_habits';
  static const String habitHistoryBox = 'habit_history';

  // Inicializar Hive para Rutina
  static Future<void> initializeRoutineHive() async {
    try {
      // Registrar adapters
      Hive.registerAdapter(DailyRoutineHabitAdapter());
      Hive.registerAdapter(HabitHistoryAdapter());

      // 🧨 TEMPORAL - Borra los datos basura de Rutina.
      //await Hive.deleteBoxFromDisk(dailyRoutineHabitBox);
      //await Hive.deleteBoxFromDisk(habitHistoryBox);

      // Crear tablas
      await Hive.openBox<DailyRoutineHabit>(dailyRoutineHabitBox);
      await Hive.openBox<HabitHistory>(habitHistoryBox);
    } catch (e) {
      debugPrint('❌ Error al inicializar Rutina Hive: $e');
    }
  }

  // Obtener caja de hábitos
  static Box<DailyRoutineHabit> getDailyRoutineHabitBox() {
    return Hive.box<DailyRoutineHabit>(dailyRoutineHabitBox);
  }

  // Obtener caja de histórico
  static Box<HabitHistory> getHabitHistoryBox() {
    return Hive.box<HabitHistory>(habitHistoryBox);
  }
}