import 'package:asend/bank/screens/add_account_screen.dart';
import 'package:asend/bank/screens/edit_account_screen.dart';
import 'package:asend/bank/screens/movement_history_screen.dart';
import 'package:asend/bank/screens/select_fund_screen.dart';
import 'package:asend/bank/screens/transfer_screen.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/bank/services/fund_service.dart';
import 'package:asend/models/account.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/notification_dot.dart';
import 'package:flutter/material.dart';

class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  void _refreshAccounts() {
    if (mounted) setState(() {});
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
          subtitle: Text('Saldo: \$${account.balance.toStringAsFixed(2)}'),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.textHint, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditAccountScreen(accountId: account.id),
                ),
              ).then((_) => _refreshAccounts());
            },
          ),
        );
      },
    );
  }

  /// Botón redondo de solo icono para la barra de acciones.
  Widget _botonIcono({
    required IconData icono,
    required VoidCallback onPressed,
    required String tooltip,
    double tamano = 56,
  }) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: tamano,
        height: tamano,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.buttonPurple,
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

  /// Abre una pantalla y refresca las cuentas al volver.
  void _abrir(Widget pantalla) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pantalla),
    ).then((_) => _refreshAccounts());
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
          // Lista de cuentas, cada una con su lápiz
          Expanded(child: _buildAccountsList()),
          // Acciones: fondos, historial, nueva cuenta y movimientos
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Punto rojo si algún fondo reparte a una cuenta eliminada
                NotificationDot(
                  visible: FundService.hayFondosConProblema(),
                  tamano: 14,
                  child: _botonIcono(
                    icono: Icons.savings,
                    tooltip: 'Fondos',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            SelectFundScreen(onFundAdded: _refreshAccounts),
                      ).then((_) => _refreshAccounts());
                    },
                  ),
                ),
                _botonIcono(
                  icono: Icons.receipt_long,
                  tooltip: 'Historial de movimientos',
                  onPressed: () => _abrir(const MovementHistoryScreen()),
                ),
                _botonIcono(
                  icono: Icons.add_card,
                  tooltip: 'Nueva cuenta',
                  onPressed: () => _abrir(
                    AddAccountScreen(onAccountAdded: _refreshAccounts),
                  ),
                ),
                _botonIcono(
                  icono: Icons.swap_horiz,
                  tooltip: 'Movimientos entre cuentas',
                  onPressed: () => _abrir(const TransferScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}