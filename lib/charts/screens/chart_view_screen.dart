import 'package:asend/charts/services/chart_service.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/color_picker_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// La gráfica de un ámbito. Arranca mostrando todo el historial;
/// el usuario acerca y arrastra para ver el tramo que quiera.
class ChartViewScreen extends StatefulWidget {
  final ChartScope ambito;
  final String titulo;

  const ChartViewScreen({
    super.key,
    required this.ambito,
    required this.titulo,
  });

  @override
  State<ChartViewScreen> createState() => _ChartViewScreenState();
}

class _ChartViewScreenState extends State<ChartViewScreen> {
  late final List<ChartLine> _lineas = ChartService.getLineas(widget.ambito);
  late final DateTimeRange? _rango = ChartService.getRango(_lineas);

  /// Claves de las líneas apagadas. Todas arrancan encendidas.
  final Set<String> _ocultas = {};

  /// Valor del eje Y donde está el dedo, para elegir el punto más
  /// cercano en vez del más alto del día.
  double? _tocadoY;

  /// Índice, dentro de la lista que llega al tooltip, del punto cuya
  /// altura queda más cerca del dedo.
  int _masCercano(List<LineBarSpot> puntos) {
    if (_tocadoY == null) return 0;

    var mejor = 0;
    var menorDistancia = (puntos[0].y - _tocadoY!).abs();

    for (var i = 1; i < puntos.length; i++) {
      final distancia = (puntos[i].y - _tocadoY!).abs();
      if (distancia < menorDistancia) {
        menorDistancia = distancia;
        mejor = i;
      }
    }
    return mejor;
  }

  /// Las líneas que se dibujan ahora mismo, con su posición original
  /// para que el color por defecto no cambie al apagar otras.
  List<MapEntry<int, ChartLine>> get _visibles => List.generate(
    _lineas.length,
    (i) => MapEntry(i, _lineas[i]),
  ).where((e) => !_ocultas.contains(e.value.clave)).toList();

  static const List<String> _mesesCortos = [
    '',
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  /// El eje X cuenta días desde el primer día con datos.
  double _aX(DateTime fecha) =>
      fecha.difference(_rango!.start).inDays.toDouble();

  DateTime _aFecha(double x) =>
      _rango!.start.add(Duration(days: x.round()));

  /// Días que abarca la gráfica completa.
  int get _totalDias => _rango!.end.difference(_rango!.start).inDays;

  /// Acercamiento máximo: el necesario para que quepa una semana.
  /// Con poco historial no tiene sentido acercar mucho.
  double get _maxScale {
    if (_totalDias <= 7) return 1;
    return (_totalDias / 7).clamp(1.0, 60.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gráfica de ${widget.titulo}'),
        centerTitle: true,
      ),
      body: _rango == null ? _vacio() : _contenido(),
    );
  }

