/// Teaching plans: the data a [TeachingLessonScreen] plays (see
/// `content/teaching/SCHEMA.md`). Built generically from the schema, so any
/// approved plan file just loads.
///
/// A plan that fails validation is left out (and the reasons are kept in
/// [TeachingPlanLibrary.issues]); its lesson then keeps its existing screen.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

/// The visual types a plan may use.
enum VisualType {
  none,
  glyph,
  picture,
  letterWord,
  objects,
  numberLine,
  baseTen,
}

/// One group of identical objects, e.g. three apples.
class ObjectGroup {
  const ObjectGroup({required this.emoji, required this.count});
  final String emoji;
  final int count;
}

class TeachingVisual {
  const TeachingVisual({
    this.type = VisualType.none,
    this.glyph = '',
    this.word = '',
    this.asset = '',
    this.caption = '',
    this.groups = const [],
    this.operator = '+',
    this.revealCount,
    this.countAll = false,
    this.result,
    this.showResult = false,
    this.from = 0,
    this.to = 10,
    this.start = 0,
    this.jump = 0,
    this.showHops = false,
    this.takeAway = 0,
    this.labels = const [],
    this.tens = 0,
    this.ones = 0,
    this.showTotal = false,
  });

  static const none = TeachingVisual();

  final VisualType type;
  final String glyph;
  final String word;
  final String asset;
  final String caption;

  // objects
  final List<ObjectGroup> groups;
  final String operator;

  /// How many GROUPS are visible (null = all).
  final int? revealCount;
  final bool countAll;
  final int? result;
  final bool showResult;

  // numberLine
  final int from;
  final int to;
  final int start;
  final int jump;
  final bool showHops;

  /// objects with operator `-`: the last [takeAway] objects of the ONE group
  /// are crossed out.
  final int takeAway;

  /// objects with operator `vs`: a name for each of the two rows.
  final List<String> labels;

  // baseTen
  final int tens;
  final int ones;
  final bool showTotal;

  /// The most objects one objects visual may show.
  static const maxObjects = 20;

  int get totalObjects => groups.fold(0, (a, g) => a + g.count);

  int get visibleGroups =>
      (revealCount ?? groups.length).clamp(0, groups.length);

  /// Operators an objects visual may use: add, take away (ASCII hyphen or the
  /// true minus sign), compare.
  static const operators = {'+', '-', '−', 'vs'};

  /// Subtraction: the second group is taken away from the first.
  bool get isSubtract => operator == '-' || operator == '−';

  /// Comparison: two groups side by side, nothing added or removed.
  bool get isCompare => operator == 'vs';

  /// Where the hops of a number line land.
  int get landing => start + jump;

  /// Plain-words description for screen readers.
  String get semanticLabel => switch (type) {
        VisualType.none => '',
        VisualType.glyph => 'Letter $glyph',
        VisualType.picture => caption.isEmpty ? 'Picture' : 'Picture: $caption',
        VisualType.letterWord => 'Letter $glyph, word $word',
        VisualType.objects => 'Groups of objects: ${[
            for (var i = 0; i < visibleGroups; i++) '${groups[i].count}',
          ].join(isCompare ? ' compared with ' : ' plus ')}${isSubtract ? ' ${groups.isEmpty ? 0 : groups.first.count} objects, $takeAway taken away' : ''}',
        VisualType.baseTen => 'Base ten blocks: $tens tens and $ones ones',
        VisualType.numberLine => 'Number line from $from to $to, '
            'start at $start${showHops ? (jump > 0 ? ', hop $jump to the right' : jump < 0 ? ', hop ${-jump} to the left' : ', stay on $start') : ''}',
      };

  static TeachingVisual fromJson(Map<String, dynamic> json) {
    final type = VisualType.values.asNameMap()[json['type']] ?? VisualType.none;
    return TeachingVisual(
      type: type,
      glyph: json['glyph'] as String? ?? '',
      word: json['word'] as String? ?? '',
      asset: json['asset'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      groups: [
        for (final g in (json['groups'] as List? ?? const []))
          ObjectGroup(
            emoji: (g as Map)['emoji'] as String? ?? '',
            count: (g['count'] as num?)?.toInt() ?? 0,
          ),
      ],
      operator: json['operator'] as String? ?? '+',
      revealCount: (json['revealCount'] as num?)?.toInt(),
      takeAway: (json['takeAway'] as num?)?.toInt() ?? 0,
      labels: [
        for (final l in (json['labels'] as List? ?? const [])) l.toString(),
      ],
      tens: (json['tens'] as num?)?.toInt() ?? 0,
      ones: (json['ones'] as num?)?.toInt() ?? 0,
      showTotal: json['showTotal'] as bool? ?? false,
      countAll: json['countAll'] as bool? ?? false,
      result: (json['result'] as num?)?.toInt(),
      showResult: json['showResult'] as bool? ?? false,
      from: (json['from'] as num?)?.toInt() ?? 0,
      to: (json['to'] as num?)?.toInt() ?? 10,
      start: (json['start'] as num?)?.toInt() ?? 0,
      jump: (json['jump'] as num?)?.toInt() ?? 0,
      showHops: json['showHops'] as bool? ?? false,
    );
  }
}

