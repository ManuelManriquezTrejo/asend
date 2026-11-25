import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/mission_magic_point.dart';

class MissionMagicPointAdapter extends TypeAdapter<MissionMagicPoint> {
  @override
  final int typeId = 33;

  @override
  MissionMagicPoint read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    final id = reader.readInt();
    final missionId = reader.readInt();
    final nombre = reader.readString();
    final puntos = reader.readInt();
    final fechaMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return MissionMagicPoint(
      id: id,
      missionId: missionId,
      nombre: nombre,
      puntos: puntos,
      fecha: DateTime.fromMillisecondsSinceEpoch(fechaMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, MissionMagicPoint obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.missionId);
    writer.writeString(obj.nombre);
    writer.writeInt(obj.puntos);
    writer.writeInt(obj.fecha.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}
