import 'package:flutter/material.dart';

class AppTheme {
  // Primary Orange Brand Color
  static const Color primaryOrange = Color(0xFFFC633C);

  // Light Theme Colors
  static const Color _primaryLight = primaryOrange;
  static const Color _accentLight = Color(0xFFFF8A65);
  static const Color _backgroundLight = Color(0xFFFFF8F5);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _borderLight = Color(0xFFFFB4A2);
  static const Color _destructive = Color(0xFFE53935);

  // Dark Theme Colors
  static const Color _primaryDark = primaryOrange;
  static const Color _accentDark = Color(0xFFFF7043);
  static const Color _backgroundDark = Color(0xFF1A0F0A);
  static const Color _cardDark = Color(0xFF2D1B14);
  static const Color _borderDark = Color(0xFF8B4513);

  // Sidebar colors
  static const Color _sidebarBgLight = Color(0xFFFFF2E8);
  static const Color _sidebarFgLight = Color(0xFF3E2723);
  static const Color _sidebarBgDark = Color(0xFF2D1B14);
  static const Color _sidebarFgDark = Color(0xFFFFCCBC);

  static const String _fontFamily = 'PTSans';

  static final TextTheme _textTheme = TextTheme(
    displayLarge: const TextStyle(fontFamily: _fontFamily, fontSize: 57),
    displayMedium: const TextStyle(fontFamily: _fontFamily, fontSize: 45),
    displaySmall: const TextStyle(fontFamily: _fontFamily, fontSize: 36),
    headlineLarge: const TextStyle(fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: const TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.bold),
    headlineSmall: const TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.bold),
    titleLarge: const TextStyle(fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: const TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
    bodyLarge: const TextStyle(fontFamily: _fontFamily, fontSize: 16),
    bodyMedium: const TextStyle(fontFamily: _fontFamily, fontSize: 14),
    labelLarge: const TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w600),
  );

  // ================= LIGHT THEME =================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      textTheme: _textTheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _backgroundLight,

      colorScheme: ColorScheme.light(
        primary: _primaryLight,
        secondary: _accentLight,
        surface: _cardLight,
        error: _destructive,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onError: Colors.white,
        outline: _borderLight,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: _cardLight,
        foregroundColor: Colors.black87,
        elevation: 0,
        titleTextStyle: _textTheme.titleLarge?.copyWith(color: Colors.black87),
      ),

      cardTheme: CardThemeData(
        color: _cardLight,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryLight,
          side: BorderSide(color: _borderLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // ✅ INPUT FIELDS → PURE WHITE
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _destructive),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      dividerTheme: DividerThemeData(color: _borderLight, thickness: 1),
    );
  }

  // ================= DARK THEME =================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      textTheme: _textTheme.apply(bodyColor: Colors.white),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _backgroundDark,

      colorScheme: ColorScheme.dark(
        primary: _primaryDark,
        secondary: _accentDark,
        surface: _cardDark,
        error: _destructive,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.white,
        outline: _borderDark,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: _cardDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: Colors.black,
        ),
      ),

      // Dark inputs stay dark (good UX)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryDark, width: 2),
        ),
      ),
    );
  }

  static Color sidebarBackground(bool isDark) =>
      isDark ? _sidebarBgDark : _sidebarBgLight;

  static Color sidebarForeground(bool isDark) =>
      isDark ? _sidebarFgDark : _sidebarFgLight;
}
