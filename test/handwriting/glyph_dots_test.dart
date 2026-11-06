import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:aksharamala/src/handwriting/glyph_dots.dart';
import 'package:aksharamala/src/handwriting/glyph_mask.dart';
import 'package:aksharamala/src/handwriting/glyph_mask_raster.dart';
import 'package:aksharamala/src/handwriting/stroke_template.dart';

GlyphMask build(int n, bool Function(int x, int y) ink) => GlyphMask(n, [
      for (var y = 0; y < n; y++)
        for (var x = 0; x < n; x++) ink(x, y),
    ]);

/// Distance (unit square) from [p] to the nearest inked cell centre.
double nearestInk(GlyphMask m, Pt p) {
  var best = double.infinity;
  for (final c in m.points) {
    best = math.min(best, c.distanceTo(p));
  }
  return best;
}

bool inkedCell(GlyphMask m, Pt p) {
  final x = (p.x * m.size).floor().clamp(0, m.size - 1);
  final y = (p.y * m.size).floor().clamp(0, m.size - 1);
  return m.at(x, y);
}

void main() {
  const n = 48;
  final cell = 1.0 / n;

  final bar = build(n, (x, y) => y >= 20 && y < 28 && x >= 6 && x < 42);
  final ring = build(n, (x, y) {
    final r = math.sqrt(math.pow(x + .5 - 24, 2) + math.pow(y + .5 - 24, 2));
    return r >= 12 && r <= 20;
  });
  final plus = build(
      n,
      (x, y) =>
          (x >= 20 && x < 28 && y >= 4 && y < 44) ||
          (y >= 20 && y < 28 && x >= 4 && x < 44));

  test('empty mask gives no dots', () {
    final m = GlyphMask(n, List.filled(n * n, false));
    expect(dotsFromMask(m), isEmpty);
  });

  test('thick horizontal bar: dots on the middle row, spaced >= spacing', () {
    final dots = dotsFromMask(bar);
    expect(dots, isNotEmpty);
    for (final d in dots) {
      expect(d.y, closeTo(24 * cell, 1.5 * cell), reason: 'y=${d.y}');
    }
    for (var i = 0; i < dots.length; i++) {
      for (var j = i + 1; j < dots.length; j++) {
        expect(dots[i].distanceTo(dots[j]), greaterThanOrEqualTo(0.05));
      }
    }
    // spans most of the bar
    final xs = dots.map((d) => d.x);
    expect(xs.reduce(math.min), lessThan(12 * cell));
    expect(xs.reduce(math.max), greaterThan(36 * cell));
  });

  test('custom spacing is honoured', () {
    final dots = dotsFromMask(bar, spacing: 0.1);
    for (var i = 0; i < dots.length; i++) {
      for (var j = i + 1; j < dots.length; j++) {
        expect(dots[i].distanceTo(dots[j]), greaterThanOrEqualTo(0.1));
      }
    }
    expect(dots.length, lessThan(dotsFromMask(bar).length));
  });

  test('thick ring: dots near the centre line and all the way round', () {
    final dots = dotsFromMask(ring);
    expect(dots, isNotEmpty);
    for (final d in dots) {
      final r = math.sqrt(math.pow(d.x - .5, 2) + math.pow(d.y - .5, 2)) * n;
      expect(r, closeTo(16, 1.5), reason: 'radius $r at $d');
    }
    // angular coverage: every 30 degree sector holds a dot
    final sectors = <int>{};
    for (final d in dots) {
      final a = math.atan2(d.y - .5, d.x - .5);
      sectors.add((((a + math.pi) / (2 * math.pi)) * 12).floor() % 12);
    }
    expect(sectors.length, 12, reason: 'sectors hit: $sectors');
  });

  test('thick plus: dots reach all four arms', () {
    final dots = dotsFromMask(plus);
    bool any(bool Function(Pt) f) => dots.any(f);
    expect(any((d) => d.y < 10 * cell && (d.x - .5).abs() < 3 * cell), isTrue,
        reason: 'top');
    expect(any((d) => d.y > 38 * cell && (d.x - .5).abs() < 3 * cell), isTrue,
        reason: 'bottom');
    expect(any((d) => d.x < 10 * cell && (d.y - .5).abs() < 3 * cell), isTrue,
        reason: 'left');
    expect(any((d) => d.x > 38 * cell && (d.y - .5).abs() < 3 * cell), isTrue,
        reason: 'right');
  });

  test('every dot lies in or within one cell of ink', () {
    for (final m in [bar, ring, plus]) {
      for (final d in dotsFromMask(m)) {
        expect(nearestInk(m, d), lessThanOrEqualTo(cell * 1.5),
            reason: 'dot $d off the glyph');
      }
    }
  });

  test('dot count is sensible for bold 48x48 glyphs; fast', () {
    for (final m in [bar, ring, plus]) {
      final sw = Stopwatch()..start();
      final dots = dotsFromMask(m);
      sw.stop();
      expect(dots.length, inInclusiveRange(1, 150));
      expect(sw.elapsedMilliseconds, lessThan(2000));
    }
  });

  test('a single inked cell and a diagonal line do not hang or crash', () {
    final one = build(n, (x, y) => x == 10 && y == 10);
    expect(dotsFromMask(one), hasLength(1));
    final diag = build(n, (x, y) => (x - y).abs() <= 1);
    final dots = dotsFromMask(diag);
    expect(dots, isNotEmpty);
    expect(dots.length, lessThan(150));
  });

  test('fully inked mask terminates', () {
    final full = build(n, (x, y) => true);
    final dots = dotsFromMask(full);
    expect(dots.length, lessThanOrEqualTo(150));
  });

  for (final glyph in ['అ', 'अ']) {
    testWidgets('real glyph $glyph rasterised: dots non-empty and on ink',
        (tester) async {
      final mask = (await tester.runAsync(() => rasteriseGlyph(glyph)))!;
      expect(mask.inkCount, greaterThan(0), reason: 'mask empty');
      final sw = Stopwatch()..start();
      final dots = dotsFromMask(mask);
      sw.stop();
      // ignore: avoid_print
      print('$glyph: ink=${mask.inkCount} dots=${dots.length} '
          'time=${sw.elapsedMilliseconds}ms');
      expect(dots, isNotEmpty);
      expect(dots.length, lessThanOrEqualTo(150));
      expect(sw.elapsedMilliseconds, lessThan(2000));
      for (final d in dots) {
        expect(nearestInk(mask, d), lessThanOrEqualTo(0.06), reason: '$d');
      }
    });
  }
}
