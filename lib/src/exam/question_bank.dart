/// The question bank: derived from implemented lessons only. Nothing is
/// authored or invented here and no translation is added.
///
/// Every question is checked by code (answer among the options, options
/// unique, at least two options, arithmetic recomputed) and only then marked
/// `machineChecked`. Regional-language questions are `educatorPending`;
/// questions spoken by the phone's voice are `ttsUnverified`; none is ever
/// `educatorVerified`.
library;

import '../batch/batch_content.dart';
import '../batch/batch_lesson.dart';
import '../curriculum.dart';
import '../levels.dart';
import '../models.dart';
import 'models.dart';

/// A lesson step the bank turned away, and why. Kept so the coverage report
/// can say what was left out.
class RejectedQuestion {
  const RejectedQuestion(this.id, this.reason);

  final String id;
  final String reason;
}

/// Questions available for one level and world.
class CoverageRow {
  const CoverageRow({
    required this.level,
    required this.worldId,
    required this.worldName,
    required this.lessons,
    required this.lessonsWithQuestions,
    required this.questions,
    required this.parentMarked,
    required this.educatorPending,
    required this.ttsUnverified,
    required this.educatorVerified,
  });

  final int level;
  final String worldId;
  final String worldName;
  final int lessons;
  final int lessonsWithQuestions;

  /// Auto-marked questions.
  final int questions;

  /// Handwriting items the parent marks (not counted in [questions]).
  final int parentMarked;
  final int educatorPending;
  final int ttsUnverified;
  final int educatorVerified;
}

class ExamQuestionBank {
  ExamQuestionBank._(this.questions, this.rejected, this._lessonCounts);

  /// The bank for the whole app: the same lessons the app offers.
  factory ExamQuestionBank.defaults() => ExamQuestionBank.fromWorlds(
      worldsWithBatch(worldsWithLevel3(worldsWithAge56(curriculum))));

  /// A bank made of ready questions (tests and previews).
  factory ExamQuestionBank.fromQuestions(List<ExamQuestion> questions) =>
      ExamQuestionBank._(List.unmodifiable(questions), const [], const {});

  factory ExamQuestionBank.fromWorlds(List<LearningWorld> worlds) {
    final questions = <ExamQuestion>[];
    final rejected = <RejectedQuestion>[];
    final lessonCounts = <String, int>{};
    for (final world in worlds) {
      for (final lesson in world.lessons) {
        for (final level in lesson.levels) {
          final key = '$level|${world.id}';
          lessonCounts[key] = (lessonCounts[key] ?? 0) + 1;
        }
        final drafts = lesson is BatchLesson
            ? _fromBatch(world, lesson)
            : _fromPlain(world, lesson);
        for (final d in drafts) {
          if (d.skipReason != null) {
            rejected.add(RejectedQuestion(d.question.id, d.skipReason!));
            continue;
          }
          final problem = _problem(d.question) ?? _leak(d.question);
          if (problem != null) {
            rejected.add(RejectedQuestion(d.question.id, problem));
          } else {
            questions.add(_stamp(_sightMatching(d.question)));
          }
        }
      }
    }
    return ExamQuestionBank._(List.unmodifiable(questions),
        List.unmodifiable(rejected), lessonCounts);
  }

  final List<ExamQuestion> questions;
  final List<RejectedQuestion> rejected;
  final Map<String, int> _lessonCounts;

  /// Auto-marked questions of [level] (empty for a level with no lessons,
  /// such as Level 5).
  List<ExamQuestion> forLevel(int level) => [
        for (final q in questions)
          if (q.levels.contains(level) && !q.isParentMarked) q
      ];

  ExamQuestion? byId(String id) {
    for (final q in questions) {
      if (q.id == id) return q;
    }
    return null;
  }

  /// Coverage per level and world, for every world at every level 1-5 (rows
  /// with zero questions are kept: they say "nothing yet").
  List<CoverageRow> coverage(List<LearningWorld> worlds) {
    final rows = <CoverageRow>[];
    for (var level = firstLevel; level <= lastLevel; level++) {
      for (final world in worlds) {
        final qs = [
          for (final q in questions)
            if (q.world == world.id && q.levels.contains(level)) q,
        ];
        final auto = qs.where((q) => !q.isParentMarked).toList();
        rows.add(CoverageRow(
          level: level,
          worldId: world.id,
          worldName: world.name,
          lessons: _lessonCounts['$level|${world.id}'] ?? 0,
          lessonsWithQuestions: {for (final q in auto) q.lessonId}.length,
          questions: auto.length,
          parentMarked: qs.length - auto.length,
          educatorPending: auto
              .where(
                  (q) => q.verification.contains(Verification.educatorPending))
              .length,
          ttsUnverified: auto
              .where((q) => q.verification.contains(Verification.ttsUnverified))
              .length,
          educatorVerified: auto
              .where(
                  (q) => q.verification.contains(Verification.educatorVerified))
              .length,
        ));
      }
    }
    return rows;
  }

