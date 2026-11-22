import 'package:asend/bank/screens/withdraw_screen.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/models/account.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lo que se puede hacer con una cuenta desde su lápiz:
/// cambiar el nombre, meter dinero, retirar y eliminarla.
class EditAccountScreen extends StatefulWidget {
  final int accountId;

  const EditAccountScreen({super.key, required this.accountId});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  void _aviso(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Convierte el texto a número. Acepta coma o punto como decimal.
  double? _leerMonto(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  // ── Nombre ─────────────────────────────────────────────

  Future<void> _cambiarNombre(Account cuenta) async {
    final controlador = TextEditingController(text: cuenta.name);
    String? error;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Cambiar nombre',
            style: TextStyle(color: AppTheme.textWhite),
          ),
          content: TextField(
            controller: controlador,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: InputDecoration(errorText: error),
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

                final mensaje = await AccountService.renombrar(
                  accountId: cuenta.id,
                  nombre: controlador.text,
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

  // ── Ingreso ────────────────────────────────────────────

  Future<void> _ingresar(Account cuenta) async {
    final montoCtrl = TextEditingController();
    final conceptoCtrl = TextEditingController();
    String? error;
    bool hecho = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Ingreso a ${cuenta.name}',
            style: const TextStyle(color: AppTheme.textWhite),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: montoCtrl,
                autofocus: true,
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
                  hintText: 'Sueldo, regalo...',
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

                final mensaje = await AccountService.ingresar(
                  accountId: cuenta.id,
                  monto: monto,
                  concepto: conceptoCtrl.text,
                );

                if (mensaje != null) {
                  setDialogState(() => error = mensaje);
                  return;
                }

                hecho = true;
                navigator.pop();
              },
              child: const Text('Ingresar'),
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
    if (hecho) _aviso('Ingreso registrado');
  }

  // ── Retiro ─────────────────────────────────────────────

  void _retirar(Account cuenta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawScreen(
          cuentaInicialId: cuenta.id,
          onWithdrawn: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  // ── Eliminar ───────────────────────────────────────────

  Future<void> _eliminar(Account cuenta) async {
    // Solo se elimina en 0, así el dinero nunca desaparece del historial
    if (!AccountService.estaEnCero(cuenta)) {
      _aviso(
        'Deja la cuenta en \$0 antes de eliminarla. '
        'Tiene \$${cuenta.balance.toStringAsFixed(2)}',
      );
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Eliminar cuenta?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          'Se eliminará "${cuenta.name}".\n\n'
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

    final mensaje = await AccountService.eliminarCuenta(cuenta.id);

    if (mensaje != null) {
      messenger.showSnackBar(SnackBar(content: Text(mensaje)));
      return;
    }

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Cuenta "${cuenta.name}" eliminada')),
    );
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cuenta = AccountService.getAccountById(widget.accountId);

    if (cuenta == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cuenta')),
        body: const Center(
          child: Text(
            'Esta cuenta ya no existe',
            style: TextStyle(color: AppTheme.textGrey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(cuenta.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Saldo actual
          const Text(
            'Saldo',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${cuenta.balance.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          _opcion(
            icono: Icons.edit,
            texto: 'Cambiar nombre',
            onTap: () => _cambiarNombre(cuenta),
          ),
          // La cuenta Metas solo se renombra: su saldo lo mueve Metas
          if (AccountService.esCuentaMetas(cuenta.id))
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Esta cuenta se mueve sola al abonar o retirar en Metas',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
              ),
            )
          else ...[
            _opcion(
              icono: Icons.south_west,
              texto: 'Ingreso',
              onTap: () => _ingresar(cuenta),
            ),
            _opcion(
              icono: Icons.arrow_outward,
              texto: 'Retirar',
              onTap: () => _retirar(cuenta),
            ),
            const SizedBox(height: 24),
            _opcion(
              icono: Icons.delete_outline,
              texto: 'Eliminar cuenta',
              color: AppTheme.danger,
              onTap: () => _eliminar(cuenta),
            ),
          ],
        ],
      ),
    );
  }

  Widget _opcion({
    required IconData icono,
    required String texto,
    required VoidCallback onTap,
    Color color = AppTheme.buttonPurple,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.bgDarkGrey,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
        child: ListTile(
          leading: Icon(icono, color: color),
          title: Text(
            texto,
            style: TextStyle(
              color: color == AppTheme.danger ? color : AppTheme.textWhite,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
          onTap: onTap,
        ),
      ),
    );
  }
}