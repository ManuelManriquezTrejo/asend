import 'dart:math' as math;

import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Qué tanto abarca cada barra a cada lado del valor actual.
const double _rangoMatiz = 20; // grados
const double _rangoSaturacion = 0.15;
const double _rangoBrillo = 0.15;

/// Los doce matices que arman el degradado en abanico del círculo.
/// El último repite al primero para que el rojo cierre sin costura.
final List<Color> _matices = List.generate(
  13,
  (i) => HSVColor.fromAHSV(1, (i * 30) % 360, 1, 1).toColor(),
);

/// Pantalla completa para elegir un color. Devuelve el Color elegido,
/// o null si se cancela.
class ColorPickerScreen extends StatefulWidget {
  /// El color desde el que se parte.
  final Color colorInicial;

  /// A qué se le está cambiando el color. Se muestra arriba.
  final String titulo;

  const ColorPickerScreen({
    super.key,
    required this.colorInicial,
    required this.titulo,
  });

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  /// El color que se está armando, en matiz, saturación y brillo.
  late HSVColor _actual = HSVColor.fromColor(widget.colorInicial);

  /// Centro de cada barra. Se recorre al soltar el dedo, pero nunca
  /// hasta las orillas: con brillo o saturación en cero el color se
  /// vuelve negro o gris y la barra dejaría de mostrar por dónde
  /// regresar. Un mínimo de 0.08 deja siempre un hilo de color.
  late double _anclaMatiz = _actual.hue;
  late double _anclaSaturacion = _actual.saturation.clamp(0.08, 1.0);
  late double _anclaBrillo = _actual.value.clamp(0.08, 1.0);

  /// Lo que el usuario escribe en el campo de hexadecimal.
  final TextEditingController _hexCtrl = TextEditingController();

  /// Mientras se escribe, el campo manda y no se sobrescribe solo.
  bool _escribiendo = false;

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  Color get _color => _actual.withAlpha(1).toColor();

  /// El color en hexadecimal, sin la parte de opacidad.
  String get _hex =>
      '#${_color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  /// Posición de la manija dentro de la barra, de 0 a 1.
  double _posicion(double valor, double ancla, double rango) =>
      ((valor - ancla) / (2 * rango) + 0.5).clamp(0.0, 1.0);

  /// Lo mismo para el matiz, que da la vuelta: de 350 a 10 son
  /// veinte grados, no trescientos cuarenta.
  double _posicionMatiz() {
    final diferencia = ((_actual.hue - _anclaMatiz + 540) % 360) - 180;
    return (diferencia / (2 * _rangoMatiz) + 0.5).clamp(0.0, 1.0);
  }

  /// Valor que le toca a una posición de la barra.
  double _valor(double t, double ancla, double rango) =>
      ancla + (t * 2 - 1) * rango;

  /// Los colores que se ven a lo largo de una barra.
  List<Color> _muestras(HSVColor Function(double t) colorEn) =>
      List.generate(24, (i) => colorEn(i / 23).toColor());

  /// El dedo sobre el círculo: el ángulo es el matiz y la distancia
  /// al centro la saturación. Aquí las anclas sí se mueven en vivo.
  void _tocarCirculo(Offset punto, double lado) {
    final centro = Offset(lado / 2, lado / 2);
    final radio = lado / 2;
    final desde = punto - centro;

    final matiz = (math.atan2(desde.dy, desde.dx) * 180 / math.pi + 360) % 360;
    final saturacion = (desde.distance / radio).clamp(0.0, 1.0);

    setState(() {
      _actual = _actual.withHue(matiz).withSaturation(saturacion);
      _anclaMatiz = matiz;
      _anclaSaturacion = saturacion.clamp(0.08, 1.0);
    });
  }

