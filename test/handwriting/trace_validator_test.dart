import 'dart:math' as math;

import 'package:aksharamala/src/handwriting/digit_templates.dart';
import 'package:aksharamala/src/handwriting/glyph_mask.dart';
import 'package:aksharamala/src/handwriting/handwriting_policy.dart';
import 'package:aksharamala/src/handwriting/letter_templates.dart';
import 'package:aksharamala/src/handwriting/stroke_template.dart';
import 'package:aksharamala/src/handwriting/stroke_validator.dart';
import 'package:aksharamala/src/handwriting/trace_validator.dart';
import 'package:flutter_test/flutter_test.dart';

const validator = TraceValidator();

final allTemplates = <StrokeTemplate>[
  ...digitTemplates.values,
  ...letterTemplates.values,
];

/// Dense points along a polyline, the way a finger reports them.
Stroke dense(Stroke s, {double step = 0.01}) {
  final out = <Pt>[s.first];
  for (var i = 1; i < s.length; i++) {
    final a = s[i - 1];
    final b = s[i];
    final n = math.max(1, (a.distanceTo(b) / step).ceil());
    for (var k = 1; k <= n; k++) {
      out.add(Pt(a.x + (b.x - a.x) * k / n, a.y + (b.y - a.y) * k / n));
    }
  }
  return out;
}

/// A smooth drift off the line, like a child's hand (not a jittery one).
Stroke wobble(Stroke s, math.Random r, double amount) {
  final phase = r.nextDouble() * 6;
  return [
    for (var i = 0; i < s.length; i++)
      Pt(s[i].x + amount * math.sin(i * .09 + phase),
          s[i].y + amount * math.cos(i * .07 + phase)),
  ];
}

/// The whole template in ONE continuous movement: each stroke follows the
/// last with a straight line joining them, the finger never leaving the pad.
List<Stroke> oneMovement(StrokeTemplate t) => [
      [for (final s in t.strokes) ...dense(s)],
    ];

