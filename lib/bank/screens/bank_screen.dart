import 'package:asend/bank/screens/select_fund_screen.dart';
import 'package:asend/bank/screens/withdraw_screen.dart';
import 'package:asend/bank/screens/movement_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/bank/screens/add_account_screen.dart';
import 'package:asend/models/account.dart';
import 'package:asend/theme/app_theme.dart';

class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  void _refreshAccounts() {
    setState(() {
      // Esto redibuja la pantalla
    });
  }

  Widget _buildAccountsList() {
    List<Account> accounts = AccountService.getAllAccounts();
    if (accounts.isEmpty) {
      return const Center(child: Text('Aun no hay cuentas existentes'));
    }
    return ListView.builder(
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        Account account = accounts[index];
        return ListTile(
          title: Text(account.name),
          trailing: Text('Saldo: \$${account.balance.toStringAsFixed(2)}'),
        );
      },
    );
  }

  /// Botón redondo de solo icono para la barra de acciones.
  Widget _botonIcono({
    required IconData icono,
    required VoidCallback onPressed,
    required String tooltip,
    Color color = AppTheme.buttonPurple,
    double tamano = 52,
  }) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: tamano,
        height: tamano,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: Icon(
            icono,
            color: AppTheme.textWhite,
            size: tamano * 0.45,
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    List<Account> accounts = AccountService.getAllAccounts();

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cuentas para eliminar')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Eliminar Cuenta',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                Account account = accounts[index];
                return ListTile(
                  title: Text(
                    account.name,
                    style: const TextStyle(color: AppTheme.textWhite),
                  ),
                  subtitle: Text(
                    'Saldo: \$${account.balance.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppTheme.textGrey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.danger),
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(account);
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonPurple,
              ),
              child: const Text(
                'Cerrar',
                style: TextStyle(color: AppTheme.textWhite),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Account account) {
    String message = account.balance == 0
        ? '¿Seguro que quieres eliminar la cuenta "${account.name}"?'
        : '¿Seguro que quieres eliminar la cuenta "${account.name}"?\nTiene un saldo de \$${account.balance.toStringAsFixed(2)}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirmar Eliminación',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: AppTheme.textGrey),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonPurple,
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.textWhite),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Capturar antes del await: después del pop este
                // context ya no sirve para buscar el messenger.
                final messenger = ScaffoldMessenger.of(context);
                final dialogNavigator = Navigator.of(context);

                await AccountService.deleteAccount(account.id);

                dialogNavigator.pop();

                if (!mounted) return;
                _refreshAccounts();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Cuenta "${account.name}" eliminada'),
                    backgroundColor: AppTheme.danger,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: AppTheme.textWhite),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banco')),
      body: Column(
        children: [
          // Título: "Bienvenido a tu banco"
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Bienvenido a tu banco',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.buttonPurple,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Lista de cuentas
          Expanded(child: _buildAccountsList()),
          // Acciones: fondos y retirar a la izquierda, historial al centro,
          // cuentas a la derecha
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Columna izquierda: agregar fondos y retirar
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _botonIcono(
                      icono: Icons.savings,
                      tooltip: 'Agregar fondos',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              SelectFundScreen(onFundAdded: _refreshAccounts),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _botonIcono(
                      icono: Icons.arrow_outward,
                      tooltip: 'Retirar',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WithdrawScreen(
                              onWithdrawn: _refreshAccounts,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Centro: historial, más grande
                _botonIcono(
                  icono: Icons.receipt_long,
                  tooltip: 'Historial de movimientos',
                  tamano: 70,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MovementHistoryScreen(),
                      ),
                    );
                  },
                ),

                // Columna derecha: agregar y eliminar cuenta
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _botonIcono(
                      icono: Icons.account_balance_wallet,
                      tooltip: 'Agregar cuenta',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddAccountScreen(
                              onAccountAdded: _refreshAccounts,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _botonIcono(
                      icono: Icons.delete,
                      tooltip: 'Eliminar cuenta',
                      color: AppTheme.danger,
                      onPressed: () => _showDeleteAccountDialog(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}