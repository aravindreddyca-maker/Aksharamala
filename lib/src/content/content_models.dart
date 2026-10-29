/// Typed model of the curriculum content packs (`content/*.json`, schema
/// `2.0-draft`) and a strict parser.
///
/// Pure Dart. The parser never throws on bad data: it records every problem as
/// a [ContentIssue] and carries on, so one bad record cannot hide the others.
library;

import 'content_issue.dart';

enum ContentModule {
  telugu,
  tamil,
  hindi,
  english,
  numbers;

  static ContentModule? byName(String name) {
    for (final m in values) {
      if (m.name == name) return m;
    }
    return null;
  }

  /// The locale a pack for this module must declare.
  String get locale => switch (this) {
        telugu => 'te-IN',
        tamil => 'ta-IN',
        hindi => 'hi-IN',
        english => 'en-IN',
        numbers => 'en-IN',
      };

  /// Telugu, Tamil and Hindi teach a non-Latin script.
  bool get isRegionalScript => this == telugu || this == tamil || this == hindi;
}

/// Age bands used by every lesson.
const knownStages = <String>{'3-4', '5-6', '7-9', '10-12'};

/// Every lesson type present in the v2 packs.
const knownLessonTypes = <String>{
  'recognition',
  'guided_tracing',
  'independent_writing',
  'picture_word_match',
  'word_ordering',
  'combine_character',
  'grammar_practice',
  'guided_writing',
  'guided_practice',
  'read_and_answer',
  'story_sequencing',
  'phonics_blending',
  'addition',
  'subtraction',
  'multiplication',
  'division',
  'numeral_recognition',
  'count_objects',
  'concept_unit',
};

/// The two handwriting types: content targets only until strokes are verified.
const handwritingTypes = <String>{'guided_tracing', 'independent_writing'};

class AudioSpec {
  const AudioSpec({
    required this.locale,
    required this.narrationText,
    required this.recordedAudioAsset,
    required this.verifiedByNativeSpeaker,
  });

  final String locale;
  final String narrationText;
  final String? recordedAudioAsset;
  final bool verifiedByNativeSpeaker;
}

class HandwritingSpec {
  const HandwritingSpec({
    required this.glyph,
    required this.scriptCategory,
    required this.strokePaths,
    required this.strokeOrderVerified,
    required this.strokeValidationEnabled,
    required this.masteryAwardEnabled,
  });

  final String glyph;
  final String scriptCategory;

  /// Ordered stroke geometry. `null` or empty means none exists yet.
  final Object? strokePaths;
  final bool strokeOrderVerified;
  final bool strokeValidationEnabled;
  final bool masteryAwardEnabled;

  bool get hasStrokes =>
      strokePaths != null &&
      !(strokePaths is List && (strokePaths as List).isEmpty);
}

class LessonRecord {
  const LessonRecord({
    required this.module,
    required this.id,
    required this.language,
    required this.chapter,
    required this.stage,
    required this.type,
    required this.target,
    required this.instruction,
    required this.prerequisites,
    required this.estimatedMinutes,
    required this.audio,
    required this.assessment,
    required this.storyPages,
    required this.events,
    this.imageAsset,
    this.assetKey,
    this.contentStatus,
    this.implementationStatus,
    this.educatorReview,
    this.comprehensionQuestion,
    this.handwriting,
    this.baseCharacter,
    this.vowelSign,
    this.renderedCombination,
    this.operands,
    this.quantity,
    this.meaningEn,
  });

  final ContentModule module;
  final String id;
  final String language;
  final String chapter;
  final String stage;
  final String type;
  final String target;
  final String instruction;
  final List<String> prerequisites;
  final int estimatedMinutes;
  final AudioSpec? audio;
  final Map<String, Object?> assessment;
  final List<String> storyPages;
  final List<String> events;
  final String? imageAsset;
  final String? assetKey;
  final String? contentStatus;
  final String? implementationStatus;
  final String? educatorReview;
  final String? comprehensionQuestion;
  final HandwritingSpec? handwriting;
  final String? baseCharacter;
  final String? vowelSign;
  final String? renderedCombination;
  final List<num>? operands;
  final num? quantity;
  final String? meaningEn;

