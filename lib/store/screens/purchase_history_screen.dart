import 'package:asend/bank/services/account_service.dart';
import 'package:asend/models/purchase.dart';
import 'package:asend/store/services/purchase_service.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  /// Compras por bloque cuando no hay filtros activos.
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
  /// Se llama al cambiar las cuentas: si un día solo tenía compras de una
  /// cuenta que se deseleccionó, deja de tener sentido tenerlo marcado.
  void _podarDias() {
    final validos = <String>{};
    for (final a in PurchaseService.getArbolFechas(cuentas: _cuentas)) {
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
    // Las cuentas disponibles salen del filtro de FECHA, no del de cuenta:
    // así marcar una no hace desaparecer las demás de la lista.
    final disponibles = PurchaseService.getCuentasDisponibles(dias: _dias);

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
    // El árbol sale del filtro de CUENTA, nunca del de fecha
    final arbol = PurchaseService.getArbolFechas(cuentas: _cuentas);

    if (arbol.isEmpty) return;

    // Todos los días del árbol, para el "Todo" y para saber si un año
    // o un mes están completos
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
    final filtradas = PurchaseService.getFiltradas(
      cuentas: _cuentas,
      dias: _dias,
    );

    // Con filtro activo se ven todas de corrido; sin filtro, por bloques
    final totalBloques = (filtradas.length / _porBloque).ceil();
    final visibles = _hayFiltro
        ? filtradas
        : filtradas.skip(_bloque * _porBloque).take(_porBloque).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Historial'), centerTitle: true),
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
                      'Sin compras que mostrar',
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
                      ? '${PurchaseService.getTotal(filtradas)}'
                      : 'Activar algún filtro',
                  style: TextStyle(
                    color: _hayFiltro ? AppTheme.textWhite : AppTheme.textHint,
                    fontSize: _hayFiltro ? 18 : 14,
                    fontWeight:
                        _hayFiltro ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Una compra: arriba cuenta, producto y monto; abajo fecha y nota.
  /// Solo lectura: eliminar vive en Tienda, y solo para el mes en curso.
  Widget _fila(Purchase c) {
    final f = c.fecha;
    final fecha =
        '${f.day.toString().padLeft(2, '0')}/'
        '${f.month.toString().padLeft(2, '0')}/${f.year} '
        '${f.hour.toString().padLeft(2, '0')}:'
        '${f.minute.toString().padLeft(2, '0')}';

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
                    AccountService.getAccountName(c.accountId),
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    c.nombre,
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '${c.precio}',
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
                const Spacer(),
                if (c.nota != null)
                  Flexible(
                    child: Text(
                      c.nota!,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
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