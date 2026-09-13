import 'package:flutter/material.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/theme/app_theme.dart';

class AddAccountScreen extends StatefulWidget {
  final Function onAccountAdded;

  const AddAccountScreen({super.key, required this.onAccountAdded});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  void _saveAccount() async {
    // Validar que no estén vacíos
    if (nameController.text.isEmpty || balanceController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Llena todos los campos')));
      return;
    }

    // Capturar antes del await: al cerrar la pantalla, este context
    // se desconecta del árbol y ya no encuentra messenger ni navigator.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      double balance = double.parse(balanceController.text);

      // Guardar la cuenta usando AccountService
      await AccountService.addAccount(
        name: nameController.text,
        balance: balance,
      );

      // Llamar la función callback para actualizar la lista
      widget.onAccountAdded();

      // Volver a la pantalla anterior
      navigator.pop();

      messenger.showSnackBar(
        const SnackBar(content: Text('Cuenta agregada correctamente')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Campo: Nombre de la cuenta
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la cuenta',
                hintText: 'Ej: Para gastar',
              ),
            ),
            const SizedBox(height: 20),

            // Campo: Saldo inicial
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Saldo inicial',
                hintText: 'Ej: 1000',
              ),
            ),
            const SizedBox(height: 30),

            // Botón: Guardar
            ElevatedButton(
              onPressed: _saveAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
              ),
              child: const Text(
                'Guardar Cuenta',
                style: TextStyle(fontSize: 16, color: AppTheme.textWhite),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
