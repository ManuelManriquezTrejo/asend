import 'package:asend/bank/screens/add_account_screen.dart';
import 'package:asend/bank/screens/edit_account_screen.dart';
import 'package:asend/bank/screens/movement_history_screen.dart';
import 'package:asend/bank/screens/new_debt_screen.dart';
import 'package:asend/bank/screens/pay_debt_screen.dart';
import 'package:asend/bank/screens/select_fund_screen.dart';
import 'package:asend/bank/screens/transfer_screen.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/bank/services/debt_service.dart';
import 'package:asend/bank/services/fund_service.dart';
import 'package:asend/models/account.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:asend/theme/notification_dot.dart';
import 'package:flutter/material.dart';

/// Pantalla principal de Banco: cuentas, recuadro de Deuda y los cuatro
/// botones de acciones. Todas las medidas son proporcionales a la
/// pantalla, para que se vea igual en un celular y en una tablet.
class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  static const List<String> _meses = [
    '',
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static const List<String> _mesesCortos = [
    '',
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  @override
  void initState() {
    super.initState();
    _refreshAccounts();
  }

  /// Crea las mensualidades de suscripción que falten y redibuja, para
  /// que el recuadro de Deuda siempre tenga los totales al día.
  Future<void> _refreshAccounts() async {
    await DebtService.generarSuscripciones();
    if (mounted) setState(() {});
  }

  String _dinero(double v) => '\$${v.toStringAsFixed(2)}';

  /// Abre una pantalla y refresca todo al volver.
  void _abrir(Widget pantalla) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pantalla),
    ).then((_) => _refreshAccounts());
  }

  // ── Cuentas ────────────────────────────────────────────

  Widget _buildAccountsList(Escala e) {
    List<Account> accounts = AccountService.getAllAccounts();
    if (accounts.isEmpty) {
      return Center(
        child: Text(
          'Aun no hay cuentas existentes',
          style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(4)),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: e.w(2)),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        Account account = accounts[index];
        return ListTile(
          title: Text(
            account.name,
            style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(4.2)),
          ),
          subtitle: Text(
            'Saldo: ${_dinero(account.balance)}',
            style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.5)),
          ),
          trailing: IconButton(
            icon: Icon(Icons.edit, color: AppTheme.textHint, size: e.t(5.5)),
            onPressed: () =>
                _abrir(EditAccountScreen(accountId: account.id)),
          ),
        );
      },
    );
  }

  // ── Recuadro de Deuda ──────────────────────────────────

  /// Recuadro con borde morado. No es un botón: solo sus dos botones
  /// de adentro responden al toque.
  Widget _recuadroDeuda(Escala e) {
    final hayPendientes = DebtService.getPendientes().isNotEmpty;
    final total = DebtService.deudaTotal();
    final delMes = DebtService.pagoDelMes();
    final proximo = DebtService.proximoPago();
    final hayPagoHoy = DebtService.hayPagoParaHoy();
    final mes = _meses[DateTime.now().month];

    return Container(
      margin: EdgeInsets.fromLTRB(e.w(4), e.h(1), e.w(4), e.h(1)),
      padding: EdgeInsets.symmetric(horizontal: e.w(4), vertical: e.h(1.5)),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkGrey,
        borderRadius: BorderRadius.circular(e.t(3)),
        border: Border.all(color: AppTheme.buttonPurple, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Deuda',
            style: TextStyle(
              color: AppTheme.buttonPurple,
              fontSize: e.t(5),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: e.h(1)),

          if (!hayPendientes)
            Text(
              'No tienes pagos pendientes',
              style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.8)),
            )
          else ...[
            _linea(e, 'Deuda total', _dinero(total)),
            // La línea del mes solo aparece si hay algo que pagar
            if (delMes > 0.005) _linea(e, 'Pago para $mes', _dinero(delMes)),
            if (proximo != null)
              _linea(
                e,
                'Próximo pago',
                '${_dinero(proximo.monto)} · ${proximo.fechaPago.day} '
                    '${_mesesCortos[proximo.fechaPago.month]}',
                rojo: DebtService.estaVencida(proximo),
              ),
          ],
          SizedBox(height: e.h(1.5)),

          Row(
            children: [
              // Pagar solo existe si hay pagos pendientes
              if (hayPendientes) ...[
                Flexible(
                  child: NotificationDot(
                    visible: hayPagoHoy,
                    tamano: e.t(3.5),
                    child: _botonDeuda(
                      e,
                      texto: 'Pagar',
                      color: AppTheme.success,
                      onPressed: () => _abrir(const PayDebtScreen()),
                    ),
                  ),
                ),
                SizedBox(width: e.w(4)),
              ],
              Flexible(
                child: _botonDeuda(
                  e,
                  texto: 'Nuevo pago',
                  color: AppTheme.successLight,
                  onPressed: () => _abrir(const NewDebtScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Un renglón del recuadro: texto a la izquierda y monto a la derecha.
  Widget _linea(Escala e, String texto, String valor, {bool rojo = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: e.h(0.4)),
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
            style: TextStyle(
              color: rojo ? AppTheme.danger : AppTheme.textWhite,
              fontSize: e.t(3.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonDeuda(
    Escala e, {
    required String texto,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: e.h(5.5),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(e.t(2.5)),
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(fontSize: e.t(3.9), fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Botones de abajo ───────────────────────────────────

  /// Botón redondo de solo icono para la barra de acciones.
  Widget _botonIcono(
    Escala e, {
    required IconData icono,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    final tamano = e.t(15);

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
          child: Icon(icono, color: AppTheme.textWhite, size: tamano * 0.45),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Banco')),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Título "Bienvenido a tu banco"
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: e.w(5),
                vertical: e.h(2),
              ),
              child: Text(
                'Bienvenido a tu banco',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.buttonPurple,
                  fontSize: e.t(6.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 2. Cuentas, con scroll si son varias
            Expanded(child: _buildAccountsList(e)),

            // 3. Recuadro de Deuda
            _recuadroDeuda(e),

            // 4. Fondos, historial, nueva cuenta y movimientos
            Padding(
              padding: EdgeInsets.fromLTRB(e.w(6), e.h(1), e.w(6), e.h(2)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Punto rojo si algún fondo reparte a una cuenta eliminada
                  NotificationDot(
                    visible: FundService.hayFondosConProblema(),
                    tamano: e.t(3.5),
                    child: _botonIcono(
                      e,
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
                    e,
                    icono: Icons.receipt_long,
                    tooltip: 'Historial de movimientos',
                    onPressed: () => _abrir(const MovementHistoryScreen()),
                  ),
                  _botonIcono(
                    e,
                    icono: Icons.add_card,
                    tooltip: 'Nueva cuenta',
                    onPressed: () => _abrir(
                      AddAccountScreen(onAccountAdded: _refreshAccounts),
                    ),
                  ),
                  _botonIcono(
                    e,
                    icono: Icons.swap_horiz,
                    tooltip: 'Movimientos entre cuentas',
                    onPressed: () => _abrir(const TransferScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}