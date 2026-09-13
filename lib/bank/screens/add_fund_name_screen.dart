import 'package:flutter/material.dart';
import 'package:asend/bank/screens/select_accounts_for_fund_screen.dart';
import 'package:asend/theme/app_theme.dart';

class AddFundNameScreen extends StatefulWidget {
  final Function onFundAdded;

  const AddFundNameScreen({super.key, required this.onFundAdded});

  @override
  State<AddFundNameScreen> createState() => _AddFundNameScreenState();
}

class _AddFundNameScreenState extends State<AddFundNameScreen> {
  final TextEditingController nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _continueToPlanDistribution() {
    // Validar que no esté vacío
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el nombre del fondo')),
      );
      return;
    }

    // Ir a la siguiente pantalla: Seleccionar cuentas
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectAccountsForFundScreen(
          fundName: nameController.text,
          onFundAdded: widget.onFundAdded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nuevo Fondo')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título
            const Text(
              'Nombre del Fondo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.buttonPurple,
              ),
            ),
            const SizedBox(height: 20),

            // Campo de texto para el nombre
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Ej: Sueldo, Trabajos, Prestamos',
              ),
            ),
            const SizedBox(height: 30),

            // Botón "Continuar"
            ElevatedButton(
              onPressed: _continueToPlanDistribution,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(fontSize: 16, color: AppTheme.textWhite),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
