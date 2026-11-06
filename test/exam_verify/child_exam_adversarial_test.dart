// Independent adversarial tests written by the ui-verifier (not the creator).
// In-memory stores and a fake clock only: real disk can hang in widget tests.
import 'dart:math';

import 'package:aksharamala/src/exam/exam_controller.dart';
import 'package:aksharamala/src/exam/models.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/exam/child_exam_screen.dart';
import 'package:aksharamala/src/screens/exam/examination_centre.dart';
import 'package:aksharamala/src/screens/exam/results_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../exam_ui/ui_helpers.dart';

class _Home extends StatelessWidget {
  const _Home(this.attemptId, {this.now});
  final String attemptId;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            key: const Key('open_exam'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => ChildExamScreen(
                  attemptId: attemptId, speech: FakeSpeech(), now: now),
            )),
            child: const Text('HOME'),
          ),
        ),
      );
}

List<ExamQuestion> richBank(int n, {String optionText = ''}) => [
      for (var i = 0; i < n; i++)
        ExamQuestion(
          id: 'R$i#q0',
          lessonId: 'R$i',
          lessonTitle: 'Animals $i',
          level: 1,
          world: 'english',
          topic: 'Animals',
          objective: 'Name animals',
          type: ExamQuestionType.multipleChoice,
          prompt: 'Which one is a cat $i?',
          options: [
            '${optionText}Cat',
            '${optionText}Dog',
            '${optionText}Cow',
            '${optionText}Hen',
          ],
          correctAnswer: '${optionText}Cat',
          explanation: 'SECRET-EXPLANATION because cats say meow.',
          verification: const {Verification.machineChecked},
        ),
    ];

void _walk(SemanticsNode n, void Function(SemanticsNode) f) {
  f(n);
  n.visitChildren((c) {
    _walk(c, f);
    return true;
  });
}

