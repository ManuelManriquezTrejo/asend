import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/body_zone.dart';

class BodyZoneAdapter extends TypeAdapter<BodyZone> {
  @override
  final int typeId = 4;

  @override
  BodyZone read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    // Leer dos veces dentro de una condicional desincroniza el stream.
    final id = reader.readInt();
    final nombre = reader.readString();
    final unidad = reader.readString();
    final orden = reader.readInt();

    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return BodyZone(
      id: id,
      nombre: nombre,
      unidad: unidad,
      orden: orden,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, BodyZone obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.nombre);
    writer.writeString(obj.unidad);
    writer.writeInt(obj.orden);

    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}
