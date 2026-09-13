import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/birthday.dart';

class BirthdayAdapter extends TypeAdapter<Birthday> {
  @override
  final int typeId = 14;

  @override
  Birthday read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    // Leer dos veces dentro de una condicional desincroniza el stream.
    final id = reader.readInt();
    final nombre = reader.readString();
    final dia = reader.readInt();
    final mes = reader.readInt();

    final tieneAnio = reader.readBool();
    final anio = tieneAnio ? reader.readInt() : null;

    final tieneNota = reader.readBool();
    final nota = tieneNota ? reader.readString() : null;

    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return Birthday(
      id: id,
      nombre: nombre,
      dia: dia,
      mes: mes,
      anio: anio,
      nota: nota,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, Birthday obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.nombre);
    writer.writeInt(obj.dia);
    writer.writeInt(obj.mes);

    writer.writeBool(obj.anio != null);
    if (obj.anio != null) {
      writer.writeInt(obj.anio!);
    }

    writer.writeBool(obj.nota != null);
    if (obj.nota != null) {
      writer.writeString(obj.nota!);
    }

    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}
