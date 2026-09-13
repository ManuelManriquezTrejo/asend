import 'package:flutter/material.dart';
import 'package:asend/models/cash_out.dart';
import 'package:asend/models/account.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/cashout/services/cash_out_service.dart';
import 'package:asend/cashout/services/cash_out_config_service.dart';

class CashOutScreen extends StatefulWidget {
  const CashOutScreen({super.key});

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> {
  @override
  void initState() {
    super.initState();
    // Crear la config si es la primera vez
    CashOutConfigService.getConfig().then((_) {
      if (mounted) setState(() {});
    });
  }

  String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _aviso(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error ? AppTheme.danger : AppTheme.bgDarkGrey,
      ),
    );
  }

  /// Muestra las cuentas para elegir una
  Future<void> _seleccionarCuenta({required bool esPaga}) async {
    final cuentas = AccountService.getAllAccounts();

    if (cuentas.isEmpty) {
      _aviso('No hay cuentas creadas en el Banco', error: true);
      return;
    }

    final elegida = await showDialog<Account>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          esPaga
              ? 'Selecciona la cuenta que paga'
              : 'Selecciona la cuenta que recibe',
          style: const TextStyle(color: AppTheme.textWhite, fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cuentas.length,
            itemBuilder: (context, i) {
              final c = cuentas[i];
              return ListTile(
                title: Text(
                  c.name,
                  style: const TextStyle(color: AppTheme.textWhite),
                ),
                subtitle: Text(
                  'Saldo: ${c.balance}',
                  style: const TextStyle(color: AppTheme.textGrey),
                ),
                onTap: () => Navigator.pop(dialogContext, c),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (elegida == null) return;

    if (esPaga) {
      await CashOutConfigService.setCuentaPaga(elegida.id);
    } else {
      await CashOutConfigService.setCuentaRecibe(elegida.id);
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _cobrar(CashOut pago) async {
    final r = await CashOutService.cobrar(pago);
    if (!mounted) return;
    setState(() {});
    _aviso(r.mensaje, error: !r.ok);
  }

  Future<void> _cobrarTodo() async {
    final total = CashOutService.getTotalPendiente();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          '¿Cobrar todo?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          'Se cobrarán $total en total.',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Cobrar',
              style: TextStyle(color: AppTheme.success),
            ),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    final r = await CashOutService.cobrarTodo();
    if (!mounted) return;
    setState(() {});
    _aviso(r.mensaje, error: r.cobrados == 0);
  }

  Future<void> _eliminar(CashOut pago) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          '¿Eliminar pago?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          '"${pago.nombre}" de ${pago.cantidad} se eliminará sin cobrarse.',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    await CashOutService.eliminarPago(pago);
    if (!mounted) return;
    setState(() {});
  }

  Widget _botonCuenta({
    required String texto,
    required bool esPaga,
    required bool alineadoDerecha,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _seleccionarCuenta(esPaga: esPaga),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.bgDarkGrey,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.buttonPurple),
          ),
          child: Text(
            texto,
            textAlign: alineadoDerecha ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = CashOutService.getPendientes();
    final total = CashOutService.getTotalPendiente();
    final config = CashOutConfigService.getConfigSync();

    final cuentaPaga = config?.cuentaPagaId == null
        ? null
        : AccountService.getAccountById(config!.cuentaPagaId!);
    final cuentaRecibe = config?.cuentaRecibeId == null
        ? null
        : AccountService.getAccountById(config!.cuentaRecibeId!);

    return Scaffold(
      appBar: AppBar(title: const Text('Pagos'), centerTitle: true),
      body: Column(
        children: [
          // Selectores de cuenta
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _botonCuenta(
                  texto: cuentaPaga?.name ?? 'Cuenta que paga',
                  esPaga: true,
                  alineadoDerecha: false,
                ),
                const SizedBox(width: 12),
                _botonCuenta(
                  texto: cuentaRecibe == null
                      ? 'Cuenta que recibe'
                      : '${cuentaRecibe.balance}',
                  esPaga: false,
                  alineadoDerecha: true,
                ),
              ],
            ),
          ),

          // Lista de pendientes
          Expanded(
            child: pendientes.isEmpty
                ? const Center(
                    child: Text(
                      'No hay pagos pendientes',
                      style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pendientes.length,
                    itemBuilder: (context, i) {
                      final p = pendientes[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bgDarkGrey,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.buttonPurple.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              p.nombre,
                              style: const TextStyle(
                                color: AppTheme.textWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${_fecha(p.fecha)} · ${p.origen}',
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${p.cantidad}',
                                  style: const TextStyle(
                                    color: AppTheme.textWhite,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.attach_money,
                                    size: 20,
                                  ),
                                  color: AppTheme.success,
                                  tooltip: 'Cobrar',
                                  onPressed: () => _cobrar(p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  color: AppTheme.danger,
                                  tooltip: 'Eliminar',
                                  onPressed: () => _eliminar(p),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Total y cobrar todo
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).size.height * 0.02,
            ),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.bgDarkGrey, width: 2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total pendiente',
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                    ),
                    Text(
                      '$total',
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: pendientes.isEmpty ? null : _cobrarTodo,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      disabledBackgroundColor: AppTheme.disabled,
                    ),
                    child: const Text(
                      'Cobrar todo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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
}
