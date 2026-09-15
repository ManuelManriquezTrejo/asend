import 'package:flutter/material.dart';
import 'package:asend/models/fund.dart';
import 'package:asend/models/fund_account.dart';
import 'package:asend/bank/services/fund_service.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/theme/app_theme.dart';

class AddAmountToFundScreen extends StatefulWidget {
  final Fund fund;
  final Function onAmountAdded;

  const AddAmountToFundScreen({
    super.key,
    required this.fund,
    required this.onAmountAdded,
  });

  @override
  State<AddAmountToFundScreen> createState() => _AddAmountToFundScreenState();
}

class _AddAmountToFundScreenState extends State<AddAmountToFundScreen> {
  final TextEditingController amountController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void _addAmountToFund() async {
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa una cantidad')));
      return;
    }

    final double? parsed = double.tryParse(amountController.text);

    if (parsed == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un número válido')));
      return;
    }

    final double amount = parsed;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cantidad debe ser mayor a 0')),
      );
      return;
    }

    // Obtener las distribuciones de este fondo
    List<FundAccount> distributions = FundService.getFundAccountsByFundId(
      widget.fund.id,
    );

    if (distributions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El fondo "${widget.fund.name}" no tiene cuentas asignadas',
          ),
        ),
      );
      return;
    }

    // Repartir según el porcentaje. Cada cuenta recibe su parte como un
    // movimiento propio, para que el historial muestre un renglón por
    // cuenta afectada.
    int repartidas = 0;
    for (FundAccount dist in distributions) {
      double amountForAccount = amount * (dist.percentage / 100);
      if (amountForAccount <= 0) continue;

      final ok = await AccountService.aplicarMovimiento(
        accountId: dist.accountId,
        monto: amountForAccount, // entra
        concepto: 'Abono: ${widget.fund.name}',
        referenciaId: widget.fund.id,
      );

      if (ok) repartidas++;
    }

    if (!mounted) return;

    if (repartidas == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo repartir: las cuentas del fondo ya no existen'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '\$$amount agregados al fondo "${widget.fund.name}"',
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'El dinero se ha distribuido correctamente entre las cuentas.',
            style: TextStyle(color: AppTheme.textGrey),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                Navigator.pop(context); // Cierra AddAmountToFundScreen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonPurple,
              ),
              child: const Text(
                'Aceptar',
                style: TextStyle(color: AppTheme.textWhite),
              ),
            ),
          ],
        );
      },
    );

    widget.onAmountAdded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agregar a ${widget.fund.name}')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿Cuánto deseas agregar a "${widget.fund.name}"?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                hintText: 'Ej: 1000',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _addAmountToFund,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
              ),
              child: const Text(
                'Agregar',
                style: TextStyle(fontSize: 16, color: AppTheme.textWhite),
              ),
            ),
          ],
        ),
      ),
    );
  }
}