  bool get isHandwriting => handwritingTypes.contains(type);
  bool get isOutline => contentStatus == 'outline_only';

  List<String>? get options {
    final o = assessment['options'];
    return o is List ? o.whereType<String>().toList() : null;
  }

  String? get correctAnswer {
    final a = assessment['correct_answer'];
    return a is String ? a : null;
  }

  bool? get shuffleOptions {
    final s = assessment['shuffle_options'];
    return s is bool ? s : null;
  }

  List<int>? get correctOrder {
    final o = assessment['correct_order'];
    return o is List ? o.whereType<int>().toList() : null;
  }
}

class ContentPack {
  const ContentPack({
    required this.module,
    required this.schemaVersion,
    required this.language,
    required this.locale,
    required this.status,
    required this.chapters,
    required this.lessons,
    this.gates = const {},
  });

  final ContentModule module;
  final String schemaVersion;
  final String language;
  final String locale;
  final String status;
  final List<String> chapters;
  final List<LessonRecord> lessons;

  /// Named prerequisites that are not single lessons: gate name -> the chapters
  /// that must be finished. A lesson may list a gate as a prerequisite.
  final Map<String, List<String>> gates;
}

class ParsedPack {
  const ParsedPack(this.pack, this.issues);

  /// Null only when the file is not usable at all.
  final ContentPack? pack;
  final List<ContentIssue> issues;
}