/// A teaching step (introduce, demonstrate, remediation explain).
class TeachingStep {
  const TeachingStep({
    required this.id,
    required this.text,
    required this.speech,
    this.visual = TeachingVisual.none,
  });

  final String id;
  final String text;
  final String speech;
  final TeachingVisual visual;

  static TeachingStep fromJson(Map<String, dynamic> json) => TeachingStep(
        id: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        speech: json['speech'] as String? ?? (json['text'] as String? ?? ''),
        visual: TeachingVisual.fromJson(
          Map<String, dynamic>.from(json['visual'] as Map? ?? const {}),
        ),
      );
}

/// A question (guided, practice, check, remediation).
class TeachingQuestion {
  const TeachingQuestion({
    required this.id,
    required this.prompt,
    required this.speech,
    required this.options,
    required this.answer,
    this.visual = TeachingVisual.none,
    this.hints = const [],
    this.wrongFeedback = const {},
    this.explanation = '',
    this.difficulty = 1,
    this.optionPictures = const {},
    this.task = '',
  });

  final String id;
  final String prompt;
  final String speech;
  final List<String> options;
  final String answer;
  final TeachingVisual visual;

  /// A ladder: hint 1 nudges, hint 2 may reveal.
  final List<String> hints;
  final Map<String, String> wrongFeedback;
  final String explanation;
  final int difficulty;
  final Map<String, String> optionPictures;

  /// Optional task type (letter_id, pick_word, not_word, word_to_letter,
  /// name_picture, hear_pick). Carried for reports; play does not depend on it.
  final String task;

  static TeachingQuestion fromJson(Map<String, dynamic> json) =>
      TeachingQuestion(
        id: json['id'] as String? ?? '',
        prompt: json['prompt'] as String? ?? '',
        speech: json['speech'] as String? ?? (json['prompt'] as String? ?? ''),
        options: [
          for (final o in (json['options'] as List? ?? const [])) o.toString(),
        ],
        answer: json['answer']?.toString() ?? '',
        visual: TeachingVisual.fromJson(
          Map<String, dynamic>.from(json['visual'] as Map? ?? const {}),
        ),
        hints: [
          for (final h in (json['hints'] as List? ?? const [])) h.toString(),
        ],
        wrongFeedback: {
          for (final e in (json['wrong_feedback'] as Map? ?? const {}).entries)
            e.key.toString(): e.value.toString(),
        },
        explanation: json['explanation'] as String? ?? '',
        difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
        optionPictures: {
          for (final e in (json['optionPictures'] as Map? ?? const {}).entries)
            e.key.toString(): e.value.toString(),
        },
        task: json['task'] as String? ?? '',
      );
}

/// Mastery thresholds, all from data.
class MasteryRules {
  const MasteryRules({
    this.checkTotal = 3,
    this.checkPass = 2,
    this.remediationPass = 2,
    this.maxRemediationCycles = 2,
    this.afterLimit = 'offer_parent_support',
  });

  final int checkTotal;
  final int checkPass;
  final int remediationPass;
  final int maxRemediationCycles;
  final String afterLimit;

  static MasteryRules fromJson(Map<String, dynamic> json) => MasteryRules(
        checkTotal: (json['check_total'] as num?)?.toInt() ?? 3,
        checkPass: (json['check_pass'] as num?)?.toInt() ?? 2,
        remediationPass: (json['remediation_pass'] as num?)?.toInt() ?? 2,
        maxRemediationCycles:
            (json['max_remediation_cycles'] as num?)?.toInt() ?? 2,
        afterLimit: json['after_limit'] as String? ?? 'offer_parent_support',
      );
}

