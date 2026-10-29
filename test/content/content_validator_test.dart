import 'package:aksharamala/src/content/content_models.dart';
import 'package:aksharamala/src/content/content_validator.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal valid recognition lesson; tests change one thing at a time.
Map<String, Object?> lesson({
  String id = 'telugu-recognise-001',
  String module = 'telugu',
  String chapter = 'letters',
  String stage = '3-4',
  String type = 'recognition',
  String target = 'అ',
  String instruction = 'Select the letter.',
  List<String> prerequisites = const [],
  Object? minutes = 3,
  Map<String, Object?>? assessment,
  Map<String, Object?> extra = const {},
}) =>
    {
      'id': id,
      'language': module,
      'chapter': chapter,
      'stage': stage,
      'type': type,
      'target': target,
      'instruction': instruction,
      'prerequisites': prerequisites,
      'estimated_minutes': minutes,
      'educator_review': 'required',
      'audio': {
        'locale': ContentModule.byName(module)?.locale ?? 'te-IN',
        'narration_text': 'x',
        'recorded_audio_asset': null,
        'verified_by_native_speaker': false,
      },
      'assessment': assessment ??
          {
            'options': ['అ', 'ఇ', 'ఉ'],
            'correct_answer': 'అ',
            'shuffle_options': true,
          },
      ...extra,
    };

Map<String, Object?> packJson(
  List<Map<String, Object?>> lessons, {
  String module = 'telugu',
  String locale = 'te-IN',
  List<Object?> chapters = const ['letters', 'handwriting', 'grammar'],
}) =>
    {
      'schema_version': '2.0-draft',
      'language': module,
      'locale': locale,
      'status': 'test',
      'chapters': chapters,
      'lessons': lessons,
    };

ValidationReport check(
  List<Map<String, Object?>> lessons, {
  ContentModule module = ContentModule.telugu,
  String? locale,
  List<Object?>? chapters,
  AssetExists? assetExists,
}) {
  final parsed = parseContentPack(
    packJson(
      lessons,
      module: module.name,
      locale: locale ?? module.locale,
      chapters: chapters ?? const ['letters', 'handwriting', 'grammar'],
    ),
    expected: module,
  );
  expect(parsed.pack, isNotNull);
  final report =
      ContentValidator(assetExists: assetExists).validate([parsed.pack!]);
  return ValidationReport(
      [...parsed.issues, ...report.issues], report.readiness);
}

Set<String> codes(ValidationReport r) => r.issues.map((i) => i.code).toSet();

Set<String> errorCodes(ValidationReport r) =>
    r.errors.map((i) => i.code).toSet();

