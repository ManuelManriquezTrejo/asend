import 'package:hive/hive.dart';
import 'package:asend/models/account_history.dart';
class AccountHistoryAdapter extends TypeAdapter<AccountHistory> {
  @override
  final int typeId = 3;

  @override
  AccountHistory read(BinaryReader reader) {
    // Leer en el MISMO orden que write, una sola lectura por campo
    final id = reader.readInt();
    final accountId = reader.readInt();
    final monto = reader.readDouble();
    final saldoAntes = reader.readDouble();
    final saldoDespues = reader.readDouble();
    final concepto = reader.readString();
    final referenciaId = reader.readInt();
    final fechaMs = reader.readInt();
    final deletedAtMs = reader.readInt();

    return AccountHistory(
      id: id,
      accountId: accountId,
      monto: monto,
      saldoAntes: saldoAntes,
      saldoDespues: saldoDespues,
      concepto: concepto,
      // -1 marca "sin referencia", porque 0 podría ser un id válido
      referenciaId: referenciaId == -1 ? null : referenciaId,
      fecha: DateTime.fromMillisecondsSinceEpoch(fechaMs),
      deletedAt: deletedAtMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deletedAtMs),
    );
  }

  @override
  void write(BinaryWriter writer, AccountHistory obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.accountId);
    writer.writeDouble(obj.monto);
    writer.writeDouble(obj.saldoAntes);
    writer.writeDouble(obj.saldoDespues);
    writer.writeString(obj.concepto);
    writer.writeInt(obj.referenciaId ?? -1);
    writer.writeInt(obj.fecha.millisecondsSinceEpoch);
    writer.writeInt(obj.deletedAt?.millisecondsSinceEpoch ?? 0);
  }
}
