import 'package:asend/gym/screens/gym_exercises_screen.dart';
import 'package:asend/gym/screens/gym_session_screen.dart';
import 'package:asend/gym/services/gym_service.dart';
import 'package:asend/models/gym_day.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';

class GymScreen extends StatefulWidget {
  const GymScreen({super.key});

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cerrarViejas();
  }

  /// Las sesiones de días anteriores se cierran al entrar.
  /// Hace lo que haría el corte de las 4 AM con la app cerrada.
  Future<void> _cerrarViejas() async {
    await GymService.cerrarSesionesViejas();
    if (mounted) setState(() => _cargando = false);
  }

  // ── Crear día ──────────────────────────────────────────

  Future<void> _crearDia() async {
    final controlador = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Nuevo día',
            style: TextStyle(color: AppTheme.textWhite),
          ),
          content: TextField(
            controller: controlador,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: InputDecoration(
              hintText: 'A Bíceps, Pierna, Push...',
              errorText: error,
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
                final nombre = controlador.text.trim();

                if (nombre.isEmpty) {
                  setDialogState(() => error = 'Escribe un nombre');
                  return;
                }
                if (GymService.existeNombreDia(nombre)) {
                  setDialogState(() => error = 'Ya existe ese día');
                  return;
                }

                final navigator = Navigator.of(context);
                await GymService.crearDia(nombre);
                navigator.pop();
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    // El TextField sigue usando el controlador durante la animación
    // de cierre; liberarlo antes rompe el árbol de widgets
    await Future.delayed(const Duration(milliseconds: 300));
    controlador.dispose();

    if (mounted) setState(() {});
  }

  // ── Eliminar día ───────────────────────────────────────

  Future<void> _eliminarDia() async {
    final dias = GymService.getDias();

    if (dias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay días para eliminar')),
      );
      return;
    }

    // 1. Escoger cuál
    final elegido = await showDialog<GymDay>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Eliminar día',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: dias.map((d) {
              final ejercicios = GymService.getEjercicios(d.id).length;

              return ListTile(
                title: Text(
                  d.nombre,
                  style: const TextStyle(color: AppTheme.textWhite),
                ),
                subtitle: Text(
                  '$ejercicios ejercicios',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ),
                onTap: () => Navigator.pop(context, d),
              );
            }).toList(),
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
        ],
      ),
    );

    if (elegido == null || !mounted) return;

    final enCurso = GymService.estaEnCurso(elegido.id);

    // 2. Confirmar
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Eliminar día?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          'Se eliminará "${elegido.nombre}" con sus ejercicios.\n\n'
          '${enCurso ? "La sesión en curso se descarta sin guardar.\n\n" : ""}'
          'El historial se conserva.',
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

    await GymService.eliminarDia(elegido);
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${elegido.nombre} eliminado')));
  }

  // ── Abrir día ──────────────────────────────────────────

  void _abrirEjercicios(GymDay dia) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GymExercisesScreen(dia: dia)),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _abrirSesion(GymDay dia) async {
    if (GymService.getEjercicios(dia.id).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega ejercicios con el lápiz antes de empezar'),
        ),
      );
      return;
    }

    // Ya en curso: entra directo con su fecha
    if (GymService.estaEnCurso(dia.id)) {
      _irASesion(dia, GymService.getFechaSesion(dia.id) ?? GymService.hoy());
      return;
    }

    // Avisar si hay otro día sin finalizar
    final otros = GymService.getDiasEnCurso();
    if (otros.isNotEmpty) {
      final nombres = otros.map((d) => d.nombre).join(', ');

      final seguir = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Hay un día sin finalizar',
            style: TextStyle(color: AppTheme.textWhite),
          ),
          content: Text(
            '$nombres sigue en curso.\n\n'
            'Puedes empezar ${dia.nombre} de todos modos; '
            'los dos quedan abiertos.',
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
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Empezar'),
            ),
          ],
        ),
      );

      if (seguir != true || !mounted) return;
    }

    await _preguntarFecha(dia, GymService.hoy());
  }

  /// Confirma la fecha del entrenamiento. Si ya hay uno guardado
  /// en esa fecha, deja cambiarla o borrar el guardado.
  Future<void> _preguntarFecha(GymDay dia, DateTime inicial) async {
    var fecha = inicial;

    while (true) {
      if (!mounted) return;

      final ocupada = GymService.existeLogEnFecha(dia.id, fecha);

      final opcion = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            ocupada ? 'Fecha ocupada' : '¿Entrenamiento de hoy?',
            style: const TextStyle(color: AppTheme.textWhite),
          ),
          content: Text(
            ocupada
                ? 'Ya guardaste ${dia.nombre} el '
                      '${fecha.day}/${fecha.month}/${fecha.year}.\n\n'
                      'Cambia la fecha o borra lo guardado.'
                : '${fecha.day}/${fecha.month}/${fecha.year}',
            style: const TextStyle(color: AppTheme.textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancelar'),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.textGrey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'fecha'),
              child: const Text(
                'Otra fecha',
                style: TextStyle(color: AppTheme.buttonPurple),
              ),
            ),
            if (ocupada)
              TextButton(
                onPressed: () => Navigator.pop(context, 'borrar'),
                child: const Text(
                  'Borrar',
                  style: TextStyle(color: AppTheme.danger),
                ),
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'aceptar'),
                child: const Text('Aceptar'),
              ),
          ],
        ),
      );

      if (opcion == null || opcion == 'cancelar' || !mounted) return;

      if (opcion == 'aceptar') {
        _irASesion(dia, fecha);
        return;
      }

      if (opcion == 'fecha') {
        final hoy = GymService.hoy();

        final elegida = await showDatePicker(
          context: context,
          initialDate: fecha,
          firstDate: DateTime(hoy.year - 2),
          lastDate: hoy, // Nunca futuro
        );

        if (elegida == null) continue;
        fecha = DateTime(elegida.year, elegida.month, elegida.day);
        continue;
      }

      if (opcion == 'borrar') {
        final confirmado = await _confirmarBorrado(dia, fecha);
        if (confirmado) await GymService.eliminarLogEnFecha(dia.id, fecha);
      }
    }
  }

  /// Dos confirmaciones antes de borrar un entrenamiento guardado.
  Future<bool> _confirmarBorrado(GymDay dia, DateTime fecha) async {
    final primera = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Borrar lo guardado?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          'Se borrará ${dia.nombre} del '
          '${fecha.day}/${fecha.month}/${fecha.year}.',
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
              'Borrar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (primera != true || !mounted) return false;

    final segunda = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Estás seguro?',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: const Text(
          'Esto no se puede deshacer.',
          style: TextStyle(color: AppTheme.textGrey),
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
              'Sí, borrar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );

    return segunda == true;
  }

  void _irASesion(GymDay dia, DateTime fecha) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GymSessionScreen(dia: dia, fecha: fecha),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rutina de gym')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.buttonPurple),
        ),
      );
    }

    final dias = GymService.getDias();

    return Scaffold(
      appBar: AppBar(title: const Text('Rutina de gym')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              dias.isEmpty
                  ? 'Aún no hay días creados'
                  : 'Bienvenido a tu rutina',
              style: const TextStyle(
                color: AppTheme.textGrey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: dias.isEmpty
                ? _vacio()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    children: dias.map(_tarjetaDia).toList(),
                  ),
          ),
          _barraInferior(),
        ],
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
            'Crea tu primer día para empezar',
            style: TextStyle(color: AppTheme.textHint, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaDia(GymDay dia) {
    final enCurso = GymService.estaEnCurso(dia.id);
    final ejercicios = GymService.getEjercicios(dia.id).length;
    final fecha = GymService.getFechaSesion(dia.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgDarkGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enCurso
                ? AppTheme.buttonPurple
                : AppTheme.disabled.withValues(alpha: 0.3),
            width: enCurso ? 2 : 1,
          ),
        ),
        child: ListTile(
          title: Text(
            dia.nombre,
            style: TextStyle(
              color: enCurso ? AppTheme.buttonPurple : AppTheme.textWhite,
              fontSize: 16,
              fontWeight: enCurso ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          subtitle: Text(
            enCurso && fecha != null
                ? 'En curso · ${fecha.day}/${fecha.month}'
                : '$ejercicios ejercicios',
            style: TextStyle(
              color: enCurso ? AppTheme.buttonPurple : AppTheme.textGrey,
              fontSize: 12,
            ),
          ),
          onTap: () => _abrirSesion(dia),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.textHint, size: 20),
            onPressed: () => _abrirEjercicios(dia),
          ),
        ),
      ),
    );
  }

  Widget _barraInferior() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).size.height * 0.02,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: _crearDia,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Crear día'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: _eliminarDia,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppTheme.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Eliminar día',
                style: TextStyle(color: AppTheme.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
