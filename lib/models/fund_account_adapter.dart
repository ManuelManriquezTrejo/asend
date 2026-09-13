import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/fund_account.dart';

class FundAccountAdapter extends TypeAdapter<FundAccount> {
  @override
  final int typeId = 2; // ID único (Account=0, Fund=1, FundAccount=2)

  @override
  FundAccount read(BinaryReader reader) {
    return FundAccount(
      id: reader.readInt(),
      fundId: reader.readInt(),
      accountId: reader.readInt(),
      percentage: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, FundAccount obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.fundId);
    writer.writeInt(obj.accountId);
    writer.writeDouble(obj.percentage);
  }
}
