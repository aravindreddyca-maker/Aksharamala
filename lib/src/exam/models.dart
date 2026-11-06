/// Domain model of the parent examination system (no UI). See
/// `audit/EXAMINATION_SYSTEM_DESIGN.md`. Everything here is plain data with
/// `toJson`/`fromJson`; nothing touches lessons, stars or `progress.json`.
library;

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

List<String> _strings(Object? v) =>
    [for (final e in (v as List? ?? const [])) e as String];

// -- Config -----------------------------------------------------------------

enum ExamType { chapter, subject, finalLevel }

/// How often a test may be retaken.
enum RetestKind { unlimited, maxAttempts, waitHours }

class RetestPolicy {
  const RetestPolicy._(this.kind, this.value);

  const RetestPolicy.unlimited() : this._(RetestKind.unlimited, 0);

  /// At most [n] submitted attempts of the same exam scope.
  const RetestPolicy.maxAttempts(int n) : this._(RetestKind.maxAttempts, n);

  /// A new attempt only [n] hours after the last one was submitted.
  const RetestPolicy.waitHours(int n) : this._(RetestKind.waitHours, n);

  final RetestKind kind;
  final int value;

  Map<String, Object> toJson() => {'kind': kind.name, 'value': value};

  factory RetestPolicy.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RetestPolicy.unlimited();
    final kind =
        _enumByName(RetestKind.values, json['kind'], RetestKind.unlimited);
    return RetestPolicy._(kind, json['value'] as int? ?? 0);
  }

  @override
  bool operator ==(Object other) =>
      other is RetestPolicy && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);
}

/// Relative weights of easy / medium / hard questions (any non-negative
/// numbers; only the proportions matter).
class DifficultyMix {
  const DifficultyMix({this.easy = 50, this.medium = 30, this.hard = 20});

  final int easy;
  final int medium;
  final int hard;

  int weightFor(int difficulty) =>
      difficulty <= 1 ? easy : (difficulty == 2 ? medium : hard);

  Map<String, Object> toJson() =>
      {'easy': easy, 'medium': medium, 'hard': hard};

  factory DifficultyMix.fromJson(Map<String, dynamic>? json) => json == null
      ? const DifficultyMix()
      : DifficultyMix(
          easy: json['easy'] as int? ?? 50,
          medium: json['medium'] as int? ?? 30,
          hard: json['hard'] as int? ?? 20,
        );
}

class ExamConfig {
  const ExamConfig({
    required this.id,
    required this.childId,
    required this.level,
    required this.type,
    this.childName = '',
    this.worlds = const [],
    this.lessonIds = const [],
    required this.questionCount,
    this.difficultyMix = const DifficultyMix(),
    this.passPercent = 60,
    this.perWorldMinPercent,
    this.timeLimitSeconds,
    this.retestPolicy = const RetestPolicy.unlimited(),
    this.includeParentMarked = false,
    required this.createdAt,
  });

  final String id;
  final String childId;

  /// Name shown on a certificate (a snapshot, so later renames do not alter
  /// old results).
  final String childName;
  final int level;
  final ExamType type;

  /// World ids. Subject exams use these; final exams use them as the chosen
  /// worlds (empty = every world).
  final List<String> worlds;

  /// Chapter exams: the lessons chosen.
  final List<String> lessonIds;
  final int questionCount;
  final DifficultyMix difficultyMix;

  /// Configurable; the default is 60.
  final double passPercent;

  /// Final exams only: every chosen world must reach this too.
  final double? perWorldMinPercent;
  final int? timeLimitSeconds;
  final RetestPolicy retestPolicy;

  /// Include handwriting/speech items that the parent marks at the end.
  final bool includeParentMarked;
  final DateTime createdAt;

  /// Same scope = same exam for retest counting.
  String get scopeKey {
    final w = [...worlds]..sort();
    final l = [...lessonIds]..sort();
    return '${type.name}|$level|${w.join(',')}|${l.join(',')}';
  }

