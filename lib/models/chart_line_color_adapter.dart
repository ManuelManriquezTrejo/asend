import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/chart_line_color.dart';

class ChartLineColorAdapter extends TypeAdapter<ChartLineColor> {
  @override
  final int typeId = 20;

  @override
  ChartLineColor read(BinaryReader reader) {
    final id = reader.readInt();
    final clave = reader.readString();
    final color = reader.readInt();

    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return ChartLineColor(
      id: id,
      clave: clave,
      color: color,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, ChartLineColor obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.clave);
    writer.writeInt(obj.color);

    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}