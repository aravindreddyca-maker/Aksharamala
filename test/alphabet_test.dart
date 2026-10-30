import 'dart:io';
import 'dart:math' as math;

import 'package:aksharamala/src/alphabet/alphabet_data.dart';
import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/content/content_loader.dart';
import 'package:aksharamala/src/content/content_models.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/handwriting/glyph_mask.dart';
import 'package:aksharamala/src/handwriting/handwriting_registry.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/alphabet_screen.dart';
import 'package:aksharamala/src/screens/world_map_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoDiskStore extends LocalStore {
  @override
  Future<LocalSnapshot> load() async =>
      const LocalSnapshot(profiles: [], progress: {});
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

/// A stand-in for the font: a plain ring, so a drawn circle traces it.
Future<GlyphMask> _ring(String glyph) async {
  const n = 32;
  return GlyphMask(n, [
    for (var y = 0; y < n; y++)
      for (var x = 0; x < n; x++)
        ((math.sqrt(math.pow((x + .5) / n - .5, 2) +
                        math.pow((y + .5) / n - .5, 2)) -
                    .28)
                .abs() <=
            .04),
  ]);
}

AppController _controller() {
  const profile = ChildProfile(id: 'p', name: 'Meena', age: 4, avatar: 'lion');
  return AppController(store: _NoDiskStore())
    ..profiles = [profile]
    ..progress = {'p': ProgressRecord.empty()}
    ..activeProfile = profile
    ..loaded = true;
}

