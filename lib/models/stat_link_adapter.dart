import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/stat_link.dart';

class StatLinkAdapter extends TypeAdapter<StatLink> {
  @override
  final int typeId = 29;

  @override
  StatLink read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    final id = reader.readInt();
    final habitId = reader.readInt();
    final statId = reader.readInt();
    final factor = reader.readDouble();
    final fechaVinculoMs = reader.readInt();

    final tieneFechaCambio = reader.readBool();
    final fechaCambioMs = tieneFechaCambio ? reader.readInt() : 0;

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return StatLink(
      id: id,
      habitId: habitId,
      statId: statId,
      factor: factor,
      fechaVinculo: DateTime.fromMillisecondsSinceEpoch(fechaVinculoMs),
      fechaCambio: tieneFechaCambio
          ? DateTime.fromMillisecondsSinceEpoch(fechaCambioMs)
          : null,
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, StatLink obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.habitId);
    writer.writeInt(obj.statId);
    writer.writeDouble(obj.factor);
    writer.writeInt(obj.fechaVinculo.millisecondsSinceEpoch);

    writer.writeBool(obj.fechaCambio != null);
    if (obj.fechaCambio != null) {
      writer.writeInt(obj.fechaCambio!.millisecondsSinceEpoch);
    }

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}
