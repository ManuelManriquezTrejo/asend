import 'package:asend/bank/services/money_service.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Crea un elemento de Dinero: nombre, tipo (efectivo o digital) y
/// saldo inicial opcional.
class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final _nombreCtrl = TextEditingController();
  final _saldoCtrl = TextEditingController();
  String _tipo = MoneyService.efectivo;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _saldoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    // Vacío cuenta como 0. Acepta coma o punto como decimal.
    final textoSaldo = _saldoCtrl.text.trim().replaceAll(',', '.');
    final saldo = textoSaldo.isEmpty ? 0.0 : double.tryParse(textoSaldo);
    if (saldo == null) {
      setState(() => _error = 'Escribe un saldo válido');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final mensaje = await MoneyService.crear(
      nombre: _nombreCtrl.text,
      tipo: _tipo,
      saldoInicial: saldo,
    );
    if (!mounted) return;

    if (mensaje != null) {
      setState(() => _error = mensaje);
      return;
    }

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('"${_nombreCtrl.text.trim()}" agregado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo dinero')),
      body: ListView(
        padding: EdgeInsets.all(e.w(5)),
        children: [
          TextField(
            controller: _nombreCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(4.2)),
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Cartera, BBVA, Nu...',
            ),
          ),
          SizedBox(height: e.h(3)),

          Text(
            'Tipo',
            style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.8)),
          ),
          SizedBox(height: e.h(1)),
          SelectorTipo(
            tipo: _tipo,
            onChanged: (t) => setState(() => _tipo = t),
          ),
          SizedBox(height: e.h(3)),

          TextField(
            controller: _saldoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Números, punto y coma: algunos teclados solo dan coma
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(4.2)),
            decoration: const InputDecoration(
              labelText: 'Saldo inicial (opcional)',
              prefixText: '\$ ',
              hintText: '0',
            ),
          ),

          if (_error != null) ...[
            SizedBox(height: e.h(2)),
            Text(
              _error!,
              style: TextStyle(color: AppTheme.danger, fontSize: e.t(3.6)),
            ),
          ],
          SizedBox(height: e.h(4)),

          SizedBox(
            height: e.h(6.5),
            child: ElevatedButton(
              onPressed: _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonPurple,
              ),
              child: Text(
                'Guardar',
                style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(4.2)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dos botones para elegir efectivo o digital. Lo usan la pantalla de
/// nuevo y el lápiz de Dinero.
class SelectorTipo extends StatelessWidget {
  final String tipo;
  final ValueChanged<String> onChanged;

  const SelectorTipo({super.key, required this.tipo, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);

    Widget boton(String valor, String texto, IconData icono) {
      final activo = tipo == valor;
      return Flexible(
        child: SizedBox(
          width: double.infinity,
          height: e.h(6),
          child: OutlinedButton.icon(
            onPressed: () => onChanged(valor),
            icon: Icon(
              icono,
              size: e.t(5),
              color: activo ? AppTheme.textWhite : AppTheme.textGrey,
            ),
            label: Text(
              texto,
              style: TextStyle(
                fontSize: e.t(3.9),
                color: activo ? AppTheme.textWhite : AppTheme.textGrey,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: activo
                  ? AppTheme.buttonPurple
                  : AppTheme.bgDarkGrey,
              side: BorderSide(color: AppTheme.buttonPurple),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        boton(MoneyService.efectivo, 'Efectivo', Icons.payments),
        SizedBox(width: e.w(3)),
        boton(MoneyService.digital, 'Digital', Icons.credit_card),
      ],
    );
  }
}