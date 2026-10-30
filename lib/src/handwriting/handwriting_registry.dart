/// Which glyphs have a stroke template: the numbers 0-10 and the English
/// capital letters A-Z. Every other glyph (the Telugu, Hindi and Tamil letters)
/// is checked against its font outline until a teacher-verified template is
/// added here.
library;

import 'digit_templates.dart';
import 'letter_templates.dart';
import 'stroke_template.dart';

StrokeTemplate? templateFor(String glyph) {
  final n = int.tryParse(glyph);
  if (n != null) return digitTemplates[n];
  return letterTemplates[glyph];
}

/// Glyphs the engine can currently check by shape from a template.
Iterable<String> get glyphsWithTemplates =>
    [...digitTemplates.keys.map((n) => '$n'), ...letterTemplates.keys];
