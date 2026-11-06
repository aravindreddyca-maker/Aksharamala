// Independent scans of the REAL question bank built from the app's lessons.
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/exam/models.dart';
import 'package:aksharamala/src/exam/question_bank.dart';
import 'package:aksharamala/src/exam/selection.dart';
import 'package:flutter_test/flutter_test.dart';

bool _tok(String text, String a) {
  final x = a.trim().toLowerCase();
  if (x.isEmpty) return false;
  return text
      .toLowerCase()
      .split(RegExp(r'[\s.,;:!?()\[\]"]+'))
      .where((t) => t.isNotEmpty)
      .contains(x);
}

void main() {
  final bank = ExamQuestionBank.defaults();
  final worlds = AppController().allWorlds;

  test(
      'S1 coverage numbers equal the real bank and an independent lesson count',
      () {
    final rows = bank.coverage(worlds);
    for (var l = 1; l <= 8; l++) {
      final fromRows = rows
          .where((r) => r.level == l)
          .fold<int>(0, (a, r) => a + r.questions);
      expect(fromRows, bank.forLevel(l).length, reason: 'level $l');
    }
    // Independent upper bound from the lessons themselves.
    final ub = {for (var l = 1; l <= 8; l++) l: 0};
    for (final w in worlds) {
      for (final lesson in w.lessons) {
        int n = 0;
        if (lesson is BatchLesson) {
          n = lesson.steps
              .where(
                  (s) => s.kind != StepKind.listen && s.kind != StepKind.write)
              .length;
        } else if (lesson.options.isNotEmpty && lesson.answer.isNotEmpty) {
          n = 1;
        }
        for (final l in lesson.levels) {
          ub[l] = ub[l]! + n;
        }
      }
    }
    // ignore: avoid_print
    print(
        'S1 bank per level: ${bank.countsByLevel()} ; upper bound from lessons: $ub ; rejected: ${bank.rejected.length}');
    for (var l = 1; l <= 8; l++) {
      expect(bank.forLevel(l).length, lessThanOrEqualTo(ub[l]!));
    }
    // Per-world coverage never exceeds what selection sees as candidates.
    for (final r in rows.where((r) => r.questions > 0)) {
      final c = ExamSelection.candidates(
        ExamConfig(
          id: 'x',
          childId: 'k',
          level: r.level,
          type: ExamType.subject,
          worlds: [r.worldId],
          questionCount: 1,
          passPercent: 50,
          createdAt: DateTime(2026),
        ),
        bank.questions,
      );
      expect(c.length, r.questions, reason: '${r.worldId} L${r.level}');
    }
  });

  test(
      'S2 answer leakage heuristics over every real question (prompt, passage, glyph, cover name)',
      () {
    final inPrompt = <String>[];
    final equalsGlyph = <String>[];
    final inPassageNonStory = <String>[];
    final coverNamesAnswer = <String>[];
    final speechIsAnswer = <String>[];
    for (final q in bank.questions) {
      if (q.isParentMarked) continue;
      final a = q.correctAnswer;
      if (_tok(q.prompt, a) && q.type != ExamQuestionType.arithmetic)
        inPrompt.add(q.id);
      if (q.glyph != null && q.glyph!.trim() == a.trim()) equalsGlyph.add(q.id);
      if (q.passage != null && _tok(q.passage!, a)) {
        inPassageNonStory.add(q.id);
      }
      final cover = q.promptPicture?.toLowerCase();
      if (cover != null &&
          a.trim().length > 2 &&
          cover.contains(a.trim().toLowerCase())) {
        coverNamesAnswer.add(q.id);
      }
      if (q.speech != null && _tok(q.speech!, a)) speechIsAnswer.add(q.id);
    }
    // ignore: avoid_print
    print(
        'S2 answer-in-prompt (${inPrompt.length}): ${inPrompt.take(25).toList()}\n'
        'S2 glyph==answer (${equalsGlyph.length}): ${equalsGlyph.take(25).toList()}\n'
        'S2 answer-in-passage non-reading (${inPassageNonStory.length}): ${inPassageNonStory.take(25).toList()}\n'
        'S2 prompt-picture file name contains answer (${coverNamesAnswer.length}): ${coverNamesAnswer.take(25).toList()}\n'
        'S2 speech contains answer token (${speechIsAnswer.length}): ${speechIsAnswer.take(25).toList()}');
    // The first four are true leaks on screen; speech is the Listen button, by design,
    // only reported (listening questions are answered by listening).
    expect(inPrompt, isEmpty, reason: 'answer appears in the visible prompt');
    expect(coverNamesAnswer, isEmpty,
        reason: 'prompt picture is named after the answer');
  });

  test('S2b glyph that equals the answer, split by type', () {
    final byType = <String, int>{};
    for (final q in bank.questions) {
      if (q.isParentMarked) continue;
      if (q.glyph != null && q.glyph!.trim() == q.correctAnswer.trim()) {
        byType[q.type.name] = (byType[q.type.name] ?? 0) + 1;
      }
    }
    // ignore: avoid_print
    print('S2b glyph==answer by type: $byType');
  });

  test(
      'S3 bank structural checks: unique ids, answer among options, unique options, picture files declared',
      () {
    final ids = <String>{};
    for (final q in bank.questions) {
      expect(ids.add(q.id), isTrue, reason: 'duplicate id ${q.id}');
      if (q.isParentMarked) continue;
      expect(q.options, contains(q.correctAnswer), reason: q.id);
      expect(q.options.toSet().length, q.options.length, reason: q.id);
      expect(q.options.length, greaterThanOrEqualTo(2), reason: q.id);
    }
    final dist = <int, int>{};
    var firstCorrect = 0;
    var total3 = 0;
    for (final q in bank.questions) {
      if (q.isParentMarked || q.options.length < 3) continue;
      total3++;
      if (q.options.first == q.correctAnswer) firstCorrect++;
      dist[q.options.length] = (dist[q.options.length] ?? 0) + 1;
    }
    // ignore: avoid_print
    print(
        'S3 option-count distribution $dist ; correct stored FIRST in $firstCorrect of $total3 (before shuffle)');
  });

  test(
      'S4 a real exam of the whole of Level 1 English hides nothing it should not show: options shuffled, answer position spread',
      () {
    final cfgx = ExamConfig(
      id: 'x',
      childId: 'k',
      level: 1,
      type: ExamType.subject,
      worlds: const ['english'],
      questionCount: 20,
      passPercent: 60,
      createdAt: DateTime(2026),
    );
    var first = 0, n = 0;
    for (var seed = 1; seed <= 20; seed++) {
      final o = ExamSelection.build(
          config: cfgx,
          bank: bank.questions,
          seed: seed,
          attemptId: 'a$seed',
          now: DateTime(2026));
      if (o is! SelectionOk) continue;
      for (final q in o.attempt.questions) {
        if (q.options.length >= 3) {
          n++;
          if (q.options.first == q.correctAnswer) first++;
        }
      }
    }
    // ignore: avoid_print
    print(
        'S4 correct answer shown FIRST in $first of $n option lists across 20 seeds');
    expect(first / n, lessThan(0.55));
  });
}
