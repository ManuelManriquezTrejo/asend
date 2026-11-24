import 'package:asend/bank/services/reconciliation_service.dart';
import 'package:asend/settings/services/app_settings_service.dart';
import 'package:asend/theme/app_theme.dart';
import 'package:asend/theme/color_picker_screen.dart';
import 'package:asend/theme/escala.dart';
import 'package:flutter/material.dart';

/// Configuración de la app, desde el botón ☰ del inicio:
/// Tema, Notificaciones y Uso.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final e = Escala(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: EdgeInsets.all(e.w(5)),
        children: [
          _titulo(e, 'Tema'),
          _cuadrosTema(e),
          SizedBox(height: e.h(2.5)),
          _titulo(e, 'Notificaciones'),
          _interruptor(
            e,
            titulo: 'Diferencias en Banco',
            descripcion: 'Punto rojo cuando un cuadre no cuadra',
            valor: ReconciliationService.avisosActivos(),
            onChanged: (v) async {
              await ReconciliationService.setAvisosActivos(v);
              if (mounted) setState(() {});
            },
          ),
          SizedBox(height: e.h(1)),
          _titulo(e, 'Uso'),
          _interruptor(
            e,
            titulo: 'Stats',
            descripcion: 'En desarrollo',
            valor: AppSettingsService.statsActivo(),
            onChanged: (v) async {
              await AppSettingsService.setStatsActivo(v);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _titulo(Escala e, String texto) {
    return Padding(
      padding: EdgeInsets.only(bottom: e.h(1)),
      child: Text(
        texto,
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: e.t(4.8),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _interruptor(
    Escala e, {
    required String titulo,
    required String descripcion,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: e.h(1.5)),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkGrey,
        borderRadius: BorderRadius.circular(e.t(2.5)),
      ),
      child: SwitchListTile(
        value: valor,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primary,
        title: Text(
          titulo,
          style: TextStyle(color: AppTheme.textWhite, fontSize: e.t(4.2)),
        ),
        subtitle: Text(
          descripcion,
          style: TextStyle(color: AppTheme.textGrey, fontSize: e.t(3.5)),
        ),
      ),
    );
  }

  // ── Tema ───────────────────────────────────────────────

  /// Los 5 cuadros: el morado de fábrica y los 4 que llena el usuario.
  /// Debajo de cada color guardado va su lápiz para editar o eliminar.
  Widget _cuadrosTema(Escala e) {
    final colores = AppSettingsService.coloresGuardados();
    final activo = AppSettingsService.indiceActivo();

    return Container(
      padding: EdgeInsets.symmetric(vertical: e.h(1.5), horizontal: e.w(2)),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkGrey,
        borderRadius: BorderRadius.circular(e.t(2.5)),
      ),
      child: Row(
        children: List.generate(AppSettingsService.maxColores + 1, (i) {
          final Color? color = i == 0
              ? AppTheme.defaultPrimary
              : (i <= colores.length ? colores[i - 1] : null);
          final esSiguienteLibre = i == colores.length + 1;

          return Expanded(
            child: Column(
              children: [
                _cuadro(
                  e,
                  color: color,
                  enUso: color != null && i == activo,
                  libre: esSiguienteLibre,
                  onTap: color != null
                      ? () => _usar(i)
                      : (esSiguienteLibre ? _agregar : null),
                ),
                SizedBox(height: e.h(0.5)),
                // El cuadro 1 y los vacíos no llevan lápiz; el espacio se
                // conserva para que los cuadros queden alineados
                SizedBox(
                  height: e.t(9),
                  child: i > 0 && color != null
                      ? _lapiz(e, i, color)
                      : null,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _cuadro(
    Escala e, {
    required Color? color,
    required bool enUso,
    required bool libre,
    required VoidCallback? onTap,
  }) {
    final lado = e.w(13);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: lado,
        height: lado,
        decoration: BoxDecoration(
          color: color ?? AppTheme.bgDark,
          borderRadius: BorderRadius.circular(e.t(2)),
          border: Border.all(
            color: enUso
                ? AppTheme.textWhite
                : (color == null ? AppTheme.textHint : Colors.transparent),
            width: enUso ? 3 : 1,
          ),
        ),
        child: color == null
            ? (libre
                  ? Icon(Icons.add, color: AppTheme.textGrey, size: e.t(7))
                  : null)
            : (enUso
                  ? Icon(Icons.check, color: _sobre(color), size: e.t(7))
                  : null),
      ),
    );
  }

  /// Blanco o negro, el que se lea mejor encima de [color].
  Color _sobre(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? AppTheme.textWhite
      : AppTheme.textBlack;

  Widget _lapiz(Escala e, int indice, Color color) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.edit, color: AppTheme.textHint, size: e.t(5)),
      color: AppTheme.bgDarkGrey,
      onSelected: (opcion) {
        if (opcion == 'editar') {
          _editar(indice, color);
        } else {
          _eliminar(indice);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'editar',
          child: Text('Editar', style: TextStyle(color: AppTheme.textWhite)),
        ),
        PopupMenuItem(
          value: 'eliminar',
          child: Text('Eliminar', style: TextStyle(color: AppTheme.danger)),
        ),
      ],
    );
  }

  /// Usa el color del cuadro y regresa al inicio ya pintado.
  Future<void> _usar(int indice) async {
    await AppSettingsService.usar(indice);
    if (!mounted) return;
    Navigator.popUntil(context, (ruta) => ruta.isFirst);
  }

  /// Abre la rueda para el siguiente cuadro libre; al guardar se usa.
  Future<void> _agregar() async {
    final elegido = await _abrirRueda(AppTheme.primary);
    if (elegido == null) return;

    await AppSettingsService.guardarColor(elegido);
    if (!mounted) return;
    Navigator.popUntil(context, (ruta) => ruta.isFirst);
  }

  /// Cambia el color de un cuadro; al guardar se usa.
  Future<void> _editar(int indice, Color actual) async {
    final elegido = await _abrirRueda(actual);
    if (elegido == null) return;

    await AppSettingsService.guardarColor(elegido, indice: indice);
    if (!mounted) return;
    Navigator.popUntil(context, (ruta) => ruta.isFirst);
  }

  Future<void> _eliminar(int indice) async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgDarkGrey,
        title: Text(
          'Eliminar color',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Text(
          '¿Eliminar este color? Los de la derecha se recorren.',
          style: TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (seguro != true) return;

    final cambioElColor = await AppSettingsService.eliminar(indice);
    if (!mounted) return;

    // Si era el color en uso, la app vuelve al morado desde el inicio
    if (cambioElColor) {
      Navigator.popUntil(context, (ruta) => ruta.isFirst);
    } else {
      setState(() {});
    }
  }

  Future<Color?> _abrirRueda(Color inicial) {
    return Navigator.push<Color>(
      context,
      MaterialPageRoute(
        builder: (_) => ColorPickerScreen(colorInicial: inicial, titulo: 'Tema'),
      ),
    );
  }
}
