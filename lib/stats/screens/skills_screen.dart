import 'package:asend/models/skill.dart';
import 'package:asend/stats/screens/edit_skill_screen.dart';
import 'package:asend/stats/services/stat_service.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';

/// Ver habilidades. Por defecto solo las obtenidas y, de cada una, solo
/// el nivel más alto. Filtros por magia, tipo y rango.
class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  /// Valor del filtro para las habilidades de magia única.
  static const int _magiaUnica = -1;

  /// null = todas las magias.
  int? _magiaFiltro;

  /// null = todos los tipos.
  String? _tipoFiltro;

  /// null = todos los rangos; −1 = sin rango.
  int? _rangoFiltro;

  bool _mostrarNoObtenidas = false;
  bool _mostrarInferiores = false;

  void _abrir(Widget pantalla) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pantalla),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  /// Niveles de una habilidad que se muestran con los filtros actuales,
  /// cada uno con si ya se tiene.
  List<({SkillLevel nivel, bool obtenido})> _nivelesVisibles(Skill s) {
    final rangoActual = StatService.rangoParaHabilidad(s);
    final obtenidos = <SkillLevel>[];
    final faltantes = <SkillLevel>[];
    for (final n in s.niveles) {
      if (StatService.nivelObtenido(n, rangoActual)) {
        obtenidos.add(n);
      } else {
        faltantes.add(n);
      }
    }

    final visibles = <({SkillLevel nivel, bool obtenido})>[];

    // Las versiones anteriores solo si se pide; si no, la más poderosa
    if (obtenidos.isNotEmpty) {
      final mostrar = _mostrarInferiores ? obtenidos : [obtenidos.last];
      for (final n in mostrar) {
        visibles.add((nivel: n, obtenido: true));
      }
    }

    if (_mostrarNoObtenidas) {
      final mostrar = _mostrarInferiores || obtenidos.isEmpty
          ? faltantes
          : faltantes.take(1).toList();
      for (final n in mostrar) {
        visibles.add((nivel: n, obtenido: false));
      }
    }

    if (_rangoFiltro != null) {
      visibles.removeWhere((v) => v.nivel.rango != _rangoFiltro);
    }
    return visibles;
  }

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);

    final habilidades = StatService.getHabilidades().where((s) {
      if (_magiaFiltro == _magiaUnica && s.magicId != null) return false;
      if (_magiaFiltro != null &&
          _magiaFiltro != _magiaUnica &&
          s.magicId != _magiaFiltro) {
        return false;
      }
      if (_tipoFiltro != null && s.tipo != _tipoFiltro) return false;
      return true;
    });

    final tarjetas = <Widget>[];
    for (final s in habilidades) {
      final niveles = _nivelesVisibles(s);
      if (niveles.isEmpty) continue;
      tarjetas.add(_tarjeta(e, s, niveles));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Habilidades')),
      body: Column(
        children: [
          _filtros(e),
          Padding(
            padding: EdgeInsets.fromLTRB(e.w(5), e.h(1), e.w(5), 0),
            child: Row(
              children: [
                Text(
                  '${tarjetas.length} habilidades · '
                  'Rango general ${StatService.letra(StatService.rangoGeneral())}',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.4)),
                ),
              ],
            ),
          ),
          Expanded(
            child: tarjetas.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(e.w(8)),
                      child: Text(
                        _mostrarNoObtenidas
                            ? 'No hay habilidades con estos filtros'
                            : 'Aún no tienes habilidades con estos filtros.\n'
                                  'Activa "No obtenidas" para ver las que faltan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: e.t(3.8),
                        ),
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
                    children: tarjetas,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filtros(Escala e) {
    final magias = StatService.getMagias();
    final estilo = TextStyle(color: AppTheme.textWhite, fontSize: e.t(3.6));

    return Container(
      color: AppTheme.bgDarkGrey,
      padding: EdgeInsets.symmetric(horizontal: e.w(4), vertical: e.h(0.5)),
      child: Column(
        children: [
          Wrap(
            spacing: e.w(4),
            children: [
              DropdownButton<int?>(
                value: _magiaFiltro,
                dropdownColor: AppTheme.bgDarkGrey,
                style: estilo,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toda magia')),
                  for (final m in magias)
                    DropdownMenuItem(value: m.id, child: Text(m.nombre)),
                  const DropdownMenuItem(
                    value: _magiaUnica,
                    child: Text('Magia única'),
                  ),
                ],
                onChanged: (v) => setState(() => _magiaFiltro = v),
              ),
              DropdownButton<String?>(
                value: _tipoFiltro,
                dropdownColor: AppTheme.bgDarkGrey,
                style: estilo,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todo tipo')),
                  for (final t in StatService.tiposHabilidad)
                    DropdownMenuItem(value: t, child: Text(t)),
                ],
                onChanged: (v) => setState(() => _tipoFiltro = v),
              ),
              DropdownButton<int?>(
                value: _rangoFiltro,
                dropdownColor: AppTheme.bgDarkGrey,
                style: estilo,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todo rango')),
                  for (var r = 0; r < StatService.rangos.length; r++)
                    DropdownMenuItem(
                      value: r,
                      child: Text('Rango ${StatService.rangos[r]}'),
                    ),
                  const DropdownMenuItem(value: -1, child: Text('Sin rango')),
                ],
                onChanged: (v) => setState(() => _rangoFiltro = v),
              ),
            ],
          ),
          Row(
            children: [
              Flexible(
                child: _interruptor(
                  e,
                  texto: 'No obtenidas',
                  valor: _mostrarNoObtenidas,
                  onChanged: (v) => setState(() => _mostrarNoObtenidas = v),
                ),
              ),
              Flexible(
                child: _interruptor(
                  e,
                  texto: 'Niveles inferiores',
                  valor: _mostrarInferiores,
                  onChanged: (v) => setState(() => _mostrarInferiores = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _interruptor(
    Escala e, {
    required String texto,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: valor,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primary,
        ),
        Flexible(
          child: Text(
            texto,
            style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.4)),
          ),
        ),
      ],
    );
  }

  Widget _tarjeta(
    Escala e,
    Skill s,
    List<({SkillLevel nivel, bool obtenido})> niveles,
  ) {
    final magia = s.magicId == null ? null : StatService.getMagia(s.magicId!);
    final origen = magia?.nombre ?? 'Magia única';
    final algunoObtenido = niveles.any((n) => n.obtenido);

    return Container(
      margin: EdgeInsets.only(bottom: e.h(1.2)),
      padding: EdgeInsets.fromLTRB(e.w(4), e.h(1.2), e.w(2), e.h(1.2)),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkGrey,
        borderRadius: BorderRadius.circular(e.t(2.5)),
        border: Border.all(
          color: algunoObtenido ? AppTheme.primary : AppTheme.textHint,
          width: algunoObtenido ? 1.5 : 1,
        ),
      ),
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
                        fontSize: e.t(4.3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$origen · ${s.tipo}',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: e.t(3.3),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: AppTheme.textHint, size: e.t(5)),
                tooltip: 'Editar',
                onPressed: () => _abrir(EditSkillScreen(skillId: s.id)),
              ),
            ],
          ),
          if (s.nota.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: e.h(0.4), right: e.w(2)),
              child: Text(
                s.nota,
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: e.t(3.4),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          for (final v in niveles) _nivel(e, v.nivel, v.obtenido),
        ],
      ),
    );
  }

  Widget _nivel(Escala e, SkillLevel n, bool obtenido) {
    final colorTexto = obtenido ? AppTheme.textWhite : AppTheme.textHint;

    return Padding(
      padding: EdgeInsets.only(top: e.h(1), right: e.w(2)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: e.w(9),
            child: Text(
              StatService.letra(n.rango),
              style: TextStyle(
                color: obtenido ? AppTheme.primary : AppTheme.textHint,
                fontSize: e.t(4.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.descripcion,
                  style: TextStyle(color: colorTexto, fontSize: e.t(3.7)),
                ),
                if (n.mana.isNotEmpty)
                  Text(
                    'Costo de mana: ${n.mana}',
                    style: TextStyle(
                      color: obtenido ? AppTheme.textGrey : AppTheme.textHint,
                      fontSize: e.t(3.3),
                    ),
                  ),
              ],
            ),
          ),
          if (!obtenido)
            Icon(Icons.lock_outline, color: AppTheme.textHint, size: e.t(4.5)),
        ],
      ),
    );
  }
}
