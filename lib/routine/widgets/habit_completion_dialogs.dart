import 'package:flutter/material.dart';
import 'package:asend/models/DailyRoutineHabit.dart';
import 'package:asend/routine/services/habit_history_service.dart';

// Dialog 1: Confirmación inicial
Future<void> showHabitCompletionDialog(
  BuildContext context,
  DailyRoutineHabit habit,
  Function onRefresh,
) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => HabitConfirmationDialog(
      habit: habit,
      onConfirm: () {
        Navigator.pop(context);
        _showValueInputDialog(context, habit, onRefresh);
      },
      onCancel: () {
        Navigator.pop(context);
      },
    ),
  );
}

// Dialog 2: Entrada de valor
Future<void> _showValueInputDialog(
  BuildContext context,
  DailyRoutineHabit habit,
  Function onRefresh,
) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ValueInputDialog(
      habit: habit,
      onValueSubmitted: (value) {
        Navigator.pop(context);
        if (value > 24 && habit.tipo == 'hora') {
          _showOver24hDialogs(context, habit, value, onRefresh);
        } else {
          _showConfirmationDialog(context, habit, value, onRefresh);
        }
      },
      onCancel: () {
        Navigator.pop(context);
      },
    ),
  );
}

// Dialog 3: Confirmación final
Future<void> _showConfirmationDialog(
  BuildContext context,
  DailyRoutineHabit habit,
  double value,
  Function onRefresh,
) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ConfirmationDialog(
      habit: habit,
      value: value,
      onConfirm: () {
        Navigator.pop(context);
        _showFinalMessageDialog(context, habit, value, onRefresh);
      },
      onCorrect: () {
        Navigator.pop(context);
        _showValueInputDialog(context, habit, onRefresh);
      },
    ),
  );
}

// Dialog 4: Provocadores si >24h
Future<void> _showOver24hDialogs(
  BuildContext context,
  DailyRoutineHabit habit,
  double totalHours,
  Function onRefresh,
) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Over24hDialog(
      habit: habit,
      totalHours: totalHours,
      onRefresh: onRefresh,
      onConfirm: () {
        Navigator.pop(context);
        _showConfirmationDialog(context, habit, totalHours, onRefresh);
      },
      onCancel: () {
        Navigator.pop(context);
        _showValueInputDialog(context, habit, onRefresh);
      },
    ),
  );
}

