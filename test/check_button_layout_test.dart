import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/lesson_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoDiskStore extends LocalStore {
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

const _sizes = <Size>[
  Size(640, 360),
  Size(800, 360),
  Size(960, 540),
  Size(1280, 800),
];

/// Every quiz that uses select-then-Check Answer: text-only, not maths.
final _checkQuizzes = <({LearningWorld world, Lesson lesson})>[
  for (final w in curriculum)
    for (final l in w.lessons)
      if (l.options.isNotEmpty &&
          l.pictures.isEmpty &&
          l.kind != LessonKind.tracing &&
          !(w.id == 'numbers' && l.id != 'num-names'))
        (world: w, lesson: l),
];

Future<void> _open(
  WidgetTester tester,
  ({LearningWorld world, Lesson lesson}) row,
  Size size,
  double scale,
) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  const profile = ChildProfile(id: 'p', name: 'A', age: 6, avatar: 'lion');
  final controller = AppController(store: _NoDiskStore())
    ..profiles = [profile]
    ..progress = {'p': ProgressRecord.empty()}
    ..activeProfile = profile
    ..loaded = true;
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    AppScope(
      controller: controller,
      child: MaterialApp(
        theme: buildTheme(),
        home: LessonScreen(world: row.world, lesson: row.lesson),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Stories read their pages first; the question comes after.
  if (row.lesson.kind == LessonKind.story) {
    for (var i = 0; i < row.lesson.story.length; i++) {
      final next = find.byType(FilledButton).last;
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  test('the quizzes under test are the text-only ones', () {
    expect(
      _checkQuizzes.map((r) => r.lesson.id).toSet(),
      {'en-word', 'hi-word', 'te-story', 'ta-story', 'num-names'},
    );
  });

  for (final size in _sizes) {
    for (final scale in [1.0, 1.3, 1.6]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()} text $scale';

      testWidgets('Check Answer is on screen with no scrolling at $tag', (
        tester,
      ) async {
        for (final row in _checkQuizzes) {
          await _open(tester, row, size, scale);
          expect(tester.takeException(), isNull, reason: row.lesson.id);
          final check = tester.getRect(find.byKey(const Key('check_answer')));
          expect(check.top, greaterThanOrEqualTo(0), reason: row.lesson.id);
          expect(
            check.bottom,
            lessThanOrEqualTo(size.height),
            reason: '${row.lesson.id} Check Answer bottom ${check.bottom}',
          );
          expect(check.height, greaterThanOrEqualTo(44), reason: row.lesson.id);
          expect(check.right, lessThanOrEqualTo(size.width));
        }
      });

      testWidgets('every answer can be reached and tapped at $tag', (
        tester,
      ) async {
        for (final row in _checkQuizzes) {
          for (final option in row.lesson.options) {
            await _open(tester, row, size, scale);
            final chip = find.byKey(Key('answer_$option'));
            // Reachable: scrolling the list brings it fully into view.
            await tester.ensureVisible(chip);
            await tester.pumpAndSettle();
            final rect = tester.getRect(chip);
            final check = tester.getRect(find.byKey(const Key('check_answer')));
            expect(rect.top, greaterThanOrEqualTo(0), reason: option);
            expect(
              rect.bottom,
              lessThanOrEqualTo(check.top + 0.5),
              reason: '${row.lesson.id} "$option" hides behind Check Answer',
            );
            expect(rect.height, greaterThanOrEqualTo(44), reason: option);
            await tester.tap(chip);
            await tester.pumpAndSettle();
            final button = tester.widget<FilledButton>(
              find.byKey(const Key('check_answer')),
            );
            expect(button.onPressed, isNotNull,
                reason: '${row.lesson.id} "$option" did not select');
          }
        }
      });
    }

    testWidgets(
      'at normal text size all answers are visible without scrolling at '
      '${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        for (final row in _checkQuizzes) {
          await _open(tester, row, size, 1.0);
          final check = tester.getRect(find.byKey(const Key('check_answer')));
          for (final option in row.lesson.options) {
            final rect = tester.getRect(find.byKey(Key('answer_$option')));
            expect(
              rect.bottom,
              lessThanOrEqualTo(check.top + 0.5),
              reason: '${row.lesson.id} "$option" needs scrolling',
            );
            expect(rect.top, greaterThanOrEqualTo(0));
          }
        }
      },
    );
  }

  testWidgets('selecting then checking still scores right and wrong', (
    tester,
  ) async {
    for (final row in _checkQuizzes) {
      for (final correct in [true, false]) {
        await _open(tester, row, const Size(800, 360), 1.0);
        final option = correct
            ? row.lesson.answer
            : row.lesson.options.firstWhere((o) => o != row.lesson.answer);
        await tester.tap(find.byKey(Key('answer_$option')));
        await tester.pumpAndSettle();
        // No scrolling needed: tap the button exactly where it is drawn.
        await tester.tap(find.byKey(const Key('check_answer')));
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(correct ? 'Wonderful!' : 'Good try!'),
          findsOneWidget,
          reason: '${row.lesson.id} ${correct ? 'right' : 'wrong'}',
        );
      }
    }
  });

  testWidgets('portrait (stacked) layout keeps working', (tester) async {
    for (final row in _checkQuizzes) {
      await _open(tester, row, const Size(411, 800), 1.0);
      expect(tester.takeException(), isNull, reason: row.lesson.id);
      await tester.ensureVisible(find.byKey(const Key('check_answer')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('check_answer')), findsOneWidget);
    }
  });
}
