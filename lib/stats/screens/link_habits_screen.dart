import 'package:asend/missions/services/mission_service.dart';
import 'package:asend/models/daily_routine_habit.dart';
import 'package:asend/models/mission.dart';
import 'package:asend/stats/services/stat_service.dart';
import 'package:asend/stats/widgets/stat_widgets.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';

/// Dos pestañas: los hábitos de Rutina con la estadística que alimentan
/// y cuántos puntos dan, y las misiones con los puntos de magia que dan
/// al completarse. El lápiz de cada uno permite cambiarlo.
class LinkHabitsScreen extends StatefulWidget {
  /// Si se abre desde una estadística, empieza filtrada por ella.
  final int? statIdInicial;

  const LinkHabitsScreen({super.key, this.statIdInicial});

  @override
  State<LinkHabitsScreen> createState() => _LinkHabitsScreenState();
}

class _LinkHabitsScreenState extends State<LinkHabitsScreen> {
  static const String _todos = 'todos';
  static const String _vinculados = 'vinculados';
  static const String _sinVincular = 'sin';

  static const String _conPuntos = 'con';
  static const String _sinPuntos = 'sin';

  /// Filtro de la pestaña Misiones.
  String _misionesFiltro = _todos;

  String _estado = _todos;

  /// Estadística elegida en el filtro; null = todas.
  late int? _statFiltro = widget.statIdInicial;

  /// 'hora', 'nota' o null para ambos.
  String? _tipoFiltro;

  String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

  List<DailyRoutineHabit> _filtrados() {
    return StatService.getHabitos().where((h) {
      final link = StatService.getLink(h.id);
      if (_estado == _vinculados && link == null) return false;
      if (_estado == _sinVincular && link != null) return false;
      if (_statFiltro != null && link?.statId != _statFiltro) return false;
      if (_tipoFiltro != null && h.tipo != _tipoFiltro) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vincular'),
          bottom: TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textGrey,
            tabs: const [
              Tab(text: 'Hábitos'),
              Tab(text: 'Misiones'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_pestanaHabitos(e), _pestanaMisiones(e)],
        ),
      ),
    );
  }

