import 'package:asend/bank/screens/add_account_screen.dart';
import 'package:asend/bank/screens/add_money_screen.dart';
import 'package:asend/bank/screens/edit_account_screen.dart';
import 'package:asend/bank/screens/edit_money_screen.dart';
import 'package:asend/bank/screens/movement_history_screen.dart';
import 'package:asend/bank/screens/new_debt_screen.dart';
import 'package:asend/bank/screens/pay_debt_screen.dart';
import 'package:asend/bank/screens/reconciliations_screen.dart';
import 'package:asend/bank/screens/select_fund_screen.dart';
import 'package:asend/bank/screens/transfer_screen.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/bank/services/debt_service.dart';
import 'package:asend/bank/services/fund_service.dart';
import 'package:asend/bank/services/money_service.dart';
import 'package:asend/bank/services/reconciliation_service.dart';
import 'package:asend/models/account.dart';
import 'package:asend/models/money_account.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:asend/theme/notification_dot.dart';
import 'package:flutter/material.dart';

/// Pantalla principal de Banco: tarjetas plegables de Cuentas, Dinero y
/// Deuda, y abajo los botones de acciones. Todas las medidas son
/// proporcionales a la pantalla, para que se vea igual en un celular y
/// en una tablet.
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
  /// que la tarjeta de Deuda siempre tenga los totales al día.
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

  // ── Tarjetas plegables ─────────────────────────────────

  /// Si cada tarjeta está abierta. Todas empiezan abiertas cada vez
  /// que se entra a Banco.
  bool _cuentasAbierta = true;
  bool _dineroAbierta = true;
  bool _deudaAbierta = true;

  /// Tarjeta con borde morado y encabezado que se toca para abrirla o
  /// cerrarla. Abierta, ocupa su parte del espacio libre (las abiertas
  /// se reparten la pantalla por igual). Cerrada, solo deja el
  /// encabezado. [accion] es un botón opcional junto a la flecha.
  Widget _tarjeta(
    Escala e, {
    required String titulo,
    required bool abierta,
    required VoidCallback onToggle,
    required Widget contenido,
    Widget? accion,
  }) {
    final tarjeta = Container(
      margin: EdgeInsets.fromLTRB(e.w(4), e.h(0.6), e.w(4), e.h(0.6)),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkGrey,
        borderRadius: BorderRadius.circular(e.t(3)),
        border: Border.all(color: AppTheme.primary, width: 2),
      ),
      child: Column(
        children: [
          // Encabezado: título, acción opcional y flecha
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(e.t(3)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(e.w(4), e.h(1), e.w(2), e.h(1)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: e.t(5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ?accion,
                  Icon(
                    abierta ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.primary,
                    size: e.t(7),
                  ),
                ],
              ),
            ),
          ),
          if (abierta) Expanded(child: contenido),
        ],
      ),
    );

    return abierta ? Expanded(child: tarjeta) : tarjeta;
  }

  // ── Cuentas ────────────────────────────────────────────

  /// Quita acentos y pasa a minúsculas, para que "Ábaco" quede junto a
  /// "abono" al ordenar y no hasta el final.
  String _claveOrden(String texto) {
    const conAcento = 'áéíóúüñ';
    const sinAcento = 'aeiouun';
    final buffer = StringBuffer();
    for (final letra in texto.toLowerCase().split('')) {
      final i = conAcento.indexOf(letra);
      buffer.write(i == -1 ? letra : sinAcento[i]);
    }
    return buffer.toString();
  }

  /// Cuentas activas en orden alfabético.
  List<Account> _cuentasOrdenadas() {
    final accounts = AccountService.getAllAccounts();
    accounts.sort(
      (a, b) => _claveOrden(a.name).compareTo(_claveOrden(b.name)),
    );
    return accounts;
  }

  Widget _tarjetaCuentas(Escala e, List<Account> accounts) {
    return _tarjeta(
      e,
      titulo: 'Cuentas (${accounts.length})',
      abierta: _cuentasAbierta,
      onToggle: () => setState(() => _cuentasAbierta = !_cuentasAbierta),
      accion: IconButton(
        icon: Icon(Icons.add_card, color: AppTheme.textWhite, size: e.t(6)),
        tooltip: 'Nueva cuenta',
        onPressed: () =>
            _abrir(AddAccountScreen(onAccountAdded: _refreshAccounts)),
      ),
      contenido: _buildAccountsList(e, accounts),
    );
  }

  Widget _buildAccountsList(Escala e, List<Account> accounts) {
    if (accounts.isEmpty) {
      return Center(
        child: Text(
          'Aun no hay cuentas existentes',
          style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(4)),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: e.w(1)),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        Account account = accounts[index];
        final esMetas = AccountService.esCuentaMetas(account.id);

        final renglon = ListTile(
          dense: true,
          // La cuenta Metas lleva icono de bandera para distinguirla
          leading: esMetas
              ? Icon(Icons.flag, color: AppTheme.primary, size: e.t(6))
              : null,
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

        if (!esMetas) return renglon;

        // Metas va dentro de un recuadro del color del tema
        return Container(
          margin: EdgeInsets.symmetric(horizontal: e.w(2), vertical: e.h(0.5)),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(e.t(2.5)),
            border: Border.all(color: AppTheme.primary, width: 1.5),
          ),
          child: renglon,
        );
      },
    );
  }

  // ── Dinero ─────────────────────────────────────────────

  /// Encabezado con el total de los marcados. Adentro, una línea con
  /// lo que hay en efectivo y en digital (también solo de los marcados)
  /// y la lista con su casilla y su lápiz.
  Widget _tarjetaDinero(Escala e) {
    final lista = MoneyService.getAll();
    final total = MoneyService.totalSeleccionado();

    return _tarjeta(
      e,
      titulo: 'Dinero (${_dinero(total)})',
      abierta: _dineroAbierta,
      onToggle: () => setState(() => _dineroAbierta = !_dineroAbierta),
      accion: IconButton(
        icon: Icon(Icons.add, color: AppTheme.textWhite, size: e.t(6)),
        tooltip: 'Nuevo dinero',
        onPressed: () => _abrir(const AddMoneyScreen()),
      ),
      contenido: _contenidoDinero(e, lista),
    );
  }

  Widget _contenidoDinero(Escala e, List<MoneyAccount> lista) {
    if (lista.isEmpty) {
      return Center(
        child: Text(
          'Agrega dónde tienes tu dinero',
          style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(4)),
        ),
      );
    }

    final efectivo = MoneyService.totalSeleccionadoDeTipo(
      MoneyService.efectivo,
    );
    final digital = MoneyService.totalSeleccionadoDeTipo(MoneyService.digital);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: e.w(4)),
          child: Row(
            children: [
              Icon(Icons.payments, color: AppTheme.textGrey, size: e.t(4.5)),
              SizedBox(width: e.w(1.5)),
              Text(
                _dinero(efectivo),
                style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.6)),
              ),
              const Spacer(),
              Icon(
                Icons.credit_card,
                color: AppTheme.textGrey,
                size: e.t(4.5),
              ),
              SizedBox(width: e.w(1.5)),
              Text(
                _dinero(digital),
                style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.6)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: e.w(1)),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final m = lista[index];
              final esEfectivo = m.tipo == MoneyService.efectivo;

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.only(left: 0, right: e.w(2)),
                // La casilla decide si entra en el total de arriba
                leading: Checkbox(
                  value: m.seleccionada,
                  activeColor: AppTheme.primary,
                  onChanged: (_) async {
                    await MoneyService.alternarSeleccion(m.id);
                    if (mounted) setState(() {});
                  },
                ),
                title: Row(
                  children: [
                    Icon(
                      esEfectivo ? Icons.payments : Icons.credit_card,
                      color: AppTheme.textHint,
                      size: e.t(4.5),
                    ),
                    SizedBox(width: e.w(2)),
                    Expanded(
                      child: Text(
                        m.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: m.seleccionada
                              ? AppTheme.textWhite
                              : AppTheme.textGrey,
                          fontSize: e.t(4.2),
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Saldo: ${_dinero(m.balance)}',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: e.t(3.5),
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: AppTheme.textHint,
                    size: e.t(5.5),
                  ),
                  onPressed: () => _abrir(EditMoneyScreen(moneyId: m.id)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Deuda ──────────────────────────────────────────────

  Widget _tarjetaDeuda(Escala e) {
    return _tarjeta(
      e,
      titulo: 'Deuda',
      abierta: _deudaAbierta,
      onToggle: () => setState(() => _deudaAbierta = !_deudaAbierta),
      contenido: _contenidoDeuda(e),
    );
  }

  /// Totales de deuda arriba (con scroll si no caben) y los botones
  /// Pagar y Nuevo pago siempre visibles abajo.
  Widget _contenidoDeuda(Escala e) {
    final hayPendientes = DebtService.getPendientes().isNotEmpty;
    final total = DebtService.deudaTotal();
    final delMes = DebtService.pagoDelMes();
    final proximo = DebtService.proximoPago();
    final hayPagoHoy = DebtService.hayPagoParaHoy();
    final mes = _meses[DateTime.now().month];

    return Padding(
      padding: EdgeInsets.fromLTRB(e.w(4), 0, e.w(4), e.h(1.5)),
      child: Column(
        children: [
          Expanded(
            child: hayPendientes
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        _linea(e, 'Deuda total', _dinero(total)),
                        // La línea del mes solo aparece si hay algo que pagar
                        if (delMes > 0.005)
                          _linea(e, 'Pago para $mes', _dinero(delMes)),
                        if (proximo != null)
                          _linea(
                            e,
                            'Próximo pago',
                            '${_dinero(proximo.monto)} · '
                                '${proximo.fechaPago.day} '
                                '${_mesesCortos[proximo.fechaPago.month]}',
                            rojo: DebtService.estaVencida(proximo),
                          ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'No tienes pagos pendientes',
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: e.t(3.8),
                      ),
                    ),
                  ),
          ),
          SizedBox(height: e.h(1)),
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

  /// Un renglón de la tarjeta: texto a la izquierda y monto a la derecha.
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
          foregroundColor: AppTheme.textBlack,
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
            backgroundColor: AppTheme.primary,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: Icon(icono, color: AppTheme.onPrimary, size: tamano * 0.45),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    final accounts = _cuentasOrdenadas();

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
                  color: AppTheme.primary,
                  fontSize: e.t(6.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 2. Tarjetas plegables. Si todas están cerradas, el
            // espacio libre queda arriba de los botones.
            _tarjetaCuentas(e, accounts),
            _tarjetaDinero(e),
            _tarjetaDeuda(e),
            if (!_cuentasAbierta && !_dineroAbierta && !_deudaAbierta)
              const Spacer(),

            // 3. Fondos, historial y movimientos
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
                    icono: Icons.swap_horiz,
                    tooltip: 'Movimientos entre cuentas',
                    onPressed: () => _abrir(const TransferScreen()),
                  ),
                                    // Punto rojo si algún cuadre tiene diferencia
                  NotificationDot(
                    visible: ReconciliationService.hayDiferencias(),
                    tamano: e.t(3.5),
                    child: _botonIcono(
                      e,
                      icono: Icons.balance,
                      tooltip: 'Cuadres',
                      onPressed: () => _abrir(const ReconciliationsScreen()),
                    ),
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