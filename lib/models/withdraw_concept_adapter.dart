import 'package:hive/hive.dart';
import 'package:asend/models/withdraw_concept.dart';

class WithdrawConceptAdapter extends TypeAdapter<WithdrawConcept> {
  @override
  final int typeId = 21;

  @override
  WithdrawConcept read(BinaryReader reader) {
    // Leer en el MISMO orden que write, una sola lectura por campo
    final id = reader.readInt();
    final nombre = reader.readString();
    final createdAtMs = reader.readInt();
    final deletedAtMs = reader.readInt();

    return WithdrawConcept(
      id: id,
      nombre: nombre,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: deletedAtMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deletedAtMs),
    );
  }

  @override
  void write(BinaryWriter writer, WithdrawConcept obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.nombre);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.deletedAt?.millisecondsSinceEpoch ?? 0);
  }
}