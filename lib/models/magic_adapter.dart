import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/magic.dart';

class MagicAdapter extends TypeAdapter<Magic> {
  @override
  final int typeId = 31;

  @override
  Magic read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    final id = reader.readInt();
    final nombre = reader.readString();
    final plantilla = reader.readString();
    final puntos = reader.readInt();

    final cuantosUmbrales = reader.readInt();
    final umbrales = <int>[
      for (var i = 0; i < cuantosUmbrales; i++) reader.readInt(),
    ];

    final orden = reader.readInt();
    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return Magic(
      id: id,
      nombre: nombre,
      plantilla: plantilla,
      puntos: puntos,
      umbrales: umbrales,
      orden: orden,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, Magic obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.nombre);
    writer.writeString(obj.plantilla);
    writer.writeInt(obj.puntos);

    writer.writeInt(obj.umbrales.length);
    for (final u in obj.umbrales) {
      writer.writeInt(u);
    }

    writer.writeInt(obj.orden);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}
