import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/achievements_screen.dart';
import 'package:aksharamala/src/screens/home_screen.dart';
import 'package:aksharamala/src/screens/lesson_screen.dart';
import 'package:aksharamala/src/screens/parent_dashboard.dart';
import 'package:aksharamala/src/screens/profile_screen.dart';
import 'package:aksharamala/src/screens/splash_screen.dart';
import 'package:aksharamala/src/screens/world_map_screen.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppController _controller({bool withProfile = true}) {
  final controller = AppController();
  const profile = ChildProfile(id: 'test', name: 'Asha', age: 4, avatar: '🦁');
  controller
    ..profiles = withProfile ? [profile] : []
    ..progress = {'test': ProgressRecord.empty()}
    ..activeProfile = withProfile ? profile : null
    ..loaded = true;
  return controller;
}

void main() {
  testWidgets('no screen overflows on phones, tablets, landscape or large text',
      (tester) async {
    const sizes = [Size(360, 640), Size(411, 914), Size(768, 1024), Size(914, 411)];
    const scales = [1.0, 1.3];
    final screens = <String, Widget Function()>{
      'splash': () => const SplashScreen(),
      'home': () => const HomeScreen(),
      'profile': () => const ProfileScreen(),
      'achievements': () => const AchievementsScreen(),
      'parent dashboard': () => const ParentDashboard(),
      for (final world in curriculum) ...{
        'map ${world.id}': () => WorldMapScreen(world: world),
        for (final lesson in world.lessons)
          'lesson ${lesson.id}': () => LessonScreen(world: world, lesson: lesson),
      },
    };

    final problems = <String>[];
    final previous = FlutterError.onError;
    var label = '';
    FlutterError.onError = (details) {
      final first = details.exceptionAsString().split('\n').first;
      problems.add('$label: $first');
    };
    try {
      for (final size in sizes) {
        for (final scale in scales) {
          for (final entry in screens.entries) {
            label = '${entry.key} @ ${size.width.toInt()}x${size.height.toInt()} text x$scale';
            tester.view
              ..devicePixelRatio = 2
              ..physicalSize = size * 2;
            await tester.pumpWidget(AppScope(
              controller: _controller(withProfile: entry.key != 'profile'),
              child: MaterialApp(
                theme: buildTheme(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: entry.value(),
              ),
            ));
            await tester.pump(const Duration(milliseconds: 500));
          }
        }
      }
    } finally {
      FlutterError.onError = previous;
      tester.view.reset();
    }
    expect(problems, isEmpty, reason: problems.take(12).join('\n'));
  });
}
