import 'package:flutter/material.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/bank/services/fund_service.dart';
import 'package:asend/bank/screens/add_account_screen.dart';
import 'package:asend/models/account.dart';
import 'package:asend/bank/screens/distribute_fund_percentage_screen.dart';
import 'package:asend/bank/screens/select_money_for_fund_screen.dart';
import 'package:asend/theme/app_theme.dart';

class SelectAccountsForFundScreen extends StatefulWidget {
  final String fundName;
  final Function onFundAdded;

  /// Con un id, modifica ese fondo en lugar de crear uno nuevo.
  final int? fundId;

  const SelectAccountsForFundScreen({
    super.key,
    required this.fundName,
    required this.onFundAdded,
    this.fundId,
  });

  @override
  State<SelectAccountsForFundScreen> createState() =>
      _SelectAccountsForFundScreenState();
}

class _SelectAccountsForFundScreenState
    extends State<SelectAccountsForFundScreen> {
  // Lista para guardar los IDs de las cuentas seleccionadas
  List<int> selectedAccountIds = [];

  @override
  void initState() {
    super.initState();

    // Al modificar un fondo, marcar las cuentas que ya tiene y siguen
    // activas. Las eliminadas se quedan fuera.
    if (widget.fundId != null) {
      selectedAccountIds = FundService.getFundAccountsByFundId(widget.fundId!)
          .map((fa) => fa.accountId)
          .where((id) => AccountService.getAccountById(id) != null)
          .toList();
    }
  }

  // Función para refrescar la pantalla cuando se agrega una nueva cuenta
  void _refreshAccounts() {
    setState(() {
      // Redibuja la pantalla para mostrar la nueva cuenta
    });
  }

  // Función que se ejecuta cuando presiona "Continuar"
  void _goToDistributionScreen() {
    // Validar que mínimo hay 1 cuenta seleccionada
    if (selectedAccountIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona mínimo 1 cuenta')),
      );
      return;
    }

    // Porcentajes actuales del fondo, para arrancar con ellos
    final iniciales = <int, double>{};
    if (widget.fundId != null) {
      for (final fa in FundService.getFundAccountsByFundId(widget.fundId!)) {
        iniciales[fa.accountId] = fa.percentage;
      }
    }

    // Repartir entre las cuentas y después elegir el Dinero
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DistributeFundPercentageScreen(
          titulo: 'Distribuye "${widget.fundName}" entre las cuentas',
          items: selectedAccountIds
              .map((id) => (id: id, nombre: AccountService.getAccountName(id)))
              .toList(),
          iniciales: iniciales,
          textoBoton: 'Continuar',
          onListo: (porcentajesCuentas) async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SelectMoneyForFundScreen(
                  fundName: widget.fundName,
                  fundId: widget.fundId,
                  porcentajesCuentas: porcentajesCuentas,
                  onFundAdded: widget.onFundAdded,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtener todas las cuentas de la base de datos
    List<Account> accounts = AccountService.getCuentasMovibles();
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Cuentas')),
      body: Column(
        children: [
          // Título: pregunta a qué cuentas se agrega el fondo
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              '¿A qué cuentas se va a agregar "${widget.fundName}"?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Lista de cuentas con checkboxes para seleccionar
          Expanded(
            child: accounts.isEmpty
                ? const Center(child: Text('No hay cuentas disponibles'))
                : ListView.builder(
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      Account account = accounts[index];
                      // Verificar si esta cuenta está seleccionada
                      bool isSelected = selectedAccountIds.contains(account.id);

                      return ListTile(
                        // Checkbox a la izquierda
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              // Agregar o remover el ID de la lista
                              if (value == true) {
                                selectedAccountIds.add(account.id);
                              } else {
                                selectedAccountIds.remove(account.id);
                              }
                            });
                          },
                        ),
                        // Nombre de la cuenta
                        title: Text(account.name),
                        // Círculo verde si está seleccionada, gris si no
                        trailing: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppTheme.success
                                : AppTheme.disabled,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Botones: "Agregar Cuenta" y "Continuar"
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón para agregar una nueva cuenta (sin cerrar esta pantalla)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddAccountScreen(onAccountAdded: _refreshAccounts),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  child: const Text('Agregar Cuenta'),
                ),
                // Botón para ir a la pantalla de distribuir porcentajes
                ElevatedButton(
                  onPressed: _goToDistributionScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
