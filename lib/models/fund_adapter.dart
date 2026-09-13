import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/Fund.dart';

class FundAdapter extends TypeAdapter<Fund> {
  @override
  final int typeId = 1;

  @override
  Fund read(BinaryReader reader) {
    return Fund(
      id: reader.readInt(),
      name: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt() * 1000),
      deletedAt: reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt() * 1000)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, Fund obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.name);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch ~/ 1000);

    if (obj.deletedAt != null) {
      writer.writeBool(true);
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch ~/ 1000);
    } else {
      writer.writeBool(false);
    }
  }
}
