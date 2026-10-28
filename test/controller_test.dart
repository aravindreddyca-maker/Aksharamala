import 'dart:io';

import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temp;
  late File snapshot;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('aksharamala_test_');
    snapshot = File('${temp.path}/progress.json');
  });

  tearDown(() async => temp.delete(recursive: true));

  test('profile and learning result survive a local reload', () async {
    final first = AppController(store: LocalStore(fileOverride: snapshot));
    await first.initialise();
    await first.addProfile('Asha', 6, '🦄');
    final world = curriculum.first;
    await first.recordResult(
      world: world,
      lesson: world.lessons.first,
      correct: true,
    );

    final second = AppController(store: LocalStore(fileOverride: snapshot));
    await second.initialise();
    expect(second.profiles.single.name, 'Asha');
    expect(second.profiles.single.stars, 3);
    expect(second.activeProgress.completedLessons, contains('en-a'));
    expect(second.activeProgress.earnedBadges, contains('first-step'));
  });

  test('adaptive engine prioritises an unfinished lesson', () async {
    final controller = AppController(store: LocalStore(fileOverride: snapshot));
    await controller.initialise();
    await controller.addProfile('Kabir', 8, '🐯');
    final world = curriculum.first;
    expect(controller.recommendedLesson(world).id, world.lessons.first.id);
    await controller.recordResult(
      world: world,
      lesson: world.lessons.first,
      correct: true,
    );
    expect(controller.recommendedLesson(world).id, world.lessons[1].id);
  });
}
