import 'dart:io';

import 'package:aksharamala/src/exam/exam_controller.dart';
import 'package:aksharamala/src/screens/exam/examination_centre.dart';
import 'package:aksharamala/src/screens/home_screen.dart';
import 'package:aksharamala/src/screens/parent_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_helpers.dart';

void main() {
  late MemoryExamStore store;
  late ExamController exams;

  setUp(() {
    store = MemoryExamStore();
    exams = examController(store, uiBank());
  });

  testWidgets('parent dashboard has the Examination Centre button and opens it',
      (
    tester,
  ) async {
    await pumpApp(tester, exams: exams, home: const ParentDashboard());
    expect(find.text('Examination Centre'), findsOneWidget);
    await tapKey(tester, 'open_exam_centre');
    expect(find.byKey(const Key('tab_conduct')), findsOneWidget);
    expect(find.byKey(const Key('tab_results')), findsOneWidget);
    expect(find.byKey(const Key('tab_history')), findsOneWidget);
    expect(find.byKey(const Key('tab_certificates')), findsOneWidget);
    expect(find.byKey(const Key('tab_settings')), findsOneWidget);
  });

  testWidgets('a PIN is asked for before the centre opens', (tester) async {
    await real(() => exams.setPin('kid', '4321'));
    await pumpApp(tester, exams: exams, home: const ParentDashboard());
    await tapKey(tester, 'open_exam_centre');
    expect(find.byKey(const Key('pin_current')), findsOneWidget);
    expect(find.byKey(const Key('tab_conduct')), findsNothing);

    // Wrong PIN: stays locked.
    await tester.enterText(find.byKey(const Key('pin_current')), '1111');
    await tapKey(tester, 'pin_ok');
    expect(find.byKey(const Key('pin_error')), findsOneWidget);
    expect(find.byKey(const Key('tab_conduct')), findsNothing);

    // Cancel: stays locked.
    await tapKey(tester, 'pin_cancel');
    expect(find.byKey(const Key('tab_conduct')), findsNothing);

    // Right PIN: opens.
    await tapKey(tester, 'open_exam_centre');
    await tester.enterText(find.byKey(const Key('pin_current')), '4321');
    await tapKey(tester, 'pin_ok');
    expect(find.byKey(const Key('tab_conduct')), findsOneWidget);
  });

  testWidgets('switching to a child with a PIN asks for that PIN',
      (tester) async {
    await real(() => exams.setPin('sib', '2468'));
    await pumpApp(
      tester,
      exams: exams,
      app: appController(profiles: [kid, sibling]),
      home: const ExaminationCentre(initialChildId: 'kid'),
    );
    await tester.tap(find.byKey(const Key('exam_child')));
    await settle(tester);
    await tester.tap(find.textContaining('Ravi').last);
    await settle(tester);
    expect(find.byKey(const Key('pin_current')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('pin_current')), '0000');
    await tapKey(tester, 'pin_ok');
    // Still showing Asha's data, not Ravi's.
    expect(find.textContaining('Ravi'), findsNothing);
  });

  testWidgets('the normal child app shows no exam entry', (tester) async {
    await pumpApp(tester, exams: exams, home: const HomeScreen());
    expect(find.textContaining('Examination'), findsNothing);
    expect(find.byKey(const Key('open_exam_centre')), findsNothing);
  });

  test('no child-facing screen can reach the Examination Centre', () {
    // Only the parent dashboard, the app scope and the exam folder itself may
    // mention the centre, the exam screens or the exam controller.
    final allowed = {
      'parent_dashboard.dart',
      'app.dart',
    };
    final offenders = <String>[];
    for (final f in Directory('lib/src').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final path = f.path.replaceAll('\\', '/');
      if (path.contains('/screens/exam/') || path.contains('/lib/src/exam/')) {
        continue;
      }
      if (path.startsWith('lib/src/exam/') ||
          path.startsWith('lib/src/screens/exam/')) {
        continue;
      }
      final name = path.split('/').last;
      final text = f.readAsStringSync();
      final touches = text.contains('screens/exam/') ||
          text.contains('exam/exam_controller') ||
          text.contains('ExaminationCentre') ||
          text.contains('ChildExamScreen');
      if (touches && !allowed.contains(name)) offenders.add(path);
    }
    expect(offenders, isEmpty);
  });
}
