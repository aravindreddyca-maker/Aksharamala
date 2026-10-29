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

/// The Noto family that carries [text]'s script, or null for Latin-only or
/// mixed text (which keeps the default font so English letters stay uniform).
String? scriptFamilyFor(String text) {
  if (RegExp('[A-Za-z]').hasMatch(text)) return null;
  for (final rune in text.runes) {
    if (rune >= 0x0B80 && rune <= 0x0BFF) return 'Noto Sans Tamil';
    if (rune >= 0x0C00 && rune <= 0x0C7F) return 'Noto Sans Telugu';
    if (rune >= 0x0900 && rune <= 0x097F) return 'Noto Sans Devanagari';
  }
  return null;
}

/// [base] with the right font for Indic text, so every Tamil, Telugu or Hindi
/// string uses one font throughout (consistent vowel signs and conjuncts).
/// These scripts have tall marks above and below the line, so the line height
/// is raised to stop them being clipped.
TextStyle scriptStyle(String text, TextStyle base) {
  final family = scriptFamilyFor(text);
  if (family == null) return base;
  return base.copyWith(
    fontFamily: family,
    fontFamilyFallback: GameTokens.multilingualFallback,
    height: (base.height ?? 1) < 1.3 ? 1.3 : base.height,
    leadingDistribution: TextLeadingDistribution.even,
  );
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
