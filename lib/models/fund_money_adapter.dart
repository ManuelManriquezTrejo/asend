import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/fund_money.dart';

class FundMoneyAdapter extends TypeAdapter<FundMoney> {
  @override
  final int typeId = 27;

  @override
  FundMoney read(BinaryReader reader) {
    // Cada campo en su propia variable ANTES de construir el objeto.
    final id = reader.readInt();
    final fundId = reader.readInt();
    final moneyId = reader.readInt();
    final percentage = reader.readDouble();

    return FundMoney(
      id: id,
      fundId: fundId,
      moneyId: moneyId,
      percentage: percentage,
    );
  }

  @override
  void write(BinaryWriter writer, FundMoney obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.fundId);
    writer.writeInt(obj.moneyId);
    writer.writeDouble(obj.percentage);
  }
}