/// Reads one pack. [expected] is the module the file is supposed to hold.
ParsedPack parseContentPack(
  Object? json, {
  required ContentModule expected,
}) {
  final issues = <ContentIssue>[];
  final name = expected.name;

  void issue(String code, String message, {String? lessonId}) {
    issues.add(ContentIssue(
      code: code,
      severity: IssueSeverity.error,
      module: name,
      lessonId: lessonId,
      message: message,
    ));
  }

  if (json is! Map) {
    issue('E002', 'file is not a JSON object');
    return ParsedPack(null, issues);
  }

  String text(Map m, String key, {String? lessonId, bool required = true}) {
    final v = m[key];
    if (v is String && (v.isNotEmpty || !required)) return v;
    if (required) {
      issue('E002', 'field "$key" missing or not text', lessonId: lessonId);
    }
    return '';
  }

  List<String> textList(Map m, String key, {String? lessonId}) {
    final v = m[key];
    if (v == null) return const [];
    if (v is List && v.every((e) => e is String)) return v.cast<String>();
    issue('E002', 'field "$key" must be a list of text', lessonId: lessonId);
    return const [];
  }

  final language = text(json, 'language');
  final locale = text(json, 'locale');
  final schema = text(json, 'schema_version');
  final status = text(json, 'status', required: false);
  final chaptersRaw = json['chapters'];
  final chapters = <String>[];
  if (chaptersRaw is List) {
    for (final c in chaptersRaw) {
      if (c is String) {
        chapters.add(c);
      } else if (c is Map && c['id'] is String) {
        chapters.add(c['id'] as String);
      } else {
        issue('E002', 'a chapter entry is neither text nor has an "id"');
      }
    }
  } else {
    issue('E002', 'field "chapters" missing or not a list');
  }

  final gates = <String, List<String>>{};
  final gatesRaw = json['gates'];
  if (gatesRaw is Map) {
    for (final e in gatesRaw.entries) {
      final req = e.value is Map ? (e.value as Map)['requires_chapters'] : null;
      if (e.key is String && req is List && req.every((c) => c is String)) {
        gates[e.key as String] = req.cast<String>();
      } else {
        issue('E002', 'gate "${e.key}" needs a "requires_chapters" list');
      }
    }
  } else if (gatesRaw != null) {
    issue('E002', 'field "gates" must be an object');
  }

  final lessons = <LessonRecord>[];
  final raw = json['lessons'];
  if (raw is! List) {
    issue('E002', 'field "lessons" missing or not a list');
    return ParsedPack(null, issues);
  }

  for (var i = 0; i < raw.length; i++) {
    final m = raw[i];
    if (m is! Map) {
      issue('E002', 'lesson #$i is not an object');
      continue;
    }
    final id = m['id'] is String && (m['id'] as String).isNotEmpty
        ? m['id'] as String
        : null;
    if (id == null) issue('E002', 'lesson #$i has no id');
    final lid = id ?? '#$i';

    AudioSpec? audio;
    final a = m['audio'];
    if (a is Map) {
      audio = AudioSpec(
        locale: a['locale'] is String ? a['locale'] as String : '',
        narrationText:
            a['narration_text'] is String ? a['narration_text'] as String : '',
        recordedAudioAsset: a['recorded_audio_asset'] is String
            ? a['recorded_audio_asset'] as String
            : null,
        verifiedByNativeSpeaker: a['verified_by_native_speaker'] == true,
      );
    }

    HandwritingSpec? hw;
    final h = m['handwriting_spec'];
    if (h is Map) {
      hw = HandwritingSpec(
        glyph: h['glyph'] is String ? h['glyph'] as String : '',
        scriptCategory: h['script_category'] is String
            ? h['script_category'] as String
            : '',
        strokePaths: h['stroke_paths'],
        strokeOrderVerified: h['stroke_order_verified'] == true,
        strokeValidationEnabled: h['stroke_validation_enabled'] == true,
        masteryAwardEnabled: h['mastery_award_enabled'] == true,
      );
    }

    final assessment = m['assessment'];
    final operands = m['operands'];
    final minutes = m['estimated_minutes'];
    if (minutes != null && minutes is! int) {
      issue('E002', 'field "estimated_minutes" must be a whole number',
          lessonId: lid);
    }

    lessons.add(LessonRecord(
      module: expected,
      id: lid,
      language: text(m, 'language', lessonId: lid),
      chapter: text(m, 'chapter', lessonId: lid),
      stage: text(m, 'stage', lessonId: lid),
      type: text(m, 'type', lessonId: lid),
      target: text(m, 'target', lessonId: lid),
      instruction: text(m, 'instruction', lessonId: lid),
      prerequisites: textList(m, 'prerequisites', lessonId: lid),
      estimatedMinutes: minutes is int ? minutes : 0,
      audio: audio,
      assessment: assessment is Map
          ? Map<String, Object?>.from(assessment)
          : const <String, Object?>{},
      storyPages: textList(m, 'story_pages', lessonId: lid),
      events: textList(m, 'events', lessonId: lid),
      imageAsset:
          m['image_asset'] is String ? m['image_asset'] as String : null,
      assetKey: m['asset_key'] is String ? m['asset_key'] as String : null,
      contentStatus:
          m['content_status'] is String ? m['content_status'] as String : null,
      implementationStatus: m['implementation_status'] is String
          ? m['implementation_status'] as String
          : null,
      educatorReview: m['educator_review'] is String
          ? m['educator_review'] as String
          : null,
      comprehensionQuestion: m['comprehension_question'] is String
          ? m['comprehension_question'] as String
          : null,
      handwriting: hw,
      baseCharacter:
          m['base_character'] is String ? m['base_character'] as String : null,
      vowelSign: m['vowel_sign'] is String ? m['vowel_sign'] as String : null,
      renderedCombination: m['rendered_combination'] is String
          ? m['rendered_combination'] as String
          : null,
      operands: operands is List && operands.every((e) => e is num)
          ? operands.cast<num>()
          : null,
      quantity: m['quantity'] is num ? m['quantity'] as num : null,
      meaningEn: m['meaning_en'] is String ? m['meaning_en'] as String : null,
    ));
  }

  return ParsedPack(
    ContentPack(
      module: expected,
      schemaVersion: schema,
      language: language,
      locale: locale,
      status: status,
      chapters: chapters,
      lessons: lessons,
      gates: gates,
    ),
    issues,
  );
}
