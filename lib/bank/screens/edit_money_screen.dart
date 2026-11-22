import 'package:asend/bank/screens/add_money_screen.dart';
import 'package:asend/bank/services/money_service.dart';
import 'package:asend/models/money_account.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lo que se puede hacer con un elemento de Dinero desde su lápiz:
/// cambiar nombre y tipo, meter dinero, retirar, pasar a otro y
/// eliminarlo (solo con saldo 0).
class EditMoneyScreen extends StatefulWidget {
  final int moneyId;

  const EditMoneyScreen({super.key, required this.moneyId});

  @override
  State<EditMoneyScreen> createState() => _EditMoneyScreenState();
}

class _EditMoneyScreenState extends State<EditMoneyScreen> {
  void _aviso(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Convierte el texto a número. Acepta coma o punto como decimal.
  double? _leerMonto(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  // ── Nombre y tipo ──────────────────────────────────────

  Future<void> _editar(MoneyAccount m) async {
    final controlador = TextEditingController(text: m.name);
    String tipo = m.tipo;
    String? error;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Nombre y tipo',
            style: TextStyle(color: AppTheme.textWhite),
          ),
          // Ancho fijo: los dos botones de tipo se reparten el espacio
          // y el diálogo no puede medirlos por sí solo
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controlador,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 16),
                SelectorTipo(
                  tipo: tipo,
                  onChanged: (t) => setDialogState(() => tipo = t),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);

                final mensaje = await MoneyService.editar(
                  moneyId: m.id,
                  nombre: controlador.text,
                  tipo: tipo,
                );

                if (mensaje != null) {
                  setDialogState(() => error = mensaje);
                  return;
                }
                navigator.pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    // El TextField sigue usando el controlador durante la animación
    // de cierre; liberarlo antes rompe el árbol de widgets
    await Future.delayed(const Duration(milliseconds: 300));
    controlador.dispose();

    if (mounted) setState(() {});
  }

  // ── Ingreso, retiro y transferencia ────────────────────

  /// Diálogo de monto y concepto opcional. Si [conDestino] es true,
  /// también pide a cuál otro Dinero se pasa. [accion] hace el
  /// movimiento y devuelve null o el mensaje de error.
  Future<void> _dialogoMonto({
    required MoneyAccount m,
    required String titulo,
    required String boton,
    required String avisoHecho,
    required Future<String?> Function(double monto, String concepto, int? destino)
    accion,
    bool conDestino = false,
  }) async {
    final otros = MoneyService.getAll().where((o) => o.id != m.id).toList();
    if (conDestino && otros.isEmpty) {
      _aviso('Crea otro elemento de Dinero para poder transferir');
      return;
    }

    final montoCtrl = TextEditingController();
    final conceptoCtrl = TextEditingController();
    int? destinoId = otros.isNotEmpty ? otros.first.id : null;
    String? error;
    bool hecho = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(titulo, style: const TextStyle(color: AppTheme.textWhite)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (conDestino) ...[
                DropdownButtonFormField<int>(
                  initialValue: destinoId,
                  dropdownColor: AppTheme.bgDarkGrey,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'Pasar a'),
                  items: [
                    for (final o in otros)
                      DropdownMenuItem(value: o.id, child: Text(o.name)),
                  ],
                  onChanged: (v) => setDialogState(() => destinoId = v),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: montoCtrl,
                autofocus: !conDestino,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                // Números, punto y coma: algunos teclados solo dan coma
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: conceptoCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: const InputDecoration(
                  labelText: 'Concepto (opcional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final monto = _leerMonto(montoCtrl.text);
                if (monto == null) {
                  setDialogState(() => error = 'Escribe un número válido');
                  return;
                }

                final navigator = Navigator.of(context);
                final mensaje = await accion(
                  monto,
                  conceptoCtrl.text,
                  destinoId,
                );

                if (mensaje != null) {
                  setDialogState(() => error = mensaje);
                  return;
                }

                hecho = true;
                navigator.pop();
              },
              child: Text(boton),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));
    montoCtrl.dispose();
    conceptoCtrl.dispose();

    if (!mounted) return;
    setState(() {});
    if (hecho) _aviso(avisoHecho);
  }

