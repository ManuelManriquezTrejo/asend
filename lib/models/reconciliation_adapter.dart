import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/reconciliation.dart';

class ReconciliationAdapter extends TypeAdapter<Reconciliation> {
  @override
  final int typeId = 26;

  @override
  Reconciliation read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    final id = reader.readInt();
    final nombre = reader.readString();

    // Las listas se guardan como cantidad seguida de cada id
    final cuantasCuentas = reader.readInt();
    final accountIds = <int>[
      for (var i = 0; i < cuantasCuentas; i++) reader.readInt(),
    ];

    final cuantosDinero = reader.readInt();
    final moneyIds = <int>[
      for (var i = 0; i < cuantosDinero; i++) reader.readInt(),
    ];

    final createdAtMs = reader.readInt();

    final tieneDeletedAt = reader.readBool();
    final deletedAtMs = tieneDeletedAt ? reader.readInt() : 0;

    return Reconciliation(
      id: id,
      nombre: nombre,
      accountIds: accountIds,
      moneyIds: moneyIds,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      deletedAt: tieneDeletedAt
          ? DateTime.fromMillisecondsSinceEpoch(deletedAtMs)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, Reconciliation obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.nombre);

    writer.writeInt(obj.accountIds.length);
    for (final id in obj.accountIds) {
      writer.writeInt(id);
    }

    writer.writeInt(obj.moneyIds.length);
    for (final id in obj.moneyIds) {
      writer.writeInt(id);
    }

    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);

    writer.writeBool(obj.deletedAt != null);
    if (obj.deletedAt != null) {
      writer.writeInt(obj.deletedAt!.millisecondsSinceEpoch);
    }
  }
}