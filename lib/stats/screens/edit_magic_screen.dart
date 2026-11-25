import 'package:asend/models/magic.dart';
import 'package:asend/models/skill.dart';
import 'package:asend/stats/screens/edit_skill_screen.dart';
import 'package:asend/stats/services/stat_service.dart';
import 'package:asend/stats/widgets/stat_widgets.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';

/// Modificar una magia: nombre, puntos por rango y sus habilidades.
class EditMagicScreen extends StatefulWidget {
  final int magicId;

  const EditMagicScreen({super.key, required this.magicId});

  @override
  State<EditMagicScreen> createState() => _EditMagicScreenState();
}

class _EditMagicScreenState extends State<EditMagicScreen> {
  late final Magic? _magia = StatService.getMagia(widget.magicId);
  late final TextEditingController _nombreCtrl = TextEditingController(
    text: _magia?.nombre ?? '',
  );
  late final List<TextEditingController> _umbralesCtrl = EditorUmbrales.crear(
    _magia?.umbrales ?? StatService.umbralesBase,
  );

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

  void _abrir(Widget pantalla) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pantalla),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _guardar(Magic magia) async {
    final umbrales = EditorUmbrales.leer(_umbralesCtrl);
    final errorTabla = StatService.validarUmbrales(umbrales);
    if (errorTabla != null) {
      _aviso(errorTabla);
      return;
    }

    // Avisar si la nueva tabla la deja en un rango menor
    final antes = StatService.rangoMagia(magia);
    final despues = StatService.rangoDe(magia.puntos, [
      for (final u in umbrales) u!,
    ]);
    if (despues < antes) {
      final seguro = await confirmar(
        context,
        titulo: 'Baja de rango',
        mensaje:
            'Con esta tabla ${magia.nombre} pasa de '
            '${StatService.letra(antes)} a ${StatService.letra(despues)} y '
            'pierde las habilidades de esos rangos. ¿Guardar de todos modos?',
        boton: 'Guardar',
      );
      if (!seguro) return;
    }

    final error = await StatService.guardarMagia(
      magia,
      nombre: _nombreCtrl.text,
      umbrales: umbrales,
    );
    if (!mounted) return;
    if (error != null) {
      _aviso(error);
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _eliminar(Magic magia) async {
    final seguro = await confirmar(
      context,
      titulo: 'Eliminar ${magia.nombre}',
      mensaje:
          'Se eliminan la magia y sus habilidades. Sus ${magia.puntos} '
          'puntos regresan a los puntos de magia disponibles.',
      boton: 'Eliminar',
      peligro: true,
    );
    if (!seguro) return;

    await StatService.eliminarMagia(magia);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _restaurar(Magic magia) async {
    final seguro = await confirmar(
      context,
      titulo: 'Restaurar habilidades',
      mensaje:
          'Las habilidades de ${magia.nombre} se reemplazan por las de '
          'fábrica, con sus descripciones y costos de mana actuales. Se '
          'pierden los cambios que les hayas hecho y las que agregaste. '
          'Los puntos y el rango no cambian.',
      boton: 'Restaurar',
      peligro: true,
    );
    if (!seguro) return;

    await StatService.restaurarHabilidades(magia);
    if (!mounted) return;
    _aviso('Habilidades restauradas');
    setState(() {});
  }

  Future<void> _eliminarHabilidad(Skill s) async {
    final seguro = await confirmar(
      context,
      titulo: 'Eliminar habilidad',
      mensaje: '¿Eliminar "${s.nombre}"?',
      boton: 'Eliminar',
      peligro: true,
    );
    if (!seguro) return;
    await StatService.eliminarHabilidad(s);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    final magia = _magia;

    if (magia == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Magia')),
        body: Center(
          child: Text(
            'Esta magia ya no existe',
            style: TextStyle(color: AppTheme.textGrey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(magia.nombre)),
      body: Column(
        children: [
          Expanded(child: _formulario(e, magia)),
          BarraGuardar(
            texto: 'Guardar nombre y rangos',
            onPressed: () => _guardar(magia),
          ),
        ],
      ),
    );
  }

  Widget _formulario(Escala e, Magic magia) {
    final habilidades = StatService.getHabilidades()
        .where((s) => s.magicId == magia.id)
        .toList();
    final deFabrica = StatService.plantillaDe(magia) != null;

    return ListView(
      padding: EdgeInsets.all(e.w(5)),
      children: [
        TextField(
          controller: _nombreCtrl,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(4.2)),
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        SizedBox(height: e.h(1)),
        Text(
          'Rango ${StatService.letra(StatService.rangoMagia(magia))} · '
          '${magia.puntos} pts',
          style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.8)),
        ),
        SizedBox(height: e.h(2.5)),
        const TituloSeccion('Puntos por rango'),
        Text(
          'Puntos de magia acumulados que pide cada letra. F es desde 0.',
          style: TextStyle(color: AppTheme.textHint, fontSize: e.t(3.3)),
        ),
        SizedBox(height: e.h(1)),
        EditorUmbrales(controladores: _umbralesCtrl),
        SizedBox(height: e.h(3)),
        TituloSeccion(
          'Habilidades (${habilidades.length})',
          accion: TextButton.icon(
            onPressed: () => _abrir(EditSkillScreen(magicId: magia.id)),
            icon: Icon(Icons.add, color: AppTheme.primary),
            label: Text('Agregar', style: TextStyle(color: AppTheme.primary)),
          ),
        ),
        Text(
          'Las habilidades se guardan desde su propio lápiz.',
          style: TextStyle(color: AppTheme.textHint, fontSize: e.t(3.3)),
        ),
        SizedBox(height: e.h(1)),
        if (habilidades.isEmpty)
          Text(
            'Esta magia aún no tiene habilidades',
            style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.6)),
          ),
        for (final s in habilidades) _habilidad(e, s),
        if (deFabrica) ...[
          SizedBox(height: e.h(2)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _restaurar(magia),
              icon: Icon(Icons.restore, color: AppTheme.primary),
              label: Text(
                'Restaurar habilidades de fábrica',
                style: TextStyle(color: AppTheme.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
        ],
        SizedBox(height: e.h(2)),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _eliminar(magia),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: AppTheme.textWhite,
            ),
            child: const Text('Eliminar magia'),
          ),
        ),
      ],
    );
  }

  Widget _habilidad(Escala e, Skill s) {
    return Recuadro(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.nombre,
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: e.t(4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${s.tipo} · desde ${StatService.letra(s.niveles.first.rango)} · '
                  '${s.niveles.length} niveles',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.3)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: AppTheme.textHint, size: e.t(5.5)),
            tooltip: 'Editar',
            onPressed: () => _abrir(EditSkillScreen(skillId: s.id)),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: AppTheme.danger,
              size: e.t(5.5),
            ),
            tooltip: 'Eliminar',
            onPressed: () => _eliminarHabilidad(s),
          ),
        ],
      ),
    );
  }
}
