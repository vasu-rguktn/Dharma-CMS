import 'package:flutter/material.dart';

class AppTheme {
  // Primary Orange Brand Color
  static const Color primaryOrange = Color(0xFFFC633C);

  // Light Theme Colors
  static const Color _primaryLight = primaryOrange;           // #FC633C
  static const Color _accentLight = Color(0xFFFF8A65);        // Softer orange
  static const Color _backgroundLight = Color(0xFFFFF8F5);     // Warm white
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _mutedLight = Color(0xFFFFE0D6);         // Light orange tint
  static const Color _borderLight = Color(0xFFFFB4A2);        // Orange border
  static const Color _destructive = Color(0xFFE53935);

  // Dark Theme Colors
  static const Color _primaryDark = primaryOrange;            // #FC633C
  static const Color _accentDark = Color(0xFFFF7043);         // Bright orange
  static const Color _backgroundDark = Color(0xFF1A0F0A);     // Deep warm black
  static const Color _cardDark = Color(0xFF2D1B14);           // Dark card
  static const Color _mutedDark = Color(0xFF4A2C1F);          // Muted dark
  static const Color _borderDark = Color(0xFF8B4513);         // Brown-orange border

  // Sidebar colors
  static const Color _sidebarBgLight = Color(0xFFFFF2E8);      // Very light orange
  static const Color _sidebarFgLight = Color(0xFF3E2723);     // Dark text
  static const Color _sidebarBgDark = Color(0xFF2D1B14);
  static const Color _sidebarFgDark = Color(0xFFFFCCBC);      // Light orange text

  // Text Styles based on PT Sans
  static const String _fontFamily = 'PTSans';

  static final TextTheme _textTheme = TextTheme(
    displayLarge: const TextStyle(fontFamily: _fontFamily, fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
    displayMedium: const TextStyle(fontFamily: _fontFamily, fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall: const TextStyle(fontFamily: _fontFamily, fontSize: 36, fontWeight: FontWeight.w400),
    headlineLarge: const TextStyle(fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: const TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w700),
    headlineSmall: const TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: const TextStyle(fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: const TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15),
    titleSmall: const TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    bodyLarge: const TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
    bodyMedium: const TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
    bodySmall: const TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
    labelLarge: const TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    labelMedium: const TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    labelSmall: const TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      textTheme: _textTheme,
      brightness: Brightness.light,
      primaryColor: _primaryLight,
      scaffoldBackgroundColor: _backgroundLight,
      cardColor: _cardLight,
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
        centerTitle: false,
        titleTextStyle: _textTheme.titleLarge?.copyWith(color: Colors.black87),
      ),
      cardTheme: CardThemeData(
        color: _cardLight,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: _borderLight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _mutedLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _destructive),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: const DividerThemeData(color: _borderLight, thickness: 1),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      textTheme: _textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      brightness: Brightness.dark,
      primaryColor: _primaryDark,
      scaffoldBackgroundColor: _backgroundDark,
      cardColor: _cardDark,
      colorScheme: ColorScheme.dark(
        primary: _primaryDark,
        secondary: _accentDark,
        surface: _cardDark,
        error: _destructive,
        onPrimary: Colors.black87,
        onSecondary: Colors.black87,
        onSurface: Colors.white,
        onError: Colors.white,
        outline: _borderDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _cardDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _textTheme.titleLarge?.copyWith(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 2,
        shadowColor: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: _borderDark),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _mutedDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _destructive),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: const DividerThemeData(color: _borderDark, thickness: 1),
    );
  }

  // Custom sidebar colors
  static Color sidebarBackground(bool isDark) => isDark ? _sidebarBgDark : _sidebarBgLight;
  static Color sidebarForeground(bool isDark) => isDark ? _sidebarFgDark : _sidebarFgLight;
}