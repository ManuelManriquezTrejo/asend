import 'package:asend/bank/screens/edit_reconciliation_screen.dart';
import 'package:asend/bank/services/reconciliation_service.dart';
import 'package:asend/models/reconciliation.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:asend/theme/notification_dot.dart';
import 'package:flutter/material.dart';

/// Lista de cuadres. Cada uno muestra cuánto suman sus cuentas, cuánto
/// su Dinero y la diferencia: verde si el Dinero tiene más, rojo si
/// las Cuentas tienen más. Desde aquí se crean y se editan.
class ReconciliationsScreen extends StatefulWidget {
  const ReconciliationsScreen({super.key});

  @override
  State<ReconciliationsScreen> createState() => _ReconciliationsScreenState();
}

class _ReconciliationsScreenState extends State<ReconciliationsScreen> {
  String _dinero(double v) => '\$${v.toStringAsFixed(2)}';

  /// Abre crear (sin id) o editar (con id) y redibuja al volver.
  void _abrir({int? id}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReconciliationScreen(reconciliationId: id),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    final cuadres = ReconciliationService.getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Cuadres')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: cuadres.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: e.w(10)),
                        child: Text(
                          'Crea un cuadre para comparar tus cuentas '
                          'contra tu dinero',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: e.t(4),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(e.w(4)),
                      itemCount: cuadres.length,
                      itemBuilder: (context, i) => _tarjeta(e, cuadres[i]),
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(e.w(5), e.h(1), e.w(5), e.h(2)),
              child: SizedBox(
                width: double.infinity,
                height: e.h(6.5),
                child: ElevatedButton.icon(
                  onPressed: () => _abrir(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.buttonPurple,
                  ),
                  icon: Icon(
                    Icons.add,
                    color: AppTheme.textWhite,
                    size: e.t(5.5),
                  ),
                  label: Text(
                    'Nuevo cuadre',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: e.t(4.2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Un cuadre: nombre y lápiz, los dos totales y la diferencia.
  Widget _tarjeta(Escala e, Reconciliation c) {
    final cuentas = ReconciliationService.totalCuentas(c);
    final dinero = ReconciliationService.totalDinero(c);
    final dif = ReconciliationService.diferencia(c);
    final hayDif = ReconciliationService.tieneDiferencia(c);

    final String textoDif;
    final Color colorDif;
    if (!hayDif) {
      textoDif = '✓ Cuadra';
      colorDif = AppTheme.textGrey;
    } else if (dif > 0) {
      textoDif = 'Dinero tiene ${_dinero(dif)} más';
      colorDif = AppTheme.success;
    } else {
      textoDif = 'Cuentas tiene ${_dinero(-dif)} más';
      colorDif = AppTheme.danger;
    }

    return Container(
      margin: EdgeInsets.only(bottom: e.h(1.5)),
      padding: EdgeInsets.fromLTRB(e.w(4), e.h(0.5), e.w(1), e.h(1.5)),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkGrey,
        borderRadius: BorderRadius.circular(e.t(3)),
        border: Border.all(
          color: hayDif ? colorDif : AppTheme.buttonPurple,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: NotificationDot(
                  visible: hayDif,
                  tamano: e.t(3),
                  child: Padding(
                    // Espacio para que el punto no tape el nombre
                    padding: EdgeInsets.only(right: e.w(4)),
                    child: Text(
                      c.nombre,
                      style: TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: e.t(4.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: AppTheme.textHint,
                  size: e.t(5.5),
                ),
                onPressed: () => _abrir(id: c.id),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(right: e.w(3)),
            child: Column(
              children: [
                _linea(e, 'Cuentas (${c.accountIds.length})', _dinero(cuentas)),
                _linea(e, 'Dinero (${c.moneyIds.length})', _dinero(dinero)),
                SizedBox(height: e.h(0.8)),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    textoDif,
                    style: TextStyle(
                      color: colorDif,
                      fontSize: e.t(4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linea(Escala e, String texto, String valor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: e.h(0.3)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.8)),
            ),
          ),
          Text(
            valor,
            style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(3.9)),
          ),
        ],
      ),
    );
  }
}