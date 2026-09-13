import 'package:flutter/material.dart';
import 'package:asend/bank/services/fund_service.dart';
import 'package:asend/models/fund.dart';
import 'package:asend/bank/screens/add_fund_name_screen.dart';
import 'package:asend/bank/screens/add_amount_to_fund_screen.dart';
import 'package:asend/theme/app_theme.dart';

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
                    return ListTile(
                      title: Text(
                        fund.name,
                        style: const TextStyle(color: AppTheme.textWhite),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward,
                        color: AppTheme.buttonPurple,
                      ),
                      onTap: () {
                        Navigator.pop(context); // Cierra el modal
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddAmountToFundScreen(
                              fund: fund,
                              onAmountAdded: _refreshFunds,
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
