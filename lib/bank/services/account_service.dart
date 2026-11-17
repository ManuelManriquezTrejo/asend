import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/models/account.dart';
import 'package:asend/models/account_history.dart';
import 'package:asend/database/hive_service.dart';

class AccountService {
  static const String boxName = 'accounts';

  // Agregar una nueva cuenta
  static Future<void> addAccount({
    required String name,
    required double balance,
  }) async {
    var box = Hive.box(boxName);

    // Buscar el ID más alto real, no depender de box.length.
    // Contar por longitud puede repetir IDs si alguna clave se libera.
    int newId = 1;
    for (final key in box.keys) {
      if (key is int && key >= newId) newId = key + 1;
    }

    Account account = Account(
      id: newId,
      name: name,
      balance: balance,
      createdAt: DateTime.now(),
    );

    await box.put(newId, account);
  }

  // Obtener todas las cuentas ACTIVAS (no eliminadas)
  static List<Account> getAllAccounts() {
    var box = Hive.box(boxName);

    // Iterar sobre los valores reales, no de 1 a length.
    // Si hubiera un hueco en los IDs, el bucle por índice
    // dejaría fuera las cuentas posteriores al hueco.
    final accounts = <Account>[];
    for (final value in box.values) {
      if (value is Account && value.deletedAt == null) {
        accounts.add(value);
      }
    }
    accounts.sort((a, b) => a.id.compareTo(b.id));
    return accounts;
  }

  // Obtener una cuenta por ID
  static Account? getAccountById(int id) {
    var box = Hive.box(boxName);
    Account? account = box.get(id);
    // Retornar solo si NO está eliminada
    if (account != null && account.deletedAt == null) {
      return account;
    }
    return null;
  }

    /// Cuenta por ID, incluyendo las eliminadas.
  /// Solo para mostrar: el historial de compras necesita el nombre
  /// de la cuenta aunque ya se haya borrado de Banco.
  /// Nunca usar esto para mover dinero.
  static Account? getAccountByIdIncluyendoEliminadas(int id) {
    var box = Hive.box(boxName);
    final value = box.get(id);
    return value is Account ? value : null;
  }

  /// Nombre de una cuenta para mostrar en pantalla.
  /// Devuelve "Cuenta eliminada" si el id ya no existe en la caja.
  static String getAccountName(int id) {
    return getAccountByIdIncluyendoEliminadas(id)?.name ?? 'Cuenta eliminada';
  }

  // Actualizar el saldo de una cuenta
  static Future<void> updateAccountBalance({
    required int accountId,
    required double newBalance,
  }) async {
    var box = Hive.box(boxName);
    Account? account = box.get(accountId);

    if (account != null) {
      account.balance = newBalance;
      await box.put(accountId, account);
    }
  }

  // Marcar una cuenta como eliminada (soft delete)
  static Future<void> deleteAccount(int accountId) async {
    var box = Hive.box(boxName);
    Account? account = box.get(accountId);

    if (account != null) {
      account.deletedAt = DateTime.now(); // ← Marca como eliminado
      await box.put(accountId, account);
    }
  }
  /// True si el saldo es 0. Los repartos por porcentaje pueden dejar
  /// fracciones menores a medio centavo, que en pantalla ya se ven
  /// como \$0.00; esas también cuentan como 0.
  static bool estaEnCero(Account cuenta) => cuenta.balance.abs() < 0.005;

  /// Elimina una cuenta solo si su saldo es 0, para que el dinero
  /// nunca desaparezca sin quedar en el historial.
  /// Devuelve null si salió bien, o el mensaje de error.
  static Future<String?> eliminarCuenta(int accountId) async {
    final cuenta = getAccountById(accountId);
    if (cuenta == null) return 'Esa cuenta ya no existe';

    if (!estaEnCero(cuenta)) {
      return 'Deja la cuenta en \$0 antes de eliminarla';
    }

    await deleteAccount(accountId);
    return null;
  }
  /// Mueve dinero en una cuenta y registra el movimiento.
  /// monto positivo = entra, negativo = sale.
  /// Devuelve false si no hay saldo suficiente (no modifica nada).
  static Future<bool> aplicarMovimiento({
    required int accountId,
    required double monto,
    required String concepto,
    int? referenciaId,
  }) async {
    final box = Hive.box(boxName);
    final Account? account = box.get(accountId);
    if (account == null || account.deletedAt != null) return false;

    final saldoAntes = account.balance;
    final saldoDespues = saldoAntes + monto;

    // No se permite dejar la cuenta en negativo
    if (saldoDespues < 0) return false;

    // El objeto solo se modifica después de pasar la validación de arriba.
    account.balance = saldoDespues;
    await box.put(accountId, account);

    // Registrar el movimiento para auditoría
    final histBox = HiveService.getAccountHistoryBox();
    int nextId = 1;
    for (final h in histBox.values) {
      if (h.id >= nextId) nextId = h.id + 1;
    }

    await histBox.add(
      AccountHistory(
        id: nextId,
        accountId: accountId,
        monto: monto,
        saldoAntes: saldoAntes,
        saldoDespues: saldoDespues,
        concepto: concepto,
        referenciaId: referenciaId,
        fecha: DateTime.now(),
      ),
    );

    return true;
  }
  /// Cambia el nombre de una cuenta. Los movimientos guardan solo el id
  /// de la cuenta, así que el historial muestra el nombre nuevo sin que
  /// cambie ningún monto. Devuelve null si salió bien, o el error.
  static Future<String?> renombrar({
    required int accountId,
    required String nombre,
  }) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return 'Escribe un nombre';

