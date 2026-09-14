import 'package:asend/models/habit_history.dart';
import 'package:asend/models/daily_routine_habit.dart';
import 'package:asend/database/routine_hive_service.dart';
import 'package:asend/config/app_config.dart';
import 'package:asend/cashout/services/cash_out_service.dart';

class HabitHistoryService {
  /// ÚNICA fuente de verdad para "qué día es hoy".
  static DateTime getToday() {
    return getLogicalDay(DateTime.now());
  }

  /// Convierte cualquier fecha/hora a su "día lógico" según el cutoff.
  static DateTime getLogicalDay(DateTime moment) {
    DateTime day = DateTime(moment.year, moment.month, moment.day);
    if (moment.hour < AppConfig.dailyCutoffHour) {
      day = day.subtract(const Duration(days: 1));
    }
    return day;
  }

  /// Guardar cambios de un hábito usando su clave real de Hive
  static Future<void> saveHabit(DailyRoutineHabit habit) async {
    final box = RoutineHiveService.getDailyRoutineHabitBox();
    for (final k in box.keys) {
      if (box.get(k)?.id == habit.id) {
        await box.put(k, habit);
        return;
      }
    }
  }

  /// Soft delete de todo el historial de un hábito.
  /// Se usa al cambiar el tipo: los valores viejos (notas 0-11) no son
  /// comparables con los nuevos (horas), así que dejan de contar para la
  /// racha, pero siguen en la tabla para estadísticas históricas.
  static Future<void> softDeleteHistory(int habitId) async {
    final box = RoutineHiveService.getHabitHistoryBox();
    final now = DateTime.now();
    for (final k in box.keys) {
      final r = box.get(k);
      if (r != null && r.habitId == habitId && r.deletedAt == null) {
        r.deletedAt = now;
        await box.put(k, r);
      }
    }
    print('🗑 Historial de hábito $habitId archivado por cambio de tipo');
  }

  /// Crear nuevo registro en HabitHistory
  static Future<void> createHabitRecord({
    required int habitId,
    required double value,
  }) async {
    try {
      final box = RoutineHiveService.getHabitHistoryBox();
      final habitBox = RoutineHiveService.getDailyRoutineHabitBox();

      // Foto del hábito en este momento: si mañana editas tipo o valor,
      // este registro conserva las reglas que aplicaban hoy.
      DailyRoutineHabit? habit;
      for (final h in habitBox.values) {
        if (h.id == habitId) {
          habit = h;
          break;
        }
      }
      if (habit == null) {
        print('❌ No se encontró el hábito $habitId');
        return;
      }

      int nextId = 1;
      for (final r in box.values) {
        if (r.id >= nextId) nextId = r.id + 1;
      }

      final newRecord = HabitHistory(
        id: nextId,
        habitId: habitId,
        recordDate: getToday(),
        recordedAt: DateTime.now(),
        value: value,
        tipoSnapshot: habit.tipo,
        valorSnapshot: habit.valor,
      );

      await box.add(newRecord);
      print(
        '✅ Registro guardado: Hábito $habitId = $value '
        '(${habit.tipo}, paga ${habit.valor})',
      );
    } catch (e) {
      print('❌ Error al crear registro: $e');
    }
  }

  /// Verificar si un hábito ya fue registrado hoy
  static bool isHabitRecordedToday(int habitId) {
    try {
      final box = RoutineHiveService.getHabitHistoryBox();
      final today = getToday();

      return box.values.any(
        (h) =>
            h.habitId == habitId &&
            h.recordDate.isAtSameMomentAs(today) &&
            h.deletedAt == null,
      );
    } catch (e) {
      print('❌ Error al verificar registro: $e');
      return false;
    }
  }

  /// Obtener todos los registros de un hábito
  static List<HabitHistory> getHabitRecords(int habitId) {
    try {
      final box = RoutineHiveService.getHabitHistoryBox();
      return box.values
          .where((r) => r.habitId == habitId && r.deletedAt == null)
          .toList();
    } catch (e) {
      print('❌ Error al obtener registros: $e');
      return [];
    }
  }

  /// Auto-rellenar días faltantes con 0.
  /// NO rellena el día actual: solo días ya terminados.
  static Future<void> fillMissingDaysWithZero() async {
    try {
      final habitBox = RoutineHiveService.getDailyRoutineHabitBox();
      final historyBox = RoutineHiveService.getHabitHistoryBox();

      final today = getToday();

      int maxRecordId = 0;
      for (final r in historyBox.values) {
        if (r.id > maxRecordId) maxRecordId = r.id;
      }

      for (final h in habitBox.values) {
        if (h.deletedAt != null) continue; // Ignorar eliminados

        // El día de creación también se ajusta al cutoff
        DateTime current = getLogicalDay(h.createdAt);

        while (current.isBefore(today)) {
      final exists = historyBox.values.any(
            (r) => r.habitId == h.id && r.recordDate.isAtSameMomentAs(current),
          );

          if (!exists) {
            maxRecordId++;
            await historyBox.add(
              HabitHistory(
                id: maxRecordId,
                habitId: h.id,
                recordDate: current,
                recordedAt: current,
                value: 0.0,
                tipoSnapshot: h.tipo,
                valorSnapshot: h.valor,
              ),
            );
            print(
              '📅 Auto-relleno: Hábito ${h.id} en '
              '${current.toIso8601String().split('T')[0]} = 0',
            );
          }

          current = current.add(const Duration(days: 1));
        }
      }

      // Con el historial ya completo, recalcular TODAS las rachas.
      // Sin esto, un día fallido no rompe la racha hasta que marques algo.
      for (final h in habitBox.values) {
        if (h.deletedAt != null) continue;
        recalculateStreak(h);
        await saveHabit(h);
      }

      // Generar el pago de cada día ya cerrado que aún no lo tenga.
      // Se recorre desde el registro más antiguo hasta ayer.
      final activos = historyBox.values
          .where((r) => r.deletedAt == null)
          .toList();
      if (activos.isNotEmpty) {
        DateTime dia = activos
            .map((r) => r.recordDate)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        while (dia.isBefore(today)) {
          await CashOutService.generarPagoDiario(dia);
          dia = dia.add(const Duration(days: 1));
        }
      }

      print('✅ Auto-relleno, rachas y pagos actualizados');
    } catch (e) {
      print('❌ Error en auto-relleno: $e');
    }
  }

  /// Recalcular racha de un hábito
  static void recalculateStreak(DailyRoutineHabit habit) {
    try {
      final records = getHabitRecords(habit.id);
      if (records.isEmpty) {
        habit.currentStreak = 0;
        return;
      }

      // Más reciente primero
      records.sort((a, b) => b.recordDate.compareTo(a.recordDate));

      int streak = 0;
      DateTime? lastDate;

      for (final record in records) {
        if (record.value < habit.minToKeepStreak) break;

        // Verificar continuidad de días
        if (lastDate != null) {
          final expected = lastDate.subtract(const Duration(days: 1));
          if (!record.recordDate.isAtSameMomentAs(expected)) break;
        }

        streak++;
        lastDate = record.recordDate;
      }

      habit.currentStreak = streak;

      if (streak > habit.maxStreak) {
        habit.maxStreak = streak;
      }

      print('🔄 Racha recalculada para ${habit.nombre}: $streak días');
    } catch (e) {
      print('❌ Error al recalcular racha: $e');
    }
  }
}
