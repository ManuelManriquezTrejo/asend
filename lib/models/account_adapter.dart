import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/Account.dart';

class AccountAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = 0;

  @override
  Account read(BinaryReader reader) {
    return Account(
      id: reader.readInt(),
      name: reader.readString(),
      balance: reader.readDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt() * 1000),
      deletedAt: reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt() * 1000)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.name);
    writer.writeDouble(obj.balance);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch ~/ 1000);

    // Guardar si tiene deletedAt
    if (obj.deletedAt != null) {
      writer.writeBool(true);
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch ~/ 1000);
    } else {
      writer.writeBool(false);
    }
  }
}
