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
    });

    test('loading never writes the aliases into the save', () async {
      final c = await open(oldSave(done: {'te-a'}, stars: {'te-a': 3}));
      expect(c.activeProgress.completedLessons, {'te-a'});
      expect(c.activeProgress.toJson()['completedLessons'], ['te-a']);
      expect(c.activeProgress.questStars, {'te-a': 3});
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

  group('levels and the save format', () {
    test('an old save without levels gets the level its age band became',
        () async {
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
        final c = await open(oldSave(age: age));
        expect(c.activeProfile!.level, level, reason: 'age $age');
      }
    });

    test('saving writes version 2 with the level and keeps the old age',
        () async {
      final c = await open(oldSave(done: {'te-a'}, stars: {'te-a': 3}, age: 8));
      await c.setLevel(5);
      final onDisk =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(onDisk['version'], 2);
      final profile = (onDisk['profiles'] as List).single as Map;
      expect(profile['level'], 5);
      expect(profile['age'], 8, reason: 'the old age is kept, not rewritten');
      expect(profile['name'], 'Meena');
      expect(onDisk.containsKey('settings'), isFalse);
    });

    test('the original file is copied once, untouched, before the first save',
        () async {
      final original = oldSave(done: {'te-a'}, stars: {'te-a': 3});
      final c = await open(original);
      final backup = File('${file.path}.v1.bak');
      expect(backup.existsSync(), isTrue);
      expect(jsonDecode(backup.readAsStringSync()), original);
      await c.setLevel(3);
      await c.setLevel(2);
      // A later save never replaces that first copy.
      expect(jsonDecode(backup.readAsStringSync()), original);
    });

    test('a version 2 save loads exactly and makes no version 1 backup',
        () async {
      final c = await open(oldSave());
      await c.setLevel(4);
      File('${file.path}.v1.bak').deleteSync();
      final again = AppController(store: LocalStore(fileOverride: file));
      await again.initialise();
      expect(again.activeProfile!.level, 4);
      expect(File('${file.path}.v1.bak').existsSync(), isFalse);
    });

    test('an unreadable file is kept and the last good save is used', () async {
      final c = await open(oldSave(done: {'te-a'}, stars: {'te-a': 3}));
      // A save leaves the previous good file beside it as progress.json.bak.
      await c.setLevel(3);
      await file.writeAsString('{ this is not json');
      final again = AppController(store: LocalStore(fileOverride: file));
      await again.initialise();
      expect(again.profiles, isNotEmpty, reason: 'recovered from the copy');
      expect(again.activeProgress.completedLessons, {'te-a'});
      final kept = temp
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('.unreadable.'));
      expect(kept, isNotEmpty, reason: 'the damaged file is not thrown away');
    });
  });

  group('switching levels', () {
    test('never changes finished lessons, stars, badges or avatar', () async {
      final c = await open(oldSave(
        done: {'te-a', 'en-a'},
        stars: {'te-a': 3, 'en-a': 3},
        profileStars: 6,
      ));
      final before = jsonEncode(c.activeProgress.toJson());
      for (final level in [5, 1, 4, 2, 3, 5, 1]) {
        await c.setLevel(level);
        expect(c.activeProfile!.level, level);
      }
      expect(jsonEncode(c.activeProgress.toJson()), before);
      expect(c.activeProfile!.stars, 6);
      expect(c.activeProfile!.avatar, 'lion');
      expect(c.activeProfile!.name, 'Meena');
    });

    test('keeps each level\'s answer statistics apart', () async {
      final c = await open(oldSave(age: 4));
      final world1 = c.worlds.firstWhere((w) => w.id == 'english');
      await c.recordResult(
          world: world1, lesson: world1.lessons.first, correct: true);
      await c.setLevel(2);
      final world2 = c.worlds.firstWhere((w) => w.id == 'english');
      await c.recordResult(
          world: world2, lesson: world2.lessons.first, correct: false);
      expect(c.accuracyAtLevel(1, 'english'), 1.0);
      expect(c.accuracyAtLevel(2, 'english'), 0.0);
      expect(c.activeProgress.levelAttempts, {'1|english': 1, '2|english': 1});
      expect(c.activeProgress.levelCorrect, {'1|english': 1});
      // They survive a save and reload.
      final again = AppController(store: LocalStore(fileOverride: file));
      await again.initialise();
      expect(
          again.activeProgress.levelAttempts, {'1|english': 1, '2|english': 1});
    });

    test('Level 5 opens with nothing broken, in every world', () async {
      final c = await open(oldSave());
      await c.setLevel(5);
      expect(c.worlds.length, 5);
      for (final w in c.worlds) {
        expect(w.lessons, isEmpty, reason: 'no Level 5 lesson exists yet');
      }
      expect(c.activeProfile!.level, 5);
      // Going back finds everything where it was.
      await c.setLevel(1);
      expect(c.worlds.any((w) => w.lessons.isNotEmpty), isTrue);
    });

    test('a level outside 1-5 is held to the nearest', () async {
      final c = await open(oldSave());
      await c.setLevel(9);
      expect(c.activeProfile!.level, 5);
      await c.setLevel(0);
      expect(c.activeProfile!.level, 1);
    });

    test('a new child can start at any level', () async {
      final c = AppController(store: LocalStore(fileOverride: file));
      await c.initialise();
      await c.createProfile(name: 'Asha', level: 5, avatar: 'panda');
      expect(c.activeProfile!.level, 5);
      expect(c.activeProgress.completedLessons, isEmpty);
    });

    test('recommending in an empty world is refused, not silently wrong',
        () async {
      final c = await open(oldSave());
      await c.setLevel(5);
      expect(() => c.recommendedLesson(c.worlds.first), throwsStateError);
    });
  });

  group('every lesson belongs to a level', () {
    test('each of the 360 lessons is in at least one of Levels 1-4', () {
      final c = AppController(store: LocalStore(fileOverride: file));
      var count = 0;
      for (final w in c.allWorlds) {
        for (final l in w.lessons) {
          expect(l.levels, isNotEmpty, reason: l.id);
          expect(l.levels.every((n) => n >= 1 && n <= 4), isTrue, reason: l.id);
          count++;
        }
      }
      expect(count, greaterThan(300));
    });

    test('no lesson is shown in Level 5 yet', () {
      final c = AppController(store: LocalStore(fileOverride: file));
      expect(
          c.allWorlds.expand((w) => w.lessons).where((l) => l.supportsLevel(5)),
          isEmpty);
    });
  });

  group('playing the new lessons', () {
    test('right first time pays 3, a mistake pays 1, never more than 3',
        () async {
      final c = await open(oldSave());
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
