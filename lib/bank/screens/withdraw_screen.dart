import 'package:flutter/material.dart';
import 'package:asend/bank/services/account_service.dart';
import 'package:asend/bank/services/withdraw_concept_service.dart';
import 'package:asend/models/account.dart';
import 'package:asend/models/withdraw_concept.dart';
import 'package:asend/theme/app_theme.dart';

/// Retirar dinero de una cuenta: cuenta, concepto y monto en una sola
/// pantalla. El concepto sale de la lista del usuario; "Retiro" viene
/// preseleccionado y es el que se usa si no se cambia nada.
class WithdrawScreen extends StatefulWidget {
  final Function onWithdrawn;

  const WithdrawScreen({super.key, required this.onWithdrawn});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController _montoController = TextEditingController();

  List<Account> _cuentas = [];
  List<WithdrawConcept> _conceptos = [];

  int? _cuentaId;
  int _conceptoId = WithdrawConceptService.idPorDefecto;

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    await WithdrawConceptService.asegurarPorDefecto();

    if (!mounted) return;
    setState(() {
      _cuentas = AccountService.getAllAccounts();
      _conceptos = WithdrawConceptService.getAll();
      _cargando = false;
    });
  }

  /// Recarga solo los conceptos, después de crear, editar o borrar uno.
  void _recargarConceptos() {
    setState(() {
      _conceptos = WithdrawConceptService.getAll();
      // Si el concepto elegido desapareció, volver al de por defecto
      if (WithdrawConceptService.getById(_conceptoId) == null) {
        _conceptoId = WithdrawConceptService.idPorDefecto;
      }
    });
  }

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // ─────────────────────────────────────────────
  // CONCEPTOS
  // ─────────────────────────────────────────────

  /// Pide un nombre y crea un concepto nuevo.
  Future<void> _crearConcepto() async {
    final controller = TextEditingController();

    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDarkGrey,
        title: const Text(
          'Nuevo concepto',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textWhite),
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: Gasolina',
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
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonPurple,
            ),
            child: const Text(
              'Crear',
              style: TextStyle(color: AppTheme.textWhite),
            ),
          ),
        ],
      ),
    );

    controller.dispose();

    if (nombre == null) return;

    final error = await WithdrawConceptService.crear(nombre);

    if (!mounted) return;

    if (error != null) {
      _aviso(error);
      return;
    }

    _recargarConceptos();

    // Dejar seleccionado el que se acaba de crear
    final creado = WithdrawConceptService.getAll().last;
    setState(() => _conceptoId = creado.id);
  }

  /// Pide un nombre nuevo para un concepto existente.
  Future<void> _editarConcepto(WithdrawConcept c) async {
    final controller = TextEditingController(text: c.nombre);

    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDarkGrey,
        title: const Text(
          'Editar concepto',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textWhite),
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonPurple,
            ),
            child: const Text(
              'Guardar',
              style: TextStyle(color: AppTheme.textWhite),
            ),
          ),
        ],
      ),
    );

    controller.dispose();

    if (nombre == null) return;

    final error = await WithdrawConceptService.editar(
      id: c.id,
      nombre: nombre,
    );

    if (!mounted) return;

    if (error != null) {
      _aviso(error);
      return;
    }

    _recargarConceptos();
  }

  /// Borra un concepto. Los retiros viejos conservan su texto.
  Future<void> _eliminarConcepto(WithdrawConcept c) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDarkGrey,
        title: const Text(
          'Eliminar concepto',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          '¿Eliminar "${c.nombre}"?\n'
          'Los retiros que ya lo usaron no cambian.',
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
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.textWhite),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final error = await WithdrawConceptService.eliminar(c.id);

    if (!mounted) return;

    if (error != null) {
      _aviso(error);
      return;
    }

    _recargarConceptos();
  }

  /// Lista de conceptos para elegir, con editar, borrar y crear nuevo.
  Future<void> _elegirConcepto() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.bgDarkGrey,
          title: const Text(
            'Concepto',
            style: TextStyle(color: AppTheme.textWhite),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _conceptos.map((c) {
                final esPorDefecto =
                    c.id == WithdrawConceptService.idPorDefecto;

                return ListTile(
                  dense: true,
                  title: Text(
                    c.nombre,
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontWeight: c.id == _conceptoId
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  leading: Icon(
                    c.id == _conceptoId
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: AppTheme.buttonPurple,
                    size: 20,
                  ),
                  // "Retiro" no se edita ni se borra
                  trailing: esPorDefecto
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AppTheme.textGrey,
                                size: 18,
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await _editarConcepto(c);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppTheme.danger,
                                size: 18,
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await _eliminarConcepto(c);
                              },
                            ),
                          ],
                        ),
                  onTap: () {
                    setState(() => _conceptoId = c.id);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _crearConcepto();
              },
              child: const Text(
                'Nuevo concepto',
                style: TextStyle(color: AppTheme.buttonPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RETIRO
  // ─────────────────────────────────────────────

  Future<void> _retirar() async {
    if (_cuentaId == null) {
      _aviso('Elige una cuenta');
      return;
    }

    final monto = double.tryParse(_montoController.text.trim());
    if (monto == null) {
      _aviso('Ingresa un número válido');
      return;
    }

    final concepto = WithdrawConceptService.getById(_conceptoId);
    if (concepto == null) {
      _aviso('Ese concepto ya no existe');
      _recargarConceptos();
      return;
    }

    final error = await AccountService.retirar(
      accountId: _cuentaId!,
      monto: monto,
      concepto: concepto.nombre,
    );

    if (!mounted) return;

    if (error != null) {
      _aviso(error);
      return;
    }

    widget.onWithdrawn();
    Navigator.pop(context);
  }

  // ─────────────────────────────────────────────
  // PANTALLA
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Retirar')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_cuentas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Retirar')),
        body: const Center(
          child: Text(
            'No hay cuentas de donde retirar',
            style: TextStyle(color: AppTheme.textHint),
          ),
        ),
      );
    }

    final conceptoActual = WithdrawConceptService.getById(_conceptoId);

    return Scaffold(
      appBar: AppBar(title: const Text('Retirar')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cuenta
            const Text(
              'Cuenta',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              initialValue: _cuentaId,
              dropdownColor: AppTheme.bgDarkGrey,
              hint: const Text(
                'Elige una cuenta',
                style: TextStyle(color: AppTheme.textHint),
              ),
              items: _cuentas.map((a) {
                return DropdownMenuItem<int>(
                  value: a.id,
                  child: Text(
                    '${a.name}  (\$${a.balance.toStringAsFixed(2)})',
                    style: const TextStyle(color: AppTheme.textWhite),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _cuentaId = v),
            ),
            const SizedBox(height: 24),

            // Concepto
            const Text(
              'Concepto',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: _elegirConcepto,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    conceptoActual?.nombre ??
                        WithdrawConceptService.nombrePorDefecto,
                    style: const TextStyle(color: AppTheme.textWhite),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.buttonPurple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Monto
            const Text(
              'Monto',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: const InputDecoration(
                hintText: 'Ej: 500',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _retirar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonPurple,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'Retirar',
                style: TextStyle(fontSize: 16, color: AppTheme.textWhite),
              ),
            ),
          ],
        ),
      ),
    );
  }
}