import 'package:flutter/material.dart';
import 'package:asend/models/DailyRoutineHabit.dart';
import 'package:asend/database/routine_hive_service.dart';
import 'package:asend/theme/app_theme.dart';

class AddRoutineHabitScreen extends StatefulWidget {
  const AddRoutineHabitScreen({super.key});

  @override
  State<AddRoutineHabitScreen> createState() => _AddRoutineHabitScreenState();
}

class _AddRoutineHabitScreenState extends State<AddRoutineHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _valorController = TextEditingController();
  final _prioridadController = TextEditingController();

  String? _selectedTipo;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _valorController.dispose();
    _prioridadController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTipo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un tipo'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final box = RoutineHiveService.getDailyRoutineHabitBox();

      // Buscar el ID más alto, no el último insertado
      int nextId = 1;
      for (final h in box.values) {
        if (h.id >= nextId) nextId = h.id + 1;
      }

      final minToKeepStreak = _selectedTipo == 'nota' ? 9.0 : 1.0;

      final newHabit = DailyRoutineHabit(
        id: nextId,
        nombre: _nombreController.text.trim(),
        tipo: _selectedTipo!,
        valor: double.parse(_valorController.text),
        prioridad: double.parse(_prioridadController.text),
        createdAt: DateTime.now(),
        minToKeepStreak: minToKeepStreak,
      );

      await box.add(newHabit);

      // La pantalla pudo cerrarse mientras esperábamos el await
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hábito creado exitosamente')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.danger,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Hábito'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              const Text(
                'Nombre del Hábito *',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: const InputDecoration(hintText: 'Ej: Estudiar'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Tipo
              const Text(
                'Tipo de Evaluación *',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTipo = 'nota';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedTipo == 'nota'
                            ? AppTheme.buttonPurple
                            : AppTheme.bgDarkGrey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: _selectedTipo == 'nota'
                              ? AppTheme.buttonPurple
                              : AppTheme.textHint,
                        ),
                      ),
                      child: const Text(
                        'Por Nota (0-11)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTipo = 'hora';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedTipo == 'hora'
                            ? AppTheme.buttonPurple
                            : AppTheme.bgDarkGrey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: _selectedTipo == 'hora'
                              ? AppTheme.buttonPurple
                              : AppTheme.textHint,
                        ),
                      ),
                      child: const Text(
                        'Por Hora (0-24)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Valor
              const Text(
                'Valor (dinero/puntos) *',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: _selectedTipo == 'hora'
                      ? 'Ej: 20 (por hora)'
                      : 'Ej: 15 (valor fijo)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El valor es obligatorio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Prioridad
              const Text(
                'Prioridad *',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _prioridadController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: const InputDecoration(
                  hintText: 'Ej: 1, 2, 2.1, 3...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La prioridad es obligatoria';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Botón crear
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.buttonPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppTheme.textWhite,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Crear Hábito',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
