import 'package:asend/bank/services/account_service.dart';
import 'package:asend/bank/services/money_service.dart';
import 'package:asend/database/money_hive_service.dart';
import 'package:asend/models/reconciliation.dart';

/// Lógica de los cuadres: cada uno suma unas cuentas y unos elementos
/// de Dinero, y avisa si no son iguales.
///
/// Diferencia = Dinero − Cuentas:
/// - positiva: el Dinero tiene más (verde)
/// - negativa: las Cuentas tienen más (rojo)
///
/// Las cuentas o elementos que se eliminen después de crear el cuadre
/// simplemente dejan de sumar. Para eliminarlos debían estar en 0,
/// así que no cambian el resultado.
///
/// Los métodos que pueden fallar devuelven null si salió bien, o el
/// mensaje de error para mostrar.
class ReconciliationService {
  // ── Consultas ──────────────────────────────────────────

  /// Todos los activos, en orden alfabético.
  static List<Reconciliation> getAll() {
    final lista = MoneyHiveService.getReconciliationsBox().values
        .where((c) => c.deletedAt == null)
        .toList();
    lista.sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );
    return lista;
  }

  static Reconciliation? getById(int id) {
    final c = MoneyHiveService.getReconciliationsBox().get(id);
    return (c != null && c.deletedAt == null) ? c : null;
  }

  /// Suma de las cuentas del cuadre que siguen activas.
  static double totalCuentas(Reconciliation c) {
    double total = 0;
    for (final id in c.accountIds) {
      total += AccountService.getAccountById(id)?.balance ?? 0;
    }
    return total;
  }

  /// Suma de los elementos de Dinero del cuadre que siguen activos.
  static double totalDinero(Reconciliation c) {
    double total = 0;
    for (final id in c.moneyIds) {
      total += MoneyService.getById(id)?.balance ?? 0;
    }
    return total;
  }

  /// Dinero − Cuentas. Positiva = el Dinero tiene más.
  static double diferencia(Reconciliation c) =>
      totalDinero(c) - totalCuentas(c);

  /// True si la diferencia llega a medio centavo o más. Lo que queda
  /// abajo son fracciones de los repartos por porcentaje.
  static bool tieneDiferencia(Reconciliation c) =>
      diferencia(c).abs() >= 0.005;

  /// True si hay que encender los puntos rojos: el aviso está activo
  /// en Configuración y algún cuadre no cuadra.
  static bool hayDiferencias() =>
      avisosActivos() && getAll().any(tieneDiferencia);

  // ── Aviso en Configuración ─────────────────────────────

  /// Clave en money_settings del interruptor "Diferencias en Banco".
  static const String _claveAviso = 'avisoDiferencias';

  /// Si se muestran los puntos rojos por diferencias. Activo por defecto.
  static bool avisosActivos() =>
      MoneyHiveService.getSettingsBox().get(_claveAviso, defaultValue: true)
          as bool;

  static Future<void> setAvisosActivos(bool activo) async {
    await MoneyHiveService.getSettingsBox().put(_claveAviso, activo);
  }

  // ── Crear, editar y eliminar ───────────────────────────

  static String? _validar({
    required String nombre,
    required List<int> accountIds,
    required List<int> moneyIds,
    int? excepto,
  }) {
    if (nombre.isEmpty) return 'Escribe un nombre';
    if (accountIds.isEmpty) return 'Elige al menos una cuenta';
    if (moneyIds.isEmpty) return 'Elige al menos un elemento de Dinero';

    final repetido = getAll().any(
      (c) =>
          c.id != excepto && c.nombre.toLowerCase() == nombre.toLowerCase(),
    );
    return repetido ? 'Ya existe un cuadre con ese nombre' : null;
  }

  static Future<String?> crear({
    required String nombre,
    required List<int> accountIds,
    required List<int> moneyIds,
  }) async {
    final limpio = nombre.trim();
    final error = _validar(
      nombre: limpio,
      accountIds: accountIds,
      moneyIds: moneyIds,
    );
    if (error != null) return error;

    final box = MoneyHiveService.getReconciliationsBox();
    int newId = 1;
    for (final key in box.keys) {
      if (key is int && key >= newId) newId = key + 1;
    }

    await box.put(
      newId,
      Reconciliation(
        id: newId,
        nombre: limpio,
        accountIds: List.of(accountIds),
        moneyIds: List.of(moneyIds),
        createdAt: DateTime.now(),
      ),
    );
    return null;
  }

  static Future<String?> editar({
    required int id,
    required String nombre,
    required List<int> accountIds,
    required List<int> moneyIds,
  }) async {
    final c = getById(id);
    if (c == null) return 'Ese cuadre ya no existe';

    final limpio = nombre.trim();
    final error = _validar(
      nombre: limpio,
      accountIds: accountIds,
      moneyIds: moneyIds,
      excepto: id,
    );
    if (error != null) return error;

    c.nombre = limpio;
    c.accountIds = List.of(accountIds);
    c.moneyIds = List.of(moneyIds);
    await MoneyHiveService.getReconciliationsBox().put(id, c);
    return null;
  }

  /// Soft delete. No mueve dinero: un cuadre solo compara.
  static Future<void> eliminar(int id) async {
    final c = getById(id);
    if (c == null) return;
    c.deletedAt = DateTime.now();
    await MoneyHiveService.getReconciliationsBox().put(id, c);
  }
}