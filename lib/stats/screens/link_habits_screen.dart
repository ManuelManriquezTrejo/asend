import 'package:asend/models/daily_routine_habit.dart';
import 'package:asend/stats/services/stat_service.dart';
import 'package:asend/stats/widgets/stat_widgets.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';

/// Todos los hábitos de Rutina con la estadística que alimentan y
/// cuántos puntos dan. Tocar uno permite cambiar el vínculo o el valor.
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
    final habitos = _filtrados();

    return Scaffold(
      appBar: AppBar(title: const Text('Vincular hábitos')),
      body: Column(
        children: [
          _filtros(e),
          Expanded(
            child: habitos.isEmpty
                ? Center(
                    child: Text(
                      'No hay hábitos con estos filtros',
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: e.t(4),
                      ),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      e.w(5),
                      e.h(1),
                      e.w(5),
                      e.h(2),
                    ),
                    children: [for (final h in habitos) _tarjeta(e, h)],
                  ),
          ),
        ],
      ),
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
}
