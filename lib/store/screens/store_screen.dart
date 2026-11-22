import 'package:asend/bank/services/account_service.dart';
import 'package:asend/bank/services/money_service.dart';
import 'package:asend/goals/screens/goals_screen.dart';
import 'package:asend/models/account.dart';
import 'package:asend/models/money_account.dart';
import 'package:asend/models/purchase.dart';
import 'package:asend/store/services/purchase_service.dart';
import 'package:asend/store/screens/purchase_history_screen.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lo que devuelve el formulario de compra.
/// Con nombre propio para evitar la ambigüedad de parseo que provoca
/// un tipo record puesto directamente como argumento de tipo.
typedef _DatosCompra = ({
  String nombre,
  int precio,
  String? nota,
  int accountId,
  int? moneyId,
});

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  void _aviso(String mensaje, {bool esError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? AppTheme.danger : AppTheme.success,
      ),
    );
  }

  /// Formulario de compra. Sirve para agregar y para editar.
  /// Devuelve (nombre, precio, nota, accountId, moneyId) o null si
  /// cancela. moneyId es null solo al editar una compra sin método.
  Future<_DatosCompra?> _formulario({
    required String titulo,
    Purchase? compra,
  }) async {
    final cuentas = AccountService.getCuentasMovibles();
    // Al editar, la cuenta de la compra debe aparecer en la lista aunque
    // haya sido eliminada de Banco; si no, el desplegable quedaría con un
    // valor que no existe entre sus opciones y Flutter lanza excepción.
    if (compra != null && !cuentas.any((c) => c.id == compra.accountId)) {
      final vieja = AccountService.getAccountByIdIncluyendoEliminadas(
        compra.accountId,
      );
      if (vieja != null) cuentas.insert(0, vieja);
    }

    // Las compras de antes de Dinero no tienen método y no se les pide
    final pideMetodo = compra == null || compra.moneyId != null;

    final dineros = MoneyService.getAll();

    // Igual que con la cuenta: si el método de la compra fue eliminado,
    // se agrega a la lista para que el desplegable tenga ese valor
    if (compra?.moneyId != null &&
        !dineros.any((m) => m.id == compra!.moneyId)) {
      final vieja = MoneyService.getByIdIncluyendoEliminados(compra!.moneyId!);
      if (vieja != null) dineros.insert(0, vieja);
    }

    final nombreCtrl = TextEditingController(text: compra?.nombre ?? '');
    final precioCtrl = TextEditingController(
      text: compra == null ? '' : '${compra.precio}',
    );
    final notaCtrl = TextEditingController(text: compra?.nota ?? '');

    // Al editar, la cuenta de la compra; al agregar, la preseleccionada
    int cuentaId =
        compra?.accountId ?? PurchaseService.getCuentaPreseleccionada()!;

    // Al editar, el método de la compra; al agregar, el último usado
    int? metodoId = pideMetodo
        ? (compra?.moneyId ?? MoneyService.getUltimoId(MoneyService.enTienda))
        : null;

    final resultado = await showDialog<_DatosCompra>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        // StatefulBuilder para que el saldo se actualice al cambiar
        // de cuenta sin reconstruir toda la pantalla de atrás
        builder: (ctx, setDialogState) {
          final saldo = PurchaseService.getSaldoCuenta(cuentaId);
          final saldoMetodo = metodoId == null
              ? null
              : MoneyService.getById(metodoId!)?.balance;

          return AlertDialog(
            title: Text(
              titulo,
              style: const TextStyle(color: AppTheme.textWhite),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cuenta de la que sale el dinero
                  DropdownButtonFormField<int>(
                    initialValue: cuentaId,
                    isExpanded: true,
                    dropdownColor: AppTheme.bgDarkGrey,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(
                      labelText: 'Cuenta',
                      labelStyle: TextStyle(color: AppTheme.textHint),
                    ),
                    items: cuentas
                        .map(
                          (Account c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                color: AppTheme.textWhite,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      if (valor == null) return;
                      setDialogState(() => cuentaId = valor);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    saldo == null
                        ? 'Cuenta eliminada'
                        : 'Disponible: ${saldo.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Método de pago: de qué elemento de Dinero sale
                  if (pideMetodo) ...[
                    DropdownButtonFormField<int>(
                      initialValue: metodoId,
                      isExpanded: true,
                      dropdownColor: AppTheme.bgDarkGrey,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: const InputDecoration(
                        labelText: 'Método de pago',
                        labelStyle: TextStyle(color: AppTheme.textHint),
                      ),
                      items: dineros
                          .map(
                            (MoneyAccount m) => DropdownMenuItem<int>(
                              value: m.id,
                              child: Row(
                                children: [
                                  Icon(
                                    m.tipo == MoneyService.efectivo
                                        ? Icons.payments
                                        : Icons.credit_card,
                                    color: AppTheme.textHint,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      m.name,
                                      style: const TextStyle(
                                        color: AppTheme.textWhite,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (valor) {
                        if (valor == null) return;
                        setDialogState(() => metodoId = valor);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      saldoMetodo == null
                          ? 'Método eliminado'
                          : 'Disponible: ${saldoMetodo.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 13,
                      ),
                    ),
                  ] else
                    const Text(
                      'Sin método (compra anterior)',
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nombreCtrl,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      labelStyle: TextStyle(color: AppTheme.textHint),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: precioCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      labelStyle: TextStyle(color: AppTheme.textHint),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notaCtrl,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                      labelStyle: TextStyle(color: AppTheme.textHint),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              ),
              TextButton(
                onPressed: () {
                  final nombre = nombreCtrl.text.trim();
                  final precio = int.tryParse(precioCtrl.text.trim());
                  final nota = notaCtrl.text.trim();

                  // Nombre y precio son obligatorios, y el método si se pide
                  if (nombre.isEmpty || precio == null || precio <= 0) return;
                  if (pideMetodo && metodoId == null) return;

                  Navigator.pop(ctx, (
                    nombre: nombre,
                    precio: precio,
                    nota: nota.isEmpty ? null : nota,
                    accountId: cuentaId,
                    moneyId: metodoId,
                  ));
                },
                child: const Text(
                  'Guardar',
                  style: TextStyle(color: AppTheme.buttonPurple),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Los TextField siguen usando los controladores durante la animación
    // de cierre; liberarlos antes rompe el árbol de widgets
    await Future.delayed(const Duration(milliseconds: 300));
    nombreCtrl.dispose();
    precioCtrl.dispose();
    notaCtrl.dispose();

    return resultado;
  }

  Future<void> _agregarCompra() async {
    // Sin cuentas en Banco no hay de dónde sacar el dinero
    if (PurchaseService.getCuentaPreseleccionada() == null) {
      _aviso('Aún no hay cuentas existentes, crea una en Banco');
      return;
    }

    // Sin Dinero no hay método de pago
    if (MoneyService.getAll().isEmpty) {
      _aviso('Agrega dónde tienes tu dinero en Banco');
      return;
    }

    final datos = await _formulario(titulo: 'Registrar compra');
    if (datos == null || !mounted) return;

    final error = await PurchaseService.agregar(
      nombre: datos.nombre,
      precio: datos.precio,
      nota: datos.nota,
      accountId: datos.accountId,
      moneyId: datos.moneyId!,
    );

    if (!mounted) return;
    setState(() {});

    if (error != null) {
      _aviso(error);
    } else {
      _aviso('Compra registrada', esError: false);
    }
  }

  Future<void> _editarCompra(Purchase compra) async {
    final datos = await _formulario(titulo: 'Editar compra', compra: compra);
    if (datos == null || !mounted) return;

    final error = await PurchaseService.editar(
      purchaseId: compra.id,
      nombre: datos.nombre,
      precio: datos.precio,
      nota: datos.nota,
      accountId: datos.accountId,
      moneyId: datos.moneyId,
    );

    if (!mounted) return;
    setState(() {});

    if (error != null) {
      _aviso(error);
    } else {
      _aviso('Compra actualizada', esError: false);
    }
  }

  Future<void> _eliminarCompra(Purchase compra) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Eliminar compra',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          '"${compra.nombre}" por ${compra.precio}.\n\n'
          'El dinero regresará a '
          '${AccountService.getAccountName(compra.accountId)}'
          '${compra.moneyId == null ? '' : ' y a ${MoneyService.getName(compra.moneyId!)}'}.',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final error = await PurchaseService.eliminar(compra.id);
    if (!mounted) return;
    setState(() {});

    if (error != null) {
      _aviso(error);
    } else {
      _aviso('Compra eliminada, dinero devuelto', esError: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compras = PurchaseService.getDelMesActual();
    final total = PurchaseService.getTotalDelMesActual();
    final porCuenta = PurchaseService.getTotalesPorCuentaDelMesActual();

    return Scaffold(
      appBar: AppBar(title: const Text('Tienda'), centerTitle: true),
      body: Column(
        children: [
          // Lo único que se mueve con el scroll
          Expanded(
            child: compras.isEmpty
                ? const Center(
                    child: Text(
                      'Sin compras este mes',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 15),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: compras.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: AppTheme.bgDarkGrey,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: AppTheme.buttonPurple.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: ListTile(
                            onTap: () => _editarCompra(c),
                            title: Text(
                              c.nombre,
                              style: const TextStyle(
                                color: AppTheme.textWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // Cuenta y método de pago, y la nota si hay
                            subtitle: Text(
                              [
                                AccountService.getAccountName(c.accountId) +
                                    (c.moneyId == null
                                        ? ''
                                        : ' · ${MoneyService.getName(c.moneyId!)}'),
                                if (c.nota != null) c.nota!,
                              ].join('\n'),
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${c.precio}',
                                  style: const TextStyle(
                                    color: AppTheme.textWhite,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: AppTheme.danger,
                                    size: 20,
                                  ),
                                  onPressed: () => _eliminarCompra(c),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),

          // Desglose por cuenta del mes, solo si hubo compras
          if (porCuenta.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: porCuenta
                    .map(
                      (c) => Text(
                        '${c.nombre}: ${c.total}',
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          // Total del mes, fijo abajo a la derecha
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Total del mes: ',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                ),
                Text(
                  '$total',
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Barra de botones fija: 25% / 50% / 25% con márgenes
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                Expanded(
                  flex: 25,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GoalsScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text(
                      'Metas',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 50,
                  child: ElevatedButton(
                    onPressed: _agregarCompra,
                    child: const Text('Registrar compra'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 25,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PurchaseHistoryScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text(
                      'Historial',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
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