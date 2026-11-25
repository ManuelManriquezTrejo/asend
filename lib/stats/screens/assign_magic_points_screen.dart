import 'package:asend/models/magic.dart';
import 'package:asend/stats/services/stat_service.dart';
import 'package:asend/stats/widgets/stat_widgets.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';

/// Repartir los puntos de magia: cuántos hay disponibles y, por cada
/// magia, cuántos tiene y cuántos le faltan para subir de rango.
class AssignMagicPointsScreen extends StatefulWidget {
  const AssignMagicPointsScreen({super.key});

  @override
  State<AssignMagicPointsScreen> createState() =>
      _AssignMagicPointsScreenState();
}

class _AssignMagicPointsScreenState extends State<AssignMagicPointsScreen> {
  void _aviso(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Suma o quita puntos. Si quitar la baja de rango, pide confirmar.
  Future<void> _mover(Magic m, int cantidad) async {
    if (cantidad == 0) return;

    if (cantidad < 0) {
      final antes = StatService.rangoMagia(m);
      final despues = StatService.rangoDe(
        (m.puntos + cantidad).clamp(0, m.puntos),
        m.umbrales,
      );
      if (despues < antes) {
        final seguro = await confirmar(
          context,
          titulo: 'Baja de rango',
          mensaje:
              '${m.nombre} pasa de ${StatService.letra(antes)} a '
              '${StatService.letra(despues)} y pierde las habilidades de '
              'esos rangos. Los puntos regresan a disponibles.',
          boton: 'Quitar',
          peligro: true,
        );
        if (!seguro) return;
      }
    }

    final error = await StatService.asignarPuntos(m, cantidad);
    if (!mounted) return;
    if (error != null) _aviso(error);
    setState(() {});
  }

  Future<void> _cantidad(Magic m) async {
    final texto = await pedirTexto(
      context,
      titulo: m.nombre,
      etiqueta: 'Cantidad (negativa para quitar)',
      numerico: true,
      validar: (t) => int.tryParse(t.trim()) == null
          ? 'Escribe un número entero, por ejemplo 5 o -5'
          : null,
    );
    if (texto == null || !mounted) return;
    await _mover(m, int.parse(texto.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final e = Escala(context);
    final magias = StatService.getMagias();
    final disponibles = StatService.puntosMagiaDisponibles();

    return Scaffold(
      appBar: AppBar(title: const Text('Repartir puntos de magia')),
      body: ListView(
        padding: EdgeInsets.all(e.w(5)),
        children: [
          Recuadro(
            resaltado: true,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Puntos disponibles',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: e.t(4.3),
                    ),
                  ),
                ),
                Text(
                  '$disponibles',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: e.t(7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: e.w(2)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: e.h(1.5)),
            child: Text(
              'Total ganado por Mana: ${StatService.puntosMagiaTotales()}. '
              'Los que no asignes se quedan pendientes.',
              style: TextStyle(color: AppTheme.textHint, fontSize: e.t(3.3)),
            ),
          ),
          for (final m in magias) _tarjeta(e, m, disponibles),
        ],
      ),
    );
  }

  Widget _tarjeta(Escala e, Magic m, int disponibles) {
    final rango = StatService.rangoMagia(m);
    final siguiente = StatService.siguienteUmbral(rango, m.umbrales);
    final faltan = siguiente == null
        ? 'Rango máximo'
        : 'Faltan ${StatService.numero(siguiente - m.puntos)} para '
              '${StatService.letra(rango + 1)}';

    return Recuadro(
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
                      m.nombre,
                      style: TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: e.t(4.3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${m.puntos} pts · $faltan',
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: e.t(3.4),
                      ),
                    ),
                  ],
                ),
              ),
              LetraRango(rango: rango, tamano: e.t(7)),
              SizedBox(width: e.w(2)),
            ],
          ),
          SizedBox(height: e.h(0.8)),
          Padding(
            padding: EdgeInsets.only(right: e.w(2)),
            child: BarraProgreso(puntos: m.puntos, umbrales: m.umbrales),
          ),
          SizedBox(height: e.h(0.5)),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle_outline, size: e.t(7)),
                color: AppTheme.textGrey,
                tooltip: 'Quitar 1',
                onPressed: m.puntos > 0 ? () => _mover(m, -1) : null,
              ),
              IconButton(
                icon: Icon(Icons.add_circle, size: e.t(7)),
                color: AppTheme.primary,
                tooltip: 'Agregar 1',
                onPressed: disponibles > 0 ? () => _mover(m, 1) : null,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _cantidad(m),
                child: Text(
                  'Otra cantidad',
                  style: TextStyle(color: AppTheme.primary),
                ),
              ),
              TextButton(
                onPressed: disponibles > 0
                    ? () => _mover(m, disponibles)
                    : null,
                child: Text(
                  'Todos',
                  style: TextStyle(
                    color: disponibles > 0
                        ? AppTheme.primary
                        : AppTheme.textHint,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
