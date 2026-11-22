import 'package:asend/bank/services/account_service.dart';
import 'package:asend/models/account.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pasar dinero de una cuenta a otra. Primero se elige la cuenta de
/// origen y después la de destino, que nunca muestra la de origen.
class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _montoCtrl = TextEditingController();
  final _conceptoCtrl = TextEditingController();

  int? _origenId;
  int? _destinoId;
  String? _errorMonto;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _conceptoCtrl.dispose();
    super.dispose();
  }

  String _dinero(double v) => '\$${v.toStringAsFixed(2)}';

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Revisa el monto contra el saldo de origen.
  /// Devuelve el monto a transferir, o null si no es válido.
  double? _validarMonto(Account origen) {
    final monto = double.tryParse(_montoCtrl.text.trim().replaceAll(',', '.'));

    if (monto == null || monto <= 0) {
      setState(() => _errorMonto = 'Escribe un monto mayor a 0');
      return null;
    }

    // Escribir el saldo que se ve en pantalla puede pasarse por
    // fracciones de centavo; en ese caso se manda el saldo exacto
    if (monto > origen.balance) {
      if (monto - origen.balance < 0.005) return origen.balance;

      setState(() => _errorMonto = 'Máximo ${_dinero(origen.balance)}');
      return null;
    }

    return monto;
  }

  Future<void> _transferir() async {
    if (_origenId == null || _destinoId == null) {
      _aviso('Elige la cuenta de origen y la de destino');
      return;
    }

    final origen = AccountService.getAccountById(_origenId!);
    final destino = AccountService.getAccountById(_destinoId!);
    if (origen == null || destino == null) {
      _aviso('Una de las cuentas ya no existe');
      return;
    }

    final monto = _validarMonto(origen);
    if (monto == null) return;

    final concepto = _conceptoCtrl.text.trim();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Confirmar transferencia?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          'De: ${origen.name}\n'
          'A: ${destino.name}\n'
          'Monto: ${_dinero(monto)}'
          '${concepto.isEmpty ? '' : '\nConcepto: $concepto'}',
          style: const TextStyle(color: AppTheme.textGrey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Transferir'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final error = await AccountService.transferir(
      origenId: origen.id,
      destinoId: destino.id,
      monto: monto,
      concepto: concepto,
    );

    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      if (mounted) setState(() {});
      return;
    }

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${_dinero(monto)} de ${origen.name} a ${destino.name}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cuentas = AccountService.getCuentasMovibles();
    if (cuentas.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('Movimientos')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Necesitas al menos dos cuentas para transferir',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
        ),
      );
    }

    final origen = _origenId == null
        ? null
        : AccountService.getAccountById(_origenId!);

    // El destino nunca ofrece la cuenta de origen
    final destinos = cuentas.where((a) => a.id != _origenId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Origen
          const Text(
            'De la cuenta',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _origenId,
            dropdownColor: AppTheme.bgDarkGrey,
            hint: const Text(
              'Elige de dónde sale',
              style: TextStyle(color: AppTheme.textHint),
            ),
            items: cuentas
                .map(
                  (a) => DropdownMenuItem<int>(
                    value: a.id,
                    child: Text(
                      a.name,
                      style: const TextStyle(color: AppTheme.textWhite),
                    ),
                  ),
                )
                .toList(),
            onChanged: (id) => setState(() {
              _origenId = id;
              _errorMonto = null;
              // Si el destino era la misma cuenta, se borra la elección
              if (_destinoId == id) _destinoId = null;
            }),
          ),
          if (origen != null) ...[
            const SizedBox(height: 6),
            Text(
              'Disponible: ${_dinero(origen.balance)}',
              style: const TextStyle(color: AppTheme.success, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),

          // 2. Destino: solo se elige después del origen
          const Text(
            'A la cuenta',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            // La llave reconstruye el campo cuando cambia el origen,
            // para que no se quede mostrando una opción que ya no existe
            key: ValueKey('destino-$_origenId'),
            initialValue: _destinoId,
            dropdownColor: AppTheme.bgDarkGrey,
            hint: Text(
              _origenId == null
                  ? 'Primero elige el origen'
                  : 'Elige a dónde va',
              style: const TextStyle(color: AppTheme.textHint),
            ),
            items: destinos
                .map(
                  (a) => DropdownMenuItem<int>(
                    value: a.id,
                    child: Text(
                      a.name,
                      style: const TextStyle(color: AppTheme.textWhite),
                    ),
                  ),
                )
                .toList(),
            onChanged: _origenId == null
                ? null
                : (id) => setState(() => _destinoId = id),
          ),
          const SizedBox(height: 24),

          // 3. Monto
          const Text(
            'Monto',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _montoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Números, punto y coma: algunos teclados solo dan coma
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: InputDecoration(
              hintText: 'Ej: 5000',
              prefixText: '\$ ',
              errorText: _errorMonto,
            ),
            onChanged: (_) {
              if (_errorMonto != null) setState(() => _errorMonto = null);
            },
          ),
          const SizedBox(height: 24),

          // 4. Concepto opcional
          const Text(
            'Concepto (opcional)',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _conceptoCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: const InputDecoration(hintText: 'Ahorro, coche...'),
          ),
          const SizedBox(height: 40),

          ElevatedButton.icon(
            onPressed: _transferir,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Transferir'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ],
      ),
    );
  }
}