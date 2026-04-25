// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App — Application Theme
// ------------------------------------------------------------------------------------------------
//
// [AppTheme] defines the visual identity of the EcoSort AI app. It provides a
// nature-inspired colour palette (greens, sand, sky) and a Material 3 light
// theme used throughout the application.
//
// Colours:
//   seed  – primary brand green   (0xFF1B7F5A)
//   leaf  – accent / secondary    (0xFF2EAD72)
//   moss  – dark text / headings  (0xFF0F3D2E)
//   sand  – warm background       (0xFFF6F1E7)
//   sky   – soft highlight        (0xFFE6F4F1)
// ------------------------------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// Centralised theme configuration for the EcoSort AI application.
class AppTheme {
  // ------------------------------------------------------------------------------------------
  // Brand colour palette
  // ------------------------------------------------------------------------------------------

  /// Primary brand colour — a rich forest green.
  static const seed = Color(0xFF1B7F5A);

  /// Secondary accent — a lively leaf green used for highlights and indicators.
  static const leaf = Color(0xFF2EAD72);

  /// Deep moss — used for heading text and strong contrast.
  static const moss = Color(0xFF0F3D2E);

  /// Warm sand — the main background colour of the app.
  static const sand = Color(0xFFF6F1E7);

  /// Soft sky — used for selected states, avatar backgrounds, and subtle accents.
  static const sky = Color(0xFFE6F4F1);

  // ------------------------------------------------------------------------------------------
  // Material 3 light theme
  // ------------------------------------------------------------------------------------------

  /// Returns a Material 3 [ThemeData] derived from the EcoSort colour palette.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: seed,
      secondary: leaf,
      surface: sand,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: sand,
      appBarTheme: const AppBarThemeData(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: moss,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: sky,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: moss,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: moss,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: moss,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: moss,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.45,
          color: Color(0xFF345148),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: Color(0xFF536B62),
        ),
      ),
    );
  }
}
