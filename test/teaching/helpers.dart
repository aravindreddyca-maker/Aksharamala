import 'dart:io';

import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/teaching/teaching_flow.dart';
import 'package:aksharamala/src/teaching/teaching_lesson_screen.dart';
import 'package:aksharamala/src/teaching/teaching_plan.dart';
import 'package:aksharamala/src/services/speech_service.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads the real pilot file once (plain async, outside any fake clock).
String pilotJson() =>
    File('content/teaching/pilot_teaching_plans.json').readAsStringSync();

TeachingPlanLibrary pilotLibrary() => TeachingPlanLibrary.parse([pilotJson()]);

/// A store that never touches the disk.
class NoDiskStore extends LocalStore {
  LocalSnapshot? last;
  int saves = 0;
  @override
  Future<LocalSnapshot> load() async =>
      const LocalSnapshot(profiles: [], progress: {});
  @override
  Future<void> save(LocalSnapshot snapshot) async {
    last = snapshot;
    saves++;
  }
}

/// Speech that never reaches a platform channel.
class FakeSpeech extends SpeechService {
  FakeSpeech({this.supported = true});
  final bool supported;
  final spoken = <String>[];
  @override
  Future<bool> speak(String text, String locale) async {
    spoken.add(text);
    return supported;
  }

  @override
  Future<void> stop() async {}
}

Future<AppController> makeController({
  NoDiskStore? store,
  String? json,
  int level = 1,
}) async {
  final text = json ?? pilotJson();
  final c = AppController(
    store: store ?? NoDiskStore(),
    teachingPlanLoader: () async => [text],
  );
  await c.initialise();
  await c.createProfile(name: 'Kid', level: level, avatar: 'lion');
  return c;
}

LearningWorld worldOf(AppController c, String lessonId) =>
    c.allWorlds.firstWhere((w) => w.lessons.any((l) => l.id == lessonId));

Lesson lessonOf(AppController c, String lessonId) =>
    worldOf(c, lessonId).lessons.firstWhere((l) => l.id == lessonId);

String wrongOf(TeachingQuestion q) =>
    q.options.firstWhere((o) => o != q.answer);

List<TeachingQuestion> easyToHard(List<TeachingQuestion> l) {
  final e = l.asMap().entries.toList()
    ..sort((a, b) {
      final d = a.value.difficulty.compareTo(b.value.difficulty);
      return d != 0 ? d : a.key.compareTo(b.key);
    });
  return [for (final x in e) x.value];
}

/// Plays the current phase of [f] to its end, answering every question
/// [correct] or not (check phases only; feedback phases always end solved).
void finishPhase(TeachingFlow f, {bool correct = true}) {
  final start = f.phase;
  var guard = 0;
  while (f.phase == start && guard++ < 50) {
    final q = f.question;
    if (q != null) {
      if (f.phase.isCheck) {
        f.pick(correct ? q.answer : wrongOf(q));
      } else {
        f.pick(q.answer);
      }
    }
    f.next();
  }
}

/// Runs a fresh flow through to the check result.
void toCheckResult(TeachingFlow f, {required bool correct}) {
  while (f.phase != TeachingPhase.check) {
    finishPhase(f);
  }
  finishPhase(f, correct: correct);
  expect(f.phase, TeachingPhase.checkResult);
}

Future<void> pumpLesson(
  WidgetTester tester,
  AppController c,
  String lessonId, {
  Size size = const Size(800, 1280),
  double textScale = 1.0,
  int seed = 7,
  FakeSpeech? speech,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    AppScope(
      controller: c,
      child: MaterialApp(
        theme: buildTheme(),
        home: TeachingLessonScreen(
          world: worldOf(c, lessonId),
          lesson: lessonOf(c, lessonId),
          plan: c.planFor(lessonId)!,
          seed: seed,
          speech: speech ?? FakeSpeech(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> tapNext(WidgetTester tester) async {
  // On the score page the button is 'Continue' and inert for a moment.
  final cont = find.byKey(const Key('continue_button'));
  if (cont.evaluate().isNotEmpty) {
    await tester.pump(resultDebounce + const Duration(milliseconds: 50));
    await tester.ensureVisible(cont);
    await tester.tap(cont);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return;
  }
  final b = find.byKey(const Key('next_button'));
  await tester.ensureVisible(b);
  await tester.tap(b);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> tapOption(WidgetTester tester, String option) async {
  final f = find.byKey(Key('option_$option'));
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pump();
}

Future<void> nextTimes(WidgetTester tester, int n) async {
  for (var i = 0; i < n; i++) {
    await tapNext(tester);
  }
}

/// Answers a list of questions on screen (guided / practice style).
Future<void> solveAll(
  WidgetTester tester,
  List<TeachingQuestion> qs,
) async {
  for (final q in qs) {
    await tapOption(tester, q.answer);
    await tapNext(tester);
  }
}

Future<void> checkAll(
  WidgetTester tester,
  List<TeachingQuestion> qs, {
  required int rightCount,
}) async {
  for (var i = 0; i < qs.length; i++) {
    await tapOption(tester, i < rightCount ? qs[i].answer : wrongOf(qs[i]));
    await tapNext(tester);
  }
}
