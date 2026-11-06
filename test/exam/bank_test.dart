import 'package:flutter/material.dart' show Color;
import 'package:aksharamala/src/batch/batch_content.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/exam/models.dart';
import 'package:aksharamala/src/exam/question_bank.dart';
import 'package:aksharamala/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final worlds = worldsWithBatch(worldsWithAge56(curriculum));
  final bank = ExamQuestionBank.fromWorlds(worlds);

  test('bank size per level and world (printed for the report)', () {
    final lines = <String>[];
    for (final r in bank.coverage(worlds)) {
      lines.add('L${r.level} ${r.worldId}: lessons=${r.lessons} '
          'withQ=${r.lessonsWithQuestions} q=${r.questions} '
          'parent=${r.parentMarked} pending=${r.educatorPending} '
          'tts=${r.ttsUnverified}');
    }
    // ignore: avoid_print
    print(lines.join('\n'));
    // ignore: avoid_print
    print('total=${bank.questions.length} rejected=${bank.rejected.length} '
        '${bank.rejected.map((r) => '${r.id}:${r.reason}').take(20).join(' | ')}');
    expect(bank.questions, isNotEmpty);
  });

  test('ids are unique and stable in form', () {
    final ids = bank.questions.map((q) => q.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final q in bank.questions) {
      expect(q.id, matches(RegExp(r'^.+#q\d+$')));
      expect(q.id.startsWith('${q.lessonId}#q'), isTrue);
    }
  });

  test('every auto-marked question: answer among unique options, >= 2 options',
      () {
    for (final q in bank.questions.where((q) => !q.isParentMarked)) {
      expect(q.options.length, greaterThanOrEqualTo(2), reason: q.id);
      expect(q.options.toSet().length, q.options.length, reason: q.id);
      expect(q.options, contains(q.correctAnswer), reason: q.id);
      expect(q.optionPictures.keys.every(q.options.contains), isTrue,
          reason: q.id);
      expect(q.prompt.trim(), isNotEmpty, reason: q.id);
      expect(q.difficulty, inInclusiveRange(1, 3));
      expect(q.marks, greaterThan(0));
    }
  });

  test('all machineChecked, none educatorVerified', () {
    for (final q in bank.questions) {
      expect(q.verification, contains(Verification.machineChecked),
          reason: q.id);
      expect(q.verification, isNot(contains(Verification.educatorVerified)),
          reason: q.id);
    }
  });

  test('Telugu/Hindi/Tamil questions are educatorPending', () {
    final regional = bank.questions
        .where((q) => const {'telugu', 'hindi', 'tamil'}.contains(q.world));
    expect(regional, isNotEmpty);
    for (final q in regional) {
      expect(q.verification, contains(Verification.educatorPending),
          reason: q.id);
    }
    final english = bank.questions.where((q) => q.world == 'english');
    for (final q in english) {
      expect(q.verification, isNot(contains(Verification.educatorPending)),
          reason: q.id);
    }
  });

  test('speech-bearing questions carry ttsUnverified, others do not', () {
    for (final q in bank.questions) {
      expect(
          q.verification.contains(Verification.ttsUnverified), q.speech != null,
          reason: q.id);
    }
  });

  test('Level 5 bank is empty; nothing invented', () {
    expect(bank.forLevel(5), isEmpty);
    expect(bank.countsByLevel()[5], 0);
    expect(
        bank
            .coverage(worlds)
            .where((r) => r.level == 5)
            .every((r) => r.questions == 0),
        isTrue);
  });

  test('every question comes from a lesson that exists in the app', () {
    final lessonIds = {
      for (final w in worlds)
        for (final l in w.lessons) l.id
    };
    for (final q in bank.questions) {
      expect(lessonIds, contains(q.lessonId));
    }
  });

  test('arithmetic is recomputed: a wrong stored answer is rejected', () {
    final lesson = Lesson(
      id: 'x-add',
      title: 'Bad add',
      subtitle: '',
      kind: LessonKind.game,
      symbol: '2 + 3',
      speech: 'x',
      locale: 'en-IN',
      challenge: '2 + 3 = ?',
      options: const ['4', '6', '7'],
      answer: '6',
      ageBands: const {ExperienceStage.creator},
    );
    final w = LearningWorld(
      id: 'numbers',
      name: 'N',
      emoji: '',
      assetPath: '',
      color: const Color(0xFF000000),
      darkColor: const Color(0xFF000000),
      description: '',
      lessons: [lesson],
    );
    final b = ExamQuestionBank.fromWorlds([w]);
    expect(b.questions, isEmpty);
    expect(b.rejected.single.reason, contains('differs from computed'));
  });

  test('arithmetic questions carry the computed answer', () {
    final adds =
        bank.questions.where((q) => q.type == ExamQuestionType.arithmetic);
    expect(adds, isNotEmpty);
    final plus = RegExp(r'^(\d+) \+ (\d+) = \?$');
    var checked = 0;
    for (final q in adds) {
      final m = plus.firstMatch(q.prompt);
      if (m == null) continue;
      expect(q.correctAnswer,
          '${int.parse(m.group(1)!) + int.parse(m.group(2)!)}');
      checked++;
    }
    expect(checked, greaterThan(0));
  });

  test('handwriting steps are parent-marked, never auto-marked', () {
    final pm = bank.questions.where((q) => q.isParentMarked).toList();
    expect(pm, isNotEmpty);
    for (final q in pm) {
      expect(q.options, isEmpty);
      expect(q.type, ExamQuestionType.parentMarked);
    }
    expect(bank.forLevel(1).any((q) => q.isParentMarked), isFalse);
  });

  test('questions round-trip through JSON', () {
    for (final q in bank.questions.take(50)) {
      final again = ExamQuestion.fromJson(q.toJson());
      expect(again.toJson(), q.toJson());
    }
  });
}
