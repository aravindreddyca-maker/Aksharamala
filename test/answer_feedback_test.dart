import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/lesson_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// When a child picks an answer they must be able to see, straight away,
/// whether it was right or wrong: colour, a tick or a cross, and words.
class _NoDiskStore extends LocalStore {
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

AppController _controller() {
  const profile = ChildProfile(id: 'p', name: 'Meena', age: 6, avatar: 'lion');
  return AppController(store: _NoDiskStore())
    ..profiles = [profile]
    ..progress = {'p': ProgressRecord.empty()}
    ..activeProfile = profile
    ..loaded = true;
}

Future<void> _open(WidgetTester tester, LearningWorld w, Lesson l) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(960, 540);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppScope(
      controller: _controller(),
      child: MaterialApp(
        theme: buildTheme(),
        home: LessonScreen(world: w, lesson: l),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Waits out the pause, then lets the pop-up finish appearing.
Future<void> _afterPause(WidgetTester tester) async {
  await tester.pump(feedbackPause);
  await tester.pumpAndSettle();
}

void main() {
  // These tests are about the pause itself, so it stays on.
  setUp(() => feedbackPause = defaultFeedbackPause);
  tearDown(() => feedbackPause = defaultFeedbackPause);

  final english = curriculum.firstWhere((w) => w.id == 'english');
  final textQuiz = english.lessons.firstWhere((l) => l.id == 'en-word');
  final pictureQuiz = english.lessons.firstWhere((l) => l.id == 'en-a');

  group('a text quiz (select, then Check Answer)', () {
    testWidgets('a wrong answer turns red with a cross, the right one green',
        (tester) async {
      await _open(tester, english, textQuiz);
      await tester.tap(find.byKey(const Key('answer_E')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('check_answer')));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      // The pop-up has not covered the answers yet.
      expect(find.byKey(const Key('result_again')), findsNothing);
      await _afterPause(tester);
      expect(find.byKey(const Key('result_again')), findsOneWidget);
    });

    testWidgets('a right answer turns green with a tick and says so',
        (tester) async {
      await _open(tester, english, textQuiz);
      await tester.tap(find.byKey(Key('answer_${textQuiz.answer}')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('check_answer')));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsNothing);
      expect(find.text('Great!'), findsOneWidget);
      await _afterPause(tester);
    });
  });

  group('a picture quiz (tap an answer)', () {
    testWidgets('a wrong tap shows a cross and the right tile, then the pop-up',
        (tester) async {
      await _open(tester, english, pictureQuiz);
      final wrong =
          pictureQuiz.options.firstWhere((o) => o != pictureQuiz.answer);
      await tester.tap(find.byKey(Key('answer_$wrong')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byKey(const Key('result_again')), findsNothing,
          reason: 'the child must see the tiles before the pop-up');
      await _afterPause(tester);
      expect(find.byKey(const Key('result_again')), findsOneWidget);
    });

    testWidgets('a right tap shows a tick', (tester) async {
      await _open(tester, english, pictureQuiz);
      await tester.tap(find.byKey(Key('answer_${pictureQuiz.answer}')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsNothing);
      await _afterPause(tester);
    });
  });
}
