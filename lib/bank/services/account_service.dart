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
}
