import 'package:hive/hive.dart';
import 'cash_out.dart';

class CashOutAdapter extends TypeAdapter<CashOut> {
  @override
  final int typeId = 10;

  @override
  CashOut read(BinaryReader reader) {
    // Leer en el MISMO orden que write, una sola lectura por campo
    final id = reader.readInt();
    final fechaMs = reader.readInt();
    final nombre = reader.readString();
    final cantidad = reader.readInt();
    final origen = reader.readString();
    final pagado = reader.readBool();
    final pagadoAtMs = reader.readInt();
    final createdAtMs = reader.readInt();
    final deletedAtMs = reader.readInt();

    return CashOut(
      id: id,
      fecha: DateTime.fromMillisecondsSinceEpoch(fechaMs),
      nombre: nombre,
      cantidad: cantidad,
      origen: origen,
      pagado: pagado,
      pagadoAt: pagadoAtMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(pagadoAtMs),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: deletedAtMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deletedAtMs),
    );
  }

  @override
  void write(BinaryWriter writer, CashOut obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.fecha.millisecondsSinceEpoch);
    writer.writeString(obj.nombre);
    writer.writeInt(obj.cantidad);
    writer.writeString(obj.origen);
    writer.writeBool(obj.pagado);
    writer.writeInt(obj.pagadoAt?.millisecondsSinceEpoch ?? 0);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.deletedAt?.millisecondsSinceEpoch ?? 0);
  }
}
