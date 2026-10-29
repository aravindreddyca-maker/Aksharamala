/// Validates curriculum content packs and sorts every lesson into a readiness
/// level.
///
/// Pure Dart. Nothing here touches the app's screens or saved progress.
library;

import 'content_issue.dart';
import 'content_models.dart';

/// How far a lesson is from being something a child can use.
///
/// There is deliberately no "published" level: publishing needs native
/// review, verified media and QA, which no record has (see
/// `educator_review: required` on every record).
enum Readiness {
  /// A handwriting target with no verified stroke geometry. Not a lesson.
  placeholder,

  /// `outline_only`: an authoring backlog item, not a lesson.
  outline,

  /// Needed content is missing (e.g. the combined letter, the pieces to
  /// arrange, the practice items).
  blueprint,

  /// Text is complete, but a picture or story image does not exist yet.
  needsMedia,

  /// Text-complete draft. Still needs native review, audio and QA.
  draft,
}

typedef AssetExists = bool Function(String assetKey);

/// Types whose assessment is "pick the correct option".
const _choiceTypes = <String>{
  'recognition',
  'picture_word_match',
  'read_and_answer',
  'numeral_recognition',
  'count_objects',
  'addition',
  'subtraction',
  'multiplication',
  'division',
};

class ValidationReport {
  ValidationReport(this.issues, this.readiness);

  final List<ContentIssue> issues;

  /// Keyed `module/lessonId`.
  final Map<String, Readiness> readiness;

  Iterable<ContentIssue> get errors =>
      issues.where((i) => i.severity == IssueSeverity.error);

  Iterable<ContentIssue> get warnings =>
      issues.where((i) => i.severity == IssueSeverity.warning);

  bool get hasErrors => errors.isNotEmpty;

