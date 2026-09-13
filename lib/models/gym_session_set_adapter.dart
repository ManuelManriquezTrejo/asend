import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/gym_session_set.dart';

class GymSessionSetAdapter extends TypeAdapter<GymSessionSet> {
  @override
  final int typeId = 18;

  @override
  GymSessionSet read(BinaryReader reader) {
    final id = reader.readInt();
    final diaId = reader.readInt();
    final ejercicioId = reader.readInt();
    final numeroSerie = reader.readInt();

    // null = casilla todavía sin llenar
    final tieneReps = reader.readBool();
    final reps = tieneReps ? reader.readInt() : null;

    final fechaMs = reader.readInt();
    final createdAtMs = reader.readInt();

    return GymSessionSet(
      id: id,
      diaId: diaId,
      ejercicioId: ejercicioId,
      numeroSerie: numeroSerie,
      reps: reps,
      fecha: DateTime.fromMillisecondsSinceEpoch(fechaMs),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }

  @override
  void write(BinaryWriter writer, GymSessionSet obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.diaId);
    writer.writeInt(obj.ejercicioId);
    writer.writeInt(obj.numeroSerie);

    writer.writeBool(obj.reps != null);
    if (obj.reps != null) {
      writer.writeInt(obj.reps!);
    }

    writer.writeInt(obj.fecha.millisecondsSinceEpoch);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
