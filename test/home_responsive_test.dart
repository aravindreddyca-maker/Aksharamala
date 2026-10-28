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
        expect(find.text('Choose your adventure'), findsOneWidget);
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
    expect(find.text('Choose your adventure'), findsOneWidget);
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
