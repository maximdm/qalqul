import 'package:flutter/material.dart';

class AppTheme {
  static const _lightBg = Color(0xFFF6F7F9);
  static const _darkBg = Color(0xFF0F1115);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _darkSurface = Color(0xFF191C22);

  /// Brand seed. Mirrored by `assets/brand` (see `tool/generate_brand_art.dart`)
  /// and by the launcher icon / splash config in `pubspec.yaml`.
  static const primary = Color(0xFF4F6DF5);
  static const primaryDeep = Color(0xFF3A50D0);
  static const _primary = primary;
  static const _primarySoft = Color(0xFFEAEefb);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: _lightBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
          surface: _lightSurface,
        ),
        cardTheme: CardThemeData(
          color: _lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.all(6),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _lightBg,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _lightSurface,
          selectedItemColor: _primary,
          unselectedItemColor: Colors.black45,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _primarySoft,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.dark,
          surface: _darkSurface,
        ),
        cardTheme: CardThemeData(
          color: _darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.all(6),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkBg,
          foregroundColor: Colors.white70,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _darkSurface,
          selectedItemColor: _primary,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF232730),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
