import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/skill.dart';

class SkillAdapter extends TypeAdapter<Skill> {
  @override
  final int typeId = 32;

  @override
  Skill read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    final id = reader.readInt();
    final nombre = reader.readString();

    final tieneMagia = reader.readBool();
    final magicId = tieneMagia ? reader.readInt() : 0;

    final tipo = reader.readString();
    final nota = reader.readString();

    // Cada nivel se guarda como rango, descripción y mana
    final cuantosNiveles = reader.readInt();
    final niveles = <SkillLevel>[];
    for (var i = 0; i < cuantosNiveles; i++) {
      final rango = reader.readInt();
      final descripcion = reader.readString();
      final mana = reader.readString();
      niveles.add(SkillLevel(rango: rango, descripcion: descripcion, mana: mana));
    }

    final orden = reader.readInt();
    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return Skill(
      id: id,
      nombre: nombre,
      magicId: tieneMagia ? magicId : null,
      tipo: tipo,
      nota: nota,
      niveles: niveles,
      orden: orden,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, Skill obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.nombre);

    writer.writeBool(obj.magicId != null);
    if (obj.magicId != null) {
      writer.writeInt(obj.magicId!);
    }

    writer.writeString(obj.tipo);
    writer.writeString(obj.nota);

    writer.writeInt(obj.niveles.length);
    for (final n in obj.niveles) {
      writer.writeInt(n.rango);
      writer.writeString(n.descripcion);
      writer.writeString(n.mana);
    }

    writer.writeInt(obj.orden);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}
