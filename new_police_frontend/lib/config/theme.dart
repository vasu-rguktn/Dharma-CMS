import 'package:flutter/material.dart';

/// Centralised app theming.
class AppTheme {
  AppTheme._();

  static const Color _primary = Color(0xFFFC633C);
  static const Color _dark = Color(0xFF1E1E2C);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _primary,
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F8FE),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _primary,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _dark,
  );

  static Color sidebarBackground(bool isDark) => isDark ? _dark : const Color(0xFF1A237E);
  static Color sidebarForeground(bool isDark) => Colors.white;
}