void main() {
  group('a clean lesson', () {
    test('has no errors', () {
      final r = check([lesson()]);
      expect(r.errors, isEmpty, reason: r.errors.join('\n'));
    });

    test('still carries the readiness warnings a draft must have', () {
      final r = check([lesson()]);
      // No recorded audio, English-only instruction, review required.
      expect(codes(r), containsAll(['W103', 'W104', 'I201']));
      expect(r.readiness['telugu/telugu-recognise-001'], Readiness.draft);
    });
  });

  group('structure errors', () {
    test('E001 duplicate lesson id', () {
      final r = check([lesson(), lesson()]);
      expect(errorCodes(r), contains('E001'));
    });

    test('E001 an id reused in another module', () {
      final a = parseContentPack(packJson([lesson(id: 'same')]),
          expected: ContentModule.telugu);
      final b = parseContentPack(
        packJson(
          [lesson(id: 'same', module: 'tamil')],
          module: 'tamil',
          locale: 'ta-IN',
        ),
        expected: ContentModule.tamil,
      );
      final r = ContentValidator().validate([a.pack!, b.pack!]);
      expect(errorCodes(r), contains('E001'));
    });

    test('E002 missing required field and wrong type', () {
      final bad = lesson()..remove('target');
      final r1 = check([bad]);
      expect(errorCodes(r1), contains('E002'));
      final r2 = check([lesson(minutes: '3')]);
      expect(errorCodes(r2), contains('E002'));
    });

    test('E002 the parser never throws on garbage', () {
      for (final garbage in <Object?>[
        null,
        5,
        'text',
        <Object?>[],
        {'lessons': 3}
      ]) {
        final parsed =
            parseContentPack(garbage, expected: ContentModule.telugu);
        expect(parsed.issues, isNotEmpty);
      }
      final parsed = parseContentPack(
        packJson([lesson(), 'not a lesson' as Object?]
            .cast<Map<String, Object?>>()
            .take(1)
            .toList()
          ..add(<String, Object?>{'id': 5})),
        expected: ContentModule.telugu,
      );
      expect(parsed.issues, isNotEmpty);
      expect(parsed.pack, isNotNull,
          reason: 'one bad record must not hide the rest');
    });

    test('E003 unknown type and E004 unknown stage', () {
      expect(errorCodes(check([lesson(type: 'hologram')])), contains('E003'));
      expect(errorCodes(check([lesson(stage: '13-15')])), contains('E004'));
    });

    test('E005 module, language and locale mismatches', () {
      expect(
        errorCodes(check([lesson()], locale: 'ta-IN')),
        contains('E005'),
        reason: 'pack locale',
      );
      expect(
        errorCodes(check([lesson(module: 'tamil')])),
        contains('E005'),
        reason: 'lesson language',
      );
      final wrongAudio = lesson()
        ..['audio'] = {
          'locale': 'hi-IN',
          'narration_text': 'x',
          'recorded_audio_asset': null,
          'verified_by_native_speaker': false,
        };
      expect(errorCodes(check([wrongAudio])), contains('E005'));
    });

    test('E013 minutes must be positive', () {
      expect(errorCodes(check([lesson(minutes: 0)])), contains('E013'));
    });

    test('E014 chapter must be declared', () {
      expect(errorCodes(check([lesson(chapter: 'mystery')])), contains('E014'));
    });

    test('chapters may be declared as objects with an id', () {
      final r = check([
        lesson()
      ], chapters: [
        {'id': 'letters'},
      ]);
      expect(r.errors, isEmpty);
    });
  });

  group('questions and answers', () {
    Map<String, Object?> options(List<String> o, String answer,
            {bool? shuffle = true}) =>
        {
          'options': o,
          'correct_answer': answer,
          if (shuffle != null) 'shuffle_options': shuffle,
        };

    test('E006 answer not among the options', () {
      final r = check([
        lesson(assessment: options(['అ', 'ఇ', 'ఉ'], 'ఎ'))
      ]);
      expect(errorCodes(r), contains('E006'));
    });

    test('E007 duplicate options', () {
      final r = check([
        lesson(assessment: options(['అ', 'అ', 'ఉ'], 'అ'))
      ]);
      expect(errorCodes(r), contains('E007'));
    });

    test('E008 fewer than two options', () {
      final r = check([
        lesson(assessment: options(['అ'], 'అ'))
      ]);
      expect(errorCodes(r), contains('E008'));
    });

    test('E016 empty assessment on a lesson that needs one', () {
      final r = check([lesson(assessment: <String, Object?>{})]);
      expect(errorCodes(r), contains('E016'));
    });

    test('E017 the answer key must match the target', () {
      final r = check([
        lesson(assessment: options(['అ', 'ఇ', 'ఉ'], 'ఇ'))
      ]);
      expect(errorCodes(r), contains('E017'));
    });

    test('W120 answer listed first and not shuffled', () {
      final r = check([
        lesson(assessment: options(['అ', 'ఇ', 'ఉ'], 'అ', shuffle: false))
      ]);
      expect(codes(r), contains('W120'));
      final ok = check([
        lesson(assessment: options(['అ', 'ఇ', 'ఉ'], 'అ'))
      ]);
      expect(codes(ok), isNot(contains('W120')));
    });

    test('an outline needs no assessment', () {
      final r = check([
        lesson(
          type: 'grammar_practice',
          chapter: 'grammar',
          assessment: <String, Object?>{},
          extra: {'content_status': 'outline_only'},
        ),
      ]);
      expect(r.errors, isEmpty, reason: r.errors.join('\n'));
      expect(r.readiness['telugu/telugu-recognise-001'], Readiness.outline);
      expect(codes(r), contains('W105'));
    });
  });

  group('arithmetic and counting', () {
    Map<String, Object?> math(String type, List<int> operands, String answer) =>
        lesson(
          id: 'n-$type',
          module: 'numbers',
          chapter: 'addition',
          type: type,
          target: '${operands[0]} ? ${operands[1]}',
          assessment: {
            'options': [answer, '999', '998'],
            'correct_answer': answer,
            'shuffle_options': true,
          },
          extra: {'operands': operands},
        );

    ValidationReport run(Map<String, Object?> l) => check(
          [l],
          module: ContentModule.numbers,
          chapters: ['addition'],
        );

    test('right keys pass, for all four operations', () {
      expect(run(math('addition', [7, 5], '12')).errors, isEmpty);
      expect(run(math('subtraction', [9, 4], '5')).errors, isEmpty);
      expect(run(math('multiplication', [6, 7], '42')).errors, isEmpty);
      expect(run(math('division', [12, 4], '3')).errors, isEmpty);
    });

    test('E009 wrong keys are caught', () {
      expect(errorCodes(run(math('addition', [7, 5], '13'))), contains('E009'));
      expect(
          errorCodes(run(math('subtraction', [9, 4], '4'))), contains('E009'));
      expect(errorCodes(run(math('multiplication', [6, 7], '41'))),
          contains('E009'));
      expect(errorCodes(run(math('division', [12, 4], '4'))), contains('E009'));
    });

    test('E009 division must be exact and never by zero', () {
      expect(errorCodes(run(math('division', [13, 4], '3'))), contains('E009'));
      expect(errorCodes(run(math('division', [5, 0], '0'))), contains('E009'));
    });

    test('E017 counting key must equal the quantity', () {
      final ok = lesson(
        id: 'c1',
        module: 'numbers',
        chapter: 'counting',
        type: 'count_objects',
        target: '3',
        assessment: {
          'options': ['3', '4', '5'],
          'correct_answer': '3',
          'shuffle_options': true,
        },
        extra: {'quantity': 3},
      );
      final bad = lesson(
        id: 'c2',
        module: 'numbers',
        chapter: 'counting',
        type: 'count_objects',
        target: '3',
        assessment: {
          'options': ['3', '4', '5'],
          'correct_answer': '4',
          'shuffle_options': true,
        },
        extra: {'quantity': 3},
      );
      final r = check([ok, bad],
          module: ContentModule.numbers, chapters: ['counting']);
      expect(r.errors.map((e) => e.lessonId), ['c2']);
      expect(errorCodes(r), {'E017'});
    });
  });

  group('stories and ordering', () {
    test('E011 story order must be a permutation of the events', () {
      Map<String, Object?> seq(List<int> order) => lesson(
            type: 'story_sequencing',
            chapter: 'letters',
            assessment: {'correct_order': order},
            extra: {
              'events': ['అ', 'ఆ', 'ఇ'],
            },
          );
      expect(
          check([
            seq([0, 1, 2])
          ]).errors,
          isEmpty);
      expect(
          check([
            seq([2, 0, 1])
          ]).errors,
          isEmpty);
      expect(
          errorCodes(check([
            seq([0, 1, 1])
          ])),
          contains('E011'));
      expect(
          errorCodes(check([
            seq([0, 1])
          ])),
          contains('E011'));
      expect(
          errorCodes(check([
            seq([0, 1, 3])
          ])),
          contains('E011'));
    });

    test('word ordering with nothing to arrange is a blueprint (W108)', () {
      final r = check([
        lesson(
          type: 'word_ordering',
          target: 'అమ్మ',
          assessment: {'correct_answer': 'అమ్మ'},
        ),
      ]);
      expect(codes(r), contains('W108'));
      expect(r.readiness['telugu/telugu-recognise-001'], Readiness.blueprint);
    });

    test('word ordering with pieces is a draft', () {
      final r = check([
        lesson(
          type: 'word_ordering',
          target: 'అమ్మ',
          assessment: {
            'correct_answer': 'అమ్మ',
            'pieces': ['అ', 'మ్మ'],
          },
        ),
      ]);
      expect(r.readiness['telugu/telugu-recognise-001'], Readiness.draft);
      expect(codes(r), isNot(contains('W108')));
    });

    test('a combined-letter lesson without the combined letter is a blueprint',
        () {
      final base = lesson(
        type: 'combine_character',
        target: 'క + ా',
        assessment: <String, Object?>{},
        extra: {'base_character': 'క', 'vowel_sign': 'ా'},
      );
      expect(check([base]).readiness['telugu/telugu-recognise-001'],
          Readiness.blueprint);
      expect(codes(check([base])), contains('W106'));
      final filled = lesson(
        type: 'combine_character',
        target: 'క + ా',
        assessment: <String, Object?>{},
        extra: {
          'base_character': 'క',
          'vowel_sign': 'ా',
          'rendered_combination': 'కా'
        },
      );
      expect(check([filled]).readiness['telugu/telugu-recognise-001'],
          Readiness.draft);
    });
  });

  group('handwriting safety', () {
    Map<String, Object?> hw({
      Object? paths,
      bool order = false,
      bool validation = false,
      bool mastery = false,
    }) =>
        lesson(
          type: 'guided_tracing',
          chapter: 'handwriting',
          assessment: {'requires_stroke_geometry': true},
          extra: {
            'handwriting_spec': {
              'glyph': 'అ',
              'script_category': 'vowel',
              'stroke_paths': paths,
              'stroke_order_verified': order,
              'stroke_validation_enabled': validation,
              'mastery_award_enabled': mastery,
            },
          },
        );

    test('no strokes: a placeholder with a warning, never an error', () {
      final r = check([hw()]);
      expect(r.errors, isEmpty);
      expect(codes(r), contains('W107'));
      expect(r.readiness['telugu/telugu-recognise-001'], Readiness.placeholder);
    });

    test('E010 mastery on without verified strokes', () {
      expect(errorCodes(check([hw(mastery: true)])), contains('E010'));
      expect(errorCodes(check([hw(validation: true)])), contains('E010'));
      expect(
        errorCodes(check([
          hw(
              mastery: true,
              paths: [
                [0, 0]
              ],
              order: false)
        ])),
        contains('E010'),
        reason: 'strokes exist but order is unverified',
      );
    });

    test('mastery is allowed only with verified strokes', () {
      final r = check([
        hw(mastery: true, validation: true, order: true, paths: [
          [
            [0.1, 0.1],
            [0.9, 0.9],
          ],
        ]),
      ]);
      expect(errorCodes(r), isNot(contains('E010')));
      expect(r.readiness['telugu/telugu-recognise-001'], Readiness.draft);
    });

    test('an empty stroke list counts as no strokes', () {
      expect(
          check([hw(paths: <Object?>[])])
              .readiness['telugu/telugu-recognise-001'],
          Readiness.placeholder);
    });
  });

  group('prerequisites', () {
    test('W101 a prerequisite that is not a lesson id', () {
      final r = check([
        lesson(prerequisites: ['letter_and_combination_mastery'])
      ]);
      expect(codes(r), contains('W101'));
      expect(r.errors, isEmpty);
    });

    test('a real prerequisite resolves', () {
      final r = check([
        lesson(id: 'a'),
        lesson(id: 'b', prerequisites: ['a']),
      ]);
      expect(codes(r), isNot(contains('W101')));
      expect(r.errors, isEmpty);
    });

    test('E012 self-requirement and cycles', () {
      expect(
        errorCodes(check([
          lesson(id: 'a', prerequisites: ['a'])
        ])),
        contains('E012'),
      );
      expect(
        errorCodes(check([
          lesson(id: 'a', prerequisites: ['b']),
          lesson(id: 'b', prerequisites: ['c']),
          lesson(id: 'c', prerequisites: ['a']),
        ])),
        contains('E012'),
      );
    });

    test('a diamond (two paths, no cycle) is fine', () {
      final r = check([
        lesson(id: 'a'),
        lesson(id: 'b', prerequisites: ['a']),
        lesson(id: 'c', prerequisites: ['a']),
        lesson(id: 'd', prerequisites: ['b', 'c']),
      ]);
      expect(errorCodes(r), isNot(contains('E012')));
    });
  });

  group('script purity', () {
    test('E015 stray script in a Telugu lesson', () {
      final r = check([
        lesson(
          assessment: {
            'options': ['అ', 'இ', 'ఉ'],
            'correct_answer': 'అ',
            'shuffle_options': true,
          },
        ),
      ]);
      expect(errorCodes(r), contains('E015'));
    });

    test('E015 Latin letters inside regional text', () {
      final r = check([lesson(target: 'అa')]);
      expect(errorCodes(r), contains('E015'));
    });

    test('digits, spaces and punctuation are allowed anywhere', () {
      final r = check([
        lesson(
          type: 'combine_character',
          target: 'క + ా 1?',
          assessment: <String, Object?>{},
        ),
      ]);
      expect(errorCodes(r), isNot(contains('E015')));
    });

    test('English labels are allowed on outline and grammar lessons', () {
      final r = check([
        lesson(
          type: 'grammar_practice',
          chapter: 'grammar',
          target: 'Naming words',
          assessment: <String, Object?>{},
          extra: {'content_status': 'outline_only'},
        ),
      ]);
      expect(errorCodes(r), isNot(contains('E015')));
    });
  });

  group('media and language warnings', () {
    test('W102 and needs-images until the picture exists', () {
      final l = lesson(
        type: 'picture_word_match',
        target: 'అమ్మ',
        assessment: {
          'options': ['అమ్మ', 'ఉడుత', 'ఓడ'],
          'correct_answer': 'అమ్మ',
          'shuffle_options': true,
        },
        extra: {'asset_key': 'telugu/vocab/001'},
      );
      final missing = check([l]);
      expect(codes(missing), contains('W102'));
      expect(missing.readiness['telugu/telugu-recognise-001'],
          Readiness.needsMedia);
      final present = check([l], assetExists: (k) => k == 'telugu/vocab/001');
      expect(codes(present), isNot(contains('W102')));
      expect(present.readiness['telugu/telugu-recognise-001'], Readiness.draft);
    });

    test('W103 audio must be both recorded and native-verified', () {
      Map<String, Object?> withAudio(String? asset, bool verified) => lesson()
        ..['audio'] = {
          'locale': 'te-IN',
          'narration_text': 'x',
          'recorded_audio_asset': asset,
          'verified_by_native_speaker': verified,
        };
      expect(codes(check([withAudio(null, false)])), contains('W103'));
      expect(codes(check([withAudio('a.mp3', false)])), contains('W103'));
      expect(codes(check([withAudio('a.mp3', true)])), isNot(contains('W103')));
    });

    test('W104 English instructions in a regional module only', () {
      expect(codes(check([lesson()])), contains('W104'));
      expect(
        codes(check([lesson(instruction: 'అక్షరం ఎంచుకోండి')])),
        isNot(contains('W104')),
      );
      final english = check(
        [
          lesson(id: 'e1', module: 'english', target: 'A', assessment: {
            'options': ['A', 'B', 'C'],
            'correct_answer': 'A',
            'shuffle_options': true,
          })
        ],
        module: ContentModule.english,
      );
      expect(codes(english), isNot(contains('W104')));
    });
  });

  group('readiness levels', () {
    test('no level is ever "published"', () {
      expect(Readiness.values.map((r) => r.name), isNot(contains('published')));
      expect(Readiness.values.length, 5);
    });
  });
}
