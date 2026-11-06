import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/exam/exam_controller.dart';
import 'package:aksharamala/src/exam/models.dart';
import 'package:aksharamala/src/exam/question_bank.dart';
import 'package:aksharamala/src/screens/exam/certificates_tab.dart';
import 'package:aksharamala/src/screens/exam/child_exam_screen.dart';
import 'package:aksharamala/src/screens/exam/examination_centre.dart';
import 'package:aksharamala/src/screens/exam/results_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_helpers.dart';

Future<ExamAttempt> _start(ExamController exams, ExamConfig c) async {
  final out = await real(() => exams.startExam(c));
  return (out as StartExamStarted).attempt;
}

void main() {
  test('topic labels are words, not internal names', () {
    expect(topicLabel('alphabet'), 'Alphabet');
    expect(topicLabel('wordBuilder'), 'Word Builder');
  });

  testWidgets('subject exam in a subject with no questions cannot start',
      (tester) async {
    final exams = examController(MemoryExamStore(), uiBank());
    await pumpApp(tester,
        exams: exams, home: const ExaminationCentre(initialChildId: 'kid'));
    await tapKey(tester, 'world_telugu');
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('start_exam')))
            .onPressed,
        isNull);
  });

  testWidgets('Level 5 result says highest level', (tester) async {
    final exams = examController(MemoryExamStore(),
        makeBank(world: 'english', lessons: 4, perLesson: 2, level: 8));
    final a = await _start(
        exams,
        cfg(
            level: 8,
            count: 4,
            worlds: ['english'],
            type: ExamType.finalLevel));
    await real(() => answerAll(exams, a, right: 4));
    await real(() => exams.submit(a.id));
    await pumpApp(tester, exams: exams, home: ResultScreen(attemptId: a.id));
    expect(find.text('Level 8 is the highest level'), findsOneWidget);
    expect(find.textContaining('Level 9'), findsNothing);
  });

  testWidgets('certificate number never wraps mid-id at 360 wide, 1.6 text',
      (tester) async {
    final exams = examController(MemoryExamStore(), uiBank());
    final a = await _start(
        exams, cfg(count: 6, worlds: ['english'], type: ExamType.finalLevel));
    await real(() => answerAll(exams, a, right: 6));
    await real(() => exams.submit(a.id));
    await pumpApp(tester,
        exams: exams,
        size: const Size(360, 800),
        scale: 1.6,
        home: const CertificateScreen(childId: 'kid', level: 1));
    final id = tester.getRect(find.byKey(const Key('certificate_id')));
    final date = tester.getRect(find.byKey(const Key('certificate_date')));
    expect(id.height, lessThan(40 * 1.6), reason: 'one line only');
    expect((id.center.dx - date.center.dx).abs(), lessThan(2));
    expectNoOverflow(tester);
  });

  for (final scale in [1.0, 1.6]) {
    testWidgets('800x360 landscape shows at least two answers at text $scale',
        (tester) async {
      final bank = [richQuestion(prompt: 'A long question ' * 12)];
      final exams = examController(MemoryExamStore(), bank);
      final a = await _start(exams, cfg(count: 1, worlds: ['english']));
      await pumpApp(tester,
          exams: exams,
          size: const Size(800, 360),
          scale: scale,
          home: ChildExamScreen(attemptId: a.id, speech: FakeSpeech()));
      expectNoOverflow(tester);
      for (final i in [0, 1]) {
        final r = tester.getRect(find.byKey(Key('option_$i')));
        expect(r.bottom, lessThanOrEqualTo(360), reason: 'option $i');
        expect(r.top, greaterThanOrEqualTo(0));
      }
    });
  }

  group('real bank (D3)', () {
    final bank = ExamQuestionBank.defaults();
    final worlds = AppController().allWorlds;

    bool tok(String text, String a) => text
        .toLowerCase()
        .split(RegExp(r'[\s.,;:!?()\[\]"]+'))
        .where((t) => t.isNotEmpty)
        .contains(a.trim().toLowerCase());

    test('no kept question shows its answer in the prompt', () {
      for (final q in bank.questions) {
        if (q.isParentMarked || q.type == ExamQuestionType.arithmetic) continue;
        expect(tok(q.prompt, q.correctAnswer), isFalse, reason: q.id);
      }
    });

    test('leaking questions are reported with a reason', () {
      final leaks =
          bank.rejected.where((r) => r.reason == 'answer visible in prompt');
      expect(leaks.length, greaterThanOrEqualTo(14));
      final ids = leaks.map((r) => r.id).toSet();
      expect(ids, contains('te-letter-004#q0'));
      expect(ids, contains('english-56-013#q1'));
    });

    test('sight-matching glyph questions are easy recognition', () {
      final sight = bank.questions.where((q) =>
          !q.isParentMarked &&
          q.glyph != null &&
          q.glyph!.trim() == q.correctAnswer.trim());
      expect(sight, isNotEmpty);
      for (final q in sight) {
        expect(q.type, ExamQuestionType.recognition, reason: q.id);
        expect(q.difficulty, 1, reason: q.id);
      }
    });

    test('coverage still adds up', () {
      final rows = bank.coverage(worlds);
      for (var l = 1; l <= 5; l++) {
        expect(
            rows
                .where((r) => r.level == l)
                .fold<int>(0, (a, r) => a + r.questions),
            bank.forLevel(l).length);
      }
      // ignore: avoid_print
      print(
          'LEVEL COUNTS ${bank.countsByLevel()} rejected ${bank.rejected.length}');
    });
  });
}
