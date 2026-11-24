import 'package:asend/bank/screens/add_money_screen.dart';
import 'package:asend/bank/screens/distribute_fund_percentage_screen.dart';
import 'package:asend/bank/services/fund_service.dart';
import 'package:asend/bank/services/money_service.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Segunda parte de crear o modificar un fondo: a qué elementos de
/// Dinero va el dinero. Después se reparten sus porcentajes y se
/// guarda el fondo completo (Cuentas y Dinero).
class SelectMoneyForFundScreen extends StatefulWidget {
  final String fundName;
  final Function onFundAdded;

  /// Con un id, modifica ese fondo en lugar de crear uno nuevo.
  final int? fundId;

  /// Reparto a Cuentas ya elegido en la pantalla anterior.
  final Map<int, double> porcentajesCuentas;

  const SelectMoneyForFundScreen({
    super.key,
    required this.fundName,
    required this.onFundAdded,
    required this.porcentajesCuentas,
    this.fundId,
  });

  @override
  State<SelectMoneyForFundScreen> createState() =>
      _SelectMoneyForFundScreenState();
}

class _SelectMoneyForFundScreenState extends State<SelectMoneyForFundScreen> {
  final List<int> _seleccionados = [];

  @override
  void initState() {
    super.initState();

    // Al modificar, marcar los que ya tiene y siguen activos
    if (widget.fundId != null) {
      _seleccionados.addAll(
        FundService.getFundMoneyByFundId(widget.fundId!)
            .map((fm) => fm.moneyId)
            .where((id) => MoneyService.getById(id) != null),
      );
    }
  }

  void _continuar() {
    if (_seleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona mínimo 1')),
      );
      return;
    }

    // Porcentajes actuales del fondo, para arrancar con ellos
    final iniciales = <int, double>{};
    if (widget.fundId != null) {
      for (final fm in FundService.getFundMoneyByFundId(widget.fundId!)) {
        iniciales[fm.moneyId] = fm.percentage;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DistributeFundPercentageScreen(
          titulo: 'Distribuye "${widget.fundName}" en tu dinero',
          items: _seleccionados
              .map((id) => (id: id, nombre: MoneyService.getName(id)))
              .toList(),
          iniciales: iniciales,
          textoBoton: 'Guardar fondo',
          onListo: (porcentajesDinero) => _guardar(context, porcentajesDinero),
        ),
      ),
    );
  }

  /// Guarda el fondo y cierra todas las pantallas del proceso hasta
  /// volver a Banco.
  Future<void> _guardar(
    BuildContext contextReparto,
    Map<int, double> porcentajesDinero,
  ) async {
    final messenger = ScaffoldMessenger.of(contextReparto);
    final navigator = Navigator.of(contextReparto);

    if (widget.fundId == null) {
      await FundService.crearFondo(
        nombre: widget.fundName,
        cuentas: widget.porcentajesCuentas,
        dineros: porcentajesDinero,
      );
    } else {
      await FundService.modificarFondo(
        fundId: widget.fundId!,
        cuentas: widget.porcentajesCuentas,
        dineros: porcentajesDinero,
      );
    }

    widget.onFundAdded();

    // Pantallas abiertas: reparto a Dinero, esta, reparto a Cuentas y
    // elegir cuentas; al crear, también la del nombre
    final cerrar = widget.fundId == null ? 5 : 4;
    for (var i = 0; i < cerrar; i++) {
      navigator.pop();
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          widget.fundId == null
              ? 'Fondo "${widget.fundName}" creado'
              : 'Fondo "${widget.fundName}" actualizado',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dineros = MoneyService.getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Dinero')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              '¿En qué dinero va a quedar "${widget.fundName}"?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: dineros.isEmpty
                ? Center(
                    child: Text(
                      'Agrega dónde tienes tu dinero',
                      style: TextStyle(color: AppTheme.textGrey),
                    ),
                  )
                : ListView.builder(
                    itemCount: dineros.length,
                    itemBuilder: (context, index) {
                      final m = dineros[index];
                      final marcado = _seleccionados.contains(m.id);

                      return ListTile(
                        leading: Checkbox(
                          value: marcado,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _seleccionados.add(m.id);
                            } else {
                              _seleccionados.remove(m.id);
                            }
                          }),
                        ),
                        title: Text(m.name),
                        subtitle: Text(
                          m.tipo == MoneyService.efectivo
                              ? 'Efectivo'
                              : 'Digital',
                          style: TextStyle(color: AppTheme.textGrey),
                        ),
                        trailing: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: marcado
                                ? AppTheme.success
                                : AppTheme.disabled,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Crear un Dinero sin salir del proceso
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddMoneyScreen(),
                      ),
                    ).then((_) {
                      if (mounted) setState(() {});
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  child: const Text('Agregar Dinero'),
                ),
                ElevatedButton(
                  onPressed: _continuar,
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