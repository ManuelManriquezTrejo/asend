import 'package:hive/hive.dart';
import 'HabitHistory.dart';

class HabitHistoryAdapter extends TypeAdapter<HabitHistory> {
  @override
  final int typeId = 7;

  @override
  HabitHistory read(BinaryReader reader) {
    final id = reader.readInt();
    final habitId = reader.readInt();
    final recordDateMs = reader.readInt();
    final recordedAtMs = reader.readInt();
    final value = reader.readDouble();
    final tipoSnapshot = reader.readString();
    final valorSnapshot = reader.readDouble();
    final deletedAtMs = reader.readInt();

    return HabitHistory(
      id: id,
      habitId: habitId,
      recordDate: DateTime.fromMillisecondsSinceEpoch(recordDateMs),
      recordedAt: DateTime.fromMillisecondsSinceEpoch(recordedAtMs),
      value: value,
      tipoSnapshot: tipoSnapshot,
      valorSnapshot: valorSnapshot,
      deletedAt: deletedAtMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deletedAtMs),
    );
  }

  @override
  void write(BinaryWriter writer, HabitHistory obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.habitId);
    writer.writeInt(obj.recordDate.millisecondsSinceEpoch);
    writer.writeInt(obj.recordedAt.millisecondsSinceEpoch);
    writer.writeDouble(obj.value);
    writer.writeString(obj.tipoSnapshot);
    writer.writeDouble(obj.valorSnapshot);
    writer.writeInt(obj.deletedAt?.millisecondsSinceEpoch ?? 0);
  }
}
