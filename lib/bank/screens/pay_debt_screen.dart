import 'package:asend/bank/screens/new_debt_screen.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/bank/services/debt_service.dart';
import 'package:asend/models/debt.dart';
import 'package:asend/models/debt_installment.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';

/// Lista de pagos pendientes agrupada por mes. Se marcan con su casilla
/// y se pagan juntos desde una cuenta. Desde aquí también se editan con
/// el lápiz y se cancelan las suscripciones.
class PayDebtScreen extends StatefulWidget {
  const PayDebtScreen({super.key});

  @override
  State<PayDebtScreen> createState() => _PayDebtScreenState();
}

class _PayDebtScreenState extends State<PayDebtScreen> {
  static const List<String> _meses = [
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

  static const List<String> _mesesCortos = [
    '',
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// Ids de las mensualidades marcadas para pagar.
  final Set<int> _marcadas = {};

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  /// Crea las mensualidades de suscripción que falten y redibuja.
  /// Quita de las marcadas las que ya no estén pendientes.
  Future<void> _recargar() async {
    await DebtService.generarSuscripciones();
    if (!mounted) return;

    final pendientes = DebtService.getPendientes().map((c) => c.id).toSet();
    setState(() {
      _marcadas.removeWhere((id) => !pendientes.contains(id));
      _cargando = false;
    });
  }

  String _dinero(double v) => '\$${v.toStringAsFixed(2)}';

  String _fecha(DateTime d) => '${d.day} ${_mesesCortos[d.month]}';

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // ── Editar ─────────────────────────────────────────────

  Future<void> _editar(DebtInstallment c) async {
    final deuda = DebtService.getDeuda(c.debtId);
    if (deuda == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewDebtScreen(editar: deuda)),
    );
    await _recargar();
  }

  // ── Pagar ──────────────────────────────────────────────

  Future<void> _pagar(List<DebtInstallment> lista) async {
    final cuotas = lista.where((c) => _marcadas.contains(c.id)).toList();
    if (cuotas.isEmpty) {
      _aviso('Marca al menos un pago');
      return;
    }

    final cuentas = AccountService.getAllAccounts();
    if (cuentas.isEmpty) {
      _aviso('Primero crea una cuenta en Banco');
      return;
    }

    final total = cuotas.fold<double>(0, (s, c) => s + c.monto);
    int? cuentaId = DebtService.cuentaPorDefecto();
    String? error;
    bool pagando = false;
    bool pagado = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final cuenta = cuentaId == null
              ? null
              : AccountService.getAccountById(cuentaId!);

          return AlertDialog(
            title: const Text(
              'Confirmar pago',
              style: TextStyle(color: AppTheme.textWhite),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estás a punto de pagar ${cuotas.length} '
                    '${cuotas.length == 1 ? 'pago' : 'pagos'} '
                    'por la cantidad de ${_dinero(total)}.',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¿De qué cuenta deseas pagar?',
                    style: TextStyle(color: AppTheme.textWhite),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: cuenta == null ? null : cuentaId,
                    isExpanded: true,
                    dropdownColor: AppTheme.bgDarkGrey,
                    hint: const Text(
                      'Elige una cuenta',
                      style: TextStyle(color: AppTheme.textHint),
                    ),
                    items: cuentas
                        .map(
                          (a) => DropdownMenuItem<int>(
                            value: a.id,
                            child: Text(
                              '${a.name} · ${_dinero(a.balance)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textWhite,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: pagando
                        ? null
                        : (id) => setDialogState(() {
                            cuentaId = id;
                            error = null;
                          }),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(color: AppTheme.danger),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: pagando ? null : () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.black,
                ),
                onPressed: pagando
                    ? null
                    : () async {
                        final id = cuentaId;
                        if (id == null) {
                          setDialogState(() => error = 'Elige una cuenta');
                          return;
                        }

                        final navigator = Navigator.of(context);
                        setDialogState(() => pagando = true);

                        final mensaje = await DebtService.pagar(
                          cuotas: cuotas,
                          accountId: id,
                        );

                        if (mensaje != null) {
                          setDialogState(() {
                            error = mensaje;
                            pagando = false;
                          });
                          return;
                        }

                        pagado = true;
                        navigator.pop();
                      },
                child: const Text('Confirmar pago'),
              ),
            ],
          );
        },
      ),
    );