    final cuenta = getAccountById(accountId);
    if (cuenta == null) return 'Esa cuenta ya no existe';

    final repetido = getAllAccounts().any(
      (a) =>
          a.id != accountId &&
          a.name.trim().toLowerCase() == limpio.toLowerCase(),
    );
    if (repetido) return 'Ya existe una cuenta con ese nombre';

    cuenta.name = limpio;
    await Hive.box(boxName).put(accountId, cuenta);
    return null;
  }

  /// Mete dinero directo a una cuenta, sin pasar por un fondo.
  /// En el historial aparece como "Ingreso", con el concepto si se escribió.
  /// Devuelve null si salió bien, o el mensaje de error.
  static Future<String?> ingresar({
    required int accountId,
    required double monto,
    String? concepto,
  }) async {
    if (monto <= 0) return 'El monto debe ser mayor a 0';

    final cuenta = getAccountById(accountId);
    if (cuenta == null) return 'Esa cuenta ya no existe';

    final texto = concepto?.trim() ?? '';

    final ok = await aplicarMovimiento(
      accountId: accountId,
      monto: monto, // entra
      concepto: texto.isEmpty ? 'Ingreso' : 'Ingreso: $texto',
    );

    return ok ? null : 'No se pudo registrar el ingreso';
  }

  /// Pasa dinero de una cuenta a otra. Primero se descuenta del origen;
  /// si no alcanza el saldo, no se mueve nada. Solo si el descuento sale
  /// bien se abona al destino. Cada movimiento guarda en referenciaId
  /// la otra cuenta. Devuelve null si salió bien, o el mensaje de error.
  static Future<String?> transferir({
    required int origenId,
    required int destinoId,
    required double monto,
    String? concepto,
  }) async {
    if (monto <= 0) return 'El monto debe ser mayor a 0';
    if (origenId == destinoId) return 'Elige dos cuentas distintas';

    final origen = getAccountById(origenId);
    final destino = getAccountById(destinoId);
    if (origen == null || destino == null) {
      return 'Una de las cuentas ya no existe';
    }

    if (origen.balance < monto) {
      return 'Saldo insuficiente en ${origen.name}';
    }

    final texto = concepto?.trim() ?? '';
    final etiqueta = texto.isEmpty ? 'Transferencia' : 'Transferencia: $texto';

    // 1. Descontar del origen. Si falla, el destino no se toca.
    final salio = await aplicarMovimiento(
      accountId: origenId,
      monto: -monto, // sale
      concepto: etiqueta,
      referenciaId: destinoId,
    );
    if (!salio) return 'Saldo insuficiente en ${origen.name}';

    // 2. Abonar al destino. Ya se validó que existe, y un abono
    // positivo nunca deja la cuenta en negativo.
    await aplicarMovimiento(
      accountId: destinoId,
      monto: monto, // entra
      concepto: etiqueta,
      referenciaId: origenId,
    );

    return null;
  }
  /// Saca dinero de una cuenta desde el botón de retirar de Banco.
  /// El concepto es el que eligió el usuario de su lista.
  /// Devuelve null si salió bien, o el mensaje de error para la alerta.
  static Future<String?> retirar({
    required int accountId,
    required double monto,
    required String concepto,
  }) async {
    if (monto <= 0) return 'El monto debe ser mayor a 0';

    final cuenta = getAccountById(accountId);
    if (cuenta == null) return 'Esa cuenta ya no existe';

    final ok = await aplicarMovimiento(
      accountId: accountId,
      monto: -monto, // sale
      concepto: 'Retiro: $concepto',
    );

    if (!ok) return 'Saldo insuficiente en la cuenta';

    return null;
  }
}