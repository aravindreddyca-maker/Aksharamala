// Curriculum audit checks. READ-ONLY: nothing here changes the app.
// Every check runs in normal and strict modes; no curriculum defect is skipped.
// These checks cannot judge pronunciation, translation quality, or whether a
// picture "feels" right: a qualified native-language educator and a real-device
// listening test are still required for those.
import 'dart:io';

import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/quest_art.dart';
import 'package:aksharamala/src/screens/lesson_screen.dart';
import 'package:aksharamala/src/screens/world_map_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoDiskStore extends LocalStore {
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

typedef _Row = ({LearningWorld world, Lesson lesson});

final List<_Row> _all = [
  for (final w in curriculum)
    for (final l in w.lessons) (world: w, lesson: l),
];

const _expectedLocale = {
  'english': 'en-US',
  'telugu': 'te-IN',
  'hindi': 'hi-IN',
  'tamil': 'ta-IN',
  'numbers': 'en-IN',
};

bool _isTelugu(int r) => r >= 0x0C00 && r <= 0x0C7F;
bool _isTamil(int r) => r >= 0x0B80 && r <= 0x0BFF;
bool _isDevanagari(int r) => r >= 0x0900 && r <= 0x097F;
bool _isLatin(int r) => (r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A);

/// Characters allowed in any script: spaces, digits, punctuation, symbols.
bool _isNeutral(int r) =>
    r == 0x20 ||
    (r >= 0x30 && r <= 0x39) ||
    '.,?!–—‘’“”_/()•-:;+−=★&×÷½%'.runes.contains(r) ||
    r == 0x0964; // Devanagari danda

bool Function(int) _scriptOf(String worldId) => switch (worldId) {
      'telugu' => _isTelugu,
      'hindi' => _isDevanagari,
      'tamil' => _isTamil,
      _ => _isLatin,
    };

bool _isEmoji(int r) =>
    r >= 0x1F000 || (r >= 0x2600 && r <= 0x27BF && r != 0x2605);

/// Dependent vowel signs, viramas and similar marks that may never start a
/// word (that would mean a broken or orphaned character).
bool _isDependentMark(int r) =>
    (r >= 0x0C3E && r <= 0x0C56) ||
    r == 0x0C62 ||
    r == 0x0C63 ||
    (r >= 0x0BBE && r <= 0x0BCD) ||
    r == 0x0BD7 ||
    (r >= 0x093E && r <= 0x094F) ||
    (r >= 0x0900 && r <= 0x0903);

Iterable<String> _texts(Lesson l) => [
      l.title,
      l.subtitle,
      l.symbol,
      l.speech,
      l.challenge,
      l.answer,
      ...l.options,
      ...l.story,
    ];

bool _isQuiz(Lesson l) => l.kind != LessonKind.tracing && l.options.isNotEmpty;

AppController _controller({
  Set<String> done = const {},
  LocalStore? store,
  int age = 6,
}) {
  final profile =
      ChildProfile(id: 'p', name: 'Audit', age: age, avatar: 'lion');
  return AppController(store: store ?? _NoDiskStore())
    ..profiles = [profile]
    ..progress = {
      'p': ProgressRecord(
        completedLessons: done,
        attempts: const {},
        correct: const {},
        lastPlayed: const {},
        earnedBadges: const {},
      ),
    }
    ..activeProfile = profile
    ..loaded = true;
}

int _ageFor(ExperienceStage stage) => switch (stage) {
      ExperienceStage.explorer => 3,
      ExperienceStage.creator => 5,
      ExperienceStage.scholar => 7,
      ExperienceStage.champion => 10,
    };

Future<void> _setView(WidgetTester tester, Size size) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
}