  Widget _vacio(Escala e, String texto) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(e.w(8)),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(4)),
        ),
      ),
    );
  }

  // ── Hábitos ────────────────────────────────────────────

  Widget _pestanaHabitos(Escala e) {
    final habitos = _filtrados();

    return Column(
      children: [
        _filtros(e),
        Expanded(
          child: habitos.isEmpty
              ? _vacio(e, 'No hay hábitos con estos filtros')
              : ListView(
                  padding: EdgeInsets.fromLTRB(e.w(5), e.h(1), e.w(5), e.h(2)),
                  children: [for (final h in habitos) _tarjeta(e, h)],
                ),
        ),
      ],
    );
  }

  Widget _filtros(Escala e) {
    final stats = StatService.getStats();
    final estilo = TextStyle(color: AppTheme.textWhite, fontSize: e.t(3.6));

    return Container(
      color: AppTheme.bgDarkGrey,
      padding: EdgeInsets.symmetric(horizontal: e.w(4), vertical: e.h(0.5)),
      child: Wrap(
        spacing: e.w(4),
        children: [
          DropdownButton<String>(
            value: _estado,
            dropdownColor: AppTheme.bgDarkGrey,
            style: estilo,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: _todos, child: Text('Todos')),
              DropdownMenuItem(value: _vinculados, child: Text('Vinculados')),
              DropdownMenuItem(value: _sinVincular, child: Text('Sin vincular')),
            ],
            onChanged: (v) => setState(() => _estado = v ?? _todos),
          ),
          DropdownButton<int?>(
            value: _statFiltro,
            dropdownColor: AppTheme.bgDarkGrey,
            style: estilo,
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem(value: null, child: Text('Toda estadística')),
              for (final s in stats)
                DropdownMenuItem(value: s.id, child: Text(s.nombre)),
            ],
            onChanged: (v) => setState(() => _statFiltro = v),
          ),
          DropdownButton<String?>(
            value: _tipoFiltro,
            dropdownColor: AppTheme.bgDarkGrey,
            style: estilo,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: null, child: Text('Hora y nota')),
              DropdownMenuItem(value: 'hora', child: Text('Hora')),
              DropdownMenuItem(value: 'nota', child: Text('Nota')),
            ],
            onChanged: (v) => setState(() => _tipoFiltro = v),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Escala e, DailyRoutineHabit h) {
    final link = StatService.getLink(h.id);
    final stat = link == null ? null : StatService.getStat(link.statId);

    final detalle = link == null || stat == null
        ? 'Sin vincular'
        : '→ ${stat.nombre} · ${StatService.textoFactor(h, link.factor)}\n'
              'Desde ${_fecha(link.fechaVinculo)}'
              '${link.fechaCambio == null ? '' : ' · cambio ${_fecha(link.fechaCambio!)}'}';

    return Recuadro(
      resaltado: link != null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.nombre,
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: e.t(4.2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  h.tipo == 'hora' ? 'Hábito de hora' : 'Hábito de nota',
                  style: TextStyle(color: AppTheme.textHint, fontSize: e.t(3.2)),
                ),
                SizedBox(height: e.h(0.4)),
                Text(
                  detalle,
                  style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.5)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: AppTheme.textHint, size: e.t(5.5)),
            tooltip: 'Cambiar vínculo',
            onPressed: () => _editar(h),
          ),
        ],
      ),
    );
  }

  /// Elegir estadística (o ninguna) y cuántos puntos da.
  Future<void> _editar(DailyRoutineHabit h) async {
    final link = StatService.getLink(h.id);
    final stats = StatService.getStats();
    int? statId = link?.statId;
    if (statId != null && StatService.getStat(statId) == null) statId = null;

    final factorCtrl = TextEditingController(
      text: StatService.numero(link?.factor ?? 1),
    );
    String? error;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(h.nombre, style: TextStyle(color: AppTheme.textWhite)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int?>(
                  initialValue: statId,
                  dropdownColor: AppTheme.bgDarkGrey,
                  style: TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'Estadística'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sin vincular'),
                    ),
                    for (final s in stats)
                      DropdownMenuItem(value: s.id, child: Text(s.nombre)),
                  ],
                  onChanged: (v) => setDialogState(() => statId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: factorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    labelText: h.tipo == 'hora'
                        ? 'Puntos por cada hora'
                        : 'Puntos por cada nota 10',
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los puntos se suman por día y se quitan los decimales. '
                  'Lo ya ganado no cambia: el cambio cuenta desde hoy.',
                  style: TextStyle(color: AppTheme.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: AppTheme.textGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final factor = leerNumero(factorCtrl.text);
                if (factor == null) {
                  setDialogState(() => error = 'Escribe un número válido');
                  return;
                }
                final navigator = Navigator.of(context);
                final mensaje = await StatService.vincular(
                  habitId: h.id,
                  statId: statId,
                  factor: factor,
                );
                if (mensaje != null) {
                  setDialogState(() => error = mensaje);
                  return;
                }
                navigator.pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    // El TextField sigue usando el controlador durante la animación de
    // cierre; liberarlo antes rompe el árbol de widgets
    await Future.delayed(const Duration(milliseconds: 300));
    factorCtrl.dispose();
    if (mounted) setState(() {});
  }

  // ── Misiones ───────────────────────────────────────────

  List<Mission> _misionesFiltradas() {
    return MissionService.getPrincipales().where((m) {
      final puntos = StatService.puntosDeMision(m.id);
      if (_misionesFiltro == _conPuntos && puntos == 0) return false;
      if (_misionesFiltro == _sinPuntos && puntos > 0) return false;
      return true;
    }).toList();
  }

  Widget _pestanaMisiones(Escala e) {
    final misiones = _misionesFiltradas();
    final completadas = StatService.getPuntosDeMisiones();

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppTheme.bgDarkGrey,
          padding: EdgeInsets.symmetric(horizontal: e.w(4), vertical: e.h(0.5)),
          child: Row(
            children: [
              DropdownButton<String>(
                value: _misionesFiltro,
                dropdownColor: AppTheme.bgDarkGrey,
                style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(3.6)),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: _todos, child: Text('Todas')),
                  DropdownMenuItem(value: _conPuntos, child: Text('Con puntos')),
                  DropdownMenuItem(value: _sinPuntos, child: Text('Sin puntos')),
                ],
                onChanged: (v) => setState(() => _misionesFiltro = v ?? _todos),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(e.w(5), e.h(1), e.w(5), e.h(2)),
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: e.h(1)),
                child: Text(
                  'Solo las misiones principales. Al completarlas, sus puntos '
                  'van directo a los puntos de magia disponibles.',
                  style: TextStyle(color: AppTheme.textHint, fontSize: e.t(3.3)),
                ),
              ),
              if (misiones.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: e.h(3)),
                  child: Text(
                    'No hay misiones con este filtro',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(4)),
                  ),
                ),
              for (final m in misiones) _tarjetaMision(e, m),
              if (completadas.isNotEmpty) ...[
                SizedBox(height: e.h(2)),
                const TituloSeccion('Ya completadas'),
                for (final c in completadas)
                  Padding(
                    padding: EdgeInsets.only(bottom: e.h(0.8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${c.nombre} · ${_fecha(c.fecha)}',
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: e.t(3.6),
                            ),
                          ),
                        ),
                        Text(
                          '+${c.puntos}',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: e.t(3.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _tarjetaMision(Escala e, Mission m) {
    final puntos = StatService.puntosDeMision(m.id);

    return Recuadro(
      resaltado: puntos > 0,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.nombre,
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: e.t(4.2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  m.taken ? 'Misión tomada' : 'En el tablón',
                  style: TextStyle(color: AppTheme.textHint, fontSize: e.t(3.2)),
                ),
                SizedBox(height: e.h(0.4)),
                Text(
                  puntos > 0
                      ? 'Da $puntos puntos de magia'
                      : 'Sin puntos de magia',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.5)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: AppTheme.textHint, size: e.t(5.5)),
            tooltip: 'Cambiar puntos',
            onPressed: () => _editarMision(m),
          ),
        ],
      ),
    );
  }

  Future<void> _editarMision(Mission m) async {
    final texto = await pedirTexto(
      context,
      titulo: m.nombre,
      etiqueta: 'Puntos de magia al completarla',
      inicial: '${StatService.puntosDeMision(m.id)}',
      numerico: true,
      validar: (t) {
        final valor = int.tryParse(t.trim());
        if (valor == null) return 'Escribe un número entero, por ejemplo 5';
        if (valor < 0) return 'Los puntos no pueden ser negativos';
        return null;
      },
    );
    if (texto == null) return;

    await StatService.setPuntosDeMision(m.id, int.parse(texto.trim()));
    if (mounted) setState(() {});
  }
}
