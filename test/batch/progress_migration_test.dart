import 'dart:convert';
import 'dart:io';

import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/batch/batch_content.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// A save file as an earlier version of the app wrote it.
Map<String, Object?> oldSave({
  Set<String> done = const {},
  Map<String, int>? stars,
  int profileStars = 0,
  int age = 5,
}) =>
    {
      'version': 1,
      'profiles': [
        {
          'id': 'p1',
          'name': 'Meena',
          'age': age,
          'avatar': 'lion',
          'stars': profileStars,
        },
      ],
      'progress': {
        'p1': {
          'completedLessons': done.toList(),
          'attempts': {'telugu': 3},
          'correct': {'telugu': 2},
          'lastPlayed': {'telugu': 'te-a'},
          'earnedBadges': ['first-step', 'four-world-hero'],
          if (stars != null) 'questStars': stars,
        },
      },
    };

void main() {
  late Directory temp;
  late File file;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('aksharamala_batch_');
    file = File('${temp.path}/progress.json');
  });

  tearDown(() async => temp.delete(recursive: true));

  Future<AppController> open(Map<String, Object?> save) async {
    await file.writeAsString(jsonEncode(save));
    final c = AppController(store: LocalStore(fileOverride: file));
    await c.initialise();
    return c;
  }

  final t1 = teluguBatch.first; // అ, replaces the old quest te-a
  final teluguWorld = curriculum.firstWhere((w) => w.id == 'telugu');

  group('older saves keep everything', () {
    test('profiles, stars, attempts and badges load as before', () async {
      final c = await open(oldSave(
        done: {'te-a', 'en-a'},
        stars: {'te-a': 3, 'en-a': 3},
        profileStars: 6,
      ));
      expect(c.profiles.single.name, 'Meena');
      expect(c.profiles.single.stars, 6);
      expect(c.activeProgress.completedLessons, {'te-a', 'en-a'});
      expect(c.activeProgress.attempts['telugu'], 3);
      expect(c.activeProgress.earnedBadges, contains('all-world-hero'));
      expect(c.newLessonsEnabled, isTrue,
          reason: 'all lessons are shown unless a parent turns them off');
    });

    test('loading never writes the aliases into the save', () async {
      final c = await open(oldSave(done: {'te-a'}, stars: {'te-a': 3}));
      expect(c.activeProgress.completedLessons, {'te-a'});
      expect(c.activeProgress.toJson()['completedLessons'], ['te-a']);
      expect(c.activeProgress.questStars, {'te-a': 3});
    });

    test('a save from before the flag existed loads and saves cleanly',
        () async {
      final c = await open(oldSave(done: {'te-a'}, stars: {'te-a': 3}));
      await c.setNewLessons(false);
      final onDisk =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect((onDisk['settings'] as Map)['newLessons'], isFalse);
      expect((onDisk['profiles'] as List).single['name'], 'Meena');
      final reopened = AppController(store: LocalStore(fileOverride: file));
      await reopened.initialise();
      expect(reopened.newLessonsEnabled, isFalse,
          reason: 'a parent who turned it off stays off');
      expect(reopened.activeProgress.completedLessons, {'te-a'});
      expect(reopened.profiles.single.stars, 0 + c.profiles.single.stars);
    });
  });

  group('the old Telugu quest counts for the new first lesson', () {
    test('finishing te-a means the new అ lesson is done', () async {
      final c = await open(oldSave(done: {'te-a'}, stars: {'te-a': 3}));
      expect(c.activeProgress.completedWithLegacy, contains(t1.id));
      expect(ProgressRecord.legacyQuestAliases[t1.id], 'te-a');
    });

    test('not finishing te-a leaves the new lesson open', () async {
      final c = await open(oldSave(done: {'en-a'}, stars: {'en-a': 3}));
      expect(c.activeProgress.completedWithLegacy, isNot(contains(t1.id)));
    });

    test('stars already paid are not paid twice', () async {
      final c = await open(oldSave(
        done: {'te-a'},
        stars: {'te-a': 3},
        profileStars: 3,
      ));
      await c.setNewLessons(true);
      final world = c.worlds.firstWhere((w) => w.id == 'telugu');
      final gained =
          await c.recordResult(world: world, lesson: t1, correct: true);
      expect(gained, 0);
      expect(c.activeProfile!.stars, 3);
    });

    test('a part-paid old quest leaves only the difference', () async {
      final c = await open(
          oldSave(done: <String>{}, stars: {'te-a': 1}, profileStars: 1));
      expect(c.activeProgress.starsPaidBy(t1.id), 1);
      final gained = await c.recordResult(
        world: teluguWorld,
        lesson: t1,
        correct: true,
      );
      expect(gained, 2);
      expect(c.activeProfile!.stars, 3);
    });

    test('no other lesson inherits anything', () async {
      final c = await open(oldSave(
        done: {'te-a', 'te-word', 'num-count'},
        stars: {'te-a': 3, 'te-word': 3, 'num-count': 3},
      ));
      final others = allBatchLessons.where((l) => l.id != t1.id);
      for (final l in others) {
        expect(c.activeProgress.completedWithLegacy, isNot(contains(l.id)),
            reason: l.id);
        expect(c.activeProgress.starsPaidBy(l.id), 0, reason: l.id);
      }
    });

    test('the alias list only names real lessons', () {
      final newIds = allBatchLessons.map((l) => l.id).toSet();
      final oldIds = {
        for (final w in curriculum) ...w.lessons.map((l) => l.id),
      };
      for (final e in ProgressRecord.legacyQuestAliases.entries) {
        expect(newIds, contains(e.key));
        expect(oldIds, contains(e.value));
      }
    });
  });

  group('the feature flag', () {
    test('off: the child sees exactly the old worlds', () async {
      final c = await open(oldSave());
      await c.setNewLessons(false);
      for (final world in curriculum) {
        expect(
          c.worlds.firstWhere((item) => item.id == world.id).lessons,
          world.forStage(ExperienceStage.creator).lessons,
        );
      }
    });

    test('on (the default): the worlds gain the newer lessons', () async {
      final c = await open(oldSave(age: 3));
      expect(c.newLessonsEnabled, isTrue);
      int count(String id) =>
          c.worlds.firstWhere((w) => w.id == id).lessons.length;
      expect(count('telugu'), greaterThan(1));
      expect(count('numbers'), greaterThan(1));
      expect(count('english'), greaterThan(0));
      expect(count('hindi'), greaterThan(0));
      expect(count('tamil'), greaterThan(0));
      for (final world in c.worlds) {
        expect(
          world.lessons.every(
            (lesson) => lesson.supportsStage(ExperienceStage.explorer),
          ),
          isTrue,
          reason: world.id,
        );
      }
    });

    test('turning it on and off changes nobody\'s progress', () async {
      final c = await open(oldSave(
        done: {'te-a', 'en-a'},
        stars: {'te-a': 3, 'en-a': 3},
        profileStars: 6,
      ));
      final before = jsonEncode(c.activeProgress.toJson());
      await c.setNewLessons(true);
      await c.setNewLessons(false);
      expect(jsonEncode(c.activeProgress.toJson()), before);
      expect(c.profiles.single.stars, 6);
    });

    test('it is stored in settings, not in any child\'s data', () async {
      final c = await open(oldSave());
      await c.setNewLessons(false);
      final onDisk =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(onDisk['settings'], {'newLessons': false});
    });
  });

  group('playing the new lessons', () {
    test('right first time pays 3, a mistake pays 1, never more than 3',
        () async {
      final c = await open(oldSave());
      await c.setNewLessons(true);
      final world = c.worlds.firstWhere((w) => w.id == 'numbers');
      final n3 = numbersBatch[3];
      expect(await c.recordResult(world: world, lesson: n3, correct: false), 1);
      expect(await c.recordResult(world: world, lesson: n3, correct: true), 2);
      expect(await c.recordResult(world: world, lesson: n3, correct: true), 0);
      expect(c.activeProfile!.stars, 3);
      expect(c.activeProgress.completedLessons, contains(n3.id));
    });

    test('recommendations move through the new lessons in order', () async {
      final c = await open(oldSave(
        age: 3,
        done: {'te-word', 'te-trace', 'te-story'},
        stars: {'te-word': 3, 'te-trace': 3, 'te-story': 3},
      ));
      await c.setNewLessons(true);
      final world = c.worlds.firstWhere((w) => w.id == 'telugu');
      expect(c.recommendedLesson(world).id, 'te-a');
      await c.recordResult(
          world: world, lesson: world.lessons.first, correct: true);
      // te-a is now done, so the next age-appropriate recognition lesson is
      // recommended. Preview-pack lessons remain in the same curriculum list.
      expect(c.recommendedLesson(world).id, world.lessons[1].id);
    });

    test('the sample quest still plays exactly as before', () async {
      final c = await open(oldSave());
      final world = curriculum.first;
      final gained = await c.recordResult(
        world: world,
        lesson: world.lessons.first,
        correct: true,
      );
      expect(gained, 3);
    });
  });
}
