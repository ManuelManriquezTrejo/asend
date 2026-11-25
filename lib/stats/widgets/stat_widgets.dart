import 'package:asend/stats/services/stat_service.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Barra de progreso hacia el siguiente rango, con el texto
/// "puntos / siguiente → letra" debajo.
class BarraProgreso extends StatelessWidget {
  final num puntos;
  final List<num> umbrales;

  const BarraProgreso({
    super.key,
    required this.puntos,
    required this.umbrales,
  });

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    final rango = StatService.rangoDe(puntos, umbrales);
    final siguiente = StatService.siguienteUmbral(rango, umbrales);

    final texto = siguiente == null
        ? '${StatService.numero(puntos)} pts · Rango máximo'
        : '${StatService.numero(puntos)} / ${StatService.numero(siguiente)} '
              'pts → ${StatService.letra(rango + 1)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(e.t(1.5)),
          child: LinearProgressIndicator(
            value: StatService.avance(puntos, umbrales),
            minHeight: e.h(1),
            color: AppTheme.primary,
            backgroundColor: AppTheme.bgDark,
          ),
        ),
        SizedBox(height: e.h(0.4)),
        Text(
          texto,
          style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.3)),
        ),
      ],
    );
  }
}

/// Barra de datos: lo actual pintado del color del tema y lo gastado
/// en gris, con "actual / máximo" debajo. Se toca para restar o sumar.
class BarraDatos extends StatelessWidget {
  final double actual;
  final double maximo;
  final VoidCallback onTap;

  const BarraDatos({
    super.key,
    required this.actual,
    required this.maximo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    final fraccion = maximo <= 0 ? 0.0 : (actual / maximo).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(e.t(1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(e.t(1.5)),
            child: SizedBox(
              height: e.h(1.4),
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: AppTheme.disabled)),
                  // Lo actual se pinta desde la izquierda
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraccion.toDouble(),
                      child: ColoredBox(color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: e.h(0.4)),
          Text(
            '${StatService.numero(actual)} / ${StatService.numero(maximo)} '
            '· toca para restar o sumar',
            style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.3)),
          ),
        ],
      ),
    );
  }
}

/// Letra del rango en mayúscula, del color del tema.
class LetraRango extends StatelessWidget {
  final int rango;
  final double tamano;

  const LetraRango({super.key, required this.rango, required this.tamano});

  @override
  Widget build(BuildContext context) {
    return Text(
      StatService.letra(rango),
      style: TextStyle(
        color: AppTheme.primary,
        fontSize: tamano,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Título de sección, igual que en Configuración.
class TituloSeccion extends StatelessWidget {
  final String texto;
  final Widget? accion;

  const TituloSeccion(this.texto, {super.key, this.accion});

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    return Padding(
      padding: EdgeInsets.only(bottom: e.h(1)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: e.t(4.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ?accion,
        ],
      ),
    );
  }
}

/// Recuadro gris con esquinas redondeadas donde va cada elemento.
class Recuadro extends StatelessWidget {
  final Widget child;
  final bool resaltado;

  const Recuadro({super.key, required this.child, this.resaltado = false});

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    return Container(
      margin: EdgeInsets.only(bottom: e.h(1.2)),
      padding: EdgeInsets.fromLTRB(e.w(4), e.h(1.2), e.w(2), e.h(1.2)),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkGrey,
        borderRadius: BorderRadius.circular(e.t(2.5)),
        border: resaltado
            ? Border.all(color: AppTheme.primary, width: 1.5)
            : null,
      ),
      // Capa Material transparente: las casillas e interruptores dibujan
      // su efecto al tocar encima del fondo gris y no debajo
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// Botón que va fijo abajo de la pantalla, siempre visible aunque se
/// esté hasta arriba, para que se sepa que hay que guardar. Va en el
/// body (no en bottomNavigationBar) para que suba con el teclado.
class BarraGuardar extends StatelessWidget {
  final VoidCallback? onPressed;
  final String texto;

  const BarraGuardar({super.key, required this.onPressed, this.texto = 'Guardar'});

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgDarkGrey,
        border: Border(top: BorderSide(color: AppTheme.primary, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(e.w(5), e.h(1), e.w(5), e.h(1.5)),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: e.h(5.5),
          child: ElevatedButton(
            onPressed: onPressed,
            child: Text(texto, style: TextStyle(fontSize: e.t(4.2))),
          ),
        ),
      ),
    );
  }
}

/// Los 7 campos de la tabla de rangos: cuántos puntos acumulados pide
/// cada letra, de E a SS.
class EditorUmbrales extends StatelessWidget {
  final List<TextEditingController> controladores;

  const EditorUmbrales({super.key, required this.controladores});

  /// Controladores ya llenos con una tabla.
  static List<TextEditingController> crear(List<int> umbrales) => [
    for (final u in umbrales) TextEditingController(text: '$u'),
  ];

  /// Lee los campos; null en los que no son número entero.
  static List<int?> leer(List<TextEditingController> controladores) => [
    for (final c in controladores) int.tryParse(c.text.trim()),
  ];

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    return Wrap(
      spacing: e.w(2),
      runSpacing: e.h(1),
      children: List.generate(controladores.length, (i) {
        return SizedBox(
          width: e.w(19),
          child: TextField(
            controller: controladores[i],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(4)),
            decoration: InputDecoration(
              labelText: StatService.letra(i + 1),
              isDense: true,
            ),
          ),
        );
      }),
    );
  }
}

/// Pregunta de sí o no. Devuelve true solo si se confirma.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String boton = 'Aceptar',
  bool peligro = false,
}) async {
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo, style: TextStyle(color: AppTheme.textWhite)),
      content: Text(mensaje, style: TextStyle(color: AppTheme.textGrey)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancelar', style: TextStyle(color: AppTheme.textGrey)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            boton,
            style: TextStyle(
              color: peligro ? AppTheme.danger : AppTheme.primary,
            ),
          ),
        ),
      ],
    ),
  );
  return respuesta == true;
}

/// Diálogo con un solo campo de texto. Devuelve lo escrito o null si se
/// cancela. [validar] devuelve null o el error a mostrar.
Future<String?> pedirTexto(
  BuildContext context, {
  required String titulo,
  required String etiqueta,
  String inicial = '',
  bool numerico = false,
  String? Function(String)? validar,
}) async {
  final controlador = TextEditingController(text: inicial);
  String? error;

  final resultado = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(titulo, style: TextStyle(color: AppTheme.textWhite)),
        content: TextField(
          controller: controlador,
          autofocus: true,
          textCapitalization: numerico
              ? TextCapitalization.none
              : TextCapitalization.sentences,
          keyboardType: numerico
              ? const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                )
              : TextInputType.text,
          inputFormatters: numerico
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]'))]
              : null,
          style: TextStyle(color: AppTheme.textWhite),
          decoration: InputDecoration(labelText: etiqueta, errorText: error),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              final texto = controlador.text;
              final mensaje = validar?.call(texto);
              if (mensaje != null) {
                setDialogState(() => error = mensaje);
                return;
              }
              Navigator.pop(context, texto);
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
  controlador.dispose();
  return resultado;
}

/// Convierte texto a número. Acepta coma o punto como decimal.
double? leerNumero(String texto) =>
    double.tryParse(texto.trim().replaceAll(',', '.'));
