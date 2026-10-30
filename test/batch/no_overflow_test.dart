import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/batch/age56_content.dart';
import 'package:aksharamala/src/batch/batch_content.dart';
import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/batch_lesson_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// "BOTTOM OVERFLOWED BY 225 PIXELS" appeared in a Tamil lesson on a short
/// phone. This plays every step of every lesson on the smallest landscape
/// screens and fails on any layout error.
class _S extends LocalStore {
  @override
  Future<LocalSnapshot> load() async =>
      const LocalSnapshot(profiles: [], progress: {});
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

Future<void> _play(
  WidgetTester tester,
  LearningWorld world,
  BatchLesson lesson,
  Size size,
  double textScale,
) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  final c = AppController(store: _S());
  await c.initialise();
  await c.addProfile('K', 5, 'lion');
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    AppScope(
      controller: c,
      child: MaterialApp(
        theme: buildTheme(),
        home: BatchLessonScreen(
          world: world,
          lesson: lesson,
          maskLoader: (_) async => throw UnimplementedError(),
        ),
      ),
    ),
  );
  await tester.pump();
  for (var i = 0; i < lesson.steps.length - 1; i++) {
    _note(tester,
        '${lesson.id} step ${i + 1} at ${size.width.toInt()}x${size.height.toInt()} x$textScale');
    final step = lesson.steps[i];
    if (step.kind.isQuestion) {
      final finder = find.byKey(Key('answer_${step.answer}'));
      if (finder.evaluate().isNotEmpty) {
        await tester.ensureVisible(finder);
        await tester.tap(finder, warnIfMissed: false);
        await tester.pump();
      }
    }
    if (step.kind == StepKind.count) {
      for (var k = 0; k < (step.quantity ?? 0); k++) {
        final star = find.byKey(Key('count_star_$k'));
        if (star.evaluate().isNotEmpty) {
          await tester.tap(star, warnIfMissed: false);
          await tester.pump();
        }
      }
    }
    final next = find.byKey(const Key('batch_next'));
    final button = tester.widget<FilledButton>(next);
    if (button.onPressed == null) break;
    await tester.tap(next);
    await tester.pump();
  }
  _note(tester,
      '${lesson.id} last step at ${size.width.toInt()}x${size.height.toInt()} x$textScale');
}

final problems = <String>[];

/// Records (instead of stopping at) a layout error, with where it happened.
void _note(WidgetTester tester, String where) {
  final e = tester.takeException();
  if (e != null) {
    final text = e.toString().split('\n');
    final widget =
        text.firstWhere((l) => l.contains('file:///'), orElse: () => '');
    problems.add('$where: ${text.first} ${widget.trim()}');
  }
}

void main() {
  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  final worlds = worldsWithBatch(worldsWithAge56(curriculum));
  LearningWorld worldOf(BatchLesson l) => worlds.firstWhere(
        (w) => w.lessons.any((x) => x.id == l.id),
      );

  for (final size in const [Size(640, 360), Size(800, 360)]) {
    testWidgets(
        'every age 5-6 lesson fits at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      problems.clear();
      for (final lesson in allAge56Lessons) {
        await _play(tester, worldOf(lesson), lesson, size, 1.0);
      }
      expect(problems, isEmpty,
          reason:
              '${problems.length} problems\n${problems.take(12).join('\n')}');
    });
  }

  testWidgets('every age 5-6 lesson fits with large text at 800x360',
      (tester) async {
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    problems.clear();
    for (final lesson in allAge56Lessons) {
      await _play(tester, worldOf(lesson), lesson, const Size(800, 360), 1.3);
    }
    expect(problems, isEmpty,
        reason: '${problems.length} problems\n${problems.take(12).join('\n')}');
  });

  testWidgets('the first-batch Telugu and number lessons fit at 640x360',
      (tester) async {
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    problems.clear();
    for (final lesson in [...teluguBatch, ...numbersBatch]) {
      await _play(tester, worldOf(lesson), lesson, const Size(640, 360), 1.0);
    }
    expect(problems, isEmpty,
        reason: '${problems.length} problems\n${problems.take(12).join('\n')}');
  });
}
