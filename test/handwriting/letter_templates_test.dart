import 'dart:math' as math;

import 'package:aksharamala/src/handwriting/handwriting_registry.dart';
import 'package:aksharamala/src/handwriting/letter_templates.dart';
import 'package:aksharamala/src/handwriting/stroke_template.dart';
import 'package:aksharamala/src/handwriting/stroke_validator.dart';
import 'package:flutter_test/flutter_test.dart';

const validator = StrokeValidator();

/// A child's attempt: the template with wobble, as if drawn by hand.
List<Stroke> attempt(StrokeTemplate t, {double jitter = 0.025, int seed = 1}) {
  final r = math.Random(seed);
  Pt p(Pt q) => Pt(q.x + (r.nextDouble() - .5) * 2 * jitter,
      q.y + (r.nextDouble() - .5) * 2 * jitter);
  return [
    for (final s in t.strokes)
      [
        for (var i = 0; i < s.length; i += (i % 3 == 0 ? 2 : 1)) p(s[i]),
        p(s.last),
      ],
  ];
}

void main() {
  test('there is one template for every capital letter A-Z', () {
    expect(letterTemplates.keys.toList()..sort(),
        [for (var c = 65; c <= 90; c++) String.fromCharCode(c)]);
    for (final e in letterTemplates.entries) {
      final t = e.value;
      expect(t.glyph, e.key);
      expect(t.script, 'english');
      expect(t.isUsable, isTrue, reason: e.key);
      expect(t.strokeOrderVerified, isFalse,
          reason: '${e.key}: no teacher has verified it');
      for (final s in t.strokes) {
        for (final p in s) {
          expect(p.x, inInclusiveRange(0.0, 1.0), reason: e.key);
          expect(p.y, inInclusiveRange(0.0, 1.0), reason: e.key);
        }
        expect(pathLength(s), greaterThan(0.25), reason: e.key);
      }
    }
  });

  test('the registry finds letters and numbers, and nothing else', () {
    expect(templateFor('A'), isNotNull);
    expect(templateFor('7'), isNotNull);
    expect(templateFor('అ'), isNull);
    expect(templateFor('a'), isNull);
    expect(glyphsWithTemplates.length, 11 + 26);
  });

  for (final mode in WritingMode.values) {
    test('every letter written with a shaky hand passes ($mode)', () {
      for (final e in letterTemplates.entries) {
        for (final seed in [1, 2, 3, 4, 5]) {
          final r = validator.check(e.value, attempt(e.value, seed: seed),
              mode: mode);
          expect(r.problem, isNull,
              reason: 'letter ${e.key} seed $seed $mode: ${r.problem}');
        }
      }
    });
  }

  test('a scribble fails every letter', () {
    for (final e in letterTemplates.entries) {
      for (final seed in [1, 2, 3, 4]) {
        final r = math.Random(seed);
        final scribble = [
          [for (var i = 0; i < 60; i++) Pt(r.nextDouble(), r.nextDouble())],
        ];
        for (final mode in WritingMode.values) {
          expect(validator.check(e.value, scribble, mode: mode).passed, isFalse,
              reason: '${e.key} seed $seed $mode');
        }
      }
    }
  });

  test('a letter does not pass as a different letter (guided)', () {
    final bad = <String>[];
    for (final a in letterTemplates.entries) {
      for (final b in letterTemplates.entries) {
        if (a.key == b.key) continue;
        if (validator.check(b.value, attempt(a.value)).passed) {
          bad.add('${a.key} accepted as ${b.key}');
        }
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('a letter does not pass as a different letter (independent)', () {
    final bad = <String>[];
    for (final a in letterTemplates.entries) {
      for (final b in letterTemplates.entries) {
        if (a.key == b.key) continue;
        if (validator
            .check(b.value, attempt(a.value), mode: WritingMode.independent)
            .passed) {
          bad.add('${a.key} accepted as ${b.key}');
        }
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('an O is not a C, and a C is not an O', () {
    final o = letterTemplates['O']!;
    final c = letterTemplates['C']!;
    expect(validator.check(c, attempt(o)).passed, isFalse);
    expect(validator.check(o, attempt(c)).passed, isFalse);
  });

  test('strokes drawn in the wrong order or direction are reported', () {
    final t = letterTemplates['T']!;
    final good = attempt(t);
    expect(validator.check(t, [good[1], good[0]]).problem,
        StrokeProblem.wrongOrder);
    expect(validator.check(t, [good[0].reversed.toList(), good[1]]).problem,
        StrokeProblem.wrongDirection);
    final e = letterTemplates['E']!;
    expect(validator.check(e, attempt(e).take(3).toList()).problem,
        StrokeProblem.tooFewStrokes);
  });
}
