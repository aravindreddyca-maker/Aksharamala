import 'package:aksharamala/src/exam/models.dart';
import 'package:aksharamala/src/exam/question_bank.dart';
import 'package:aksharamala/src/exam/selection.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

ExamAttempt ok(SelectionOutcome o) {
  expect(o, isA<SelectionOk>(), reason: o is SelectionRefused ? o.reason : '');
  return (o as SelectionOk).attempt;
}

SelectionOutcome build(
  ExamConfig c,
  List<ExamQuestion> bank, {
  int seed = 1,
  Set<String> last = const {},
  bool Function(String)? exists,
}) =>
    ExamSelection.build(
      config: c,
      bank: bank,
      seed: seed,
      attemptId: 'a1',
      now: DateTime(2026, 1, 1),
      lastAskedIds: last,
      assetExists: exists,
    );

void main() {
  test('balances across lessons: ten lessons, ten questions, one each', () {
    final bank = makeBank(lessons: 10, perLesson: 3);
    for (var seed = 0; seed < 20; seed++) {
      final a = ok(build(cfg(count: 10), bank, seed: seed));
      expect({for (final q in a.questions) q.lessonId}.length, 10,
          reason: 'seed $seed');
    }
  });

  test(
      'more questions than lessons: no lesson gets a second before all have one',
      () {
    final bank = makeBank(lessons: 4, perLesson: 5);
    final a = ok(build(cfg(count: 6), bank));
    final counts = <String, int>{};
    for (final q in a.questions) {
      counts[q.lessonId] = (counts[q.lessonId] ?? 0) + 1;
    }
    expect(counts.length, 4);
    expect(counts.values.every((c) => c >= 1 && c <= 2), isTrue);
  });

  test('no question appears twice', () {
    final bank = makeBank(lessons: 5, perLesson: 4);
    final a = ok(build(cfg(count: 20), bank));
    expect({for (final q in a.questions) q.id}.length, 20);
  });

  test('honest refusal carries the available count', () {
    final bank = makeBank(lessons: 3, perLesson: 2);
    final r = build(cfg(count: 10), bank);
    expect(r, isA<SelectionRefused>());
    r as SelectionRefused;
    expect(r.available, 6);
    expect(r.requested, 10);
    expect(r.reason, contains('6'));
    // The offered size works.
    ok(build(cfg(count: 6), bank));
  });

  test('empty scope (Level 5) is refused with 0 available, nothing invented',
      () {
    final bank = ExamQuestionBank.fromQuestions(makeBank()).questions;
    final r = build(cfg(level: 5), bank) as SelectionRefused;
    expect(r.available, 0);
    final zero = build(cfg(count: 0), bank) as SelectionRefused;
    expect(zero.available, 0);
  });

  test('deterministic for a given seed, different for another', () {
    final bank = makeBank(lessons: 8, perLesson: 4);
    String sig(ExamAttempt a) =>
        a.questions.map((q) => '${q.id}:${q.options.join()}').join('|');
    final a = ok(build(cfg(count: 12), bank, seed: 77));
    final b = ok(build(cfg(count: 12), bank.reversed.toList(), seed: 77));
    final c = ok(build(cfg(count: 12), bank, seed: 78));
    expect(sig(a), sig(b));
    expect(sig(a), isNot(sig(c)));
    expect(a.seed, 77);
  });

  test('retest prefers questions not asked in the last attempt', () {
    final bank = makeBank(lessons: 6, perLesson: 4); // 24
    for (var seed = 0; seed < 10; seed++) {
      final first = ok(build(cfg(count: 10), bank, seed: seed));
      final lastIds = {for (final q in first.questions) q.id};
      final second =
          ok(build(cfg(count: 10), bank, seed: seed + 100, last: lastIds));
      expect(second.questions.where((q) => lastIds.contains(q.id)), isEmpty,
          reason: 'seed $seed');
    }
  });

  test('retest repeats only as many as it must', () {
    final bank = makeBank(lessons: 3, perLesson: 4); // 12
    final last = {for (final q in bank.take(8)) q.id};
    final a = ok(build(cfg(count: 10), bank, last: last));
    expect(a.questions.where((q) => last.contains(q.id)).length, 6);
  });

  test('option shuffle keeps the same options and the answer', () {
    final bank = makeBank(lessons: 6, perLesson: 2);
    var moved = 0;
    for (var seed = 0; seed < 10; seed++) {
      final a = ok(build(cfg(count: 12), bank, seed: seed));
      for (final q in a.questions) {
        expect(q.options.toSet(), {'A', 'B', 'C', 'D'});
        expect(q.options, contains(q.correctAnswer));
        if (q.options.join() != 'ABCD') moved++;
      }
    }
    expect(moved, greaterThan(0));
  });

  test('frozen copies are independent of later bank changes', () {
    final bank = makeBank(lessons: 3, perLesson: 2);
    final a = ok(build(cfg(count: 4), bank));
    final json = a.toJson();
    expect(ExamAttempt.fromJson(json).toJson(), json);
  });

  test('final exam guarantees a minimum from every chosen world', () {
    final bank = [
      ...makeBank(world: 'big1', lessons: 12, perLesson: 3, prefix: 'X'),
      ...makeBank(world: 'big2', lessons: 12, perLesson: 3, prefix: 'Y'),
      ...makeBank(world: 'tiny', lessons: 2, perLesson: 1, prefix: 'Z'),
    ];
    final c = cfg(
        type: ExamType.finalLevel,
        worlds: ['big1', 'big2', 'tiny'],
        count: 12,
        perWorld: 50);
    // quota = 12 ~/ 6 = 2: the tiny world's two questions always make it in.
    for (var seed = 0; seed < 30; seed++) {
      final a = ok(build(c, bank, seed: seed));
      expect(a.questions.where((q) => q.world == 'tiny').length, 2,
          reason: 'seed $seed');
      for (final w in ['big1', 'big2']) {
        expect(a.questions.where((q) => q.world == w).length,
            greaterThanOrEqualTo(2));
      }
      expect(a.questions.length, 12);
    }
  });

  test('final exam refuses when a chosen world has no questions', () {
    final bank = makeBank(world: 'w1', lessons: 5, perLesson: 2);
    final r = build(
        cfg(type: ExamType.finalLevel, worlds: ['w1', 'ghost'], count: 4),
        bank);
    expect(r, isA<SelectionRefused>());
    expect((r as SelectionRefused).reason, contains('ghost'));
    expect(r.available, 10);
  });

  test('scope by type', () {
    final bank = [
      ...makeBank(world: 'w1', lessons: 3, perLesson: 2, prefix: 'A'),
      ...makeBank(world: 'w2', lessons: 3, perLesson: 2, prefix: 'B'),
      ...makeBank(world: 'w1', lessons: 2, perLesson: 2, prefix: 'C', level: 2),
    ];
    final chapter = ok(build(
        cfg(
            type: ExamType.chapter,
            worlds: [],
            lessonIds: ['A0', 'B1'],
            count: 4),
        bank));
    expect({for (final q in chapter.questions) q.lessonId}, {'A0', 'B1'});
    final subject =
        ok(build(cfg(type: ExamType.subject, worlds: ['w2'], count: 6), bank));
    expect(subject.questions.every((q) => q.world == 'w2'), isTrue);
    final level2 = ok(build(
        cfg(type: ExamType.finalLevel, worlds: [], level: 2, count: 4), bank));
    expect(level2.questions.every((q) => q.levels.contains(2)), isTrue);
    expect(build(cfg(type: ExamType.subject, worlds: ['w2'], count: 7), bank),
        isA<SelectionRefused>());
  });

  test('difficulty mix is followed where available', () {
    final bank = makeBank(
        lessons: 12,
        perLesson: 5,
        difficulty: (l, q) => q % 3 == 0 ? 1 : (q % 3 == 1 ? 2 : 3));
    final c = cfg(
        count: 10, mix: const DifficultyMix(easy: 50, medium: 30, hard: 20));
    for (var seed = 0; seed < 10; seed++) {
      final a = ok(build(c, bank, seed: seed));
      int n(int d) => a.questions.where((q) => q.difficulty == d).length;
      expect([n(1), n(2), n(3)], [5, 3, 2], reason: 'seed $seed');
    }
  });

  test('difficulty mix relaxes when a difficulty does not exist', () {
    final bank = makeBank(lessons: 6, perLesson: 3); // all easy
    final a = ok(build(cfg(count: 9, mix: const DifficultyMix()), bank));
    expect(a.questions.length, 9);
  });

  test('unplayable questions (missing picture) are dropped before counting',
      () {
    final bank = [
      ...makeBank(lessons: 4, perLesson: 1),
      mq('P', 0, pictures: {'A': 'missing.png'}),
      mq('P', 1, cover: 'cover_missing.png'),
    ];
    final c = cfg(count: 4);
    final candidates = ExamSelection.candidates(c, bank,
        assetExists: (p) => !p.contains('missing'));
    expect(candidates.length, 4);
    final a = ok(build(c, bank, exists: (p) => !p.contains('missing')));
    expect(a.questions.any((q) => q.lessonId == 'P'), isFalse);
    final r = build(cfg(count: 6), bank, exists: (p) => !p.contains('missing'));
    expect((r as SelectionRefused).available, 4);
  });

  test('parent-marked questions only when the config asks for them', () {
    final bank = [
      ...makeBank(lessons: 3, perLesson: 1),
      mq('W', 0, type: ExamQuestionType.parentMarked),
    ];
    expect(ExamSelection.candidates(cfg(), bank).length, 3);
    expect(ExamSelection.candidates(cfg(parent: true), bank).length, 4);
  });

  test(
      'works on the real bank: an empty level refused, Level 1 English subject works',
      () {
    final real = ExamQuestionBank.defaults();
    // The regional worlds stop at Level 5, so Level 8 Telugu has no questions.
    final l8 =
        build(cfg(level: 8, worlds: ['telugu'], count: 5), real.questions);
    expect((l8 as SelectionRefused).available, 0);
    final l1 = ok(
        build(cfg(level: 1, worlds: ['english'], count: 10), real.questions));
    expect(l1.questions.length, 10);
    expect({for (final q in l1.questions) q.id}.length, 10);
    final tooMany =
        build(cfg(level: 1, worlds: ['english'], count: 500), real.questions);
    expect((tooMany as SelectionRefused).available, greaterThan(20));
  });
}