Future<void> _openLesson(
  WidgetTester tester,
  _Row row, {
  AppController? controller,
}) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    AppScope(
      controller: controller ?? _controller(),
      child: MaterialApp(
        theme: buildTheme(),
        home: LessonScreen(world: row.world, lesson: row.lesson),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Reads through a story to its question.
Future<void> _finishStory(WidgetTester tester, Lesson lesson) async {
  if (lesson.kind != LessonKind.story) return;
  for (var i = 0; i < lesson.story.length; i++) {
    final next = find.byType(FilledButton).last;
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
  }
}

/// Answers a quiz with [option], through either interaction style.
Future<void> _answer(WidgetTester tester, String option) async {
  await tester.tap(find.byKey(Key('answer_$option')));
  await tester.pumpAndSettle();
  final check = find.byKey(const Key('check_answer'));
  if (check.evaluate().isNotEmpty) {
    // Scroll to it first: on 360 dp-high screens it starts below the fold
    // (that is AUD-031, checked separately).
    await tester.ensureVisible(check);
    await tester.pumpAndSettle();
    await tester.tap(check);
    await tester.pumpAndSettle();
  }
}

void main() {
  setUp(() => feedbackPause = Duration.zero);
  tearDown(() => feedbackPause = defaultFeedbackPause);

  // ---------------------------------------------------------------------
  group('1 inventory', () {
    test('prints the inventory used by the audit report', () {
      // ignore_for_file: avoid_print
      for (final w in curriculum) {
        final kinds = <LessonKind, int>{};
        for (final l in w.lessons) {
          kinds[l.kind] = (kinds[l.kind] ?? 0) + 1;
        }
        final quizzes = w.lessons.where(_isQuiz).toList();
        final distractors =
            quizzes.fold<int>(0, (n, l) => n + l.options.length);
        final pictures =
            w.lessons.fold<int>(0, (n, l) => n + l.pictures.length);
        final covers = w.lessons.where((l) => l.cover != null).length;
        final storyPages = w.lessons.fold<int>(0, (n, l) => n + l.story.length);
        print(
          'INV|${w.id}|lessons=${w.lessons.length}|kinds=$kinds|'
          'quizzes=${quizzes.length}|options=$distractors|'
          'optionPictures=$pictures|covers=$covers|storyPages=$storyPages',
        );
      }
      print('INV|total lessons=${_all.length}|worlds=${curriculum.length}');
      expect(_all.length, 177);
    });

    test('lesson ids are unique across the whole curriculum', () {
      final ids = _all.map((r) => r.lesson.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every lesson has the fields a lesson needs', () {
      for (final r in _all) {
        final l = r.lesson;
        for (final entry in {
          'id': l.id,
          'title': l.title,
          'subtitle': l.subtitle,
          'symbol': l.symbol,
          'speech': l.speech,
          'locale': l.locale,
          'challenge': l.challenge,
        }.entries) {
          expect(entryTrim(entry.value), isNotEmpty,
              reason: '${l.id} ${entry.key}');
        }
      }
    });
  });

  // ---------------------------------------------------------------------
  group('2 script and Unicode', () {
    test('locale matches the language of each world', () {
      for (final r in _all) {
        expect(r.lesson.locale, _expectedLocale[r.world.id],
            reason: '${r.lesson.id} locale');
      }
    });

    test('each lesson text is in its own script (no strays)', () {
      final stray = <String>[];
      for (final r in _all) {
        final ok = _scriptOf(r.world.id);
        for (final t in _texts(r.lesson)) {
          for (final rune in t.runes) {
            if (!ok(rune) && !_isNeutral(rune) && !_isEmoji(rune)) {
              stray.add('${r.lesson.id}: U+${rune.toRadixString(16)} in "$t"');
            }
          }
        }
      }
      expect(stray, isEmpty, reason: stray.take(10).join('\n'));
    });

    test('no invisible joiners, BOM, or orphaned vowel signs', () {
      final bad = <String>[];
      for (final r in _all) {
        for (final t in _texts(r.lesson)) {
          for (final rune in t.runes) {
            if ((rune >= 0x200B && rune <= 0x200F) || rune == 0xFEFF) {
              bad.add(
                  '${r.lesson.id}: invisible U+${rune.toRadixString(16)} in "$t"');
            }
          }
          for (final word in t.split(RegExp(r'\s+'))) {
            if (word.isNotEmpty && _isDependentMark(word.runes.first)) {
              bad.add('${r.lesson.id}: word "$word" starts with a vowel sign');
            }
          }
        }
      }
      expect(bad, isEmpty, reason: bad.join('\n'));
    });

    test('Telugu words never end in a bare virama', () {
      final bad = <String>[];
      for (final r in _all.where((r) => r.world.id == 'telugu')) {
        for (final t in _texts(r.lesson)) {
          for (final w in t.split(RegExp(r'\s+'))) {
            if (w.isNotEmpty && w.runes.last == 0x0C4D) {
              bad.add('${r.lesson.id}: "$w"');
            }
          }
        }
      }
      expect(bad, isEmpty);
    });

    test('emoji are not used as lesson content', () {
      final bad = <String>[
        for (final r in _all)
          if (r.lesson.symbol.runes.any(_isEmoji))
            '${r.lesson.id}: symbol "${r.lesson.symbol}"',
      ];
      expect(bad, isEmpty, reason: bad.join('\n'));
    });

    test('speech text can be spoken by the voice its locale selects', () {
      // An English voice cannot be assumed to read Telugu/Hindi/Tamil script.
      final bad = <String>[
        for (final r in _all)
          if (r.lesson.locale.startsWith('en') &&
              r.lesson.speech.runes.any((c) => c > 0x2FF))
            '${r.lesson.id}: "${r.lesson.speech}" sent to ${r.lesson.locale}',
      ];
      expect(bad, isEmpty, reason: bad.join('\n'));
    });
  });

  // ---------------------------------------------------------------------
  group('3 questions and answers', () {
    test('quiz lessons have 2+ options, a valid answer, and no duplicates', () {
      for (final r in _all.where((r) => _isQuiz(r.lesson))) {
        final l = r.lesson;
        expect(l.options.length, greaterThanOrEqualTo(2), reason: l.id);
        expect(l.options.toSet().length, l.options.length,
            reason: '${l.id} has duplicate options');
        expect(l.options.where((o) => o == l.answer).length, 1,
            reason: '${l.id} answer must appear exactly once');
        for (final o in l.options) {
          expect(o.trim(), o, reason: '${l.id} option "$o" has stray spaces');
          expect(o, isNotEmpty);
        }
      }
    });

    test('tracing lessons have no options (nothing to score)', () {
      for (final r in _all.where((r) => r.lesson.kind == LessonKind.tracing)) {
        expect(r.lesson.options, isEmpty, reason: r.lesson.id);
        expect(r.lesson.answer, isEmpty, reason: r.lesson.id);
      }
    });

    test('a letter question has exactly one option starting with that letter',
        () {
      for (final r in _all.where((r) => r.lesson.kind == LessonKind.alphabet)) {
        final l = r.lesson;
        if (l.symbol == '?') {
          expect(l.options.where((o) => o == l.answer).length, 1, reason: l.id);
          continue;
        }
        final letter = l.symbol.runes.first;
        final starting = l.options
            .where((o) =>
                o.runes.first == letter ||
                o
                    .toLowerCase()
                    .startsWith(String.fromCharCode(letter).toLowerCase()))
            .toList();
        expect(starting, [l.answer], reason: l.id);
      }
    });

    test('number-name options agree with the number-name table (English)', () {
      final lesson = _all.firstWhere((r) => r.lesson.id == 'num-names').lesson;
      String en(int n) => numberNames[n]!['en']!.toLowerCase();
      expect(lesson.answer, en(5));
      expect(lesson.options, contains(en(3)));
      expect(lesson.options, contains(en(7)));
      for (var n = 1; n <= 10; n++) {
        for (final lang in ['en', 'te', 'hi', 'ta']) {
          expect(numberNames[n]![lang]!.trim(), isNotEmpty, reason: '$n $lang');
        }
      }
    });

    test('sums and differences in the maths quests are arithmetically right',
        () {
      for (final r in _all.where((r) => r.world.id == 'numbers')) {
        final l = r.lesson;
        final m = RegExp(r'^(\d+) ([+−]) (\d+)$').firstMatch(l.symbol);
        if (m == null) continue;
        final a = int.parse(m.group(1)!), b = int.parse(m.group(3)!);
        final expected = m.group(2) == '+' ? a + b : a - b;
        expect(l.answer, '$expected', reason: l.id);
        expect(l.challenge, startsWith(l.symbol), reason: l.id);
        expect(l.options.where((o) => o == '$expected').length, 1);
      }
      final count = _all.firstWhere((r) => r.lesson.id == 'num-count').lesson;
      expect(count.answer, '${'★'.allMatches(count.symbol).length}');
    });

    test('a three-letter word with a missing letter has exactly one valid fill',
        () {
      // Tiny dictionaries for the two fill-the-blank quests.
      const english = {'CAT', 'COT', 'CUT'};
      const hindi = {'कमल'};
      for (final id in ['en-word', 'hi-word']) {
        final l = _all.firstWhere((r) => r.lesson.id == id).lesson;
        final words = id == 'en-word' ? english : hindi;
        final parts = l.symbol.replaceAll(' ', '').split('_');
        final fills = id == 'en-word'
            ? l.options.where((o) => words.contains('C${o}T')).toList()
            : l.options.where((o) => words.contains('क$oल')).toList();
        expect(fills, [l.answer],
            reason: '$id: "${l.symbol}" accepts $fills (parts $parts)');
      }
    });

    test('the prompt panel does not already show the answer', () {
      final bad = <String>[
        for (final r in _all.where((r) => _isQuiz(r.lesson)))
          if (r.lesson.symbol.replaceAll(' ', '') == r.lesson.answer)
            '${r.lesson.id}: shows "${r.lesson.symbol}", answer "${r.lesson.answer}"',
      ];
      expect(bad, isEmpty, reason: bad.join('\n'));
    });

    test('word-building quizzes give the child a picture clue', () {
      final bad = <String>[
        for (final r in _all.where((r) => r.lesson.kind == LessonKind.words))
          if (r.lesson.pictures.isEmpty && r.lesson.cover == null) r.lesson.id,
      ];
      expect(bad, isEmpty, reason: 'no picture: $bad');
    });

    test('story answers are stated in the story pages', () {
      // Comprehension needs the answer to be in the text the child read.
      final bad = <String>[];
      for (final r in _all.where((r) => r.lesson.kind == LessonKind.story)) {
        final pages = r.lesson.story.join(' ');
        final words = r.lesson.answer
            .split(' ')
            .where((w) => w.length > 1 && w.toLowerCase() != 'a')
            .toList();
        for (final w in words) {
          if (!pages.contains(w)) {
            bad.add('${r.lesson.id}: "$w" not in pages');
          }
        }
      }
      expect(bad, isEmpty, reason: bad.join('\n'));
    });

    test('the spoken line agrees with the on-screen story (key facts)', () {
      // Hand-listed facts that must match between speech and pages.
      const facts = {
        'hi-story': ['घाटी'],
        'en-story': ['found'],
        'ta-story': ['மலர்த்'],
      };
      final bad = <String>[];
      facts.forEach((id, words) {
        final l = _all.firstWhere((r) => r.lesson.id == id).lesson;
        for (final w in words) {
          if (l.speech.contains(w) != l.story.join(' ').contains(w)) {
            bad.add('$id: "$w" differs between speech and pages');
          }
        }
      });
      expect(bad, isEmpty, reason: bad.join('\n'));
    });
  });

  // ---------------------------------------------------------------------
  group('4 images and audio', () {
    test('every image path in the curriculum exists', () {
      final missing = <String>[];
      for (final r in _all) {
        final paths = [
          r.world.assetPath,
          ...r.lesson.pictures.values,
          if (r.lesson.cover != null) r.lesson.cover!,
          if (questArt[r.lesson.id] != null) questArt[r.lesson.id]!,
        ];
        for (final p in paths) {
          if (!File(p).existsSync()) missing.add('${r.lesson.id}: $p');
        }
      }
      expect(missing, isEmpty, reason: missing.join('\n'));
    });

    test('a picture map covers every option or none (no half-pictured quiz)',
        () {
      for (final r in _all.where((r) => r.lesson.pictures.isNotEmpty)) {
        expect(r.lesson.pictures.keys.toSet(), r.lesson.options.toSet(),
            reason: r.lesson.id);
      }
    });

    test('image files are real images of a sensible size', () {
      for (final r in _all) {
        final paths = [
          ...r.lesson.pictures.values,
          if (r.lesson.cover != null) r.lesson.cover!,
        ];
        for (final p in paths) {
          final bytes = File(p).readAsBytesSync();
          expect(bytes.length, greaterThan(5000), reason: '$p is tiny');
          expect(bytes.length, lessThan(2000000), reason: '$p is huge');
        }
      }
    });

    test('audio: no audio files exist, so spoken text must carry every lesson',
        () {
      final audio = Directory('assets')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => RegExp(r'\.(mp3|wav|ogg|m4a|aac)$').hasMatch(f.path))
          .toList();
      // This documents a fact: there is no recorded audio. Speech is Android
      // text-to-speech only, which is NOT verified here (needs real devices).
      expect(audio, isEmpty);
      for (final r in _all) {
        expect(r.lesson.speech.trim(), isNotEmpty, reason: r.lesson.id);
      }
    });

    test('no unused image files are shipped', () {
      final source = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.readAsStringSync())
          .join('\n');
      final dynamicFolders = [
        'assets/images/emblems/',
        'assets/images/avatars/'
      ];
      final unused = <String>[];
      for (final f in Directory('assets/images')
          .listSync(recursive: true)
          .whereType<File>()) {
        final path = f.path.replaceAll('\\', '/');
        if (dynamicFolders.any(path.contains)) continue;
        if (!source.contains(path)) unused.add(path);
      }
      expect(unused, isEmpty, reason: unused.join('\n'));
    });

    test('no dead curriculum data is left in the code', () {
      final source = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) =>
              f.path.endsWith('.dart') && !f.path.endsWith('curriculum.dart'))
          .map((f) => f.readAsStringSync())
          .join('\n');
      final dead = <String>[
        if (!source.contains('numberNames')) 'numberNames (table of 1-10)',
        if (!RegExp(r'\.emoji\b').hasMatch(source))
          'LearningWorld.emoji (5 values)',
      ];
      expect(dead, isEmpty, reason: 'never read: $dead');
    });
  });

  // ---------------------------------------------------------------------
  group('5 age fit', () {
    test('a 3-year-old and a 12-year-old are offered different content', () {
      final young = _controller();
      final old = _controller();
      young.activeProfile =
          const ChildProfile(id: 'p', name: 'A', age: 3, avatar: 'lion');
      old.activeProfile =
          const ChildProfile(id: 'p', name: 'B', age: 12, avatar: 'lion');
      for (final w in curriculum) {
        expect(
            old.recommendedLesson(w.forStage(ExperienceStage.champion)).id !=
                young
                    .recommendedLesson(w.forStage(ExperienceStage.explorer))
                    .id,
            isTrue,
            reason: '${w.id}: same first quest for ages 3 and 12');
      }
    });

    test('every age band has at least one quest meant for it', () {
      // The Lesson model has no age or difficulty field at all.
      final fields = File('lib/src/models.dart').readAsStringSync();
      final lessonClass = fields.substring(
        fields.indexOf('class Lesson {'),
        fields.indexOf('class LearningWorld'),
      );
      expect(
          lessonClass.toLowerCase().contains('age') ||
              lessonClass.toLowerCase().contains('level') ||
              lessonClass.toLowerCase().contains('difficulty'),
          isTrue,
          reason: 'Lesson has no age/level/difficulty field');
    });

    test('each Indic world teaches more than one letter', () {
      for (final id in ['telugu', 'hindi', 'tamil', 'english']) {
        final w = curriculum.firstWhere((w) => w.id == id);
        final letters = w.lessons
            .where((l) => l.kind == LessonKind.alphabet)
            .map((l) => l.answer)
            .toSet();
        expect(letters.length, greaterThan(1),
            reason: '$id teaches ${letters.length} letter(s)');
      }
    });

    test('tracing instructions that mention dots refer to dots that are drawn',
        () {
      final src = File('lib/src/screens/lesson_screen.dart').readAsStringSync();
      final mentionsDots = _all
          .where((r) => r.lesson.kind == LessonKind.tracing)
          .any((r) =>
              ['చుక్క', 'बिंदु', 'புள்ளி'].any(r.lesson.challenge.contains));
      final drawsDots = src.contains('drawPoints') || src.contains('dotted');
      expect(mentionsDots && !drawsDots, isFalse,
          reason: 'instructions mention dots but none are drawn');
    });
  });

  // ---------------------------------------------------------------------
  group('6 behaviour: every quest, answers, feedback', () {
    testWidgets('every quest opens from its world map', (tester) async {
      await _setView(tester, const Size(800, 360));
      for (final w in curriculum) {
        for (final stage in ExperienceStage.values) {
          final stageWorld = w.forStage(stage);
          for (final l in stageWorld.lessons) {
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(
              AppScope(
                controller: _controller(age: _ageFor(stage)),
                child: MaterialApp(
                  theme: buildTheme(),
                  home: WorldMapScreen(world: stageWorld),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final card = find.byKey(Key('lesson_${l.id}'));
            final trail = tester.widget<ListView>(
              find.byKey(const Key('quest_trail')),
            );
            final scroll = trail.controller!;
            final index = stageWorld.lessons.indexOf(l);
            scroll.jumpTo(
              (index * 344.0).clamp(0, scroll.position.maxScrollExtent),
            );
            await tester.pumpAndSettle();
            await tester.ensureVisible(card);
            await tester.pumpAndSettle();
            await tester.tap(card);
            await tester.pumpAndSettle();
            expect(find.byType(LessonScreen), findsOneWidget, reason: l.id);
            expect(tester.takeException(), isNull, reason: l.id);
          }
        }
      }
    });

    testWidgets('every quest opens directly with no error at 4 sizes', (
      tester,
    ) async {
      for (final size in const [
        Size(640, 360),
        Size(800, 360),
        Size(960, 540),
        Size(1280, 800),
      ]) {
        await _setView(tester, size);
        for (final r in _all) {
          await _openLesson(tester, r);
          expect(tester.takeException(), isNull,
              reason: '${r.lesson.id} $size');
        }
      }
    });

    testWidgets('the correct answer is accepted in every quiz', (tester) async {
      await _setView(tester, const Size(800, 360));
      for (final r in _all.where((r) => _isQuiz(r.lesson))) {
        await _openLesson(tester, r);
        await _finishStory(tester, r.lesson);
        await _answer(tester, r.lesson.answer);
        expect(find.bySemanticsLabel('Wonderful!'), findsOneWidget,
            reason: '${r.lesson.id}: correct answer not accepted');
      }
    });

    testWidgets('a wrong answer gets "Good try" feedback in every quiz', (
      tester,
    ) async {
      await _setView(tester, const Size(800, 360));
      for (final r in _all.where((r) => _isQuiz(r.lesson))) {
        await _openLesson(tester, r);
        await _finishStory(tester, r.lesson);
        final wrong = r.lesson.options.firstWhere((o) => o != r.lesson.answer);
        await _answer(tester, wrong);
        expect(find.bySemanticsLabel('Good try!'), findsOneWidget,
            reason: '${r.lesson.id}: wrong answer got no feedback');
        expect(find.byKey(const Key('result_again')), findsOneWidget);
        expect(find.byKey(const Key('result_back')), findsOneWidget);
      }
    });

    testWidgets('every wrong option (not just one) is rejected',
        (tester) async {
      await _setView(tester, const Size(800, 360));
      for (final r in _all.where((r) => _isQuiz(r.lesson))) {
        for (final wrong
            in r.lesson.options.where((o) => o != r.lesson.answer)) {
          await _openLesson(tester, r);
          await _finishStory(tester, r.lesson);
          await _answer(tester, wrong);
          expect(find.bySemanticsLabel('Good try!'), findsOneWidget,
              reason: '${r.lesson.id}: "$wrong" was accepted');
        }
      }
    });

    testWidgets(
      'the Check Answer button is on screen without scrolling (AUD-031, fixed)',
      (tester) async {
        final bad = <String>[];
        for (final size in const [
          Size(640, 360),
          Size(800, 360),
          Size(960, 540),
          Size(1280, 800),
        ]) {
          await _setView(tester, size);
          for (final r in _all.where((r) =>
              _isQuiz(r.lesson) &&
              r.lesson.pictures.isEmpty &&
              !(r.world.id == 'numbers' && r.lesson.id != 'num-names'))) {
            await _openLesson(tester, r);
            await _finishStory(tester, r.lesson);
            final rect = tester.getRect(find.byKey(const Key('check_answer')));
            if (rect.bottom > size.height) {
              bad.add(
                  '${r.lesson.id} at ${size.width.toInt()}x${size.height.toInt()}: '
                  'Check Answer bottom ${rect.bottom.toStringAsFixed(0)} > ${size.height.toInt()}');
            }
          }
        }
        expect(bad, isEmpty, reason: bad.join('\n'));
      },
    );

    testWidgets('tracing cannot be finished before anything is drawn', (
      tester,
    ) async {
      await _setView(tester, const Size(800, 360));
      for (final r in _all.where((r) => r.lesson.kind == LessonKind.tracing)) {
        await _openLesson(tester, r);
        final finish = find.byKey(const Key('finish_trace'));
        expect(tester.widget<FilledButton>(finish).onPressed, isNull,
            reason: '${r.lesson.id}: finish enabled before any drawing');
      }
    });

    testWidgets(
      'a meaningless scribble far from the letter does not pass tracing',
      (tester) async {
        final accepted = <String>[];
        await _setView(tester, const Size(800, 360));
        for (final r
            in _all.where((r) => r.lesson.kind == LessonKind.tracing)) {
          await _openLesson(tester, r);
          final finish = find.byKey(const Key('finish_trace'));
          // A zig-zag in the corner, nowhere near the letter's shape.
          final pad = find.byKey(const Key('trace_pad'));
          final g = await tester
              .startGesture(tester.getTopLeft(pad) + const Offset(5, 5));
          for (var i = 0; i < 20; i++) {
            await g.moveBy(Offset(i.isEven ? 6 : -6, 4));
            await tester.pump(const Duration(milliseconds: 16));
          }
          await g.up();
          await tester.pumpAndSettle();
          if (tester.widget<FilledButton>(finish).onPressed != null) {
            accepted.add(r.lesson.id);
          }
        }
        expect(accepted, isEmpty, reason: 'scribble accepted in: $accepted');
      },
    );
  });

  // ---------------------------------------------------------------------
  group('7 progress and rewards', () {
    late Directory temp;
    late File file;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('aksharamala_audit_');
      file = File('${temp.path}/progress.json');
    });

    tearDown(() async => temp.delete(recursive: true));

    test('completing every quest is saved and restored exactly', () async {
      final c = AppController(store: LocalStore(fileOverride: file));
      await c.initialise();
      await c.addProfile('Audit', 7, 'lion');
      for (final r in _all) {
        await c.recordResult(world: r.world, lesson: r.lesson, correct: true);
      }
      final again = AppController(store: LocalStore(fileOverride: file));
      await again.initialise();
      expect(again.activeProgress.completedLessons,
          _all.map((r) => r.lesson.id).toSet());
      expect(again.activeProfile!.stars, _all.length * 3);
      expect(
          again.activeProgress.earnedBadges,
          containsAll(
              ['first-step', 'world-walker', 'bright-star', 'all-world-hero']));
      for (final w in curriculum) {
        expect(again.completedInWorld(w), w.lessons.length, reason: w.id);
      }
    });

    test('rewards cannot be repeated: every quest pays at most 3 stars',
        () async {
      final c = AppController(store: _NoDiskStore())
        ..profiles = const [
          ChildProfile(id: 'p', name: 'A', age: 6, avatar: 'lion'),
        ]
        ..progress = {'p': ProgressRecord.empty()}
        ..activeProfile =
            const ChildProfile(id: 'p', name: 'A', age: 6, avatar: 'lion')
        ..loaded = true;
      for (var round = 0; round < 5; round++) {
        for (final r in _all) {
          await c.recordResult(
              world: r.world, lesson: r.lesson, correct: round.isEven);
          await c.recordResult(world: r.world, lesson: r.lesson, correct: true);
        }
      }
      expect(c.activeProfile!.stars, _all.length * 3);
    });

    test('a wrong answer alone never completes a quest', () async {
      final c = _controller();
      for (final r in _all) {
        for (var i = 0; i < 5; i++) {
          await c.recordResult(
              world: r.world, lesson: r.lesson, correct: false);
        }
      }
      expect(c.activeProgress.completedLessons, isEmpty);
      expect(c.activeProfile!.stars, _all.length * 3,
          reason: 'at most 3 per quest');
      expect(c.activeProgress.earnedBadges, isEmpty);
    });

    test('no quest is locked: finishing in any order works', () async {
      final c = _controller();
      for (final r in _all.reversed) {
        await c.recordResult(world: r.world, lesson: r.lesson, correct: true);
      }
      expect(c.activeProgress.completedLessons.length, _all.length);
      for (final w in curriculum) {
        // After mastery a world still recommends something valid.
        expect(w.lessons.map((l) => l.id), contains(c.recommendedLesson(w).id));
      }
    });

    testWidgets('every quest card is tappable from the start (no locks)', (
      tester,
    ) async {
      await _setView(tester, const Size(960, 540));
      for (final w in curriculum) {
        for (final stage in ExperienceStage.values) {
          final stageWorld = w.forStage(stage);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            AppScope(
              controller: _controller(age: _ageFor(stage)),
              child: MaterialApp(
                theme: buildTheme(),
                home: WorldMapScreen(world: stageWorld),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final first = tester.widget<InkWell>(
            find.byKey(Key('lesson_${stageWorld.lessons.first.id}')),
          );
          expect(first.onTap, isNotNull);
          expect(tester.takeException(), isNull, reason: '${w.id} $stage');
        }
      }
    });
  });
}

String entryTrim(String s) => s.trim();
