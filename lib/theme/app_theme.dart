import 'package:flutter/material.dart';

class AppTheme {
  // Colores
  static const Color bgDark = Color(0xFF1A1A1A); // Negro
  static const Color bgDarkGrey = Color(0xFF2A2A2A); // Gris oscuro
  static const Color buttonPurple = Color(0xFF7C3AED); // Morado
  static const Color textWhite = Color(0xFFFFFFFF); // Blanco
  static const Color textGrey = Color(0xFFB0B0B0); // Gris claro
  static const Color textHint = Color(
    0x62FFFFFF,
  ); // Blanco tenue (hints, iconos secundarios)
  static const Color danger = Color(0xFFF44336); // Rojo (errores, eliminar)
  static const Color success = Color(0xFF4CAF50); // Verde (éxito, seleccionado)
  static const Color disabled = Color(0xFF9E9E9E); // Gris (deshabilitado)

  // ThemeData oscuro centralizado
  static ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: bgDark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: buttonPurple,
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
          backgroundColor: buttonPurple,
          foregroundColor: textWhite,
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
          borderSide: BorderSide(color: buttonPurple),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: buttonPurple),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: buttonPurple, width: 2),
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
        actionTextColor: buttonPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
