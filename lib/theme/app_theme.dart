import 'package:flutter/material.dart';

class AppTheme {
  /// Color principal de fábrica (cuadro 1 de Tema). Con él la app usa
  /// los grises neutros originales.
  static const Color defaultPrimary = Color(0xFF7C3AED); // Morado

  /// Color principal activo. Lo cambia AppSettingsService al elegir
  /// un cuadro en Configuración → Tema.
  static Color _primary = defaultPrimary;

  /// Avisa a la app que el color cambió para que se vuelva a dibujar.
  static final ValueNotifier<int> cambios = ValueNotifier(0);

  /// Cambia el color principal y redibuja la app.
  static void aplicar(Color color) {
    _primary = color;
    cambios.value++;
  }

  static bool get _esDefault => _primary.toARGB32() == defaultPrimary.toARGB32();

  /// Un tono del color principal con la saturación reducida al
  /// [factor] indicado y la luminosidad fija en [luz] (0 a 1).
  static Color _tono(double factor, double luz) {
    final hsl = HSLColor.fromColor(_primary);
    return HSLColor.fromAHSL(
      1,
      hsl.hue,
      (hsl.saturation * factor).clamp(0.0, 1.0),
      luz,
    ).toColor();
  }

  // Colores que salen del color principal
  static Color get primary => _primary;

  /// Texto e iconos encima del color principal: blanco o negro, el que
  /// se lea mejor según qué tan claro es el color.
  static Color get onPrimary =>
      ThemeData.estimateBrightnessForColor(_primary) == Brightness.dark
      ? textWhite
      : textBlack;

  /// Fondo de las pantallas (negro con un toque del color principal).
  static Color get bgDark =>
      _esDefault ? const Color(0xFF1A1A1A) : _tono(0.25, 0.10);

  /// Fondo de tarjetas, barras y campos (gris oscuro con un toque).
  static Color get bgDarkGrey =>
      _esDefault ? const Color(0xFF2A2A2A) : _tono(0.25, 0.165);

  /// Texto secundario (gris claro con un toque).
  static Color get textGrey =>
      _esDefault ? const Color(0xFFB0B0B0) : _tono(0.30, 0.72);

  // Colores fijos
  static const Color textWhite = Color(0xFFFFFFFF); // Blanco
  static const Color textBlack = Color(0xFF000000); // Negro (sobre verde)
  static const Color textHint = Color(
    0x62FFFFFF,
  ); // Blanco tenue (hints, iconos secundarios)
  static const Color danger = Color(0xFFF44336); // Rojo (errores, eliminar)
  static const Color success = Color(0xFF4CAF50); // Verde (éxito, seleccionado)
  static const Color successLight = Color(0xFF81C784); // Verde claro
  static const Color disabled = Color(0xFF9E9E9E); // Gris (deshabilitado)

  // ThemeData oscuro centralizado
  static ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: bgDark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        surface: bgDark,
        surfaceContainer: bgDarkGrey,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDarkGrey,
        foregroundColor: textWhite,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgDarkGrey,
        labelStyle: TextStyle(color: textGrey),
        hintStyle: TextStyle(color: textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textWhite),
        bodyMedium: TextStyle(color: textWhite),
        labelLarge: TextStyle(color: textWhite),
        headlineSmall: TextStyle(color: textWhite),
        headlineMedium: TextStyle(color: textWhite),
        headlineLarge: TextStyle(color: textWhite),
      ),
      listTileTheme: ListTileThemeData(
        textColor: textWhite,
        titleTextStyle: TextStyle(color: textWhite),
        subtitleTextStyle: TextStyle(color: textGrey),
      ),
      // Sin esto el texto sale en un gris que no contrasta
      // con el fondo oscuro del SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgDarkGrey,
        contentTextStyle: TextStyle(color: textWhite, fontSize: 14),
        actionTextColor: primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
