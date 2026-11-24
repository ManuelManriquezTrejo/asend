import 'package:asend/database/money_hive_service.dart';
import 'package:asend/models/money_account.dart';
import 'package:asend/models/money_history.dart';

/// Lógica de la tarjeta Dinero de Banco: los lugares reales donde está
/// el dinero (cartera, BBVA, Nu...). Todo movimiento de saldo pasa por
/// [aplicarMovimiento] para que quede en MoneyHistory.
///
/// Los métodos que pueden fallar devuelven null si salió bien, o el
/// mensaje de error para mostrar.
class MoneyService {
  static const String efectivo = 'efectivo';
  static const String digital = 'digital';

  // ── Consultas ──────────────────────────────────────────

  /// Quita acentos y pasa a minúsculas para ordenar alfabéticamente.
  static String _claveOrden(String texto) {
    const conAcento = 'áéíóúüñ';
    const sinAcento = 'aeiouun';
    final buffer = StringBuffer();
    for (final letra in texto.toLowerCase().split('')) {
      final i = conAcento.indexOf(letra);
      buffer.write(i == -1 ? letra : sinAcento[i]);
    }
    return buffer.toString();
  }

  /// Todos los activos, en orden alfabético.
  static List<MoneyAccount> getAll() {
    final lista = MoneyHiveService.getAccountsBox().values
        .where((m) => m.deletedAt == null)
        .toList();
    lista.sort((a, b) => _claveOrden(a.name).compareTo(_claveOrden(b.name)));
    return lista;
  }

  /// Uno por id, solo si está activo.
  static MoneyAccount? getById(int id) {
    final m = MoneyHiveService.getAccountsBox().get(id);
    return (m != null && m.deletedAt == null) ? m : null;
  }
  /// Uno por id, aunque esté eliminado. Solo para mostrar, por ejemplo
  /// el método de una compra vieja. Nunca usar para mover dinero.
  static MoneyAccount? getByIdIncluyendoEliminados(int id) {
    return MoneyHiveService.getAccountsBox().get(id);
  }
  /// Nombre para mostrar, aunque ya esté eliminado.
  /// Nunca usar para mover dinero.
  static String getName(int id) {
    return MoneyHiveService.getAccountsBox().get(id)?.name ??
        'Dinero eliminado';
  }

  /// Suma de los marcados para el total de Banco.
  static double totalSeleccionado() {
    return getAll()
        .where((m) => m.seleccionada)
        .fold<double>(0, (s, m) => s + m.balance);
  }

  /// Suma de los marcados de un tipo ('efectivo' o 'digital').
  static double totalSeleccionadoDeTipo(String tipo) {
    return getAll()
        .where((m) => m.seleccionada && m.tipo == tipo)
        .fold<double>(0, (s, m) => s + m.balance);
  }

  /// True si el saldo es 0, ignorando fracciones menores a medio
  /// centavo que dejan los repartos por porcentaje.
  static bool estaEnCero(MoneyAccount m) => m.balance.abs() < 0.005;

  // ── Último usado ───────────────────────────────────────

  /// Lugares que recuerdan su propio último Dinero usado.
  static const String enTienda = 'tienda';
  static const String enPagoDeuda = 'pagoDeuda';

  /// El último Dinero usado en [donde], si sigue activo. Si no hay o
  /// ya no existe, el primero de la lista. null si no hay ninguno.
  static int? getUltimoId(String donde) {
    final id = MoneyHiveService.getSettingsBox().get('ultimoMoneyId_$donde');
    if (id is int && getById(id) != null) return id;

    final todos = getAll();
    return todos.isEmpty ? null : todos.first.id;
  }

  static Future<void> setUltimoId(String donde, int id) async {
    await MoneyHiveService.getSettingsBox().put('ultimoMoneyId_$donde', id);
  }
  // ── Movimiento base ────────────────────────────────────