void main() {
  final loaded = loadContentDirectory('content/pack_v2/content');
  List<String> packLetters(ContentModule m) => [
        for (final l in loaded.packs.firstWhere((p) => p.module == m).lessons)
          if (l.type == 'recognition') l.target,
      ];

  group('the alphabets', () {
    test('cover every letter in the pack, once each', () {
      expect(englishAlphabet.letters.length, 26);
      expect(teluguAlphabet.letters.length, 51);
      expect(hindiAlphabet.letters.length, 46);
      expect(tamilAlphabet.letters.length, 30);
      for (final (set, module) in [
        (teluguAlphabet, ContentModule.telugu),
        (hindiAlphabet, ContentModule.hindi),
        (tamilAlphabet, ContentModule.tamil),
      ]) {
        expect(set.letters.map((l) => l.glyph).toList(), packLetters(module),
            reason: '${set.worldId} letters and order');
      }
      expect(englishAlphabet.letters.map((l) => l.glyph).toList(),
          [for (var c = 65; c <= 90; c++) String.fromCharCode(c)]);
      expect(englishAlphabet.letters.map((l) => l.glyph).toSet(),
          packLetters(ContentModule.english).toSet());
    });

    test('words are real pack words that start with their letter', () {
      final vocab = {
        for (final p in loaded.packs)
          p.module.name: {
            for (final l in p.lessons)
              if (l.type == 'picture_word_match') l.target.toLowerCase(),
          },
      };
      for (final set in alphabets.values) {
        for (final l in set.letters.where((l) => l.word != null)) {
          expect(vocab[set.worldId], contains(l.word!.toLowerCase()),
              reason: '${set.worldId} ${l.glyph} ${l.word}');
          final lead =
              set.worldId == 'tamil' ? l.glyph.replaceAll('்', '') : l.glyph;
          expect(l.word!.toLowerCase().startsWith(lead.toLowerCase()), isTrue,
              reason: '${l.word} must start with ${l.glyph}');
        }
      }
    });

    test('every picture named exists on disk', () {
      for (final set in alphabets.values) {
        for (final l in set.letters.where((l) => l.picture != null)) {
          expect(File(l.picture!).existsSync(), isTrue, reason: l.picture);
        }
      }
    });

    test('every English letter has its picture except Q (queen)', () {
      final without = [
        for (final l in englishAlphabet.letters)
          if (l.picture == null) l.glyph,
      ];
      expect(without, ['Q'],
          reason:
              'the supplied queen is cropped at the hem, so it is not shipped');
      for (final l in englishAlphabet.letters.where((l) => l.picture != null)) {
        final b = File(l.picture!).readAsBytesSync();
        // WebP (RIFF....WEBP) or one of the first art set's PNGs.
        final isWebp = String.fromCharCodes(b.sublist(8, 12)) == 'WEBP';
        final isPng =
            b[0] == 0x89 && String.fromCharCodes(b.sublist(1, 4)) == 'PNG';
        expect(isWebp || isPng, isTrue, reason: l.picture);
      }
    });

    test('lesson ids are unique and never collide with real quests', () {
      final real = {for (final w in curriculum) ...w.lessons.map((l) => l.id)};
      final ids = [
        for (final s in alphabets.values)
          for (var i = 0; i < s.letters.length; i++) s.lessonId(i),
      ];
      expect(ids.toSet().length, ids.length);
      expect(ids.where(real.contains), isEmpty);
      expect(englishAlphabet.lessonId(1), 'alpha-english-002');
    });

    test('letters with no natural word are shown on their own', () {
      expect(teluguAlphabet.letters.firstWhere((l) => l.glyph == 'ఋ').word,
          isNull);
      expect(
          teluguAlphabet.letters.firstWhere((l) => l.glyph == 'ఋ').speech, 'ఋ');
      expect(englishAlphabet.letters.first.speech, 'A. Apple.');
    });
  });

  Future<AppController> openAlphabet(
    WidgetTester tester, {
    String world = 'english',
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(960, 540);
    addTearDown(tester.view.reset);
    final c = _controller();
    final w = curriculum.firstWhere((w) => w.id == world);
    await tester.pumpWidget(
      AppScope(
        controller: c,
        child: MaterialApp(
          theme: buildTheme(),
          home: AlphabetScreen(
            world: w,
            letters: alphabets[world]!,
            maskLoader: _ring,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  /// Writes the letter on screen: its stroke template where it has one (the
  /// English capitals), otherwise a ring, which traces the stand-in font mask.
  Future<void> traceRing(WidgetTester tester) async {
    final rect = tester.getRect(find.byKey(const Key('letter_pad')));
    final glyph =
        tester.widget<Text>(find.byKey(const Key('letter_big'))).data!;
    final template = templateFor(glyph);
    final strokes = template != null
        ? [
            for (final s in template.strokes)
              [
                for (final p in s)
                  Offset(rect.left + rect.width * p.x,
                      rect.top + rect.height * p.y),
              ],
          ]
        : [
            [
              for (var k = 0; k <= 40; k++)
                Offset(
                  rect.left +
                      rect.width * (.5 + .28 * math.sin(2 * math.pi * k / 40)),
                  rect.top +
                      rect.height * (.5 - .28 * math.cos(2 * math.pi * k / 40)),
                ),
            ],
          ];
    for (final pts in strokes) {
      final g = await tester.startGesture(pts.first);
      for (final p in pts.skip(1)) {
        await g.moveTo(p);
        await tester.pump();
      }
      await g.up();
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('write_check')));
    await tester.pump();
  }

  group('learning every letter', () {
    testWidgets('all 26 letters are on one page and none is locked',
        (tester) async {
      await openAlphabet(tester);
      expect(find.text('0 of 26 letters traced'), findsOneWidget);
      expect(find.text('Start with the first letter'), findsOneWidget);
      for (var i = 0; i < 26; i++) {
        await tester.ensureVisible(find.byKey(Key('letter_tile_$i')));
        expect(find.byKey(Key('letter_tile_$i')), findsOneWidget);
      }
    });

    testWidgets('tracing A saves it and offers B next, then B opens',
        (tester) async {
      final c = await openAlphabet(tester);
      await tester.tap(find.byKey(const Key('alphabet_continue')));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsWidgets);
      expect(find.byKey(const Key('letter_word')), findsOneWidget);
      // The next button is not offered until A has been traced.
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('next_letter')))
            .onPressed,
        isNull,
      );
      await traceRing(tester);
      expect(find.text('Traced! +3 stars'), findsOneWidget);
      final next =
          tester.widget<FilledButton>(find.byKey(const Key('next_letter')));
      expect(next.onPressed, isNotNull);
      expect(find.text('Next: B'), findsOneWidget);
      expect(c.activeProgress.completedLessons, contains('alpha-english-001'));
      expect(c.activeProfile!.stars, 3);

      await tester.tap(find.byKey(const Key('next_letter')));
      await tester.pumpAndSettle();
      expect(
          tester.widget<Text>(find.byKey(const Key('letter_big'))).data, 'B');
      expect(find.text('2 / 26'), findsOneWidget);
    });

    testWidgets('a scribble does not finish a letter', (tester) async {
      final c = await openAlphabet(tester);
      await tester.tap(find.byKey(const Key('letter_tile_0')));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byKey(const Key('letter_pad')));
      final rnd = math.Random(4);
      final g = await tester.startGesture(rect.topLeft + const Offset(10, 10));
      for (var i = 0; i < 40; i++) {
        await g.moveTo(rect.topLeft +
            Offset(
                rnd.nextDouble() * rect.width, rnd.nextDouble() * rect.height));
        await tester.pump();
      }
      await g.up();
      await tester.tap(find.byKey(const Key('write_check')));
      await tester.pump();
      expect(find.text('Traced!'), findsNothing);
      expect(c.activeProgress.completedLessons, isEmpty);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('next_letter')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('any letter can be opened, and arrows move freely',
        (tester) async {
      await openAlphabet(tester);
      await tester.ensureVisible(find.byKey(const Key('letter_tile_9')));
      await tester.tap(find.byKey(const Key('letter_tile_9')));
      await tester.pumpAndSettle();
      expect(
          tester.widget<Text>(find.byKey(const Key('letter_big'))).data, 'J');
      await tester.tap(find.byKey(const Key('next_arrow')));
      await tester.pumpAndSettle();
      expect(
          tester.widget<Text>(find.byKey(const Key('letter_big'))).data, 'K');
      await tester.tap(find.byKey(const Key('prev_letter')));
      await tester.pumpAndSettle();
      expect(
          tester.widget<Text>(find.byKey(const Key('letter_big'))).data, 'J');
    });

    testWidgets('the last letter ends with a way back, not a dead end',
        (tester) async {
      await openAlphabet(tester);
      await tester.ensureVisible(find.byKey(const Key('letter_tile_25')));
      await tester.tap(find.byKey(const Key('letter_tile_25')));
      await tester.pumpAndSettle();
      expect(find.text('All letters'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('next_arrow')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('Telugu letters work the same way', (tester) async {
      await openAlphabet(tester, world: 'telugu');
      expect(find.text('0 of 51 letters traced'), findsOneWidget);
      await tester.tap(find.byKey(const Key('alphabet_continue')));
      await tester.pumpAndSettle();
      await traceRing(tester);
      expect(find.text('Next: ఆ'), findsOneWidget);
    });

    testWidgets('the progress page remembers traced letters', (tester) async {
      final c = await openAlphabet(tester);
      await tester.tap(find.byKey(const Key('alphabet_continue')));
      await tester.pumpAndSettle();
      await traceRing(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('1 of 26 letters traced'), findsOneWidget);
      expect(c.activeProgress.completedLessons, contains('alpha-english-001'));
      // "Next letter" now points at B.
      await tester.tap(find.byKey(const Key('alphabet_continue')));
      await tester.pumpAndSettle();
      expect(
          tester.widget<Text>(find.byKey(const Key('letter_big'))).data, 'B');
    });

    testWidgets('a traced letter pays 3 stars once, however often it is redone',
        (tester) async {
      final c = await openAlphabet(tester);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const Key('letter_tile_0')));
        await tester.pumpAndSettle();
        await traceRing(tester);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      expect(c.activeProfile!.stars, 3);
    });
  });

  group('the world map', () {
    for (final id in ['english', 'telugu', 'hindi', 'tamil']) {
      testWidgets('$id has an All letters button', (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(960, 540);
        addTearDown(tester.view.reset);
        final w = curriculum.firstWhere((w) => w.id == id);
        await tester.pumpWidget(
          AppScope(
            controller: _controller(),
            child: MaterialApp(
                theme: buildTheme(), home: WorldMapScreen(world: w)),
          ),
        );
        await tester.pump();
        expect(find.byKey(const Key('all_letters')), findsOneWidget);
        await tester.tap(find.byKey(const Key('all_letters')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('alphabet_progress_text')), findsOneWidget);
      });
    }

    testWidgets('All letters is the first card of the trail, before quest 1',
        (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(960, 540);
      addTearDown(tester.view.reset);
      final c = _controller();
      final w = curriculum.firstWhere((w) => w.id == 'english');
      await tester.pumpWidget(
        AppScope(
          controller: c,
          child:
              MaterialApp(theme: buildTheme(), home: WorldMapScreen(world: w)),
        ),
      );
      await tester.pumpAndSettle();
      final card = tester.getRect(find.byKey(const Key('all_letters')));
      final quest =
          tester.getRect(find.byKey(Key('lesson_${w.lessons.first.id}')));
      expect(card.left, lessThan(quest.left));
      expect(find.text('0 of 26 traced'), findsOneWidget);
      // It is part of the trail, not a button in the header.
      expect(
        find.descendant(
          of: find.byKey(const Key('quest_trail')),
          matching: find.byKey(const Key('all_letters')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the map opens on All letters even when later quests are done',
        (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(960, 540);
      addTearDown(tester.view.reset);
      final w = curriculum.firstWhere((w) => w.id == 'english');
      final c = _controller();
      c.progress['p'] = ProgressRecord(
        completedLessons: {w.lessons[0].id, w.lessons[1].id, w.lessons[2].id},
        attempts: const {},
        correct: const {},
        lastPlayed: const {},
        earnedBadges: const {},
      );
      await tester.pumpWidget(
        AppScope(
          controller: c,
          child:
              MaterialApp(theme: buildTheme(), home: WorldMapScreen(world: w)),
        ),
      );
      await tester.pumpAndSettle();
      final card = tester.getRect(find.byKey(const Key('all_letters')));
      expect(card.left, greaterThanOrEqualTo(0));
      expect(card.right, lessThanOrEqualTo(960));
    });

    testWidgets('Number Galaxy has none: numbers are not an alphabet',
        (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(960, 540);
      addTearDown(tester.view.reset);
      final w = curriculum.firstWhere((w) => w.id == 'numbers');
      await tester.pumpWidget(
        AppScope(
          controller: _controller(),
          child:
              MaterialApp(theme: buildTheme(), home: WorldMapScreen(world: w)),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('all_letters')), findsNothing);
    });
  });
}