  void _ingresar(MoneyAccount m) => _dialogoMonto(
    m: m,
    titulo: 'Ingreso a ${m.name}',
    boton: 'Ingresar',
    avisoHecho: 'Ingreso registrado',
    accion: (monto, concepto, _) => MoneyService.ingresar(
      moneyId: m.id,
      monto: monto,
      concepto: concepto,
    ),
  );

  void _retirar(MoneyAccount m) => _dialogoMonto(
    m: m,
    titulo: 'Retirar de ${m.name}',
    boton: 'Retirar',
    avisoHecho: 'Retiro registrado',
    accion: (monto, concepto, _) => MoneyService.retirar(
      moneyId: m.id,
      monto: monto,
      concepto: concepto,
    ),
  );

  void _transferir(MoneyAccount m) => _dialogoMonto(
    m: m,
    titulo: 'Transferir desde ${m.name}',
    boton: 'Transferir',
    avisoHecho: 'Transferencia registrada',
    conDestino: true,
    accion: (monto, concepto, destino) async {
      if (destino == null) return 'Elige a dónde pasar el dinero';
      return MoneyService.transferir(
        origenId: m.id,
        destinoId: destino,
        monto: monto,
        concepto: concepto,
      );
    },
  );

  // ── Eliminar ───────────────────────────────────────────

  Future<void> _eliminar(MoneyAccount m) async {
    // Solo se elimina en 0, así el dinero nunca desaparece del historial
    if (!MoneyService.estaEnCero(m)) {
      _aviso(
        'Déjalo en \$0 antes de eliminarlo. '
        'Tiene \$${m.balance.toStringAsFixed(2)}',
      );
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Eliminar?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          'Se eliminará "${m.name}".\n\n'
          'Su historial de movimientos se conserva.',
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

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final mensaje = await MoneyService.eliminar(m.id);

    if (mensaje != null) {
      messenger.showSnackBar(SnackBar(content: Text(mensaje)));
      return;
    }

    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text('"${m.name}" eliminado')));
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    final m = MoneyService.getById(widget.moneyId);

    if (m == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dinero')),
        body: Center(
          child: Text(
            'Ya no existe',
            style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(4)),
          ),
        ),
      );
    }

    final esEfectivo = m.tipo == MoneyService.efectivo;

    return Scaffold(
      appBar: AppBar(title: Text(m.name)),
      body: ListView(
        padding: EdgeInsets.all(e.w(5)),
        children: [
          // Tipo y saldo actual
          Text(
            esEfectivo ? 'Efectivo' : 'Digital',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.8)),
          ),
          SizedBox(height: e.h(0.5)),
          Text(
            '\$${m.balance.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: e.t(8.5),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: e.h(4)),

          _opcion(
            e,
            icono: Icons.edit,
            texto: 'Cambiar nombre y tipo',
            onTap: () => _editar(m),
          ),
          _opcion(
            e,
            icono: Icons.south_west,
            texto: 'Ingreso',
            onTap: () => _ingresar(m),
          ),
          _opcion(
            e,
            icono: Icons.arrow_outward,
            texto: 'Retirar',
            onTap: () => _retirar(m),
          ),
          _opcion(
            e,
            icono: Icons.swap_horiz,
            texto: 'Transferir',
            onTap: () => _transferir(m),
          ),
          SizedBox(height: e.h(3)),
          _opcion(
            e,
            icono: Icons.delete_outline,
            texto: 'Eliminar',
            color: AppTheme.danger,
            onTap: () => _eliminar(m),
          ),
        ],
      ),
    );
  }

  Widget _opcion(
    Escala e, {
    required IconData icono,
    required String texto,
    required VoidCallback onTap,
    Color color = AppTheme.buttonPurple,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: e.h(1.5)),
      child: Material(
        color: AppTheme.bgDarkGrey,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(e.t(2)),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
        child: ListTile(
          leading: Icon(icono, color: color, size: e.t(6)),
          title: Text(
            texto,
            style: TextStyle(
              color: color == AppTheme.danger ? color : AppTheme.textWhite,
              fontSize: e.t(4),
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: AppTheme.textHint,
            size: e.t(6),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}