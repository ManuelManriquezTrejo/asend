import 'package:flutter/material.dart';
import 'package:asend/models/daily_routine_habit.dart';
import 'package:asend/routine/services/habit_history_service.dart';
import 'package:asend/theme/app_theme.dart';

class EditRoutineHabitScreen extends StatefulWidget {
  final DailyRoutineHabit habit;

  const EditRoutineHabitScreen({super.key, required this.habit});

  @override
  State<EditRoutineHabitScreen> createState() => _EditRoutineHabitScreenState();
}

class _EditRoutineHabitScreenState extends State<EditRoutineHabitScreen> {
  /// Muestra un diálogo con un campo de texto y devuelve lo escrito
  Future<String?> _askText({
    required String titulo,
    required String valorActual,
    required String hint,
    bool numerico = false,
    String? Function(String)? validar,
  }) async {
    final controller = TextEditingController(text: valorActual);
    String error = '';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            titulo,
            style: const TextStyle(color: AppTheme.textWhite),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: numerico
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: AppTheme.textHint),
                  filled: true,
                  fillColor: AppTheme.bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.buttonPurple),
                  ),
                ),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final texto = controller.text.trim();
                final msg = validar?.call(texto);
                if (msg != null) {
                  setDialogState(() => error = msg);
                  return;
                }
                Navigator.pop(dialogContext, texto);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: AppTheme.bgDarkGrey),
    );
  }

  // ── NOMBRE ────────────────────────────────────────────────
  Future<void> _editarNombre() async {
    final nuevo = await _askText(
      titulo: 'Nuevo nombre',
      valorActual: widget.habit.nombre,
      hint: 'Ej: Estudiar',
      validar: (t) => t.isEmpty ? 'El nombre no puede estar vacío' : null,
    );
    if (nuevo == null) return;

    widget.habit.nombre = nuevo;
    await HabitHistoryService.saveHabit(widget.habit);
    setState(() {});
    _aviso('Nombre actualizado');
  }

  // ── VALOR ─────────────────────────────────────────────────
  Future<void> _editarValor() async {
    final esHora = widget.habit.tipo == 'hora';
    final nuevo = await _askText(
      titulo: esHora ? 'Pago por hora' : 'Pago fijo',
      valorActual: widget.habit.valor.toString(),
      hint: esHora ? 'Ej: 20 (por cada hora)' : 'Ej: 15 (valor fijo)',
      numerico: true,
      validar: (t) {
        final v = double.tryParse(t);
        if (v == null) return 'Ingresa un número válido';
        if (v < 0) return 'El valor no puede ser negativo';
        return null;
      },
    );
    if (nuevo == null) return;

    widget.habit.valor = double.parse(nuevo);
    await HabitHistoryService.saveHabit(widget.habit);
    setState(() {});
    _aviso('Valor actualizado. Los registros pasados conservan el anterior.');
  }

  // ── PRIORIDAD ─────────────────────────────────────────────
  Future<void> _editarPrioridad() async {
    final nuevo = await _askText(
      titulo: 'Nueva prioridad',
      valorActual: widget.habit.prioridad.toString(),
      hint: 'Ej: 1, 2, 2.1, 3...',
      numerico: true,
      validar: (t) =>
          double.tryParse(t) == null ? 'Ingresa un número válido' : null,
    );
    if (nuevo == null) return;

    widget.habit.prioridad = double.parse(nuevo);
    await HabitHistoryService.saveHabit(widget.habit);
    setState(() {});
    _aviso('Prioridad actualizada');
  }

  // ── MÍNIMO PARA RACHA ─────────────────────────────────────
  Future<void> _editarMinimo() async {
    final esHora = widget.habit.tipo == 'hora';
    final tope = esHora ? 24.0 : 11.0;

    final nuevo = await _askText(
      titulo: 'Mínimo para mantener racha',
      valorActual: widget.habit.minToKeepStreak.toString(),
      hint: esHora ? 'Horas (0 - 24)' : 'Nota (0 - 11)',
      numerico: true,
      validar: (t) {
        final v = double.tryParse(t);
        if (v == null) return 'Ingresa un número válido';
        if (v <= 0) return 'Debe ser mayor que 0';
        if (v > tope) {
          return esHora ? 'Máximo 24 horas en un día' : 'La nota máxima es 11';
        }
        return null;
      },
    );
    if (nuevo == null) return;

    widget.habit.minToKeepStreak = double.parse(nuevo);
    // El historial no cambia, pero la racha se recalcula con el nuevo umbral
    HabitHistoryService.recalculateStreak(widget.habit);
    await HabitHistoryService.saveHabit(widget.habit);
    setState(() {});
    _aviso('Mínimo actualizado. Racha: ${widget.habit.currentStreak} días');
  }

  // ── TIPO ──────────────────────────────────────────────────
  Future<void> _editarTipo() async {
    final actual = widget.habit.tipo;
    final nuevo = actual == 'nota' ? 'hora' : 'nota';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          '¿Cambiar tipo?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          'Pasarás de "$actual" a "$nuevo".\n\n'
          'Tu historial se archiva y la racha vuelve a cero, porque los '
          'valores viejos no son comparables con los nuevos.\n\n'
          'Después tendrás que indicar el nuevo pago.',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    // Pedir el nuevo pago antes de aplicar nada
    final valorTexto = await _askText(
      titulo: nuevo == 'hora' ? 'Pago por hora' : 'Pago fijo',
      valorActual: widget.habit.valor.toString(),
      hint: nuevo == 'hora' ? 'Ej: 20 (por cada hora)' : 'Ej: 15 (valor fijo)',
      numerico: true,
      validar: (t) {
        final v = double.tryParse(t);
        if (v == null) return 'Ingresa un número válido';
        if (v < 0) return 'El valor no puede ser negativo';
        return null;
      },
    );
    if (valorTexto == null) return; // canceló, no se cambia nada

    await HabitHistoryService.softDeleteHistory(widget.habit.id);

    widget.habit.tipo = nuevo;
    widget.habit.valor = double.parse(valorTexto);
    widget.habit.minToKeepStreak = nuevo == 'nota' ? 9.0 : 1.0;
    // El historial viejo se archivó: ambas rachas empiezan de cero
    widget.habit.currentStreak = 0;
    widget.habit.maxStreak = 0;
    await HabitHistoryService.saveHabit(widget.habit);
    setState(() {});
    _aviso('Tipo cambiado a "$nuevo". Racha reiniciada.');
  }

  // ── UI ────────────────────────────────────────────────────
  Widget _opcion({
    required IconData icono,
    required String titulo,
    required String actual,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgDarkGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.buttonPurple.withValues(alpha: 0.3),
          ),
        ),
        child: ListTile(
          leading: Icon(icono, color: AppTheme.buttonPurple),
          title: Text(
            titulo,
            style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
          ),
          subtitle: Text(
            actual,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    final esHora = h.tipo == 'hora';

    return Scaffold(
      appBar: AppBar(title: const Text('Modificar Hábito'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            h.nombre,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Racha actual: ${h.currentStreak} días',
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const Text(
            '¿Qué quieres modificar?',
            style: TextStyle(color: AppTheme.textWhite, fontSize: 14),
          ),
          const SizedBox(height: 12),

          _opcion(
            icono: Icons.label_outline,
            titulo: 'Nombre',
            actual: h.nombre,
            onTap: _editarNombre,
          ),
          _opcion(
            icono: Icons.swap_horiz,
            titulo: 'Tipo de evaluación',
            actual: esHora ? 'Por hora (0-24)' : 'Por nota (0-11)',
            onTap: _editarTipo,
          ),
          _opcion(
            icono: Icons.attach_money,
            titulo: 'Valor',
            actual: esHora ? '${h.valor} por hora' : '${h.valor} fijo',
            onTap: _editarValor,
          ),
          _opcion(
            icono: Icons.sort,
            titulo: 'Prioridad',
            actual: '${h.prioridad}',
            onTap: _editarPrioridad,
          ),
          _opcion(
            icono: Icons.local_fire_department_outlined,
            titulo: 'Mínimo para mantener racha',
            actual: esHora
                ? '${h.minToKeepStreak} horas'
                : 'Nota ${h.minToKeepStreak}',
            onTap: _editarMinimo,
          ),
        ],
      ),
    );
  }
}
