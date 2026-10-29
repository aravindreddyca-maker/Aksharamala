import 'dart:math' as math;

import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/batch/batch_content.dart';
import 'package:aksharamala/src/handwriting/digit_templates.dart';
import 'package:aksharamala/src/handwriting/glyph_mask.dart';
import 'package:aksharamala/src/screens/batch_lesson_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Saving is real file IO, which stalls widget tests; nothing here needs it.
class _NoDiskStore extends LocalStore {
  @override
  Future<LocalSnapshot> load() async =>
      const LocalSnapshot(profiles: [], progress: {});

  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

/// A stand-in for the font: a plain ring.
Future<GlyphMask> _ring(String glyph) async {
  const n = 32;
  return GlyphMask(n, [
    for (var y = 0; y < n; y++)
      for (var x = 0; x < n; x++)
        ((math.sqrt(math.pow((x + .5) / n - .5, 2) +
                        math.pow((y + .5) / n - .5, 2)) -
                    .28)
                .abs() <=
            .04),
  ]);
}

void main() {
  late AppController controller;

  Future<void> open(
    WidgetTester tester,
    String worldId,
    int index,
  ) async {
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    controller = AppController(store: _NoDiskStore());
    await controller.initialise();
    await controller.addProfile('Meena', 4, 'lion');
    await controller.setNewLessons(true);
    final world = controller.worlds.firstWhere((w) => w.id == worldId);
    final lesson = (worldId == 'telugu' ? teluguBatch : numbersBatch)[index];
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          theme: buildTheme(),
          home: BatchLessonScreen(
            world: world,
            lesson: lesson,
            maskLoader: _ring,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('batch_next')));
    await tester.pump();
  }

  Future<void> tapAnswer(WidgetTester tester, String option) async {
    final finder = find.byKey(Key('answer_$option'));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  String prompt(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('step_prompt'))).data!;

  Future<void> draw(WidgetTester tester, List<Offset> unit) async {
    final rect = tester.getRect(find.byKey(const Key('writing_pad')));
    final pts = [
      for (final p in unit)
        Offset(rect.left + p.dx * rect.width, rect.top + p.dy * rect.height),
    ];
    final g = await tester.startGesture(pts.first);
    for (final p in pts.skip(1)) {
      await g.moveTo(p);
      await tester.pump();
    }
    await g.up();
    await tester.pump();
  }

  Future<void> traceDigit(WidgetTester tester, int n) async {
    for (final s in digitTemplates[n]!.strokes) {
      await draw(tester, [for (final p in s) Offset(p.x, p.y)]);
    }
  }

