import 'dart:convert';
import 'dart:math';

import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/exam/exam_controller.dart';
import 'package:aksharamala/src/exam/exam_store.dart';
import 'package:aksharamala/src/exam/models.dart';
import 'package:aksharamala/src/exam/question_bank.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/exam/exam_scope.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/services/speech_service.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../exam/helpers.dart';

export '../exam/helpers.dart';

/// Real disk IO never completes inside a widget test, so nothing here uses it.
class NoDiskStore extends LocalStore {
  @override
  Future<LocalSnapshot> load() async =>
      const LocalSnapshot(profiles: [], progress: {});

  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

/// `exams.json` held in memory (round-tripped through JSON like the real
/// file), so a second controller can be built from the same "disk".
class MemoryExamStore extends ExamStore {
  ExamData disk = const ExamData();
  int saves = 0;

  @override
  Future<ExamData> load() async {
    lastLoadStatus = ExamLoadStatus.ok;
    return disk;
  }

  @override
  Future<void> save(ExamData data) async {
    disk = ExamData.fromJson(Map<String, dynamic>.from(
        jsonDecode(jsonEncode(data.toJson())) as Map));
    saves++;
  }
}

class FakeSpeech implements SpeechService {
  final List<String> spoken = [];
  int stops = 0;

  @override
  Future<bool> speak(String text, String locale) async {
    spoken.add('$locale|$text');
    return true;
  }

  @override
  Future<void> stop() async => stops++;
}

const kid =
    ChildProfile(id: 'kid', name: 'Asha', age: 5, avatar: 'lion', level: 1);
const sibling =
    ChildProfile(id: 'sib', name: 'Ravi', age: 8, avatar: 'panda', level: 2);

AppController appController({List<ChildProfile> profiles = const [kid]}) =>
    AppController(store: NoDiskStore())
      ..profiles = [...profiles]
      ..progress = {for (final p in profiles) p.id: ProgressRecord.empty()}
      ..activeProfile = profiles.isEmpty ? null : profiles.first
      ..loaded = true;

/// English level 1: 6 lessons x 3 questions = 18 auto-marked questions.
List<ExamQuestion> uiBank({bool parentMarked = false}) => [
      ...makeBank(world: 'english', lessons: 6, perLesson: 3),
      if (parentMarked)
        mq('P0', 0, world: 'english', type: ExamQuestionType.parentMarked),
    ];

ExamController examController(
  MemoryExamStore store,
  List<ExamQuestion> bank, {
  TestClock? clock,
}) =>
    ExamController(
      store: store,
      bank: ExamQuestionBank.fromQuestions(bank),
      clock: clock?.call,
      random: Random(7),
    );

/// A question made for the child-screen tests.
ExamQuestion richQuestion({
  String id = 'R0#q0',
  String prompt = 'Which one is a cat?',
  String? speech,
  String explanation = 'Because it says meow.',
}) =>
    ExamQuestion(
      id: id,
      lessonId: 'R0',
      lessonTitle: 'Animals',
      level: 1,
      world: 'english',
      topic: 'Animals',
      objective: 'Name animals',
      type: ExamQuestionType.multipleChoice,
      prompt: prompt,
      speech: speech,
      options: const ['Cat', 'Dog', 'Cow'],
      correctAnswer: 'Cat',
      explanation: explanation,
      verification: const {Verification.machineChecked},
    );

Future<void> setView(
  WidgetTester tester,
  Size size, {
  double scale = 1.0,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

/// Builds the app scopes around [home] (a fresh tree each call).
Future<void> pumpApp(
  WidgetTester tester, {
  required ExamController exams,
  required Widget home,
  AppController? app,
  Size size = const Size(800, 1280),
  double scale = 1.0,
}) async {
  await setView(tester, size, scale: scale);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    AppScope(
      controller: app ?? appController(),
      child: ExamScope(
        controller: exams,
        child: MaterialApp(theme: buildTheme(), home: home),
      ),
    ),
  );
  await settle(tester);
}

/// Makes sure the widget with [key] is built and on screen.
Future<void> reveal(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  if (f.evaluate().isEmpty) {
    // Lists build lazily: try each vertical list, top first, until it exists.
    final lists = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    final n = lists.evaluate().length;
    for (var i = 0; i < n && f.evaluate().isEmpty; i++) {
      final list = lists.at(i);
      await tester.drag(list, const Offset(0, 6000));
      await tester.pumpAndSettle();
      if (f.evaluate().isNotEmpty) break;
      try {
        await tester.scrollUntilVisible(f, 200,
            scrollable: list, maxScrolls: 60);
      } catch (_) {
        // not in this list
      }
    }
  }
  await tester.ensureVisible(f);
  await settle(tester);
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await reveal(tester, key);
  await tester.tap(find.byKey(Key(key)));
  await settle(tester);
}

Future<void> openTab(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await settle(tester);
}

/// The option button showing [text] on the child screen.
Finder optionWith(String text) => find.descendant(
      of: find.byWidgetPredicate((w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('option_')),
      matching: find.text(text),
    );

void expectNoOverflow(WidgetTester tester) {
  final e = tester.takeException();
  expect(e, isNull, reason: 'layout exception: $e');
}

/// Runs [f] to completion. Futures that need the microtask queue never finish
/// inside a widget test's fake-async zone unless run like this.
Future<T> real<T>(Future<T> Function() f) async =>
    (await TestWidgetsFlutterBinding.instance.runAsync(f)) as T;

/// Settles the widget tree and the (real-time) exam store writes that the
/// controller awaits before it notifies listeners.
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
  await tester.pumpAndSettle();
}
