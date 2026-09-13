import 'package:hive/hive.dart';
import 'cash_out_config.dart';

class CashOutConfigAdapter extends TypeAdapter<CashOutConfig> {
  @override
  final int typeId = 11;

  @override
  CashOutConfig read(BinaryReader reader) {
    final id = reader.readInt();
    final pagaId = reader.readInt();
    final recibeId = reader.readInt();

    return CashOutConfig(
      id: id,
      // -1 marca "sin seleccionar", porque 0 podría ser un id válido
      cuentaPagaId: pagaId == -1 ? null : pagaId,
      cuentaRecibeId: recibeId == -1 ? null : recibeId,
    );
  }

  @override
  void write(BinaryWriter writer, CashOutConfig obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.cuentaPagaId ?? -1);
    writer.writeInt(obj.cuentaRecibeId ?? -1);
  }
}
