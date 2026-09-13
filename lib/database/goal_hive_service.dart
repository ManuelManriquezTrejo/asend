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

      print('✅ Goals Hive inicializado');
    } catch (e) {
      print('❌ Error al inicializar Goals Hive: $e');
    }
  }

  static Box<Goal> getGoalsBox() => Hive.box<Goal>(goalsBox);

  /// Ver todos los datos de Metas
  static void printAllData() {
    String f(DateTime? d) => d == null
        ? '—'
        : d.toIso8601String().split('.')[0].replaceFirst('T', ' ');

    print('\n\n========== 🎯 METAS - BASE DE DATOS ==========');

    final box = getGoalsBox();
    print('\n📌 TABLA: Goal (${box.length} registros)');

    if (box.isEmpty) {
      print('  ❌ Sin metas');
    } else {
      final metas = box.values.toList()..sort((a, b) => a.id.compareTo(b.id));

      int totalApartado = 0;
      for (final g in metas) {
        print(
          '  ${g.deletedAt == null ? "🎯" : "🗑"} '
          '─────────────────────────',
        );
        print('     id        : ${g.id}');
        print('     nombre    : ${g.nombre}');
        print('     saldo     : ${g.saldo}');
        print('     createdAt : ${f(g.createdAt)}');
        print('     deletedAt : ${f(g.deletedAt)}');

        if (g.deletedAt == null) {
          totalApartado += g.saldo;
        }
      }
      print('\n  💰 TOTAL APARTADO EN METAS: $totalApartado');
    }

    print('\n==========================================\n');
  }
}
