import 'package:asend/gym/services/gym_service.dart';
import 'package:asend/models/gym_day.dart';
import 'package:asend/models/gym_exercise.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GymExercisesScreen extends StatefulWidget {
  final GymDay dia;

  const GymExercisesScreen({super.key, required this.dia});

  @override
  State<GymExercisesScreen> createState() => _GymExercisesScreenState();
}

class _GymExercisesScreenState extends State<GymExercisesScreen> {
  /// Cómo se muestra el peso: 0 y vacío significan sin peso extra.
  String _peso(GymExercise e) =>
      e.peso == 0 ? 'Sin peso' : '${_numero(e.peso)} ${e.unidadPeso}';

  /// Quita el .0 de los enteros: 22.5 se queda, 20.0 sale como 20.
  String _numero(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  // ── Crear y editar ─────────────────────────────────────

  /// Diálogo compartido. Con [ejercicio] en null crea uno nuevo.
  Future<void> _dialogoEjercicio({GymExercise? ejercicio}) async {
    final esNuevo = ejercicio == null;
    final existentes = GymService.getEjercicios(widget.dia.id);

    final nombreCtrl = TextEditingController(text: ejercicio?.nombre ?? '');
    final pesoCtrl = TextEditingController(
      text: ejercicio == null || ejercicio.peso == 0
          ? ''
          : _numero(ejercicio.peso),
    );
    final seriesCtrl = TextEditingController(
      text: ejercicio?.series.toString() ?? '4',
    );
    final repsCtrl = TextEditingController(
      text: ejercicio?.reps.toString() ?? '12',
    );

    String unidad = ejercicio?.unidadPeso ?? GymService.unidadesPeso.first;

    // Al crear, la posición por defecto es el final
    int orden = ejercicio?.orden ?? existentes.length + 1;
    final maxOrden = esNuevo ? existentes.length + 1 : existentes.length;

    String? errorNombre;
    String? errorPeso;
    String? errorSeries;
    String? errorReps;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.bgDarkGrey,
          title: Text(
            esNuevo ? 'Nuevo ejercicio' : 'Editar ejercicio',
            style: const TextStyle(color: AppTheme.textWhite),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nombreCtrl,
                  autofocus: esNuevo,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Press banca, curl...',
                    errorText: errorNombre,
                  ),
                ),
                const SizedBox(height: 16),

                // Peso y unidad
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pesoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        // Negativo para fondos con banda de apoyo
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,-]'),
                          ),
                        ],
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: InputDecoration(
                          labelText: 'Peso',
                          hintText: 'Vacío = sin peso',
                          errorText: errorPeso,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botón ± por si el teclado no trae el signo menos
                    IconButton(
                      tooltip: 'Cambiar signo',
                      icon: const Icon(
                        Icons.exposure,
                        color: AppTheme.buttonPurple,
                      ),
                      onPressed: () {
                        final texto = pesoCtrl.text.trim();
                        if (texto.isEmpty) return;

                        pesoCtrl.text = texto.startsWith('-')
                            ? texto.substring(1)
                            : '-$texto';
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  children: GymService.unidadesPeso.map((u) {
                    final elegida = u == unidad;

                    return ChoiceChip(
                      label: Text(u),
                      selected: elegida,
                      onSelected: (_) => setDialogState(() => unidad = u),
                      backgroundColor: AppTheme.bgDark,
                      selectedColor: AppTheme.buttonPurple,
                      labelStyle: TextStyle(
                        color: elegida ? AppTheme.textWhite : AppTheme.textGrey,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: elegida
                            ? AppTheme.buttonPurple
                            : AppTheme.textHint,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Formato: series x reps
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: seriesCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: InputDecoration(
                          labelText: 'Series',
                          errorText: errorSeries,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '×',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: repsCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: InputDecoration(
                          labelText: 'Reps',
                          errorText: errorReps,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Orden de realización',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(maxOrden, (i) {
                    final posicion = i + 1;
                    final elegida = posicion == orden;

                    return ChoiceChip(
                      label: Text('$posicion'),
                      selected: elegida,
                      onSelected: (_) =>
                          setDialogState(() => orden = posicion),
                      backgroundColor: AppTheme.bgDark,
                      selectedColor: AppTheme.buttonPurple,
                      labelStyle: TextStyle(
                        color: elegida ? AppTheme.textWhite : AppTheme.textGrey,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: elegida
                            ? AppTheme.buttonPurple
                            : AppTheme.textHint,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = nombreCtrl.text.trim();

                final eNombre = nombre.isEmpty
                    ? 'Escribe un nombre'
                    : GymService.existeNombreEjercicio(
                        widget.dia.id,
                        nombre,
                        exceptoId: ejercicio?.id,
                      )
                    ? 'Ya existe ese ejercicio'
                    : null;

                final ePeso = GymService.validarPeso(pesoCtrl.text);
                final eSeries = GymService.validarSeries(seriesCtrl.text);
                final eReps = GymService.validarReps(repsCtrl.text);

                if (eNombre != null ||
                    ePeso != null ||
                    eSeries != null ||
                    eReps != null) {
                  setDialogState(() {
                    errorNombre = eNombre;
                    errorPeso = ePeso;
                    errorSeries = eSeries;
                    errorReps = eReps;
                  });
                  return;
                }

                final navigator = Navigator.of(context);
                final peso = GymService.parsearPeso(pesoCtrl.text);
                final series = int.parse(seriesCtrl.text.trim());
                final reps = int.parse(repsCtrl.text.trim());

                if (esNuevo) {
                  await GymService.crearEjercicio(
                    diaId: widget.dia.id,
                    nombre: nombre,
                    peso: peso,
                    unidadPeso: unidad,
                    series: series,
                    reps: reps,
                    orden: orden,
                  );
                } else {
                  await GymService.editarEjercicio(
                    ejercicio,
                    nombre: nombre,
                    peso: peso,
                    unidadPeso: unidad,
                    series: series,
                    reps: reps,
                    orden: orden,
                  );
                }

                navigator.pop();
              },
              child: Text(esNuevo ? 'Crear' : 'Guardar'),
            ),
          ],
        ),
      ),
    );

    // El TextField sigue usando los controladores durante la
    // animación de cierre; liberarlos antes rompe el árbol
    await Future.delayed(const Duration(milliseconds: 300));
    nombreCtrl.dispose();
    pesoCtrl.dispose();
    seriesCtrl.dispose();
    repsCtrl.dispose();

    if (mounted) setState(() {});
  }

  // ── Eliminar ───────────────────────────────────────────

  Future<void> _eliminarEjercicio(GymExercise ejercicio) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgDarkGrey,
        title: const Text(
          '¿Eliminar ejercicio?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          'Se eliminará "${ejercicio.nombre}".\n\n'
          'Su historial se conserva.',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    await GymService.eliminarEjercicio(ejercicio);
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${ejercicio.nombre} eliminado')),
    );
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ejercicios = GymService.getEjercicios(widget.dia.id);
    final enCurso = GymService.estaEnCurso(widget.dia.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.dia.nombre)),
      body: Column(
        children: [
          if (enCurso) _avisoEnCurso(),
          Expanded(
            child: ejercicios.isEmpty
                ? _vacio()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: ejercicios.map(_tarjeta).toList(),
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).size.height * 0.02,
            ),
            child: ElevatedButton.icon(
              onPressed: () => _dialogoEjercicio(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar ejercicio'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cambiar series con una sesión abierta puede borrar reps ya anotadas.
  Widget _avisoEnCurso() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.buttonPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.buttonPurple),
      ),
      child: const Text(
        'Este día tiene una sesión en curso. Bajar las series '
        'puede borrar reps ya anotadas.',
        style: TextStyle(color: AppTheme.buttonPurple, fontSize: 12),
      ),
    );
  }

  Widget _vacio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 56, color: AppTheme.textHint),
          SizedBox(height: 16),
          Text(
            'Aún no hay ejercicios',
            style: TextStyle(color: AppTheme.textHint, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(GymExercise ejercicio) {
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
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.buttonPurple,
            child: Text(
              '${ejercicio.orden}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            ejercicio.nombre,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${_peso(ejercicio)} · '
            '${ejercicio.series}×${ejercicio.reps}',
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppTheme.textHint,
                  size: 20,
                ),
                onPressed: () => _dialogoEjercicio(ejercicio: ejercicio),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.danger,
                  size: 20,
                ),
                onPressed: () => _eliminarEjercicio(ejercicio),
              ),
            ],
          ),
        ),
      ),
    );
  }
}