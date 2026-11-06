import 'package:aksharamala/src/exam/exam_controller.dart';
import 'package:aksharamala/src/exam/exam_store.dart';
import 'package:aksharamala/src/exam/models.dart';
import 'package:aksharamala/src/screens/exam/examination_centre.dart';
import 'package:aksharamala/src/screens/exam/results_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_helpers.dart';

void main() {
  late MemoryExamStore store;
  late ExamController exams;
  late TestClock clock;

  setUp(() {
    store = MemoryExamStore();
    clock = TestClock();
    exams = examController(store, uiBank(parentMarked: true), clock: clock);
  });

  Future<ExamAttempt> take({
    required int right,
    int count = 5,
    ExamType type = ExamType.subject,
    bool parent = false,
  }) async {
    final out = await real(() => exams.startExam(cfg(
          count: count,
          worlds: ['english'],
          type: type,
          parent: parent,
        )));
    final a = (out as StartExamStarted).attempt;
    await real(() => answerAll(exams, a, right: right));
    await real(() => exams.submit(a.id));
    clock.advance(const Duration(hours: 1));
    return exams.attemptById(a.id)!;
  }

  Future<void> openCentre(WidgetTester tester,
          {Size size = const Size(800, 1280)}) =>
      pumpApp(tester,
          exams: exams,
          size: size,
          home: const ExaminationCentre(initialChildId: 'kid'));

  testWidgets('empty states say there is nothing yet', (tester) async {
    await openCentre(tester);
    await openTab(tester, 'tab_results');
    expect(find.byKey(const Key('no_results')), findsOneWidget);
    await openTab(tester, 'tab_history');
    expect(find.byKey(const Key('no_history')), findsOneWidget);
    await openTab(tester, 'tab_certificates');
    expect(find.byKey(const Key('no_certificates')), findsOneWidget);
  });

  testWidgets(
      'result screen shows score, breakdown, wrong answers and recommendations',
      (tester) async {
    final a = await take(right: 3);
    await openCentre(tester);
    await openTab(tester, 'tab_results');

    expect(find.text('3 of 5 marks'), findsOneWidget);
    expect(find.textContaining('60%'), findsWidgets);
    expect(find.text('Passed'), findsOneWidget);
    expect(find.byKey(const Key('tamper_warning')), findsNothing);
    expect(find.byKey(const Key('subject_english')), findsOneWidget);
    expect(find.textContaining('English'), findsWidgets);

    // Recommendations come from the missed questions' lessons.
    final r = exams.resultFor(a.id)!;
    expect(r.wrong, hasLength(2));
    expect(r.recommendations, isNotEmpty);
    for (final rec in r.recommendations) {
      await tester
          .ensureVisible(find.byKey(Key('recommendation_${rec.lessonId}')));
      expect(find.text(recommendationText(rec)), findsOneWidget);
      expect(find.textContaining('(${rec.lessonId})'), findsNothing);
    }
    // Wrong answers open to show the correct answer.
    final wrong = find.byKey(Key('wrong_${r.wrong.first.questionId}'));
    await tester.ensureVisible(wrong);
    await tester.tap(wrong);
    await settle(tester);
    expect(find.text('Correct answer: A'), findsWidgets);
    expect(find.textContaining('Revise:'), findsWidgets);
    expect(find.byKey(const Key('readiness')), findsOneWidget);
  });

  testWidgets('failed exam shows Not passed yet', (tester) async {
    await take(right: 1);
    await openCentre(tester);
    await openTab(tester, 'tab_results');
    expect(find.text('Not passed yet'), findsOneWidget);
  });

  testWidgets(
      'parent marking: awaiting state, then marks recalculate the result',
      (tester) async {
    final a = await take(right: 4, count: 19, parent: true);
    final result = exams.resultFor(a.id)!;
    expect(result.isProvisional, isTrue);
    final q = a.questions.firstWhere((q) => q.isParentMarked);

    await openCentre(tester);
    await openTab(tester, 'tab_results');
    expect(find.text('Awaiting parent marking'), findsOneWidget);
    expect(find.byKey(const Key('awaiting_note')), findsOneWidget);
    expect(find.byKey(const Key('parent_marking')), findsOneWidget);
    expect(find.text('Not marked yet'), findsOneWidget);

    await tapKey(tester, 'mark_correct_${q.id}');
    expect(find.text('Awaiting parent marking'), findsNothing);
    expect(find.byKey(const Key('awaiting_note')), findsNothing);
    expect(find.text('Marked correct'), findsOneWidget);
    expect(exams.resultFor(a.id)!.isProvisional, isFalse);

    await tapKey(tester, 'mark_incorrect_${q.id}');
    expect(find.text('Marked incorrect'), findsOneWidget);
    expect(exams.attemptById(a.id)!.parentMarks[q.id], isFalse);
  });

  testWidgets('a result that fails verification shows the tamper warning',
      (tester) async {
    final a = await take(right: 3);
    // Hand-edit the stored file, then reopen from it.
    final json = store.disk.toJson();
    final results = (json['results'] as List).cast<Map<String, Object?>>();
    results.first['obtainedMarks'] = 5;
    results.first['percent'] = 100.0;
    store.disk = ExamData.fromJson(Map<String, dynamic>.from(json));
    exams = examController(store, uiBank(parentMarked: true), clock: clock);
    await real(() => exams.load());
    expect(exams.verifyResult(a.id), isFalse);

    await openCentre(tester);
    await openTab(tester, 'tab_results');
    expect(find.byKey(const Key('tamper_warning')), findsOneWidget);
    expect(find.textContaining('Result could not be verified'), findsOneWidget);
  });

  testWidgets('history is newest first and opens a result', (tester) async {
    final first = await take(right: 5);
    final second = await take(right: 2);
    final third = await take(right: 4);
    await openCentre(tester);
    await openTab(tester, 'tab_history');

    final ys = [
      for (final a in [third, second, first])
        tester.getTopLeft(find.byKey(Key('history_${a.id}'))).dy,
    ];
    expect(ys[0], lessThan(ys[1]));
    expect(ys[1], lessThan(ys[2]));
    expect(find.textContaining('Attempt 3'), findsOneWidget);
    expect(find.textContaining('Attempt 1'), findsOneWidget);

    await tester.tap(find.byKey(Key('history_${second.id}')));
    await settle(tester);
    expect(find.text('Exam result'), findsOneWidget);
    expect(find.text('2 of 5 marks'), findsOneWidget);
  });

  testWidgets('history lists discarded and unfinished attempts too',
      (tester) async {
    final out =
        await real(() => exams.startExam(cfg(count: 3, worlds: ['english'])));
    final a = (out as StartExamStarted).attempt;
    await real(() => exams.abandon(a.id));
    clock.advance(const Duration(hours: 1));
    await real(() => exams.startExam(cfg(count: 3, worlds: ['english'])));
    await openCentre(tester);
    await openTab(tester, 'tab_history');
    expect(find.textContaining('Discarded'), findsOneWidget);
    expect(find.textContaining('Unfinished'), findsOneWidget);
  });

  group('certificates', () {
    Future<void> passFinal() => take(right: 5, type: ExamType.finalLevel);

    testWidgets('a passed final exam gives one certificate card',
        (tester) async {
      await passFinal();
      await openCentre(tester);
      await openTab(tester, 'tab_certificates');
      expect(find.byKey(const Key('certificate_1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('certificate_1')));
      await settle(tester);
      expect(find.byKey(const Key('certificate_card')), findsOneWidget);
      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('completed Level 1 in Aksharamala.'), findsOneWidget);
      final cert = exams.certificateFor('kid', 1)!;
      expect(find.text('Certificate number: ${cert.id}'), findsOneWidget);
      expect(find.textContaining('Date: '), findsOneWidget);
      expect(find.textContaining('not an accredited qualification'),
          findsOneWidget);
      expect(find.textContaining('accredited by'), findsNothing);
    });

    testWidgets('a second pass of the same level does not add a certificate',
        (tester) async {
      await passFinal();
      await passFinal();
      expect(exams.certificatesFor('kid'), hasLength(1));
      await openCentre(tester);
      await openTab(tester, 'tab_certificates');
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('reissue asks first, then counts; cancel changes nothing',
        (tester) async {
      await passFinal();
      await openCentre(tester);
      await openTab(tester, 'tab_certificates');
      await tester.tap(find.byKey(const Key('certificate_1')));
      await settle(tester);

      await tapKey(tester, 'reissue_certificate');
      expect(find.text('Reissue this certificate?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(exams.certificateFor('kid', 1)!.issuedCount, 1);
      expect(find.byKey(const Key('certificate_reissued')), findsNothing);

      await tapKey(tester, 'reissue_certificate');
      await tapKey(tester, 'confirm_reissue');
      expect(exams.certificateFor('kid', 1)!.issuedCount, 2);
      expect(find.text('Reissued 1 time(s)'), findsOneWidget);
      expect(exams.certificatesFor('kid'), hasLength(1));
    });

    testWidgets('a failed final exam gives none', (tester) async {
      await take(right: 1, type: ExamType.finalLevel);
      expect(exams.certificatesFor('kid'), isEmpty);
    });
  });

  group('question bank and settings', () {
    testWidgets('coverage per level, Level 5 empty, flags counted',
        (tester) async {
      final flagged = ExamQuestion(
        id: 'F0#q0',
        lessonId: 'F0',
        lessonTitle: 'Flagged',
        level: 2,
        world: 'telugu',
        topic: 't',
        objective: 'o',
        type: ExamQuestionType.multipleChoice,
        prompt: 'p',
        speech: 'say it',
        options: const ['A', 'B'],
        correctAnswer: 'A',
        verification: const {
          Verification.machineChecked,
          Verification.educatorPending,
          Verification.ttsUnverified,
        },
      );
      exams = examController(store, [...uiBank(), flagged], clock: clock);
      await openCentre(tester);
      await openTab(tester, 'tab_settings');

      expect(
          find.text('19 auto-marked questions in all. Educator-verified: 0.'),
          findsOneWidget);
      expect(find.text('Waiting for an educator to check the language: 1.'),
          findsOneWidget);
      expect(find.text('Spoken by the phone voice, not yet checked: 1.'),
          findsOneWidget);

      expect(find.text('Level 1: 18 questions'), findsOneWidget);
      expect(find.text('Level 2: 1 questions'), findsOneWidget);
      // The cards are built lazily: scroll down to the last level.
      await tester.drag(find.byType(ListView).last, const Offset(0, -3000));
      await settle(tester);
      expect(find.text('Level 8: 0 questions'), findsOneWidget);
      await tester.tap(find.byKey(const Key('coverage_level_8')));
      await settle(tester);
      expect(find.byKey(const Key('coverage_empty_8')), findsOneWidget);
      expect(find.text('No questions yet - Level 8 lessons are coming.'),
          findsWidgets);

      await tester.ensureVisible(find.byKey(const Key('coverage_level_1')));
      await tester.tap(find.byKey(const Key('coverage_level_1')));
      await settle(tester);
      expect(find.textContaining('English Forest: 18 questions from 6 of'),
          findsOneWidget);
    });

    testWidgets('default pass mark is saved for the child', (tester) async {
      await openCentre(tester);
      await openTab(tester, 'tab_settings');
      await tapKey(tester, 'default_pass_plus');
      await tapKey(tester, 'default_pass_plus');
      expect(exams.passPercentFor('kid'), 70);
      expect(store.disk.settings['kid']!.defaultPassPercent, 70);
      // The Conduct tab starts from it.
      await openTab(tester, 'tab_conduct');
      expect(
          tester.widget<Text>(find.byKey(const Key('pass_value'))).data, '70%');
    });

    testWidgets('PIN: set, change, clear', (tester) async {
      await openCentre(tester);
      await openTab(tester, 'tab_settings');
      expect(find.text('No exam PIN is set.'), findsOneWidget);

      // Not four digits.
      await tapKey(tester, 'pin_set');
      await tester.enterText(find.byKey(const Key('pin_new')), '12');
      await tapKey(tester, 'pin_ok');
      expect(find.byKey(const Key('pin_error')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('pin_new')), '1234');
      await tapKey(tester, 'pin_ok');
      expect(exams.hasPin('kid'), isTrue);
      expect(find.text('An exam PIN is set.'), findsOneWidget);
      // Only a salted hash is stored.
      expect(store.disk.toJson().toString(), isNot(contains('1234')));

      // Change needs the current PIN.
      await tapKey(tester, 'pin_change');
      await tester.enterText(find.byKey(const Key('pin_current')), '9999');
      await tester.enterText(find.byKey(const Key('pin_new')), '5678');
      await tapKey(tester, 'pin_ok');
      expect(find.byKey(const Key('pin_error')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('pin_current')), '1234');
      await tapKey(tester, 'pin_ok');
      expect(exams.verifyPin('kid', '5678'), isTrue);

      // Clear needs the current PIN.
      await tapKey(tester, 'pin_clear');
      await tester.enterText(find.byKey(const Key('pin_current')), '1234');
      await tapKey(tester, 'pin_ok');
      expect(exams.hasPin('kid'), isTrue);
      await tester.enterText(find.byKey(const Key('pin_current')), '5678');
      await tapKey(tester, 'pin_ok');
      expect(exams.hasPin('kid'), isFalse);
      expect(find.text('No exam PIN is set.'), findsOneWidget);
    });
  });
}
