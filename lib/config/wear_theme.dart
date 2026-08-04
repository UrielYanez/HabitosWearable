import 'package:flutter/material.dart';

class WearTheme {
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF16161A);
  static const Color surfaceElevated = Color(0xFF222228);
  static const Color card = Color(0xFF1C1C22);
  static const Color border = Color(0xFF2E2E38);

  static const Color primary = Color(0xFF6366F1);     // Neon Indigo
  static const Color secondary = Color(0xFF8B5CF6);   // Purple
  static const Color success = Color(0xFF10B981);     // Emerald Green
  static const Color water = Color(0xFF06B6D4);       // Cyan Water
  static const Color timer = Color(0xFFF59E0B);       // Amber Timer
  static const Color steps = Color(0xFF34D399);       // Light Emerald
  static const Color error = Color(0xFFEF4444);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 12,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 10,
          color: textMuted,
        ),
      ),
    );
  }
}
