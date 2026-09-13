import 'package:hive/hive.dart';
import 'mission_history.dart';

class MissionHistoryAdapter extends TypeAdapter<MissionHistory> {
  @override
  final int typeId = 9;

  @override
  MissionHistory read(BinaryReader reader) {
    final id = reader.readInt();
    final missionId = reader.readInt();
    final nombre = reader.readString();
    final valorSnapshot = reader.readDouble();
    final completedAtMs = reader.readInt();
    final deletedAtMs = reader.readInt();

    return MissionHistory(
      id: id,
      missionId: missionId,
      nombre: nombre,
      valorSnapshot: valorSnapshot,
      completedAt: DateTime.fromMillisecondsSinceEpoch(completedAtMs),
      deletedAt: deletedAtMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deletedAtMs),
    );
  }

  @override
  void write(BinaryWriter writer, MissionHistory obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.missionId);
    writer.writeString(obj.nombre);
    writer.writeDouble(obj.valorSnapshot);
    writer.writeInt(obj.completedAt.millisecondsSinceEpoch);
    writer.writeInt(obj.deletedAt?.millisecondsSinceEpoch ?? 0);
  }
}
