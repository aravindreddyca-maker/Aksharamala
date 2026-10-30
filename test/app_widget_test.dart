import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/home_screen.dart';
import 'package:aksharamala/src/screens/lesson_screen.dart';
import 'package:aksharamala/src/screens/world_map_screen.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('age-adaptive home exposes five interactive world maps', (
    tester,
  ) async {
    final controller = AppController();
    const profile = ChildProfile(
      id: 'test',
      name: 'Asha',
      age: 6,
      avatar: '🦄',
    );
    controller
      ..profiles = [profile]
      ..progress = {'test': ProgressRecord.empty()}
      ..activeProfile = profile
      ..loaded = true;
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Asha'), findsWidgets);
    expect(find.textContaining('Trace • Spell'), findsOneWidget);
    for (final id in ['english', 'telugu', 'hindi', 'tamil']) {
      expect(find.byKey(Key('world_$id')), findsOneWidget);
      expect(
        tester.widget<InkWell>(find.byKey(Key('world_$id'))).onTap,
        isNotNull,
      );
    }
    await tester.drag(
      find.byKey(const Key('home_scroll')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('world_numbers')), findsOneWidget);
    expect(
      tester.widget<InkWell>(find.byKey(const Key('world_numbers'))).onTap,
      isNotNull,
    );

    final world = curriculum.first;
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          theme: buildTheme(),
          home: WorldMapScreen(world: world),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('English Forest'), findsWidgets);
    expect(find.byKey(const Key('lesson_en-a')), findsOneWidget);

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          theme: buildTheme(),
          home: LessonScreen(world: world, lesson: world.lessons.first),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('speak_button')), findsOneWidget);
    // "A is for Apple" is a picture quiz: tap a picture to answer, no Check.
    expect(find.byKey(const Key('check_answer')), findsNothing);
    for (final option in ['Apple', 'Ball', 'Cat']) {
      expect(find.byKey(Key('answer_$option')), findsOneWidget);
    }
  });
}