  ExamConfig copyWith({
    String? id,
    int? questionCount,
    double? passPercent,
    DateTime? createdAt,
    RetestPolicy? retestPolicy,
  }) =>
      ExamConfig(
        id: id ?? this.id,
        childId: childId,
        childName: childName,
        level: level,
        type: type,
        worlds: worlds,
        lessonIds: lessonIds,
        questionCount: questionCount ?? this.questionCount,
        difficultyMix: difficultyMix,
        passPercent: passPercent ?? this.passPercent,
        perWorldMinPercent: perWorldMinPercent,
        timeLimitSeconds: timeLimitSeconds,
        retestPolicy: retestPolicy ?? this.retestPolicy,
        includeParentMarked: includeParentMarked,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'childId': childId,
        'childName': childName,
        'level': level,
        'type': type.name,
        'worlds': worlds,
        'lessonIds': lessonIds,
        'questionCount': questionCount,
        'difficultyMix': difficultyMix.toJson(),
        'passPercent': passPercent,
        'perWorldMinPercent': perWorldMinPercent,
        'timeLimitSeconds': timeLimitSeconds,
        'retestPolicy': retestPolicy.toJson(),
        'includeParentMarked': includeParentMarked,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ExamConfig.fromJson(Map<String, dynamic> json) => ExamConfig(
        id: json['id'] as String,
        childId: json['childId'] as String,
        childName: json['childName'] as String? ?? '',
        level: json['level'] as int,
        type: _enumByName(ExamType.values, json['type'], ExamType.chapter),
        worlds: _strings(json['worlds']),
        lessonIds: _strings(json['lessonIds']),
        questionCount: json['questionCount'] as int,
        difficultyMix: DifficultyMix.fromJson(
            (json['difficultyMix'] as Map?)?.cast<String, dynamic>()),
        passPercent: (json['passPercent'] as num? ?? 60).toDouble(),
        perWorldMinPercent: (json['perWorldMinPercent'] as num?)?.toDouble(),
        timeLimitSeconds: json['timeLimitSeconds'] as int?,
        retestPolicy: RetestPolicy.fromJson(
            (json['retestPolicy'] as Map?)?.cast<String, dynamic>()),
        includeParentMarked: json['includeParentMarked'] as bool? ?? false,
        createdAt:
            _date(json['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

// -- Question ---------------------------------------------------------------

enum ExamQuestionType {
  multipleChoice,
  pictureIdentification,
  arithmetic,
  fillBlank,
  listening,
  parentMarked,

  /// Matching a shown symbol to its twin among the options (sight matching).
  recognition,
}

/// Flags on a question. A question may carry several.
enum Verification {
  /// The code checked the question (answer among options, options unique,
  /// arithmetic recomputed).
  machineChecked,

  /// Regional-language text nobody qualified has confirmed yet.
  educatorPending,

  /// A person recorded that an educator confirmed it. The bank never sets this.
  educatorVerified,

  /// The question is spoken by the phone's voice, whose pronunciation nobody
  /// has checked.
  ttsUnverified,
}

class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.lessonId,
    this.lessonTitle = '',
    required this.level,
    Set<int>? levels,
    required this.world,
    required this.topic,
    required this.objective,
    required this.type,
    required this.prompt,
    this.speech,
    this.passage,
    this.glyph,
    this.quantity,
    this.promptPicture,
    this.options = const [],
    required this.correctAnswer,
    this.difficulty = 1,
    this.marks = 1,
    this.explanation = '',
    this.optionPictures = const {},
    this.verification = const {},
  }) : _levels = levels;

  /// Stable: `<lessonId>#q<n>`.
  final String id;
  final String lessonId;
  final String lessonTitle;

  /// Lowest level the lesson belongs to; [levels] has all of them.
  final int level;
  final Set<int>? _levels;
  Set<int> get levels => _levels ?? {level};

  /// World id (the "subject").
  final String world;
  final String topic;
  final String objective;
  final ExamQuestionType type;
  final String prompt;

  /// What the Listen button may say. Null when the lesson's spoken line would
  /// give the answer away.
  final String? speech;

  /// Text to read before answering (story questions).
  final String? passage;

  /// A letter or symbol the screen shows with the prompt.
  final String? glyph;

  /// Stars to show (count questions).
  final int? quantity;

  /// A bundled picture shown with the prompt (a cover picture).
  final String? promptPicture;
  final List<String> options;

  /// For parent-marked questions this is `'correct'` and options are empty.
  final String correctAnswer;

  /// 1 easy, 2 medium, 3 hard.
  final int difficulty;
  final int marks;
  final String explanation;

  /// Option -> bundled picture path.
  final Map<String, String> optionPictures;
  final Set<Verification> verification;

  bool get isParentMarked => type == ExamQuestionType.parentMarked;
  bool get isRegionalPending =>
      verification.contains(Verification.educatorPending);

  ExamQuestion withOptions(List<String> newOptions) => ExamQuestion(
        id: id,
        lessonId: lessonId,
        lessonTitle: lessonTitle,
        level: level,
        levels: _levels,
        world: world,
        topic: topic,
        objective: objective,
        type: type,
        prompt: prompt,
        speech: speech,
        passage: passage,
        glyph: glyph,
        quantity: quantity,
        promptPicture: promptPicture,
        options: newOptions,
        correctAnswer: correctAnswer,
        difficulty: difficulty,
        marks: marks,
        explanation: explanation,
        optionPictures: optionPictures,
        verification: verification,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
        'level': level,
        'levels': (levels.toList()..sort()),
        'world': world,
        'topic': topic,
        'objective': objective,
        'type': type.name,
        'prompt': prompt,
        'speech': speech,
        'passage': passage,
        'glyph': glyph,
        'quantity': quantity,
        'promptPicture': promptPicture,
        'options': options,
        'correctAnswer': correctAnswer,
        'difficulty': difficulty,
        'marks': marks,
        'explanation': explanation,
        'optionPictures': optionPictures,
        'verification': [for (final v in verification) v.name],
      };

  factory ExamQuestion.fromJson(Map<String, dynamic> json) => ExamQuestion(
        id: json['id'] as String,
        lessonId: json['lessonId'] as String,
        lessonTitle: json['lessonTitle'] as String? ?? '',
        level: json['level'] as int,
        levels: {
          for (final l in (json['levels'] as List? ?? [json['level']])) l as int
        },
        world: json['world'] as String,
        topic: json['topic'] as String? ?? '',
        objective: json['objective'] as String? ?? '',
        type: _enumByName(ExamQuestionType.values, json['type'],
            ExamQuestionType.multipleChoice),
        prompt: json['prompt'] as String,
        speech: json['speech'] as String?,
        passage: json['passage'] as String?,
        glyph: json['glyph'] as String?,
        quantity: json['quantity'] as int?,
        promptPicture: json['promptPicture'] as String?,
        options: _strings(json['options']),
        correctAnswer: json['correctAnswer'] as String,
        difficulty: json['difficulty'] as int? ?? 1,
        marks: json['marks'] as int? ?? 1,
        explanation: json['explanation'] as String? ?? '',
        optionPictures: Map<String, String>.from(
            json['optionPictures'] as Map? ?? const {}),
        verification: {
          for (final v in (json['verification'] as List? ?? const []))
            _enumByName(Verification.values, v, Verification.machineChecked),
        },
      );
}

// -- Attempt ----------------------------------------------------------------

enum AttemptStatus { inProgress, submitted, abandoned }

class ExamAnswer {
  const ExamAnswer(this.answer, this.answeredAt);

  final String answer;
  final DateTime answeredAt;

  Map<String, Object> toJson() =>
      {'answer': answer, 'answeredAt': answeredAt.toIso8601String()};

  factory ExamAnswer.fromJson(Map<String, dynamic> json) => ExamAnswer(
        json['answer'] as String,
        _date(json['answeredAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class ExamAttempt {
  const ExamAttempt({
    required this.id,
    required this.config,
    required this.childId,
    required this.startedAt,
    this.finishedAt,
    this.status = AttemptStatus.inProgress,
    required this.seed,
    required this.questions,
    this.answers = const {},
    this.parentMarks = const {},
    this.retestNumber = 1,
  });

  final String id;

  /// The configuration as it was when the exam started.
  final ExamConfig config;
  final String childId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final AttemptStatus status;
  final int seed;

  /// Frozen copies, in the order shown (options already shuffled).
  final List<ExamQuestion> questions;
  final Map<String, ExamAnswer> answers;

  /// Parent-marked question id -> marked correct.
  final Map<String, bool> parentMarks;

  /// 1 for the first attempt of this exam scope, 2 for the first retest, ...
  final int retestNumber;

  bool get isInProgress => status == AttemptStatus.inProgress;

  int get answeredCount => answers.length;

  ExamAttempt copyWith({
    DateTime? finishedAt,
    AttemptStatus? status,
    Map<String, ExamAnswer>? answers,
    Map<String, bool>? parentMarks,
  }) =>
      ExamAttempt(
        id: id,
        config: config,
        childId: childId,
        startedAt: startedAt,
        finishedAt: finishedAt ?? this.finishedAt,
        status: status ?? this.status,
        seed: seed,
        questions: questions,
        answers: answers ?? this.answers,
        parentMarks: parentMarks ?? this.parentMarks,
        retestNumber: retestNumber,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'config': config.toJson(),
        'childId': childId,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'status': status.name,
        'seed': seed,
        'questions': [for (final q in questions) q.toJson()],
        'answers': answers.map((k, v) => MapEntry(k, v.toJson())),
        'parentMarks': parentMarks,
        'retestNumber': retestNumber,
      };

  factory ExamAttempt.fromJson(Map<String, dynamic> json) => ExamAttempt(
        id: json['id'] as String,
        config: ExamConfig.fromJson(
            Map<String, dynamic>.from(json['config'] as Map)),
        childId: json['childId'] as String,
        startedAt:
            _date(json['startedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        finishedAt: _date(json['finishedAt']),
        status: _enumByName(
            AttemptStatus.values, json['status'], AttemptStatus.inProgress),
        seed: json['seed'] as int? ?? 0,
        questions: [
          for (final q in (json['questions'] as List? ?? const []))
            ExamQuestion.fromJson(Map<String, dynamic>.from(q as Map)),
        ],
        answers: {
          for (final e in (json['answers'] as Map? ?? const {}).entries)
            e.key as String:
                ExamAnswer.fromJson(Map<String, dynamic>.from(e.value as Map)),
        },
        parentMarks:
            Map<String, bool>.from(json['parentMarks'] as Map? ?? const {}),
        retestNumber: json['retestNumber'] as int? ?? 1,
      );
}

// -- Result -----------------------------------------------------------------

/// Marks for one group (a world, topic or objective).
class ScoreLine {
  const ScoreLine({
    required this.obtained,
    required this.total,
    required this.correct,
    required this.count,
  });

  final int obtained;
  final int total;
  final int correct;
  final int count;

  double get percent => total == 0 ? 0 : obtained * 100 / total;

  Map<String, Object> toJson() => {
        'obtained': obtained,
        'total': total,
        'correct': correct,
        'count': count
      };

  factory ScoreLine.fromJson(Map<String, dynamic> json) => ScoreLine(
        obtained: json['obtained'] as int,
        total: json['total'] as int,
        correct: json['correct'] as int,
        count: json['count'] as int,
      );
}

class WrongAnswer {
  const WrongAnswer({
    required this.questionId,
    required this.lessonId,
    required this.world,
    required this.objective,
    required this.prompt,
    required this.given,
    required this.correct,
    required this.explanation,
  });

  final String questionId;
  final String lessonId;
  final String world;
  final String objective;
  final String prompt;

  /// Empty when the question was not answered.
  final String given;
  final String correct;
  final String explanation;

  Map<String, Object> toJson() => {
        'questionId': questionId,
        'lessonId': lessonId,
        'world': world,
        'objective': objective,
        'prompt': prompt,
        'given': given,
        'correct': correct,
        'explanation': explanation,
      };

  factory WrongAnswer.fromJson(Map<String, dynamic> json) => WrongAnswer(
        questionId: json['questionId'] as String,
        lessonId: json['lessonId'] as String,
        world: json['world'] as String? ?? '',
        objective: json['objective'] as String? ?? '',
        prompt: json['prompt'] as String? ?? '',
        given: json['given'] as String? ?? '',
        correct: json['correct'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
      );
}

class Recommendation {
  const Recommendation({
    required this.lessonId,
    required this.lessonTitle,
    required this.objective,
    required this.missed,
    required this.asked,
  });

  final String lessonId;
  final String lessonTitle;
  final String objective;
  final int missed;
  final int asked;

  /// e.g. `Revise: Rocket Addition (num-add), Add two quantities within ten:
  /// missed 3 of 4`.
  String get text =>
      'Revise: ${lessonTitle.isEmpty ? lessonId : '$lessonTitle ($lessonId)'}'
      '${objective.isEmpty ? '' : ', $objective'}: missed $missed of $asked';

  Map<String, Object> toJson() => {
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
        'objective': objective,
        'missed': missed,
        'asked': asked,
      };

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        lessonId: json['lessonId'] as String,
        lessonTitle: json['lessonTitle'] as String? ?? '',
        objective: json['objective'] as String? ?? '',
        missed: json['missed'] as int,
        asked: json['asked'] as int,
      );
}

class Readiness {
  const Readiness({
    required this.level,
    required this.ready,
    this.weakWorlds = const [],
    this.weakObjectives = const [],
    required this.text,
  });

  final int level;

  /// True only after a passed final exam at [level].
  final bool ready;
  final List<String> weakWorlds;
  final List<String> weakObjectives;
  final String text;

  Map<String, Object> toJson() => {
        'level': level,
        'ready': ready,
        'weakWorlds': weakWorlds,
        'weakObjectives': weakObjectives,
        'text': text,
      };

  factory Readiness.fromJson(Map<String, dynamic> json) => Readiness(
        level: json['level'] as int,
        ready: json['ready'] as bool,
        weakWorlds: _strings(json['weakWorlds']),
        weakObjectives: _strings(json['weakObjectives']),
        text: json['text'] as String? ?? '',
      );
}

class ExamResult {
  const ExamResult({
    required this.attemptId,
    required this.childId,
    required this.level,
    required this.type,
    required this.retestNumber,
    required this.totalMarks,
    required this.obtainedMarks,
    required this.percent,
    required this.passPercent,
    required this.passed,
    required this.bySubject,
    required this.byTopic,
    required this.byObjective,
    required this.timeTakenSeconds,
    required this.wrong,
    required this.recommendations,
    required this.readiness,
    required this.awaitingParentMarks,
    required this.unanswered,
    required this.finishedAt,
    required this.checksum,
  });

  final String attemptId;
  final String childId;
  final int level;
  final ExamType type;
  final int retestNumber;

  /// Marks of the questions counted so far (parent-marked ones still waiting
  /// are not included).
  final int totalMarks;
  final int obtainedMarks;
  final double percent;
  final double passPercent;
  final bool passed;
  final Map<String, ScoreLine> bySubject;
  final Map<String, ScoreLine> byTopic;
  final Map<String, ScoreLine> byObjective;
  final int timeTakenSeconds;
  final List<WrongAnswer> wrong;
  final List<Recommendation> recommendations;
  final Readiness readiness;

  /// Parent-marked questions not yet marked. While above 0 the percentage
  /// leaves them out and [isProvisional] is true.
  final int awaitingParentMarks;
  final int unanswered;
  final DateTime finishedAt;
  final String checksum;

  bool get isProvisional => awaitingParentMarks > 0;

  Map<String, Object?> toJson() => {
        'attemptId': attemptId,
        'childId': childId,
        'level': level,
        'type': type.name,
        'retestNumber': retestNumber,
        'totalMarks': totalMarks,
        'obtainedMarks': obtainedMarks,
        'percent': percent,
        'passPercent': passPercent,
        'passed': passed,
        'bySubject': bySubject.map((k, v) => MapEntry(k, v.toJson())),
        'byTopic': byTopic.map((k, v) => MapEntry(k, v.toJson())),
        'byObjective': byObjective.map((k, v) => MapEntry(k, v.toJson())),
        'timeTakenSeconds': timeTakenSeconds,
        'wrong': [for (final w in wrong) w.toJson()],
        'recommendations': [for (final r in recommendations) r.toJson()],
        'readiness': readiness.toJson(),
        'awaitingParentMarks': awaitingParentMarks,
        'unanswered': unanswered,
        'finishedAt': finishedAt.toIso8601String(),
        'checksum': checksum,
      };

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    Map<String, ScoreLine> lines(Object? v) => {
          for (final e in (v as Map? ?? const {}).entries)
            e.key as String:
                ScoreLine.fromJson(Map<String, dynamic>.from(e.value as Map)),
        };
    return ExamResult(
      attemptId: json['attemptId'] as String,
      childId: json['childId'] as String,
      level: json['level'] as int,
      type: _enumByName(ExamType.values, json['type'], ExamType.chapter),
      retestNumber: json['retestNumber'] as int? ?? 1,
      totalMarks: json['totalMarks'] as int,
      obtainedMarks: json['obtainedMarks'] as int,
      percent: (json['percent'] as num).toDouble(),
      passPercent: (json['passPercent'] as num).toDouble(),
      passed: json['passed'] as bool,
      bySubject: lines(json['bySubject']),
      byTopic: lines(json['byTopic']),
      byObjective: lines(json['byObjective']),
      timeTakenSeconds: json['timeTakenSeconds'] as int? ?? 0,
      wrong: [
        for (final w in (json['wrong'] as List? ?? const []))
          WrongAnswer.fromJson(Map<String, dynamic>.from(w as Map)),
      ],
      recommendations: [
        for (final r in (json['recommendations'] as List? ?? const []))
          Recommendation.fromJson(Map<String, dynamic>.from(r as Map)),
      ],
      readiness: Readiness.fromJson(
          Map<String, dynamic>.from(json['readiness'] as Map)),
      awaitingParentMarks: json['awaitingParentMarks'] as int? ?? 0,
      unanswered: json['unanswered'] as int? ?? 0,
      finishedAt:
          _date(json['finishedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      checksum: json['checksum'] as String? ?? '',
    );
  }
}

// -- Certificate ------------------------------------------------------------

class Certificate {
  const Certificate({
    required this.id,
    required this.childId,
    required this.displayName,
    required this.level,
    required this.issuedAt,
    required this.attemptId,
    this.issuedCount = 1,
    this.lastReissuedAt,
  });

  /// `AKS-L{level}-{yyyymmdd}-{4 chars}`.
  final String id;
  final String childId;
  final String displayName;
  final int level;
  final DateTime issuedAt;
  final String attemptId;

  /// 1 when first issued; goes up only when the parent asks for a reissue.
  final int issuedCount;
  final DateTime? lastReissuedAt;

  /// The wording never claims external accreditation.
  String get statement => '$displayName completed Level $level in Aksharamala.';

  Certificate reissued(DateTime at) => Certificate(
        id: id,
        childId: childId,
        displayName: displayName,
        level: level,
        issuedAt: issuedAt,
        attemptId: attemptId,
        issuedCount: issuedCount + 1,
        lastReissuedAt: at,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'childId': childId,
        'displayName': displayName,
        'level': level,
        'issuedAt': issuedAt.toIso8601String(),
        'attemptId': attemptId,
        'issuedCount': issuedCount,
        'lastReissuedAt': lastReissuedAt?.toIso8601String(),
      };

  factory Certificate.fromJson(Map<String, dynamic> json) => Certificate(
        id: json['id'] as String,
        childId: json['childId'] as String,
        displayName: json['displayName'] as String? ?? '',
        level: json['level'] as int,
        issuedAt:
            _date(json['issuedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        attemptId: json['attemptId'] as String? ?? '',
        issuedCount: json['issuedCount'] as int? ?? 1,
        lastReissuedAt: _date(json['lastReissuedAt']),
      );
}

// -- Per-child settings -----------------------------------------------------

class ChildExamSettings {
  const ChildExamSettings({
    this.defaultPassPercent = 60,
    this.pinSalt,
    this.pinHash,
  });

  final double defaultPassPercent;
  final String? pinSalt;
  final String? pinHash;

  bool get hasPin => pinHash != null && pinSalt != null;

  ChildExamSettings copyWith({double? defaultPassPercent}) => ChildExamSettings(
        defaultPassPercent: defaultPassPercent ?? this.defaultPassPercent,
        pinSalt: pinSalt,
        pinHash: pinHash,
      );

  ChildExamSettings withPin(String? salt, String? hash) => ChildExamSettings(
        defaultPassPercent: defaultPassPercent,
        pinSalt: salt,
        pinHash: hash,
      );

  Map<String, Object?> toJson() => {
        'defaultPassPercent': defaultPassPercent,
        'pinSalt': pinSalt,
        'pinHash': pinHash,
      };

  factory ChildExamSettings.fromJson(Map<String, dynamic> json) =>
      ChildExamSettings(
        defaultPassPercent:
            (json['defaultPassPercent'] as num? ?? 60).toDouble(),
        pinSalt: json['pinSalt'] as String?,
        pinHash: json['pinHash'] as String?,
      );
}
