import 'dart:convert';

import 'package:aksharamala/src/exam/evaluation.dart';
import 'package:aksharamala/src/exam/models.dart';
import 'package:aksharamala/src/exam/selection.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

ExamAttempt attemptOf(ExamConfig c, List<ExamQuestion> bank, {int seed = 3}) {
  final o = ExamSelection.build(
    config: c,
    bank: bank,
    seed: seed,
    attemptId: 'att1',
    now: DateTime(2026, 1, 1, 9),
  );
  return (o as SelectionOk).attempt;
}

/// First [right] questions right, the rest wrong; the first of the "wrong" ones
/// is left blank.
ExamAttempt answered(ExamAttempt a, int right, {bool blankOne = false}) {
  final answers = <String, ExamAnswer>{};
  for (var i = 0; i < a.questions.length; i++) {
    final q = a.questions[i];
    if (q.isParentMarked) continue;
    if (i < right) {
      answers[q.id] = ExamAnswer(q.correctAnswer, DateTime(2026, 1, 1, 9, 1));
    } else if (!(blankOne && i == right)) {
      answers[q.id] = ExamAnswer(
          q.options.firstWhere((o) => o != q.correctAnswer),
          DateTime(2026, 1, 1, 9, 1));
    }
  }
  return a.copyWith(
    answers: answers,
    status: AttemptStatus.submitted,
    finishedAt: DateTime(2026, 1, 1, 9, 5),
  );
}

