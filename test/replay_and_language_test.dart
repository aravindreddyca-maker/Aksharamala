import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/result_text.dart';
import 'package:aksharamala/src/screens/achievements_screen.dart';
import 'package:aksharamala/src/screens/lesson_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoDiskStore extends LocalStore {
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

const _sizes = <Size>[
  Size(640, 360),
  Size(800, 360),
  Size(960, 540),
  Size(1280, 800),
];

AppController _controller({Set<String> done = const {}}) {
  const profile = ChildProfile(id: 'p', name: 'Meena', age: 6, avatar: 'lion');
  return AppController(store: _NoDiskStore())
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

LearningWorld _world(String id) => curriculum.firstWhere((w) => w.id == id);

Future<void> _open(
  WidgetTester tester,
  LearningWorld world,
  Lesson lesson, {
  Size size = const Size(960, 540),
  double scale = 1.0,
  Random? random,
  Set<String> done = const {},
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    AppScope(
      controller: _controller(done: done),
      child: MaterialApp(
        theme: buildTheme(),
        home: LessonScreen(world: world, lesson: lesson, random: random),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The answers on screen, top to bottom.
List<String> _order(WidgetTester tester, Lesson lesson) {
  final shown = [
    for (final o in lesson.options)
      if (find.byKey(Key('answer_$o')).evaluate().isNotEmpty) o,
  ];
  shown.sort(
    (a, b) => tester
        .getTopLeft(find.byKey(Key('answer_$a')))
        .dy
        .compareTo(tester.getTopLeft(find.byKey(Key('answer_$b'))).dy),
  );
  return shown;
}

void main() {
  group('answer order', () {
    test('every quest lists the right answer first, so shuffling matters', () {
      // This is why the order cannot stay as authored: a child would learn
      // "tap the top one".
      final firstIsRight = <String>[];
      for (final world in curriculum) {
        for (final lesson in world.lessons) {
          if (lesson.options.isNotEmpty &&
              lesson.options.first == lesson.answer) {
            firstIsRight.add(lesson.id);
          }
        }
      }
      expect(firstIsRight.length, greaterThan(8));
    });

    testWidgets('the right answer does not always sit at the top', (
      tester,
    ) async {
      final world = _world('english');
      final lesson = world.lessons.first;
      final tops = <int>{};
      for (var seed = 0; seed < 40; seed++) {
        await _open(tester, world, lesson, random: Random(seed));
        tops.add(_order(tester, lesson).indexOf(lesson.answer));
      }
      expect(tops, {0, 1, 2}, reason: 'answer lands in every slot over time');
    });

    testWidgets('a screen handed a different lesson reshuffles for it', (
      tester,
    ) async {
      final world = _world('numbers');
      Future<void> show(Lesson lesson) async {
        await tester.pumpWidget(
          AppScope(
            controller: _controller(),
            child: MaterialApp(
              theme: buildTheme(),
              home: LessonScreen(
                world: world,
                lesson: lesson,
                random: Random(1),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      final count = world.lessons.firstWhere((l) => l.id == 'num-count');
      final add = world.lessons.firstWhere((l) => l.id == 'num-add');
      await show(count);
      expect(_order(tester, count).toSet(), count.options.toSet());
      await show(add); // same screen type, same place: state is reused
      expect(_order(tester, add).toSet(), add.options.toSet());
      expect(tester.takeException(), isNull);
    });

    testWidgets('same answers, nothing lost or invented, in every quest', (
      tester,
    ) async {
      for (final world in curriculum) {
        for (final lesson in world.lessons) {
          if (lesson.options.isEmpty || lesson.kind == LessonKind.story) {
            continue;
          }
          await _open(tester, world, lesson, random: Random(3));
          expect(
            _order(tester, lesson).toSet(),
            lesson.options.toSet(),
            reason: lesson.id,
          );
          expect(_order(tester, lesson).length, lesson.options.length);
          expect(tester.takeException(), isNull, reason: lesson.id);
        }
      }
    });

    testWidgets('Play again always gives a different order', (tester) async {
      final world = _world('english');
      final lesson = world.lessons.first;
      for (var seed = 0; seed < 12; seed++) {
        await _open(tester, world, lesson, random: Random(seed));
        var before = _order(tester, lesson);
        for (var round = 0; round < 4; round++) {
          await tester.tap(find.byKey(const Key('answer_Ball')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('result_again')));
          await tester.pumpAndSettle();
          final after = _order(tester, lesson);
          expect(after, isNot(before), reason: 'seed $seed round $round');
          before = after;
        }
      }
    });

    testWidgets('picture answers keep their own picture after shuffling', (
      tester,
    ) async {
      final world = _world('tamil');
      final lesson = world.lessons.first; // ta-a, three picture answers
      await _open(tester, world, lesson, random: Random(5));
      for (final entry in lesson.pictures.entries) {
        final tile = find.byKey(Key('answer_${entry.key}'));
        final image = tester.widget<Image>(
          find.descendant(of: tile, matching: find.byType(Image)),
        );
        expect(
          ((image.image as ResizeImage).imageProvider as AssetImage).assetName,
          entry.value,
          reason: entry.key,
        );
      }
    });

    testWidgets('the right tile still scores right wherever it lands', (
      tester,
    ) async {
      final world = _world('english');
      final lesson = world.lessons.first;
      await _open(tester, world, lesson, random: Random(9));
      await tester.tap(find.byKey(Key('answer_${lesson.answer}')));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Wonderful!'), findsOneWidget);
    });

    testWidgets('shuffled quests still fit at every size and text scale', (
      tester,
    ) async {
      final world = _world('tamil');
      for (final size in _sizes) {
        for (final scale in [1.0, 1.3]) {
          for (final lesson in world.lessons.take(2)) {
            await _open(
              tester,
              world,
              lesson,
              size: size,
              scale: scale,
              random: Random(size.width.toInt()),
            );
            expect(tester.takeException(), isNull, reason: '$size $scale');
            for (final option in lesson.options) {
              final r = tester.getRect(find.byKey(Key('answer_$option')));
              expect(r.height, greaterThanOrEqualTo(56));
              expect(r.bottom, lessThanOrEqualTo(size.height));
            }
          }
        }
      }
    });
  });

  group('pop-up language', () {
    test('locales map to the right language', () {
      expect(languageForLocale('ta-IN'), QuestLanguage.tamil);
      expect(languageForLocale('te-IN'), QuestLanguage.telugu);
      expect(languageForLocale('hi-IN'), QuestLanguage.hindi);
      expect(languageForLocale('en-US'), QuestLanguage.english);
      expect(languageForLocale('en-IN'), QuestLanguage.english);
      expect(languageForLocale('xx'), QuestLanguage.english);
    });

    test('every language has every sentence, filled in and its own script', () {
      for (final locale in ['en-US', 'ta-IN', 'te-IN', 'hi-IN']) {
        final t = ResultText.forLocale(locale);
        final all = {
          'earned2': t.message(correct: true, gained: 2),
          'earned3': t.message(correct: true, gained: 3),
          'earned1': t.message(correct: true, gained: 1),
          'already': t.message(correct: true, gained: 0),
          'courage': t.message(correct: false, gained: 1),
          'tryAgain': t.message(correct: false, gained: 0),
          'again': t.playAgain,
          'back': t.backToMap,
        };
        for (final e in all.entries) {
          expect(e.value.trim(), isNotEmpty, reason: '$locale ${e.key}');
          expect(e.value, isNot(contains(r'$')), reason: '$locale ${e.key}');
        }
        expect(all['earned3'], contains('3'), reason: locale);
        expect(all['earned2'], contains('2'), reason: locale);
        expect(all['earned1'], contains('1'), reason: locale);
        // Six different sentences, so a state is never reported as another.
        expect(
          {
            all['earned3'],
            all['earned1'],
            all['already'],
            all['courage'],
            all['tryAgain'],
          }.length,
          5,
          reason: locale,
        );
        if (locale != 'en-US') {
          final script = switch (languageForLocale(locale)) {
            QuestLanguage.tamil => RegExp('[஀-௿]'),
            QuestLanguage.telugu => RegExp('[ఀ-౿]'),
            _ => RegExp('[ऀ-ॿ]'),
          };
          for (final e in all.entries) {
            expect(
              script.hasMatch(e.value),
              isTrue,
              reason: '$locale ${e.key} is not in its own script',
            );
            expect(
              RegExp('[A-Za-z]').hasMatch(e.value),
              isFalse,
              reason: '$locale ${e.key} still has English words',
            );
          }
        }
      }
    });

    test('english message wording is unchanged', () {
      expect(
        questResultMessage(correct: true, gained: 3),
        'You earned 3 stars and completed this quest.',
      );
      expect(
        questResultMessage(correct: false, gained: 1),
        contains('courage star'),
      );
    });

    for (final entry in {
      'tamil': 'ta-IN',
      'telugu': 'te-IN',
      'hindi': 'hi-IN',
      'english': 'en-US',
    }.entries) {
      for (final correct in [true, false]) {
        testWidgets(
          '${entry.key} quest pop-up (${correct ? 'right' : 'wrong'}) is in its language',
          (tester) async {
            final world = _world(entry.key);
            final lesson = world.lessons.first;
            expect(lesson.locale, startsWith(entry.value.substring(0, 2)));
            await _open(tester, world, lesson, size: const Size(800, 360));
            final wrong = lesson.options.firstWhere((o) => o != lesson.answer);
            await tester.tap(
              find.byKey(Key('answer_${correct ? lesson.answer : wrong}')),
            );
            await tester.pumpAndSettle();
            final text = ResultText.forLocale(entry.value);
            expect(tester.takeException(), isNull);
            expect(find.text(text.playAgain), findsOneWidget);
            expect(find.text(text.backToMap), findsOneWidget);
            expect(
              find.text(
                  text.message(correct: correct, gained: correct ? 3 : 1)),
              findsOneWidget,
            );
            if (entry.key != 'english') {
              expect(find.text('Play again'), findsNothing);
              expect(find.text('Back to map'), findsNothing);
            }
            // Buttons are on screen and big enough.
            for (final key in ['result_again', 'result_back']) {
              final r = tester.getRect(find.byKey(Key(key)));
              expect(r.height, greaterThanOrEqualTo(48));
              expect(r.bottom, lessThanOrEqualTo(360));
              expect(r.right, lessThanOrEqualTo(800));
            }
          },
        );
      }
    }

    testWidgets('the pop-up fits at every size and text scale in Tamil', (
      tester,
    ) async {
      final world = _world('tamil');
      final lesson = world.lessons.first;
      for (final size in _sizes) {
        for (final scale in [1.0, 1.3]) {
          await _open(tester, world, lesson, size: size, scale: scale);
          await tester.tap(find.byKey(Key('answer_${lesson.answer}')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$size $scale');
          final again = tester.getRect(find.byKey(const Key('result_again')));
          final back = tester.getRect(find.byKey(const Key('result_back')));
          expect(again.bottom, lessThanOrEqualTo(size.height));
          expect(back.bottom, lessThanOrEqualTo(size.height));
        }
      }
    });

    testWidgets('Number Galaxy keeps an English pop-up', (tester) async {
      final world = _world('numbers');
      final lesson = world.lessons.firstWhere((l) => l.id == 'num-add');
      await _open(tester, world, lesson);
      await tester.tap(find.byKey(Key('answer_${lesson.answer}')));
      await tester.pumpAndSettle();
      expect(find.text('Play again'), findsOneWidget);
    });
  });

  group('all-world badge', () {
    test('the badge now has an honest id and the screen lists it', () {
      final ids = AchievementsScreen.badges.map((b) => b.id).toList();
      expect(ids, contains('all-world-hero'));
      expect(ids, isNot(contains('four-world-hero')));
    });

    test('a quest in every one of the five worlds earns it', () async {
      final c = _controller();
      expect(curriculum.length, 5);
      for (final world in curriculum.take(4)) {
        await c.recordResult(
          world: world,
          lesson: world.lessons.first,
          correct: true,
        );
        expect(
          c.activeProgress.earnedBadges,
          isNot(contains('all-world-hero')),
          reason: 'after ${world.id}',
        );
      }
      final last = curriculum.last;
      await c.recordResult(
        world: last,
        lesson: last.lessons.first,
        correct: true,
      );
      expect(c.activeProgress.earnedBadges, contains('all-world-hero'));
    });

    test('an old save that earned "four-world-hero" keeps the badge', () async {
      final temp = await Directory.systemTemp.createTemp('aksharamala_badge_');
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}/progress.json');
      file.writeAsStringSync(
        jsonEncode({
          'version': 1,
          'profiles': [
            {
              'id': 'old',
              'name': 'Asha',
              'age': 6,
              'avatar': 'lion',
              'stars': 9
            },
          ],
          'progress': {
            'old': {
              'completedLessons': ['en-a'],
              'attempts': {'english': 1},
              'correct': {'english': 1},
              'lastPlayed': {'english': 'en-a'},
              'earnedBadges': ['first-step', 'four-world-hero'],
            },
          },
        }),
      );
      final c = AppController(store: LocalStore(fileOverride: file));
      await c.initialise();
      c.selectProfile(c.profiles.single);
      expect(
        c.activeProgress.earnedBadges,
        {'first-step', 'all-world-hero'},
        reason: 'old id is carried over to the new one',
      );
      // And it is saved under the new id from now on.
      await c.recordResult(
        world: curriculum.first,
        lesson: curriculum.first.lessons[1],
        correct: true,
      );
      final saved = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final badges =
          (saved['progress']['old']['earnedBadges'] as List).cast<String>();
      expect(badges, contains('all-world-hero'));
      expect(badges, isNot(contains('four-world-hero')));
    });

    testWidgets('the Rewards screen shows it earned after migration', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(960, 540);
      addTearDown(tester.view.reset);
      final controller = _controller();
      final p = controller.activeProgress;
      controller.progress['p'] = ProgressRecord.fromJson({
        ...p.toJson(),
        'earnedBadges': ['four-world-hero'],
      });
      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: MaterialApp(
            theme: buildTheme(),
            home: const AchievementsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1/4 badges'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
