import 'package:flutter/material.dart';
import 'package:asend/models/daily_routine_habit.dart';
import 'package:asend/database/routine_hive_service.dart';
import 'package:asend/routine/services/habit_history_service.dart';
import 'package:asend/theme/app_theme.dart';
import 'add_routine_habit_screen.dart';
import 'edit_routine_habit_screen.dart';

class RoutineListScreen extends StatefulWidget {
  const RoutineListScreen({super.key});

  @override
  State<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends State<RoutineListScreen> {
  /// Soft delete: marca deletedAt y desaparece de las pantallas,
  /// pero el hábito y su historial siguen en las tablas.
  Future<void> _confirmDelete(DailyRoutineHabit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          '¿Eliminar hábito?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          '"${habit.nombre}" dejará de aparecer en tus pantallas.\n\n'
          'Su historial se conserva para estadísticas futuras.',
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

    if (confirmed != true) return;

    habit.deletedAt = DateTime.now();
    await HabitHistoryService.saveHabit(habit);

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('"${habit.nombre}" eliminado')));
  }

  @override
  Widget build(BuildContext context) {
    final box = RoutineHiveService.getDailyRoutineHabitBox();

    // Solo activos, ordenados por prioridad y luego alfabéticamente
    final habits = box.values.where((h) => h.deletedAt == null).toList()
      ..sort((a, b) {
        final c = a.prioridad.compareTo(b.prioridad);
        return c != 0
            ? c
            : a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Rutina Actual'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: habits.isEmpty
                ? const Center(
                    child: Text(
                      'No hay hábitos creados aún',
                      style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];
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
                              habit.nombre,
                              style: const TextStyle(
                                color: AppTheme.textWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${habit.tipo} · Racha: ${habit.currentStreak} · Récord: ${habit.maxStreak}',
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  color: AppTheme.buttonPurple,
                                  tooltip: 'Modificar',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditRoutineHabitScreen(
                                          habit: habit,
                                        ),
                                      ),
                                    ).then((_) => setState(() {}));
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  color: AppTheme.danger,
                                  tooltip: 'Eliminar',
                                  onPressed: () => _confirmDelete(habit),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Botón inferior
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddRoutineHabitScreen(),
                    ),
                  ).then((_) => setState(() {}));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.buttonPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Agregar Hábito',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
