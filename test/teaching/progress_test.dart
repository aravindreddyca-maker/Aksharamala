import 'dart:convert';
import 'dart:io';

import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/teaching/teaching_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('loading plans: injected loader, none by default, errors ignored',
      () async {
    final none = AppController(store: NoDiskStore());
    await none.initialise();
    expect(none.planFor('en-a'), isNull);

    final withPlans = await makeController();
    expect(withPlans.planFor('en-a'), isNotNull);
    expect(withPlans.planFor('en-b'), isNull);

    final broken = AppController(
      store: NoDiskStore(),
      teachingPlanLoader: () async => throw StateError('no asset'),
    );
    await broken.initialise();
    expect(broken.planFor('en-a'), isNull);
    expect(broken.loaded, isTrue);
  });

  test('mastery goes through recordResult exactly once', () async {
    final store = NoDiskStore();
    final c = await makeController(store: store);
    final world = worldOf(c, 'en-a');
    final lesson = lessonOf(c, 'en-a');
    const t = TeachingProgress(viewed: true, checkBestScore: 3);
    final gained = await c.recordTeachingMastery(
      world: world,
      lesson: lesson,
      teaching: t,
    );
    expect(gained, 3);
    expect(c.activeProgress.completedLessons, contains('en-a'));
    expect(c.activeProfile!.stars, 3);
    expect(c.activeProgress.attempts[world.id], 1);
    expect(c.activeProgress.correct[world.id], 1);
    expect(c.teachingProgressFor('en-a').mastery, MasteryStatus.mastered);
    expect(c.teachingProgressFor('en-a').updatedAt, isNotNull);

    // Revisiting and passing again pays nothing and is not counted again.
    final again = await c.recordTeachingMastery(
      world: world,
      lesson: lesson,
      teaching: t,
    );
    expect(again, 0);
    expect(c.activeProfile!.stars, 3);
    expect(c.activeProgress.attempts[world.id], 1);
    expect(store.last!.progress.values.first.teaching.keys, ['en-a']);
  });

  test('needsSupport is recorded; nothing is marked finished or paid',
      () async {
    final c = await makeController();
    await c.recordTeachingNeedsSupport(
      lesson: lessonOf(c, 'num-add'),
      teaching: const TeachingProgress(
        viewed: true,
        mastery: MasteryStatus.needsSupport,
        remediationCycles: 2,
      ),
    );
    expect(
      c.teachingProgressFor('num-add').mastery,
      MasteryStatus.needsSupport,
    );
    expect(c.activeProgress.completedLessons, isNot(contains('num-add')));
    expect(c.activeProfile!.stars, 0);
    // The child can still master it later.
    await c.recordTeachingMastery(
      world: worldOf(c, 'num-add'),
      lesson: lessonOf(c, 'num-add'),
      teaching: const TeachingProgress(viewed: true),
    );
    expect(c.activeProgress.completedLessons, contains('num-add'));
    expect(c.teachingProgressFor('num-add').mastery, MasteryStatus.mastered);
  });

  test('needsSupport never overwrites mastered on a replay', () async {
    final c = await makeController();
    await c.recordTeachingMastery(
      world: worldOf(c, 'en-a'),
      lesson: lessonOf(c, 'en-a'),
      teaching: const TeachingProgress(viewed: true),
    );
    await c.recordTeachingNeedsSupport(
      lesson: lessonOf(c, 'en-a'),
      teaching: const TeachingProgress(mastery: MasteryStatus.needsSupport),
    );
    expect(c.teachingProgressFor('en-a').mastery, MasteryStatus.mastered);
  });

  test('ordinary results keep teaching progress', () async {
    final c = await makeController();
    await c.saveTeachingProgress(
      'en-a',
      const TeachingProgress(viewed: true, phase: 'practice'),
    );
    final other = c.allWorlds.first.lessons[1];
    await c.recordResult(
      world: c.allWorlds.first,
      lesson: other,
      correct: true,
    );
    expect(c.teachingProgressFor('en-a').phase, 'practice');
  });

  test('level switching keeps teaching progress per lesson', () async {
    final c = await makeController();
    await c.saveTeachingProgress(
      'en-a',
      const TeachingProgress(viewed: true, checkBestScore: 2),
    );
    await c.setLevel(3);
    await c.setLevel(1);
    expect(c.teachingProgressFor('en-a').checkBestScore, 2);
    await c.setLevel(5);
    expect(c.teachingProgressFor('en-a').viewed, isTrue);
  });

  test('progress JSON round trip; empty teaching is not written', () {
    expect(ProgressRecord.empty().toJson().containsKey('teaching'), isFalse);
    const t = TeachingProgress(
      viewed: true,
      phasesDone: {'introduce', 'demonstrate'},
      guidedDone: true,
      checkBestScore: 3,
      checkLastScore: 1,
      mastery: MasteryStatus.needsSupport,
      remediationCycles: 2,
      updatedAt: '2026-10-31T00:00:00Z',
      phase: 'remediation',
    );
    final back = TeachingProgress.fromJson(
      jsonDecode(jsonEncode(t.toJson())) as Map<String, dynamic>,
    );
    expect(back.phasesDone, t.phasesDone);
    expect(back.checkBestScore, 3);
    expect(back.checkLastScore, 1);
    expect(back.mastery, MasteryStatus.needsSupport);
    expect(back.remediationCycles, 2);
    expect(back.phase, 'remediation');
    expect(back.guidedDone, isTrue);
    expect(back.practiceDone, isFalse);
  });

  group('real save files', () {
    late Directory temp;
    late File file;
    setUp(() {
      temp = Directory.systemTemp.createTempSync('aksha_teaching_');
      file = File('${temp.path}/progress.json');
    });
    tearDown(() => temp.deleteSync(recursive: true));

    test(
        'an old save without teaching fields loads unchanged and keeps '
        'working; the v1 backup still happens', () async {
      final old = {
        'profiles': [
          {'id': 'a', 'name': 'Old', 'age': 6, 'avatar': 'lion', 'stars': 5},
        ],
        'progress': {
          'a': {
            'completedLessons': ['en-b'],
            'attempts': {'english': 2},
            'correct': {'english': 1},
            'lastPlayed': {'english': 'en-b'},
            'earnedBadges': ['first-step'],
            'questStars': {'en-b': 3},
          },
        },
      };
      file.writeAsStringSync(jsonEncode(old));
      final c = AppController(
        store: LocalStore(fileOverride: file),
        teachingPlanLoader: () async => [pilotJson()],
      );
      await c.initialise();
      final rec = c.activeProgress;
      expect(rec.completedLessons, {'en-b'});
      expect(rec.attempts['english'], 2);
      expect(rec.questStars['en-b'], 3);
      expect(rec.teaching, isEmpty);
      expect(c.activeProfile!.stars, 5);
      expect(c.activeProfile!.level, 2, reason: 'age 6 -> level 2 as before');
      expect(File('${file.path}.v1.bak').existsSync(), isTrue);

      // It keeps working: an ordinary result still pays.
      await c.recordResult(
        world: worldOf(c, 'en-a'),
        lesson: lessonOf(c, 'en-a'),
        correct: true,
      );
      final saved = jsonDecode(file.readAsStringSync()) as Map;
      final prog = (saved['progress'] as Map)['a'] as Map;
      expect(prog.containsKey('teaching'), isFalse);
      expect(saved['version'], saveFormatVersion);

      // A taught lesson adds the new field next to the old ones.
      await c.saveTeachingProgress(
        'en-a',
        const TeachingProgress(viewed: true),
      );
      final c2 = AppController(store: LocalStore(fileOverride: file));
      await c2.initialise();
      expect(
        c2.activeProgress.completedLessons,
        containsAll(['en-b', 'en-a']),
      );
      expect(c2.teachingProgressFor('en-a').viewed, isTrue);
    });
  });
}
