import 'package:aksharamala/src/exam/exam_controller.dart';
import 'package:aksharamala/src/exam/models.dart';
import 'package:aksharamala/src/screens/exam/child_exam_screen.dart';
import 'package:aksharamala/src/screens/exam/examination_centre.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_helpers.dart';

const _sizes = <Size>[
  Size(360, 800),
  Size(390, 844),
  Size(800, 1280),
  Size(1024, 768),
];

/// A long Telugu string (built from code points so this file stays ASCII).
final String _telugu = String.fromCharCodes([
  0x0C05,
  0x0C2E,
  0x0C4D,
  0x0C2E,
  0x0C3E,
  0x0C2F,
  0x0C3F,
  0x0C15,
  0x0C3F,
  0x0C32,
  0x0C4D,
  0x0C32,
  0x0C3E,
  0x0C32,
  0x0C41,
]);

void main() {
  for (final size in _sizes) {
    for (final scale in [1.0, 1.6]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()} text $scale';

      testWidgets('Examination Centre has no overflow at $tag', (tester) async {
        final store = MemoryExamStore();
        final clock = TestClock();
        final bank = [
          ...uiBank(parentMarked: true),
          richQuestion(id: 'T0#q0', prompt: _telugu),
        ];
        final exams = examController(store, bank, clock: clock);
        // Data for every tab: a failed attempt, a passed final, an unfinished one.
        final r1 = await real(
            () => exams.startExam(cfg(count: 6, worlds: ['english'])));
        await real(
            () => answerAll(exams, (r1 as StartExamStarted).attempt, right: 2));
        await real(() => exams.submit((r1 as StartExamStarted).attempt.id));
        clock.advance(const Duration(hours: 1));
        final r2 = await real(() => exams.startExam(
            cfg(count: 6, worlds: ['english'], type: ExamType.finalLevel)));
        await real(
            () => answerAll(exams, (r2 as StartExamStarted).attempt, right: 5));
        await real(() => exams.submit((r2 as StartExamStarted).attempt.id));
        clock.advance(const Duration(hours: 1));
        await real(() => exams.startExam(cfg(count: 3, worlds: ['english'])));

        await pumpApp(tester,
            exams: exams,
            size: size,
            scale: scale,
            home: const ExaminationCentre(initialChildId: 'kid'));
        expectNoOverflow(tester);

        // Conduct tab with every option switched on.
        await tapKey(tester, 'world_english');
        await tapKey(tester, 'timed');
        await tapKey(tester, 'retest_maxAttempts');
        await tapKey(tester, 'type_finalLevel');
        await tapKey(tester, 'per_world');
        await tapKey(tester, 'type_chapter');
        await tapKey(tester, 'lesson_L0');
        await tapKey(tester, 'level_5');
        await tapKey(tester, 'level_1');
        expectNoOverflow(tester);
        await reveal(tester, 'start_exam');
        final start = tester.getRect(find.byKey(const Key('start_exam')));
        expect(start.height, greaterThanOrEqualTo(48));
        expect(start.right, lessThanOrEqualTo(size.width));
        expect(start.left, greaterThanOrEqualTo(0));

        for (final tab in [
          'tab_results',
          'tab_history',
          'tab_certificates',
          'tab_settings'
        ]) {
          await openTab(tester, tab);
          expectNoOverflow(tester);
        }
        // Open every coverage level and a wrong answer on the results tab.
        for (var l = 1; l <= 5; l++) {
          await tapKey(tester, 'coverage_level_$l');
        }
        expectNoOverflow(tester);
        await tapKey(tester, 'pin_set');
        expectNoOverflow(tester);
        await tapKey(tester, 'pin_cancel');

        await openTab(tester, 'tab_results');
        final wrongId = exams.resultsFor('kid').first.wrong.first.questionId;
        await tapKey(tester, 'wrong_$wrongId');
        expectNoOverflow(tester);

        await openTab(tester, 'tab_certificates');
        await tester.tap(find.byKey(const Key('certificate_1')));
        await settle(tester);
        expectNoOverflow(tester);
        expect(find.byKey(const Key('certificate_card')), findsOneWidget);
      });

      testWidgets('child exam screens have no overflow at $tag',
          (tester) async {
        final store = MemoryExamStore();
        final bank = [
          richQuestion(id: 'R0#q0', speech: 'Cat'),
          richQuestion(id: 'R0#q1', prompt: _telugu),
          richQuestion(
              id: 'R0#q2',
              prompt:
                  'A very long question that goes on and on so that it has to '
                  'wrap onto many lines at a large text size, which is exactly '
                  'what a real story question can do to the screen. '
                  'Which animal says meow?',
              speech: 'Meow'),
          ...makeBank(world: 'english', lessons: 2, perLesson: 2),
        ];
        final exams = examController(store, bank);
        final out = await real(() =>
            exams.startExam(cfg(count: 7, worlds: ['english'], limit: 600)));
        final a = (out as StartExamStarted).attempt;

        await pumpApp(tester,
            exams: exams,
            size: size,
            scale: scale,
            home: ChildExamScreen(attemptId: a.id, speech: FakeSpeech()));
        expectNoOverflow(tester);

        for (var i = 0; i < a.questions.length; i++) {
          await tapKey(tester, 'option_0');
          expectNoOverflow(tester);
          final opt = tester.getRect(find.byKey(const Key('option_0')));
          expect(opt.height, greaterThanOrEqualTo(48));
          final next = find.byKey(
              Key(i == a.questions.length - 1 ? 'go_review' : 'next_question'));
          expect(tester.getRect(next).height, greaterThanOrEqualTo(48));
          expect(tester.getRect(next).bottom, lessThanOrEqualTo(size.height));
          await tester.tap(next);
          await settle(tester);
        }
        expectNoOverflow(tester);
        expect(find.byKey(const Key('review_list')), findsOneWidget);
        await tapKey(tester, 'submit_exam');
        expectNoOverflow(tester);
        await tapKey(tester, 'confirm_submit');
        expectNoOverflow(tester);
        expect(find.byKey(const Key('hand_back')), findsOneWidget);
        final back = tester.getRect(find.byKey(const Key('hand_back')));
        expect(back.height, greaterThanOrEqualTo(48));
      });
    }
  }
}
