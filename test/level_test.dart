import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/home_screen.dart';
import 'package:aksharamala/src/screens/profile_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Levels are a friendlier way to show the four existing age stages. They add
/// no new saved data, and anyone can pick any of them at any time.
class _NoDiskStore extends LocalStore {
  @override
  Future<LocalSnapshot> load() async =>
      const LocalSnapshot(profiles: [], progress: {});

  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

AppController _controller({int age = 4}) {
  final profile =
      ChildProfile(id: 'p', name: 'Meena', age: age, avatar: 'lion');
  return AppController(store: _NoDiskStore())
    ..profiles = [profile]
    ..progress = {
      'p': const ProgressRecord(
        completedLessons: {'en-a'},
        attempts: {'english': 2},
        correct: {'english': 2},
        lastPlayed: {},
        earnedBadges: {'first-step'},
        questStars: {'en-a': 3},
      ),
    }
    ..activeProfile = profile
    ..loaded = true;
}

void main() {
  group('level to stage', () {
    test('Level 1 to 4 are ages 3-4, 5-6, 7-9 and 10-12', () {
      expect([for (final s in ExperienceStage.values) s.levelLabel],
          ['Level 1', 'Level 2', 'Level 3', 'Level 4']);
      expect([for (final s in ExperienceStage.values) s.ageLabel],
          ['Ages 3–4', 'Ages 5–6', 'Ages 7–9', 'Ages 10–12']);
    });

    test('every level maps back to itself through its saved age', () {
      for (final s in ExperienceStage.values) {
        expect(stageForAge(s.representativeAge), s);
        expect(stageForLevel(s.level), s);
      }
    });

    test('an out-of-range level is held to the nearest', () {
      expect(stageForLevel(0), ExperienceStage.explorer);
      expect(stageForLevel(9), ExperienceStage.champion);
    });

    test('older saves still show the right level for their age', () {
      for (final (age, level) in [
        (3, 1),
        (4, 1),
        (5, 2),
        (6, 2),
        (7, 3),
        (9, 3),
        (10, 4),
        (12, 4)
      ]) {
        expect(ChildProfile(id: 'x', name: 'x', age: age, avatar: 'lion').level,
            level,
            reason: 'age $age');
      }
    });
  });

  group('changing level', () {
    test('any level can be chosen, in any order, from any level', () async {
      final c = _controller();
      for (final level in [4, 1, 3, 2, 4, 2]) {
        await c.setLevel(level);
        expect(c.activeProfile!.level, level);
        expect(c.profiles.single.level, level);
      }
    });

    test('nothing earned is touched', () async {
      final c = _controller();
      final before = c.activeProgress.toJson().toString();
      await c.setLevel(4);
      await c.setLevel(1);
      expect(c.activeProgress.toJson().toString(), before);
      expect(c.activeProfile!.name, 'Meena');
      expect(c.activeProfile!.avatar, 'lion');
    });

    test('choosing the level a child is already on changes nothing', () async {
      final c = _controller(age: 5);
      await c.setLevel(2);
      expect(c.activeProfile!.age, 5, reason: 'the saved age is left alone');
    });

    test('the quests shown follow the level', () async {
      final c = _controller();
      await c.setLevel(1);
      final low = c.worlds.fold<int>(0, (n, w) => n + w.lessons.length);
      await c.setLevel(3);
      final high = c.worlds.fold<int>(0, (n, w) => n + w.lessons.length);
      expect(low, isNot(high));
    });
  });

  group('changing the level of a saved profile', () {
    test('works for a profile that is not the one playing', () async {
      final c = _controller();
      const other =
          ChildProfile(id: 'q', name: 'Ravi', age: 11, avatar: 'panda');
      c.profiles = [...c.profiles, other];
      await c.setLevelFor('q', 1);
      expect(c.profiles.firstWhere((p) => p.id == 'q').level, 1);
      expect(c.activeProfile!.id, 'p', reason: 'the playing profile stays');
      expect(c.activeProfile!.level, 1);
      await c.setLevelFor('p', 3);
      expect(c.activeProfile!.level, 3);
      expect(c.profiles.firstWhere((p) => p.id == 'q').level, 1);
    });

    test('an unknown profile is ignored', () async {
      final c = _controller();
      await c.setLevelFor('nobody', 4);
      expect(c.activeProfile!.level, 1);
    });
  });

  testWidgets('the saved-profile list lets anyone change a level',
      (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(960, 540);
    addTearDown(tester.view.reset);
    final c = _controller();
    await tester.pumpWidget(
      AppScope(
        controller: c,
        child: MaterialApp(
          theme: buildTheme(),
          home: const ProfileScreen(allowSkip: true),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Level 1 • Little Explorer'), findsOneWidget);
    await tester.tap(find.byKey(const Key('level_of_p')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a level'), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byKey(const Key('level_3')),
    ));
    await tester.pumpAndSettle();
    expect(c.profiles.single.level, 3);
    expect(find.textContaining('Level 3 • Curious Scholar'), findsOneWidget);
    // Choosing a level did not open the profile.
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('the home screen shows the level and anyone can change it',
      (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(960, 540);
    addTearDown(tester.view.reset);
    final c = _controller();
    await tester.pumpWidget(
      AppScope(
        controller: c,
        child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Level 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('level_button')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a level'), findsOneWidget);
    // All four are offered, none locked.
    for (final k in ['level_1', 'level_2', 'level_3', 'level_4']) {
      expect(find.byKey(Key(k)), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('level_4')));
    await tester.pumpAndSettle();
    expect(c.activeProfile!.level, 4);
    expect(find.text('Level 4'), findsOneWidget);
    expect(find.text('Choose a level'), findsNothing);
  });

  testWidgets('the level button fits at the smallest landscape size',
      (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(640, 360);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppScope(
        controller: _controller(),
        child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final r = tester.getRect(find.byKey(const Key('level_button')));
    expect(r.height, greaterThanOrEqualTo(44));
    expect(r.right, lessThanOrEqualTo(640));
  });
}
