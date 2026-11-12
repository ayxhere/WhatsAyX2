import 'package:flutter/material.dart';

/// AyX dark theme — same palette as AyXWhatsapp.
/// Clean, clear, WZH-style: lots of whitespace, rounded corners.
class AppTheme {
  static const Color bg = Color(0xFF1A1D24);
  static const Color surface = Color(0xFF22262F);
  static const Color surfaceVariant = Color(0xFF262B36);
  static const Color primary = Color(0xFF4DD0C4);
  static const Color secondary = Color(0xFF82AAFF);
  static const Color text = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF9AA3B2);
  static const Color border = Color(0xFF2E3440);
  static const Color success = Color(0xFF25D366);
  static const Color danger = Color(0xFFFF6B6B);

  static const double radiusCard = 20;
  static const double radiusField = 14;

  /// Build the app ThemeData from the user's settings.
  ///
  /// [accent] is the accent color value (e.g. 0xFF4DD0C4 for teal).
  /// [mode] is 'system' | 'light' | 'amoled'. 'system' follows the
  /// current dark palette, 'light' is a light theme, 'amoled' is pure
  /// black. Changing either rebuilds the whole app (MaterialApp is
  /// rebuilt from the SettingsStore listener in main.dart), so the
  /// theme and accent apply instantly across the whole app.
  static ThemeData dark({int? accent, String? mode}) {
    final accentColor =
        accent != null ? Color(accent) : primary;
    final isLight = mode == 'light';
    final isAmoled = mode == 'amoled';
    final bgColor = isLight
        ? const Color(0xFFF5F6F8)
        : isAmoled
            ? Colors.black
            : bg;
    final surfaceColor = isLight
        ? Colors.white
        : isAmoled
            ? const Color(0xFF0A0A0A)
            : surface;
    final textColor = isLight ? const Color(0xFF1A1D24) : text;
    final textSecColor =
        isLight ? const Color(0xFF5A6474) : textSecondary;
    final borderColor =
        isLight ? const Color(0xFFE0E3E8) : border;
    final scheme = isLight
        ? ColorScheme.light(
            primary: accentColor,
            secondary: secondary,
            surface: surfaceColor,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: textColor,
          )
        : ColorScheme.dark(
            primary: accentColor,
            secondary: secondary,
            surface: surfaceColor,
            onPrimary: Colors.black,
            onSecondary: Colors.black,
            onSurface: textColor,
          );
    return ThemeData(
      useMaterial3: true,
      brightness: isLight ? Brightness.light : Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bgColor,
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? const Color(0xFFED EFF2)
            : surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: textSecColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusField),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: accentColor,
        unselectedItemColor: textSecColor,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: textColor,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: textColor, fontSize: 15),
        bodySmall: TextStyle(color: textSecColor, fontSize: 13),
      ),
    );
  }
}
