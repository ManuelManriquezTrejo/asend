import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/gym_exercise.dart';

class GymExerciseAdapter extends TypeAdapter<GymExercise> {
  @override
  final int typeId = 16;

  @override
  GymExercise read(BinaryReader reader) {
    final id = reader.readInt();
    final diaId = reader.readInt();
    final nombre = reader.readString();
    final peso = reader.readDouble();
    final unidadPeso = reader.readString();
    final series = reader.readInt();
    final reps = reader.readInt();
    final orden = reader.readInt();

    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return GymExercise(
      id: id,
      diaId: diaId,
      nombre: nombre,
      peso: peso,
      unidadPeso: unidadPeso,
      series: series,
      reps: reps,
      orden: orden,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, GymExercise obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.diaId);
    writer.writeString(obj.nombre);
    writer.writeDouble(obj.peso);
    writer.writeString(obj.unidadPeso);
    writer.writeInt(obj.series);
    writer.writeInt(obj.reps);
    writer.writeInt(obj.orden);

    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}
