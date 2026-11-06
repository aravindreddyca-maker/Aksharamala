// Renders the exam screens with REAL Roboto + Material Icons (loaded from the
// Flutter SDK) so a human/agent can look at PNGs. Run with --update-goldens.
// English only: Telugu/Hindi/Tamil shaping is NOT covered (no font bundled).
import 'dart:io';

import 'package:aksharamala/src/exam/exam_controller.dart';
import 'package:aksharamala/src/exam/models.dart';
import 'package:aksharamala/src/screens/exam/certificates_tab.dart';
import 'package:aksharamala/src/screens/exam/child_exam_screen.dart';
import 'package:aksharamala/src/screens/exam/examination_centre.dart';
import 'package:aksharamala/src/screens/exam/results_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../exam_ui/ui_helpers.dart';

const _fonts = 'E:/flutter-sdk/bin/cache/artifacts/material_fonts';

Future<void> _load(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(
        ByteData.sublistView(File('$_fonts/$f').readAsBytesSync())));
  }
  await l.load();
}

List<ExamQuestion> _bank() => [
      for (var i = 0; i < 8; i++)
        ExamQuestion(
          id: 'E$i#q0',
          lessonId: 'E$i',
          lessonTitle: 'Animal sounds $i',
          level: 1,
          world: 'english',
          topic: 'alphabet',
          objective: 'Name common animals',
          type: ExamQuestionType.multipleChoice,
          prompt: 'Which animal says meow? ($i)',
          options: const ['Cat', 'Dog', 'Cow'],
          correctAnswer: 'Cat',
          explanation: 'A cat says meow.',
          verification: const {Verification.machineChecked},
        ),
    ];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _load('Roboto', [
      'roboto-regular.ttf',
      'roboto-bold.ttf',
      'roboto-black.ttf',
      'roboto-medium.ttf'
    ]);
    await _load('MaterialIcons', ['materialicons-regular.otf']);
  });

  Future<void> shot(WidgetTester tester, String name) async {
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  testWidgets('capture exam screens',
      skip: !Platform.environment.containsKey('EXAM_VERIFY_SHOTS'),
      (tester) async {
    final store = MemoryExamStore();
    final clock = TestClock();
    final exams = examController(store, _bank(), clock: clock);
    final out = await real(() => exams.startExam(ExamConfig(
          id: 'c1',
          childId: 'kid',
          childName: 'Asha',
          level: 1,
          type: ExamType.finalLevel,
          worlds: const ['english'],
          questionCount: 6,
          passPercent: 60,
          timeLimitSeconds: 900,
          createdAt: DateTime(2026, 1, 1),
        )));
    final a = (out as StartExamStarted).attempt;

    // 1. Child question at 360x800 (phone).
    await pumpApp(tester,
        exams: exams,
        size: const Size(360, 800),
        home: ChildExamScreen(
            attemptId: a.id, speech: FakeSpeech(), now: clock.call));
    await tester.tap(find
        .ancestor(
            of: find.text(a.questions[0].options[1]),
            matching: find.byType(InkWell))
        .first);
    await settle(tester);
    await shot(tester, 'child_question_360x800');

    // 2. Same at landscape 800x360 with 1.6 text.
    await pumpApp(tester,
        exams: exams,
        size: const Size(800, 360),
        scale: 1.6,
        home: ChildExamScreen(
            attemptId: a.id, speech: FakeSpeech(), now: clock.call));
    await shot(tester, 'child_question_800x360_t16');

    // 3. Review page.
    await pumpApp(tester,
        exams: exams,
        size: const Size(360, 800),
        home: ChildExamScreen(
            attemptId: a.id, speech: FakeSpeech(), now: clock.call));
    for (var i = 0; i < 4; i++) {
      await tapKey(tester, 'next_question');
    }
    await tapKey(tester, 'go_review');
    await shot(tester, 'child_review_360x800');

    // 4. Done page.
    await real(() => answerAll(exams, a, right: 5));
    await tapKey(tester, 'submit_exam');
    await tapKey(tester, 'confirm_submit');
    await shot(tester, 'child_done_360x800');

    // 5. Centre: conduct, results, certificates (tablet-ish and phone).
    await pumpApp(tester,
        exams: exams,
        size: const Size(360, 800),
        home: const ExaminationCentre(initialChildId: 'kid'));
    await shot(tester, 'centre_conduct_360x800');
    await openTab(tester, 'tab_results');
    await shot(tester, 'centre_results_360x800');
    await openTab(tester, 'tab_certificates');
    await shot(tester, 'centre_certificates_360x800');
    await openTab(tester, 'tab_settings');
    await shot(tester, 'centre_settings_360x800');

    await pumpApp(tester,
        exams: exams,
        size: const Size(360, 800),
        home: const CertificateScreen(childId: 'kid', level: 1));
    await shot(tester, 'certificate_360x800');
    await pumpApp(tester,
        exams: exams,
        size: const Size(360, 800),
        home: ResultScreen(attemptId: a.id));
    await shot(tester, 'result_360x800');
  });
}
