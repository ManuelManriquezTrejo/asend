import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/money_account.dart';

class MoneyAccountAdapter extends TypeAdapter<MoneyAccount> {
  @override
  final int typeId = 24;

  @override
  MoneyAccount read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    // Leer dos veces dentro de una condicional desincroniza el stream.
    final id = reader.readInt();
    final name = reader.readString();
    final tipo = reader.readString();
    final balance = reader.readDouble();
    final seleccionada = reader.readBool();
    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return MoneyAccount(
      id: id,
      name: name,
      tipo: tipo,
      balance: balance,
      seleccionada: seleccionada,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, MoneyAccount obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.tipo);
    writer.writeDouble(obj.balance);
    writer.writeBool(obj.seleccionada);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}