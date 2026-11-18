import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/debt_installment.dart';

class DebtInstallmentAdapter extends TypeAdapter<DebtInstallment> {
  @override
  final int typeId = 23;

  @override
  DebtInstallment read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    // Leer dos veces dentro de una condicional desincroniza el stream.
    final id = reader.readInt();
    final debtId = reader.readInt();
    final numero = reader.readInt();
    final monto = reader.readDouble();
    final fechaPagoMs = reader.readInt();
    final fechaLimiteMs = reader.readInt();

    final tienePagadoAt = reader.readBool();
    final pagadoAtMs = tienePagadoAt ? reader.readInt() : 0;

    final tieneAccountId = reader.readBool();
    final accountId = tieneAccountId ? reader.readInt() : null;

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return DebtInstallment(
      id: id,
      debtId: debtId,
      numero: numero,
      monto: monto,
      fechaPago: DateTime.fromMillisecondsSinceEpoch(fechaPagoMs),
      fechaLimite: DateTime.fromMillisecondsSinceEpoch(fechaLimiteMs),
      pagadoAt: tienePagadoAt
          ? DateTime.fromMillisecondsSinceEpoch(pagadoAtMs)
          : null,
      accountId: accountId,
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, DebtInstallment obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.debtId);
    writer.writeInt(obj.numero);
    writer.writeDouble(obj.monto);
    writer.writeInt(obj.fechaPago.millisecondsSinceEpoch);
    writer.writeInt(obj.fechaLimite.millisecondsSinceEpoch);

    writer.writeBool(obj.pagadoAt != null);
    if (obj.pagadoAt != null) {
      writer.writeInt(obj.pagadoAt!.millisecondsSinceEpoch);
    }

    writer.writeBool(obj.accountId != null);
    if (obj.accountId != null) {
      writer.writeInt(obj.accountId!);
    }

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}