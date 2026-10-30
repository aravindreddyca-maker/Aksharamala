import 'dart:io';

import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/home_screen.dart';
import 'package:aksharamala/src/screens/lesson_screen.dart';
import 'package:aksharamala/src/screens/world_map_screen.dart';
import 'package:aksharamala/src/screens/splash_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:aksharamala/src/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoDiskStore extends LocalStore {
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

void main() {
  setUp(() => feedbackPause = Duration.zero);
  tearDown(() => feedbackPause = defaultFeedbackPause);

  final sizes = <Size>[
    const Size(640, 360),
    const Size(800, 360),
    const Size(960, 540),
    const Size(1280, 800),
  ];

  AppController controller() {
    final result = AppController();
    const profile = ChildProfile(
      id: 'responsive',
      name: 'Ananya',
      age: 8,
      avatar: '🦄',
    );
    return result
      ..profiles = [profile]
      ..progress = {'responsive': ProgressRecord.empty()}
      ..activeProfile = profile
      ..loaded = true;
  }

  Future<void> setViewport(WidgetTester tester, Size size, double scale) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
  }

  for (final size in sizes) {
    testWidgets(
      'home has no overflow at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await setViewport(tester, size, 1.0);
        await tester.pumpWidget(
          AppScope(
            controller: controller(),
            child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('home_scroll')), findsOneWidget);
        expect(find.textContaining('Ananya'), findsWidgets);
        await tester.drag(
          find.byKey(const Key('home_scroll')),
          const Offset(0, -800),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('world_numbers')), findsOneWidget);
      },
    );
  }

  for (final size in sizes) {
    testWidgets(
      'home never scrolls vertically and keeps tiles on screen at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await setViewport(tester, size, 1.0);
        await tester.pumpWidget(
          AppScope(
            controller: controller(),
            child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final scrollable = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(const Key('home_scroll')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(scrollable.axisDirection, AxisDirection.right);
        // Every tile is tall enough to read and sits inside the viewport
        // vertically; at 800 wide and up all five also fit horizontally.
        for (final world in curriculum) {
          final rect = tester.getRect(find.byKey(Key('world_${world.id}')));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
          expect(rect.height, greaterThanOrEqualTo(150));
          expect(rect.width, greaterThanOrEqualTo(120));
          if (size.width >= 800) {
            expect(rect.right, lessThanOrEqualTo(size.width));
          }
        }
        for (final path in [
          'assets/images/emblems/english.png',
          'assets/images/rewards/star.png',
        ]) {
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is Image &&
                  w.image is AssetImage &&
                  (w.image as AssetImage).assetName == path,
            ),
            findsWidgets,
          );
        }
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Image &&
                w.image is AssetImage &&
                (w.image as AssetImage).assetName ==
                    'assets/images/backgrounds/home_bg.webp',
          ),
          findsOneWidget,
        );
        // A bundled mascot stands in each of the five cards.
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Image &&
                w.image is AssetImage &&
                (w.image as AssetImage).assetName.startsWith(
                      'assets/images/mascots/',
                    ),
          ),
          findsNWidgets(5),
        );
      },
    );
  }

  testWidgets('home remains readable with 160 percent text scaling', (
    tester,
  ) async {
    await setViewport(tester, const Size(640, 360), 1.6);
    await tester.pumpWidget(
      AppScope(
        controller: controller(),
        child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Ananya'), findsWidgets);
    for (final world in curriculum) {
      expect(find.byKey(Key('world_${world.id}')), findsOneWidget);
    }
  });

  testWidgets('splash is scroll-safe at 640x360 with large text', (
    tester,
  ) async {
    await setViewport(tester, const Size(640, 360), 1.3);
    await tester.pumpWidget(
      AppScope(
        controller: controller(),
        child: MaterialApp(theme: buildTheme(), home: const SplashScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1300));
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Aksharamala'), findsOneWidget);
  });

  for (final size in sizes) {
    for (final scale in [1.0, 1.3]) {
      testWidgets(
        'launch page fits and Start is tappable at ${size.width.toInt()}x${size.height.toInt()} text $scale',
        (tester) async {
          await setViewport(tester, size, scale);
          await tester.pumpWidget(
            AppScope(
              controller: controller(),
              child: MaterialApp(
                theme: buildTheme(),
                home: const SplashScreen(),
              ),
            ),
          );
          // Not tappable while loading, tappable once the delay has passed.
          expect(
            tester
                .widget<FilledButton>(find.byKey(const Key('start_adventure')))
                .onPressed,
            isNull,
          );
          await tester.pump(const Duration(milliseconds: 1300));
          await tester.pump(const Duration(milliseconds: 1000));
          expect(tester.takeException(), isNull);
          // The logo is an image announced as the app's name.
          expect(find.bySemanticsLabel('Aksharamala'), findsOneWidget);
          final logo = tester.getRect(
            find.byWidgetPredicate(
              (w) =>
                  w is Image &&
                  w.image is AssetImage &&
                  (w.image as AssetImage).assetName ==
                      'assets/images/brand/logo.png',
            ),
          );
          expect(logo.top, greaterThanOrEqualTo(0));
          expect(logo.height, greaterThanOrEqualTo(100));
          final button = find.byKey(const Key('start_adventure'));
          expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
          final rect = tester.getRect(button);
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is Image &&
                  w.image is AssetImage &&
                  (w.image as AssetImage).assetName.startsWith(
                        'assets/images/mascots/',
                      ),
            ),
            findsNWidgets(5),
          );
        },
      );
    }
  }

  for (final size in sizes) {
    testWidgets(
      'quiz uses overflow-free landscape panels at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await setViewport(tester, size, 1.3);
        final world = curriculum.first;
        await tester.pumpWidget(
          AppScope(
            controller: controller(),
            child: MaterialApp(
              theme: buildTheme(),
              home: LessonScreen(world: world, lesson: world.lessons.first),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('speak_button')), findsOneWidget);
        // Picture quiz: three picture answers on screen, no Check button.
        expect(find.byKey(const Key('check_answer')), findsNothing);
        final lesson = world.lessons.first;
        for (final option in lesson.options) {
          final rect = tester.getRect(find.byKey(Key('answer_$option')));
          expect(rect.height, greaterThanOrEqualTo(56));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
        }
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Image &&
                w.image is ResizeImage &&
                (w.image as ResizeImage).imageProvider is AssetImage &&
                ((w.image as ResizeImage).imageProvider as AssetImage)
                    .assetName
                    .startsWith('assets/images/quiz/'),
          ),
          findsNWidgets(3),
        );
      },
    );
  }

  for (final size in sizes) {
    for (final correct in [true, false]) {
      testWidgets(
        'quest result pop-up (${correct ? 'right' : 'wrong'} answer) fits at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await setViewport(tester, size, 1.3);
          final world = curriculum.first;
          final lesson = world.lessons.first;
          // Saving progress is real file IO, which never completes inside a
          // widget test, so use a store that keeps nothing.
          final saved = controller();
          final withStore = AppController(store: _NoDiskStore())
            ..profiles = saved.profiles
            ..progress = saved.progress
            ..activeProfile = saved.activeProfile
            ..loaded = true;
          await tester.pumpWidget(
            AppScope(
              controller: withStore,
              child: MaterialApp(
                theme: buildTheme(),
                home: LessonScreen(world: world, lesson: lesson),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(Key('answer_${correct ? lesson.answer : 'Ball'}')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('result_again')), findsOneWidget);
          expect(find.byKey(const Key('result_back')), findsOneWidget);
          expect(
            find.bySemanticsLabel(correct ? 'Wonderful!' : 'Good try!'),
            findsOneWidget,
          );
          for (final key in ['result_again', 'result_back']) {
            final rect = tester.getRect(find.byKey(Key(key)));
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.bottom, lessThanOrEqualTo(size.height));
            expect(rect.right, lessThanOrEqualTo(size.width));
          }
        },
      );
    }
  }

  testWidgets('every picture and cover named in the curriculum exists', (
    tester,
  ) async {
    final missing = <String>[];
    for (final world in curriculum) {
      for (final lesson in world.lessons) {
        final cover = lesson.cover;
        for (final path in [
          ...lesson.pictures.values,
          if (cover != null) cover
        ]) {
          if (!File(path).existsSync()) missing.add('${lesson.id}: $path');
        }
        // Every picture is keyed by a real answer option.
        for (final key in lesson.pictures.keys) {
          expect(lesson.options, contains(key), reason: lesson.id);
        }
      }
    }
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  for (final id in [
    'te-a',
    'te-word',
    'hi-a',
    'hi-story',
    'ta-a',
    'ta-word',
  ]) {
    testWidgets('$id shows three picture answers and no Check button', (
      tester,
    ) async {
      await setViewport(tester, const Size(800, 360), 1.3);
      final world = curriculum.firstWhere(
        (w) => w.lessons.any((l) => l.id == id),
      );
      final lesson = world.lessons.firstWhere((l) => l.id == id);
      await tester.pumpWidget(
        AppScope(
          controller: controller(),
          child: MaterialApp(
            theme: buildTheme(),
            home: LessonScreen(world: world, lesson: lesson),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Story quizzes read the story first; the question follows.
      if (lesson.kind == LessonKind.story) {
        for (var i = 0; i < lesson.story.length; i++) {
          // The page button can sit below the fold on a short screen.
          final next = find.byType(FilledButton).last;
          await tester.ensureVisible(next);
          await tester.pumpAndSettle();
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
      }
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('check_answer')), findsNothing);
      for (final option in lesson.options) {
        final rect = tester.getRect(find.byKey(Key('answer_$option')));
        expect(rect.height, greaterThanOrEqualTo(56), reason: option);
        expect(rect.bottom, lessThanOrEqualTo(360), reason: option);
      }
    });
  }

  for (final id in ['en-story', 'te-story', 'hi-story', 'ta-story']) {
    testWidgets('$id shows its cover scene instead of an emoji', (
      tester,
    ) async {
      await setViewport(tester, const Size(800, 360), 1.0);
      final world = curriculum.firstWhere(
        (w) => w.lessons.any((l) => l.id == id),
      );
      final lesson = world.lessons.firstWhere((l) => l.id == id);
      await tester.pumpWidget(
        AppScope(
          controller: controller(),
          child: MaterialApp(
            theme: buildTheme(),
            home: LessonScreen(world: world, lesson: lesson),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is ResizeImage &&
              ((w.image as ResizeImage).imageProvider as AssetImage)
                      .assetName ==
                  lesson.cover,
        ),
        findsOneWidget,
      );
      expect(find.text(lesson.symbol), findsNothing);
    });
  }

  testWidgets('text-only English quizzes keep select-then-check', (
    tester,
  ) async {
    await setViewport(tester, const Size(800, 360), 1.3);
    final world = curriculum.first;
    final lesson = world.lessons.firstWhere((l) => l.id == 'en-word');
    await tester.pumpWidget(
      AppScope(
        controller: controller(),
        child: MaterialApp(
          theme: buildTheme(),
          home: LessonScreen(world: world, lesson: lesson),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('check_answer')), findsOneWidget);
  });

  final numbers = curriculum.firstWhere((w) => w.id == 'numbers');
  for (final size in sizes) {
    testWidgets(
      'math quests are simple and overflow-free at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await setViewport(tester, size, 1.3);
        for (final id in ['num-count', 'num-add', 'num-subtract']) {
          final lesson = numbers.lessons.firstWhere((l) => l.id == id);
          await tester.pumpWidget(
            AppScope(
              controller: controller(),
              child: MaterialApp(
                theme: buildTheme(),
                home: LessonScreen(world: numbers, lesson: lesson),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: id);
          // English only: no Telugu, Hindi or Tamil, no Check button.
          expect(find.textContaining('ఎన్ని'), findsNothing, reason: id);
          expect(find.textContaining('कितने'), findsNothing, reason: id);
          expect(find.textContaining('எத்தனை'), findsNothing, reason: id);
          expect(find.byKey(const Key('check_answer')), findsNothing);
          expect(find.byKey(const Key('speak_button')), findsOneWidget);
          for (final option in lesson.options) {
            final rect = tester.getRect(find.byKey(Key('answer_$option')));
            expect(rect.height, greaterThanOrEqualTo(56), reason: id);
            expect(rect.bottom, lessThanOrEqualTo(size.height), reason: id);
          }
        }
      },
    );
  }

  testWidgets('every avatar choice, and legacy emoji values, uses bundled art',
      (
    tester,
  ) async {
    await setViewport(tester, const Size(800, 360), 1.0);
    const legacy = {
      '🦁': 'lion',
      '🐼': 'panda',
      '🦄': 'unicorn',
      '🐯': 'tiger'
    };
    final values = [...GameAvatar.options, ...legacy.keys, '🐸', '🤖'];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: Wrap(
            children: [for (final v in values) GameAvatar(value: v, size: 64)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final names = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => (i.image as AssetImage).assetName)
        .toSet();
    expect(names, {
      for (final n in GameAvatar.options) 'assets/images/avatars/$n.png',
    });
    // An unknown value falls back to the icon avatar rather than crashing.
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(body: GameAvatar(value: 'mystery')),
      ),
    );
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('Number Names keeps its multilingual choices', (tester) async {
    await setViewport(tester, const Size(960, 540), 1.0);
    final lesson = numbers.lessons.firstWhere((l) => l.id == 'num-names');
    await tester.pumpWidget(
      AppScope(
        controller: controller(),
        child: MaterialApp(
          theme: buildTheme(),
          home: LessonScreen(world: numbers, lesson: lesson),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('check_answer')), findsOneWidget);
    expect(find.textContaining('ஐந்து'), findsWidgets);
  });

  // The home cards now show English names only; the scripts appear on each
  // world's map, so that is where their rendering is checked.
  for (final entry in {
    'telugu': 'అక్షరాలు',
    'hindi': 'अक्षर',
    'tamil': 'தமிழ்',
  }.entries) {
    testWidgets('${entry.key} script renders on its landscape world map', (
      tester,
    ) async {
      await setViewport(tester, const Size(960, 540), 1.2);
      final world = curriculum.firstWhere((w) => w.id == entry.key);
      await tester.pumpWidget(
        AppScope(
          controller: controller(),
          child: MaterialApp(
            theme: buildTheme(),
            home: WorldMapScreen(world: world),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining(entry.value), findsWidgets);
    });
  }
}
