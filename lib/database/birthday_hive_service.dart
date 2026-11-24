import 'package:flutter/foundation.dart';
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
    } catch (e) {
      debugPrint('❌ Error al inicializar Birthdays Hive: $e');
    }
  }

  static Box<Birthday> getBirthdaysBox() => Hive.box<Birthday>(birthdaysBox);
}