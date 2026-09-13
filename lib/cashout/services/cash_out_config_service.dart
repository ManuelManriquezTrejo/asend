import 'package:asend/models/cash_out_config.dart';
import 'package:asend/database/cash_out_hive_service.dart';

class CashOutConfigService {
  /// Devuelve la configuración, creándola si aún no existe.
  /// Solo hay un registro (clave 1) que persiste entre sesiones.
  static Future<CashOutConfig> getConfig() async {
    final box = CashOutHiveService.getConfigBox();
    final existente = box.get(1);
    if (existente != null) return existente;

    final nueva = CashOutConfig();
    await box.put(1, nueva);
    return nueva;
  }

  /// Versión sin await, para usar dentro de build().
  /// Devuelve null si aún no se ha creado.
  static CashOutConfig? getConfigSync() {
    return CashOutHiveService.getConfigBox().get(1);
  }

  static Future<void> setCuentaPaga(int accountId) async {
    final config = await getConfig();
    config.cuentaPagaId = accountId;
    await CashOutHiveService.getConfigBox().put(1, config);
  }

  static Future<void> setCuentaRecibe(int accountId) async {
    final config = await getConfig();
    config.cuentaRecibeId = accountId;
    await CashOutHiveService.getConfigBox().put(1, config);
  }
}
