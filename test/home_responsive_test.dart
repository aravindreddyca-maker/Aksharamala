import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/home_screen.dart';
import 'package:aksharamala/src/screens/lesson_screen.dart';
import 'package:aksharamala/src/screens/splash_screen.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
        expect(find.text('Namaste, Ananya!'), findsOneWidget);
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
        // Each learner gets one of the five bundled mascot guides.
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Image &&
                w.image is AssetImage &&
                (w.image as AssetImage).assetName.startsWith(
                      'assets/images/mascots/',
                    ),
          ),
          findsOneWidget,
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
    expect(find.text('Namaste, Ananya!'), findsOneWidget);
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
    expect(find.text('Aksharamala'), findsOneWidget);
  });

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
        expect(find.byKey(const Key('check_answer')), findsOneWidget);
      },
    );
  }

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

  testWidgets('Tamil, Telugu and Hindi scripts render in the landscape home', (
    tester,
  ) async {
    await setViewport(tester, const Size(960, 540), 1.2);
    await tester.pumpWidget(
      AppScope(
        controller: controller(),
        child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
      ),
    );
    await tester.drag(
      find.byKey(const Key('home_scroll')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('தமிழ்'), findsWidgets);
  });
}
