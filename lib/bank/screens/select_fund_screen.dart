import 'package:flutter/material.dart';
import 'package:asend/bank/services/fund_service.dart';
import 'package:asend/models/fund.dart';
import 'package:asend/bank/screens/add_fund_name_screen.dart';
import 'package:asend/bank/screens/add_amount_to_fund_screen.dart';
import 'package:asend/bank/screens/select_accounts_for_fund_screen.dart';
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

  /// Un fondo con problema (cuentas o Dinero eliminados, o sin reparto
  /// a Dinero) no deja abonar. Ofrece modificarlo o eliminarlo.
  Future<void> _avisoFondoConProblema(Fund fund) async {
    final motivo = FundService.motivoProblema(fund.id) ?? '';

    final opcion = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Revisa "${fund.name}"',
          style: const TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          '$motivo.\n\n'
          'Para poder abonarle, modifica sus cuentas, su dinero y sus '
          'porcentajes, o elimínalo.',
          style: TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
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

    if (opcion == 'eliminar') {
      await FundService.deleteFund(fund.id);
      _refreshFunds();
      widget.onFundAdded();
      messenger.showSnackBar(
        SnackBar(content: Text('Fondo "${fund.name}" eliminado')),
      );
      return;
    }

    _abrirModificar(fund);
  }

  /// Cierra la lista de fondos y abre la elección de cuentas y
  /// porcentajes de ese fondo, ya con sus valores actuales.
  void _abrirModificar(Fund fund) {
    final navigator = Navigator.of(context);

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

  /// Pide el nombre nuevo de un fondo y lo guarda.
  Future<void> _renombrarFondo(Fund fund) async {
    final controlador = TextEditingController(text: fund.name);
    String? error;
    bool hecho = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Cambiar nombre',
            style: TextStyle(color: AppTheme.textWhite),
          ),
          content: TextField(
            controller: controlador,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: InputDecoration(errorText: error),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);

                final mensaje = await FundService.renombrarFondo(
                  fundId: fund.id,
                  nombre: controlador.text,
                );

                if (mensaje != null) {
                  setDialogState(() => error = mensaje);
                  return;
                }

                hecho = true;
                navigator.pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    // El TextField sigue usando el controlador durante la animación
    // de cierre; liberarlo antes rompe el árbol de widgets
    await Future.delayed(const Duration(milliseconds: 300));
    controlador.dispose();

    if (!mounted || !hecho) return;
    _refreshFunds();
    widget.onFundAdded();
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
                backgroundColor: AppTheme.primary,
              ),
              child: Text(
                'Cerrar',
                style: TextStyle(color: AppTheme.onPrimary),
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
            Text(
              'Fondos a agregar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Lista de fondos o mensaje vacío
            if (funds.isEmpty)
              Padding(
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
                    final motivo = FundService.motivoProblema(fund.id);
                    final conProblema = motivo != null;

                    return ListTile(
                      title: Text(
                        fund.name,
                        style: const TextStyle(color: AppTheme.textWhite),
                      ),
                      subtitle: conProblema
                          ? Text(
                              motivo,
                              style: const TextStyle(
                                color: AppTheme.danger,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      // Lápiz con dos opciones: nombre, o cuentas y
                      // porcentajes. Tocar el nombre sigue abriendo abonar.
                      trailing: NotificationDot(
                        visible: conProblema,
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.edit,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          color: AppTheme.bgDarkGrey,
                          onSelected: (opcion) {
                            if (opcion == 'nombre') {
                              _renombrarFondo(fund);
                            } else {
                              _abrirModificar(fund);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'nombre',
                              child: Text(
                                'Cambiar nombre',
                                style: TextStyle(color: AppTheme.textWhite),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'cuentas',
                              child: Text(
                                'Cuentas, dinero y porcentajes',
                                style: TextStyle(color: AppTheme.textWhite),
                              ),
                            ),
                          ],
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
                      backgroundColor: AppTheme.primary,
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