/// A lesson made of steps: listen, pick, count, compare, write. The first
/// batch (ten Telugu lessons and Number Galaxy 0-10) is built from these.
///
/// A [BatchLesson] *is* a [Lesson], so the quest map, stars, badges and saved
/// progress treat it like any other quest. Only the screen that plays it
/// differs.
library;

import '../models.dart';

enum StepKind {
  /// See and hear the letter or number. Nothing to answer.
  listen,

  /// Pick the matching letter from letters.
  pickLetter,

  /// Pick the picture word that starts with the letter.
  pickWord,

  /// Pick the group of stars that shows the number.
  pickQuantity,

  /// Tap each star to count, then pick the number.
  count,

  /// Pick the bigger or smaller of two numbers.
  compare,

  /// Write the letter or number on the pad.
  write,
}

extension StepKindX on StepKind {
  /// Steps a child must get right for the lesson to count as finished.
  /// Writing is practice only until a teacher verifies the stroke templates.
  bool get isRequired => this != StepKind.listen && this != StepKind.write;

  bool get isQuestion => isRequired;
}

enum WriteMode {
  /// A guide is shown and the child writes on it.
  guided,

  /// No guide: the child writes from memory.
  independent,
}

class BatchStep {
  const BatchStep({
    required this.kind,
    required this.prompt,
    required this.speech,
    this.options = const [],
    this.answer = '',
    this.pictures = const {},
    this.quantity,
    this.glyph,
    this.writeMode = WriteMode.guided,
    this.sourceRecord,
  });

  final StepKind kind;

  /// What the child reads, in the lesson's language.
  final String prompt;

  /// What the Listen button says.
  final String speech;

  /// Answer choices (questions only). The right answer is `answer`; the screen
  /// shuffles the order every time.
  final List<String> options;
  final String answer;

  /// Option -> bundled picture path. An option with no picture (or a picture
  /// that does not exist yet) is shown as its word.
  final Map<String, String> pictures;

  /// Stars to show (count steps, listen step for numbers).
  final int? quantity;

  /// The letter or number being heard or written.
  final String? glyph;

  final WriteMode writeMode;

  /// The record in the content pack this step comes from, for traceability.
  final String? sourceRecord;
}

class BatchLesson extends Lesson {
  BatchLesson({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.kind,
    required super.symbol,
    required super.locale,
    required this.steps,
    required this.sourceRecords,
    super.prerequisites = const [],
    this.ageBand = '3-4',
  }) : super(
          speech: steps.first.speech,
          challenge: steps.firstWhere((s) => s.kind.isQuestion).prompt,
          options: const [],
          answer: '',
          ageBands: {_stageForAgeBand(ageBand)},
          difficultyLevel: LessonDifficulty.foundation,
          learningObjective: 'Complete the guided ${kind.name} sequence.',
        );

  final List<BatchStep> steps;

  /// Every pack record this lesson draws on; each must exist in the pack.
  final List<String> sourceRecords;

  final String ageBand;

  List<BatchStep> get questions =>
      steps.where((s) => s.kind.isQuestion).toList();
}

ExperienceStage _stageForAgeBand(String ageBand) => switch (ageBand) {
      '3-4' => ExperienceStage.explorer,
      '5-6' => ExperienceStage.creator,
      '7-9' => ExperienceStage.scholar,
      '10-12' => ExperienceStage.champion,
      _ => throw ArgumentError.value(ageBand, 'ageBand'),
    };
