import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/exercise_change.dart';

class ExerciseChangeAdapter extends TypeAdapter<ExerciseChange> {
  @override
  final int typeId = 17;

  @override
  ExerciseChange read(BinaryReader reader) {
    final id = reader.readInt();
    final ejercicioId = reader.readInt();
    final peso = reader.readDouble();
    final unidadPeso = reader.readString();
    final series = reader.readInt();
    final reps = reader.readInt();

    final fechaMs = reader.readInt();
    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return ExerciseChange(
      id: id,
      ejercicioId: ejercicioId,
      peso: peso,
      unidadPeso: unidadPeso,
      series: series,
      reps: reps,
      fecha: DateTime.fromMillisecondsSinceEpoch(fechaMs),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseChange obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.ejercicioId);
    writer.writeDouble(obj.peso);
    writer.writeString(obj.unidadPeso);
    writer.writeInt(obj.series);
    writer.writeInt(obj.reps);

    writer.writeInt(obj.fecha.millisecondsSinceEpoch);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}
