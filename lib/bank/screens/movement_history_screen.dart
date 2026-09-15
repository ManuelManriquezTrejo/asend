import 'package:asend/bank/services/account_service.dart';
import 'package:asend/bank/services/movement_service.dart';
import 'package:asend/models/account_history.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Historial de movimientos de Banco: fecha, cuenta, categoría y monto.
/// Solo lectura, con filtros de fecha y cuenta.
class MovementHistoryScreen extends StatefulWidget {
  const MovementHistoryScreen({super.key});

  @override
  State<MovementHistoryScreen> createState() => _MovementHistoryScreenState();
}

class _MovementHistoryScreenState extends State<MovementHistoryScreen> {
  /// Movimientos por bloque cuando no hay filtros activos.
  static const int _porBloque = 50;

  final Set<int> _cuentas = {};
  final Set<String> _dias = {};

  int _bloque = 0;

  static const List<String> _nombresMes = [
    '',
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  bool get _hayFiltro => _cuentas.isNotEmpty || _dias.isNotEmpty;

  String _clave(int anio, int mes, int dia) {
    return '$anio-${mes.toString().padLeft(2, '0')}-'
        '${dia.toString().padLeft(2, '0')}';
  }

  /// Quita del filtro de fecha los días que ya no existen en el árbol.
  void _podarDias() {
    final validos = <String>{};
    for (final a in MovementService.getArbolFechas(cuentas: _cuentas)) {
      for (final m in a.meses) {
        for (final d in m.dias) {
          validos.add(_clave(a.anio, m.mes, d));
        }
      }
    }
    _dias.removeWhere((d) => !validos.contains(d));
  }

  // ─────────────────────────────────────────────
  // FILTRO DE CUENTA
  // ─────────────────────────────────────────────

  Future<void> _filtroCuenta() async {
    final disponibles = MovementService.getCuentasDisponibles(dias: _dias);

    if (disponibles.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Filtrar por cuenta',
            style: TextStyle(color: AppTheme.textWhite),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                CheckboxListTile(
                  dense: true,
                  value: _cuentas.length == disponibles.length,
                  title: const Text(
                    'Todas',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onChanged: (v) => setDialogState(() {
                    _cuentas.clear();
                    if (v == true) {
                      _cuentas.addAll(disponibles.map((c) => c.id));
                    }
                  }),
                ),
                const Divider(height: 1, color: AppTheme.disabled),
                ...disponibles.map(
                  (c) => CheckboxListTile(
                    dense: true,
                    value: _cuentas.contains(c.id),
                    title: Text(
                      c.nombre,
                      style: const TextStyle(color: AppTheme.textWhite),
                    ),
                    onChanged: (v) => setDialogState(() {
                      if (v == true) {
                        _cuentas.add(c.id);
                      } else {
                        _cuentas.remove(c.id);
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Listo',
                style: TextStyle(color: AppTheme.buttonPurple),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _podarDias();
      _bloque = 0;
    });
  }

  // ─────────────────────────────────────────────
  // FILTRO DE FECHA
  // ─────────────────────────────────────────────

  Future<void> _filtroFecha() async {
    final arbol = MovementService.getArbolFechas(cuentas: _cuentas);

    if (arbol.isEmpty) return;

    final todos = <String>[];
    for (final a in arbol) {
      for (final m in a.meses) {
        for (final d in m.dias) {
          todos.add(_clave(a.anio, m.mes, d));
        }
      }
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Filtrar por fecha',
            style: TextStyle(color: AppTheme.textWhite),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                CheckboxListTile(
                  dense: true,
                  value: _dias.length == todos.length,
                  title: const Text(
                    'Todo',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onChanged: (v) => setDialogState(() {
                    _dias.clear();
                    if (v == true) _dias.addAll(todos);
                  }),
                ),
                const Divider(height: 1, color: AppTheme.disabled),
                ...arbol.map((a) {
                  final diasAnio = <String>[];
                  for (final m in a.meses) {
                    for (final d in m.dias) {
                      diasAnio.add(_clave(a.anio, m.mes, d));
                    }
                  }

                  return ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(left: 16),
                    leading: Checkbox(
                      value: diasAnio.every(_dias.contains),
                      onChanged: (v) => setDialogState(() {
                        if (v == true) {
                          _dias.addAll(diasAnio);
                        } else {
                          _dias.removeAll(diasAnio);
                        }
                      }),
                    ),
                    title: Text(
                      '${a.anio}',
                      style: const TextStyle(color: AppTheme.textWhite),
                    ),
                    children: a.meses.map((m) {
                      final diasMes = m.dias
                          .map((d) => _clave(a.anio, m.mes, d))
                          .toList();

                      return ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(left: 16),
                        leading: Checkbox(
                          value: diasMes.every(_dias.contains),
                          onChanged: (v) => setDialogState(() {
                            if (v == true) {
                              _dias.addAll(diasMes);
                            } else {
                              _dias.removeAll(diasMes);
                            }
                          }),
                        ),
                        title: Text(
                          _nombresMes[m.mes],
                          style: const TextStyle(color: AppTheme.textWhite),
                        ),
                        children: m.dias.map((d) {
                          final clave = _clave(a.anio, m.mes, d);
                          return CheckboxListTile(
                            dense: true,
                            value: _dias.contains(clave),
                            title: Text(
                              '$d de ${_nombresMes[m.mes]}',
                              style: const TextStyle(
                                color: AppTheme.textWhite,
                                fontSize: 13,
                              ),
                            ),
                            onChanged: (v) => setDialogState(() {
                              if (v == true) {
                                _dias.add(clave);
                              } else {
                                _dias.remove(clave);
                              }
                            }),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Listo',
                style: TextStyle(color: AppTheme.buttonPurple),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _bloque = 0);
  }

  // ─────────────────────────────────────────────
  // PANTALLA
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtrados = MovementService.getFiltrados(
      cuentas: _cuentas,
      dias: _dias,
    );

    // Con filtro activo se ven todos de corrido; sin filtro, por bloques
    final totalBloques = (filtrados.length / _porBloque).ceil();
    final visibles = _hayFiltro
        ? filtrados
        : filtrados.skip(_bloque * _porBloque).take(_porBloque).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos'), centerTitle: true),
      body: Column(
        children: [
          // Filtros fijos bajo el título
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _filtroFecha,
                    child: Text(
                      _dias.isEmpty ? 'Fecha' : 'Fecha (${_dias.length})',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _filtroCuenta,
                    child: Text(
                      _cuentas.isEmpty
                          ? 'Cuenta'
                          : 'Cuenta (${_cuentas.length})',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (_hayFiltro) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Limpiar filtros',
                    icon: const Icon(
                      Icons.filter_alt_off,
                      color: AppTheme.danger,
                    ),
                    onPressed: () => setState(() {
                      _cuentas.clear();
                      _dias.clear();
                      _bloque = 0;
                    }),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.disabled),

          // Los datos, lo único que se mueve con el scroll
          Expanded(
            child: visibles.isEmpty
                ? const Center(
                    child: Text(
                      'Sin movimientos que mostrar',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 15),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    children: visibles.map(_fila).toList(),
                  ),
          ),

          // Números de bloque, solo sin filtros y si hay más de uno
          if (!_hayFiltro && totalBloques > 1)
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: totalBloques,
                itemBuilder: (ctx, i) {
                  final activo = i == _bloque;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: TextButton(
                      onPressed: () => setState(() => _bloque = i),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(38, 34),
                        padding: EdgeInsets.zero,
                        backgroundColor: activo
                            ? AppTheme.buttonPurple
                            : AppTheme.bgDarkGrey,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: activo
                              ? AppTheme.textWhite
                              : AppTheme.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Total fijo abajo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Total: ',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                ),
                Text(
                  _hayFiltro
                      ? MovementService.getTotal(
                          filtrados,
                        ).toStringAsFixed(2)
                      : 'Activar algún filtro',
                  style: TextStyle(
                    color: _hayFiltro ? AppTheme.textWhite : AppTheme.textHint,
                    fontSize: _hayFiltro ? 18 : 14,
                    fontWeight: _hayFiltro
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Un movimiento: arriba cuenta, categoría y monto; abajo la fecha.
  Widget _fila(AccountHistory m) {
    final f = m.fecha;
    final fecha =
        '${f.day.toString().padLeft(2, '0')}/'
        '${f.month.toString().padLeft(2, '0')}/${f.year} '
        '${f.hour.toString().padLeft(2, '0')}:'
        '${f.minute.toString().padLeft(2, '0')}';

    // El signo va en el número, sin color: el monto ya viene con él
    final monto = m.monto.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgDarkGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.buttonPurple.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    AccountService.getAccountName(m.accountId),
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    MovementService.getCategoria(m.concepto),
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    monto,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  fecha,
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}