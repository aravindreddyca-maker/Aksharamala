import '../models.dart';
import 'batch_lesson.dart';

/// One multiple-choice question of a Level 3 lesson.
class L3Q {
  const L3Q(this.prompt, this.options, this.answer);

  final String prompt;
  final List<String> options;
  final String answer;
}

/// A Level 3 (ages 7-9) or Level 4 (ages 10-12, pass `ageBand: '10-12'`) lesson; Level 5 passes `ageBand: '10-12', level: 5`: a short teaching line, then [questions] to
/// answer. Level 3 English and Number Galaxy lessons are written in code, so
/// their answers can be checked by tests (see test/level3_content_test.dart).
BatchLesson level3Lesson({
  required String id,
  required String module,
  required String title,
  required String objective,
  required String topic,
  required String skill,
  required String teach,
  required List<L3Q> questions,
  List<String> examples = const [],
  String? symbol,
  String? locale,
  String ageBand = '7-9',
  int? level,
}) {
  final numbers = module == 'numbers';
  return BatchLesson(
    id: id,
    title: title,
    subtitle: objective,
    kind: numbers ? LessonKind.game : LessonKind.words,
    symbol: symbol ?? (examples.isNotEmpty ? examples.first : title),
    locale: locale ?? (numbers ? 'en-IN' : 'en-US'),
    ageBand: ageBand,
    // Level 5 has no age band of its own: it is named by level.
    levelSet: level == null ? null : {level},
    difficultyLevel: LessonDifficulty.intermediate,
    learningObjective: objective,
    topic: topic,
    skill: skill,
    examples: examples,
    educatorReviewVerified: false,
    sourceRecords: [id],
    steps: [
      BatchStep(
        kind: StepKind.listen,
        prompt: teach,
        speech: teach,
        glyph: symbol ?? (examples.isNotEmpty ? examples.first : title),
        sourceRecord: id,
      ),
      for (final q in questions)
        BatchStep(
          kind: StepKind.choice,
          prompt: q.prompt,
          speech: q.prompt,
          options: q.options,
          answer: q.answer,
          sourceRecord: id,
        ),
    ],
  );
}