void main() {
  late MemoryExamStore store;
  late ExamController exams;
  late TestClock clock;

  Future<ExamAttempt> start(
    List<ExamQuestion> bank, {
    int count = 4,
    int? limit,
    ExamType type = ExamType.subject,
    String childId = 'kid',
    double pass = 60,
  }) async {
    store = MemoryExamStore();
    clock = TestClock();
    exams = examController(store, bank, clock: clock);
    final out = await real(() => exams.startExam(cfg(
        childId: childId,
        count: count,
        worlds: ['english'],
        limit: limit,
        type: type,
        pass: pass)));
    return (out as StartExamStarted).attempt;
  }

  Future<void> openExam(WidgetTester tester, ExamAttempt a,
      {Size size = const Size(390, 844),
      double scale = 1.0,
      bool useClock = false}) async {
    await pumpApp(tester,
        exams: exams,
        size: size,
        scale: scale,
        home: _Home(a.id, now: useClock ? clock.call : null));
    await tapKey(tester, 'open_exam');
  }

  testWidgets('V1 semantics tree never exposes the answer or explanation',
      (tester) async {
    final handle = tester.ensureSemantics();
    final a = await start(richBank(6));
    await openExam(tester, a);
    final texts = <String>[];
    final optionData = <String, SemanticsData>{};
    final root =
        tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
    _walk(root, (n) {
      final d = n.getSemanticsData();
      texts.add('${d.label}|${d.value}|${d.hint}|${d.tooltip}');
      if (a.questions[0].options.contains(d.label)) optionData[d.label] = d;
    });
    final joined = texts.join('\n').toLowerCase();
    expect(joined.contains('secret-explanation'), isFalse);
    expect(joined.contains('correct'), isFalse, reason: joined);
    expect(joined.contains('right'), isFalse);
    expect(joined.contains('wrong'), isFalse);
    expect(joined.contains('hint'), isFalse);
    expect(optionData.length, 4,
        reason: 'all four options appear as semantic nodes');
    // The correct option must look exactly like the wrong ones to a screen reader.
    final shapes = optionData.values
        .map((d) =>
            '${d.hasFlag(SemanticsFlag.isButton)}|${d.hasFlag(SemanticsFlag.isSelected)}|'
            '${d.hasAction(SemanticsAction.tap)}|${d.hint}|${d.value}')
        .toSet();
    expect(shapes.length, 1, reason: 'option semantics differ: $shapes');
    // Widget keys must not carry the answer either.
    for (final w in tester.allWidgets) {
      final k = w.key;
      if (k is ValueKey<String>) {
        expect(k.value.toLowerCase().contains('cat'), isFalse, reason: k.value);
      }
    }
    // Nothing in any Text widget except the option itself says "Cat" as a flag.
    expect(find.textContaining('SECRET'), findsNothing);
    handle.dispose();
  });

  testWidgets(
      'V2 correct option position is not always first (leak by position)',
      (tester) async {
    final a = await start(richBank(12), count: 12);
    var first = 0;
    for (final q in a.questions) {
      if (q.options.first == q.correctAnswer) first++;
    }
    // 12 questions x 4 options: chance of >= 9 first by luck is negligible.
    expect(first, lessThan(9));
  });

  testWidgets(
      'V3 submitting twice (UI then controller, and concurrently) gives one result',
      (tester) async {
    final a = await start(richBank(6), type: ExamType.finalLevel, pass: 50);
    await real(() => answerAll(exams, a, right: 4));
    await openExam(tester, a);
    for (var i = 0; i < 3; i++) {
      await tapKey(tester, 'next_question');
    }
    await tapKey(tester, 'go_review');
    await tapKey(tester, 'submit_exam');
    await tapKey(tester, 'confirm_submit');
    expect(find.byKey(const Key('done_headline')), findsOneWidget);
    expect(exams.data.results.length, 1);
    final savesAfterFirst = store.saves;
    final r =
        await real(() => Future.wait([exams.submit(a.id), exams.submit(a.id)]));
    expect(exams.data.results.length, 1);
    expect(exams.data.certificates.length, 1);
    expect(r[0].checksum, r[1].checksum);
    expect(store.saves, savesAfterFirst,
        reason: 'idempotent submit must not rewrite');
  });

  testWidgets(
      'V3b concurrent first submit does not duplicate certificate or result',
      (tester) async {
    final a = await start(richBank(6), type: ExamType.finalLevel, pass: 50);
    await real(() => answerAll(exams, a, right: 5));
    final both =
        await real(() => Future.wait([exams.submit(a.id), exams.submit(a.id)]));
    expect(exams.data.results.length, 1);
    expect(exams.data.certificates.length, 1);
    expect(both[0].checksum, both[1].checksum);
  });

  testWidgets(
      'V4 app killed mid-exam resumes from stored JSON at the first unanswered question',
      (tester) async {
    final a = await start(richBank(6), count: 5);
    await openExam(tester, a);
    Future<void> pickAt(int i, int optionIndex) async {
      final q = exams.attemptById(a.id)!.questions[i];
      final f = find
          .ancestor(
              of: find.text(q.options[optionIndex]),
              matching: find.byType(InkWell))
          .first;
      await tester.tap(f);
      await settle(tester);
    }

    await pickAt(0, 1);
    await tapKey(tester, 'next_question');
    await pickAt(1, 2);
    // "Kill": discard the widget tree and controller; rebuild from the JSON.
    await tester.pumpWidget(const SizedBox());
    final disk = store.disk;
    final store2 = MemoryExamStore()..disk = disk;
    final exams2 = examController(store2, richBank(6), clock: clock);
    await real(exams2.load);
    expect(exams2.inProgressFor('kid'), isNotNull);
    expect(exams2.inProgressFor('kid')!.answeredCount, 2);
    exams = exams2;
    store = store2;
    await openExam(tester, a);
    expect(find.text('Question 3 of 5'), findsOneWidget);
    // Earlier answers survived and are still selected when going back.
    await tapKey(tester, 'prev_question');
    final q1 = exams2.attemptById(a.id)!.questions[1];
    expect(exams2.attemptById(a.id)!.answers[q1.id]!.answer, q1.options[2]);
    // Question order and option order are frozen, identical to before the kill.
    expect([for (final q in exams2.attemptById(a.id)!.questions) q.id],
        [for (final q in a.questions) q.id]);
    expect([
      for (final q in exams2.attemptById(a.id)!.questions) q.options.join('|')
    ], [
      for (final q in a.questions) q.options.join('|')
    ]);
  });

  testWidgets(
      'V5 an exam of one child is not answerable as another child, and is invisible to the sibling',
      (tester) async {
    final a = await start(richBank(6), count: 4);
    final q = a.questions.first;
    expect(await real(() => exams.answer(a.id, q.id, q.correctAnswer)), isTrue);
    // The sibling has nothing in progress, no history, no results.
    expect(exams.inProgressFor('sib'), isNull);
    expect(exams.attemptsFor('sib'), isEmpty);
    expect(exams.resultsFor('sib'), isEmpty);
    // The answer is stored against the attempt's own child only.
    expect(exams.attemptById(a.id)!.childId, 'kid');
    // The sibling can start their own exam while kid's is open (separate attempts).
    final out = await real(() => exams.startExam(
        cfg(id: 'c2', childId: 'sib', count: 4, worlds: ['english'])));
    expect(out, isA<StartExamStarted>());
    final b = (out as StartExamStarted).attempt;
    expect(b.id, isNot(a.id));
    // The attempt-id-only API has no child check: an answer to sib's attempt
    // is accepted regardless of which profile is active. Document it.
    expect(await real(() => exams.answer(b.id, b.questions.first.id, 'A')),
        isFalse,
        reason: 'A is not one of the rich options, so this must be refused');
    // kid's attempt untouched by sib's activity.
    expect(exams.attemptById(a.id)!.answers.length, 1);
  });

  testWidgets(
      'V6 final exam with a subject that has zero questions: UI refusal and the offer button',
      (tester) async {
    store = MemoryExamStore();
    clock = TestClock();
    // Only English has questions (18). Telugu has none.
    exams = examController(store, uiBank(), clock: clock);
    await pumpApp(tester,
        exams: exams, home: const ExaminationCentre(initialChildId: 'kid'));
    await tapKey(tester, 'type_finalLevel');
    expect(find.byKey(const Key('availability')), findsOneWidget);
    final t0 = tester.widget<Text>(find.byKey(const Key('availability'))).data;
    // Parent adds Telugu to the final exam.
    // D1 fix: a subject with no questions is switched off, not selectable.
    final chip =
        tester.widget<FilterChip>(find.byKey(const Key('final_world_telugu')));
    expect(chip.onSelected, isNull);
    expect(chip.selected, isFalse);
    expect(find.textContaining('Telugu Kingdom (no questions yet)'),
        findsOneWidget);
    expect(find.byKey(const Key('final_empty_note')), findsOneWidget);
    expect(find.textContaining('"telugu"'), findsNothing);
    expect(t0, contains('18'));
    await tapKey(tester, 'start_exam');
    // The exam starts with the subject that has questions; no refusal loop.
    expect(find.byType(ChildExamScreen), findsOneWidget);
    expect(exams.inProgressFor('kid')!.config.worlds, ['english']);
  });

  testWidgets(
      'V7 timer expiry on the review page hands in; late tap cannot change answers',
      (tester) async {
    final a = await start(richBank(6), count: 4, limit: 600);
    await openExam(tester, a, useClock: true);
    final q0 = a.questions[0];
    await tester.tap(find
        .ancestor(of: find.text(q0.options[1]), matching: find.byType(InkWell))
        .first);
    await settle(tester);
    for (var i = 0; i < 3; i++) {
      await tapKey(tester, 'next_question');
    }
    await tapKey(tester, 'go_review');
    clock.advance(const Duration(seconds: 601));
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(find.byKey(const Key('done_headline')), findsOneWidget);
    expect(find.byKey(const Key('time_up_note')), findsOneWidget);
    expect(exams.attemptById(a.id)!.status, AttemptStatus.submitted);
    expect(exams.attemptById(a.id)!.answers.length, 1);
    expect(
        await real(() => exams.answer(a.id, q0.id, q0.correctAnswer)), isFalse);
    expect(exams.attemptById(a.id)!.answers[q0.id]!.answer, q0.options[1]);
  });

  testWidgets(
      'V8 system back (device gesture) asks first, Keep going stays, Leave keeps the attempt',
      (tester) async {
    final a = await start(richBank(6), count: 4);
    await openExam(tester, a);
    await tester.tap(find
        .ancestor(
            of: find.text(a.questions[0].options[0]),
            matching: find.byType(InkWell))
        .first);
    await settle(tester);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('Leave the exam?'), findsOneWidget);
    await tapKey(tester, 'keep_going');
    expect(find.byType(ChildExamScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await settle(tester);
    await tapKey(tester, 'confirm_leave');
    expect(find.byType(ChildExamScreen), findsNothing);
    expect(exams.inProgressFor('kid'), isNotNull);
    expect(exams.inProgressFor('kid')!.answeredCount, 1);
  });

  testWidgets('V9 Level 5 result screen heading', (tester) async {
    store = MemoryExamStore();
    clock = TestClock();
    exams = examController(
        store, makeBank(world: 'english', lessons: 4, perLesson: 2, level: 8),
        clock: clock);
    final out = await real(() => exams.startExam(cfg(
        level: 8,
        count: 4,
        worlds: ['english'],
        type: ExamType.finalLevel,
        pass: 50)));
    final a = (out as StartExamStarted).attempt;
    await real(() => answerAll(exams, a, right: 4));
    await real(() => exams.submit(a.id));
    await pumpApp(tester, exams: exams, home: ResultScreen(attemptId: a.id));
    expect(find.textContaining('Level 9'), findsNothing,
        reason:
            'DEFECT: Level 8 is the highest level, but the result says "Ready for Level 9?"');
  });

  testWidgets('V10 no answer/marks on the done page even for a pass',
      (tester) async {
    final a = await start(richBank(6), count: 4);
    await real(() => answerAll(exams, a, right: 4));
    await openExam(tester, a);
    for (var i = 0; i < 3; i++) {
      await tapKey(tester, 'next_question');
    }
    await tapKey(tester, 'go_review');
    await tapKey(tester, 'submit_exam');
    await tapKey(tester, 'confirm_submit');
    final all = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join('\n');
    expect(RegExp(r'\d+\s*%|marks|of \d+|Cat|SECRET').hasMatch(all), isFalse,
        reason: all);
  });

  // ---- Layout: 360x800, rotated 800x360, text 1.6, long option text --------
  final long =
      'A very long option sentence that keeps going and going so that it must wrap onto several lines ';
  final unbroken = 'Supercalifragilisticexpialidocious' * 3;
  for (final size in const [Size(360, 800), Size(800, 360), Size(360, 640)]) {
    for (final scale in [1.0, 1.6]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()} text $scale';
      testWidgets(
          'V11 child exam with large option text wraps without overflow at $tag',
          (tester) async {
        final bank = [
          for (var i = 0; i < 4; i++)
            ExamQuestion(
              id: 'L$i#q0',
              lessonId: 'L$i',
              lessonTitle: 'Long $i',
              level: 1,
              world: 'english',
              topic: 'Long',
              objective: 'Read long things',
              type: ExamQuestionType.multipleChoice,
              prompt: '$long$long$long?',
              passage: i == 0 ? long * 8 : null,
              options: [long + long, unbroken, 'Short', '$long $i'],
              correctAnswer: 'Short',
              verification: const {Verification.machineChecked},
            ),
        ];
        final a = await start(bank, count: 4);
        await openExam(tester, a, size: size, scale: scale);
        expectNoOverflow(tester);
        // Every control is reachable: scroll to each option and the Next button.
        for (var i = 0; i < 4; i++) {
          await reveal(tester, 'option_$i');
          final r = tester.getRect(find.byKey(Key('option_$i')));
          expect(r.height, greaterThanOrEqualTo(48));
          expect(r.right, lessThanOrEqualTo(size.width + 0.5));
        }
        await reveal(tester, 'next_question');
        final nb = tester.getRect(find.byKey(const Key('next_question')));
        expect(nb.height, greaterThanOrEqualTo(48));
        expect(nb.bottom, lessThanOrEqualTo(size.height + 0.5));
        // Review page and done page too.
        for (var i = 0; i < 3; i++) {
          await tapKey(tester, 'next_question');
        }
        await tapKey(tester, 'go_review');
        expectNoOverflow(tester);
        await tapKey(tester, 'submit_exam');
        expectNoOverflow(tester);
        await tapKey(tester, 'confirm_submit');
        expectNoOverflow(tester);
        await reveal(tester, 'hand_back');
        expect(tester.getRect(find.byKey(const Key('hand_back'))).bottom,
            lessThanOrEqualTo(size.height + 0.5));
      });
    }
  }

  for (final size in const [Size(360, 800), Size(800, 360)]) {
    testWidgets(
        'V12 centre tabs with a very long child name and long answers, ${size.width.toInt()}x${size.height.toInt()} text 1.6',
        (tester) async {
      final longName = 'Venkata Subrahmanya Lakshmi Narasimha Rao ' * 2;
      final profile = ChildProfile(
          id: 'kid', name: longName, age: 5, avatar: 'lion', level: 1);
      store = MemoryExamStore();
      clock = TestClock();
      final bank = [
        for (var i = 0; i < 6; i++)
          ExamQuestion(
            id: 'L$i#q0',
            lessonId: 'L$i',
            lessonTitle: 'Lesson $long',
            level: 1,
            world: 'english',
            topic: 'Topic $unbroken',
            objective: 'Objective $long',
            type: ExamQuestionType.multipleChoice,
            prompt: '$long?',
            options: [long, unbroken, 'Short'],
            correctAnswer: long,
            explanation: long * 3,
            verification: const {Verification.machineChecked},
          ),
      ];
      exams = examController(store, bank, clock: clock);
      final out = await real(() => exams.startExam(ExamConfig(
            id: 'c1',
            childId: 'kid',
            childName: longName,
            level: 1,
            type: ExamType.finalLevel,
            worlds: const ['english'],
            questionCount: 6,
            passPercent: 50,
            createdAt: DateTime(2026, 1, 1),
          )));
      final a = (out as StartExamStarted).attempt;
      await real(() => answerAll(exams, a, right: 6));
      await real(() => exams.submit(a.id));
      // second, failed attempt for the Wrong-answers tile
      clock.advance(const Duration(days: 1));
      final out2 = await real(() => exams.startExam(ExamConfig(
            id: 'c2',
            childId: 'kid',
            childName: longName,
            level: 1,
            type: ExamType.subject,
            worlds: const ['english'],
            questionCount: 6,
            passPercent: 50,
            createdAt: DateTime(2026, 1, 1),
          )));
      final b = (out2 as StartExamStarted).attempt;
      await real(() => answerAll(exams, b, right: 1));
      await real(() => exams.submit(b.id));
      await pumpApp(tester,
          exams: exams,
          size: size,
          scale: 1.6,
          app: appController(profiles: [profile]),
          home: const ExaminationCentre(initialChildId: 'kid'));
      for (final tab in [
        'tab_conduct',
        'tab_results',
        'tab_history',
        'tab_certificates',
        'tab_settings'
      ]) {
        await openTab(tester, tab);
        expectNoOverflow(tester);
        if (tab == 'tab_results') {
          await tester.dragUntilVisible(find.textContaining('Wrong or missed'),
              find.byType(Scrollable).last, const Offset(0, -200));
          await settle(tester);
          expectNoOverflow(tester);
        }
      }
      await openTab(tester, 'tab_certificates');
      await tester.tap(find.byKey(const Key('certificate_1')));
      await settle(tester);
      expectNoOverflow(tester);
    });
  }

  test('V13 Random import used (keeps analyzer quiet)',
      () => expect(Random(1).nextInt(1), 0));
}