  /// Auto-marked questions per level.
  Map<int, int> countsByLevel() => {
        for (var l = firstLevel; l <= lastLevel; l++) l: forLevel(l).length,
      };
}

// -- Derivation -------------------------------------------------------------

class _Draft {
  const _Draft(this.question, [this.skipReason]);

  final ExamQuestion question;

  /// Set when a step was recognised but cannot become a question; the draft
  /// then only carries an id for the report.
  final String? skipReason;
}

bool _regional(LearningWorld world, Lesson lesson) {
  final locale = lesson.locale.toLowerCase();
  return locale.startsWith('te') ||
      locale.startsWith('hi') ||
      locale.startsWith('ta') ||
      const {'telugu', 'hindi', 'tamil'}.contains(world.id);
}

int _difficulty(Lesson lesson) => switch (lesson.difficultyLevel) {
      LessonDifficulty.foundation => 1,
      LessonDifficulty.beginner => 2,
      LessonDifficulty.intermediate => 2,
      LessonDifficulty.advanced => 3,
    };

Set<Verification> _flags(LearningWorld world, Lesson lesson, String? speech) =>
    {
      if (_regional(world, lesson)) Verification.educatorPending,
      if (speech != null) Verification.ttsUnverified,
    };

/// Adds `machineChecked` once the checks have passed.
ExamQuestion _stamp(ExamQuestion q) => ExamQuestion(
      id: q.id,
      lessonId: q.lessonId,
      lessonTitle: q.lessonTitle,
      level: q.level,
      levels: q.levels,
      world: q.world,
      topic: q.topic,
      objective: q.objective,
      type: q.type,
      prompt: q.prompt,
      speech: q.speech,
      passage: q.passage,
      glyph: q.glyph,
      quantity: q.quantity,
      promptPicture: q.promptPicture,
      options: q.options,
      correctAnswer: q.correctAnswer,
      difficulty: q.difficulty,
      marks: q.marks,
      explanation: q.explanation,
      optionPictures: q.optionPictures,
      verification: {...q.verification, Verification.machineChecked},
    );

/// Why a drafted question fails the checks, or null.
String? _problem(ExamQuestion q) {
  if (q.prompt.trim().isEmpty) return 'empty prompt';
  if (q.isParentMarked) return null;
  final options = q.options.map((o) => o.trim()).toList();
  if (options.length < 2) return 'fewer than two options';
  if (options.toSet().length != options.length) return 'duplicate options';
  if (options.any((o) => o.isEmpty)) return 'empty option';
  if (!options.contains(q.correctAnswer.trim()))
    return 'answer is not among the options';
  if (q.optionPictures.keys.any((k) => !options.contains(k))) {
    return 'picture for an option that does not exist';
  }
  return null;
}

/// A question whose visible prompt already contains the answer would show
/// it to the child. Arithmetic prompts are exempt (the answer follows `=`).
String? _leak(ExamQuestion q) {
  if (q.isParentMarked || q.type == ExamQuestionType.arithmetic) return null;
  if (_containsToken(q.prompt, q.correctAnswer))
    return 'answer visible in prompt';
  return null;
}

/// A large symbol equal to the correct option is sight matching: kept, but
/// the easiest kind and labelled as recognition.
ExamQuestion _sightMatching(ExamQuestion q) {
  final g = q.glyph?.trim();
  if (q.isParentMarked ||
      g == null ||
      g.isEmpty ||
      g != q.correctAnswer.trim()) {
    return q;
  }
  return ExamQuestion(
    id: q.id,
    lessonId: q.lessonId,
    lessonTitle: q.lessonTitle,
    level: q.level,
    levels: q.levels,
    world: q.world,
    topic: q.topic,
    objective: q.objective,
    type: ExamQuestionType.recognition,
    prompt: q.prompt,
    speech: q.speech,
    passage: q.passage,
    glyph: q.glyph,
    quantity: q.quantity,
    promptPicture: q.promptPicture,
    options: q.options,
    correctAnswer: q.correctAnswer,
    difficulty: 1,
    marks: q.marks,
    explanation: q.explanation,
    optionPictures: q.optionPictures,
    verification: q.verification,
  );
}