void main() {
  group('the child follows the letter', () {
    test('every number and capital is accepted written stroke by stroke', () {
      for (final t in allTemplates) {
        final r = validator.check(t, [for (final s in t.strokes) dense(s)]);
        expect(r.passed, isTrue, reason: '${t.glyph}: ${r.problem}');
      }
    });

    test('every one is accepted in ONE continuous movement', () {
      for (final t in allTemplates) {
        final r = validator.check(t, oneMovement(t));
        expect(r.passed, isTrue, reason: '${t.glyph}: ${r.problem}');
      }
    });

    test('order, direction and starting point do not matter', () {
      for (final t in allTemplates) {
        final reversed = [
          for (final s in t.strokes.reversed) dense(s).reversed.toList(),
        ];
        final r = validator.check(t, reversed);
        expect(r.passed, isTrue, reason: '${t.glyph}: ${r.problem}');
      }
    });

    test('a shaky hand is forgiven', () {
      final r = math.Random(7);
      for (final t in allTemplates) {
        final shaky = [
          for (final s in t.strokes) wobble(dense(s), r, 0.025),
        ];
        final res = validator.check(t, shaky);
        expect(res.passed, isTrue, reason: '${t.glyph}: ${res.problem}');
      }
    });

    test('a letter drawn a little off the guide is accepted', () {
      for (final t in allTemplates) {
        final off = [
          for (final s in t.strokes)
            [for (final p in dense(s)) Pt(p.x + 0.04, p.y - 0.03)],
        ];
        final res = validator.check(t, off);
        expect(res.passed, isTrue, reason: '${t.glyph}: ${res.problem}');
      }
    });
  });

  group('wrong or unfinished tracing is rejected', () {
    test('nothing, and a dot', () {
      final t = letterTemplates['A']!;
      expect(validator.check(t, const []).problem, StrokeProblem.nothing);
      final dot = validator.check(t, [
        [const Pt(.5, .5), const Pt(.5, .501)],
      ]);
      expect(dot.passed, isFalse);
    });

    test('a missing part of the letter is not accepted', () {
      for (final t in allTemplates) {
        if (t.strokes.length < 2) continue;
        final total = t.strokes.fold<double>(0, (n, s) => n + pathLength(s));
        for (var skip = 0; skip < t.strokes.length; skip++) {
          // A tiny dot is not a "major component"; everything bigger is.
          if (pathLength(t.strokes[skip]) < total * .15) continue;
          final partial = [
            for (var i = 0; i < t.strokes.length; i++)
              if (i != skip) dense(t.strokes[i]),
          ];
          expect(validator.check(t, partial).passed, isFalse,
              reason: '${t.glyph} without stroke ${skip + 1}');
        }
      }
    });

    test('half of a stroke is not enough', () {
      for (final t in allTemplates) {
        final total = t.strokes.fold<double>(0, (n, x) => n + pathLength(x));
        for (var i = 0; i < t.strokes.length; i++) {
          final s = dense(t.strokes[i]);
          if (pathLength(s) < total * .3) continue;
          final missing = s.sublist(s.length ~/ 2);
          // Only where the missing half is not hidden by the rest of the
          // letter (the 4 crosses itself, so its halves overlap).
          final others = [
            for (var j = 0; j < t.strokes.length; j++)
              if (j != i) ...dense(t.strokes[j]),
            ...s.sublist(0, s.length ~/ 2),
          ];
          final hidden = missing
              .where((p) => others.any((q) => q.distanceTo(p) < .12))
              .length;
          if (hidden > missing.length * .3) continue;
          final drawn = [
            for (var j = 0; j < t.strokes.length; j++)
              j == i ? s.sublist(0, s.length ~/ 2) : dense(t.strokes[j]),
          ];
          expect(validator.check(t, drawn).passed, isFalse,
              reason: '${t.glyph}: half of stroke ${i + 1}');
        }
      }
    });

    test('a scribble across the page is rejected for every letter', () {
      final zigzag = <Pt>[];
      for (var i = 0; i < 40; i++) {
        zigzag.add(Pt(i.isEven ? .05 : .95, .05 + i * .0231));
      }
      for (final t in allTemplates) {
        expect(validator.check(t, [dense(zigzag)]).passed, isFalse,
            reason: t.glyph);
      }
    });

    test('scribbling over the right letter is rejected', () {
      final t = letterTemplates['L']!;
      final over = [
        for (var k = 0; k < 8; k++) ...[for (final s in t.strokes) dense(s)],
      ];
      expect(validator.check(t, over).passed, isFalse);
    });

    test('a different letter is rejected', () {
      // Trace a T over an L, and an O over an A.
      final pairs = {'L': 'T', 'A': 'O', 'E': 'O', 'V': 'T', 'Z': 'O'};
      for (final e in pairs.entries) {
        final want = letterTemplates[e.key]!;
        final drawn = [
          for (final s in letterTemplates[e.value]!.strokes) dense(s),
        ];
        expect(validator.check(want, drawn).passed, isFalse,
            reason: '${e.value} drawn for ${e.key}');
      }
    });

    test('a straight line is no letter (except a letter that is a line)', () {
      final line = dense([const Pt(.1, .1), const Pt(.9, .9)]);
      for (final t in allTemplates) {
        final lineLike = t.strokes.length == 1 &&
            (t.glyph == 'I' || t.glyph == '1' || t.glyph == 'l');
        if (lineLike) continue;
        expect(validator.check(t, [line]).passed, isFalse, reason: t.glyph);
      }
    });
  });

  group('through the policy', () {
    test('trace mode ignores stroke order and never awards mastery', () {
      final t = letterTemplates['H']!;
      final backwards = [
        for (final s in t.strokes.reversed) dense(s).reversed.toList(),
      ];
      final r = const HandwritingPolicy()
          .judge(drawn: backwards, template: t, mode: WritingMode.trace);
      expect(r.shapeOk, isTrue);
      expect(r.awardsMastery, isFalse);
      // The strict, ordered check is unchanged for guided writing.
      final strict = const HandwritingPolicy()
          .judge(drawn: backwards, template: t, mode: WritingMode.guided);
      expect(strict.shapeOk, isFalse);
    });
  });

  group('letters without a template (Telugu, Hindi, Tamil, small letters)', () {
    // A ring, as a stand-in for any glyph drawn from its font.
    final mask = GlyphMask.fromRows([
      '..........',
      '...####...',
      '..#....#..',
      '.#......#.',
      '.#......#.',
      '.#......#.',
      '.#......#.',
      '..#....#..',
      '...####...',
      '..........',
    ]);
    Stroke ring(double from, double to) => [
          for (var k = 0; k <= 60; k++)
            () {
              final a = from + (to - from) * k / 60;
              return Pt(.5 + .35 * math.sin(a), .5 - .35 * math.cos(a));
            }(),
        ];
    WritingResult judge(List<Stroke> drawn) => const HandwritingPolicy()
        .judge(drawn: drawn, mask: mask, mode: WritingMode.trace);

    test('one continuous movement is accepted', () {
      expect(judge([ring(0, 2 * math.pi)]).shapeOk, isTrue);
    });

    test('two separate movements are accepted, in any order or direction', () {
      expect(
        judge([ring(math.pi, 2 * math.pi), ring(math.pi, 0)]).shapeOk,
        isTrue,
      );
    });

    test('half a ring is incomplete; a line is not the glyph', () {
      expect(judge([ring(0, math.pi)]).shapeOk, isFalse);
      expect(
        judge([
          dense([const Pt(.1, .1), const Pt(.9, .9)]),
        ]).shapeOk,
        isFalse,
      );
    });
  });
}
