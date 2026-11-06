import 'dart:io';

import 'package:aksharamala/src/exam/exam_controller.dart';
import 'package:aksharamala/src/exam/exam_store.dart';
import 'package:aksharamala/src/exam/models.dart';
import 'package:aksharamala/src/exam/question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

/// A made-up question for tests (not part of the real bank).
ExamQuestion mq(
  String lesson,
  int n, {
  String world = 'w1',
  int level = 1,
  int difficulty = 1,
  String topic = 't',
  String? objective,
  ExamQuestionType type = ExamQuestionType.multipleChoice,
  Map<String, String> pictures = const {},
  String? cover,
}) {
  if (type == ExamQuestionType.parentMarked) {
    return ExamQuestion(
      id: '$lesson#q$n',
      lessonId: lesson,
      lessonTitle: 'Title $lesson',
      level: level,
      world: world,
      topic: topic,
      objective: objective ?? 'Objective $lesson',
      type: type,
      prompt: 'Write it',
      correctAnswer: 'correct',
      difficulty: difficulty,
      verification: const {Verification.machineChecked},
    );
  }
  return ExamQuestion(
    id: '$lesson#q$n',
    lessonId: lesson,
    lessonTitle: 'Title $lesson',
    level: level,
    world: world,
    topic: topic,
    objective: objective ?? 'Objective $lesson',
    type: type,
    prompt: 'Question $lesson $n',
    options: const ['A', 'B', 'C', 'D'],
    correctAnswer: 'A',
    difficulty: difficulty,
    optionPictures: pictures,
    promptPicture: cover,
    verification: const {Verification.machineChecked},
  );
}

/// [lessons] lessons with [perLesson] questions each.
List<ExamQuestion> makeBank({
  String world = 'w1',
  int lessons = 10,
  int perLesson = 3,
  String prefix = 'L',
  int level = 1,
  int Function(int lesson, int q)? difficulty,
}) =>
    [
      for (var l = 0; l < lessons; l++)
        for (var q = 0; q < perLesson; q++)
          mq('$prefix$l', q,
              world: world,
              level: level,
              difficulty: difficulty?.call(l, q) ?? 1),
    ];

ExamConfig cfg({
  String id = 'c1',
  String childId = 'kid',
  int level = 1,
  ExamType type = ExamType.subject,
  List<String> worlds = const ['w1'],
  List<String> lessonIds = const [],
  int count = 5,
  double pass = 60,
  double? perWorld,
  int? limit,
  RetestPolicy policy = const RetestPolicy.unlimited(),
  DifficultyMix mix = const DifficultyMix(easy: 1, medium: 1, hard: 1),
  bool parent = false,
}) =>
    ExamConfig(
      id: id,
      childId: childId,
      childName: 'Asha',
      level: level,
      type: type,
      worlds: worlds,
      lessonIds: lessonIds,
      questionCount: count,
      difficultyMix: mix,
      passPercent: pass,
      perWorldMinPercent: perWorld,
      timeLimitSeconds: limit,
      retestPolicy: policy,
      includeParentMarked: parent,
      createdAt: DateTime(2026, 1, 1),
    );

/// A clock tests can move.
class TestClock {
  TestClock([DateTime? start]) : now = start ?? DateTime(2026, 10, 31, 9);

  DateTime now;

  DateTime call() => now;

  void advance(Duration d) => now = now.add(d);
}

class TempEnv {
  TempEnv._(this.dir);

  final Directory dir;

  static Future<TempEnv> create() async =>
      TempEnv._(await Directory.systemTemp.createTemp('exam_test_'));

  File get examFile => File('${dir.path}/exams.json');
  File get progressFile => File('${dir.path}/progress.json');

  ExamStore newStore() => ExamStore(fileOverride: examFile);

  ExamController newController({
    required List<ExamQuestion> bank,
    TestClock? clock,
    ExamStore? store,
  }) =>
      ExamController(
        store: store ?? newStore(),
        bank: ExamQuestionBank.fromQuestions(bank),
        clock: clock?.call,
      );

  Future<void> dispose() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  List<String> fileNames() => dir
      .listSync()
      .map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last)
      .toList()
    ..sort();
}

/// Answers every question of the attempt: the first [right] correctly, the
/// rest wrongly.
Future<void> answerAll(
  ExamController c,
  ExamAttempt attempt, {
  required int right,
}) async {
  var i = 0;
  for (final q in attempt.questions) {
    if (q.isParentMarked) continue;
    final answer = i < right
        ? q.correctAnswer
        : q.options.firstWhere((o) => o != q.correctAnswer);
    expect(await c.answer(attempt.id, q.id, answer), isTrue);
    i++;
  }
}