  /// Mueve dinero y lo registra en MoneyHistory.
  /// monto positivo = entra, negativo = sale.
  /// Devuelve false si no existe o si quedaría en negativo (no modifica nada).
  static Future<bool> aplicarMovimiento({
    required int moneyId,
    required double monto,
    required String concepto,
    int? referenciaId,
  }) async {
    final box = MoneyHiveService.getAccountsBox();
    final m = box.get(moneyId);
    if (m == null || m.deletedAt != null) return false;

    final saldoAntes = m.balance;
    final saldoDespues = saldoAntes + monto;

    // Medio centavo de margen por los decimales de los repartos
    if (saldoDespues < -0.005) return false;

    m.balance = saldoDespues;
    await box.put(moneyId, m);

    final histBox = MoneyHiveService.getHistoryBox();
    int nextId = 1;
    for (final h in histBox.values) {
      if (h.id >= nextId) nextId = h.id + 1;
    }

    await histBox.put(
      nextId,
      MoneyHistory(
        id: nextId,
        moneyId: moneyId,
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

  // ── Crear y editar ─────────────────────────────────────

  static String? _validarNombre(String limpio, {int? excepto}) {
    if (limpio.isEmpty) return 'Escribe un nombre';
    final repetido = getAll().any(
      (m) =>
          m.id != excepto &&
          m.name.trim().toLowerCase() == limpio.toLowerCase(),
    );
    return repetido ? 'Ya existe uno con ese nombre' : null;
  }

  /// Crea uno nuevo. Si trae saldo inicial, entra como movimiento
  /// "Saldo inicial" para que también quede en el historial.
  static Future<String?> crear({
    required String nombre,
    required String tipo,
    double saldoInicial = 0,
  }) async {
    final limpio = nombre.trim();
    final error = _validarNombre(limpio);
    if (error != null) return error;
    if (saldoInicial < 0) return 'El saldo no puede ser negativo';

    final box = MoneyHiveService.getAccountsBox();
    int newId = 1;
    for (final key in box.keys) {
      if (key is int && key >= newId) newId = key + 1;
    }

    await box.put(
      newId,
      MoneyAccount(
        id: newId,
        name: limpio,
        tipo: tipo,
        balance: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (saldoInicial > 0) {
      await aplicarMovimiento(
        moneyId: newId,
        monto: saldoInicial,
        concepto: 'Saldo inicial',
      );
    }
    return null;
  }

  /// Cambia nombre y tipo. No toca el saldo.
  static Future<String?> editar({
    required int moneyId,
    required String nombre,
    required String tipo,
  }) async {
    final m = getById(moneyId);
    if (m == null) return 'Ya no existe';

    final limpio = nombre.trim();
    final error = _validarNombre(limpio, excepto: moneyId);
    if (error != null) return error;

    m.name = limpio;
    m.tipo = tipo;
    await MoneyHiveService.getAccountsBox().put(moneyId, m);
    return null;
  }

  /// Marca o desmarca si entra en el total de Banco.
  static Future<void> alternarSeleccion(int moneyId) async {
    final m = getById(moneyId);
    if (m == null) return;
    m.seleccionada = !m.seleccionada;
    await MoneyHiveService.getAccountsBox().put(moneyId, m);
  }

  /// Soft delete, solo con saldo 0 para que el dinero nunca
  /// desaparezca sin quedar en el historial.
  static Future<String?> eliminar(int moneyId) async {
    final m = getById(moneyId);
    if (m == null) return 'Ya no existe';
    if (!estaEnCero(m)) return 'Déjalo en \$0 antes de eliminarlo';

    m.deletedAt = DateTime.now();
    await MoneyHiveService.getAccountsBox().put(moneyId, m);
    return null;
  }

  // ── Ingreso, retiro y transferencia ────────────────────

  static String _etiqueta(String base, String? concepto) {
    final texto = concepto?.trim() ?? '';
    return texto.isEmpty ? base : '$base: $texto';
  }

  static Future<String?> ingresar({
    required int moneyId,
    required double monto,
    String? concepto,
  }) async {
    if (monto <= 0) return 'El monto debe ser mayor a 0';
    if (getById(moneyId) == null) return 'Ya no existe';

    final ok = await aplicarMovimiento(
      moneyId: moneyId,
      monto: monto, // entra
      concepto: _etiqueta('Ingreso', concepto),
    );
    return ok ? null : 'No se pudo registrar el ingreso';
  }

  static Future<String?> retirar({
    required int moneyId,
    required double monto,
    String? concepto,
  }) async {
    if (monto <= 0) return 'El monto debe ser mayor a 0';
    final m = getById(moneyId);
    if (m == null) return 'Ya no existe';

    final ok = await aplicarMovimiento(
      moneyId: moneyId,
      monto: -monto, // sale
      concepto: _etiqueta('Retiro', concepto),
    );
    return ok ? null : 'Saldo insuficiente en ${m.name}';
  }

  /// Pasa dinero de uno a otro. Primero sale del origen; si no alcanza,
  /// no se mueve nada. Cada movimiento guarda en referenciaId el otro.
  static Future<String?> transferir({
    required int origenId,
    required int destinoId,
    required double monto,
    String? concepto,
  }) async {
    if (monto <= 0) return 'El monto debe ser mayor a 0';
    if (origenId == destinoId) return 'Elige dos distintos';

    final origen = getById(origenId);
    final destino = getById(destinoId);
    if (origen == null || destino == null) return 'Uno de los dos ya no existe';

    final etiqueta = _etiqueta('Transferencia', concepto);

    // 1. Sale del origen. Si falla, el destino no se toca.
    final salio = await aplicarMovimiento(
      moneyId: origenId,
      monto: -monto,
      concepto: etiqueta,
      referenciaId: destinoId,
    );
    if (!salio) return 'Saldo insuficiente en ${origen.name}';

    // 2. Entra al destino. Un abono positivo nunca deja negativo.
    await aplicarMovimiento(
      moneyId: destinoId,
      monto: monto,
      concepto: etiqueta,
      referenciaId: origenId,
    );
    return null;
  }
}