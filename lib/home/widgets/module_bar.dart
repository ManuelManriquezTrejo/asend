import 'package:asend/bank/screens/bank_screen.dart';
import 'package:asend/birthdays/screens/birthdays_screen.dart';
import 'package:asend/body/screens/body_screen.dart';
import 'package:asend/cashout/screens/cash_out_screen.dart';
import 'package:asend/goals/screens/goals_screen.dart';
import 'package:asend/gym/screens/gym_screen.dart';
import 'package:asend/missions/screens/mission_board_screen.dart';
import 'package:asend/routine/screens/routine_list_screen.dart';
import 'package:asend/store/screens/store_screen.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Un módulo dentro del menú. Sin [destino] = en mantenimiento.
class _Opcion {
  final IconData icono;
  final String etiqueta;
  final Widget Function()? destino;

  const _Opcion(this.icono, this.etiqueta, [this.destino]);
}

/// Un círculo del main con los módulos que despliega.
class _Seccion {
  final IconData icono;
  final String etiqueta;
  final List<_Opcion> opciones;

  const _Seccion(this.icono, this.etiqueta, this.opciones);
}

/// Secciones de izquierda a derecha.
/// Los módulos de cada una van de arriba hacia abajo.
final List<_Seccion> _secciones = [
  _Seccion(Icons.account_balance_wallet, 'Economía', [
    _Opcion(Icons.account_balance, 'Banco', () => const BankScreen()),
    _Opcion(Icons.payments, 'Pagos', () => const CashOutScreen()),
    _Opcion(Icons.shopping_basket, 'Tienda', () => const StoreScreen()),
    _Opcion(Icons.savings, 'Metas', () => const GoalsScreen()),
  ]),
  _Seccion(Icons.bolt, 'Actividades', [
    _Opcion(Icons.checklist, 'Rutina', () => const RoutineListScreen()),
    _Opcion(Icons.map, 'Misiones', () => const MissionBoardScreen()),
  ]),
  _Seccion(Icons.insights, 'Datos', [
    _Opcion(Icons.fitness_center, 'Gym', () => const GymScreen()),
    _Opcion(Icons.straighten, 'Medidas', () => const BodyScreen()),
    _Opcion(Icons.cake, 'Cumpleaños', () => const BirthdaysScreen()),
  ]),
];

/// Barra inferior del main: Economía, Actividades y Datos.
/// Al tocar un círculo se oscurece el fondo y brotan sus módulos encima.
class ModuleBar extends StatelessWidget {
  /// Se llama al volver de un módulo, para refrescar el main.
  final VoidCallback onVolver;

  const ModuleBar({super.key, required this.onVolver});

  @override
  Widget build(BuildContext context) {
    return _Barra(abierta: null, onTocarSeccion: (i) => _abrirMenu(context, i));
  }

  void _abrirMenu(BuildContext context, int seccion) {
    // Se capturan antes de abrir, porque se usan después de cerrar el menú
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar menú',
      barrierColor: AppTheme.bgDark.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 180),
      // El fondo se oscurece solo; los botones animan su propia entrada
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          child,
      pageBuilder: (context, animation, secondaryAnimation) {
        return _MenuAbierto(
          seccionInicial: seccion,
          onElegir: (opcion) {
            navigator.pop(); // Cerrar el menú antes de navegar

            final destino = opcion.destino;
            if (destino == null) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${opcion.etiqueta} - En mantenimiento'),
                ),
              );
              return;
            }

            navigator
                .push(MaterialPageRoute(builder: (context) => destino()))
                .then((_) => onVolver());
          },
        );
      },
    );
  }
}

/// Capa sobre el fondo oscuro. Redibuja la barra en la misma posición
/// y permite cambiar de sección sin cerrar el menú.
class _MenuAbierto extends StatefulWidget {
  final int seccionInicial;
  final ValueChanged<_Opcion> onElegir;

  const _MenuAbierto({required this.seccionInicial, required this.onElegir});

  @override
  State<_MenuAbierto> createState() => _MenuAbiertoState();
}

class _MenuAbiertoState extends State<_MenuAbierto> {
  late int _abierta = widget.seccionInicial;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      // Transparente: los toques fuera de los botones cierran el menú
      child: Material(
        type: MaterialType.transparency,
        child: _Barra(
          abierta: _abierta,
          onTocarSeccion: (i) {
            if (i == _abierta) {
              Navigator.of(context).pop(); // Mismo círculo = cerrar
            } else {
              setState(() => _abierta = i);
            }
          },
          onTocarOpcion: widget.onElegir,
        ),
      ),
    );
  }
}

/// Fila de los 3 círculos. Se dibuja igual en el main y sobre el fondo
/// oscuro, así los círculos quedan exactamente en el mismo lugar.
class _Barra extends StatelessWidget {
  final int? abierta;
  final ValueChanged<int> onTocarSeccion;
  final ValueChanged<_Opcion>? onTocarOpcion;

  const _Barra({
    required this.abierta,
    required this.onTocarSeccion,
    this.onTocarOpcion,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).size.height * 0.02,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_secciones.length, (i) {
          final seccion = _secciones[i];
          final estaAbierta = abierta == i;

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (estaAbierta) ..._opcionesAnimadas(seccion.opciones),
                _Circulo(
                  icono: seccion.icono,
                  etiqueta: seccion.etiqueta,
                  activo: estaAbierta,
                  apagado: abierta != null && !estaAbierta,
                  onTap: () => onTocarSeccion(i),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Los módulos brotan hacia arriba: el más cercano al círculo aparece primero.
  List<Widget> _opcionesAnimadas(List<_Opcion> opciones) {
    return List.generate(opciones.length, (j) {
      final opcion = opciones[j];
      final distancia = opciones.length - 1 - j; // 0 = justo encima del círculo

      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 140 + 50 * distancia),
        curve: Curves.easeOut,
        builder: (context, valor, child) => Opacity(
          opacity: valor,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - valor)),
            child: child,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _Circulo(
            icono: opcion.icono,
            etiqueta: opcion.etiqueta,
            tamano: 48,
            enMenu: true,
            enMantenimiento: opcion.destino == null,
            onTap: () => onTocarOpcion?.call(opcion),
          ),
        ),
      );
    });
  }
}

/// Botón circular con etiqueta debajo. Mismo formato en barra y menús.
class _Circulo extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  final double tamano;
  final bool activo; // Su menú está abierto: aro blanco
  final bool apagado; // Otra sección está abierta: se ve tenue
  final bool enMantenimiento;
  final bool enMenu; // Etiqueta más clara sobre el fondo oscuro

  const _Circulo({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.tamano = 56,
    this.activo = false,
    this.apagado = false,
    this.enMantenimiento = false,
    this.enMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color colorEtiqueta = enMantenimiento
        ? AppTheme.textHint
        : (enMenu ? AppTheme.textWhite : AppTheme.textGrey);

    return Opacity(
      opacity: apagado ? 0.4 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: enMantenimiento ? AppTheme.disabled : AppTheme.buttonPurple,
            shape: CircleBorder(
              side: activo
                  ? const BorderSide(color: AppTheme.textWhite, width: 2)
                  : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: tamano,
                height: tamano,
                child: Icon(icono, color: Colors.black, size: tamano * 0.46),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            style: TextStyle(color: colorEtiqueta, fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
