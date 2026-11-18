import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/debt.dart';

class DebtAdapter extends TypeAdapter<Debt> {
  @override
  final int typeId = 22;

  @override
  Debt read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    // Leer dos veces dentro de una condicional desincroniza el stream.
    final id = reader.readInt();
    final nombre = reader.readString();
    final tipo = reader.readString();
    final monto = reader.readDouble();
    final diaPago = reader.readInt();
    final diasLimite = reader.readInt();
    final fechaInicioMs = reader.readInt();
    final meses = reader.readInt();
    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return Debt(
      id: id,
      nombre: nombre,
      tipo: tipo,
      monto: monto,
      diaPago: diaPago,
      diasLimite: diasLimite,
      fechaInicio: DateTime.fromMillisecondsSinceEpoch(fechaInicioMs),
      meses: meses,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, Debt obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.nombre);
    writer.writeString(obj.tipo);
    writer.writeDouble(obj.monto);
    writer.writeInt(obj.diaPago);
    writer.writeInt(obj.diasLimite);
    writer.writeInt(obj.fechaInicio.millisecondsSinceEpoch);
    writer.writeInt(obj.meses);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}