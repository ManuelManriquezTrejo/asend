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

      print('✅ Gym Hive inicializado');
    } catch (e) {
      print('❌ Error al inicializar Gym Hive: $e');
    }
  }

  static Box<GymDay> getDaysBox() => Hive.box<GymDay>(daysBox);

  static Box<GymExercise> getExercisesBox() =>
      Hive.box<GymExercise>(exercisesBox);

  static Box<ExerciseChange> getChangesBox() =>
      Hive.box<ExerciseChange>(changesBox);

  static Box<GymSessionSet> getSetsBox() => Hive.box<GymSessionSet>(setsBox);

  static Box<GymSessionLog> getLogsBox() => Hive.box<GymSessionLog>(logsBox);

  /// Ver todos los datos de Gym
  static void printAllData() {
    String f(DateTime? d) => d == null
        ? '—'
        : d.toIso8601String().split('.')[0].replaceFirst('T', ' ');

    print('\n\n========== 🏋️ GYM - BASE DE DATOS ==========');

    // ── Días ──
    final dias = getDaysBox();
    print('\n📌 TABLA: GymDay (${dias.length} registros)');

    if (dias.isEmpty) {
      print('  ❌ Sin días');
    } else {
      final lista = dias.values.toList()
        ..sort((a, b) => a.orden.compareTo(b.orden));

      for (final d in lista) {
        print(
          '  ${d.deletedAt == null ? "📅" : "🗑"} '
          '─────────────────────────',
        );
        print('     id        : ${d.id}');
        print('     nombre    : ${d.nombre}');
        print('     orden     : ${d.orden}');
        print('     createdAt : ${f(d.createdAt)}');
        print('     deletedAt : ${f(d.deletedAt)}');
      }
    }

    // ── Ejercicios ──
    final ejercicios = getExercisesBox();
    print('\n📌 TABLA: GymExercise (${ejercicios.length} registros)');

    if (ejercicios.isEmpty) {
      print('  ❌ Sin ejercicios');
    } else {
      final lista = ejercicios.values.toList()
        ..sort((a, b) {
          final porDia = a.diaId.compareTo(b.diaId);
          return porDia != 0 ? porDia : a.orden.compareTo(b.orden);
        });

      for (final e in lista) {
        print(
          '  ${e.deletedAt == null ? "🏋️" : "🗑"} '
          '─────────────────────────',
        );
        print('     id        : ${e.id}');
        print('     diaId     : ${e.diaId}');
        print('     nombre    : ${e.nombre}');
        print('     peso      : ${e.peso} ${e.unidadPeso}');
        print('     formato   : ${e.series}x${e.reps}');
        print('     orden     : ${e.orden}');
        print('     createdAt : ${f(e.createdAt)}');
        print('     deletedAt : ${f(e.deletedAt)}');
      }
    }

    // ── Cambios ──
    final cambios = getChangesBox();
    print('\n📌 TABLA: ExerciseChange (${cambios.length} registros)');

    if (cambios.isEmpty) {
      print('  ❌ Sin cambios');
    } else {
      final lista = cambios.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      for (final c in lista) {
        print(
          '  ${c.deletedAt == null ? "📝" : "🗑"} '
          '─────────────────────────',
        );
        print('     id          : ${c.id}');
        print('     ejercicioId : ${c.ejercicioId}');
        print('     peso        : ${c.peso} ${c.unidadPeso}');
        print('     formato     : ${c.series}x${c.reps}');
        print('     fecha       : ${f(c.fecha)}');
        print('     deletedAt   : ${f(c.deletedAt)}');
      }
    }

    // ── Sesión en curso ──
    final sets = getSetsBox();
    print(
      '\n📌 TABLA: GymSessionSet (${sets.length} registros) '
      '— guardado temporal',
    );

    if (sets.isEmpty) {
      print('  ❌ Sin sesiones en curso');
    } else {
      final lista = sets.values.toList()
        ..sort((a, b) {
          final porEjercicio = a.ejercicioId.compareTo(b.ejercicioId);
          return porEjercicio != 0
              ? porEjercicio
              : a.numeroSerie.compareTo(b.numeroSerie);
        });

      for (final s in lista) {
        print('  ⏳ ─────────────────────────');
        print('     id          : ${s.id}');
        print('     diaId       : ${s.diaId}');
        print('     ejercicioId : ${s.ejercicioId}');
        print('     serie       : ${s.numeroSerie}');
        print('     reps        : ${s.reps ?? "— vacía"}');
        print('     fecha       : ${f(s.fecha)}');
      }
    }

    // ── Historial ──
    final logs = getLogsBox();
    print('\n📌 TABLA: GymSessionLog (${logs.length} registros)');

    if (logs.isEmpty) {
      print('  ❌ Sin historial');
    } else {
      final lista = logs.values.toList()
        ..sort((a, b) {
          final porFecha = a.fecha.compareTo(b.fecha);
          if (porFecha != 0) return porFecha;

          final porEjercicio = a.ejercicioId.compareTo(b.ejercicioId);
          return porEjercicio != 0
              ? porEjercicio
              : a.numeroSerie.compareTo(b.numeroSerie);
        });

      for (final l in lista) {
        print(
          '  ${l.deletedAt == null ? "📊" : "🗑"} '
          '─────────────────────────',
        );
        print('     id          : ${l.id}');
        print('     diaId       : ${l.diaId}');
        print('     ejercicio   : ${l.nombreSnapshot} (${l.ejercicioId})');
        print('     serie       : ${l.numeroSerie}/${l.seriesSnapshot}');
        print(
          '     reps        : ${l.reps ?? "— vacía"} '
          'de ${l.repsObjetivoSnapshot}',
        );
        print('     peso        : ${l.pesoSnapshot} ${l.unidadSnapshot}');
        print('     fecha       : ${f(l.fecha)}');
        print('     deletedAt   : ${f(l.deletedAt)}');
      }
    }

    print('\n==========================================\n');
  }
}
