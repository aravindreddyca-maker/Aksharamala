import 'package:aksharamala/src/exam/exam_controller.dart';
import 'package:aksharamala/src/exam/models.dart';
import 'package:aksharamala/src/screens/exam/child_exam_screen.dart';
import 'package:aksharamala/src/screens/exam/examination_centre.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_helpers.dart';

void main() {
  late MemoryExamStore store;
  late ExamController exams;

  setUp(() {
    store = MemoryExamStore();
    exams = examController(store, uiBank());
  });

  Future<void> openCentre(WidgetTester tester) => pumpApp(
        tester,
        exams: exams,
        home: const ExaminationCentre(initialChildId: 'kid'),
      );

  testWidgets('shows honest availability and starts a subject exam',
      (tester) async {
    await openCentre(tester);
    // Nothing chosen yet.
    expect(find.text('Choose a subject.'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('start_exam')))
            .onPressed,
        isNull);

    await tapKey(tester, 'world_english');
    expect(find.text('This level has 18 questions for this subject.'),
        findsOneWidget);

    // Five questions.
    for (var i = 0; i < 5; i++) {
      await tapKey(tester, 'count_minus');
    }
    expect(find.text('5'), findsWidgets);
    await tapKey(tester, 'start_exam');

    expect(find.byType(ChildExamScreen), findsOneWidget);
    expect(find.text('Question 1 of 5'), findsOneWidget);
    final attempt = exams.inProgressFor('kid')!;
    expect(attempt.questions, hasLength(5));
    expect(attempt.config.type, ExamType.subject);
    expect(attempt.config.level, 1);
    expect(attempt.config.passPercent, 60);
    expect(attempt.config.timeLimitSeconds, isNull);
  });

  testWidgets('rules chosen on screen reach the exam config', (tester) async {
    await openCentre(tester);
    await tapKey(tester, 'world_english');
    for (var i = 0; i < 5; i++) {
      await tapKey(tester, 'count_minus');
    }
    await tapKey(tester, 'pass_plus');
    await tapKey(tester, 'timed');
    await tapKey(tester, 'minutes_plus');
    await tapKey(tester, 'retest_maxAttempts');
    await tapKey(tester, 'mix_1');
    await tapKey(tester, 'start_exam');

    final c = exams.inProgressFor('kid')!.config;
    expect(c.passPercent, 65);
    expect(c.timeLimitSeconds, 25 * 60);
    expect(c.retestPolicy, const RetestPolicy.maxAttempts(3));
    expect(c.difficultyMix.easy, 70);
  });

  testWidgets('refuses with the controller message when too few, offers N',
      (tester) async {
    await openCentre(tester);
    await tapKey(tester, 'world_english');
    // Default is 10; ask for 30.
    for (var i = 0; i < 20; i++) {
      await tapKey(tester, 'count_plus');
    }
    await settle(tester);
    await tapKey(tester, 'start_exam');

    expect(find.byType(ChildExamScreen), findsNothing);
    expect(exams.data.attempts, isEmpty);
    final msg = tester.widget<Text>(find.descendant(
        of: find.byKey(const Key('start_message')),
        matching: find.byType(Text)));
    expect(msg.data, contains('18'));
    expect(find.byKey(const Key('use_available')), findsOneWidget);
    expect(find.text('Use 18 questions instead'), findsOneWidget);

    await tapKey(tester, 'use_available');
    expect(find.text('Question 1 of 18'), findsOneWidget);
  });

  testWidgets('Level 8 says its lessons are coming and cannot start',
      (tester) async {
    await openCentre(tester);
    await tapKey(tester, 'world_english');
    await tapKey(tester, 'level_8');
    expect(find.text('No questions yet - Level 8 lessons are coming.'),
        findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('start_exam')))
            .onPressed,
        isNull);
  });

  testWidgets('chapter test lets the parent pick lessons', (tester) async {
    await openCentre(tester);
    await tapKey(tester, 'type_chapter');
    expect(find.text('Choose at least one lesson.'), findsOneWidget);
    await tapKey(tester, 'lesson_L0');
    await tapKey(tester, 'lesson_L1');
    expect(find.text('The chosen lessons have 6 questions.'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tapKey(tester, 'count_minus');
    }
    await tapKey(tester, 'start_exam');
    final a = exams.inProgressFor('kid')!;
    expect(a.config.type, ExamType.chapter);
    expect(a.config.lessonIds, ['L0', 'L1']);
    expect(a.questions.every((q) => q.lessonId == 'L0' || q.lessonId == 'L1'),
        isTrue);
  });

  testWidgets('final level exam covers chosen worlds', (tester) async {
    await openCentre(tester);
    await tapKey(tester, 'type_finalLevel');
    expect(find.text('This level has 18 questions for the chosen subjects.'),
        findsOneWidget);
    await tapKey(tester, 'per_world');
    for (var i = 0; i < 5; i++) {
      await tapKey(tester, 'count_minus');
    }
    await tapKey(tester, 'start_exam');
    final c = exams.inProgressFor('kid')!.config;
    expect(c.type, ExamType.finalLevel);
    expect(c.perWorldMinPercent, 60);
  });

  testWidgets('unfinished attempt offers Resume or Discard', (tester) async {
    final started =
        await real(() => exams.startExam(cfg(count: 4, worlds: ['english'])));
    expect(started, isA<StartExamStarted>());
    await openCentre(tester);
    expect(find.byKey(const Key('unfinished_card')), findsOneWidget);
    expect(find.text('Unfinished exam'), findsOneWidget);

    // A second start is refused while one is open.
    await tapKey(tester, 'world_english');
    await tapKey(tester, 'start_exam');
    expect(find.textContaining('unfinished exam'), findsWidgets);
    expect(exams.data.attempts, hasLength(1));

    // Discard asks first.
    await tapKey(tester, 'discard_exam');
    expect(find.text('Discard this exam?'), findsOneWidget);
    await tapKey(tester, 'confirm_discard');
    expect(exams.inProgressFor('kid'), isNull);
    expect(find.byKey(const Key('unfinished_card')), findsNothing);
    expect(exams.data.attempts.single.status, AttemptStatus.abandoned);
    expect(exams.data.results, isEmpty);
  });

  testWidgets('Resume reopens the child exam', (tester) async {
    await real(() => exams.startExam(cfg(count: 4, worlds: ['english'])));
    await openCentre(tester);
    await tapKey(tester, 'resume_exam');
    expect(find.byType(ChildExamScreen), findsOneWidget);
    expect(find.text('Question 1 of 4'), findsOneWidget);
  });

  testWidgets('retest policy refusal is shown', (tester) async {
    final a = (await real(() => exams.startExam(cfg(
        count: 3,
        worlds: ['english'],
        policy: const RetestPolicy.maxAttempts(1))))) as StartExamStarted;
    await real(() => exams.submit(a.attempt.id));
    await openCentre(tester);
    await tapKey(tester, 'world_english');
    for (var i = 0; i < 7; i++) {
      await tapKey(tester, 'count_minus');
    }
    await tapKey(tester, 'retest_maxAttempts');
    await tapKey(tester, 'retest_value_minus');
    await tapKey(tester, 'retest_value_minus');
    await tapKey(tester, 'start_exam');
    expect(find.textContaining('at most 1'), findsOneWidget);
    expect(exams.inProgressFor('kid'), isNull);
  });
}
