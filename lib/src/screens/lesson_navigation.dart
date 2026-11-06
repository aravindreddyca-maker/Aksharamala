import 'package:flutter/material.dart';

import '../app.dart';
import '../app_controller.dart';
import '../batch/batch_lesson.dart';
import '../models.dart';
import '../teaching/teaching_lesson_screen.dart';
import 'batch_lesson_screen.dart';
import 'lesson_screen.dart';

/// The screen that plays [lesson]: taught step by step when it has a teaching
/// plan, otherwise its existing batch or quest screen. One place, so the lesson
/// map and "Next Lesson" always open a lesson the same way.
Widget lessonScreenFor(
  AppController controller,
  LearningWorld world,
  Lesson lesson,
) {
  final plan = controller.planFor(lesson.id);
  if (plan != null) {
    return TeachingLessonScreen(world: world, lesson: lesson, plan: plan);
  }
  return lesson is BatchLesson
      ? BatchLessonScreen(world: world, lesson: lesson)
      : LessonScreen(world: world, lesson: lesson);
}

/// The lesson that follows [lesson] in the same world at the child's level:
/// the next one in the list that is open to the child. Null for the last one.
/// It never moves to another level or another world.
Lesson? nextLessonAfter(
  AppController controller,
  LearningWorld world,
  Lesson lesson,
) {
  final shown = controller.worlds.where((w) => w.id == world.id);
  final lessons = (shown.isEmpty ? world : shown.first).lessons;
  final at = lessons.indexWhere((l) => l.id == lesson.id);
  if (at < 0) return null;
  for (var i = at + 1; i < lessons.length; i++) {
    if (controller.isLessonUnlocked(lessons[i])) return lessons[i];
  }
  return null;
}

/// A "Next Lesson" action for the result popup, or null when [lesson] is the
/// last one. Progress was already saved by the time the popup is on screen.
/// It closes the popup, then swaps this lesson for the next, so Back from the
/// next lesson returns to the lesson list.
VoidCallback? nextLessonAction(
  BuildContext context,
  LearningWorld world,
  Lesson lesson, {
  required bool correct,
}) {
  if (!correct) return null;
  final controller = AppScope.of(context);
  final next = nextLessonAfter(controller, world, lesson);
  if (next == null) return null;
  final navigator = Navigator.of(context);
  return () {
    // Pop the popup, then replace the finished lesson with the next one.
    navigator.pop();
    navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => lessonScreenFor(controller, world, next),
      ),
    );
  };
}