class RemediationPlan {
  const RemediationPlan({
    this.explain = const [],
    this.guided = const [],
    this.check = const [],
  });

  final List<TeachingStep> explain;
  final List<TeachingQuestion> guided;
  final List<TeachingQuestion> check;
}

class TeachingPlan {
  const TeachingPlan({
    required this.lessonId,
    required this.world,
    required this.level,
    required this.locale,
    required this.title,
    required this.objective,
    required this.mastery,
    required this.introduce,
    required this.demonstrate,
    required this.guided,
    required this.practice,
    required this.check,
    required this.remediation,
    this.prerequisites = const [],
    this.status = '',
  });

  final String lessonId;
  final String world;
  final int level;
  final String locale;
  final String title;
  final String objective;
  final MasteryRules mastery;
  final List<String> prerequisites;
  final List<TeachingStep> introduce;
  final List<TeachingStep> demonstrate;
  final List<TeachingQuestion> guided;
  final List<TeachingQuestion> practice;
  final List<TeachingQuestion> check;
  final RemediationPlan remediation;

  /// The file's status (e.g. `pilot_unverified`); carried for reports only.
  final String status;

  Iterable<TeachingQuestion> get allQuestions => [
        ...guided,
        ...practice,
        ...check,
        ...remediation.guided,
        ...remediation.check,
      ];

  Iterable<TeachingStep> get allSteps => [
        ...introduce,
        ...demonstrate,
        ...remediation.explain,
      ];

