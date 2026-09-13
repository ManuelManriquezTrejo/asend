import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/birthday.dart';
import 'package:asend/models/birthday_adapter.dart';

class BirthdayHiveService {
  static const String birthdaysBox = 'birthdays';

  static Future<void> initializeBirthdayHive() async {
    try {
      Hive.registerAdapter(BirthdayAdapter());

      // 🧨 BORRAR DATOS - descomentar, correr UNA vez y volver a comentar
      // await Hive.deleteBoxFromDisk(birthdaysBox);

      await Hive.openBox<Birthday>(birthdaysBox);

      print('✅ Birthdays Hive inicializado');
    } catch (e) {
      print('❌ Error al inicializar Birthdays Hive: $e');
    }
  }

  static Box<Birthday> getBirthdaysBox() => Hive.box<Birthday>(birthdaysBox);

  /// Ver todos los datos de Cumpleaños
  static void printAllData() {
    String f(DateTime? d) => d == null
        ? '—'
        : d.toIso8601String().split('.')[0].replaceFirst('T', ' ');

    print('\n\n========== 🎂 CUMPLEAÑOS - BASE DE DATOS ==========');

    final box = getBirthdaysBox();
    print('\n📌 TABLA: Birthday (${box.length} registros)');

    if (box.isEmpty) {
      print('  ❌ Sin cumpleaños');
    } else {
      final cumples = box.values.toList()..sort((a, b) => a.id.compareTo(b.id));

      for (final b in cumples) {
        print(
          '  ${b.deletedAt == null ? "🎂" : "🗑"} '
          '─────────────────────────',
        );
        print('     id        : ${b.id}');
        print('     nombre    : ${b.nombre}');
        print(
          '     fecha     : ${b.dia.toString().padLeft(2, '0')}/'
          '${b.mes.toString().padLeft(2, '0')}',
        );
        print('     anio      : ${b.anio ?? "—"}');
        print('     nota      : ${b.nota ?? "—"}');
        print('     createdAt : ${f(b.createdAt)}');
        print('     deletedAt : ${f(b.deletedAt)}');
      }
    }

    print('\n==========================================\n');
  }
}
