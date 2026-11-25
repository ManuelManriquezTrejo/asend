import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/stat_point.dart';

class StatPointAdapter extends TypeAdapter<StatPoint> {
  @override
  final int typeId = 30;

  @override
  StatPoint read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    final id = reader.readInt();
    final statId = reader.readInt();
    final fechaMs = reader.readInt();
    final puntos = reader.readInt();
    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return StatPoint(
      id: id,
      statId: statId,
      fecha: DateTime.fromMillisecondsSinceEpoch(fechaMs),
      puntos: puntos,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, StatPoint obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.statId);
    writer.writeInt(obj.fecha.millisecondsSinceEpoch);
    writer.writeInt(obj.puntos);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}
