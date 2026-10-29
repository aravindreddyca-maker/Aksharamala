/// Which glyphs have a stroke template. Today that is the numbers 0-10 only;
/// every other glyph (the Telugu letters) is checked against its font outline
/// until a teacher-verified template is added here.
library;

import 'digit_templates.dart';
import 'stroke_template.dart';

StrokeTemplate? templateFor(String glyph) {
  final n = int.tryParse(glyph);
  return n == null ? null : digitTemplates[n];
}

/// Glyphs the engine can currently check by shape from a template.
Iterable<String> get glyphsWithTemplates =>
    digitTemplates.keys.map((n) => '$n');
