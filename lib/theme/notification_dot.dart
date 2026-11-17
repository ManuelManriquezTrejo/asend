import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Pone un punto rojo de aviso en la esquina superior derecha de [child]
/// cuando [visible] es true. Marca algo que necesita revisión, como un
/// fondo o una configuración que apunta a una cuenta eliminada.
class NotificationDot extends StatelessWidget {
  final Widget child;
  final bool visible;
  final double tamano;

  const NotificationDot({
    super.key,
    required this.child,
    required this.visible,
    this.tamano = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              width: tamano,
              height: tamano,
              decoration: BoxDecoration(
                color: AppTheme.danger,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.bgDark, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}