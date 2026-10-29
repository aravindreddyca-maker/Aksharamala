import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/handwriting/handwriting_registry.dart';
import 'package:aksharamala/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedRecognition = {
    'english': 26,
    'telugu': 51,
    'hindi': 46,
    'tamil': 30,
  };

  const legacyIds = {
    'en-a',
    'en-word',
    'en-trace',
    'en-story',
    'te-a',
    'te-word',
    'te-trace',
    'te-story',
    'hi-a',
    'hi-word',
    'hi-trace',
    'hi-story',
    'ta-a',
    'ta-word',
    'ta-trace',
    'ta-story',
    'num-count',
    'num-add',
    'num-subtract',
    'num-names',
  };

  test('legacy IDs remain present and every ID is globally unique', () {
    final ids = [for (final w in curriculum) ...w.lessons.map((l) => l.id)];
    expect(ids.toSet().length, ids.length);
    expect(ids.toSet(), containsAll(legacyIds));
  });

  test('every lesson has complete progression metadata', () {
    for (final world in curriculum) {
      for (final lesson in world.lessons) {
        expect(lesson.ageBands, isNotEmpty, reason: lesson.id);
        expect(lesson.learningObjective.trim(), isNotEmpty, reason: lesson.id);
        expect(LessonDifficulty.values, contains(lesson.difficultyLevel));
        expect(lesson.prerequisites.toSet().length, lesson.prerequisites.length,
            reason: lesson.id);
      }
    }
  });

  test('prerequisites resolve inside their world and contain no cycles', () {
    for (final world in curriculum) {
      final byId = {for (final lesson in world.lessons) lesson.id: lesson};
      for (final lesson in world.lessons) {
        for (final prerequisite in lesson.prerequisites) {
          expect(byId, contains(prerequisite),
              reason: '${lesson.id} -> $prerequisite');
        }
      }

      final visiting = <String>{};
      final visited = <String>{};
      void visit(String id) {
        expect(visiting.add(id), isTrue, reason: 'cycle reaches $id');
        for (final prerequisite in byId[id]!.prerequisites) {
          if (!visited.contains(prerequisite)) visit(prerequisite);
        }
        visiting.remove(id);
        visited.add(id);
      }

      for (final id in byId.keys) {
        if (!visited.contains(id)) visit(id);
      }
    }
  });

  test('all four language recognition inventories are complete and playable',
      () {
    for (final entry in expectedRecognition.entries) {
      final world = curriculum.firstWhere((w) => w.id == entry.key);
      final lessons = world.lessons
          .where((lesson) =>
              lesson.kind == LessonKind.alphabet &&
              lesson.ageBands.contains(ExperienceStage.explorer))
          .toList();
      expect(lessons.length, entry.value, reason: entry.key);
      for (final lesson in lessons) {
        expect(lesson.options.length, 3, reason: lesson.id);
        expect(lesson.options.toSet().length, 3, reason: lesson.id);
        expect(lesson.options.where((o) => o == lesson.answer).length, 1,
            reason: lesson.id);
      }
    }
  });

  test('every world has distinct real content for all four age bands', () {
    for (final world in curriculum) {
      final idsByStage = <ExperienceStage, Set<String>>{};
      for (final stage in ExperienceStage.values) {
        final lessons = world.lessons.where((l) => l.supportsStage(stage));
        expect(lessons, isNotEmpty, reason: '${world.id}/${stage.name}');
        expect(
            lessons.every(
                (l) => l.options.isNotEmpty || l.kind == LessonKind.tracing),
            isTrue,
            reason: '${world.id}/${stage.name} contains empty content');
        idsByStage[stage] = lessons.map((l) => l.id).toSet();
      }
      for (final a in ExperienceStage.values) {
        for (final b
            in ExperienceStage.values.where((b) => b.index > a.index)) {
          expect(idsByStage[a]!.intersection(idsByStage[b]!), isEmpty,
              reason: '${world.id}: ${a.name} duplicates ${b.name}');
        }
      }
    }
  });

  test('age-aware recommendations differ in every world', () {
    final young = AppController()
      ..activeProfile = const ChildProfile(
          id: 'young', name: 'Young', age: 3, avatar: 'lion');
    final older = AppController()
      ..activeProfile = const ChildProfile(
          id: 'older', name: 'Older', age: 12, avatar: 'lion');
    for (final world in curriculum) {
      expect(
          young.recommendedLesson(world.forStage(ExperienceStage.explorer)).id,
          isNot(older
              .recommendedLesson(world.forStage(ExperienceStage.champion))
              .id),
          reason: world.id);
    }
  });

  test('language handwriting remains practice without verified templates', () {
    for (final world in curriculum.where((w) => w.id != 'numbers')) {
      for (final lesson
          in world.lessons.where((l) => l.kind == LessonKind.tracing)) {
        final template = templateFor(lesson.symbol);
        expect(template == null || !template.strokeOrderVerified, isTrue,
            reason: lesson.id);
      }
    }
  });
}
