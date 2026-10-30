import 'dart:convert';
import 'dart:io';

import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/batch/age56_content.dart';
import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/world_map_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoDiskStore extends LocalStore {
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

Map<String, dynamic> _source(String module) =>
    jsonDecode(File('content/age56/${module}_age_5_6.json').readAsStringSync())
        as Map<String, dynamic>;

AppController _controller() {
  const profile =
      ChildProfile(id: 'p', name: 'Creator', age: 5, avatar: 'lion');
  return AppController(store: _NoDiskStore())
    ..profiles = const [profile]
    ..progress = {'p': ProgressRecord.empty()}
    ..activeProfile = profile
    ..loaded = true;
}

void main() {
  const expected = {
    'english': 30,
    'telugu': 26,
    'hindi': 26,
    'tamil': 26,
    'numbers': 54,
  };

  test('all five supplied JSON files are complete and structurally valid', () {
    final allIds = <String>{};
    final placeholder = RegExp(
      r'placeholder|todo|tbd|lorem|coming soon',
      caseSensitive: false,
    );
    for (final entry in expected.entries) {
      final source = _source(entry.key);
      expect(source['module'], entry.key);
      expect(source['age_band'], '5-6');
      final lessons = (source['lessons'] as List).cast<Map<String, dynamic>>();
      expect(lessons, hasLength(entry.value), reason: entry.key);
      final moduleIds = lessons.map((lesson) => lesson['id'] as String).toSet();
      expect(moduleIds, hasLength(lessons.length), reason: entry.key);
      expect(allIds.intersection(moduleIds), isEmpty, reason: entry.key);
      allIds.addAll(moduleIds);
      final prompts = <String>{};
      for (final lesson in lessons) {
        final id = lesson['id'] as String;
        expect(placeholder.hasMatch(jsonEncode(lesson)), isFalse, reason: id);
        expect(lesson['module'], entry.key, reason: id);
        expect(lesson['age_band'], '5-6', reason: id);
        for (final field in ['title', 'objective', 'topic', 'skill']) {
          expect((lesson[field] as String).trim(), isNotEmpty,
              reason: '$id $field');
        }
        final steps = (lesson['steps'] as List).cast<Map<String, dynamic>>();
        final teach = steps.where((step) => step['type'] == 'teach').single;
        final practice =
            steps.where((step) => step['type'] == 'practice').single;
        expect((teach['text'] as String).trim(), isNotEmpty, reason: id);
        expect(practice['shuffle_options'], isTrue, reason: id);
        final options = (practice['options'] as List).cast<String>();
        expect(options.length, greaterThanOrEqualTo(2), reason: id);
        expect(options.toSet(), hasLength(options.length), reason: id);
        expect(options, contains(practice['answer']), reason: id);
        expect(prompts.add(practice['prompt'] as String), isTrue, reason: id);
        for (final prerequisite
            in (lesson['prerequisites'] as List).cast<String>()) {
          expect(moduleIds, contains(prerequisite), reason: id);
        }
      }
    }
    expect(allIds, hasLength(162));
  });

  test('generated BatchLessons exactly retain source teaching and answers', () {
    expect(age56GeneratedLessonCount, 162);
    expect(allAge56Lessons, hasLength(162));
    final generated = {for (final lesson in allAge56Lessons) lesson.id: lesson};
    for (final module in expected.keys) {
      final lessons =
          (_source(module)['lessons'] as List).cast<Map<String, dynamic>>();
      for (final source in lessons) {
        final id = source['id'] as String;
        final lesson = generated[id]!;
        final steps = (source['steps'] as List).cast<Map<String, dynamic>>();
        final teach = steps.where((step) => step['type'] == 'teach').single;
        final practice =
            steps.where((step) => step['type'] == 'practice').single;
        expect(lesson.ageBands, {ExperienceStage.creator}, reason: id);
        expect(lesson.difficultyLevel, isNot(LessonDifficulty.foundation),
            reason: id);
        expect(lesson.learningObjective, source['objective'], reason: id);
        expect(lesson.topic, source['topic'], reason: id);
        expect(lesson.skill, source['skill'], reason: id);
        expect(lesson.examples, isNotEmpty, reason: id);
        expect(lesson.educatorReviewVerified, isFalse, reason: id);
        expect(lesson.steps, hasLength(2), reason: id);
        expect(lesson.steps.first.kind, StepKind.listen, reason: id);
        expect(lesson.steps.first.prompt, teach['text'], reason: id);
        expect(lesson.steps.last.kind, StepKind.choice, reason: id);
        expect(lesson.steps.last.prompt, practice['prompt'], reason: id);
        expect(lesson.steps.last.options, practice['options'], reason: id);
        expect(lesson.steps.last.answer, practice['answer'], reason: id);
      }
    }
  });

  test('effective prerequisite graphs are complete, resolvable and acyclic',
      () {
    for (final entry in age56ByWorld.entries) {
      final lessons = entry.value;
      final byId = {for (final lesson in lessons) lesson.id: lesson};
      expect(lessons.first.prerequisites, isEmpty, reason: entry.key);
      for (var i = 1; i < lessons.length; i++) {
        expect(lessons[i].prerequisites, isNotEmpty, reason: lessons[i].id);
        for (final prerequisite in lessons[i].prerequisites) {
          expect(byId, contains(prerequisite), reason: lessons[i].id);
          expect(lessons.indexOf(byId[prerequisite]!), lessThan(i),
              reason: lessons[i].id);
        }
      }
    }
  });

  test('age-five worlds include every supplied lesson in the existing engine',
      () {
    final controller = _controller();
    for (final entry in expected.entries) {
      final world =
          controller.worlds.firstWhere((world) => world.id == entry.key);
      final imported = world.lessons.whereType<BatchLesson>().where(
            (lesson) => lesson.id.contains('-56-'),
          );
      expect(imported, hasLength(entry.value), reason: entry.key);
    }
  });

  test('prerequisites prevent bypass and unlock after completion', () async {
    final controller = _controller();
    final world =
        controller.worlds.firstWhere((world) => world.id == 'english');
    final first =
        world.lessons.firstWhere((lesson) => lesson.id == 'english-56-001');
    final second =
        world.lessons.firstWhere((lesson) => lesson.id == 'english-56-002');
    expect(controller.isLessonUnlocked(first), isTrue);
    expect(controller.isLessonUnlocked(second), isFalse);
    expect(
        await controller.recordResult(
            world: world, lesson: second, correct: true),
        0);
    expect(
        controller.activeProgress.completedLessons, isNot(contains(second.id)));
    expect(
        await controller.recordResult(
            world: world, lesson: first, correct: true),
        3);
    expect(controller.isLessonUnlocked(second), isTrue);
  });

  testWidgets('locked quest cards cannot navigate until prerequisites are met',
      (tester) async {
    final controller = _controller();
    final world =
        controller.worlds.firstWhere((world) => world.id == 'english');
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
            theme: buildTheme(), home: WorldMapScreen(world: world)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('lesson_english-56-002')),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    final locked = tester.widget<InkWell>(
      find.byKey(const Key('lesson_english-56-002')),
    );
    expect(locked.onTap, isNull);
    expect(find.text('Locked'), findsWidgets);
  });

  test('handwriting remains non-mastery and imported speech is unverified', () {
    expect(StepKind.write.isRequired, isFalse);
    for (final lesson in allAge56Lessons) {
      expect(lesson.steps.where((step) => step.kind == StepKind.write), isEmpty,
          reason: lesson.id);
      expect(lesson.steps.first.speech.trim(), isNotEmpty, reason: lesson.id);
      expect(lesson.educatorReviewVerified, isFalse, reason: lesson.id);
    }
  });

  test('all pre-import legacy lesson IDs remain present', () {
    const legacy = {
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
    final ids = {
      for (final world in curriculum) ...world.lessons.map((l) => l.id)
    };
    expect(ids, containsAll(legacy));
  });
}