  static TeachingPlan fromJson(Map<String, dynamic> json,
      {String status = ''}) {
    List<TeachingStep> steps(Object? v) => [
          for (final s in (v as List? ?? const []))
            TeachingStep.fromJson(Map<String, dynamic>.from(s as Map)),
        ];
    List<TeachingQuestion> questions(Object? v) => [
          for (final q in (v as List? ?? const []))
            TeachingQuestion.fromJson(Map<String, dynamic>.from(q as Map)),
        ];
    final rem = Map<String, dynamic>.from(json['remediation'] as Map? ?? {});
    return TeachingPlan(
      lessonId: json['lesson_id'] as String? ?? '',
      world: json['world'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 1,
      locale: json['locale'] as String? ?? 'en-US',
      title: json['title'] as String? ?? '',
      objective: json['objective'] as String? ?? '',
      mastery: MasteryRules.fromJson(
        Map<String, dynamic>.from(json['mastery'] as Map? ?? const {}),
      ),
      prerequisites: [
        for (final p in (json['prerequisites'] as List? ?? const []))
          p.toString(),
      ],
      introduce: steps(json['introduce']),
      demonstrate: steps(json['demonstrate']),
      guided: questions(json['guided']),
      practice: questions(json['practice']),
      check: questions(json['check']),
      remediation: RemediationPlan(
        explain: steps(rem['explain']),
        guided: questions(rem['guided']),
        check: questions(rem['check']),
      ),
      status: status,
    );
  }

  /// Everything wrong with this plan; empty when it can be played.
  List<String> validate() {
    final issues = <String>[];
    void bad(String m) => issues.add('$lessonId: $m');
    if (lessonId.isEmpty) bad('missing lesson_id');
    if (introduce.isEmpty) bad('no introduce steps');
    if (demonstrate.isEmpty) bad('no demonstrate steps');
    if (guided.isEmpty) bad('no guided questions');
    if (practice.isEmpty) bad('no practice questions');
    if (check.isEmpty) bad('no check questions');
    if (remediation.explain.isEmpty ||
        remediation.guided.isEmpty ||
        remediation.check.isEmpty) {
      bad('remediation needs explain, guided and check');
    }
    if (mastery.checkPass < 1 || mastery.checkPass > check.length) {
      bad('check_pass ${mastery.checkPass} is outside 1..${check.length}');
    }
    if (mastery.remediationPass < 1 ||
        mastery.remediationPass > remediation.check.length) {
      bad('remediation_pass ${mastery.remediationPass} is outside '
          '1..${remediation.check.length}');
    }
    if (mastery.maxRemediationCycles < 0) {
      bad('max_remediation_cycles is negative');
    }
    final ids = <String>{};
    void id(String value, String where) {
      if (value.isEmpty) {
        bad('empty id in $where');
      } else if (!ids.add(value)) {
        bad('duplicate id $value');
      }
    }

    void visual(TeachingVisual v, String where) {
      if (v.type == VisualType.picture || v.type == VisualType.letterWord) {
        // The asset may legitimately be missing from disk (placeholder), but
        // the field must be present.
        if (v.asset.isEmpty) bad('$where: ${v.type.name} visual has no asset');
      }
      if (v.type == VisualType.objects) {
        if (v.groups.isEmpty) bad('$where: objects visual has no groups');
        if (!TeachingVisual.operators.contains(v.operator)) {
          bad('$where: objects operator "${v.operator}" is not one of '
              '${TeachingVisual.operators.join(' ')}');
        }
        if (v.isCompare && v.groups.length != 2) {
          bad('$where: operator "vs" needs exactly two groups');
        }
        if (v.isCompare &&
            v.labels.isNotEmpty &&
            (v.labels.length != 2 || v.labels.any((l) => l.trim().isEmpty))) {
          bad('$where: vs labels must be two non-empty strings');
        }
        if (v.isSubtract) {
          if (v.groups.length != 1) {
            bad('$where: operator "-" is ONE group with takeAway, '
                'not ${v.groups.length} groups');
          } else if (v.takeAway < 0 || v.takeAway > v.groups.first.count) {
            bad('$where: takeAway ${v.takeAway} is outside '
                '0..${v.groups.first.count}');
          }
        } else if (v.takeAway != 0) {
          bad('$where: takeAway needs operator "-"');
        }
        if (v.totalObjects > TeachingVisual.maxObjects) {
          bad('$where: ${v.totalObjects} objects is more than '
              '${TeachingVisual.maxObjects} (use baseTen for big numbers)');
        }
        if (v.groups.any((g) => g.count < 0)) {
          bad('$where: a group has a negative count');
        }
        final r = v.revealCount;
        if (r != null && (r < 0 || r > v.groups.length)) {
          bad('$where: revealCount $r is outside 0..${v.groups.length}');
        }
      }
      if (v.type == VisualType.baseTen &&
          (v.tens < 0 || v.tens > 9 || v.ones < 0 || v.ones > 9)) {
        bad('$where: baseTen needs 0-9 tens and 0-9 ones '
            '(has ${v.tens} and ${v.ones})');
      }
      if (v.type == VisualType.numberLine) {
        if (v.to <= v.from) bad('$where: numberLine to <= from');
        if (v.start < v.from || v.start > v.to) {
          bad('$where: numberLine start ${v.start} is off the line');
        }
        if (v.showHops && (v.landing < v.from || v.landing > v.to)) {
          bad('$where: hops land on ${v.landing}, off the line');
        }
      }
    }

    for (final s in allSteps) {
      id(s.id, 'step');
      if (s.text.trim().isEmpty) bad('step ${s.id} has no text');
      visual(s.visual, s.id);
    }
    for (final q in allQuestions) {
      id(q.id, 'question');
      visual(q.visual, q.id);
      if (q.prompt.trim().isEmpty) bad('question ${q.id} has no prompt');
      if (q.options.length < 2 || q.options.length > 4) {
        bad('question ${q.id} needs 2-4 options, has ${q.options.length}');
      }
      if (q.options.toSet().length != q.options.length) {
        bad('question ${q.id} has duplicate options');
      }
      if (!q.options.contains(q.answer)) {
        bad('question ${q.id} answer "${q.answer}" is not in its options');
      }
      for (final key in q.wrongFeedback.keys) {
        if (!q.options.contains(key) || key == q.answer) {
          bad('question ${q.id} wrong_feedback "$key" is not a wrong option');
        }
      }
      for (final key in q.optionPictures.keys) {
        if (!q.options.contains(key)) {
          bad('question ${q.id} optionPictures "$key" is not an option');
        }
      }
    }
    return issues;
  }
}

/// What [indexPlanFiles] returns: each lesson's JSON text by lesson id, each
/// file's status, and the problems found while splitting the files. Plain
/// strings and maps only, so it can cross an isolate boundary cheaply.
typedef PlanIndex = Map<String, Object?>;

/// Splits plan files into one JSON string per lesson. Run it off the main
/// isolate for big files (`compute(indexPlanFiles, files)`); a lesson's text is
/// parsed and validated only when that lesson is first asked for.
PlanIndex indexPlanFiles(List<String> files) {
  final lessons = <String, String>{};
  final status = <String, String>{};
  final issues = <String>[];
  var n = 0;
  for (final text in files) {
    n++;
    try {
      final root = jsonDecode(text);
      if (root is! Map) {
        issues.add('file $n: top level is not an object');
        continue;
      }
      final fileStatus = root['status'] as String? ?? '';
      for (final raw in (root['lessons'] as List? ?? const [])) {
        if (raw is! Map || raw['lesson_id'] is! String) {
          issues.add('file $n: a lesson has no lesson_id');
          continue;
        }
        final id = raw['lesson_id'] as String;
        if (lessons.containsKey(id)) {
          issues.add('$id: duplicate plan, first one kept');
          continue;
        }
        lessons[id] = jsonEncode(raw);
        status[id] = fileStatus;
      }
    } on Object catch (e) {
      issues.add('file $n: not valid JSON ($e)');
    }
  }
  return {'lessons': lessons, 'status': status, 'issues': issues};
}

/// All loaded plans, by lesson id.
///
/// Built from an index, a lesson is decoded and validated the first time it is
/// asked for ([planFor]) and then kept, so start-up costs only the index and
/// opening a lesson costs one small parse. [plansById] and [issues] are for
/// tests and reports: they decode everything.
class TeachingPlanLibrary {
  TeachingPlanLibrary(Map<String, TeachingPlan> plans,
      {List<String> issues = const []})
      : _plans = {...plans},
        _raw = {},
        _status = {},
        _issues = [...issues];

