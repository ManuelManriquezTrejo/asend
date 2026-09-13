import 'package:hive/hive.dart';
import 'mission.dart';

class MissionAdapter extends TypeAdapter<Mission> {
  @override
  final int typeId = 8;

  @override
  Mission read(BinaryReader reader) {
    // Leer en el MISMO orden que write, una sola lectura por campo
    final id = reader.readInt();
    final parentId = reader.readInt();
    final nombre = reader.readString();
    final valor = reader.readDouble();
    final fechaInicioMs = reader.readInt();
    final fechaLimiteMs = reader.readInt();
    final completed = reader.readBool();
    final taken = reader.readBool();
    final createdAtMs = reader.readInt();
    final deletedAtMs = reader.readInt();

    return Mission(
      id: id,
      parentId: parentId == -1 ? null : parentId,
      nombre: nombre,
      valor: valor,
      fechaInicio: fechaInicioMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(fechaInicioMs),
      fechaLimite: fechaLimiteMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(fechaLimiteMs),
      completed: completed,
      taken: taken,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: deletedAtMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deletedAtMs),
    );
  }

  @override
  void write(BinaryWriter writer, Mission obj) {
    writer.writeInt(obj.id);
    // -1 marca "sin padre", porque 0 podría ser un id válido
    writer.writeInt(obj.parentId ?? -1);
    writer.writeString(obj.nombre);
    writer.writeDouble(obj.valor);
    writer.writeInt(obj.fechaInicio?.millisecondsSinceEpoch ?? 0);
    writer.writeInt(obj.fechaLimite?.millisecondsSinceEpoch ?? 0);
    writer.writeBool(obj.completed);
    writer.writeBool(obj.taken);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.deletedAt?.millisecondsSinceEpoch ?? 0);
  }
}
