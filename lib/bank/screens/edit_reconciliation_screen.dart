import 'package:asend/bank/services/account_service.dart';
import 'package:asend/bank/services/money_service.dart';
import 'package:asend/bank/services/reconciliation_service.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';

/// Crea un cuadre (sin [reconciliationId]) o edita uno existente:
/// nombre y qué cuentas y qué elementos de Dinero compara.
/// Al editar, abajo aparece el botón para eliminarlo.
/// Aquí no se crean ni se borran cuentas ni Dinero, solo se eligen.
class EditReconciliationScreen extends StatefulWidget {
  final int? reconciliationId;

  const EditReconciliationScreen({super.key, this.reconciliationId});

  @override
  State<EditReconciliationScreen> createState() =>
      _EditReconciliationScreenState();
}

class _EditReconciliationScreenState extends State<EditReconciliationScreen> {
  final _nombreCtrl = TextEditingController();
  final Set<int> _cuentas = {};
  final Set<int> _dineros = {};
  String? _error;

  bool get _editando => widget.reconciliationId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.reconciliationId;
    if (id == null) return;

    final c = ReconciliationService.getById(id);
    if (c == null) return;
    _nombreCtrl.text = c.nombre;
    _cuentas.addAll(c.accountIds);
    _dineros.addAll(c.moneyIds);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  String _dinero(double v) => '\$${v.toStringAsFixed(2)}';

  Future<void> _guardar() async {
    final navigator = Navigator.of(context);

    // Solo se guardan ids que siguen activos, por si alguno se
    // eliminó mientras el cuadre ya existía
    final cuentas = _cuentas
        .where((id) => AccountService.getAccountById(id) != null)
        .toList();
    final dineros = _dineros
        .where((id) => MoneyService.getById(id) != null)
        .toList();

    final mensaje = _editando
        ? await ReconciliationService.editar(
            id: widget.reconciliationId!,
            nombre: _nombreCtrl.text,
            accountIds: cuentas,
            moneyIds: dineros,
          )
        : await ReconciliationService.crear(
            nombre: _nombreCtrl.text,
            accountIds: cuentas,
            moneyIds: dineros,
          );
    if (!mounted) return;

    if (mensaje != null) {
      setState(() => _error = mensaje);
      return;
    }
    navigator.pop();
  }

  Future<void> _eliminar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Eliminar cuadre?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          'Se eliminará "${_nombreCtrl.text.trim()}".\n\n'
          'Tus cuentas y tu dinero no cambian.',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    final navigator = Navigator.of(context);
    await ReconciliationService.eliminar(widget.reconciliationId!);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);

    final cuentas = AccountService.getAllAccounts()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final dineros = MoneyService.getAll();

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar cuadre' : 'Nuevo cuadre')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(e.w(5)),
                children: [
                  TextField(
                    controller: _nombreCtrl,
                    autofocus: !_editando,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: e.t(4.2),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Personal, Deudas...',
                    ),
                  ),
                  SizedBox(height: e.h(3)),

                  _titulo(e, 'Cuentas', _cuentas.length),
                  if (cuentas.isEmpty)
                    _vacio(e, 'No tienes cuentas')
                  else
                    for (final a in cuentas)
                      _casilla(
                        e,
                        nombre: a.name,
                        saldo: a.balance,
                        marcada: _cuentas.contains(a.id),
                        onChanged: (v) => setState(() {
                          v ? _cuentas.add(a.id) : _cuentas.remove(a.id);
                        }),
                      ),
                  SizedBox(height: e.h(3)),

                  _titulo(e, 'Dinero', _dineros.length),
                  if (dineros.isEmpty)
                    _vacio(e, 'No tienes elementos de Dinero')
                  else
                    for (final m in dineros)
                      _casilla(
                        e,
                        nombre: m.name,
                        saldo: m.balance,
                        icono: m.tipo == MoneyService.efectivo
                            ? Icons.payments
                            : Icons.credit_card,
                        marcada: _dineros.contains(m.id),
                        onChanged: (v) => setState(() {
                          v ? _dineros.add(m.id) : _dineros.remove(m.id);
                        }),
                      ),

                  if (_error != null) ...[
                    SizedBox(height: e.h(2)),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: AppTheme.danger,
                        fontSize: e.t(3.8),
                      ),
                    ),
                  ],

                  if (_editando) ...[
                    SizedBox(height: e.h(4)),
                    TextButton.icon(
                      onPressed: _eliminar,
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppTheme.danger,
                        size: e.t(5.5),
                      ),
                      label: Text(
                        'Eliminar cuadre',
                        style: TextStyle(
                          color: AppTheme.danger,
                          fontSize: e.t(4),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(e.w(5), e.h(1), e.w(5), e.h(2)),
              child: SizedBox(
                width: double.infinity,
                height: e.h(6.5),
                child: ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.buttonPurple,
                  ),
                  child: Text(
                    'Guardar',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: e.t(4.2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Encabezado de sección con cuántos hay marcados.
  Widget _titulo(Escala e, String texto, int marcados) {
    return Padding(
      padding: EdgeInsets.only(bottom: e.h(0.5)),
      child: Text(
        '$texto ($marcados)',
        style: TextStyle(
          color: AppTheme.buttonPurple,
          fontSize: e.t(4.6),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _vacio(Escala e, String texto) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: e.h(1)),
      child: Text(
        texto,
        style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.8)),
      ),
    );
  }

  Widget _casilla(
    Escala e, {
    required String nombre,
    required double saldo,
    required bool marcada,
    required ValueChanged<bool> onChanged,
    IconData? icono,
  }) {
    return CheckboxListTile(
      value: marcada,
      onChanged: (v) => onChanged(v ?? false),
      activeColor: AppTheme.buttonPurple,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Row(
        children: [
          if (icono != null) ...[
            Icon(icono, color: AppTheme.textHint, size: e.t(4.5)),
            SizedBox(width: e.w(2)),
          ],
          Expanded(
            child: Text(
              nombre,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(4)),
            ),
          ),
        ],
      ),
      secondary: Text(
        _dinero(saldo),
        style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.8)),
      ),
    );
  }
}