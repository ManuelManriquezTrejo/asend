import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:asend/theme/app_theme.dart';

/// Ajustes generales de la app: los colores de Tema y el interruptor
/// de Stats. Guarda tipos simples, así que la caja no necesita adapter.
class AppSettingsService {
  static const String settingsBox = 'app_settings';

  static const String _claveColores = 'temaColores';
  static const String _claveActivo = 'temaActivo';
  static const String _claveStats = 'statsActivo';

  /// Cuadros que el usuario puede llenar (del 2 al 5).
  static const int maxColores = 4;

  static Future<void> initializeAppSettings() async {
    try {
      // 🧨 BORRAR DATOS - descomentar, correr UNA vez y volver a comentar
      // await Hive.deleteBoxFromDisk(settingsBox);

      await Hive.openBox(settingsBox);
      AppTheme.aplicar(colorActivo());
    } catch (e) {
      debugPrint('❌ Error al inicializar App Settings: $e');
    }
  }

  static Box get _box => Hive.box(settingsBox);

  // ── Tema ───────────────────────────────────────────────

  /// Colores guardados en los cuadros 2 a 5, en orden.
  static List<Color> coloresGuardados() {
    final valores = List<int>.from(
      _box.get(_claveColores, defaultValue: <int>[]) as List,
    );
    return valores.map((v) => Color(v)).toList();
  }

  /// Cuadro en uso: 0 es el morado de fábrica, 1 a 4 son los guardados.
  static int indiceActivo() {
    final indice = _box.get(_claveActivo, defaultValue: 0) as int;
    return indice <= coloresGuardados().length ? indice : 0;
  }

  /// Color del cuadro en uso.
  static Color colorActivo() {
    final indice = indiceActivo();
    if (indice == 0) return AppTheme.defaultPrimary;
    return coloresGuardados()[indice - 1];
  }

  /// Usa el color de un cuadro y redibuja la app.
  static Future<void> usar(int indice) async {
    await _box.put(_claveActivo, indice);
    AppTheme.aplicar(colorActivo());
  }

  /// Guarda un color y lo deja en uso. Con [indice] null lo pone en el
  /// primer cuadro libre; con un número reemplaza ese cuadro.
  static Future<void> guardarColor(Color color, {int? indice}) async {
    final colores = coloresGuardados();

    if (indice == null) {
      if (colores.length >= maxColores) return;
      colores.add(color);
      indice = colores.length;
    } else {
      colores[indice - 1] = color;
    }

    await _guardarLista(colores);
    await usar(indice);
  }

  /// Elimina un cuadro y recorre los de la derecha. Si era el que se
  /// estaba usando, vuelve al morado. Devuelve true si cambió el color
  /// en uso.
  static Future<bool> eliminar(int indice) async {
    final colores = coloresGuardados();
    final activo = indiceActivo();

    colores.removeAt(indice - 1);
    await _guardarLista(colores);

    if (activo == indice) {
      await usar(0);
      return true;
    }

    // El que estaba en uso se recorrió un lugar a la izquierda
    if (activo > indice) {
      await _box.put(_claveActivo, activo - 1);
    }
    return false;
  }

  static Future<void> _guardarLista(List<Color> colores) async {
    await _box.put(
      _claveColores,
      colores.map((c) => c.toARGB32()).toList(),
    );
  }

  // ── Stats ──────────────────────────────────────────────

  /// Si el módulo Stats está encendido. Apagado por defecto.
  static bool statsActivo() =>
      _box.get(_claveStats, defaultValue: false) as bool;

  static Future<void> setStatsActivo(bool valor) async {
    await _box.put(_claveStats, valor);
  }
}
