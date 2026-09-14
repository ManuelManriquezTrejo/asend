import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/purchase.dart';

class PurchaseAdapter extends TypeAdapter<Purchase> {
  @override
  final int typeId = 12;

  @override
  Purchase read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    // Leer dos veces dentro de una condicional desincroniza el stream.
    final id = reader.readInt();
    final nombre = reader.readString();
    final precio = reader.readInt();

    final tieneNota = reader.readBool();
    final nota = tieneNota ? reader.readString() : null;

    final accountId = reader.readInt();
    final fechaMs = reader.readInt();

    return Purchase(
      id: id,
      nombre: nombre,
      precio: precio,
      nota: nota,
      accountId: accountId,
      fecha: DateTime.fromMillisecondsSinceEpoch(fechaMs),
    );
  }

  @override
  void write(BinaryWriter writer, Purchase obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.nombre);
    writer.writeInt(obj.precio);

    writer.writeBool(obj.nota != null);
    if (obj.nota != null) {
      writer.writeString(obj.nota!);
    }

    writer.writeInt(obj.accountId);
    writer.writeInt(obj.fecha.millisecondsSinceEpoch);
  }
}