  TeachingPlanLibrary._indexed(this._raw, this._status, List<String> issues)
      : _plans = {},
        _issues = [...issues];

  /// Library from [indexPlanFiles] output.
  factory TeachingPlanLibrary.fromIndex(PlanIndex index) =>
      TeachingPlanLibrary._indexed(
        Map<String, String>.from(index['lessons'] as Map? ?? const {}),
        Map<String, String>.from(index['status'] as Map? ?? const {}),
        List<String>.from(index['issues'] as List? ?? const []),
      );

  static final empty = TeachingPlanLibrary({});

  final Map<String, TeachingPlan> _plans;
  final Map<String, String> _raw;
  final Map<String, String> _status;
  final List<String> _issues;

  /// Whether a plan exists for [lessonId] (not yet validated if still lazy).
  bool hasPlan(String lessonId) =>
      _plans.containsKey(lessonId) || _raw.containsKey(lessonId);

  Set<String> get lessonIds => {..._plans.keys, ..._raw.keys};

  bool get isEmpty => _plans.isEmpty && _raw.isEmpty;

  /// The plan for [lessonId], decoded and validated on first use. A plan that
  /// does not validate is reported in [issues] and treated as absent, so its
  /// lesson keeps its existing screen.
  TeachingPlan? planFor(String lessonId) {
    final ready = _plans[lessonId];
    if (ready != null) return ready;
    final text = _raw.remove(lessonId);
    if (text == null) return null;
    try {
      final plan = TeachingPlan.fromJson(
        Map<String, dynamic>.from(jsonDecode(text) as Map),
        status: _status[lessonId] ?? '',
      );
      final problems = plan.validate();
      if (problems.isNotEmpty) {
        _issues.addAll(problems);
        return null;
      }
      return _plans[lessonId] = plan;
    } on Object catch (e) {
      _issues.add('$lessonId: could not be read ($e)');
      return null;
    }
  }

  /// Every valid plan (decodes all of them).
  Map<String, TeachingPlan> get plansById {
    for (final id in _raw.keys.toList()) {
      planFor(id);
    }
    return Map.unmodifiable(_plans);
  }

  /// Why any plan or file was left out (decodes all of them first).
  List<String> get issues {
    plansById;
    return List.unmodifiable(_issues);
  }

  /// Parses plan files at once (each a JSON string, `{schema_version, status,
  /// lessons[]}`). A bad file or plan is skipped and reported in [issues].
  factory TeachingPlanLibrary.parse(Iterable<String> jsonFiles) =>
      TeachingPlanLibrary.fromIndex(indexPlanFiles(jsonFiles.toList()));
}

/// Supplies the plan files' text. Tests inject their own.
typedef TeachingPlanLoader = Future<List<String>> Function();

/// Reads every `content/teaching/*.json` bundled as an asset.
Future<List<String>> assetTeachingPlanLoader() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final paths = manifest
      .listAssets()
      .where((p) => p.startsWith('content/teaching/') && p.endsWith('.json'))
      .toList()
    ..sort();
  return [for (final p in paths) await rootBundle.loadString(p)];
}
