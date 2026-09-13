import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/daily_routine_habit_adapter.dart';
import 'package:asend/models/habit_history_adapter.dart';
import 'package:asend/models/DailyRoutineHabit.dart';
import 'package:asend/models/HabitHistory.dart';

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

      print('✅ Rutina Hive inicializado');
    } catch (e) {
      print('❌ Error al inicializar Rutina Hive: $e');
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

  /// Ver TODOS los campos de ambas tablas de Rutina
  static void printAllData() {
    String f(DateTime? d) => d == null
        ? '—'
        : d.toIso8601String().split('.')[0].replaceFirst('T', ' ');

    print('\n\n========== 📋 RUTINA - BASE DE DATOS ==========');

    final habitBox = getDailyRoutineHabitBox();
    print('\n📌 TABLA: DailyRoutineHabit (${habitBox.length} registros)');
    if (habitBox.isEmpty) {
      print('  ❌ Sin hábitos');
    } else {
      for (final h in habitBox.values) {
        print(
          '  ${h.deletedAt == null ? "✓" : "🗑"} ─────────────────────────',
        );
        print('     id                 : ${h.id}');
        print('     nombre             : ${h.nombre}');
        print('     tipo               : ${h.tipo}');
        print('     valor              : ${h.valor}');
        print('     prioridad          : ${h.prioridad}');
        print('     createdAt          : ${f(h.createdAt)}');
        print('     currentStreak      : ${h.currentStreak}');
        print('     maxStreak          : ${h.maxStreak}');
        print('     maxStreakStartDate : ${f(h.maxStreakStartDate)}');
        print('     maxStreakEndDate   : ${f(h.maxStreakEndDate)}');
        print('     secondMaxStreak    : ${h.secondMaxStreak}');
        print('     minToKeepStreak    : ${h.minToKeepStreak}');
        print('     deletedAt          : ${f(h.deletedAt)}');
      }
    }

    final historyBox = getHabitHistoryBox();
    print('\n📅 TABLA: HabitHistory (${historyBox.length} registros)');
    if (historyBox.isEmpty) {
      print('  ❌ Sin registros');
    } else {
      // Ordenar por hábito y luego por fecha, para leerlo fácil
      final records = historyBox.values.toList()
        ..sort((a, b) {
          final c = a.habitId.compareTo(b.habitId);
          return c != 0 ? c : a.recordDate.compareTo(b.recordDate);
        });

      for (final r in records) {
        final nombre = habitBox.values
            .where((h) => h.id == r.habitId)
            .map((h) => h.nombre)
            .join();
        print(
          '  ${r.deletedAt == null ? "✓" : "🗑"} ─────────────────────────',
        );
        print('     id            : ${r.id}');
        print(
          '     habitId       : ${r.habitId} (${nombre.isEmpty ? "?" : nombre})',
        );
        print('     recordDate    : ${f(r.recordDate)}');
        print('     recordedAt    : ${f(r.recordedAt)}');
        print('     value         : ${r.value}');
        print('     tipoSnapshot  : ${r.tipoSnapshot}');
        print('     valorSnapshot : ${r.valorSnapshot}');
        print('     deletedAt     : ${f(r.deletedAt)}');
      }
    }

    print('\n==========================================\n');
  }
}
