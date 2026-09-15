import 'package:asend/bank/services/account_service.dart';
import 'package:asend/database/hive_service.dart';
import 'package:asend/models/account_history.dart';

/// Una cuenta disponible en el filtro del historial.
class CuentaFiltro {
  final int id;
  final String nombre;

  CuentaFiltro({required this.id, required this.nombre});
}

/// Un año del árbol de fechas, con sus meses.
class AnioFiltro {
  final int anio;
  final List<MesFiltro> meses;

  AnioFiltro({required this.anio, required this.meses});
}

/// Un mes del árbol de fechas, con sus días.
class MesFiltro {
  final int mes;
  final List<int> dias;

  MesFiltro({required this.mes, required this.dias});
}

/// Lee los movimientos de AccountHistory para el historial de Banco.
///
/// La categoría no se guarda: se deduce del texto del concepto. Así los
/// movimientos que ya estaban guardados siguen sirviendo sin tocar el
/// modelo ni borrar la caja.
class MovementService {
  /// Categoría que se muestra en la tabla, según el concepto guardado.
  /// Lo que no reconoce se marca como movimiento antiguo.
  static String getCategoria(String concepto) {
    // Las variantes van antes que 'Compra:' a secas, porque todas
    // empiezan con la misma palabra
    if (concepto.startsWith('Compra eliminada')) return 'Compra cancelada';
    if (concepto.startsWith('Compra movida')) return 'Compra cancelada';
    if (concepto.startsWith('Ajuste de compra')) return 'Ajuste';
    if (concepto.startsWith('Compra')) return 'Compra';

    if (concepto.startsWith('Pago')) return 'Pago';
    if (concepto.startsWith('Cobro')) return 'Pago';

    if (concepto.startsWith('Abono a meta')) return 'Compra meta';
    if (concepto.startsWith('Reparto a metas')) return 'Compra meta';
    if (concepto.startsWith('Meta eliminada')) return 'Compra meta devolución';
    if (concepto.startsWith('Retiro de meta')) return 'Devolución de meta';

    if (concepto.startsWith('Abono:')) return 'Abono';

    // Retiro manual: se muestra el concepto que eligió el usuario
    if (concepto.startsWith('Retiro:')) {
      final texto = concepto.substring('Retiro:'.length).trim();
      return texto.isEmpty ? 'Retiro' : texto;
    }

    return 'M. antiguo';
  }

  /// Todos los movimientos vivos, del más nuevo al más viejo.
  static List<AccountHistory> _getTodos() {
    final box = HiveService.getAccountHistoryBox();

    final movimientos = <AccountHistory>[];
    for (final m in box.values) {
      if (m.deletedAt == null) movimientos.add(m);
    }

    movimientos.sort((a, b) => b.fecha.compareTo(a.fecha));
    return movimientos;
  }

  static String _clave(int anio, int mes, int dia) {
    return '$anio-${mes.toString().padLeft(2, '0')}-'
        '${dia.toString().padLeft(2, '0')}';
  }

  static String _claveDe(DateTime f) => _clave(f.year, f.month, f.day);

  /// Movimientos que pasan los filtros activos.
  /// Un set vacío significa "sin filtrar por eso".
  static List<AccountHistory> getFiltrados({
    required Set<int> cuentas,
    required Set<String> dias,
  }) {
    return _getTodos().where((m) {
      if (cuentas.isNotEmpty && !cuentas.contains(m.accountId)) return false;
      if (dias.isNotEmpty && !dias.contains(_claveDe(m.fecha))) return false;
      return true;
    }).toList();
  }

  /// Cuentas que aparecen en el historial, filtrando por fecha.
  /// Sale del filtro de FECHA para que marcar una cuenta no haga
  /// desaparecer las demás de la lista.
  static List<CuentaFiltro> getCuentasDisponibles({
    required Set<String> dias,
  }) {
    final ids = <int>{};
    for (final m in _getTodos()) {
      if (dias.isNotEmpty && !dias.contains(_claveDe(m.fecha))) continue;
      ids.add(m.accountId);
    }

    final cuentas = ids
        .map(
          (id) => CuentaFiltro(
            id: id,
            nombre: AccountService.getAccountName(id),
          ),
        )
        .toList();

    cuentas.sort((a, b) => a.nombre.compareTo(b.nombre));
    return cuentas;
  }

  /// Árbol año → mes → día con las fechas que hay, filtrando por cuenta.
  /// Sale del filtro de CUENTA, nunca del de fecha.
  static List<AnioFiltro> getArbolFechas({required Set<int> cuentas}) {
    // anio -> mes -> días
    final mapa = <int, Map<int, Set<int>>>{};

    for (final m in _getTodos()) {
      if (cuentas.isNotEmpty && !cuentas.contains(m.accountId)) continue;

      final f = m.fecha;
      mapa.putIfAbsent(f.year, () => {});
      mapa[f.year]!.putIfAbsent(f.month, () => {});
      mapa[f.year]![f.month]!.add(f.day);
    }

    final anios = mapa.keys.toList()..sort((a, b) => b.compareTo(a));

    return anios.map((anio) {
      final meses = mapa[anio]!.keys.toList()..sort((a, b) => b.compareTo(a));

      return AnioFiltro(
        anio: anio,
        meses: meses.map((mes) {
          final dias = mapa[anio]![mes]!.toList()
            ..sort((a, b) => b.compareTo(a));
          return MesFiltro(mes: mes, dias: dias);
        }).toList(),
      );
    }).toList();
  }

  /// Suma de los montos de una lista, con su signo.
  static double getTotal(List<AccountHistory> movimientos) {
    double total = 0;
    for (final m in movimientos) {
      total += m.monto;
    }
    return total;
  }
}