import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/teaching/teaching_lesson_screen.dart';
import 'package:aksharamala/src/teaching/teaching_plan.dart';
import 'package:aksharamala/src/teaching/teaching_progress.dart';
import 'package:aksharamala/src/teaching/teaching_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:aksharamala/src/widgets/fit_content.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final lib = pilotLibrary();

  String title(WidgetTester t) =>
      t.widget<Text>(find.byKey(const Key('teaching_title'))).data!;

  testWidgets('F1: lesson title in guided, neutral title in practice and check',
      (t) async {
    for (final id in lib.plansById.keys) {
      final plan = lib.planFor(id)!;
      final c = await makeController();
      await pumpLesson(t, c, id);
      expect(title(t), plan.title, reason: id);
      await nextTimes(t, plan.introduce.length + plan.demonstrate.length);
      expect(title(t), plan.title);
      await solveAll(t, plan.guided);
      expect(title(t), 'Practise');
      await solveAll(t, easyToHard(plan.practice));
      expect(title(t), 'Show what you know');
      expect(find.text(plan.title), findsNothing, reason: '$id check title');
      await checkAll(t, plan.check, rightCount: 0);
      expect(title(t), 'Show what you know');
      await t.pumpWidget(const SizedBox());
    }
  });

  testWidgets('F2: score page is a separate state; quick taps cannot skip it',
      (t) async {
    final c = await makeController();
    final plan = lib.planFor('en-a')!;
    await pumpLesson(t, c, 'en-a');
    await nextTimes(t, plan.introduce.length + plan.demonstrate.length);
    await solveAll(t, plan.guided);
    await solveAll(t, easyToHard(plan.practice));
    await checkAll(t, plan.check.take(2).toList(), rightCount: 2);
    await tapOption(t, plan.check.last.answer);
    final next = find.byKey(const Key('next_button'));
    await t.tap(next);
    await t.pump(const Duration(milliseconds: 40));
    expect(find.byKey(const Key('check_score')), findsOneWidget);
    expect(next, findsNothing, reason: 'Next is gone on the score page');
    final cont = find.byKey(const Key('continue_button'));
    expect(cont, findsOneWidget);
    expect(t.widget<FilledButton>(cont).onPressed, isNull,
        reason: 'inert right after the page appears');
    await t.tap(cont, warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('check_score')), findsOneWidget);
    expect(c.activeProgress.completedLessons, isEmpty);
    await t.pump(resultDebounce);
    expect(t.widget<FilledButton>(cont).onPressed, isNotNull);
    await t.tap(cont);
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(c.activeProgress.completedLessons, contains('en-a'));
  });

  group('F3 phone on its side', () {
    const sizes = [Size(915, 410), Size(800, 360), Size(640, 360)];
    for (final size in sizes) {
      testWidgets(
          '${size.width.toInt()}x${size.height.toInt()}: options, '
          'feedback and hint stay on screen', (t) async {
        final c = await makeController();
        final plan = lib.planFor('te-a')!;
        await pumpLesson(t, c, 'te-a', size: size);
        await nextTimes(t, plan.introduce.length + plan.demonstrate.length);
        final q = plan.guided.firstWhere((q) => q.options.length >= 3);
        for (final g in plan.guided) {
          if (g == q) break;
          await tapOption(t, g.answer);
          await tapNext(t);
        }
        bool onScreen(Finder f) {
          final r = t.getRect(f);
          return r.top >= 0 &&
              r.bottom <= size.height &&
              r.left >= 0 &&
              r.right <= size.width;
        }

        for (final o in q.options) {
          expect(onScreen(find.byKey(Key('option_$o'))), isTrue,
              reason: 'option $o visible without scrolling');
        }
        final prompt = t.getRect(find.byKey(const Key('question_prompt')));
        expect(prompt.top, greaterThanOrEqualTo(0));
        await t.tap(find.byKey(const Key('hint_button')));
        await t.pump();
        expect(find.text(q.hints.first), findsOneWidget);
        for (final o in q.options) {
          expect(onScreen(find.byKey(Key('option_$o'))), isTrue,
              reason: 'option $o after a hint');
        }
        final wrong = wrongOf(q);
        await t.tap(find.byKey(Key('option_$wrong')));
        await t.pump();
        final fb = find.text(q.wrongFeedback[wrong]!);
        expect(fb, findsOneWidget);
        expect(onScreen(fb), isTrue, reason: 'feedback visible');
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('Next is right-aligned in landscape', (t) async {
      final c = await makeController();
      await pumpLesson(t, c, 'en-a', size: const Size(915, 410));
      final r = t.getRect(find.byKey(const Key('next_button')));
      expect(r.right, greaterThan(915 - 24));
    });

    testWidgets('a picture step keeps its caption on screen', (t) async {
      final c = await makeController();
      final plan = lib.planFor('te-a')!;
      await pumpLesson(t, c, 'te-a', size: const Size(915, 410));
      var seen = 0;
      for (var i = 0;
          i < plan.introduce.length + plan.demonstrate.length;
          i++) {
        final cap = find.byKey(const Key('visual_caption'));
        if (cap.evaluate().isNotEmpty) {
          seen++;
          final r = t.getRect(cap);
          expect(r.bottom, lessThanOrEqualTo(410), reason: 'step $i');
          expect(r.top, greaterThanOrEqualTo(0));
        }
        expect(t.takeException(), isNull);
        await tapNext(t);
      }
      expect(seen, greaterThan(0));
    });
  });

  group('R2-1 hint and feedback together on a phone on its side', () {
    Future<void> hintAndWrong(WidgetTester t, Size size, double scale) async {
      final c = await makeController();
      final plan = lib.planFor('en-a')!;
      await pumpLesson(t, c, 'en-a', size: size, textScale: scale);
      await nextTimes(t, plan.introduce.length + plan.demonstrate.length);
      final q = plan.guided.first;
      await t.ensureVisible(find.byKey(const Key('hint_button')));
      await t.tap(find.byKey(const Key('hint_button')));
      await t.pump();
      final wrong = wrongOf(q);
      await t.ensureVisible(find.byKey(Key('option_$wrong')));
      await t.tap(find.byKey(Key('option_$wrong')));
      await t.pump();
      expect(t.takeException(), isNull);
      if (scale > 1) return; // only "no overflow" is asked at 1.6
      final hint = find.text(q.hints.first);
      final fb = find.text(q.wrongFeedback[wrong]!);
      expect(hint, findsOneWidget);
      expect(fb, findsOneWidget);
      // The strip that holds both is a scroll view; neither text may sit
      // outside its visible area (that is what "cut off" means).
      final strip =
          find.ancestor(of: fb, matching: find.byType(FitContent)).first;
      final box = t.getRect(strip);
      for (final f in [hint, fb]) {
        final r = t.getRect(f);
        expect(r.top, greaterThanOrEqualTo(box.top - 0.5), reason: '$f top');
        expect(r.bottom, lessThanOrEqualTo(box.bottom + 0.5),
            reason: '$f bottom');
        expect(r.bottom, lessThanOrEqualTo(size.height));
      }
      // The whole feedback sentence is laid out in full (not one line cut).
      final para = t.renderObject<RenderParagraph>(fb);
      // (The strip may be scaled down a little to fit; never cut.)
      expect(t.getRect(fb).height,
          greaterThanOrEqualTo((para.size.height - 1) * 0.6));
      // At least two options stay on screen.
      var visible = 0;
      for (final o in q.options) {
        final r = t.getRect(find.byKey(Key('option_$o')));
        if (r.top >= 0 && r.bottom <= size.height) visible++;
      }
      expect(visible, greaterThanOrEqualTo(2));
    }

    for (final size in const [Size(800, 360), Size(915, 410)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()} text 1.0',
          (t) => hintAndWrong(t, size, 1.0));
    }
    testWidgets('640x360 text 1.6 has no overflow',
        (t) => hintAndWrong(t, const Size(640, 360), 1.6));
  });

  group('R3-1 options keep the rest of the pane after a hint', () {
    for (final size in const [Size(915, 410), Size(800, 360), Size(640, 360)]) {
      for (final scale in [1.0, 1.3, 1.6]) {
        testWidgets('${size.width.toInt()}x${size.height.toInt()} text $scale',
            (t) async {
          final c = await makeController();
          final plan = lib.planFor('te-a')!;
          await pumpLesson(t, c, 'te-a', size: size, textScale: scale);
          await nextTimes(t, plan.introduce.length + plan.demonstrate.length);
          final q = plan.guided.firstWhere((q) => q.options.length >= 3);
          for (final g in plan.guided) {
            if (g == q) break;
            await tapOption(t, g.answer);
            await tapNext(t);
          }
          Future<void> check(String when) async {
            final first = find.byKey(Key('option_${q.options.first}'));
            final scroll = find.byKey(const Key('options_area'));
            final area = t.getRect(scroll);
            final nextTop = t.getRect(find.byKey(const Key('next_button'))).top;
            expect(area.height, greaterThanOrEqualTo(56),
                reason: '$when: room for one tappable row');
            expect(area.bottom, greaterThan(nextTop - 20),
                reason: '$when: no dead area under the options');
            for (final o in q.options) {
              final f = find.byKey(Key('option_$o'));
              await t.ensureVisible(f);
              await t.pump();
              // FitContent decides between scaling and scrolling after a
              // layout, so give it the frame it needs to settle.
              await t.pump();
              await t.ensureVisible(f);
              await t.pump();
              final r = t.getRect(f);
              final a2 = t.getRect(scroll);
              expect(r.top, greaterThanOrEqualTo(a2.top - 1),
                  reason: '$when $o');
              expect(r.bottom, lessThanOrEqualTo(a2.bottom + 1),
                  reason: '$when $o fully inside the options area');
            }
            expect(t.takeException(), isNull);
          }

          await check('before the hint');
          await t.ensureVisible(find.byKey(const Key('hint_button')));
          await t.tap(find.byKey(const Key('hint_button')));
          await t.pump();
          await check('after a hint');
          await t.tap(find.byKey(const Key('hint_button')));
          await t.pump();
          await check('after two hints');
          await t.tap(find.byKey(Key('option_${wrongOf(q)}')));
          await t.pump();
          await check('hints and a wrong answer');
        });
      }
    }
  });

  testWidgets('equals sign stays with its result; plus never wraps alone',
      (t) async {
    t.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(260, 400);
    addTearDown(t.view.reset);
    const v = TeachingVisual(
      type: VisualType.objects,
      groups: [
        ObjectGroup(emoji: 'A', count: 5),
        ObjectGroup(emoji: 'B', count: 3),
      ],
      result: 8,
      showResult: true,
    );
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: TeachingVisualView(visual: v))),
      ),
    );
    await t.pumpAndSettle();
    final eq = t.getRect(find.text('='));
    final res = t.getRect(find.byKey(const Key('objects_result')));
    expect((eq.center.dy - res.center.dy).abs(), lessThan(20));
    expect(eq.right, lessThanOrEqualTo(res.left + 1));
    final plus = t.getRect(find.text('+'));
    final g1 = t.getRect(find.byKey(const Key('object_group_1')));
    expect((plus.center.dy - g1.center.dy).abs(), lessThan(g1.height));
    expect(plus.right, lessThanOrEqualTo(g1.left + 1));
    expect(t.takeException(), isNull);
  });

  test('F7: wrongly typed teaching fields are ignored, the save survives', () {
    final base = {
      'completedLessons': ['en-a'],
      'attempts': {'english': 1},
      'correct': {'english': 1},
      'lastPlayed': <String, String>{},
      'earnedBadges': <String>[],
      'questStars': {'en-a': 3},
    };
    for (final bad in <Object?>[
      'x',
      7,
      [1, 2],
      {'en-a': 'oops'},
      {'en-a': null},
      {
        'en-a': [1]
      },
    ]) {
      final r = ProgressRecord.fromJson({...base, 'teaching': bad});
      expect(r.completedLessons, {'en-a'});
      expect(r.questStars['en-a'], 3);
    }
    final p = TeachingProgress.fromJson({
      'viewed': 'yes',
      'phasesDone': 'x',
      'guidedDone': 3,
      'checkBestScore': 'two',
      'checkLastScore': 2,
      'mastery': 5,
      'remediationCycles': 'a',
      'updatedAt': 9,
      'phase': 7,
    });
    expect(p.viewed, isFalse);
    expect(p.phasesDone, isEmpty);
    expect(p.checkBestScore, isNull);
    expect(p.checkLastScore, 2, reason: 'a good field next to bad ones stays');
    expect(p.mastery, MasteryStatus.notStarted);
    expect(p.phase, isNull);
    final mixed = TeachingProgress.fromJson({
      'phasesDone': ['introduce', 3, null],
    });
    expect(mixed.phasesDone, {'introduce'});
    final rec = ProgressRecord.fromJson({
      ...base,
      'teaching': {
        'en-a': {'phasesDone': 'x', 'mastery': 'mastered'},
        'te-a': 'bad',
      },
    });
    expect(rec.teaching.keys, ['en-a']);
    expect(rec.teaching['en-a']!.mastery, MasteryStatus.mastered);
  });
}
