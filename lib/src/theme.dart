import 'package:flutter/material.dart';

abstract final class GameTokens {
  static const spaceXs = 6.0;
  static const spaceSm = 10.0;
  static const spaceMd = 16.0;
  static const spaceLg = 24.0;
  static const radiusMd = 18.0;
  static const radiusLg = 26.0;
  static const minTouch = 52.0;
  static const ink = Color(0xFF17233A);
  static const canvas = Color(0xFFFFFBF4);
  static const navy = Color(0xFF13213A);
  static const gold = Color(0xFFFFD85C);
  static const multilingualFallback = <String>[
    'Noto Sans Telugu',
    'Noto Sans Devanagari',
    'Noto Sans Tamil',
    'Noto Sans',
  ];
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6657D9),
    brightness: Brightness.light,
    surface: GameTokens.canvas,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: GameTokens.canvas,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontWeight: FontWeight.w900,
        height: 1.05,
        fontFamilyFallback: GameTokens.multilingualFallback,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w900,
        fontFamilyFallback: GameTokens.multilingualFallback,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w800,
        fontFamilyFallback: GameTokens.multilingualFallback,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w800,
        fontFamilyFallback: GameTokens.multilingualFallback,
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.w500,
        height: 1.35,
        fontFamilyFallback: GameTokens.multilingualFallback,
      ),
      bodyMedium: TextStyle(
        fontFamilyFallback: GameTokens.multilingualFallback,
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w800,
        fontFamilyFallback: GameTokens.multilingualFallback,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(GameTokens.minTouch, GameTokens.minTouch),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(GameTokens.minTouch, GameTokens.minTouch),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GameTokens.radiusMd),
      ),
    ),
  );
}
