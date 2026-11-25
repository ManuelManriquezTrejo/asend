import 'package:asend/models/skill.dart';
import 'package:asend/stats/services/stat_service.dart';
import 'package:asend/stats/widgets/stat_widgets.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';

/// Un nivel mientras se edita: su rango y sus dos campos de texto.
class _NivelEditable {
  int rango;
  final TextEditingController descripcion;
  final TextEditingController mana;

  _NivelEditable({
    required this.rango,
    required String descripcion,
    required String mana,
  }) : descripcion = TextEditingController(text: descripcion),
       mana = TextEditingController(text: mana);

  void dispose() {
    descripcion.dispose();
    mana.dispose();
  }
}

/// Crear o editar una habilidad. Con [skillId] edita esa; si no, crea
/// una nueva dentro de [magicId] o de magia única.
class EditSkillScreen extends StatefulWidget {
  final int? skillId;
  final int? magicId;

  const EditSkillScreen({super.key, this.skillId, this.magicId});

  @override
  State<EditSkillScreen> createState() => _EditSkillScreenState();
}

class _EditSkillScreenState extends State<EditSkillScreen> {
  /// La habilidad original o una nueva vacía. No se modifica: al
  /// guardar se arma una copia con lo que hay en los campos.
  late final Skill _base = _cargar();

  late final TextEditingController _nombreCtrl = TextEditingController(
    text: _base.nombre,
  );
  late final TextEditingController _notaCtrl = TextEditingController(
    text: _base.nota,
  );
  late String _tipo = _base.tipo;
  late int? _magicId = _base.magicId;
  late final List<_NivelEditable> _niveles = [
    for (final n in _base.niveles)
      _NivelEditable(rango: n.rango, descripcion: n.descripcion, mana: n.mana),
  ];

  bool get _esNueva => widget.skillId == null;

  Skill _cargar() {
    if (widget.skillId != null) {
      for (final s in StatService.getHabilidades()) {
        if (s.id == widget.skillId) return s;
      }
    }
    return StatService.nuevaHabilidad(magicId: widget.magicId);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _notaCtrl.dispose();
    for (final n in _niveles) {
      n.dispose();
    }
    super.dispose();
  }

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Nuevo nivel copiado del último, un rango arriba: solo se cambia lo
  /// que sea distinto.
  void _agregarNivel() {
    final ultimo = _niveles.isEmpty ? null : _niveles.last;
    if (ultimo != null && ultimo.rango >= StatService.rangos.length - 1) {
      _aviso('El último nivel ya es SS');
      return;
    }
    setState(() {
      _niveles.add(
        _NivelEditable(
          rango: ultimo == null ? 0 : (ultimo.rango < 0 ? 0 : ultimo.rango + 1),
          descripcion: ultimo?.descripcion.text ?? '',
          mana: ultimo?.mana.text ?? '',
        ),
      );
    });
  }

  void _quitarNivel(int i) {
    final nivel = _niveles[i];
    setState(() => _niveles.removeAt(i));
    // Se libera después de que el campo sale de la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) => nivel.dispose());
  }

