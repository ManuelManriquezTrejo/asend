import 'package:asend/models/stat.dart';
import 'package:asend/stats/screens/link_habits_screen.dart';
import 'package:asend/stats/services/stat_service.dart';
import 'package:asend/stats/widgets/stat_widgets.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';

/// Modificar una estadística: nombre, barra, rango, puntos por rango y
/// hábitos vinculados. Mana no se puede eliminar.
class EditStatScreen extends StatefulWidget {
  final int statId;

  const EditStatScreen({super.key, required this.statId});

  @override
  State<EditStatScreen> createState() => _EditStatScreenState();
}

class _EditStatScreenState extends State<EditStatScreen> {
  late final Stat? _stat = StatService.getStat(widget.statId);
  late final TextEditingController _nombreCtrl = TextEditingController(
    text: _stat?.nombre ?? '',
  );
  late final List<TextEditingController> _umbralesCtrl = EditorUmbrales.crear(
    _stat?.umbrales ?? StatService.umbralesBase,
  );
  late bool _mostrarBarra = _stat?.mostrarBarra ?? true;
  late bool _mostrarRango = _stat?.mostrarRango ?? true;
  late String _tipoBarra = _stat?.tipoBarra ?? StatService.barraProgreso;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    for (final c in _umbralesCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _guardar(Stat stat) async {
    final umbrales = EditorUmbrales.leer(_umbralesCtrl);
    final errorTabla = StatService.validarUmbrales(umbrales);
    if (errorTabla != null) {
      _aviso(errorTabla);
      return;
    }

    // Avisar si la nueva tabla lo deja en un rango menor
    final puntos = StatService.puntos(stat.id);
    final antes = StatService.rangoDe(puntos, stat.umbrales);
    final despues = StatService.rangoDe(puntos, [for (final u in umbrales) u!]);
    if (despues < antes) {
      final seguro = await confirmar(
        context,
        titulo: 'Baja de rango',
        mensaje:
            'Con esta tabla ${stat.nombre} pasa de ${StatService.letra(antes)} '
            'a ${StatService.letra(despues)}. ¿Guardar de todos modos?',
        boton: 'Guardar',
      );
      if (!seguro) return;
    }

    final error = await StatService.guardarStat(
      stat,
      nombre: _nombreCtrl.text,
      umbrales: umbrales,
      mostrarBarra: _mostrarBarra,
      mostrarRango: _mostrarRango,
      tipoBarra: _tipoBarra,
    );
    if (!mounted) return;
    if (error != null) {
      _aviso(error);
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _eliminar(Stat stat) async {
    final vinculados = StatService.getLinksDeStat(stat.id).length;
    final seguro = await confirmar(
      context,
      titulo: 'Eliminar ${stat.nombre}',
      mensaje: vinculados == 0
          ? '¿Eliminar esta estadística?'
          : 'Tiene $vinculados hábitos vinculados; quedarán sin vincular. '
                '¿Eliminar esta estadística?',
      boton: 'Eliminar',
      peligro: true,
    );
    if (!seguro) return;

    final error = await StatService.eliminarStat(stat);
    if (!mounted) return;
    if (error != null) {
      _aviso(error);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    final stat = _stat;

    if (stat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estadística')),
        body: Center(
          child: Text(
            'Esta estadística ya no existe',
            style: TextStyle(color: AppTheme.textGrey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(stat.nombre)),
      body: Column(
        children: [
          Expanded(child: _formulario(e, stat)),
          BarraGuardar(onPressed: () => _guardar(stat)),
        ],
      ),
    );
  }

  Widget _formulario(Escala e, Stat stat) {
    final habitos = StatService.getHabitos();
    final vinculados = StatService.getLinksDeStat(stat.id);

    return ListView(
      padding: EdgeInsets.all(e.w(5)),
      children: [
        TextField(
          controller: _nombreCtrl,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(4.2)),
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        if (stat.esMana)
          Padding(
            padding: EdgeInsets.only(top: e.h(0.8)),
            child: Text(
              'Cada punto que gana esta estadística también es un punto '
              'de magia. No se puede eliminar.',
              style: TextStyle(color: AppTheme.textHint, fontSize: e.t(3.3)),
            ),
          ),
        SizedBox(height: e.h(2.5)),
        const TituloSeccion('Qué se ve en la tarjeta'),
        Recuadro(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _mostrarRango,
                onChanged: (v) => setState(() => _mostrarRango = v),
                activeThumbColor: AppTheme.primary,
                title: Text(
                  'Mostrar rango',
                  style: TextStyle(color: AppTheme.textWhite),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _mostrarBarra,
                onChanged: (v) => setState(() => _mostrarBarra = v),
                activeThumbColor: AppTheme.primary,
                title: Text(
                  'Mostrar barra',
                  style: TextStyle(color: AppTheme.textWhite),
                ),
              ),
              Row(
                children: [
                  Flexible(
                    child: _opcionBarra(
                      e,
                      valor: StatService.barraProgreso,
                      titulo: 'Progreso',
                      descripcion: 'Cuánto falta para el siguiente rango',
                    ),
                  ),
                  SizedBox(width: e.w(2)),
                  Flexible(
                    child: _opcionBarra(
                      e,
                      valor: StatService.barraDatos,
                      titulo: 'Datos',
                      descripcion: 'Actual contra máximo; se resta y suma',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: e.h(1.5)),
        const TituloSeccion('Puntos por rango'),
        Text(
          'Puntos acumulados que pide cada letra. F es desde 0.',
          style: TextStyle(color: AppTheme.textHint, fontSize: e.t(3.3)),
        ),
        SizedBox(height: e.h(1)),
        EditorUmbrales(controladores: _umbralesCtrl),
        SizedBox(height: e.h(2.5)),
        TituloSeccion(
          'Hábitos vinculados',
          accion: TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LinkHabitsScreen(statIdInicial: stat.id),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
            icon: Icon(Icons.link, color: AppTheme.primary),
            label: Text('Vincular', style: TextStyle(color: AppTheme.primary)),
          ),
        ),
        if (vinculados.isEmpty)
          Text(
            'Ningún hábito alimenta esta estadística',
            style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.6)),
          ),
        for (final l in vinculados)
          for (final h in habitos.where((h) => h.id == l.habitId))
            Padding(
              padding: EdgeInsets.only(bottom: e.h(0.6)),
              child: Text(
                '• ${h.nombre} — ${StatService.textoFactor(h, l.factor)}',
                style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(3.8)),
              ),
            ),
        if (!stat.esMana) ...[
          SizedBox(height: e.h(3)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _eliminar(stat),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: AppTheme.textWhite,
              ),
              child: const Text('Eliminar estadística'),
            ),
          ),
        ],
      ],
    );
  }

  /// Recuadro que se toca para elegir el tipo de barra.
  Widget _opcionBarra(
    Escala e, {
    required String valor,
    required String titulo,
    required String descripcion,
  }) {
    final elegido = _tipoBarra == valor;
    return InkWell(
      onTap: () => setState(() => _tipoBarra = valor),
      borderRadius: BorderRadius.circular(e.t(2)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(e.w(2.5)),
        decoration: BoxDecoration(
          color: elegido
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.bgDark,
          borderRadius: BorderRadius.circular(e.t(2)),
          border: Border.all(
            color: elegido ? AppTheme.primary : AppTheme.textHint,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: e.t(3.8),
              ),
            ),
            Text(
              descripcion,
              style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.2)),
            ),
          ],
        ),
      ),
    );
  }
}
