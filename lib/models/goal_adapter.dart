import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/goal.dart';

class GoalAdapter extends TypeAdapter<Goal> {
  @override
  final int typeId = 13;

  @override
  Goal read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    // Leer dos veces dentro de una condicional desincroniza el stream.
    final id = reader.readInt();
    final nombre = reader.readString();
    final saldo = reader.readInt();
    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return Goal(
      id: id,
      nombre: nombre,
      saldo: saldo,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.nombre);
    writer.writeInt(obj.saldo);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}
