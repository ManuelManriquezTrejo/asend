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

      print('✅ Misiones Hive inicializado');
    } catch (e) {
      print('❌ Error al inicializar Misiones Hive: $e');
    }
  }

  static Box<Mission> getMissionBox() => Hive.box<Mission>(missionBox);

  static Box<MissionHistory> getMissionHistoryBox() =>
      Hive.box<MissionHistory>(missionHistoryBox);

  /// Ver todos los datos de Misiones
  static void printAllData() {
    String f(DateTime? d) => d == null
        ? '—'
        : d.toIso8601String().split('.')[0].replaceFirst('T', ' ');

    print('\n\n========== 🗺 MISIONES - BASE DE DATOS ==========');

    final box = getMissionBox();
    print('\n📌 TABLA: Mission (${box.length} registros)');
    if (box.isEmpty) {
      print('  ❌ Sin misiones');
    } else {
      for (final m in box.values) {
        print(
          '  ${m.deletedAt == null ? "✓" : "🗑"} ─────────────────────────',
        );
        print('     id           : ${m.id}');
        print('     parentId     : ${m.parentId ?? "— (principal)"}');
        print('     nombre       : ${m.nombre}');
        print('     valor        : ${m.valor}');
        print('     fechaInicio  : ${f(m.fechaInicio)}');
        print('     fechaLimite  : ${f(m.fechaLimite)}');
        print('     completed    : ${m.completed}');
        print('     taken        : ${m.taken}');
        print('     createdAt    : ${f(m.createdAt)}');
        print('     deletedAt    : ${f(m.deletedAt)}');
      }
    }

    final histBox = getMissionHistoryBox();
    print('\n📜 TABLA: MissionHistory (${histBox.length} registros)');
    if (histBox.isEmpty) {
      print('  ❌ Sin registros');
    } else {
      for (final h in histBox.values) {
        print(
          '  ${h.deletedAt == null ? "✓" : "🗑"} ─────────────────────────',
        );
        print('     id            : ${h.id}');
        print('     missionId     : ${h.missionId}');
        print('     nombre        : ${h.nombre}');
        print('     valorSnapshot : ${h.valorSnapshot}');
        print('     completedAt   : ${f(h.completedAt)}');
        print('     deletedAt     : ${f(h.deletedAt)}');
      }
    }

    print('\n==========================================\n');
  }
}
