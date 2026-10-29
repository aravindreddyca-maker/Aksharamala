import 'dart:math' as math;

import 'package:aksharamala/src/handwriting/digit_templates.dart';
import 'package:aksharamala/src/handwriting/glyph_mask.dart';
import 'package:aksharamala/src/handwriting/handwriting_policy.dart';
import 'package:aksharamala/src/handwriting/stroke_template.dart';
import 'package:aksharamala/src/handwriting/stroke_validator.dart';
import 'package:flutter_test/flutter_test.dart';

const validator = StrokeValidator();

/// A child's attempt: the template with wobble, as if drawn by hand.
List<Stroke> attempt(
  StrokeTemplate t, {
  double jitter = 0.025,
  int seed = 1,
  double scale = 1,
  Pt shift = const Pt(0, 0),
}) {
  final r = math.Random(seed);
  Pt p(Pt q) => Pt(
        q.x * scale + shift.x + (r.nextDouble() - .5) * 2 * jitter,
        q.y * scale + shift.y + (r.nextDouble() - .5) * 2 * jitter,
      );
  return [
    for (final s in t.strokes)
      [
        for (var i = 0; i < s.length; i += (i % 3 == 0 ? 2 : 1)) p(s[i]),
        p(s.last),
      ],
  ];
}

void main() {
  group('digit templates', () {
    test('there is one for every number 0 to 10', () {
      expect(digitTemplates.keys.toList()..sort(),
          [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('each is well formed and inside the writing square', () {
      for (final e in digitTemplates.entries) {
        final t = e.value;
        expect(t.glyph, '${e.key}');
        expect(t.script, 'numbers');
        expect(t.isUsable, isTrue, reason: t.glyph);
        for (final s in t.strokes) {
          for (final p in s) {
            expect(p.x, inInclusiveRange(0.0, 1.0), reason: t.glyph);
            expect(p.y, inInclusiveRange(0.0, 1.0), reason: t.glyph);
          }
          expect(pathLength(s), greaterThan(0.3), reason: t.glyph);
        }
      }
    });

    test('stroke counts', () {
      expect(digitTemplates[4]!.strokes.length, 2);
      expect(digitTemplates[10]!.strokes.length, 2);
      for (final n in [0, 1, 2, 3, 5, 6, 7, 8, 9]) {
        expect(digitTemplates[n]!.strokes.length, 1, reason: '$n');
      }
    });

    test('none claims a teacher has verified its stroke order', () {
      expect(
          digitTemplates.values.every((t) => !t.strokeOrderVerified), isTrue);
    });
  });

  group('accepting real writing', () {
    for (final mode in WritingMode.values) {
      test('every digit written with a shaky hand passes ($mode)', () {
        for (final e in digitTemplates.entries) {
          for (final seed in [1, 2, 3, 4, 5]) {
            final r = validator.check(
              e.value,
              attempt(e.value, seed: seed),
              mode: mode,
            );
            expect(r.problem, isNull,
                reason: 'digit ${e.key} seed $seed: ${r.problem}');
          }
        }
      });
    }

    test('independent writing may be any size and anywhere on the pad', () {
      for (final e in digitTemplates.entries) {
        final r = validator.check(
          e.value,
          attempt(e.value, scale: 0.45, shift: const Pt(0.4, 0.1)),
          mode: WritingMode.independent,
        );
        expect(r.problem, isNull, reason: 'digit ${e.key}');
      }
    });

    test('guided writing must stay on the guide', () {
      final t = digitTemplates[7]!;
      final r = validator.check(
        t,
        attempt(t, scale: 0.45, shift: const Pt(0.45, 0.45)),
      );
      expect(r.passed, isFalse);
    });
  });

  group('rejecting what is not writing', () {
    List<Stroke> zigzag(int seed) {
      final r = math.Random(seed);
      return [
        [for (var i = 0; i < 60; i++) Pt(r.nextDouble(), r.nextDouble())],
      ];
    }

    test('a random scribble fails every digit, in both modes', () {
      for (final e in digitTemplates.entries) {
        for (final seed in [1, 2, 3, 4, 5, 6]) {
          for (final mode in WritingMode.values) {
            final r = validator.check(e.value, zigzag(seed), mode: mode);
            expect(r.passed, isFalse,
                reason: 'digit ${e.key} seed $seed $mode');
          }
        }
      }
    });

    test('nothing and dots are "nothing drawn"', () {
      final t = digitTemplates[3]!;
      expect(validator.check(t, const []).problem, StrokeProblem.nothing);
      expect(
        validator.check(t, [
          [const Pt(.5, .5), const Pt(.5, .501)],
        ]).problem,
        StrokeProblem.nothing,
      );
    });

    test('a straight line is not any digit but 1 or 7-like shapes', () {
      final line = [
        [const Pt(.2, .5), const Pt(.8, .5)],
      ];
      for (final n in [0, 2, 3, 5, 6, 8, 9]) {
        expect(validator.check(digitTemplates[n]!, line).passed, isFalse,
            reason: '$n');
      }
    });

    test('a digit does not pass as a different digit', () {
      for (final a in digitTemplates.entries) {
        for (final b in digitTemplates.entries) {
          if (a.key == b.key) continue;
          for (final mode in WritingMode.values) {
            final r = validator.check(b.value, attempt(a.value), mode: mode);
            expect(r.passed, isFalse,
                reason: '${a.key} accepted as ${b.key} ($mode)');
          }
        }
      }
    });

    test('a circle is a 0 but not a 6 or 8', () {
      final zero = attempt(digitTemplates[0]!);
      expect(validator.check(digitTemplates[0]!, zero).passed, isTrue);
      expect(validator.check(digitTemplates[6]!, zero).passed, isFalse);
      expect(validator.check(digitTemplates[8]!, zero).passed, isFalse);
    });

    test('too few strokes is unfinished', () {
      final t = digitTemplates[4]!;
      final one = [attempt(t).first];
      expect(validator.check(t, one).problem, StrokeProblem.tooFewStrokes);
    });

    test('too many strokes is rejected', () {
      final t = digitTemplates[7]!;
      final two = [...attempt(t), ...attempt(t, seed: 9)];
      expect(validator.check(t, two).problem, StrokeProblem.tooManyStrokes);
    });

    test('a stroke drawn backwards is reported as the wrong direction', () {
      final t = digitTemplates[7]!;
      final backwards = [attempt(t).first.reversed.toList()];
      final r = validator.check(t, backwards);
      expect(r.problem, StrokeProblem.wrongDirection);
      expect(r.badStroke, 0);
    });

    test('strokes in the wrong order are reported', () {
      final t = digitTemplates[10]!;
      final good = attempt(t);
      final swapped = [good[1], good[0]];
      final r = validator.check(t, swapped);
      expect(r.problem, StrokeProblem.wrongOrder);
    });

    test('scribbling over one stroke again and again is rejected', () {
      final t = digitTemplates[1]!;
      final stroke = attempt(t).first;
      final repeated = [
        [
          ...stroke,
          ...stroke.reversed,
          ...stroke,
          ...stroke.reversed,
          ...stroke,
        ],
      ];
      expect(validator.check(t, repeated).passed, isFalse);
    });
  });

  group('resample', () {
    test('keeps the ends and spaces points evenly', () {
      final s = [const Pt(0, 0), const Pt(1, 0)];
      final r = resample(s, 5);
      expect(r.length, 5);
      expect(r.first, const Pt(0, 0));
      expect(r.last.x, closeTo(1, 1e-9));
      expect(r[2].x, closeTo(0.5, 1e-9));
    });

    test('handles a bent path and a single point', () {
      final bent =
          resample([const Pt(0, 0), const Pt(1, 0), const Pt(1, 1)], 9);
      expect(bent.length, 9);
      expect(bent[4].x, closeTo(1, 1e-9));
      expect(resample([const Pt(.3, .3)], 4).length, 4);
    });
  });

  group('mask check (glyphs with no template yet)', () {
    // A ring: the shape of "0" without any stroke data. Pen thickness is
    // 0.08 of the pad, like a real glyph.
    const n = 32;
    final ring = GlyphMask(n, [
      for (var y = 0; y < n; y++)
        for (var x = 0; x < n; x++)
          ((math.sqrt(math.pow((x + .5) / n - .5, 2) +
                          math.pow((y + .5) / n - .5, 2)) -
                      .28)
                  .abs() <=
              .04),
    ]);

    List<Stroke> circle({double r = 0.28, double cx = .5, double cy = .5}) => [
          [
            for (var k = 0; k <= 40; k++)
              Pt(cx + r * math.sin(2 * math.pi * k / 40),
                  cy - r * math.cos(2 * math.pi * k / 40)),
          ],
        ];

    const mv = MaskValidator();

    test('tracing the ring passes', () {
      final r = mv.check(ring, circle());
      expect(r.problem, isNull, reason: '${r.coverage} ${r.precision}');
    });

    test('a half ring is incomplete', () {
      final half = [circle().first.take(20).toList()];
      expect(mv.check(ring, half).problem, MaskProblem.incomplete);
    });

    test('a line across the page is off the shape', () {
      final r = mv.check(ring, [
        [const Pt(.05, .05), const Pt(.95, .95)],
      ]);
      expect(r.problem, MaskProblem.offShape);
    });

    test('a scribble all over the page is off the shape', () {
      final rnd = math.Random(7);
      final r = mv.check(ring, [
        [for (var i = 0; i < 80; i++) Pt(rnd.nextDouble(), rnd.nextDouble())],
      ]);
      expect(r.passed, isFalse);
    });

    test('colouring the ring in again and again is too much ink', () {
      final strokes = [
        for (var i = 0; i < 8; i++) circle().first,
      ];
      expect(mv.check(ring, strokes).problem, MaskProblem.tooMuchInk);
    });

    test('nothing drawn', () {
      expect(mv.check(ring, const []).problem, MaskProblem.nothing);
    });

    test('independent mode accepts a smaller ring elsewhere on the pad', () {
      final r = mv.check(
        ring,
        circle(r: 0.12, cx: .75, cy: .3),
        mode: WritingMode.independent,
      );
      expect(r.problem, isNull, reason: '${r.coverage} ${r.precision}');
    });
  });

  group('policy: what an attempt is worth', () {
    const policy = HandwritingPolicy();
    final unverified = digitTemplates[7]!;
    final verified = StrokeTemplate(
      glyph: unverified.glyph,
      script: unverified.script,
      strokes: unverified.strokes,
      strokeOrderVerified: true,
    );

    test('a good shape on an unverified template is practice, not mastery', () {
      final r = policy.judge(drawn: attempt(unverified), template: unverified);
      expect(r.outcome, WritingOutcome.goodShape);
      expect(r.shapeOk, isTrue);
      expect(r.awardsMastery, isFalse);
    });

    test('mastery needs a verified template', () {
      final r = policy.judge(drawn: attempt(verified), template: verified);
      expect(r.outcome, WritingOutcome.mastered);
      expect(r.awardsMastery, isTrue);
    });

    test('a scribble never earns anything, verified or not', () {
      final rnd = math.Random(3);
      final scribble = [
        [for (var i = 0; i < 60; i++) Pt(rnd.nextDouble(), rnd.nextDouble())],
      ];
      for (final t in [unverified, verified]) {
        final r = policy.judge(drawn: scribble, template: t);
        expect(r.outcome, WritingOutcome.tryAgain);
        expect(r.awardsMastery, isFalse);
        expect(r.shapeOk, isFalse);
      }
    });

    test('a wrong direction on a verified template is not mastery', () {
      final back = [attempt(verified).first.reversed.toList()];
      final r = policy.judge(drawn: back, template: verified);
      expect(r.awardsMastery, isFalse);
      expect(r.stroke!.problem, StrokeProblem.wrongDirection);
    });

    test('a mask alone can only ever give a good shape', () {
      final ring = GlyphMask.fromRows([
        for (var y = 0; y < 8; y++)
          [
            for (var x = 0; x < 8; x++)
              (y == 0 || y == 7 || x == 0 || x == 7) ? '#' : '.'
          ].join(),
      ]);
      final square = [
        [
          const Pt(.07, .07),
          const Pt(.93, .07),
          const Pt(.93, .93),
          const Pt(.07, .93),
          const Pt(.07, .07),
        ],
      ];
      final r = policy.judge(drawn: square, mask: ring);
      expect(r.outcome, WritingOutcome.goodShape);
      expect(r.awardsMastery, isFalse);
    });

    test('with no template and no mask, nothing can be judged', () {
      expect(policy.judge(drawn: attempt(unverified)).outcome,
          WritingOutcome.nothing);
    });

    test('nothing drawn stays "nothing"', () {
      expect(policy.judge(drawn: const [], template: verified).outcome,
          WritingOutcome.nothing);
    });
  });
}
