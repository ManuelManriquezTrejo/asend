import 'package:flutter/material.dart';
import 'package:asend/bank/services/fund_service.dart';
import 'package:asend/models/fund.dart';
import 'package:asend/bank/screens/add_fund_name_screen.dart';
import 'package:asend/bank/screens/add_amount_to_fund_screen.dart';
import 'package:asend/bank/screens/select_accounts_for_fund_screen.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/notification_dot.dart';

class SelectFundScreen extends StatefulWidget {
  final Function onFundAdded;

  const SelectFundScreen({super.key, required this.onFundAdded});

  @override
  State<SelectFundScreen> createState() => _SelectFundScreenState();
}

class _SelectFundScreenState extends State<SelectFundScreen> {
  void _refreshFunds() {
    // Verificar que el widget aún está montado
    if (mounted) {
      setState(() {
        // Redibuja para mostrar nuevos fondos
      });
    }
  }
  /// Un fondo que reparte a cuentas eliminadas no deja abonar.
  /// Ofrece modificarlo (cuentas y porcentajes) o eliminarlo.
  Future<void> _avisoFondoConProblema(Fund fund) async {
    final eliminadas = FundService.getCuentasEliminadas(fund.id)
        .map((fa) => AccountService.getAccountName(fa.accountId))
        .join(', ');

    final opcion = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Revisa "${fund.name}"',
          style: const TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          'Este fondo reparte a cuentas que ya no existen: $eliminadas.\n\n'
          'Para poder abonarle, modifica sus cuentas y porcentajes, '
          'o elimínalo.',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'eliminar'),
            child: const Text(
              'Eliminar fondo',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'modificar'),
            child: const Text('Modificar fondo'),
          ),
        ],
      ),
    );

    if (opcion == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (opcion == 'eliminar') {
      await FundService.deleteFund(fund.id);
      _refreshFunds();
      widget.onFundAdded();
      messenger.showSnackBar(
        SnackBar(content: Text('Fondo "${fund.name}" eliminado')),
      );
      return;
    }

    // Modificar: se cierra la lista de fondos y se abre la de cuentas
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (context) => SelectAccountsForFundScreen(
          fundName: fund.name,
          fundId: fund.id,
          onFundAdded: widget.onFundAdded,
        ),
      ),
    );
  }
  void _showDeleteFundDialog() {
    List<Fund> funds = FundService.getAllFunds();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Eliminar Fondo',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: funds.length,
              itemBuilder: (context, index) {
                Fund fund = funds[index];
                return ListTile(
                  title: Text(
                    fund.name,
                    style: const TextStyle(color: AppTheme.textWhite),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.danger),
                    onPressed: () async {
                      // Capturar antes del await
                      final messenger = ScaffoldMessenger.of(context);
                      final dialogNavigator = Navigator.of(context);

                      // Eliminar el fondo
                      await FundService.deleteFund(fund.id);

                      // Cerrar diálogo
                      dialogNavigator.pop();

                      // Refrescar la lista
                      _refreshFunds();

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Fondo "${fund.name}" eliminado'),
                          backgroundColor: AppTheme.danger,
                        ),
                      );
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

  @override
  Widget build(BuildContext context) {
    List<Fund> funds = FundService.getAllFunds();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppTheme.bgDarkGrey,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            const Text(
              'Fondos a agregar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.buttonPurple,
              ),
            ),
            const SizedBox(height: 20),

            // Lista de fondos o mensaje vacío
            if (funds.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No hay fondos creados',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: funds.length,
                  itemBuilder: (context, index) {
                    Fund fund = funds[index];
                    final conProblema = FundService.tieneCuentaEliminada(
                      fund.id,
                    );

                    return ListTile(
                      title: Text(
                        fund.name,
                        style: const TextStyle(color: AppTheme.textWhite),
                      ),
                      subtitle: conProblema
                          ? const Text(
                              'Tiene cuentas eliminadas',
                              style: TextStyle(
                                color: AppTheme.danger,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      trailing: NotificationDot(
                        visible: conProblema,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_forward,
                            color: AppTheme.buttonPurple,
                          ),
                        ),
                      ),
                      onTap: () {
                        if (conProblema) {
                          _avisoFondoConProblema(fund);
                          return;
                        }
                        Navigator.pop(context); // Cierra el modal
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddAmountToFundScreen(
                              fund: fund,
                              onAmountAdded: widget.onFundAdded,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // Botones: "Agregar Nuevo Fondo" y "Eliminar Fondo" (con Flexible)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddFundNameScreen(
                            onFundAdded: () {
                              _refreshFunds();
                              widget.onFundAdded();
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonPurple,
                    ),
                    child: const Text('Agregar Nuevo Fondo'),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: ElevatedButton(
                    onPressed: funds.isEmpty
                        ? null
                        : () => _showDeleteFundDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                    ),
                    child: const Text('Eliminar Fondo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
