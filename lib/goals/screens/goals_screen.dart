import 'package:asend/goals/services/goal_service.dart';
import 'package:asend/models/goal.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // ─────────────────────────────────────────────
  // AVISOS
  // ─────────────────────────────────────────────

  void _aviso(String mensaje, {bool esError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? AppTheme.danger : AppTheme.success,
      ),
    );
  }

  /// Diálogo de texto libre. Devuelve el texto o null si cancela.
  Future<String?> _pedirTexto({
    required String titulo,
    required String etiqueta,
  }) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo, style: const TextStyle(color: AppTheme.textWhite)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textWhite),
          decoration: InputDecoration(
            labelText: etiqueta,
            labelStyle: const TextStyle(color: AppTheme.textHint),
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
              final texto = controller.text.trim();
              if (texto.isEmpty) return;
              Navigator.pop(ctx, texto);
            },
            child: const Text(
              'Aceptar',
              style: TextStyle(color: AppTheme.buttonPurple),
            ),
          ),
        ],
      ),
    );
  }

  /// Diálogo de monto entero. Devuelve el número o null si cancela.
  Future<int?> _pedirMonto({required String titulo, String? ayuda}) {
    final controller = TextEditingController();

    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo, style: const TextStyle(color: AppTheme.textWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ayuda != null) ...[
              Text(
                ayuda,
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: const InputDecoration(
                labelText: 'Monto',
                labelStyle: TextStyle(color: AppTheme.textHint),
              ),
            ),
          ],
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
              final monto = int.tryParse(controller.text.trim());
              if (monto == null || monto <= 0) return;
              Navigator.pop(ctx, monto);
            },
            child: const Text(
              'Aceptar',
              style: TextStyle(color: AppTheme.buttonPurple),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ACCIONES
  // ─────────────────────────────────────────────

  Future<void> _agregarMeta() async {
    final nombre = await _pedirTexto(titulo: 'Nueva meta', etiqueta: 'Nombre');
    if (nombre == null) return;

    await GoalService.agregarMeta(nombre);
    if (!mounted) return;
    setState(() {});
    _aviso('Meta "$nombre" creada', esError: false);
  }

  /// Botón verde: reparte equitativamente entre todas las metas.
  Future<void> _agregarFondos() async {
    final metas = GoalService.getMetas();

    // Sin metas ni siquiera se abre la ventana
    if (metas.isEmpty) {
      _aviso('No hay metas registradas');
      return;
    }

    final saldo = GoalService.getSaldoCuenta();

    final monto = await _pedirMonto(
      titulo: 'Agregar fondos',
      ayuda:
          'Se reparte en partes iguales entre ${metas.length} metas.\n'
          'El sobrante se queda en la cuenta.'
          '${saldo == null ? '' : '\n\nDisponible: ${saldo.toStringAsFixed(0)}'}',
    );
    if (monto == null || !mounted) return;

    final porMeta = GoalService.calcularPorMeta(monto);

    // Confirmación mostrando cuánto toca y cuánto sobra
    if (porMeta > 0) {
      final sale = porMeta * metas.length;
      final sobrante = monto - sale;
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Confirmar reparto',
            style: TextStyle(color: AppTheme.textWhite),
          ),
          content: Text(
            '$porMeta a cada una de las ${metas.length} metas.\n'
            'Salen $sale de la cuenta.'
            '${sobrante > 0 ? '\nSobrante: $sobrante (se queda en la cuenta)' : ''}',
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
                'Repartir',
                style: TextStyle(color: AppTheme.success),
              ),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
    }

    final error = await GoalService.repartir(monto);
    if (!mounted) return;
    setState(() {});

    if (error != null) {
      _aviso(error);
    } else {
      _aviso('Repartido: $porMeta a cada meta', esError: false);
    }
  }

  /// Botón a la derecha de cada meta: abonar o retirar individual.
  Future<void> _moverMeta(Goal meta) async {
    final accion = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          meta.nombre,
          style: const TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          'Acumulado: ${meta.saldo}',
          style: const TextStyle(color: AppTheme.textGrey),
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
            onPressed: () => Navigator.pop(ctx, 'retirar'),
            child: const Text(
              'Retirar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'abonar'),
            child: const Text(
              'Abonar',
              style: TextStyle(color: AppTheme.success),
            ),
          ),
        ],
      ),
    );
    if (accion == null || !mounted) return;

    final esAbono = accion == 'abonar';

    if (!esAbono && meta.saldo == 0) {
      _aviso('Esta meta no tiene fondos');
      return;
    }

    final saldo = GoalService.getSaldoCuenta();

    final monto = await _pedirMonto(
      titulo: esAbono ? 'Abonar a ${meta.nombre}' : 'Retirar de ${meta.nombre}',
      ayuda: esAbono
          ? (saldo == null
                ? null
                : 'Disponible en la cuenta: ${saldo.toStringAsFixed(0)}')
          : 'Disponible en la meta: ${meta.saldo}',
    );
    if (monto == null || !mounted) return;

    final error = esAbono
        ? await GoalService.abonar(meta.id, monto)
        : await GoalService.retirar(meta.id, monto);

    if (!mounted) return;
    setState(() {});

    if (error != null) {
      _aviso(error);
    } else {
      _aviso(
        esAbono ? 'Abonado $monto a ${meta.nombre}' : 'Retirado $monto',
        esError: false,
      );
    }
  }

  /// Botón inferior: despliega todas las metas para elegir cuál borrar.
  Future<void> _eliminarMeta() async {
    final metas = GoalService.getMetas();

    if (metas.isEmpty) {
      _aviso('No hay metas registradas');
      return;
    }

    final elegida = await showDialog<Goal>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '¿Cuál meta quieres eliminar?',
          style: TextStyle(color: AppTheme.textWhite, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: metas
                .map(
                  (m) => ListTile(
                    title: Text(
                      m.nombre,
                      style: const TextStyle(color: AppTheme.textWhite),
                    ),
                    trailing: Text(
                      '${m.saldo}',
                      style: const TextStyle(color: AppTheme.textGrey),
                    ),
                    onTap: () => Navigator.pop(ctx, m),
                  ),
                )
                .toList(),
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
        ],
      ),
    );
    if (elegida == null || !mounted) return;

    // Con fondos: avisar que el dinero vuelve a la cuenta.
    // Sin fondos: se elimina directo.
    if (elegida.saldo > 0) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Eliminar meta',
            style: TextStyle(color: AppTheme.textWhite),
          ),
          content: Text(
            'La meta "${elegida.nombre}" tiene ${elegida.saldo}.\n\n'
            'Ese dinero regresará a la cuenta.',
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
    }

    final error = await GoalService.eliminarMeta(elegida.id);
    if (!mounted) return;
    setState(() {});

    if (error != null) {
      _aviso(error);
    } else {
      _aviso('Meta "${elegida.nombre}" eliminada', esError: false);
    }
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final metas = GoalService.getMetas();
    final total = GoalService.getTotalApartado();

    return Scaffold(
      appBar: AppBar(title: const Text('Metas'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: metas.isEmpty
                ? const Center(
                    child: Text(
                      'Aún no tienes metas',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 15),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: metas.map((m) {
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
                              m.nombre,
                              style: const TextStyle(
                                color: AppTheme.textWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${m.saldo}',
                                  style: const TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: AppTheme.buttonPurple,
                                    size: 20,
                                  ),
                                  onPressed: () => _moverMeta(m),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),

          // Total apartado
          if (metas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total apartado',
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

          // Botones inferiores
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                Flexible(
                  child: ElevatedButton(
                    onPressed: _agregarMeta,
                    child: const Text('Agregar meta'),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton(
                    onPressed: _agregarFondos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                    ),
                    child: const Icon(Icons.attach_money, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton(
                    onPressed: _eliminarMeta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                    ),
                    child: const Text('Eliminar'),
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