void main() {
  final bank = makeBank(lessons: 5, perLesson: 2);

  test('scores by comparing stored answers', () {
    final a = answered(attemptOf(cfg(count: 10), bank), 7);
    final r = ExamEvaluator.evaluate(a);
    expect(r.totalMarks, 10);
    expect(r.obtainedMarks, 7);
    expect(r.percent, 70);
    expect(r.passed, isTrue);
    expect(r.wrong.length, 3);
    expect(r.timeTakenSeconds, 300);
    expect(r.awaitingParentMarks, 0);
  });

  test('pass mark is configurable and inclusive', () {
    final base = attemptOf(cfg(count: 10, pass: 70), bank);
    expect(ExamEvaluator.evaluate(answered(base, 7)).passed, isTrue);
    expect(ExamEvaluator.evaluate(answered(base, 6)).passed, isFalse);
    final lenient = attemptOf(cfg(count: 10, pass: 40), bank);
    expect(ExamEvaluator.evaluate(answered(lenient, 4)).passed, isTrue);
  });

  test('unanswered counts as wrong and is reported', () {
    final a = answered(attemptOf(cfg(count: 10), bank), 5, blankOne: true);
    final r = ExamEvaluator.evaluate(a);
    expect(r.unanswered, 1);
    expect(r.obtainedMarks, 5);
    expect(r.wrong.where((w) => w.given.isEmpty).length, 1);
  });

  test('nothing answered fails with 0%', () {
    final a = attemptOf(cfg(count: 10), bank).copyWith(
        status: AttemptStatus.submitted,
        finishedAt: DateTime(2026, 1, 1, 9, 1));
    final r = ExamEvaluator.evaluate(a);
    expect(r.percent, 0);
    expect(r.passed, isFalse);
  });

  test('final exam: overall pass but a world below its minimum fails', () {
    final fbank = [
      ...makeBank(world: 'w1', lessons: 5, perLesson: 2, prefix: 'A'),
      ...makeBank(world: 'w2', lessons: 5, perLesson: 2, prefix: 'B'),
    ];
    final c = cfg(
        type: ExamType.finalLevel,
        worlds: ['w1', 'w2'],
        count: 20,
        pass: 60,
        perWorld: 50);
    final base = attemptOf(c, fbank);
    ExamAttempt withRight(bool Function(ExamQuestion) isRight) {
      final answers = {
        for (final q in base.questions)
          q.id: ExamAnswer(
              isRight(q)
                  ? q.correctAnswer
                  : q.options.firstWhere((o) => o != q.correctAnswer),
              DateTime(2026, 1, 1)),
      };
      return base.copyWith(
          answers: answers,
          status: AttemptStatus.submitted,
          finishedAt: DateTime(2026, 1, 1, 9, 5));
    }

    // w1 all right, w2 only 2 of 10 right: 12/20 = 60% overall, w2 = 20%.
    var w2right = 0;
    final lopsided = withRight((q) {
      if (q.world == 'w1') return true;
      return w2right++ < 2;
    });
    final r1 = ExamEvaluator.evaluate(lopsided);
    expect(r1.percent, 60);
    expect(r1.bySubject['w2']!.percent, 20);
    expect(r1.passed, isFalse);
    expect(r1.readiness.ready, isFalse);
    expect(r1.readiness.weakWorlds, ['w2']);

    // 80% in each world: passes and is ready.
    final counts = <String, int>{};
    final good =
        withRight((q) => (counts[q.world] = (counts[q.world] ?? 0) + 1) <= 8);
    final r2 = ExamEvaluator.evaluate(good);
    expect(r2.passed, isTrue);
    expect(r2.readiness.ready, isTrue);
    expect(r2.readiness.text, contains('Level 2'));

    // The same lopsided answers pass when there is no per-world minimum.
    final noMin = ExamAttempt.fromJson({
      ...lopsided.toJson(),
      'config': {...lopsided.config.toJson(), 'perWorldMinPercent': null},
    });
    expect(ExamEvaluator.evaluate(noMin).passed, isTrue);
  });

  test('readiness is never claimed for a non-final exam', () {
    final a = answered(attemptOf(cfg(count: 10), bank), 10);
    final r = ExamEvaluator.evaluate(a);
    expect(r.passed, isTrue);
    expect(r.readiness.ready, isFalse);
    expect(r.readiness.text, contains('final exam'));
  });

  test('parent-marked questions wait and are excluded from the percent', () {
    final pbank = [
      ...makeBank(lessons: 4, perLesson: 1),
      mq('W', 0, type: ExamQuestionType.parentMarked)
    ];
    final base = attemptOf(cfg(count: 5, parent: true), pbank);
    final auto = base.questions.where((q) => !q.isParentMarked);
    final pm = base.questions.firstWhere((q) => q.isParentMarked);
    final a = base.copyWith(
      answers: {
        for (final q in auto)
          q.id: ExamAnswer(q.correctAnswer, DateTime(2026, 1, 1))
      },
      status: AttemptStatus.submitted,
      finishedAt: DateTime(2026, 1, 1, 9, 2),
    );
    final waiting = ExamEvaluator.evaluate(a);
    expect(waiting.awaitingParentMarks, 1);
    expect(waiting.isProvisional, isTrue);
    expect(waiting.totalMarks, 4);
    expect(waiting.percent, 100);
    expect(waiting.readiness.ready, isFalse);

    final marked =
        ExamEvaluator.evaluate(a.copyWith(parentMarks: {pm.id: false}));
    expect(marked.awaitingParentMarks, 0);
    expect(marked.totalMarks, 5);
    expect(marked.obtainedMarks, 4);
    expect(marked.percent, 80);
    expect(marked.wrong.single.questionId, pm.id);

    final right =
        ExamEvaluator.evaluate(a.copyWith(parentMarks: {pm.id: true}));
    expect(right.percent, 100);
  });

  test('breakdowns by world, topic and objective', () {
    final bbank = [
      for (var i = 0; i < 4; i++)
        mq('A$i', 0, world: 'w1', topic: 'letters', objective: 'Know letters'),
      for (var i = 0; i < 4; i++)
        mq('B$i', 0, world: 'w2', topic: 'sums', objective: 'Add'),
    ];
    final base = attemptOf(
        cfg(type: ExamType.finalLevel, worlds: ['w1', 'w2'], count: 8), bbank);
    final a = base.copyWith(
      answers: {
        for (final q in base.questions)
          q.id: ExamAnswer(
              q.world == 'w1'
                  ? q.correctAnswer
                  : q.options.firstWhere((o) => o != 'A'),
              DateTime(2026, 1, 1)),
      },
      status: AttemptStatus.submitted,
      finishedAt: DateTime(2026, 1, 1, 9, 3),
    );
    final r = ExamEvaluator.evaluate(a);
    expect(r.bySubject['w1']!.correct, 4);
    expect(r.bySubject['w2']!.correct, 0);
    expect(r.byTopic['letters']!.percent, 100);
    expect(r.byTopic['sums']!.percent, 0);
    expect(r.byObjective['Add']!.count, 4);
  });

  test('recommendations name the lesson id, objective and counts', () {
    final rbank = [
      for (var i = 0; i < 4; i++)
        mq('num-add', i, objective: 'Add two quantities within ten'),
      for (var i = 0; i < 2; i++)
        mq('num-sub', i, objective: 'Subtract within ten'),
      mq('en-a', 0, objective: 'Recognise A'),
    ];
    final base = attemptOf(cfg(count: 7), rbank);
    // Miss 3 of 4 in num-add, 1 of 2 in num-sub, none in en-a.
    final missed = <String, int>{'num-add': 3, 'num-sub': 1};
    final answers = <String, ExamAnswer>{};
    for (final q in base.questions) {
      final left = missed[q.lessonId] ?? 0;
      final wrong = left > 0;
      if (wrong) missed[q.lessonId] = left - 1;
      answers[q.id] = ExamAnswer(
          wrong
              ? q.options.firstWhere((o) => o != q.correctAnswer)
              : q.correctAnswer,
          DateTime(2026, 1, 1));
    }
    final r = ExamEvaluator.evaluate(base.copyWith(
        answers: answers,
        status: AttemptStatus.submitted,
        finishedAt: DateTime(2026, 1, 1, 9, 2)));
    expect(r.recommendations.map((e) => e.lessonId), ['num-add', 'num-sub']);
    final first = r.recommendations.first;
    expect(first.missed, 3);
    expect(first.asked, 4);
    expect(first.text, contains('num-add'));
    expect(first.text, contains('Add two quantities within ten'));
    expect(first.text, contains('missed 3 of 4'));
    expect(r.recommendations.last.text, contains('missed 1 of 2'));
    expect(r.recommendations.any((e) => e.lessonId == 'en-a'), isFalse);
  });

  test('checksum detects a changed answer, mark, or score', () {
    final a = answered(attemptOf(cfg(count: 10), bank), 7);
    final r = ExamEvaluator.evaluate(a);
    expect(ExamEvaluator.verify(r, a), isTrue);

    // Edit one stored answer to the right one.
    final q = a.questions
        .firstWhere((q) => a.answers[q.id]!.answer != q.correctAnswer);
    final tampered = a.copyWith(answers: {
      ...a.answers,
      q.id: ExamAnswer(q.correctAnswer, DateTime(2026, 1, 1))
    });
    expect(ExamEvaluator.verify(r, tampered), isFalse);

    // Edit the stored score and leave the checksum.
    final edited = ExamResult.fromJson(
        {...r.toJson(), 'obtainedMarks': 10, 'percent': 100.0});
    expect(ExamEvaluator.verify(edited, a), isFalse);

    // Edit pass/fail alone.
    final flipped = ExamResult.fromJson({...r.toJson(), 'passed': false});
    expect(ExamEvaluator.verify(flipped, a), isFalse);

    // Edit a parent mark.
    final pbank = [
      ...makeBank(lessons: 3, perLesson: 1),
      mq('W', 0, type: ExamQuestionType.parentMarked)
    ];
    final base = attemptOf(cfg(count: 4, parent: true), pbank);
    final pm = base.questions.firstWhere((q) => q.isParentMarked);
    final marked = base.copyWith(parentMarks: {pm.id: false});
    final pr = ExamEvaluator.evaluate(marked);
    expect(ExamEvaluator.verify(pr, marked), isTrue);
    expect(
        ExamEvaluator.verify(pr, marked.copyWith(parentMarks: {pm.id: true})),
        isFalse);
  });

  test('checksum survives a JSON round trip of result and attempt', () {
    final a = answered(attemptOf(cfg(count: 10), bank), 6);
    final r = ExamEvaluator.evaluate(a);
    final a2 = ExamAttempt.fromJson(
        jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>);
    final r2 = ExamResult.fromJson(
        jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>);
    expect(ExamEvaluator.verify(r2, a2), isTrue);
    expect(r2.recommendations.length, r.recommendations.length);
  });

  test('time taken is capped at the time limit', () {
    final c = cfg(count: 5, limit: 60);
    final a = answered(attemptOf(c, bank), 5)
        .copyWith(finishedAt: DateTime(2026, 1, 1, 9, 30));
    expect(ExamEvaluator.evaluate(a).timeTakenSeconds, 60);
  });
}
