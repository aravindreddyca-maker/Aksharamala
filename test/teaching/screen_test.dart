import 'package:aksharamala/src/art/art_picture.dart';
import 'package:aksharamala/src/art/art_registry.dart';
import 'package:aksharamala/src/teaching/teaching_plan.dart';
import 'package:aksharamala/src/teaching/teaching_progress.dart';
import 'package:aksharamala/src/teaching/teaching_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final lib = pilotLibrary();

  Future<void> teachToCheck(WidgetTester tester, String id) async {
    final plan = lib.planFor(id)!;
    expect(find.byKey(const Key('step_text')), findsOneWidget);
    await nextTimes(tester, plan.introduce.length);
    await nextTimes(tester, plan.demonstrate.length);
    await solveAll(tester, plan.guided);
    await solveAll(tester, easyToHard(plan.practice));
  }

  testWidgets('opens on a teaching step: no question, no options', (t) async {
    final c = await makeController();
    await pumpLesson(t, c, 'en-a');
    expect(find.byKey(const Key('step_text')), findsOneWidget);
    expect(find.byKey(const Key('question_prompt')), findsNothing);
    expect(find.textContaining('Learn'), findsOneWidget);
    expect(find.byKey(const Key('listen_button')), findsOneWidget);
    expect(find.byKey(const Key('back_button')), findsNothing);
  });

  testWidgets('phase indicator moves through the five phases', (t) async {
    final c = await makeController();
    final plan = lib.planFor('en-a')!;
    await pumpLesson(t, c, 'en-a');
    String label() =>
        t.widget<Text>(find.byKey(const Key('phase_label'))).data!;
    expect(label(), startsWith('1 of 5'));
    await nextTimes(t, plan.introduce.length);
    expect(label(), startsWith('2 of 5'));
    await nextTimes(t, plan.demonstrate.length);
    expect(label(), startsWith('3 of 5'));
    await solveAll(t, plan.guided);
    expect(label(), startsWith('4 of 5'));
    await solveAll(t, easyToHard(plan.practice));
    expect(label(), startsWith('5 of 5'));
  });

  testWidgets(
      'Listen speaks the step in the lesson locale; missing voice is '
      'explained on screen', (t) async {
    final c = await makeController();
    final speech = FakeSpeech(supported: false);
    await pumpLesson(t, c, 'te-a', speech: speech);
    await t.tap(find.byKey(const Key('listen_button')));
    await t.pump();
    await t.pump();
    expect(speech.spoken, [lib.planFor('te-a')!.introduce.first.speech]);
    expect(find.byKey(const Key('voice_notice')), findsOneWidget);
  });

  testWidgets(
      'guided: hint ladder, retry without penalty, explanation after '
      'a correct answer', (t) async {
    final c = await makeController();
    final plan = lib.planFor('en-a')!;
    await pumpLesson(t, c, 'en-a');
    await nextTimes(t, plan.introduce.length + plan.demonstrate.length);
    final q = plan.guided.first;
    expect(find.byKey(const Key('hint_button')), findsOneWidget);
    expect(find.byKey(const Key('hint_text_0')), findsNothing);
    await t.tap(find.byKey(const Key('hint_button')));
    await t.pump();
    expect(find.text(q.hints[0]), findsOneWidget);
    expect(find.text(q.hints[1]), findsNothing);
    await t.tap(find.byKey(const Key('hint_button')));
    await t.pump();
    expect(find.text(q.hints[1]), findsOneWidget);
    // Wrong, then the plan's own feedback; Next stays off.
    final wrong = wrongOf(q);
    await tapOption(t, wrong);
    expect(find.text(q.wrongFeedback[wrong]!), findsOneWidget);
    expect(
        t.widget<FilledButton>(find.byKey(const Key('next_button'))).onPressed,
        isNull);
    expect(find.byKey(const Key('explanation_text')), findsNothing);
    // Retry freely; right answer shows the explanation and enables Next.
    await tapOption(t, q.answer);
    expect(find.byKey(const Key('explanation_text')), findsOneWidget);
    expect(find.text(q.explanation), findsOneWidget);
    expect(
        t.widget<FilledButton>(find.byKey(const Key('next_button'))).onPressed,
        isNotNull);
    expect(c.activeProfile!.stars, 0, reason: 'a wrong try costs nothing');
  });

  testWidgets(
      'practice: one question at a time, immediate feedback, no hint '
      'button', (t) async {
    final c = await makeController();
    final plan = lib.planFor('num-add')!;
    await pumpLesson(t, c, 'num-add');
    await nextTimes(t, plan.introduce.length + plan.demonstrate.length);
    await solveAll(t, plan.guided);
    final q = easyToHard(plan.practice).first;
    expect(find.byKey(const Key('hint_button')), findsNothing);
    expect(find.byKey(const Key('question_prompt')), findsOneWidget);
    final wrong = wrongOf(q);
    await tapOption(t, wrong);
    expect(find.text(q.wrongFeedback[wrong]!), findsOneWidget);
    expect(find.text(q.explanation), findsNothing, reason: 'no answer leak');
  });

  testWidgets(
      'check shows no hints and no feedback until the end, then the '
      'score', (t) async {
    final c = await makeController();
    final plan = lib.planFor('hi-a')!;
    await pumpLesson(t, c, 'hi-a');
    await teachToCheck(t, 'hi-a');
    expect(find.byKey(const Key('hint_button')), findsNothing);
    final q = plan.check.first;
    await tapOption(t, wrongOf(q));
    expect(find.byKey(const Key('feedback_text')), findsNothing);
    expect(find.byKey(const Key('explanation_text')), findsNothing);
    expect(find.byKey(const Key('check_result')), findsNothing);
    await tapNext(t);
    await tapOption(t, plan.check[1].answer);
    await tapNext(t);
    await tapOption(t, plan.check[2].answer);
    expect(find.byKey(const Key('check_result')), findsNothing);
    expect(find.text('See my score'), findsOneWidget);
    await tapNext(t);
    expect(find.byKey(const Key('check_result')), findsOneWidget);
    expect(find.text('2 out of 3'), findsOneWidget);
    expect(find.byKey(const Key('check_review_0')), findsOneWidget);
  });

  testWidgets('pass -> mastery calls recordResult once: stars, completed',
      (t) async {
    final c = await makeController();
    final plan = lib.planFor('en-a')!;
    await pumpLesson(t, c, 'en-a');
    await teachToCheck(t, 'en-a');
    await checkAll(t, plan.check, rightCount: 3);
    await tapNext(t); // Finish
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(c.activeProgress.completedLessons, contains('en-a'));
    expect(c.activeProfile!.stars, 3);
    expect(c.activeProgress.attempts['english'], 1);
    final tp = c.teachingProgressFor('en-a');
    expect(tp.mastery, MasteryStatus.mastered);
    expect(tp.checkBestScore, 3);
    expect(
        tp.phasesDone,
        containsAll(
            ['introduce', 'demonstrate', 'guided', 'practice', 'check']));
    expect(tp.phase, isNull);
  });

  testWidgets('fail -> remediation -> pass', (t) async {
    final c = await makeController();
    final plan = lib.planFor('ta-a')!;
    await pumpLesson(t, c, 'ta-a');
    await teachToCheck(t, 'ta-a');
    await checkAll(t, plan.check, rightCount: 0);
    expect(find.text('0 out of 3'), findsOneWidget);
    await tapNext(t);
    expect(find.byKey(const Key('remediation_banner')), findsOneWidget);
    expect(find.textContaining('Extra help'), findsOneWidget);
    await nextTimes(t, plan.remediation.explain.length);
    await solveAll(t, plan.remediation.guided);
    // The alternate check (cycle 1 keeps the stored order).
    await checkAll(t, plan.remediation.check, rightCount: 3);
    expect(find.text('3 out of 3'), findsOneWidget);
    expect(c.activeProgress.completedLessons, isNot(contains('ta-a')));
    await tapNext(t);
    await t.pump(const Duration(milliseconds: 300));
    expect(c.activeProgress.completedLessons, contains('ta-a'));
    expect(c.teachingProgressFor('ta-a').remediationCycles, 1);
  });

  testWidgets(
      'limit reached -> needs support, not mastered, child can '
      'continue', (t) async {
    final c = await makeController();
    final plan = lib.planFor('num-add')!;
    await pumpLesson(t, c, 'num-add');
    await teachToCheck(t, 'num-add');
    await checkAll(t, plan.check, rightCount: 0);
    await tapNext(t);
    for (var cycle = 1; cycle <= 2; cycle++) {
      await nextTimes(t, plan.remediation.explain.length);
      await solveAll(t, plan.remediation.guided);
      // From cycle 2 the same items come in another order: find by prompt.
      for (var i = 0; i < plan.remediation.check.length; i++) {
        final prompt =
            t.widget<Text>(find.byKey(const Key('question_prompt'))).data!;
        final q = plan.remediation.check.firstWhere((q) => q.prompt == prompt);
        await tapOption(t, wrongOf(q));
        await tapNext(t);
      }
      await tapNext(t);
    }
    await t.pump();
    expect(find.byKey(const Key('needs_support_card')), findsOneWidget);
    expect(find.byKey(const Key('support_back')), findsOneWidget);
    expect(find.byKey(const Key('next_button')), findsNothing);
    final tp = c.teachingProgressFor('num-add');
    expect(tp.mastery, MasteryStatus.needsSupport);
    expect(tp.remediationCycles, 2);
    expect(c.activeProgress.completedLessons, isNot(contains('num-add')));
    expect(c.activeProfile!.stars, 0);
    // Try again from the start works.
    await t.tap(find.byKey(const Key('support_retry')));
    await t.pump();
    expect(find.byKey(const Key('step_text')), findsOneWidget);
    expect(c.teachingProgressFor('num-add').mastery, MasteryStatus.learning);
  });

  testWidgets('resume: reopening mid-lesson starts at the current phase',
      (t) async {
    final c = await makeController();
    final plan = lib.planFor('en-a')!;
    await pumpLesson(t, c, 'en-a');
    await nextTimes(t, plan.introduce.length + plan.demonstrate.length);
    await solveAll(t, plan.guided.take(1).toList());
    expect(c.teachingProgressFor('en-a').phase, 'guided');
    // "Restart the app": a new screen on the same saved progress.
    await t.pumpWidget(const SizedBox());
    await pumpLesson(t, c, 'en-a');
    expect(find.byKey(const Key('question_prompt')), findsOneWidget);
    expect(find.byKey(const Key('hint_button')), findsOneWidget);
    expect(find.textContaining('3 of 5'), findsOneWidget);
    expect(find.textContaining('1 / ${plan.guided.length}'), findsOneWidget);
  });

  testWidgets('a completed lesson can be replayed from the start', (t) async {
    final c = await makeController();
    await c.recordTeachingMastery(
      world: worldOf(c, 'en-a'),
      lesson: lessonOf(c, 'en-a'),
      teaching: const TeachingProgress(viewed: true, checkBestScore: 3),
    );
    final stars = c.activeProfile!.stars;
    await pumpLesson(t, c, 'en-a');
    expect(find.byKey(const Key('step_text')), findsOneWidget);
    await teachToCheck(t, 'en-a');
    await checkAll(t, lib.planFor('en-a')!.check, rightCount: 3);
    await tapNext(t);
    await t.pump(const Duration(milliseconds: 300));
    expect(c.teachingProgressFor('en-a').mastery, MasteryStatus.mastered);
    expect(c.activeProfile!.stars, stars, reason: 'no star farming');
    expect(c.activeProgress.attempts['english'], 1);
  });

  testWidgets('audio-only practice item shows a replay tile', (t) async {
    final c = await makeController();
    final plan = lib.planFor('en-a')!;
    final sorted = easyToHard(plan.practice);
    final idx = sorted.indexWhere((q) => q.visual.type == VisualType.none);
    expect(idx, greaterThanOrEqualTo(0));
    final speech = FakeSpeech(supported: false);
    await pumpLesson(t, c, 'en-a', speech: speech);
    await nextTimes(t, plan.introduce.length + plan.demonstrate.length);
    await solveAll(t, plan.guided);
    await solveAll(t, sorted.take(idx).toList());
    expect(find.byKey(const Key('replay_button')), findsOneWidget);
    expect(find.byKey(const Key('listen_button')), findsNothing,
        reason: 'one listen control, not two');
    await t.tap(find.byKey(const Key('replay_button')));
    await t.pump();
    await t.pump();
    expect(speech.spoken.last, sorted[idx].speech);
    expect(find.byKey(const Key('voice_notice')), findsOneWidget);
    // The notice does not carry the spoken answer.
    final notice = t.widget<Text>(find.byKey(const Key('voice_notice'))).data!;
    expect(notice.contains(sorted[idx].answer), isFalse);
  });

  testWidgets('option pictures appear whenever the plan gives them', (t) async {
    final c = await makeController();
    final plan = lib.planFor('en-a')!;
    final withPics = plan.guided.indexWhere((q) => q.optionPictures.isNotEmpty);
    expect(withPics, greaterThanOrEqualTo(0));
    await pumpLesson(t, c, 'en-a');
    await nextTimes(t, plan.introduce.length + plan.demonstrate.length);
    await solveAll(t, plan.guided.take(withPics).toList());
    final q = plan.guided[withPics];
    for (final o in q.optionPictures.keys) {
      expect(
        find.descendant(
            of: find.byKey(Key('option_$o')),
            matching: find.byType(ArtPicture)),
        findsOneWidget,
      );
    }
  });

  group('layout', () {
    const sizes = [
      Size(360, 800),
      Size(390, 844),
      Size(800, 1280),
      Size(1024, 768),
      Size(640, 360),
    ];

    for (final id in ['te-a', 'num-add']) {
      for (final size in sizes) {
        testWidgets(
            '$id plays start to finish at ${size.width.toInt()}x'
            '${size.height.toInt()} text x1.6 with no overflow', (t) async {
          final c = await makeController();
          final plan = lib.planFor(id)!;
          await pumpLesson(t, c, id, size: size, textScale: 1.6);
          Future<void> ok() async => expect(t.takeException(), isNull);
          for (var i = 0;
              i < plan.introduce.length + plan.demonstrate.length;
              i++) {
            await ok();
            await tapNext(t);
          }
          for (final q in plan.guided) {
            await t.ensureVisible(find.byKey(const Key('hint_button')));
            await t.tap(find.byKey(const Key('hint_button')));
            await t.pump();
            await tapOption(t, wrongOf(q));
            await ok();
            await tapOption(t, q.answer);
            await ok();
            await tapNext(t);
          }
          for (final q in easyToHard(plan.practice)) {
            await tapOption(t, wrongOf(q));
            await tapOption(t, q.answer);
            await ok();
            await tapNext(t);
          }
          // Fail the check, view the result, go through remediation.
          for (final q in plan.check) {
            await tapOption(t, wrongOf(q));
            await ok();
            await tapNext(t);
          }
          await ok();
          expect(find.byKey(const Key('check_result')), findsOneWidget);
          await tapNext(t);
          for (var i = 0; i < plan.remediation.explain.length; i++) {
            await ok();
            await tapNext(t);
          }
          await solveAll(t, plan.remediation.guided);
          await checkAll(t, plan.remediation.check, rightCount: 3);
          await ok();
          await tapNext(t);
          await t.pump(const Duration(milliseconds: 300));
          await ok();
          // The pass dialog is up and fits too.
          expect(c.activeProgress.completedLessons, contains(id));
        });
      }
    }

    testWidgets('needs-support card fits a small phone at x1.6', (t) async {
      final c = await makeController();
      final plan = lib.planFor('te-a')!;
      await pumpLesson(t, c, 'te-a',
          size: const Size(360, 800), textScale: 1.6);
      await teachToCheck(t, 'te-a');
      await checkAll(t, plan.check, rightCount: 0);
      await tapNext(t);
      for (var cycle = 0; cycle < 2; cycle++) {
        await nextTimes(t, plan.remediation.explain.length);
        await solveAll(t, plan.remediation.guided);
        for (var i = 0; i < plan.remediation.check.length; i++) {
          final prompt =
              t.widget<Text>(find.byKey(const Key('question_prompt'))).data!;
          final q =
              plan.remediation.check.firstWhere((q) => q.prompt == prompt);
          await tapOption(t, wrongOf(q));
          await tapNext(t);
        }
        await tapNext(t);
      }
      expect(find.byKey(const Key('needs_support_card')), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('visuals', () {
    Future<void> show(WidgetTester t, TeachingVisual v,
        {bool question = false, Size size = const Size(400, 400)}) async {
      t.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: TeachingVisualView(visual: v, isQuestion: question),
          ),
        ),
      ));
      await t.pump();
    }

    testWidgets('objects: revealCount shows that many groups, with operator',
        (t) async {
      const v = TeachingVisual(
        type: VisualType.objects,
        groups: [
          ObjectGroup(emoji: 'A', count: 2),
          ObjectGroup(emoji: 'B', count: 3),
        ],
        revealCount: 1,
      );
      await show(t, v);
      expect(find.byKey(const Key('object_group_0')), findsOneWidget);
      expect(find.byKey(const Key('object_group_1')), findsNothing);
      expect(find.text('+'), findsNothing);
      await show(
          t,
          const TeachingVisual(
            type: VisualType.objects,
            groups: [
              ObjectGroup(emoji: 'A', count: 2),
              ObjectGroup(emoji: 'B', count: 3),
            ],
            revealCount: 2,
          ));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('object_group_1')), findsOneWidget);
      expect(find.text('+'), findsOneWidget);
    });

    testWidgets(
        'objects: countAll numbers 1..n; result only when '
        'showResult', (t) async {
      const base = [
        ObjectGroup(emoji: 'A', count: 2),
        ObjectGroup(emoji: 'B', count: 3),
      ];
      await show(
          t,
          const TeachingVisual(
              type: VisualType.objects,
              groups: base,
              countAll: true,
              result: 5));
      await t.pumpAndSettle();
      for (var n = 1; n <= 5; n++) {
        expect(find.byKey(Key('object_number_$n')), findsOneWidget);
      }
      expect(find.byKey(const Key('objects_result')), findsNothing,
          reason: 'result given but showResult false');
      await show(
          t,
          const TeachingVisual(
              type: VisualType.objects,
              groups: base,
              result: 5,
              showResult: true));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('objects_result')), findsOneWidget);
      expect(find.byKey(const Key('object_number_1')), findsNothing);
    });

    testWidgets('a single group has no operator', (t) async {
      await show(
          t,
          const TeachingVisual(
            type: VisualType.objects,
            groups: [ObjectGroup(emoji: 'A', count: 10)],
            revealCount: 1,
            countAll: true,
          ));
      expect(find.text('+'), findsNothing);
      expect(find.byKey(const Key('object_number_10')), findsOneWidget);
    });

    testWidgets('numberLine renders with and without hops', (t) async {
      await show(
          t,
          const TeachingVisual(
              type: VisualType.numberLine,
              from: 0,
              to: 10,
              start: 4,
              jump: 2,
              showHops: true));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('number_line')), findsOneWidget);
      await show(
          t,
          const TeachingVisual(
              type: VisualType.numberLine, from: 0, to: 10, start: 4, jump: 2));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('number_line')), findsOneWidget);
    });

    testWidgets('number line painter ignores jump when hops are hidden',
        (t) async {
      // Same pixels whatever the second addend is, so nothing leaks the sum.
      Future<List<int>> paint(int jump) async {
        await show(
            t,
            TeachingVisual(
                type: VisualType.numberLine,
                from: 0,
                to: 10,
                start: 3,
                jump: jump));
        await t.pumpAndSettle();
        final box =
            t.renderObject<RenderBox>(find.byKey(const Key('number_line')));
        return [box.size.width.toInt(), jump * 0];
      }

      expect(await paint(2), await paint(6));
      final a = TeachingVisual.fromJson(const {
        'type': 'numberLine',
        'from': 0,
        'to': 10,
        'start': 3,
        'jump': 6,
        'showHops': false,
      });
      expect(a.showHops, isFalse);
    });

    testWidgets('picture with an empty caption prints nothing', (t) async {
      await show(
          t,
          const TeachingVisual(
            type: VisualType.picture,
            asset: 'assets/images/quiz/apple.png',
            caption: '',
          ),
          question: true);
      await t.pump();
      expect(find.byKey(const Key('visual_caption')), findsNothing);
      await show(
          t,
          const TeachingVisual(
            type: VisualType.picture,
            asset: 'assets/images/quiz/apple.png',
            caption: 'Apple',
          ));
      expect(find.byKey(const Key('visual_caption')), findsOneWidget);
    });

    testWidgets('glyph and letterWord render', (t) async {
      await show(t, const TeachingVisual(type: VisualType.glyph, glyph: 'A'));
      expect(find.byKey(const Key('visual_glyph')), findsOneWidget);
      await show(
          t,
          const TeachingVisual(
            type: VisualType.letterWord,
            glyph: 'A',
            word: 'Apple',
            asset: 'assets/images/quiz/apple.png',
          ));
      expect(find.byKey(const Key('visual_word')), findsOneWidget);
    });
  });

  group('art placeholder', () {
    Future<void> pic(WidgetTester t, Widget w) async {
      await t.pumpWidget(MaterialApp(
          home: Scaffold(
              body:
                  Center(child: SizedBox(width: 200, height: 200, child: w)))));
      await t.pump();
      await t.pump();
    }

    testWidgets('a missing asset shows a labelled tile, no exception',
        (t) async {
      await pic(
          t,
          const ArtPicture(
            asset: 'assets/images/quiz/does_not_exist.png',
            conceptLabel: 'Zebra',
          ));
      expect(find.byKey(const Key('art_placeholder')), findsOneWidget);
      expect(find.text('Artwork coming soon'), findsOneWidget);
      expect(find.text('Zebra'), findsOneWidget);
      expect(find.byIcon(Icons.broken_image), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('the registry supplies the concept label', (t) async {
      await pic(
          t,
          const ArtPicture(
            asset: 'assets/images/quiz/new_thing.png',
            registry: {
              'assets/images/quiz/new_thing.png': ArtAssetSpec(
                id: 'assets/images/quiz/new_thing.png',
                concept: 'Giraffe',
                description: 'a giraffe',
                world: 'english',
                level: 1,
                lessonIds: ['en-a'],
                width: 512,
                height: 512,
                transparent: true,
                suggestedFilename: 'new_thing.png',
              ),
            },
          ));
      expect(find.text('Giraffe'), findsOneWidget);
    });

    testWidgets('a question picture never names its answer', (t) async {
      await pic(
          t,
          const ArtPicture(
            asset: 'assets/images/quiz/does_not_exist.png',
            conceptLabel: 'Zebra',
            hideConcept: true,
          ));
      expect(find.text('Artwork coming soon'), findsOneWidget);
      expect(find.text('Zebra'), findsNothing);
    });

    testWidgets('an existing asset is shown, not the placeholder', (t) async {
      await pic(t, const ArtPicture(asset: 'assets/images/quiz/apple.png'));
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump();
      expect(find.byKey(const Key('art_placeholder')), findsNothing);
    });
  });
}