  Future<void> _guardar() async {
    final copia = Skill(
      id: _base.id,
      nombre: _nombreCtrl.text,
      magicId: _magicId,
      tipo: _tipo,
      nota: _notaCtrl.text.trim(),
      niveles: [
        for (final n in _niveles)
          SkillLevel(
            rango: n.rango,
            descripcion: n.descripcion.text.trim(),
            mana: n.mana.text.trim(),
          ),
      ],
      orden: _base.orden,
      createdAt: _base.createdAt,
    );

    final error = await StatService.guardarHabilidad(copia);
    if (!mounted) return;
    if (error != null) {
      _aviso(error);
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _eliminar() async {
    final seguro = await confirmar(
      context,
      titulo: 'Eliminar habilidad',
      mensaje: '¿Eliminar "${_base.nombre}"?',
      boton: 'Eliminar',
      peligro: true,
    );
    if (!seguro) return;
    await StatService.eliminarHabilidad(_base);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_esNueva ? 'Nueva habilidad' : 'Editar habilidad'),
      ),
      body: Column(
        children: [
          Expanded(child: _formulario(e)),
          BarraGuardar(onPressed: _guardar),
        ],
      ),
    );
  }

  Widget _formulario(Escala e) {
    final magias = StatService.getMagias();
    if (_magicId != null && !magias.any((m) => m.id == _magicId)) {
      _magicId = null;
    }
    final estilo = TextStyle(color: AppTheme.textWhite, fontSize: e.t(4));

    return ListView(
      padding: EdgeInsets.all(e.w(5)),
      children: [
        TextField(
          controller: _nombreCtrl,
          textCapitalization: TextCapitalization.sentences,
          style: estilo,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        SizedBox(height: e.h(1.5)),
        DropdownButtonFormField<int?>(
          initialValue: _magicId,
          dropdownColor: AppTheme.bgDarkGrey,
          style: estilo,
          decoration: const InputDecoration(labelText: 'Magia'),
          items: [
            for (final m in magias)
              DropdownMenuItem(value: m.id, child: Text(m.nombre)),
            const DropdownMenuItem(value: null, child: Text('Magia única')),
          ],
          onChanged: (v) => setState(() => _magicId = v),
        ),
        SizedBox(height: e.h(0.6)),
        Text(
          _magicId == null
              ? 'Magia única: no pertenece a ninguna magia. Cada nivel se '
                    'desbloquea cuando el rango general llega a su letra; '
                    'sin rango se tiene desde el inicio.'
              : 'Cada nivel se desbloquea cuando la magia llega a su letra.',
          style: TextStyle(color: AppTheme.textHint, fontSize: e.t(3.2)),
        ),
        SizedBox(height: e.h(1.5)),
        DropdownButtonFormField<String>(
          initialValue: StatService.tiposHabilidad.contains(_tipo)
              ? _tipo
              : StatService.tiposHabilidad.first,
          dropdownColor: AppTheme.bgDarkGrey,
          style: estilo,
          decoration: const InputDecoration(labelText: 'Tipo'),
          items: [
            for (final t in StatService.tiposHabilidad)
              DropdownMenuItem(value: t, child: Text(t)),
          ],
          onChanged: (v) => setState(() => _tipo = v ?? _tipo),
        ),
        SizedBox(height: e.h(1.5)),
        TextField(
          controller: _notaCtrl,
          textCapitalization: TextCapitalization.sentences,
          minLines: 1,
          maxLines: 4,
          style: estilo,
          decoration: const InputDecoration(
            labelText: 'Qué hace en general (opcional)',
          ),
        ),
        SizedBox(height: e.h(2.5)),
        TituloSeccion(
          'Niveles (${_niveles.length})',
          accion: TextButton.icon(
            onPressed: _agregarNivel,
            icon: Icon(Icons.add, color: AppTheme.primary),
            label: Text(
              'Agregar nivel',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
        ),
        Text(
          'Cada nivel nuevo copia el anterior un rango arriba; solo cambia '
          'lo que sea distinto. En Ver habilidades se muestra el nivel más '
          'alto que tengas.',
          style: TextStyle(color: AppTheme.textHint, fontSize: e.t(3.2)),
        ),
        SizedBox(height: e.h(1)),
        for (var i = 0; i < _niveles.length; i++) _nivel(e, i),
        if (!_esNueva) ...[
          SizedBox(height: e.h(2)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _eliminar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: AppTheme.textWhite,
              ),
              child: const Text('Eliminar habilidad'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _nivel(Escala e, int i) {
    final n = _niveles[i];
    final estilo = TextStyle(color: AppTheme.textWhite, fontSize: e.t(3.8));

    return Recuadro(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  // Clave propia de cada nivel: al borrar uno de arriba,
                  // los de abajo no heredan su valor
                  key: ValueKey('rango_${identityHashCode(n)}'),
                  initialValue: n.rango,
                  dropdownColor: AppTheme.bgDarkGrey,
                  style: estilo,
                  decoration: const InputDecoration(
                    labelText: 'Rango',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: -1, child: Text('Sin rango')),
                    for (var r = 0; r < StatService.rangos.length; r++)
                      DropdownMenuItem(
                        value: r,
                        child: Text(StatService.rangos[r]),
                      ),
                  ],
                  onChanged: (v) => setState(() => n.rango = v ?? n.rango),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppTheme.danger,
                  size: e.t(5.5),
                ),
                tooltip: 'Quitar nivel',
                onPressed: _niveles.length > 1 ? () => _quitarNivel(i) : null,
              ),
            ],
          ),
          SizedBox(height: e.h(1)),
          TextField(
            key: ValueKey('desc_${identityHashCode(n)}'),
            controller: n.descripcion,
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 5,
            style: estilo,
            decoration: const InputDecoration(
              labelText: 'Qué hace (con datos y unidades)',
              isDense: true,
            ),
          ),
          SizedBox(height: e.h(1)),
          TextField(
            key: ValueKey('mana_${identityHashCode(n)}'),
            controller: n.mana,
            style: estilo,
            decoration: const InputDecoration(
              labelText: 'Costo de mana',
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