  /// Toma lo que se escribió y, si son seis caracteres válidos,
  /// mueve el color y recentra las tres barras.
  void _aplicarHex(String texto) {
    final limpio = texto.replaceAll('#', '').trim();
    if (limpio.length != 6) return;

    final numero = int.tryParse(limpio, radix: 16);
    if (numero == null) return;

    final color = Color(0xFF000000 | numero);
    final hsv = HSVColor.fromColor(color);

    setState(() {
      _actual = hsv;
      _anclaMatiz = hsv.hue;
      _anclaSaturacion = hsv.saturation.clamp(0.08, 1.0);
      _anclaBrillo = hsv.value.clamp(0.08, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    // El campo sigue al color, salvo mientras se está escribiendo
    if (!_escribiendo) {
      final texto = _hex.substring(1);
      if (_hexCtrl.text != texto) _hexCtrl.text = texto;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) _cancelar();
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              children: [
                _encabezado(),
                Expanded(child: _circulo()),
                const SizedBox(height: 8),
                _barras(),
                const SizedBox(height: 12),
                _pie(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Arriba: qué se está cambiando, pintado con el color de ahora,
  /// y su hexadecimal, que también se puede escribir a mano.
  Widget _encabezado() {
    return Column(
      children: [
        Text(
          widget.titulo,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.textHint),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '#',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
            ),
            SizedBox(
              width: 86,
              child: TextField(
                controller: _hexCtrl,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  counterText: '',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                ),
                onTap: () => _escribiendo = true,
                onChanged: _aplicarHex,
                onSubmitted: (_) => setState(() => _escribiendo = false),
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                  setState(() => _escribiendo = false);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _circulo() {
    return Center(
      child: LayoutBuilder(
        builder: (contexto, limites) {
          final lado = math.min(limites.maxWidth, limites.maxHeight);
          return GestureDetector(
            onTapDown: (d) => _tocarCirculo(d.localPosition, lado),
            onPanDown: (d) => _tocarCirculo(d.localPosition, lado),
            onPanUpdate: (d) => _tocarCirculo(d.localPosition, lado),
            child: CustomPaint(
              size: Size(lado, lado),
              painter: _CirculoPainter(
                matiz: _actual.hue,
                saturacion: _actual.saturation,
                brillo: _actual.value,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _barras() {
    // Fuera del rango válido la barra se apaga. El matiz da la
    // vuelta, así que nunca tiene zonas muertas.
    final minSaturacion = 0.5 - _anclaSaturacion / (2 * _rangoSaturacion);
    final maxSaturacion = 0.5 + (1 - _anclaSaturacion) / (2 * _rangoSaturacion);
    final minBrillo = 0.5 - _anclaBrillo / (2 * _rangoBrillo);
    final maxBrillo = 0.5 + (1 - _anclaBrillo) / (2 * _rangoBrillo);

    return Column(
      children: [
        _barra(
          etiqueta: 'Color',
          muestras: _muestras(
            (t) => _actual.withHue(
              (_valor(t, _anclaMatiz, _rangoMatiz) + 360) % 360,
            ),
          ),
          posManija: _posicionMatiz(),
          tMin: 0,
          tMax: 1,
          onArrastre: (t) => setState(() {
            _actual = _actual.withHue(
              (_valor(t, _anclaMatiz, _rangoMatiz) + 360) % 360,
            );
          }),
          onSoltar: () => setState(() => _anclaMatiz = _actual.hue),
        ),
        _barra(
          etiqueta: 'Saturación',
          muestras: _muestras(
            (t) => _actual.withSaturation(
              _valor(t, _anclaSaturacion, _rangoSaturacion).clamp(0.0, 1.0),
            ),
          ),
          posManija: _posicion(
            _actual.saturation,
            _anclaSaturacion,
            _rangoSaturacion,
          ),
          tMin: minSaturacion,
          tMax: maxSaturacion,
          onArrastre: (t) => setState(() {
            _actual = _actual.withSaturation(
              _valor(t, _anclaSaturacion, _rangoSaturacion).clamp(0.0, 1.0),
            );
          }),
          onSoltar: () => setState(
            () => _anclaSaturacion = _actual.saturation.clamp(0.08, 1.0),
          ),
        ),
        _barra(
          etiqueta: 'Tono',
          muestras: _muestras(
            (t) => _actual.withValue(
              _valor(t, _anclaBrillo, _rangoBrillo).clamp(0.0, 1.0),
            ),
          ),
          posManija: _posicion(_actual.value, _anclaBrillo, _rangoBrillo),
          tMin: minBrillo,
          tMax: maxBrillo,
          onArrastre: (t) => setState(() {
            _actual = _actual.withValue(
              _valor(t, _anclaBrillo, _rangoBrillo).clamp(0.0, 1.0),
            );
          }),
          onSoltar: () => setState(
            () => _anclaBrillo = _actual.value.clamp(0.08, 1.0),
          ),
        ),
      ],
    );
  }

  Widget _barra({
    required String etiqueta,
    required List<Color> muestras,
    required double posManija,
    required double tMin,
    required double tMax,
    required void Function(double t) onArrastre,
    required VoidCallback onSoltar,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (contexto, limites) {
              final ancho = limites.maxWidth;
              double aT(Offset p) => (p.dx / ancho).clamp(0.0, 1.0);

              return GestureDetector(
                onTapDown: (d) => onArrastre(aT(d.localPosition)),
                onTapUp: (_) => onSoltar(),
                onHorizontalDragStart: (d) => onArrastre(aT(d.localPosition)),
                onHorizontalDragUpdate: (d) => onArrastre(aT(d.localPosition)),
                onHorizontalDragEnd: (_) => onSoltar(),
                child: CustomPaint(
                  size: Size(ancho, 30),
                  painter: _BarraPainter(
                    muestras: muestras,
                    posManija: posManija,
                    tMin: tMin.clamp(0.0, 1.0),
                    tMax: tMax.clamp(0.0, 1.0),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Abajo: cada botón con su muestra encima. Izquierda el color
  /// de antes, derecha el de ahora.
  Widget _pie() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _bloqueBoton(
          muestra: widget.colorInicial,
          leyenda: 'Antes',
          texto: 'Cancelar',
          fondo: AppTheme.danger,
          onPressed: _cancelar,
        ),
        _bloqueBoton(
          muestra: _color,
          leyenda: 'Ahora',
          texto: 'Confirmar',
          fondo: AppTheme.success,
          onPressed: _confirmar,
        ),
      ],
    );
  }

  Widget _bloqueBoton({
    required Color muestra,
    required String leyenda,
    required String texto,
    required Color fondo,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Text(
          leyenda,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Container(
          width: 120,
          height: 40,
          decoration: BoxDecoration(
            color: muestra,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.textHint),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: fondo,
              foregroundColor: AppTheme.textWhite,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(texto, style: const TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmar() async {
    final seguro = await _preguntar(
      'Guardar color',
      '¿Dejar este color para ${widget.titulo}?',
    );
    if (!seguro) return;
    if (!mounted) return;
    Navigator.pop(context, _color);
  }

  Future<void> _cancelar() async {
    final seguro = await _preguntar(
      'Descartar cambios',
      '¿Salir sin guardar el color nuevo?',
    );
    if (!seguro) return;
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<bool> _preguntar(String titulo, String mensaje) async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          titulo,
          style: const TextStyle(color: AppTheme.textWhite, fontSize: 16),
        ),
        content: Text(
          mensaje,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'No',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sí',
              style: TextStyle(color: AppTheme.buttonPurple),
            ),
          ),
        ],
      ),
    );
    return respuesta ?? false;
  }
}

/// El círculo: matiz en el ángulo, saturación en el radio.
/// Se arma encimando tres figuras en lugar de calcular píxel por píxel.
class _CirculoPainter extends CustomPainter {
  final double matiz;
  final double saturacion;
  final double brillo;

  const _CirculoPainter({
    required this.matiz,
    required this.saturacion,
    required this.brillo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = size.width / 2;
    final area = Rect.fromCircle(center: centro, radius: radio);

    // Los matices, en abanico alrededor del centro
    canvas.drawCircle(
      centro,
      radio,
      Paint()..shader = SweepGradient(colors: _matices).createShader(area),
    );

    // Blanco al centro que se desvanece: eso es la saturación
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.textWhite,
            AppTheme.textWhite.withValues(alpha: 0),
          ],
        ).createShader(area),
    );

    // Velo negro encima: eso es el tono. Se topa en 0.85 para que
    // el círculo nunca quede completamente negro y se siga viendo
    // dónde está uno parado.
    if (brillo < 1) {
      canvas.drawCircle(
        centro,
        radio,
        Paint()
          ..color = AppTheme.bgDark.withValues(
            alpha: ((1 - brillo) * 0.85).clamp(0.0, 0.85),
          ),
      );
    }

    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppTheme.textHint,
    );

    // El cuadrito que marca dónde quedó el color
    final angulo = matiz * math.pi / 180;
    final punto =
        centro +
        Offset(math.cos(angulo), math.sin(angulo)) * (saturacion * radio);
    final marca = Rect.fromCenter(center: punto, width: 18, height: 18);

    canvas.drawRect(
      marca,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppTheme.textWhite,
    );
    canvas.drawRect(
      marca,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppTheme.bgDark,
    );
  }

  @override
  bool shouldRepaint(_CirculoPainter anterior) =>
      anterior.matiz != matiz ||
      anterior.saturacion != saturacion ||
      anterior.brillo != brillo;
}

/// Una barra de ajuste fino: el degradado muestra hasta dónde
/// se puede llegar desde el color de ahora.
class _BarraPainter extends CustomPainter {
  final List<Color> muestras;
  final double posManija;

  /// Tramo de la barra que sí tiene colores válidos.
  final double tMin;
  final double tMax;

  const _BarraPainter({
    required this.muestras,
    required this.posManija,
    required this.tMin,
    required this.tMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    final borde = RRect.fromRectAndRadius(area, const Radius.circular(8));

    canvas.save();
    canvas.clipRRect(borde);

    canvas.drawRect(
      area,
      Paint()..shader = LinearGradient(colors: muestras).createShader(area),
    );

    final apagado = Paint()..color = AppTheme.bgDarkGrey;
    if (tMin > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * tMin, size.height),
        apagado,
      );
    }
    if (tMax < 1) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * tMax,
          0,
          size.width * (1 - tMax),
          size.height,
        ),
        apagado,
      );
    }

    canvas.restore();

    canvas.drawRRect(
      borde,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppTheme.textHint,
    );

    final x = (size.width * posManija).clamp(6.0, size.width - 6);
    final manija = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, size.height / 2),
        width: 12,
        height: size.height,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(manija, Paint()..color = AppTheme.textWhite);
    canvas.drawRRect(
      manija,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppTheme.bgDark,
    );
  }

  @override
  bool shouldRepaint(_BarraPainter anterior) =>
      anterior.posManija != posManija ||
      anterior.tMin != tMin ||
      anterior.tMax != tMax ||
      anterior.muestras.first != muestras.first ||
      anterior.muestras.last != muestras.last;
}