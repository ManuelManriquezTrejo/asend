import 'package:asend/charts/services/chart_service.dart';
import 'package:asend/theme/app_theme.dart';
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

  /// Clave de la línea resaltada, o null si ninguna lo está.
  /// La resaltada se dibuja gruesa y las demás se atenúan.
  String? _resaltada;

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

  DateTime _aFecha(double x) => _rango!.start.add(Duration(days: x.round()));

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
    final resaltada = _resaltada == null
        ? null
        : _lineas.firstWhere((l) => l.clave == _resaltada);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            resaltada == null
                ? '${_fechaCorta(_rango!.start)} — ${_fechaCorta(_rango!.end)}'
                : resaltada.nombre,
            style: TextStyle(
              color: resaltada == null
                  ? AppTheme.textGrey
                  : ChartService.getColor(
                      resaltada.clave,
                      _lineas.indexOf(resaltada),
                    ),
              fontSize: 13,
              fontWeight:
                  resaltada == null ? FontWeight.normal : FontWeight.bold,
            ),
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

  /// Una fila por línea: casilla para encenderla, su nombre para
  /// resaltarla en la gráfica, y un cuadro para cambiarle el color.
  Widget _filaLinea(int i) {
    final linea = _lineas[i];
    final color = ChartService.getColor(linea.clave, i);
    final encendida = !_ocultas.contains(linea.clave);
    final resaltada = _resaltada == linea.clave;

    return Row(
      children: [
        Checkbox(
          value: encendida,
          onChanged: (_) => setState(() {
            if (encendida) {
              _ocultas.add(linea.clave);
              // Apagarla también quita el resaltado
              if (resaltada) _resaltada = null;
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
          child: InkWell(
            onTap: encendida
                ? () => setState(() {
                    _resaltada = resaltada ? null : linea.clave;
                  })
                : null,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                linea.nombre,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: !encendida
                      ? AppTheme.textHint
                      : (resaltada ? color : AppTheme.textWhite),
                  fontSize: 13,
                  fontWeight:
                      resaltada ? FontWeight.bold : FontWeight.normal,
                ),
              ),
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
          onPressed: () => _elegirColor(linea.clave),
        ),
      ],
    );
  }

  /// Paleta con los colores disponibles. Al tocar uno se guarda.
  Future<void> _elegirColor(String clave) async {
    final elegido = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Color de la línea',
          style: TextStyle(color: AppTheme.textWhite, fontSize: 16),
        ),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ChartService.coloresPorDefecto
              .map(
                (c) => InkWell(
                  onTap: () => Navigator.pop(ctx, c),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.textHint),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
        ],
      ),
    );

    if (elegido == null) return;

    await ChartService.setColor(clave, elegido);
    if (!mounted) return;
    setState(() {});
  }

  String _fechaCorta(DateTime d) =>
      '${d.day} ${_mesesCortos[d.month]} ${d.year}';

  LineChartData _datos() {
    return LineChartData(
      minX: 0,
      maxX: _totalDias.toDouble(),
      lineBarsData: _visibles.map((e) {
        final linea = e.value;
        final color = ChartService.getColor(linea.clave, e.key);
        final esResaltada = _resaltada == linea.clave;
        final hayResaltada = _resaltada != null;

        return LineChartBarData(
          spots: linea.puntos
              .map((p) => FlSpot(_aX(p.fecha), p.valor))
              .toList(),
          // Con una resaltada, las demás se atenúan para que destaque
          color: hayResaltada && !esResaltada
              ? color.withValues(alpha: 0.2)
              : color,
          barWidth: esResaltada ? 4 : 2,
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
          // Con una línea resaltada solo se muestra esa; sin ninguna,
          // el primer punto del día, que es el de valor más alto
          getTooltipItems: (puntos) {
            var elegido = 0;

            if (_resaltada != null) {
              for (var i = 0; i < puntos.length; i++) {
                if (_visibles[puntos[i].barIndex].value.clave == _resaltada) {
                  elegido = i;
                  break;
                }
              }
            }

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
  String _numero(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}