String _norm(String s) => s.trim();

Map<String, String> _picturesFor(
        List<String> options, Map<String, String> pictures) =>
    {
      for (final o in options)
        if (pictures.containsKey(o)) o: pictures[o]!,
    };

bool _containsToken(String text, String answer) {
  final a = answer.trim().toLowerCase();
  if (a.isEmpty) return false;
  final tokens = text
      .toLowerCase()
      .split(RegExp(r'[\s.,;:!?()\[\]"]+'))
      .where((t) => t.isNotEmpty);
  return tokens.contains(a);
}

// -- Arithmetic recomputation ----------------------------------------------

class _Calc {
  const _Calc(this.answer, this.explanation, {this.isPattern = false});

  final String answer;
  final String explanation;
  final bool isPattern;
}

/// Recognises a prompt the code can solve itself and returns the answer it
/// computes, or null when the prompt is not arithmetic.
_Calc? _recompute(String raw) {
  final p = raw
      .replaceAll('−', '-')
      .replaceAll('–', '-')
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .trim();

  final op = RegExp(r'^(\d+)\s*([+\-*/])\s*(\d+)\s*=\s*\?$').firstMatch(p);
  if (op != null) {
    final a = int.parse(op.group(1)!);
    final b = int.parse(op.group(3)!);
    final sign = op.group(2)!;
    int? r;
    switch (sign) {
      case '+':
        r = a + b;
      case '-':
        r = a - b;
      case '*':
        r = a * b;
      case '/':
        r = (b != 0 && a % b == 0) ? a ~/ b : null;
    }
    if (r == null) return const _Calc('', 'not a whole-number division');
    final shown =
        sign == '*' ? '×' : (sign == '/' ? '÷' : (sign == '-' ? '−' : '+'));
    return _Calc('$r', '$a $shown $b = $r');
  }

  final half = RegExp(r'½ of (\d+)').firstMatch(p);
  if (half != null) {
    final n = int.parse(half.group(1)!);
    if (n.isOdd) return const _Calc('', 'half is not a whole number');
    return _Calc('${n ~/ 2}', 'Half of $n is ${n ~/ 2}.');
  }

  final percent = RegExp(r'(\d+)\s*% of (\d+)').firstMatch(p);
  if (percent != null) {
    final pc = int.parse(percent.group(1)!);
    final n = int.parse(percent.group(2)!);
    if ((pc * n) % 100 != 0) return const _Calc('', 'percentage is not whole');
    return _Calc('${pc * n ~/ 100}', '$pc% of $n is ${pc * n ~/ 100}.');
  }

  final sign = RegExp(r'sign:\s*(\d+)\s*_+\s*(\d+)').firstMatch(p);
  if (sign != null) {
    final a = int.parse(sign.group(1)!);
    final b = int.parse(sign.group(2)!);
    final s = a < b ? '<' : (a > b ? '>' : '=');
    return _Calc(s, '$a $s $b');
  }

  final tens = RegExp(r'How many tens are in (\d+)').firstMatch(p);
  if (tens != null) {
    final n = int.parse(tens.group(1)!);
    return _Calc('${n ~/ 10}', 'There are ${n ~/ 10} tens in $n.');
  }

  final cmp =
      RegExp(r'Which number is (bigger|smaller): (\d+) or (\d+)').firstMatch(p);
  if (cmp != null) {
    final a = int.parse(cmp.group(2)!);
    final b = int.parse(cmp.group(3)!);
    final big = cmp.group(1) == 'bigger';
    final r = big ? (a > b ? a : b) : (a < b ? a : b);
    return _Calc('$r', 'The ${cmp.group(1)} number is $r.');
  }

  final next = RegExp(r'What comes next:\s*((?:\d+\s*,\s*)+)_+').firstMatch(p);
  if (next != null) {
    final nums = [
      for (final s in next.group(1)!.split(','))
        if (s.trim().isNotEmpty) int.parse(s.trim()),
    ];
    if (nums.length >= 3) {
      final d = nums[1] - nums[0];
      final steady = [
        for (var i = 2; i < nums.length; i++) nums[i] - nums[i - 1] == d
      ].every((x) => x);
      if (steady) {
        final r = nums.last + d;
        return _Calc(
            '$r', 'The pattern changes by $d each time, so next is $r.',
            isPattern: true);
      }
    }
    return const _Calc('', 'pattern is not a steady count');
  }
  return null;
}