// Mensaje final antes de guardar
Future<void> _showFinalMessageDialog(
  BuildContext context,
  DailyRoutineHabit habit,
  double value,
  Function onRefresh,
) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => FinalMessageDialog(
      habit: habit,
      value: value,
      onConfirm: () async {
        // Guardar el registro del día
        await HabitHistoryService.createHabitRecord(
          habitId: habit.id,
          value: value,
        );

        // Recalcular racha con el historial ya actualizado
        HabitHistoryService.recalculateStreak(habit);

        // Persistir el hábito (busca su clave real de Hive)
        await HabitHistoryService.saveHabit(habit);

        // Cerrar el diálogo y refrescar la pantalla
        if (dialogContext.mounted) {
          Navigator.pop(dialogContext);
        }
        onRefresh();
      },
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// DIALOG 1: Confirmación inicial
// ═══════════════════════════════════════════════════════════════
class HabitConfirmationDialog extends StatelessWidget {
  final DailyRoutineHabit habit;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const HabitConfirmationDialog({
    required this.habit,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: Text('¿Se ha completado?', style: TextStyle(color: Colors.white)),
      content: Text(
        'Marcaste "${habit.nombre}" como completado',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('No')),
        TextButton(onPressed: onConfirm, child: const Text('Sí')),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DIALOG 2: Entrada de valor (nota o horas+minutos)
// ═══════════════════════════════════════════════════════════════
class ValueInputDialog extends StatefulWidget {
  final DailyRoutineHabit habit;
  final Function(double) onValueSubmitted;
  final VoidCallback onCancel;

  const ValueInputDialog({
    required this.habit,
    required this.onValueSubmitted,
    required this.onCancel,
  });

  @override
  State<ValueInputDialog> createState() => _ValueInputDialogState();
}

class _ValueInputDialogState extends State<ValueInputDialog> {
  late TextEditingController _noteController;
  late TextEditingController _hoursController;
  late TextEditingController _minutesController;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _hoursController = TextEditingController();
    _minutesController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    setState(() {
      _errorMessage = '';
    });

    double value = 0;

    if (widget.habit.tipo == 'nota') {
      if (_noteController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Ingresa una calificación';
        });
        return;
      }

      final noteValue = int.tryParse(_noteController.text);
      if (noteValue == null) {
        setState(() {
          _errorMessage = 'Número inválido';
        });
        return;
      }

      if (noteValue > 11) {
        setState(() {
          _errorMessage = 'Número inválido';
        });
        return;
      }

      value = noteValue.toDouble();
    } else {
      // Tipo "hora"
      final hours = int.tryParse(_hoursController.text) ?? 0;
      final minutes = int.tryParse(_minutesController.text) ?? 0;

      if (hours == 0 && minutes == 0) {
        setState(() {
          _errorMessage = 'Ingresa al menos 1 minuto';
        });
        return;
      }

      value = hours + (minutes / 60);
    }

    widget.onValueSubmitted(value);
  }

  @override
  Widget build(BuildContext context) {
    const Color purpleUva = Color(0xFF7C3AED);

    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: Text(
        widget.habit.tipo == 'nota' ? 'Calificación (0-11)' : 'Tiempo dedicado',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.habit.tipo == 'nota')
            TextFormField(
              controller: _noteController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ingresa nota (0-11)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: purpleUva),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Horas',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: purpleUva),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Minutos',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: purpleUva),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Cancelar')),
        TextButton(onPressed: _handleSubmit, child: const Text('Siguiente')),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DIALOG 3: Confirmación final
// ═══════════════════════════════════════════════════════════════
class ConfirmationDialog extends StatelessWidget {
  final DailyRoutineHabit habit;
  final double value;
  final VoidCallback onConfirm;
  final VoidCallback onCorrect;

  const ConfirmationDialog({
    required this.habit,
    required this.value,
    required this.onConfirm,
    required this.onCorrect,
  });

  @override
  Widget build(BuildContext context) {
    String displayValue = '';
    if (habit.tipo == 'nota') {
      displayValue = '${value.toInt()}/11';
    } else {
      final hours = value.toInt();
      final minutes = ((value - hours) * 60).toInt();
      displayValue = '${hours}h ${minutes}m';
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: Text('¿Confirmas?', style: TextStyle(color: Colors.white)),
      content: Text(
        'Registraste: $displayValue de "${habit.nombre}"',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(onPressed: onCorrect, child: const Text('Corregir')),
        TextButton(onPressed: onConfirm, child: const Text('Confirmar')),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DIALOG 4: Provocadores si >24h
// ═══════════════════════════════════════════════════════════════
class Over24hDialog extends StatefulWidget {
  final DailyRoutineHabit habit;
  final double totalHours;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final Function onRefresh;

  const Over24hDialog({
    required this.habit,
    required this.totalHours,
    required this.onConfirm,
    required this.onCancel,
    required this.onRefresh,
  });

  @override
  State<Over24hDialog> createState() => _Over24hDialogState();
}

class _Over24hDialogState extends State<Over24hDialog> {
  int _stage = 1;

  @override
  Widget build(BuildContext context) {
    if (_stage == 1) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text('¡Wow!', style: TextStyle(color: Colors.white)),
        content: Text(
          'Hiciste ${widget.totalHours.toStringAsFixed(1)} horas en un día de 24...\n\n¿Estás seguro?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onCancel();
            },
            child: const Text('No, corregir'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _stage = 2;
              });
            },
            child: const Text('Sí'),
          ),
        ],
      );
    } else if (_stage == 2) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text('¿Estás seguro?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Esto es bastante inusual...',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onCancel();
            },
            child: const Text('No, corregir'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _stage = 3;
              });
            },
            child: const Text('Sí'),
          ),
        ],
      );
    } else {
      return Over24hFinalDialog(onRefresh: widget.onRefresh);
    }
  }
}

class Over24hFinalDialog extends StatefulWidget {
  final Function onRefresh;

  const Over24hFinalDialog({required this.onRefresh});

  @override
  State<Over24hFinalDialog> createState() => _Over24hFinalDialogState();
}

class _Over24hFinalDialogState extends State<Over24hFinalDialog> {
  late String _randomPhrase;
  bool _showSecondPhrase = false;

  final List<String> _phrases = [
    'Es difícil de creer',
    'Viniendo de ti es difícil de creer',
    'Pero siendo tú...',
    'No me esperaba eso',
    'Hmm, interesante',
  ];

  @override
  void initState() {
    super.initState();
    _randomPhrase = (_phrases..shuffle()).first;

    // 3 segundos para frase aleatoria
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSecondPhrase = true;
        });

        // 1.5 segundos para "No te creo"
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            // Cierra todos los dialogs (3 niveles)
            Navigator.popUntil(context, (route) => route.isFirst);
            widget.onRefresh();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _showSecondPhrase ? 'No te creo' : _randomPhrase,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MENSAJE FINAL
// ═══════════════════════════════════════════════════════════════
class FinalMessageDialog extends StatelessWidget {
  final DailyRoutineHabit habit;
  final double value;
  final VoidCallback onConfirm;

  const FinalMessageDialog({
    required this.habit,
    required this.value,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    String displayValue = '';
    if (habit.tipo == 'nota') {
      displayValue = '${value.toInt()}/11';
    } else {
      final hours = value.toInt();
      final minutes = ((value - hours) * 60).toInt();
      displayValue = '${hours}h ${minutes}m';
    }

    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '✅ Completado',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hiciste $displayValue de "${habit.nombre}"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onConfirm,
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}
