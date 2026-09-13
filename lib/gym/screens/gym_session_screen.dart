import 'package:asend/gym/services/gym_service.dart';
import 'package:asend/models/gym_day.dart';
import 'package:asend/models/gym_exercise.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GymSessionScreen extends StatefulWidget {
  final GymDay dia;
  final DateTime fecha;

  const GymSessionScreen({
    super.key,
    required this.dia,
    required this.fecha,
  });

  @override
  State<GymSessionScreen> createState() => _GymSessionScreenState();
}

class _GymSessionScreenState extends State<GymSessionScreen> {
  late DateTime _fecha = widget.fecha;

  /// Un controlador y un foco por casilla, con clave "ejercicioId-serie".
  final Map<String, TextEditingController> _controladores = {};
  final Map<String, FocusNode> _focos = {};

  bool _finalizando = false;

  static const List<String> _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  static const List<String> _dias = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves',
    'Viernes', 'Sábado', 'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _prepararCasillas();
  }

  @override
  void dispose() {
    for (final c in _controladores.values) {
      c.dispose();
    }
    for (final f in _focos.values) {
      f.dispose();
    }
    super.dispose();
  }

  String _clave(int ejercicioId, int serie) => '$ejercicioId-$serie';

  /// Carga en cada casilla lo que ya estuviera guardado.
  void _prepararCasillas() {
    for (final ejercicio in GymService.getEjercicios(widget.dia.id)) {
      for (var serie = 1; serie <= ejercicio.series; serie++) {
        final clave = _clave(ejercicio.id, serie);
        final reps = GymService.getReps(widget.dia.id, ejercicio.id, serie);

        _controladores[clave] =
            TextEditingController(text: reps?.toString() ?? '');
        _focos[clave] = FocusNode();
      }
    }
  }

  String _fechaLarga(DateTime d) =>
      '${_dias[d.weekday - 1]} ${d.day} de ${_meses[d.month - 1]}';

  String _peso(GymExercise e) =>
      e.peso == 0 ? 'Sin peso' : '${_numero(e.peso)} ${e.unidadPeso}';

  String _numero(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  // ── Guardado ───────────────────────────────────────────

  /// Se llama al escribir. Guarda al momento para no perder
  /// el progreso si se cierra la app.
  Future<void> _guardar(GymExercise ejercicio, int serie, String texto) async {
    if (GymService.validarRepsSesion(texto) != null) return;

    final limpio = texto.trim();

    await GymService.guardarReps(
      diaId: widget.dia.id,
      ejercicioId: ejercicio.id,
      numeroSerie: serie,
      fecha: _fecha,
      reps: limpio.isEmpty ? null : int.parse(limpio),
    );
  }

  /// Mueve el foco a la siguiente serie del mismo ejercicio.
  /// En la última, cierra el teclado.
  void _siguienteCasilla(GymExercise ejercicio, int serie) {
    if (serie >= ejercicio.series) {
      FocusScope.of(context).unfocus();
      return;
    }
    _focos[_clave(ejercicio.id, serie + 1)]?.requestFocus();
  }

  // ── Fecha ──────────────────────────────────────────────

  Future<void> _cambiarFecha() async {
    final hoy = GymService.hoy();

    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(hoy.year - 2),
      lastDate: hoy, // Nunca futuro
      builder: (context, child) => Theme(
        data: Theme.of(context),
        child: child!,
      ),
    );

    if (elegida == null || !mounted) return;
    if (GymService.mismoDia(elegida, _fecha)) return;

    if (GymService.existeLogEnFecha(widget.dia.id, elegida)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya hay un entrenamiento guardado en esa fecha'),
        ),
      );
      return;
    }

    await GymService.cambiarFechaSesion(widget.dia.id, elegida);
    if (!mounted) return;

    setState(() => _fecha = elegida);
  }

  // ── Finalizar ──────────────────────────────────────────

  Future<void> _finalizar() async {
    final vacias = GymService.contarVacias(widget.dia.id);

    if (vacias > 0) {
      final seguir = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            '¿Finalizar rutina?',
            style: TextStyle(color: AppTheme.textWhite),
          ),
          content: Text(
            'Quedan $vacias ${vacias == 1 ? "serie" : "series"} sin anotar.\n\n'
            'Se guardarán como 0.',
            style: const TextStyle(color: AppTheme.textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Seguir anotando',
                style: TextStyle(color: AppTheme.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Finalizar'),
            ),
          ],
        ),
      );

      if (seguir != true) return;
    }

    if (!mounted) return;
    setState(() => _finalizando = true);

    await GymService.finalizarSesion(widget.dia.id);
    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.dia.nombre} guardado')),
    );
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ejercicios = GymService.getEjercicios(widget.dia.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.dia.nombre)),
      // El teclado empuja el contenido en lugar de taparlo
      resizeToAvoidBottomInset: true,
      body: ejercicios.isEmpty
          ? _vacio()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _cabeceraFecha(),
                const SizedBox(height: 16),
                ...ejercicios.map(_filaEjercicio),
                const SizedBox(height: 16),
                // Botón al final de la lista, no fijo
                ElevatedButton.icon(
                  onPressed: _finalizando ? null : _finalizar,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Rutina acabada'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _vacio() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 56, color: AppTheme.textHint),
            SizedBox(height: 16),
            Text(
              'Este día no tiene ejercicios.\n'
              'Agrégalos con el lápiz.',
              style: TextStyle(color: AppTheme.textHint, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabeceraFecha() {
    return InkWell(
      onTap: _cambiarFecha,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _fechaLarga(_fecha),
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.edit_calendar,
              color: AppTheme.buttonPurple,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaEjercicio(GymExercise ejercicio) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgDarkGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.buttonPurple.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${ejercicio.orden}. ',
                  style: const TextStyle(
                    color: AppTheme.buttonPurple,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    ejercicio.nombre,
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${_peso(ejercicio)} · '
                  '${ejercicio.series}×${ejercicio.reps}',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Una casilla por serie
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                ejercicio.series,
                (i) => _casilla(ejercicio, i + 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _casilla(GymExercise ejercicio, int serie) {
    final clave = _clave(ejercicio.id, serie);
    final esUltima = serie == ejercicio.series;

    return SizedBox(
      width: 62,
      child: Column(
        children: [
          Text(
            'S$serie',
            style: const TextStyle(color: AppTheme.textHint, fontSize: 10),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _controladores[clave],
            focusNode: _focos[clave],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            // Con "Siguiente" avanza; tocar fuera también funciona
            textInputAction:
                esUltima ? TextInputAction.done : TextInputAction.next,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
              hintText: '—',
            ),
            onChanged: (texto) => _guardar(ejercicio, serie, texto),
            onSubmitted: (_) => _siguienteCasilla(ejercicio, serie),
          ),
        ],
      ),
    );
  }
}