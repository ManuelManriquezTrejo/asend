import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/stat.dart';

class StatAdapter extends TypeAdapter<Stat> {
  @override
  final int typeId = 28;

  @override
  Stat read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    final id = reader.readInt();
    final nombre = reader.readString();
    final esMana = reader.readBool();
    final orden = reader.readInt();

    final cuantosUmbrales = reader.readInt();
    final umbrales = <int>[
      for (var i = 0; i < cuantosUmbrales; i++) reader.readInt(),
    ];

    final mostrarBarra = reader.readBool();
    final mostrarRango = reader.readBool();
    final tipoBarra = reader.readString();
    final gastado = reader.readDouble();
    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return Stat(
      id: id,
      nombre: nombre,
      esMana: esMana,
      orden: orden,
      umbrales: umbrales,
      mostrarBarra: mostrarBarra,
      mostrarRango: mostrarRango,
      tipoBarra: tipoBarra,
      gastado: gastado,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, Stat obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.nombre);
    writer.writeBool(obj.esMana);
    writer.writeInt(obj.orden);

    writer.writeInt(obj.umbrales.length);
    for (final u in obj.umbrales) {
      writer.writeInt(u);
    }

    writer.writeBool(obj.mostrarBarra);
    writer.writeBool(obj.mostrarRango);
    writer.writeString(obj.tipoBarra);
    writer.writeDouble(obj.gastado);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}