String _defaultExplanation(String answer, String objective) =>
    'The correct answer is $answer.${objective.isEmpty ? '' : ' Lesson aim: $objective'}';

// -- Plain lessons ----------------------------------------------------------

List<_Draft> _fromPlain(LearningWorld world, Lesson lesson) {
  final id = '${lesson.id}#q0';
  if (lesson.options.isEmpty || lesson.answer.isEmpty) {
    // Tracing and other activities without a quiz are not exam questions.
    return const [];
  }
  final options = [for (final o in lesson.options) _norm(o)];
  var answer = _norm(lesson.answer);
  var type = ExamQuestionType.multipleChoice;
  var explanation = _defaultExplanation(answer, lesson.learningObjective);
  String? speech;
  String? passage;
  String? glyph;
  int? quantity;
  final pictures = _picturesFor(options, lesson.pictures);

  final calc = _recompute(lesson.challenge);
  if (calc != null) {
    if (calc.answer.isEmpty) {
      return [
        _Draft(_stub(world, lesson, id),
            'arithmetic not computable: ${calc.explanation}')
      ];
    }
    if (calc.answer != answer) {
      return [
        _Draft(_stub(world, lesson, id),
            'stored answer "$answer" differs from computed "${calc.answer}"'),
      ];
    }
    answer = calc.answer;
    type = ExamQuestionType.arithmetic;
    explanation = calc.explanation;
  } else if (lesson.kind == LessonKind.story) {
    passage = lesson.story.isNotEmpty ? lesson.story.join(' ') : lesson.speech;
  } else if (lesson.symbol == '?') {
    // "Which letter is this?" is answered by listening to the letter.
    type = ExamQuestionType.listening;
    speech = lesson.speech;
  } else if (lesson.kind != LessonKind.numbers &&
      lesson.pictures.isNotEmpty &&
      !lesson.challenge.contains(lesson.symbol) &&
      lesson.speech.isNotEmpty) {
    // "Pick the word for the picture": the word is spoken.
    type = ExamQuestionType.listening;
    speech = lesson.speech;
  } else if (lesson.kind == LessonKind.numbers && lesson.symbol.contains('★')) {
    // The stars in the symbol are the thing to count; recompute the count.
    quantity = '★'.allMatches(lesson.symbol).length;
    if ('$quantity' != answer) {
      return [
        _Draft(_stub(world, lesson, id),
            'stored answer "$answer" differs from counted "$quantity"'),
      ];
    }
    type = ExamQuestionType.arithmetic;
    explanation = 'There are $quantity stars.';
  } else if (lesson.challenge.contains('_')) {
    type = ExamQuestionType.fillBlank;
    glyph = null;
  } else if (pictures.isNotEmpty) {
    type = ExamQuestionType.pictureIdentification;
  }

  if (type == ExamQuestionType.multipleChoice && pictures.isNotEmpty) {
    type = ExamQuestionType.pictureIdentification;
  }

  if (glyph == null &&
      quantity == null &&
      type != ExamQuestionType.arithmetic &&
      lesson.symbol != '?' &&
      lesson.kind == LessonKind.alphabet &&
      !lesson.challenge.contains(lesson.symbol)) {
    glyph = lesson.symbol;
  }

  return [
    _Draft(ExamQuestion(
      id: id,
      lessonId: lesson.id,
      lessonTitle: lesson.title,
      level: (lesson.levels.toList()..sort()).first,
      levels: lesson.levels,
      world: world.id,
      topic: lesson.kind.name,
      objective: lesson.learningObjective,
      type: type,
      prompt: lesson.challenge,
      speech: speech,
      passage: passage,
      glyph: glyph,
      quantity: quantity,
      promptPicture: lesson.cover,
      options: options,
      correctAnswer: answer,
      difficulty: _difficulty(lesson),
      explanation: explanation,
      optionPictures: pictures,
      verification: _flags(world, lesson, speech),
    )),
  ];
}

ExamQuestion _stub(LearningWorld world, Lesson lesson, String id) =>
    ExamQuestion(
      id: id,
      lessonId: lesson.id,
      level: (lesson.levels.toList()..sort()).first,
      world: world.id,
      topic: '',
      objective: '',
      type: ExamQuestionType.multipleChoice,
      prompt: '-',
      correctAnswer: '',
    );

