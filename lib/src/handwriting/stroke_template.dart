/// Handwriting building blocks shared by every script (Telugu, Tamil, Hindi,
/// English and numbers). Pure Dart, so the checks run the same in tests and on
/// a phone.
///
/// Coordinates are a unit square, x to the right and y *down*, the way a
/// writing pad is laid out. A child's strokes are turned into that square by
/// dividing by the pad's width and height.
library;

import 'dart:math' as math;

class Pt {
  const Pt(this.x, this.y);

  final double x;
  final double y;

  double distanceTo(Pt o) {
    final dx = x - o.x;
    final dy = y - o.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  bool operator ==(Object other) => other is Pt && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Pt($x, $y)';
}

/// One stroke is one pen-down to pen-up path.
typedef Stroke = List<Pt>;

/// The correct way to write one glyph: ordered strokes, each with a direction.
class StrokeTemplate {
  const StrokeTemplate({
    required this.glyph,
    required this.script,
    required this.strokes,
    this.strokeOrderVerified = false,
    this.source = 'unspecified',
  });

  /// What is written, e.g. `7` or `అ`.
  final String glyph;

  /// `numbers`, `telugu`, `tamil`, `hindi` or `english`.
  final String script;

  /// Strokes in the order they are written, each in writing direction.
  final List<Stroke> strokes;

  /// True only once a teacher has confirmed the stroke order and direction.
  /// Until then the engine gives feedback but never awards mastery.
  final bool strokeOrderVerified;

  /// Where the geometry came from, for the asset manifest.
  final String source;

  bool get isUsable =>
      strokes.isNotEmpty && strokes.every((s) => s.length >= 2);
}

enum WritingMode {
  /// The guide is on screen; the child writes on top of it.
  guided,

  /// No guide; the shape is judged wherever and however big the child draws.
  independent,
}

/// Total length of a stroke.
double pathLength(Stroke s) {
  var len = 0.0;
  for (var i = 1; i < s.length; i++) {
    len += s[i - 1].distanceTo(s[i]);
  }
  return len;
}

/// [n] points spaced evenly along the stroke's length.
Stroke resample(Stroke s, int n) {
  if (s.isEmpty) return const [];
  if (s.length == 1 || pathLength(s) == 0) return List.filled(n, s.first);
  final total = pathLength(s);
  final step = total / (n - 1);
  final out = <Pt>[s.first];
  var needed = step;
  var carried = 0.0;
  for (var i = 1; i < s.length && out.length < n; i++) {
    final a = s[i - 1];
    final b = s[i];
    final seg = a.distanceTo(b);
    if (seg == 0) continue;
    var pos = 0.0;
    while (carried + (seg - pos) >= needed && out.length < n) {
      pos += needed - carried;
      final t = pos / seg;
      out.add(Pt(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t));
      carried = 0;
      needed = step;
    }
    carried += seg - pos;
  }
  while (out.length < n) {
    out.add(s.last);
  }
  return out;
}