  group('a Telugu lesson, from start to finish', () {
    testWidgets('a mistake on the way pays 1 star, and the words are Telugu',
        (tester) async {
      await open(tester, 'telugu', 0); // అ – అమ్మ
      expect(prompt(tester), 'అక్షరాన్ని వినండి');
      expect(find.text('అ'), findsWidgets);
      await next(tester);

      expect(prompt(tester), 'ఈ అక్షరం ఏది?');
      // Next is locked until the right letter is picked.
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('batch_next')))
            .onPressed,
        isNull,
      );
      await tapAnswer(tester, 'ఇ'); // wrong
      expect(find.text('మళ్ళీ ప్రయత్నించండి'), findsOneWidget);
      await tapAnswer(tester, 'అ');
      expect(find.text('శభాష్!'), findsOneWidget);
      await next(tester);

      expect(prompt(tester), 'అ తో మొదలయ్యే పదం ఏది?');
      await tapAnswer(tester, 'అమ్మ');
      await next(tester);

      // Writing: practice, can be skipped.
      expect(prompt(tester), 'అ అక్షరాన్ని వ్రాయండి');
      expect(find.text('Skip'), findsOneWidget);
      await next(tester);
      expect(find.text('Finish'), findsOneWidget);
      await next(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('result_back')), findsOneWidget);
      expect(controller.activeProfile!.stars, 1);
      expect(controller.activeProgress.completedLessons, isEmpty,
          reason: 'a mistake means not yet finished');
    });

    testWidgets('a clean run finishes the lesson and pays 3', (tester) async {
      await open(tester, 'telugu', 1); // ఆ – ఆవు
      await next(tester);
      await tapAnswer(tester, 'ఆ');
      await next(tester);
      await tapAnswer(tester, 'ఆవు');
      await next(tester);
      await next(tester);
      await next(tester);
      await tester.pumpAndSettle();
      expect(controller.activeProfile!.stars, 3);
      expect(controller.activeProgress.completedLessons,
          contains('telugu-recognise-002'));
    });

    testWidgets('the letter-only lesson (ఎ) has no word step', (tester) async {
      await open(tester, 'telugu', 6);
      await next(tester);
      await tapAnswer(tester, 'ఎ');
      await next(tester);
      expect(prompt(tester), 'ఎ అక్షరాన్ని వ్రాయండి');
    });

    testWidgets('wrong answers can only be tried once each', (tester) async {
      await open(tester, 'telugu', 0);
      await next(tester);
      await tapAnswer(tester, 'ఇ');
      await tapAnswer(tester, 'ఇ');
      await tapAnswer(tester, 'ఋ');
      await tapAnswer(tester, 'అ');
      await next(tester);
      await tapAnswer(tester, 'అమ్మ');
      await next(tester);
      await next(tester);
      await next(tester);
      await tester.pumpAndSettle();
      expect(controller.activeProfile!.stars, 1);
    });

    testWidgets('the same answers appear in a different order next time',
        (tester) async {
      await open(tester, 'telugu', 0);
      await next(tester);
      final labels = [
        for (final o in ['అ', 'ఇ', 'ఋ'])
          tester.getTopLeft(find.byKey(Key('answer_$o'))).dy,
      ];
      expect(labels.toSet().length, 3);
    });
  });

  group('a Number Galaxy lesson', () {
    testWidgets('quantity, counting, comparing and writing 3', (tester) async {
      await open(tester, 'numbers', 3);
      expect(prompt(tester), 'This is the number 3.');
      await next(tester);

      expect(prompt(tester), 'Which group has 3 stars?');
      await tapAnswer(tester, '3');
      await next(tester);

      expect(prompt(tester), 'Tap each star to count. How many stars?');
      expect(find.byKey(const Key('count_so_far')), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(Key('count_star_$i')));
        await tester.pump();
      }
      expect(
          tester.widget<Text>(find.byKey(const Key('count_so_far'))).data, '3');
      await tapAnswer(tester, '3');
      await next(tester);

      expect(prompt(tester), 'Which number is smaller: 3 or 4?');
      await tapAnswer(tester, '3');
      await next(tester);

      // Guided writing: the right shape is accepted.
      expect(prompt(tester), 'Trace the number 3.');
      await traceDigit(tester, 3);
      await tester.tap(find.byKey(const Key('write_check')));
      await tester.pump();
      expect(find.text('Well written!'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      await next(tester);

      // Independent writing: a scribble is not accepted.
      expect(prompt(tester), 'Now write 3 yourself.');
      final rnd = math.Random(5);
      await draw(tester, [
        for (var i = 0; i < 40; i++) Offset(rnd.nextDouble(), rnd.nextDouble()),
      ]);
      await tester.tap(find.byKey(const Key('write_check')));
      await tester.pump();
      expect(find.text('Well written!'), findsNothing);
      expect(find.text('Follow the shape of the number'), findsOneWidget);
      await next(tester);
      await tester.pumpAndSettle();

      // Handwriting never blocks or pays: a clean quiz still pays 3.
      expect(controller.activeProfile!.stars, 3);
    });

    testWidgets('writing the wrong number is not accepted', (tester) async {
      await open(tester, 'numbers', 3);
      for (var i = 0; i < 4; i++) {
        await next(tester);
        if (i < 3) {
          // answer the question on each step
          if (i == 0) await tapAnswer(tester, '3');
          if (i == 1) {
            for (var k = 0; k < 3; k++) {
              await tester.tap(find.byKey(Key('count_star_$k')));
              await tester.pump();
            }
            await tapAnswer(tester, '3');
          }
          if (i == 2) await tapAnswer(tester, '3');
        }
      }
      await traceDigit(tester, 7);
      await tester.tap(find.byKey(const Key('write_check')));
      await tester.pump();
      expect(find.text('Well written!'), findsNothing);
    });

    testWidgets('zero shows an empty box to count', (tester) async {
      await open(tester, 'numbers', 0);
      await next(tester);
      await tapAnswer(tester, '0');
      await next(tester);
      expect(prompt(tester), 'How many stars are in the box?');
      expect(find.byKey(const Key('count_star_0')), findsNothing);
      await tapAnswer(tester, '0');
      expect(find.text('Great!'), findsOneWidget);
    });
  });

  group('writing on a letter with no stroke template', () {
    testWidgets('a scribble is refused and nothing is awarded', (tester) async {
      await open(tester, 'telugu', 0);
      await next(tester);
      await tapAnswer(tester, 'అ');
      await next(tester);
      await tapAnswer(tester, 'అమ్మ');
      await next(tester);
      await tester.pumpAndSettle();
      final rnd = math.Random(2);
      await draw(tester, [
        for (var i = 0; i < 40; i++) Offset(rnd.nextDouble(), rnd.nextDouble()),
      ]);
      await tester.tap(find.byKey(const Key('write_check')));
      await tester.pump();
      expect(find.text('బాగా వ్రాశారు!'), findsNothing);
      expect(find.text('అక్షరం ఆకారాన్ని అనుసరించండి'), findsOneWidget);
    });

    testWidgets('tracing the shape is accepted as practice only',
        (tester) async {
      await open(tester, 'telugu', 0);
      await next(tester);
      await tapAnswer(tester, 'అ');
      await next(tester);
      await tapAnswer(tester, 'అమ్మ');
      await next(tester);
      await tester.pumpAndSettle();
      await draw(tester, [
        for (var k = 0; k <= 40; k++)
          Offset(.5 + .28 * math.sin(2 * math.pi * k / 40),
              .5 - .28 * math.cos(2 * math.pi * k / 40)),
      ]);
      await tester.tap(find.byKey(const Key('write_check')));
      await tester.pump();
      expect(find.text('బాగా వ్రాశారు!'), findsOneWidget);
      // ...but it pays nothing and completes nothing by itself.
      expect(controller.activeProfile!.stars, 0);
    });
  });
}
