import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/handwriting/letter_templates.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/result_text.dart';
import 'package:aksharamala/src/screens/lesson_navigation.dart';
import 'package:aksharamala/src/screens/lesson_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Store extends LocalStore {
  @override
  Future<LocalSnapshot> load() async =>
      const LocalSnapshot(profiles: [], progress: {});
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

Future<AppController> controller({int age = 5}) async {
  final c = AppController(store: _Store());
  await c.initialise();
  await c.addProfile('Kid', age, 'lion');
  return c;
}

/// A host page that opens [lesson] the way the lesson list does.
Future<void> openFromList(
  WidgetTester tester,
  AppController c,
  LearningWorld world,
  Lesson lesson,
) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(960, 540);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppScope(
      controller: c,
      child: MaterialApp(
        theme: buildTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('open'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => lessonScreenFor(c, world, lesson),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
}

/// A plain choose-the-answer quest (not tracing, story or counting).
bool isPlainQuiz(AppController c, Lesson l) =>
    c.planFor(l.id) == null &&
    l.kind != LessonKind.tracing &&
    l.kind != LessonKind.story &&
    l.options.length >= 2 &&
    l.pictures.isEmpty;

Future<void> answerRight(WidgetTester tester, Lesson l) async {
  await tester.tap(find.byKey(Key('answer_${l.answer}')));
  await tester.pump();
  final check = find.byKey(const Key('check_answer'));
  if (check.evaluate().isNotEmpty) {
    await tester.tap(check);
  }
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => feedbackPause = Duration.zero);
  tearDown(() => feedbackPause = defaultFeedbackPause);

  late AppController c;
  late LearningWorld world;
  late Lesson first;
  late Lesson second;

  setUp(() async {
    c = await controller();
    // Any world with two plain quizzes in a row at the child's level.
    outer:
    for (final w in c.worlds) {
      for (var i = 0; i + 1 < w.lessons.length; i++) {
        if (isPlainQuiz(c, w.lessons[i]) && isPlainQuiz(c, w.lessons[i + 1])) {
          world = w;
          first = w.lessons[i];
          second = w.lessons[i + 1];
          break outer;
        }
      }
    }
  });

  testWidgets('finishing a lesson offers Next Lesson as the main action',
      (tester) async {
    await openFromList(tester, c, world, first);
    await answerRight(tester, first);
    final next = find.byKey(const Key('result_next'));
    expect(next, findsOneWidget);
    expect(find.text('Next Lesson'), findsOneWidget);
    expect(find.byKey(const Key('result_back')), findsOneWidget);
    expect(find.text('Back to lessons'), findsOneWidget);
    // Next Lesson is the big primary button, above the others.
    final nextRect = tester.getRect(next);
    expect(nextRect.height, greaterThanOrEqualTo(56));
    expect(nextRect.top,
        lessThan(tester.getRect(find.byKey(const Key('result_back'))).top));
  });

  testWidgets('progress is saved before the next lesson opens', (tester) async {
    await openFromList(tester, c, world, first);
    await answerRight(tester, first);
    // Saved already, with the popup still on screen.
    expect(c.activeProgress.completedLessons, contains(first.id));
    expect(c.activeProfile!.stars, greaterThan(0));
    final stars = c.activeProfile!.stars;
    await tester.tap(find.byKey(const Key('result_next')));
    await tester.pumpAndSettle();
    // The next lesson is now on screen, with its own title.
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text(second.title), findsWidgets);
    expect(find.text(first.title), findsNothing);
    expect(c.activeProfile!.stars, stars, reason: 'opening costs nothing');
    expect(c.activeProgress.completedLessons, contains(first.id));
  });

  testWidgets('the next lesson is playable, and Back returns to the list',
      (tester) async {
    await openFromList(tester, c, world, first);
    await answerRight(tester, first);
    await tester.tap(find.byKey(const Key('result_next')));
    await tester.pumpAndSettle();
    await answerRight(tester, second);
    expect(
        c.activeProgress.completedLessons, containsAll([first.id, second.id]));
    await tester.tap(find.byKey(const Key('result_back')));
    await tester.pumpAndSettle();
    // Straight back to where the lessons were listed: one step, not two.
    expect(find.byKey(const Key('open')), findsOneWidget);
    expect(find.byType(LessonScreen), findsNothing);
  });

  testWidgets('the next lesson stays in the same world and level',
      (tester) async {
    final level = c.activeProfile!.level;
    for (final w in c.worlds) {
      for (final l in w.lessons) {
        final next = nextLessonAfter(c, w, l);
        if (next == null) continue;
        final at = w.lessons.indexWhere((x) => x.id == l.id);
        expect(w.lessons.map((x) => x.id), contains(next.id));
        expect(w.lessons.indexWhere((x) => x.id == next.id), greaterThan(at));
        expect(next.ageBands, contains(l.ageBands.first),
            reason: 'level $level: ${l.id} -> ${next.id}');
      }
    }
  });

  testWidgets('the last lesson offers no Next, only Back (and Play again)',
      (tester) async {
    final last = world.lessons.last;
    expect(nextLessonAfter(c, world, last), isNull);
    if (!isPlainQuiz(c, last)) return; // exercised by the popup test below
    await openFromList(tester, c, world, last);
    await answerRight(tester, last);
    expect(find.byKey(const Key('result_next')), findsNothing);
    expect(find.byKey(const Key('result_back')), findsOneWidget);
    expect(find.byKey(const Key('result_again')), findsOneWidget);
  });

  testWidgets('a wrong answer does not offer Next Lesson', (tester) async {
    await openFromList(tester, c, world, first);
    final wrong = first.options.firstWhere((o) => o != first.answer);
    await tester.tap(find.byKey(Key('answer_$wrong')));
    await tester.pump();
    final check = find.byKey(const Key('check_answer'));
    if (check.evaluate().isNotEmpty) await tester.tap(check);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('result_next')), findsNothing);
    expect(find.byKey(const Key('result_back')), findsOneWidget);
    expect(c.activeProgress.completedLessons, isNot(contains(first.id)));
  });

  testWidgets('tracing a letter right and pressing Check finishes the lesson',
      (tester) async {
    c = await controller(age: 3);
    final w = c.worlds.firstWhere((w) => w.id == 'english');
    final trace = w.lessons.firstWhere((l) => l.kind == LessonKind.tracing);
    final template = letterTemplates[trace.symbol]!;
    await openFromList(tester, c, w, trace);
    final rect = tester.getRect(find.byKey(const Key('trace_pad')));
    // The whole letter in ONE movement, then nothing else is pressed.
    final points = <Offset>[
      for (final s in template.strokes)
        for (var i = 0; i < s.length - 1; i++)
          for (var k = 0; k < 6; k++)
            Offset(
              rect.left + rect.width * (s[i].x + (s[i + 1].x - s[i].x) * k / 6),
              rect.top + rect.height * (s[i].y + (s[i + 1].y - s[i].y) * k / 6),
            ),
    ];
    final g = await tester.startGesture(points.first);
    for (final p in points.skip(1)) {
      await g.moveTo(p);
      await tester.pump();
    }
    await g.up();
    await tester.pumpAndSettle();
    // Drawing alone finishes nothing: the child presses Check.
    expect(c.activeProgress.completedLessons, isNot(contains(trace.id)));
    await tester.tap(find.byKey(const Key('write_check')));
    await tester.pumpAndSettle();
    expect(c.activeProgress.completedLessons, contains(trace.id));
    expect(find.byKey(const Key('result_back')), findsOneWidget);
  });

  testWidgets('a scribble does not finish a tracing lesson', (tester) async {
    c = await controller(age: 3);
    final w = c.worlds.firstWhere((w) => w.id == 'english');
    final trace = w.lessons.firstWhere((l) => l.kind == LessonKind.tracing);
    await openFromList(tester, c, w, trace);
    final rect = tester.getRect(find.byKey(const Key('trace_pad')));
    final g = await tester.startGesture(rect.topLeft + const Offset(20, 20));
    for (var k = 0; k < 40; k++) {
      await g.moveTo(Offset(rect.left + rect.width * (k.isEven ? .1 : .9),
          rect.top + rect.height * (.1 + k * .02)));
      await tester.pump();
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('result_back')), findsNothing);
    expect(c.activeProgress.completedLessons, isNot(contains(trace.id)));
  });

  group('the popup fits every screen with nothing scrolling', () {
    for (final withNext in [true, false]) {
      for (final correct in [true, false]) {
        testWidgets('next=$withNext correct=$correct', (tester) async {
          addTearDown(tester.view.reset);
          for (final size in const [
            Size(640, 360),
            Size(844, 390),
            Size(360, 640),
            Size(390, 844),
            Size(1280, 800),
            Size(800, 1280),
          ]) {
            tester.view
              ..devicePixelRatio = 1
              ..physicalSize = size;
            await tester.pumpWidget(MaterialApp(
              theme: buildTheme(),
              home: Scaffold(
                body: LessonResultDialog(
                  correct: correct,
                  text: ResultText.forLocale('en-IN'),
                  gained: 3,
                  onNext: withNext ? () {} : null,
                  onAgain: () {},
                  onBack: () {},
                ),
              ),
            ));
            await tester.pump();
            expect(tester.takeException(), isNull, reason: '$size');
            expect(find.byType(Scrollable), findsNothing, reason: '$size');
            for (final key in [
              if (withNext) 'result_next',
              'result_again',
              'result_back',
            ]) {
              final r = tester.getRect(find.byKey(Key(key)));
              expect(r.top, greaterThanOrEqualTo(0), reason: '$key $size');
              expect(r.bottom, lessThanOrEqualTo(size.height),
                  reason: '$key $size');
              expect(r.left, greaterThanOrEqualTo(0), reason: '$key $size');
              expect(r.right, lessThanOrEqualTo(size.width),
                  reason: '$key $size');
              expect(r.height, greaterThanOrEqualTo(44),
                  reason: '$key touch target $size');
            }
          }
        });
      }
    }
  });
}
