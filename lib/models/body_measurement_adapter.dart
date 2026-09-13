import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/body_measurement.dart';

class BodyMeasurementAdapter extends TypeAdapter<BodyMeasurement> {
  @override
  final int typeId = 5;

  @override
  BodyMeasurement read(BinaryReader reader) {
    final id = reader.readInt();
    final zonaId = reader.readInt();
    final valor = reader.readDouble();
    final unidadSnapshot = reader.readString();

    final fechaMs = reader.readInt();
    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return BodyMeasurement(
      id: id,
      zonaId: zonaId,
      valor: valor,
      unidadSnapshot: unidadSnapshot,
      fecha: DateTime.fromMillisecondsSinceEpoch(fechaMs),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, BodyMeasurement obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.zonaId);
    writer.writeDouble(obj.valor);
    writer.writeString(obj.unidadSnapshot);

    writer.writeInt(obj.fecha.millisecondsSinceEpoch);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}