// -- Batch lessons ----------------------------------------------------------

List<_Draft> _fromBatch(LearningWorld world, BatchLesson lesson) {
  final out = <_Draft>[];
  final levels = lesson.levels;
  final level = (levels.toList()..sort()).first;
  final topic = lesson.topic.isNotEmpty ? lesson.topic : lesson.kind.name;
  for (var i = 0; i < lesson.steps.length; i++) {
    final s = lesson.steps[i];
    final id = '${lesson.id}#q$i';
    if (s.kind == StepKind.listen) continue;

    if (s.kind == StepKind.write) {
      // Handwriting is never auto-marked: the parent marks it.
      out.add(_Draft(ExamQuestion(
        id: id,
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        level: level,
        levels: levels,
        world: world.id,
        topic: topic,
        objective: lesson.learningObjective,
        type: ExamQuestionType.parentMarked,
        prompt: s.prompt,
        speech: s.speech.isEmpty ? null : s.speech,
        glyph: s.glyph,
        correctAnswer: 'correct',
        difficulty: _difficulty(lesson),
        explanation: 'The parent marks this: was it written correctly?',
        verification: _flags(world, lesson, s.speech.isEmpty ? null : s.speech),
      )));
      continue;
    }

    final options = [for (final o in s.options) _norm(o)];
    var answer = _norm(s.answer);
    var type = ExamQuestionType.multipleChoice;
    var explanation = _defaultExplanation(answer, lesson.learningObjective);
    int? quantity;
    final pictures = _picturesFor(options, s.pictures);

    String? skip;
    final calc = _recompute(s.prompt);
    switch (s.kind) {
      case StepKind.count:
        quantity = s.quantity;
        if (quantity == null || '$quantity' != answer) {
          skip = 'count answer "$answer" differs from quantity $quantity';
        }
        type = ExamQuestionType.arithmetic;
        explanation = 'There are $quantity stars.';
      case StepKind.pickQuantity:
        if (s.glyph == null || s.glyph != answer) {
          skip = 'pickQuantity answer "$answer" differs from the number asked';
        }
        type = ExamQuestionType.arithmetic;
        explanation = 'The group with $answer stars is the right one.';
      case StepKind.compare:
        if (calc == null || calc.answer.isEmpty) {
          skip = 'compare prompt could not be recomputed';
        } else if (calc.answer != answer) {
          skip =
              'stored answer "$answer" differs from computed "${calc.answer}"';
        } else {
          explanation = calc.explanation;
        }
        type = ExamQuestionType.arithmetic;
      case StepKind.pickLetter:
        type = pictures.isNotEmpty
            ? ExamQuestionType.pictureIdentification
            : ExamQuestionType.multipleChoice;
      case StepKind.pickWord:
        type = pictures.isNotEmpty
            ? ExamQuestionType.pictureIdentification
            : ExamQuestionType.multipleChoice;
      case StepKind.choice:
        if (calc != null) {
          if (calc.answer.isEmpty) {
            skip = 'arithmetic not computable: ${calc.explanation}';
          } else if (calc.answer != answer) {
            skip =
                'stored answer "$answer" differs from computed "${calc.answer}"';
          } else {
            type = ExamQuestionType.arithmetic;
            explanation = calc.explanation;
          }
        } else if (s.prompt.contains('__') || s.prompt.contains(' _ ')) {
          type = ExamQuestionType.fillBlank;
        } else if (pictures.isNotEmpty) {
          type = ExamQuestionType.pictureIdentification;
        }
      case StepKind.listen:
      case StepKind.write:
        break;
    }

    // The spoken line is offered only when it does not give the answer away.
    final speech = (s.speech.isEmpty || _containsToken(s.speech, answer))
        ? null
        : s.speech;

    final q = ExamQuestion(
      id: id,
      lessonId: lesson.id,
      lessonTitle: lesson.title,
      level: level,
      levels: levels,
      world: world.id,
      topic: topic,
      objective: lesson.learningObjective,
      type: type,
      prompt: s.prompt,
      speech: speech,
      glyph: s.kind == StepKind.pickLetter || s.kind == StepKind.pickWord
          ? s.glyph
          : null,
      quantity: quantity,
      options: options,
      correctAnswer: answer,
      difficulty: _difficulty(lesson),
      explanation: explanation,
      optionPictures: pictures,
      verification: _flags(world, lesson, speech),
    );
    out.add(skip == null ? _Draft(q) : _Draft(q, skip));
  }
  return out;
}
