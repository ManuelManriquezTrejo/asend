import 'dart:math';

import 'package:flutter/widgets.dart';

/// Medidas proporcionales a la pantalla, para que una misma vista se
/// vea bien en un celular y en una tablet sin usar píxeles fijos.
///
/// - [w] y [h]: porcentaje del ancho y del alto de la pantalla.
/// - [t]: porcentaje del lado corto, para letras e iconos. Así no
///   crecen de más al acostar el teléfono.
class Escala {
  final double ancho;
  final double alto;

  Escala(BuildContext context)
    : ancho = MediaQuery.sizeOf(context).width,
      alto = MediaQuery.sizeOf(context).height;

  double w(double porcentaje) => ancho * porcentaje / 100;

  double h(double porcentaje) => alto * porcentaje / 100;

  double t(double porcentaje) => min(ancho, alto) * porcentaje / 100;
}