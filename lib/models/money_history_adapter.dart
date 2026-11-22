import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/money_history.dart';

class MoneyHistoryAdapter extends TypeAdapter<MoneyHistory> {
  @override
  final int typeId = 25;

  @override
  MoneyHistory read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    final id = reader.readInt();
    final moneyId = reader.readInt();
    final monto = reader.readDouble();
    final saldoAntes = reader.readDouble();
    final saldoDespues = reader.readDouble();
    final concepto = reader.readString();

    final tieneReferencia = reader.readBool();
    final referenciaId = tieneReferencia ? reader.readInt() : null;

    final fechaMs = reader.readInt();

    return MoneyHistory(
      id: id,
      moneyId: moneyId,
      monto: monto,
      saldoAntes: saldoAntes,
      saldoDespues: saldoDespues,
      concepto: concepto,
      referenciaId: referenciaId,
      fecha: DateTime.fromMillisecondsSinceEpoch(fechaMs),
    );
  }

  @override
  void write(BinaryWriter writer, MoneyHistory obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.moneyId);
    writer.writeDouble(obj.monto);
    writer.writeDouble(obj.saldoAntes);
    writer.writeDouble(obj.saldoDespues);
    writer.writeString(obj.concepto);

    writer.writeBool(obj.referenciaId != null);
    if (obj.referenciaId != null) writer.writeInt(obj.referenciaId!);

    writer.writeInt(obj.fecha.millisecondsSinceEpoch);
  }
}