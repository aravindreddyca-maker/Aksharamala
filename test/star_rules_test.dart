import 'dart:convert';
import 'dart:io';

import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/lesson_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temp;
  late File file;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('aksharamala_stars_');
    file = File('${temp.path}/progress.json');
  });

  tearDown(() async => temp.delete(recursive: true));

  Future<AppController> fresh() async {
    final controller = AppController(store: LocalStore(fileOverride: file));
    await controller.initialise();
    await controller.addProfile('Meena', 6, 'lion');
    return controller;
  }

  final world = curriculum.first;
  final lesson = world.lessons.first;
  final other = world.lessons[1];

  Future<int> play(AppController c, {required bool correct, Lesson? l}) =>
      c.recordResult(world: world, lesson: l ?? lesson, correct: correct);

  group('stars per quest', () {
    test('a right answer pays 3 the first time', () async {
      final c = await fresh();
      expect(await play(c, correct: true), 3);
      expect(c.activeProfile!.stars, 3);
    });

    test('replaying a finished quest pays nothing, however often', () async {
      final c = await fresh();
      await play(c, correct: true);
      for (var i = 0; i < 20; i++) {
        expect(await play(c, correct: true), 0);
        expect(await play(c, correct: false), 0);
      }
      expect(c.activeProfile!.stars, 3, reason: 'no farming');
    });

    test('mistake then right still totals 3, never more', () async {
      final c = await fresh();
      expect(await play(c, correct: false), 1);
      expect(await play(c, correct: true), 2);
      expect(c.activeProfile!.stars, 3);
      expect(await play(c, correct: true), 0);
    });

    test('mistakes alone cannot pass 3 stars on one quest', () async {
      final c = await fresh();
      var total = 0;
      for (var i = 0; i < 10; i++) {
        total += await play(c, correct: false);
      }
      expect(total, 3);
      expect(c.activeProfile!.stars, 3);
      // ...and the quest is still not complete: only a right answer does that.
      expect(c.activeProgress.completedLessons, isNot(contains(lesson.id)));
    });

    test('each quest has its own allowance', () async {
      final c = await fresh();
      await play(c, correct: true);
      expect(await play(c, correct: true, l: other), 3);
      expect(c.activeProfile!.stars, 6);
    });

    test('progress, badges and recommendations are unchanged by the cap',
        () async {
      final c = await fresh();
      await play(c, correct: true);
      await play(c, correct: true); // a free replay
      expect(c.activeProgress.completedLessons, {lesson.id});
      expect(c.activeProgress.earnedBadges, contains('first-step'));
      expect(c.recommendedLesson(world).id, other.id);
      // Accuracy statistics still count practice attempts.
      expect(c.activeProgress.attempts[world.id], 2);
      expect(c.activeProgress.correct[world.id], 2);
    });
  });

  group('saved data', () {
    test('stars paid per quest survive a reload', () async {
      final c = await fresh();
      await play(c, correct: false); // 1 of 3 paid
      final again = AppController(store: LocalStore(fileOverride: file));
      await again.initialise();
      expect(again.activeProgress.starsPaidBy(lesson.id), 1);
      expect(await play(again, correct: true), 2);
      expect(again.activeProfile!.stars, 3);
    });

    test('an old save without the field loads, and finished quests stay paid',
        () async {
      // Exactly what the previous version wrote: no "questStars" key.
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
              'completedLessons': ['en-a', 'en-word'],
              'attempts': {'english': 4},
              'correct': {'english': 3},
              'lastPlayed': {'english': 'en-word'},
              'earnedBadges': ['first-step'],
            },
          },
        }),
      );
      final c = AppController(store: LocalStore(fileOverride: file));
      await c.initialise();
      c.selectProfile(c.profiles.single);
      expect(c.activeProfile!.stars, 9, reason: 'existing stars untouched');
      expect(c.activeProgress.completedLessons, {'en-a', 'en-word'});
      // The two finished quests were paid under the old rules: no more.
      expect(await play(c, correct: true), 0);
      expect(
          await play(c,
              correct: true,
              l: world.lessons.firstWhere((l) => l.id == 'en-word')),
          0);
      // An unfinished quest still pays in full.
      expect(
          await play(c,
              correct: true,
              l: world.lessons.firstWhere((l) => l.id == 'en-trace')),
          3);
      expect(c.activeProfile!.stars, 12);
    });

    test('the new field round-trips through JSON', () {
      const record = ProgressRecord(
        completedLessons: {'en-a'},
        attempts: {'english': 2},
        correct: {'english': 1},
        lastPlayed: {'english': 'en-a'},
        earnedBadges: {'first-step'},
        questStars: {'en-a': 3, 'en-word': 1},
      );
      final back = ProgressRecord.fromJson(
        Map<String, dynamic>.from(
            jsonDecode(jsonEncode(record.toJson())) as Map),
      );
      expect(back.questStars, {'en-a': 3, 'en-word': 1});
      expect(back.starsPaidBy('en-word'), 1);
      expect(back.starsPaidBy('never-played'), 0);
    });
  });

  group('what the pop-up says', () {
    test('words match what was actually paid', () {
      expect(
        questResultMessage(correct: true, gained: 3),
        'You earned 3 stars and completed this quest.',
      );
      expect(
        questResultMessage(correct: true, gained: 1),
        'You earned 1 star and completed this quest.',
      );
      expect(
        questResultMessage(correct: true, gained: 0),
        contains('already collected every star'),
      );
      expect(
        questResultMessage(correct: false, gained: 1),
        contains('courage star'),
      );
      final none = questResultMessage(correct: false, gained: 0);
      expect(none, isNot(contains('star')));
    });

    testWidgets('a replay of a finished quest does not promise stars', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(960, 540);
      addTearDown(tester.view.reset);
      const profile = ChildProfile(id: 'p', name: 'M', age: 6, avatar: 'lion');
      final controller = AppController(store: _NoDiskStore())
        ..profiles = [profile]
        ..progress = {
          'p': ProgressRecord(
            completedLessons: {lesson.id},
            attempts: const {},
            correct: const {},
            lastPlayed: const {},
            earnedBadges: const {'first-step'},
          ),
        }
        ..activeProfile = profile
        ..loaded = true;
      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: MaterialApp(
            theme: buildTheme(),
            home: LessonScreen(world: world, lesson: lesson),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('answer_${lesson.answer}')));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('already collected every star'), findsOneWidget);
      expect(find.textContaining('You earned'), findsNothing);
      expect(controller.activeProfile!.stars, 0);
    });
  });
}

class _NoDiskStore extends LocalStore {
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}
