import 'package:hive/hive.dart';
import 'DailyRoutineHabit.dart';

class DailyRoutineHabitAdapter extends TypeAdapter<DailyRoutineHabit> {
  @override
  final int typeId = 6;

  @override
  DailyRoutineHabit read(BinaryReader reader) {
    // IMPORTANTE: leer en el MISMO orden en que se escribió,
    // una sola lectura por campo, guardada en variable.
    final id = reader.readInt();
    final nombre = reader.readString();
    final tipo = reader.readString();
    final valor = reader.readDouble();
    final prioridad = reader.readDouble();
    final createdAtMs = reader.readInt();
    final currentStreak = reader.readInt();
    final maxStreak = reader.readInt();
    final maxStreakStartMs = reader.readInt();
    final maxStreakEndMs = reader.readInt();
    final secondMaxStreak = reader.readInt();
    final minToKeepStreak = reader.readDouble();
    final deletedAtMs = reader.readInt();

    return DailyRoutineHabit(
      id: id,
      nombre: nombre,
      tipo: tipo,
      valor: valor,
      prioridad: prioridad,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      currentStreak: currentStreak,
      maxStreak: maxStreak,
      maxStreakStartDate: maxStreakStartMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(maxStreakStartMs),
      maxStreakEndDate: maxStreakEndMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(maxStreakEndMs),
      secondMaxStreak: secondMaxStreak,
      minToKeepStreak: minToKeepStreak,
      deletedAt: deletedAtMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deletedAtMs),
    );
  }

  @override
  void write(BinaryWriter writer, DailyRoutineHabit obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.nombre);
    writer.writeString(obj.tipo);
    writer.writeDouble(obj.valor);
    writer.writeDouble(obj.prioridad);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.currentStreak);
    writer.writeInt(obj.maxStreak);
    writer.writeInt(obj.maxStreakStartDate?.millisecondsSinceEpoch ?? 0);
    writer.writeInt(obj.maxStreakEndDate?.millisecondsSinceEpoch ?? 0);
    writer.writeInt(obj.secondMaxStreak);
    writer.writeDouble(obj.minToKeepStreak);
    writer.writeInt(obj.deletedAt?.millisecondsSinceEpoch ?? 0);
  }
}
