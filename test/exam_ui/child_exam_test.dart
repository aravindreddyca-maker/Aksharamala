import 'package:aksharamala/src/exam/exam_controller.dart';
import 'package:aksharamala/src/exam/models.dart';
import 'package:aksharamala/src/screens/exam/child_exam_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_helpers.dart';

/// A home page the exam can pop back to.
class _Home extends StatelessWidget {
  const _Home(this.attemptId, {this.speech, this.now});

  final String attemptId;
  final FakeSpeech? speech;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            key: const Key('open_exam'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => ChildExamScreen(
                attemptId: attemptId,
                speech: speech ?? FakeSpeech(),
                now: now,
              ),
            )),
            child: const Text('HOME'),
          ),
        ),
      );
}

void main() {
  late MemoryExamStore store;
  late ExamController exams;
  late TestClock clock;

  Future<ExamAttempt> start({
    List<ExamQuestion>? bank,
    int count = 4,
    int? limit,
    bool parent = false,
  }) async {
    store = MemoryExamStore();
    clock = TestClock();
    exams = examController(store, bank ?? uiBank(), clock: clock);
    final out = await real(() => exams.startExam(
        cfg(count: count, worlds: ['english'], limit: limit, parent: parent)));
    return (out as StartExamStarted).attempt;
  }

  Future<void> openExam(
    WidgetTester tester,
    ExamAttempt a, {
    FakeSpeech? speech,
    bool useClock = false,
    Size size = const Size(390, 844),
  }) async {
    await pumpApp(
      tester,
      exams: exams,
      size: size,
      home: _Home(a.id, speech: speech, now: useClock ? clock.call : null),
    );
    await tapKey(tester, 'open_exam');
  }

  /// Taps the option that carries [text].
  Future<void> pick(WidgetTester tester, String text) async {
    final f = find
        .ancestor(of: find.text(text), matching: find.byType(InkWell))
        .first;
    await tester.tap(f);
    await settle(tester);
  }

  Future<void> answerCurrent(WidgetTester tester, ExamAttempt a, int i,
      {required bool right}) async {
    final q = a.questions[i];
    final text = right
        ? q.correctAnswer
        : q.options.firstWhere((o) => o != q.correctAnswer);
    await pick(tester, text);
  }

  testWidgets(
      'one question per screen with progress and no right/wrong feedback',
      (tester) async {
    final a = await start();
    await openExam(tester, a);
    expect(find.text('Question 1 of 4'), findsOneWidget);
    expect(find.byKey(const Key('prompt')), findsOneWidget);
    expect(find.byKey(const Key('option_0')), findsOneWidget);

    // Answer wrongly: nothing about right or wrong appears.
    await answerCurrent(tester, a, 0, right: false);
    for (final word in [
      'Correct',
      'Wrong',
      'Right',
      'Incorrect',
      'Try again',
      'Well done',
      'Oops'
    ]) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
    // And the same for a right answer.
    await tapKey(tester, 'next_question');
    expect(find.text('Question 2 of 4'), findsOneWidget);
    await answerCurrent(tester, a, 1, right: true);
    for (final word in ['Correct', 'Wrong', 'Right', 'Incorrect']) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
    // Saved after every answer, with no hint or explanation shown.
    expect(exams.attemptById(a.id)!.answeredCount, 2);
    expect(store.disk.attempts.single.answers.length, 2);
    expect(find.textContaining('Because'), findsNothing);
  });

  testWidgets('an answer can be changed until submission', (tester) async {
    final a = await start();
    await openExam(tester, a);
    final q = a.questions[0];
    await pick(tester, q.options[0]);
    expect(exams.attemptById(a.id)!.answers[q.id]!.answer, q.options[0]);
    await pick(tester, q.options[2]);
    expect(exams.attemptById(a.id)!.answers[q.id]!.answer, q.options[2]);
    // Going on and coming back keeps the last choice selected.
    await tapKey(tester, 'next_question');
    await tapKey(tester, 'prev_question');
    final tile = tester.widget<Semantics>(find
        .ancestor(
            of: find.byKey(const Key('option_2')),
            matching: find.byType(Semantics))
        .first);
    expect(tile, isNotNull);
    await pick(tester, q.options[3]);
    expect(exams.attemptById(a.id)!.answers[q.id]!.answer, q.options[3]);
    expect(exams.attemptById(a.id)!.answeredCount, 1);
  });

  testWidgets(
      'review page lists answered and unanswered and goes back to a question',
      (tester) async {
    final a = await start();
    await openExam(tester, a);
    await answerCurrent(tester, a, 0, right: true);
    for (var i = 0; i < 3; i++) {
      await tapKey(tester, 'next_question');
    }
    await tapKey(tester, 'go_review');
    expect(find.text('Check your answers'), findsOneWidget);
    expect(find.text('3 questions not answered yet.'), findsOneWidget);
    expect(find.byKey(const Key('review_status_0')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('review_status_0'))).data,
        'Answered');
    expect(tester.widget<Text>(find.byKey(const Key('review_status_1'))).data,
        'Not answered');

    await tapKey(tester, 'review_2');
    expect(find.text('Question 3 of 4'), findsOneWidget);
  });

  testWidgets(
      'submit asks for confirmation; Keep checking leaves the exam open',
      (tester) async {
    final a = await start();
    await openExam(tester, a);
    await answerCurrent(tester, a, 0, right: true);
    await tapKey(tester, 'next_question');
    await tapKey(tester, 'next_question');
    await tapKey(tester, 'next_question');
    await tapKey(tester, 'go_review');
    await tapKey(tester, 'submit_exam');
    expect(find.text('Hand in your exam?'), findsOneWidget);
    expect(find.textContaining('3 questions are not answered'), findsOneWidget);

    await tapKey(tester, 'keep_checking');
    expect(find.text('Hand in your exam?'), findsNothing);
    expect(exams.attemptById(a.id)!.status, AttemptStatus.inProgress);
    expect(exams.data.results, isEmpty);
  });

  testWidgets(
      'after submit the child sees pass/try-again only, no marks; device handed back',
      (tester) async {
    final a = await start();
    await openExam(tester, a);
    for (var i = 0; i < 4; i++) {
      await answerCurrent(tester, a, i, right: true);
      if (i < 3) await tapKey(tester, 'next_question');
    }
    await tapKey(tester, 'go_review');
    await tapKey(tester, 'submit_exam');
    await tapKey(tester, 'confirm_submit');

    expect(find.byKey(const Key('done_headline')), findsOneWidget);
    expect(find.text('Well done!'), findsOneWidget);
    final all = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' | ');
    expect(all, isNot(contains('%')));
    expect(all, isNot(contains('marks')));
    expect(all, isNot(matches(RegExp(r'\d+ (of|/) \d+'))));
    expect(all, contains('give the device back'));

    final stored = exams.resultFor(a.id)!;
    expect(stored.passed, isTrue);
    expect(exams.attemptById(a.id)!.status, AttemptStatus.submitted);

    // Handing back returns to the first screen (not into the parent centre).
    await tapKey(tester, 'hand_back');
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('a failed exam gets an encouraging try-again message',
      (tester) async {
    final a = await start();
    await openExam(tester, a);
    for (var i = 0; i < 4; i++) {
      await answerCurrent(tester, a, i, right: false);
      if (i < 3) await tapKey(tester, 'next_question');
    }
    await tapKey(tester, 'go_review');
    await tapKey(tester, 'submit_exam');
    await tapKey(tester, 'confirm_submit');
    expect(find.text('Good try!'), findsOneWidget);
    expect(find.textContaining('Fail'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('an exam awards no stars and changes no lesson progress',
      (tester) async {
    final a = await start();
    final app = appController();
    await pumpApp(tester, exams: exams, app: app, home: _Home(a.id));
    await tapKey(tester, 'open_exam');
    for (var i = 0; i < 4; i++) {
      await answerCurrent(tester, a, i, right: true);
      if (i < 3) await tapKey(tester, 'next_question');
    }
    await tapKey(tester, 'go_review');
    await tapKey(tester, 'submit_exam');
    await tapKey(tester, 'confirm_submit');
    expect(app.activeProfile!.stars, 0);
    expect(app.activeProgress.completedLessons, isEmpty);
    expect(app.activeProgress.attempts, isEmpty);
  });

  testWidgets('back asks first and keeps the attempt resumable',
      (tester) async {
    final a = await start();
    await openExam(tester, a);
    await answerCurrent(tester, a, 0, right: true);

    await tapKey(tester, 'exam_back');
    expect(find.text('Leave the exam?'), findsOneWidget);
    await tapKey(tester, 'keep_going');
    expect(find.byType(ChildExamScreen), findsOneWidget);

    // The system back gesture asks too.
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('Leave the exam?'), findsOneWidget);
    await tapKey(tester, 'confirm_leave');
    expect(find.byType(ChildExamScreen), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
    final kept = exams.attemptById(a.id)!;
    expect(kept.status, AttemptStatus.inProgress);
    expect(kept.answeredCount, 1);
  });

  testWidgets('resume after rebuilding the controller from the same store',
      (tester) async {
    final a = await start();
    await openExam(tester, a);
    await answerCurrent(tester, a, 0, right: true);
    await tapKey(tester, 'next_question');
    await answerCurrent(tester, a, 1, right: false);

    // "Close the app": throw the controller and the tree away.
    await tester.pumpWidget(const SizedBox());
    final reopened = examController(store, uiBank(), clock: clock);
    await real(() => reopened.load());
    final again = reopened.inProgressFor('kid')!;
    expect(again.id, a.id);
    expect(again.answeredCount, 2);
    exams = reopened;

    await openExam(tester, again);
    // Resumes at the first unanswered question, earlier answers kept.
    expect(find.text('Question 3 of 4'), findsOneWidget);
    await tapKey(tester, 'prev_question');
    await tapKey(tester, 'prev_question');
    expect(find.text('Question 1 of 4'), findsOneWidget);
    expect(reopened.attemptById(a.id)!.answers[a.questions[0].id]!.answer,
        a.questions[0].correctAnswer);
  });

  testWidgets('timer is a plain number; expiry submits what is answered',
      (tester) async {
    final a = await start(limit: 90);
    await openExam(tester, a, useClock: true);
    expect(
        tester.widget<Text>(find.byKey(const Key('exam_timer'))).data, '1:30');
    await answerCurrent(tester, a, 0, right: true);

    clock.advance(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 1));
    expect(
        tester.widget<Text>(find.byKey(const Key('exam_timer'))).data, '1:00');

    clock.advance(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);

    expect(find.byKey(const Key('done_headline')), findsOneWidget);
    expect(find.byKey(const Key('time_up_note')), findsOneWidget);
    final stored = exams.attemptById(a.id)!;
    expect(stored.status, AttemptStatus.submitted);
    expect(stored.answeredCount, 1);
    final r = exams.resultFor(a.id)!;
    expect(r.unanswered, 3);
  });

  testWidgets('no timer is shown for an untimed exam', (tester) async {
    final a = await start();
    await openExam(tester, a);
    expect(find.byKey(const Key('exam_timer')), findsNothing);
  });

  testWidgets('Listen speaks the lesson line only when a question has one',
      (tester) async {
    final bank = [
      richQuestion(id: 'R0#q0', speech: 'Cat'),
      richQuestion(id: 'R0#q1', prompt: 'Second', speech: null),
    ];
    final a = await start(bank: bank, count: 2);
    final speech = FakeSpeech();
    await openExam(tester, a, speech: speech);
    // Questions are shuffled: walk both and count the Listen buttons.
    var listens = 0;
    for (var i = 0; i < 2; i++) {
      if (find.byKey(const Key('listen')).evaluate().isNotEmpty) {
        listens++;
        await tapKey(tester, 'listen');
      }
      if (i == 0) await tapKey(tester, 'next_question');
    }
    expect(listens, 1);
    expect(speech.spoken, ['en-US|Cat']);
  });

  testWidgets('parent-marked items need no answer and are left to the parent',
      (tester) async {
    final a =
        await start(bank: uiBank(parentMarked: true), count: 19, parent: true);
    expect(a.questions.any((q) => q.isParentMarked), isTrue);
    await openExam(tester, a);
    final idx = a.questions.indexWhere((q) => q.isParentMarked);
    for (var i = 0; i < idx; i++) {
      await tapKey(tester, 'next_question');
    }
    expect(find.textContaining('grown-up will check it'), findsOneWidget);
    expect(find.byKey(const Key('option_0')), findsNothing);
  });
}