  Widget _vacio() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 56, color: AppTheme.textHint),
            SizedBox(height: 16),
            Text(
              'Aún no hay datos que graficar',
              style: TextStyle(color: AppTheme.textHint, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenido() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${_fechaCorta(_rango!.start)} — ${_fechaCorta(_rango!.end)}',
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 24, 16),
            child: LineChart(
              _datos(),
              transformationConfig: FlTransformationConfig(
                scaleAxis: FlScaleAxis.horizontal,
                maxScale: _maxScale,
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: AppTheme.bgDarkGrey),
        Expanded(
          flex: 2,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            children: List.generate(_lineas.length, _filaLinea),
          ),
        ),
      ],
    );
  }

  /// Una fila por línea: casilla para encenderla, su nombre, y un
  /// cuadro a la derecha para cambiarle el color.
  Widget _filaLinea(int i) {
    final linea = _lineas[i];
    final color = ChartService.getColor(linea.clave, i);
    final encendida = !_ocultas.contains(linea.clave);

    return Row(
      children: [
        Checkbox(
          value: encendida,
          onChanged: (_) => setState(() {
            if (encendida) {
              _ocultas.add(linea.clave);
            } else {
              _ocultas.remove(linea.clave);
            }
          }),
          fillColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.selected)
                ? color
                : AppTheme.disabled,
          ),
        ),
        Expanded(
          child: Text(
            linea.nombre,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: encendida ? AppTheme.textWhite : AppTheme.textHint,
              fontSize: 13,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Cambiar color',
          icon: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.textHint),
            ),
          ),
          onPressed: () => _elegirColor(linea, color),
        ),
      ],
    );
  }

  /// Abre el selector a pantalla completa y guarda lo que devuelva.
  /// Si se cancela no se toca nada.
  Future<void> _elegirColor(ChartLine linea, Color actual) async {
    final elegido = await Navigator.push<Color>(
      context,
      MaterialPageRoute(
        builder: (_) => ColorPickerScreen(
          colorInicial: actual,
          titulo: linea.nombre,
        ),
      ),
    );

    if (elegido == null) return;

    await ChartService.setColor(linea.clave, elegido);
    if (!mounted) return;
    setState(() {});
  }

  String _fechaCorta(DateTime d) => '${d.day} ${_mesesCortos[d.month]} ${d.year}';

  LineChartData _datos() {
    return LineChartData(
      minX: 0,
      maxX: _totalDias.toDouble(),
      lineBarsData: _visibles.map((e) {
        final linea = e.value;

        return LineChartBarData(
          spots: linea.puntos
              .map((p) => FlSpot(_aX(p.fecha), p.valor))
              .toList(),
          color: ChartService.getColor(linea.clave, e.key),
          barWidth: 2,
          isCurved: false,
          dotData: const FlDotData(show: false),
        );
      }).toList(),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (v) => FlLine(
          color: AppTheme.textHint.withValues(alpha: 0.15),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (v) => FlLine(
          color: AppTheme.textHint.withValues(alpha: 0.15),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: AppTheme.buttonPurple.withValues(alpha: 0.3),
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (valor, meta) => SideTitleWidget(
              meta: meta,
              child: Text(
                _numero(valor),
                style: const TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (valor, meta) {
              final fecha = _aFecha(valor);
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  '${fecha.day} ${_mesesCortos[fecha.month]}',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchCallback: (evento, respuesta) {
          final y = respuesta?.lineBarSpots?.isNotEmpty ?? false
              ? respuesta!.lineBarSpots!.first.y
              : null;

          // El toque termina: se limpia para el siguiente
          if (evento is FlTapUpEvent ||
              evento is FlPanEndEvent ||
              evento is FlLongPressEnd) {
            _tocadoY = null;
            return;
          }
          if (y != null) _tocadoY = respuesta!.lineBarSpots!.first.y;
        },
        // Solo la línea más cercana al dedo: con muchos datos, mostrar
        // todas las que cruzan ese día llena la pantalla
        getTouchedSpotIndicator: (barData, indices) => indices
            .map(
              (_) => TouchedSpotIndicatorData(
                FlLine(color: barData.color, strokeWidth: 1),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 4,
                        color: bar.color ?? AppTheme.textWhite,
                        strokeWidth: 0,
                      ),
                ),
              ),
            )
            .toList(),
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppTheme.bgDark,
          // La lista llega ordenada por cercanía: solo el primero se
          // dibuja, el resto se devuelve en null y no ocupa espacio
          getTooltipItems: (puntos) {
            final elegido = _masCercano(puntos);

            return List.generate(puntos.length, (i) {
              if (i != elegido) return null;

              final p = puntos[i];
            final entrada = _visibles[p.barIndex];
            final linea = entrada.value;
            final fecha = _aFecha(p.x);

            return LineTooltipItem(
              '${linea.nombre}\n'
              '${_numero(p.y)} · ${fecha.day} ${_mesesCortos[fecha.month]}',
              TextStyle(
                color: ChartService.getColor(linea.clave, entrada.key),
                fontSize: 11,
              ),
            );
            });
          },
        ),
      ),
    );
  }

  /// Quita el .0 de los enteros: 22.5 se queda, 20.0 sale como 20.
  String _numero(double v) => v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(1);
}