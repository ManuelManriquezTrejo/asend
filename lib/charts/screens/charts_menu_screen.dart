import 'package:asend/charts/services/chart_service.dart';
import 'package:asend/charts/screens/chart_view_screen.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Un módulo del menú. Con más de un ámbito, se despliega para elegir.
class _Fuente {
  final IconData icono;
  final String nombre;
  final List<_SubOpcion> opciones;

  const _Fuente(this.icono, this.nombre, this.opciones);
}

/// Un ámbito concreto que se puede graficar.
class _SubOpcion {
  final String nombre;
  final ChartScope ambito;

  const _SubOpcion(this.nombre, this.ambito);
}

const List<_Fuente> _fuentes = [
  _Fuente(Icons.fitness_center, 'Gym', [
    _SubOpcion('Peso', ChartScope.gymPeso),
    _SubOpcion('Repeticiones', ChartScope.gymReps),
  ]),
  _Fuente(Icons.straighten, 'Medidas', [
    _SubOpcion('Medidas', ChartScope.medidas),
  ]),
  _Fuente(Icons.checklist, 'Rutina', [
    _SubOpcion('Por hora', ChartScope.rutinaHora),
    _SubOpcion('Por nota', ChartScope.rutinaNota),
  ]),
  _Fuente(Icons.payments, 'Pagos', [
    _SubOpcion('Pagos', ChartScope.pagos),
  ]),
];

class ChartsMenuScreen extends StatefulWidget {
  const ChartsMenuScreen({super.key});

  @override
  State<ChartsMenuScreen> createState() => _ChartsMenuScreenState();
}

class _ChartsMenuScreenState extends State<ChartsMenuScreen> {
  /// Nombre de la fuente desplegada, o null si ninguna lo está.
  String? _abierta;

  void _abrirGrafica(ChartScope ambito, String titulo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChartViewScreen(ambito: ambito, titulo: titulo),
      ),
    );
  }

  /// Con una sola opción entra directo; con dos las despliega.
  void _tocarFuente(_Fuente fuente) {
    if (fuente.opciones.length == 1) {
      _abrirGrafica(fuente.opciones.first.ambito, fuente.nombre);
      return;
    }

    setState(() {
      _abierta = _abierta == fuente.nombre ? null : fuente.nombre;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gráficas'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '¿Qué quieres ver?',
            style: TextStyle(color: AppTheme.textWhite, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ..._fuentes.map(_tarjeta),
        ],
      ),
    );
  }

  Widget _tarjeta(_Fuente fuente) {
    final abierta = _abierta == fuente.nombre;
    final tieneVarias = fuente.opciones.length > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.bgDarkGrey,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: AppTheme.buttonPurple.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Icon(fuente.icono, color: AppTheme.buttonPurple),
              title: Text(
                fuente.nombre,
                style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(
                tieneVarias
                    ? (abierta ? Icons.expand_less : Icons.expand_more)
                    : Icons.chevron_right,
                color: AppTheme.textHint,
              ),
              onTap: () => _tocarFuente(fuente),
            ),
            if (abierta)
              ...fuente.opciones.map(
                (o) => ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 56, right: 16),
                  title: Text(
                    o.nombre,
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 14,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textHint,
                    size: 20,
                  ),
                  onTap: () =>
                      _abrirGrafica(o.ambito, '${fuente.nombre} · ${o.nombre}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}