    if (!mounted) return;
    if (pagado) {
      _marcadas.clear();
      _aviso('Pago realizado: ${_dinero(total)}');
    }
    await _recargar();
  }

  // ── Cancelar suscripción ───────────────────────────────

  Future<void> _cancelarSuscripcion() async {
    final suscripciones = DebtService.getSuscripciones();
    if (suscripciones.isEmpty) {
      _aviso('No tienes suscripciones');
      return;
    }

    // 1. Elegir cuál, de una lista con scroll
    final elegida = await showDialog<Debt>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Qué suscripción quieres cancelar?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suscripciones.length,
            itemBuilder: (context, i) {
              final d = suscripciones[i];
              return ListTile(
                title: Text(
                  d.nombre,
                  style: const TextStyle(color: AppTheme.textWhite),
                ),
                subtitle: Text(
                  '${_dinero(d.monto)} · día ${d.diaPago} de cada mes',
                  style: const TextStyle(color: AppTheme.textGrey),
                ),
                onTap: () => Navigator.pop(context, d),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Volver',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
        ],
      ),
    );

    if (elegida == null || !mounted) return;

    // 2. Aviso de 3 segundos; después aparece el botón para confirmar
    bool listo = false;
    bool esperando = false;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (!esperando) {
            esperando = true;
            Future.delayed(const Duration(seconds: 3), () {
              if (context.mounted) setDialogState(() => listo = true);
            });
          }

          return AlertDialog(
            title: Text(
              'Cancelar "${elegida.nombre}"',
              style: const TextStyle(color: AppTheme.textWhite),
            ),
            content: const Text(
              'Se recomienda cancelar primero la suscripción antes de '
              'borrar el recordatorio.',
              style: TextStyle(color: AppTheme.textGrey, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Volver',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              ),
              if (listo)
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Cancelar suscripción',
                    style: TextStyle(color: AppTheme.danger),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          );
        },
      ),
    );

    if (confirmado != true || !mounted) return;

    await DebtService.eliminar(elegida.id);
    if (!mounted) return;

    _aviso('Suscripción "${elegida.nombre}" cancelada');
    await _recargar();
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);

    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pagar')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final lista = DebtService.getPendientesParaLista();
    final hayPendientes = lista.isNotEmpty;
    final haySuscripciones = DebtService.getSuscripciones().isNotEmpty;

    final marcadas = lista.where((c) => _marcadas.contains(c.id)).toList();
    final totalMarcado = marcadas.fold<double>(0, (s, c) => s + c.monto);

    return Scaffold(
      appBar: AppBar(title: const Text('Pagar')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: !hayPendientes
                  ? Center(
                      child: Text(
                        'No tienes pagos pendientes',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: e.t(4.2),
                        ),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: e.w(4),
                        vertical: e.h(1),
                      ),
                      children: _porMes(e, lista),
                    ),
            ),

            // Lo marcado y los botones
            Container(
              padding: EdgeInsets.fromLTRB(e.w(5), e.h(1.2), e.w(5), e.h(2)),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.bgDarkGrey, width: 2),
                ),
              ),
              child: Column(
                children: [
                  if (marcadas.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: e.h(1)),
                      child: Text(
                        '${marcadas.length} '
                        '${marcadas.length == 1 ? 'pago marcado' : 'pagos marcados'}'
                        ' · ${_dinero(totalMarcado)}',
                        style: TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: e.t(3.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Flexible(
                        child: SizedBox(
                          width: double.infinity,
                          height: e.h(6.5),
                          child: ElevatedButton(
                            onPressed: marcadas.isEmpty
                                ? null
                                : () => _pagar(lista),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: AppTheme.disabled,
                            ),
                            child: Text(
                              'Pagar',
                              style: TextStyle(
                                fontSize: e.t(4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: e.w(4)),
                      Flexible(
                        child: SizedBox(
                          width: double.infinity,
                          height: e.h(6.5),
                          child: OutlinedButton(
                            onPressed: haySuscripciones
                                ? _cancelarSuscripcion
                                : null,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: haySuscripciones
                                    ? AppTheme.danger
                                    : AppTheme.disabled,
                              ),
                            ),
                            child: Text(
                              'Cancelar suscripción',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: haySuscripciones
                                    ? AppTheme.danger
                                    : AppTheme.disabled,
                                fontSize: e.t(3.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Arma la lista con un encabezado y una línea por cada mes.
  List<Widget> _porMes(Escala e, List<DebtInstallment> lista) {
    final widgets = <Widget>[];
    int? mesActual;

    for (final c in lista) {
      final clave = c.fechaPago.year * 12 + c.fechaPago.month;

      if (clave != mesActual) {
        mesActual = clave;
        widgets.add(_encabezadoMes(e, c.fechaPago));
      }
      widgets.add(_renglon(e, c));
    }
    return widgets;
  }

  Widget _encabezadoMes(Escala e, DateTime fecha) {
    return Padding(
      padding: EdgeInsets.only(top: e.h(2), bottom: e.h(0.8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_meses[fecha.month]} ${fecha.year}',
            style: TextStyle(
              color: AppTheme.buttonPurple,
              fontSize: e.t(4.2),
              fontWeight: FontWeight.bold,
            ),
          ),
          Divider(color: AppTheme.buttonPurple.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _renglon(Escala e, DebtInstallment c) {
    final vencida = DebtService.estaVencida(c);
    final marcada = _marcadas.contains(c.id);
    final tipo = DebtService.tipoDe(c);

    final etiquetaTipo = tipo == DebtService.recurrente
        ? 'Suscripción'
        : tipo == DebtService.gasto
        ? 'Tarjeta'
        : 'Pago único';

    final colorTexto = vencida ? AppTheme.danger : AppTheme.textWhite;

    return InkWell(
      onTap: () => setState(() {
        if (marcada) {
          _marcadas.remove(c.id);
        } else {
          _marcadas.add(c.id);
        }
      }),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: e.h(0.4)),
        child: Row(
          children: [
            Checkbox(
              value: marcada,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _marcadas.add(c.id);
                } else {
                  _marcadas.remove(c.id);
                }
              }),
              fillColor: WidgetStateProperty.resolveWith(
                (estados) => estados.contains(WidgetState.selected)
                    ? AppTheme.success
                    : null,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DebtService.nombreDe(c),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorTexto,
                      fontSize: e.t(3.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    vencida ? '$etiquetaTipo · Vencido' : etiquetaTipo,
                    style: TextStyle(
                      color: vencida ? AppTheme.danger : AppTheme.textGrey,
                      fontSize: e.t(3.1),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _dinero(c.monto),
                  style: TextStyle(
                    color: colorTexto,
                    fontSize: e.t(3.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _fecha(c.fechaPago),
                  style: TextStyle(
                    color: vencida ? AppTheme.danger : AppTheme.textGrey,
                    fontSize: e.t(3.1),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.edit, color: AppTheme.textHint, size: e.t(5)),
              onPressed: () => _editar(c),
            ),
          ],
        ),
      ),
    );
  }
}