  Map<String, int> countByCode() {
    final out = <String, int>{};
    for (final i in issues) {
      out[i.code] = (out[i.code] ?? 0) + 1;
    }
    return Map.fromEntries(
      out.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  List<ContentIssue> byCode(String code) =>
      issues.where((i) => i.code == code).toList();
}

class ContentValidator {
  /// [assetExists] answers "is there a real image for this `asset_key`?".
  /// The default says no, which is the truth for the v2 packs.
  ContentValidator({AssetExists? assetExists})
      : _assetExists = assetExists ?? ((_) => false);

  final AssetExists _assetExists;

  ValidationReport validate(List<ContentPack> packs) {
    final issues = <ContentIssue>[];
    final readiness = <String, Readiness>{};

    final seenIds = <String, String>{}; // id -> module that first used it
    for (final pack in packs) {
      _checkPack(pack, issues);
      final ids = pack.lessons.map((l) => l.id).toSet();
      for (final l in pack.lessons) {
        final first = seenIds[l.id];
        if (first != null) {
          issues.add(
              _err('E001', pack.module, l.id, 'id already used in "$first"'));
        } else {
          seenIds[l.id] = pack.module.name;
        }
        _checkLesson(pack, l, ids, issues);
        readiness['${pack.module.name}/${l.id}'] = classify(l);
      }
      _checkPrerequisiteCycles(pack, issues);
    }
    return ValidationReport(issues, readiness);
  }

  Readiness classify(LessonRecord l) {
    if (l.isHandwriting && !(l.handwriting?.hasStrokes ?? false)) {
      return Readiness.placeholder;
    }
    if (l.isOutline) return Readiness.outline;
    if (_isBlueprint(l)) return Readiness.blueprint;
    final key = l.assetKey;
    if (key != null && !_assetExists(key)) return Readiness.needsMedia;
    return Readiness.draft;
  }

  bool _isBlueprint(LessonRecord l) {
    if (l.type == 'combine_character' &&
        (l.renderedCombination == null || l.renderedCombination!.isEmpty)) {
      return true;
    }
    if (l.type == 'word_ordering' && !_hasPieces(l)) return true;
    if (l.type == 'phonics_blending' && l.assessment.isEmpty) return true;
    return false;
  }

  bool _hasPieces(LessonRecord l) =>
      l.assessment['pieces'] is List ||
      l.assessment['letters'] is List ||
      l.assessment['tiles'] is List;

  // -- pack level ---------------------------------------------------------

  void _checkPack(ContentPack pack, List<ContentIssue> issues) {
    final m = pack.module;
    if (pack.language != m.name) {
      issues.add(_err('E005', m, null,
          'pack language "${pack.language}" does not match module "${m.name}"'));
    }
    if (pack.locale != m.locale) {
      issues.add(_err('E005', m, null,
          'pack locale "${pack.locale}" should be "${m.locale}"'));
    }
    for (final g in pack.gates.entries) {
      for (final c in g.value) {
        if (!pack.chapters.contains(c)) {
          issues.add(_err('E018', m, null,
              'gate "${g.key}" requires chapter "$c" which is not declared'));
        }
      }
    }
  }

  // -- lesson level -------------------------------------------------------

  void _checkLesson(
    ContentPack pack,
    LessonRecord l,
    Set<String> ids,
    List<ContentIssue> issues,
  ) {
    final m = pack.module;
    void err(String code, String msg) => issues.add(_err(code, m, l.id, msg));
    void warn(String code, String msg) => issues.add(_warn(code, m, l.id, msg));

    if (!knownLessonTypes.contains(l.type)) {
      err('E003', 'unknown lesson type "${l.type}"');
    }
    if (!knownStages.contains(l.stage)) {
      err('E004', 'unknown stage "${l.stage}"');
    }
    if (l.language != m.name) {
      err('E005', 'lesson language "${l.language}" is not "${m.name}"');
    }
    if (l.audio != null && l.audio!.locale != pack.locale) {
      err('E005',
          'audio locale "${l.audio!.locale}" differs from pack locale "${pack.locale}"');
    }
    if (l.estimatedMinutes <= 0) {
      err('E013', 'estimated_minutes is ${l.estimatedMinutes}');
    }
    if (!pack.chapters.contains(l.chapter)) {
      err('E014', 'chapter "${l.chapter}" is not declared');
    }

    for (final p in l.prerequisites) {
      if (!ids.contains(p) && !pack.gates.containsKey(p)) {
        warn('W101', 'prerequisite "$p" is not a lesson id or a declared gate');
      }
    }

    _checkAssessment(m, l, issues);
    _checkHandwriting(m, l, issues);
    _checkScript(m, l, issues);
    _checkReadinessWarnings(m, l, issues);
  }

  void _checkAssessment(
      ContentModule m, LessonRecord l, List<ContentIssue> issues) {
    void err(String code, String msg) => issues.add(_err(code, m, l.id, msg));
    if (l.isOutline) return;

    if (_choiceTypes.contains(l.type)) {
      final options = l.options;
      final answer = l.correctAnswer;
      if (l.assessment.isEmpty || options == null || answer == null) {
        err('E016', 'a ${l.type} lesson needs options and a correct answer');
        return;
      }
      if (options.length < 2) {
        err('E008', 'only ${options.length} option(s)');
      }
      if (options.toSet().length != options.length) {
        err('E007', 'options repeat: $options');
      }
      if (!options.contains(answer)) {
        err('E006', 'answer "$answer" is not in $options');
      }
      _checkAnswerKey(m, l, answer, issues);
      // Correct answer listed first is only a problem if nothing shuffles it.
      if (options.isNotEmpty &&
          options.first == answer &&
          l.shuffleOptions != true) {
        issues.add(_warn('W120', m, l.id,
            'correct answer is listed first and shuffle_options is not true'));
      }
    }

    if (l.type == 'story_sequencing') {
      final order = l.correctOrder;
      if (order == null || l.events.isEmpty) {
        err('E016', 'story_sequencing needs events and a correct_order');
      } else {
        final expected = List<int>.generate(l.events.length, (i) => i);
        final sorted = [...order]..sort();
        if (sorted.length != expected.length || !_sameList(sorted, expected)) {
          err(
              'E011',
              'correct_order $order is not a permutation of '
                  '0..${l.events.length - 1}');
        }
      }
    }

    if (l.type == 'word_ordering' && l.correctAnswer == null) {
      err('E016', 'word_ordering needs a correct_answer');
    }
    if (l.type == 'read_and_answer' && l.storyPages.isEmpty) {
      err('E016', 'read_and_answer has no story pages');
    }
  }

  /// The answer must agree with what the lesson says it teaches.
  void _checkAnswerKey(
    ContentModule m,
    LessonRecord l,
    String answer,
    List<ContentIssue> issues,
  ) {
    void err(String code, String msg) => issues.add(_err(code, m, l.id, msg));
    switch (l.type) {
      case 'recognition' || 'picture_word_match' || 'numeral_recognition':
        if (answer != l.target) {
          err('E017', 'answer "$answer" differs from target "${l.target}"');
        }
      case 'count_objects':
        final q = l.quantity;
        if (q == null || answer != '${q.toInt()}') {
          err('E017', 'answer "$answer" differs from quantity $q');
        }
      case 'addition' || 'subtraction' || 'multiplication' || 'division':
        final o = l.operands;
        if (o == null || o.length != 2) {
          err('E016', 'arithmetic lesson has no two operands');
          return;
        }
        final x = o[0].toInt(), y = o[1].toInt();
        final int? want = switch (l.type) {
          'addition' => x + y,
          'subtraction' => x - y,
          'multiplication' => x * y,
          _ => (y != 0 && x % y == 0) ? x ~/ y : null,
        };
        if (want == null || answer != '$want') {
          err('E009', '${l.type} $x, $y: key "$answer", correct "$want"');
        }
    }
  }

  void _checkHandwriting(
      ContentModule m, LessonRecord l, List<ContentIssue> issues) {
    final spec = l.handwriting;
    final flagged = spec != null &&
        (spec.masteryAwardEnabled || spec.strokeValidationEnabled);
    final assessFlag = l.assessment['mastery_award_enabled'] == true;
    if ((flagged || assessFlag) &&
        !(spec != null && spec.hasStrokes && spec.strokeOrderVerified)) {
      issues.add(_err('E010', m, l.id,
          'mastery/stroke validation is on but there are no verified strokes'));
    }
    if (l.isHandwriting && !(spec?.hasStrokes ?? false)) {
      issues.add(_warn('W107', m, l.id, 'no verified stroke geometry'));
    }
  }

  // -- script purity ------------------------------------------------------

  static bool _isTelugu(int r) => r >= 0x0C00 && r <= 0x0C7F;
  static bool _isTamil(int r) => r >= 0x0B80 && r <= 0x0BFF;
  static bool _isDevanagari(int r) => r >= 0x0900 && r <= 0x097F;
  static bool _isLatin(int r) =>
      (r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A);

  String? _scriptOf(int r) {
    if (_isTelugu(r)) return 'telugu';
    if (_isTamil(r)) return 'tamil';
    if (_isDevanagari(r)) return 'hindi';
    if (_isLatin(r)) return 'english';
    return null; // digits, punctuation, spaces: allowed anywhere
  }

  void _checkScript(
      ContentModule m, LessonRecord l, List<ContentIssue> issues) {
    if (m == ContentModule.numbers) return;
    // Grammar and writing prompts and outlines are English labels by design.
    if (l.isOutline ||
        const {'grammar_practice', 'guided_writing', 'guided_practice'}
            .contains(l.type)) {
      return;
    }
    final texts = <String>[
      l.target,
      ...?l.options,
      if (l.correctAnswer != null) l.correctAnswer!,
      ...l.storyPages,
      ...l.events,
      if (l.comprehensionQuestion != null) l.comprehensionQuestion!,
    ];
    for (final t in texts) {
      for (final r in t.runes) {
        final s = _scriptOf(r);
        if (s != null && s != m.name) {
          issues.add(_err('E015', m, l.id,
              'U+${r.toRadixString(16).toUpperCase()} ($s) in "$t"'));
          return; // one finding per record is enough
        }
      }
    }
  }

  // -- readiness warnings -------------------------------------------------

  void _checkReadinessWarnings(
    ContentModule m,
    LessonRecord l,
    List<ContentIssue> issues,
  ) {
    void warn(String code, String msg) => issues.add(_warn(code, m, l.id, msg));
    if (l.isOutline) warn('W105', 'outline only (${l.type}: "${l.target}")');
    if (_isBlueprint(l) && !l.isOutline) {
      if (l.type == 'word_ordering') {
        warn('W108', 'no letters or pieces to arrange for "${l.target}"');
      } else {
        warn('W106', '${l.type} "${l.target}" is a blueprint');
      }
    }
    final key = l.assetKey;
    if (key != null && !_assetExists(key)) {
      warn('W102', 'no image for asset_key "$key"');
    }
    final a = l.audio;
    if (a == null ||
        a.recordedAudioAsset == null ||
        !a.verifiedByNativeSpeaker) {
      warn('W103', 'no recorded, native-verified audio');
    }
    if (m.isRegionalScript && !_hasRegionalScript(m, l.instruction)) {
      warn('W104', 'instruction is English: "${l.instruction}"');
    }
    if (l.educatorReview == 'required') {
      issues.add(ContentIssue(
        code: 'I201',
        severity: IssueSeverity.info,
        module: m.name,
        lessonId: l.id,
        message: 'native-educator review required',
      ));
    }
  }

  bool _hasRegionalScript(ContentModule m, String text) => text.runes.any(
        (r) => switch (m) {
          ContentModule.telugu => _isTelugu(r),
          ContentModule.tamil => _isTamil(r),
          ContentModule.hindi => _isDevanagari(r),
          _ => true,
        },
      );

  // -- prerequisite cycles ------------------------------------------------

  void _checkPrerequisiteCycles(ContentPack pack, List<ContentIssue> issues) {
    final byId = {for (final l in pack.lessons) l.id: l};
    final state = <String, int>{}; // 1 = visiting, 2 = done
    final reported = <String>{};

    void visit(String id, List<String> path) {
      state[id] = 1;
      for (final p in byId[id]!.prerequisites) {
        if (!byId.containsKey(p)) continue; // unresolved: W101, not a cycle
        if (p == id) {
          if (reported.add(id)) {
            issues.add(_err('E012', pack.module, id, 'requires itself'));
          }
        } else if (state[p] == 1) {
          if (reported.add(id)) {
            issues.add(_err('E012', pack.module, id,
                'cycle: ${[...path, id, p].join(' -> ')}'));
          }
        } else if (state[p] == null) {
          visit(p, [...path, id]);
        }
      }
      state[id] = 2;
    }

    for (final l in pack.lessons) {
      if (state[l.id] == null) visit(l.id, const []);
    }
  }

  // -- helpers ------------------------------------------------------------

  static bool _sameList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  ContentIssue _err(String code, ContentModule m, String? id, String msg) =>
      ContentIssue(
        code: code,
        severity: IssueSeverity.error,
        module: m.name,
        lessonId: id,
        message: msg,
      );

  ContentIssue _warn(String code, ContentModule m, String? id, String msg) =>
      ContentIssue(
        code: code,
        severity: IssueSeverity.warning,
        module: m.name,
        lessonId: id,
        message: msg,
      );
}
