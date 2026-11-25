import 'package:asend/models/magic.dart';
import 'package:asend/models/stat.dart';
import 'package:asend/stats/screens/add_magic_screen.dart';
import 'package:asend/stats/screens/assign_magic_points_screen.dart';
import 'package:asend/stats/screens/edit_magic_screen.dart';
import 'package:asend/stats/screens/edit_skill_screen.dart';
import 'package:asend/stats/screens/edit_stat_screen.dart';
import 'package:asend/stats/screens/link_habits_screen.dart';
import 'package:asend/stats/screens/skills_screen.dart';
import 'package:asend/stats/services/stat_service.dart';
import 'package:asend/stats/widgets/stat_widgets.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';

/// Pantalla principal de Stats: nombre y rango general del personaje,
/// estadísticas, magias y botones de habilidades.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    _procesar();
  }

  /// Procesa los días cerrados pendientes antes de mostrar los puntos.
  Future<void> _procesar() async {
    await StatService.procesarDiasCerrados();
    if (mounted) setState(() {});
  }

  /// Abre una pantalla y redibuja al volver.
  void _abrir(Widget pantalla) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pantalla),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    final stats = StatService.getStats();
    final magias = StatService.getMagias();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        actions: [
          IconButton(
            icon: Icon(Icons.link, color: AppTheme.primary, size: e.t(7)),
            tooltip: 'Vincular hábitos',
            onPressed: () => _abrir(const LinkHabitsScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(e.w(5)),
        children: [
          _personaje(e),
          SizedBox(height: e.h(1.5)),
          const TituloSeccion('Estadísticas'),
          for (final s in stats) _tarjetaStat(e, s),
          _botonAncho(
            e,
            icono: Icons.add,
            texto: 'Agregar estadística',
            onPressed: _agregarStat,
          ),
          SizedBox(height: e.h(2.5)),
          TituloSeccion(
            'Magias',
            accion: magias.isEmpty
                ? null
                : TextButton.icon(
                    onPressed: () =>
                        _abrir(const AssignMagicPointsScreen()),
                    icon: Icon(Icons.tune, color: AppTheme.primary),
                    label: Text(
                      'Repartir',
                      style: TextStyle(color: AppTheme.primary),
                    ),
                  ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: e.h(1)),
            child: Text(
              'Puntos de magia disponibles: '
              '${StatService.puntosMagiaDisponibles()}',
              style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.8)),
            ),
          ),
          for (final m in magias) _tarjetaMagia(e, m),
          _botonAncho(
            e,
            icono: Icons.auto_awesome,
            texto: 'Agregar magia',
            onPressed: () => _abrir(const AddMagicScreen()),
          ),
          SizedBox(height: e.h(2.5)),
          Row(
            children: [
              Flexible(
                child: _botonAncho(
                  e,
                  icono: Icons.add_circle_outline,
                  texto: 'Agregar habilidad',
                  onPressed: () => _abrir(const EditSkillScreen()),
                ),
              ),
              SizedBox(width: e.w(3)),
              Flexible(
                child: _botonAncho(
                  e,
                  icono: Icons.menu_book,
                  texto: 'Ver habilidades',
                  onPressed: () => _abrir(const SkillsScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botonAncho(
    Escala e, {
    required IconData icono,
    required String texto,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono, size: e.t(5)),
        label: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: e.t(3.8)),
        ),
      ),
    );
  }

  // ── Personaje ──────────────────────────────────────────

  /// Nombre editable a la izquierda y rango general a la derecha.
  Widget _personaje(Escala e) {
    final nombre = StatService.nombrePersonaje();

    return Recuadro(
      resaltado: true,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _editarNombre,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: e.h(1)),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        nombre.isEmpty ? 'Sin nombre' : nombre,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: nombre.isEmpty
                              ? AppTheme.textHint
                              : AppTheme.textWhite,
                          fontSize: e.t(5.5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: e.w(2)),
                    Icon(Icons.edit, color: AppTheme.textHint, size: e.t(4.5)),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              LetraRango(rango: StatService.rangoGeneral(), tamano: e.t(11)),
              Text(
                'General',
                style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3)),
              ),
            ],
          ),
          SizedBox(width: e.w(2)),
        ],
      ),
    );
  }

  Future<void> _editarNombre() async {
    final nuevo = await pedirTexto(
      context,
      titulo: 'Nombre del personaje',
      etiqueta: 'Nombre (puede ir vacío)',
      inicial: StatService.nombrePersonaje(),
    );
    if (nuevo == null) return;
    await StatService.setNombrePersonaje(nuevo);
    if (mounted) setState(() {});
  }

  // ── Estadísticas ───────────────────────────────────────

  Widget _tarjetaStat(Escala e, Stat s) {
    final puntos = StatService.puntos(s.id);

    return Recuadro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.nombre,
                      style: TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: e.t(4.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$puntos pts',
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: e.t(3.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (s.mostrarRango)
                LetraRango(rango: StatService.rangoStat(s), tamano: e.t(7)),
              IconButton(
                icon: Icon(Icons.edit, color: AppTheme.textHint, size: e.t(5.5)),
                tooltip: 'Modificar',
                onPressed: () => _abrir(EditStatScreen(statId: s.id)),
              ),
            ],
          ),
          if (s.mostrarBarra) ...[
            SizedBox(height: e.h(0.8)),
            Padding(
              padding: EdgeInsets.only(right: e.w(2)),
              child: s.tipoBarra == StatService.barraDatos
                  ? BarraDatos(
                      actual: StatService.actualDatos(s),
                      maximo: puntos.toDouble(),
                      onTap: () => _dialogoDatos(s),
                    )
                  : BarraProgreso(puntos: puntos, umbrales: s.umbrales),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _agregarStat() async {
    final nombre = await pedirTexto(
      context,
      titulo: 'Nueva estadística',
      etiqueta: 'Nombre',
      validar: (texto) => texto.trim().isEmpty ? 'Escribe un nombre' : null,
    );
    if (nombre == null) return;

    final error = await StatService.crearStat(nombre);
    if (!mounted) return;
    if (error != null) {
      _aviso(error);
      return;
    }
    setState(() {});
  }

  /// Restar, sumar o llenar la barra de datos.
  Future<void> _dialogoDatos(Stat s) async {
    final controlador = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> mover(bool restar) async {
            final cantidad = leerNumero(controlador.text);
            if (cantidad == null || cantidad <= 0) {
              setDialogState(() => error = 'Escribe una cantidad mayor a 0');
              return;
            }
            final navigator = Navigator.of(context);
            await StatService.moverDatos(s, restar ? cantidad : -cantidad);
            navigator.pop();
          }

          return AlertDialog(
            title: Text(
              s.nombre,
              style: TextStyle(color: AppTheme.textWhite),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${StatService.numero(StatService.actualDatos(s))} / '
                  '${StatService.puntos(s.id)}',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controlador,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await StatService.llenarDatos(s);
                  navigator.pop();
                },
                child: Text('Llenar', style: TextStyle(color: AppTheme.primary)),
              ),
              TextButton(
                onPressed: () => mover(false),
                child: Text('Sumar', style: TextStyle(color: AppTheme.primary)),
              ),
              ElevatedButton(
                onPressed: () => mover(true),
                child: const Text('Restar'),
              ),
            ],
          );
        },
      ),
    );

    // El TextField sigue usando el controlador durante la animación de
    // cierre; liberarlo antes rompe el árbol de widgets
    await Future.delayed(const Duration(milliseconds: 300));
    controlador.dispose();
    if (mounted) setState(() {});
  }

  // ── Magias ─────────────────────────────────────────────

  Widget _tarjetaMagia(Escala e, Magic m) {
    return Recuadro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.nombre,
                      style: TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: e.t(4.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${m.puntos} pts',
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: e.t(3.5),
                      ),
                    ),
                  ],
                ),
              ),
              LetraRango(rango: StatService.rangoMagia(m), tamano: e.t(7)),
              IconButton(
                icon: Icon(Icons.edit, color: AppTheme.textHint, size: e.t(5.5)),
                tooltip: 'Modificar',
                onPressed: () => _abrir(EditMagicScreen(magicId: m.id)),
              ),
            ],
          ),
          SizedBox(height: e.h(0.8)),
          Padding(
            padding: EdgeInsets.only(right: e.w(2)),
            child: BarraProgreso(puntos: m.puntos, umbrales: m.umbrales),
          ),
        ],
      ),
    );
  }
}
