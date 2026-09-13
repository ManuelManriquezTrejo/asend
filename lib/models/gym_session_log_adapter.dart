import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/gym_session_log.dart';

class GymSessionLogAdapter extends TypeAdapter<GymSessionLog> {
  @override
  final int typeId = 19;

  @override
  GymSessionLog read(BinaryReader reader) {
    final id = reader.readInt();
    final diaId = reader.readInt();
    final ejercicioId = reader.readInt();
    final nombreSnapshot = reader.readString();
    final numeroSerie = reader.readInt();

    final tieneReps = reader.readBool();
    final reps = tieneReps ? reader.readInt() : null;

    final pesoSnapshot = reader.readDouble();
    final unidadSnapshot = reader.readString();
    final seriesSnapshot = reader.readInt();
    final repsObjetivoSnapshot = reader.readInt();

    final fechaMs = reader.readInt();
    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return GymSessionLog(
      id: id,
      diaId: diaId,
      ejercicioId: ejercicioId,
      nombreSnapshot: nombreSnapshot,
      numeroSerie: numeroSerie,
      reps: reps,
      pesoSnapshot: pesoSnapshot,
      unidadSnapshot: unidadSnapshot,
      seriesSnapshot: seriesSnapshot,
      repsObjetivoSnapshot: repsObjetivoSnapshot,
      fecha: DateTime.fromMillisecondsSinceEpoch(fechaMs),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, GymSessionLog obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.diaId);
    writer.writeInt(obj.ejercicioId);
    writer.writeString(obj.nombreSnapshot);
    writer.writeInt(obj.numeroSerie);

    writer.writeBool(obj.reps != null);
    if (obj.reps != null) {
      writer.writeInt(obj.reps!);
    }

    writer.writeDouble(obj.pesoSnapshot);
    writer.writeString(obj.unidadSnapshot);
    writer.writeInt(obj.seriesSnapshot);
    writer.writeInt(obj.repsObjetivoSnapshot);

    writer.writeInt(obj.fecha.millisecondsSinceEpoch);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}
