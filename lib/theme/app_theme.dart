import 'package:flutter/material.dart';

class AppTheme {
  // ===== Colors =====

  static const Color background = Color(0xFF0F0A18);

  static const Color purple = Color(0xFF8E2BFF);

  static const Color purpleLight = Color(0xFFB55CFF);

  static const Color glass = Color(0x22FFFFFF);

  static const Color border = Color(0x55FFFFFF);

  static const Color text = Colors.white;

  static const Color success = Color(0xFF3DDC84);

  static const Color error = Color(0xFFFF5C5C);

  // ===== Light Theme =====

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: purple,
      ),
    );
  }

  // ===== Dark Theme =====

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.dark,

      scaffoldBackgroundColor: background,

      colorScheme: ColorScheme.dark(
        primary: purple,
        secondary: purpleLight,
        surface: background,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),

      cardTheme: CardThemeData(
        color: glass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: text,
          fontSize: 34,
          fontWeight: FontWeight.bold,
        ),

        headlineMedium: TextStyle(
          color: text,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),

        titleLarge: TextStyle(
          color: text,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),

        bodyLarge: TextStyle(
          color: text,
          fontSize: 18,
        ),

        bodyMedium: TextStyle(
          color: text,
          fontSize: 16,
        ),

        labelLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,

          backgroundColor: purple,

          foregroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }

  // ===== Reusable Decorations =====

  static BoxDecoration glassDecoration = BoxDecoration(
    color: glass,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: border,
      width: 1,
    ),
  );

  static List<BoxShadow> neonGlow = [
    BoxShadow(
      color: purple.withOpacity(.70),
      blurRadius: 40,
      spreadRadius: 4,
    ),
    BoxShadow(
      color: purple.withOpacity(.35),
      blurRadius: 80,
      spreadRadius: 10,
    ),
  ];
}