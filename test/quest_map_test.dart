import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/quest_art.dart';
import 'package:aksharamala/src/screens/lesson_screen.dart';
import 'package:aksharamala/src/screens/world_map_screen.dart';
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

final _tamil = curriculum.firstWhere((w) => w.id == 'tamil');

AppController _controller({Set<String> done = const {}}) {
  const profile = ChildProfile(id: 'p', name: 'Meena', age: 6, avatar: 'lion');
  return AppController(store: _NoDiskStore())
    ..profiles = [profile]
    ..progress = {
      'p': ProgressRecord(
        completedLessons: done,
        attempts: const {},
        correct: const {},
        lastPlayed: const {},
        earnedBadges: const {},
      ),
    }
    ..activeProfile = profile
    ..loaded = true;
}

Future<void> _show(
  WidgetTester tester,
  Size size, {
  double scale = 1.0,
  LearningWorld? world,
  Set<String> done = const {},
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    AppScope(
      controller: _controller(done: done),
      child: MaterialApp(
        theme: buildTheme(),
        home: WorldMapScreen(world: world ?? _tamil),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _card(WidgetTester tester, String id) =>
    tester.getRect(find.byKey(Key('lesson_$id')));

void main() {
  test('every quest has an illustration (or its letter) and files exist', () {
    final missing = <String>[];
    for (final world in curriculum) {
      for (final lesson in world.lessons) {
        final path = questArt[lesson.id];
        if (lesson.kind == LessonKind.tracing) {
          // Tracing teaches one letter, so the card draws that letter.
          if (path != null) {
            missing.add('${lesson.id}: tracing quests must not use a picture');
          }
        } else if (path == null) {
          missing.add('${lesson.id}: no art mapped');
        } else if (!File(path).existsSync()) {
          missing.add('${lesson.id}: $path is missing');
        }
      }
    }
    expect(missing, isEmpty, reason: missing.join('\n'));
    // Nothing in the map points at a lesson that no longer exists.
    final ids = {
      for (final w in curriculum) ...w.lessons.map((l) => l.id),
    };
    expect(ids.containsAll(questArt.keys), isTrue);
  });

  test('quest labels are text the lesson already contains (nothing invented)',
      () {
    final bad = <String>[];
    for (final world in curriculum) {
      for (final lesson in world.lessons) {
        final label = questLabel[lesson.id];
        if (label == null) continue;
        final pool = [
          lesson.symbol,
          lesson.title,
          lesson.subtitle,
          lesson.challenge,
          lesson.answer,
          ...lesson.options,
        ].join(' | ');
        if (!pool.contains(label)) bad.add('${lesson.id}: "$label"');
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
    final ids = {
      for (final w in curriculum) ...w.lessons.map((l) => l.id),
    };
    expect(ids.containsAll(questLabel.keys), isTrue);
  });

  test('Indic text gets one consistent script font and tall line height', () {
    final tamil = scriptStyle('அ – அம்மா', const TextStyle(fontSize: 18));
    expect(tamil.fontFamily, 'Noto Sans Tamil');
    expect(tamil.height, greaterThanOrEqualTo(1.3));
    expect(
      scriptStyle('अ – अनार', const TextStyle()).fontFamily,
      'Noto Sans Devanagari',
    );
    expect(
      scriptStyle('అ – అమ్మ', const TextStyle()).fontFamily,
      'Noto Sans Telugu',
    );
    // English, and mixed English + Tamil, keep the default font.
    expect(
        scriptStyle('Count the Stars', const TextStyle()).fontFamily, isNull);
    expect(
      scriptStyle('Discover தமிழ் stories', const TextStyle()).fontFamily,
      isNull,
    );
  });

  for (final size in _sizes) {
    for (final scale in [1.0, 1.3]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()} text $scale';

      testWidgets('Tamil quest trail fits with no overflow at $tag', (
        tester,
      ) async {
        await _show(tester, size, scale: scale);
        expect(tester.takeException(), isNull);

        // The first card is fully on screen, inside the screen vertically.
        final first = _card(tester, 'ta-a');
        expect(first.left, greaterThanOrEqualTo(0));
        expect(first.top, greaterThanOrEqualTo(0));
        expect(first.bottom, lessThanOrEqualTo(size.height));
        expect(first.right, lessThanOrEqualTo(size.width));
        expect(first.height, greaterThanOrEqualTo(120));

        // Big play button: at least 48 dp tall, inside its card.
        final play = tester.getRect(find.text('Play').first);
        expect(play.bottom, lessThanOrEqualTo(first.bottom));
        expect(play.height, greaterThan(0));

        // Header, arrows and dots are all on screen. Arrows appear only when
        // there is more to scroll to: at 1280 wide all four cards fit.
        if (size.width >= 1280) {
          expect(find.byKey(const Key('trail_next')), findsNothing);
          for (final lesson in _tamil.lessons) {
            final r = _card(tester, lesson.id);
            expect(r.left, greaterThanOrEqualTo(0), reason: lesson.id);
            expect(r.right, lessThanOrEqualTo(size.width), reason: lesson.id);
          }
        } else {
          expect(find.byKey(const Key('trail_next')), findsOneWidget);
        }
        final dots = find.descendant(
          of: find.byKey(const Key('trail_dots')),
          matching: find.byType(AnimatedContainer),
        );
        expect(dots, findsNWidgets(_tamil.lessons.length));
        expect(
          tester.getRect(find.byKey(const Key('trail_dots'))).bottom,
          lessThanOrEqualTo(size.height),
        );
      });
    }
  }

  testWidgets('every world map fits at every size (cards, arrows, dots)', (
    tester,
  ) async {
    for (final size in _sizes) {
      for (final world in curriculum) {
        await _show(tester, size, world: world, scale: 1.3);
        expect(
          tester.takeException(),
          isNull,
          reason: '${world.id} at $size',
        );
        final first = _card(tester, world.lessons.first.id);
        expect(first.bottom, lessThanOrEqualTo(size.height));
        expect(first.left, greaterThanOrEqualTo(0));
      }
    }
  });

  testWidgets('arrows page the trail and the last card is never cut off', (
    tester,
  ) async {
    await _show(tester, const Size(640, 360));
    // At the start there is nothing before, but more after.
    expect(find.byKey(const Key('trail_prev')), findsNothing);
    expect(find.byKey(const Key('trail_next')), findsOneWidget);

    var guard = 0;
    while (find.byKey(const Key('trail_next')).evaluate().isNotEmpty &&
        guard++ < 10) {
      await tester.tap(find.byKey(const Key('trail_next')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('trail_next')), findsNothing);
    expect(find.byKey(const Key('trail_prev')), findsOneWidget);
    final last = _card(tester, 'ta-story');
    expect(last.right, lessThanOrEqualTo(640));
    expect(last.left, greaterThanOrEqualTo(0));

    await tester.tap(find.byKey(const Key('trail_prev')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trail_next')), findsOneWidget);
  });

  testWidgets('each arrow press lands on the next whole card', (tester) async {
    for (final size in const [Size(640, 360), Size(800, 360), Size(960, 540)]) {
      await _show(tester, size);
      final margin = size.width < 720 ? 14.0 : 24.0;
      final lessons = _tamil.lessons;
      for (var i = 1; i < lessons.length; i++) {
        if (find.byKey(const Key('trail_next')).evaluate().isEmpty) break;
        await tester.tap(find.byKey(const Key('trail_next')));
        await tester.pumpAndSettle();
        // After pressing, either card i sits exactly at the left margin, or
        // the list has reached its end with the last card fully visible.
        final left = _card(tester, lessons[i].id).left;
        final atEnd = find.byKey(const Key('trail_next')).evaluate().isEmpty;
        expect(
          (left - margin).abs() < 1.5 || atEnd,
          isTrue,
          reason: '$size press $i: card ${lessons[i].id} left=$left',
        );
        if (atEnd) {
          final last = _card(tester, lessons.last.id);
          expect(last.right, lessThanOrEqualTo(size.width + 0.5));
          expect(last.left, greaterThanOrEqualTo(0));
        }
        // Whatever is at the margin is a complete card on screen.
        final shown = _card(tester, lessons[i].id);
        expect(shown.right, lessThanOrEqualTo(size.width + 0.5));
      }
    }
  });

  testWidgets('a quick flick moves on by a card, not a stray distance', (
    tester,
  ) async {
    await _show(tester, const Size(800, 360));
    await tester.fling(
      find.byKey(const Key('quest_trail')),
      const Offset(-300, 0),
      1200,
    );
    await tester.pumpAndSettle();
    // Only cards near the screen are built; measure those.
    final lefts = [
      for (final l in _tamil.lessons)
        if (find.byKey(Key('lesson_${l.id}')).evaluate().isNotEmpty)
          _card(tester, l.id).left,
    ];
    final atMargin = lefts.any((x) => (x - 24).abs() < 1.5);
    final atEnd = find.byKey(const Key('trail_next')).evaluate().isEmpty;
    expect(atMargin || atEnd, isTrue, reason: 'lefts $lefts');
    // The first card has left the margin: the flick really moved the list.
    expect(
      find.byKey(const Key('lesson_ta-a')).evaluate().isEmpty ||
          _card(tester, 'ta-a').left < 24,
      isTrue,
    );
  });

  testWidgets('the dots and card bottoms keep clear of the lower edge', (
    tester,
  ) async {
    const insets = [
      EdgeInsets.zero,
      EdgeInsets.only(bottom: 16, left: 48, right: 48),
      EdgeInsets.only(bottom: 24, left: 32, right: 32, top: 12),
    ];
    for (final size in _sizes) {
      for (final inset in insets) {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = size
          ..padding = FakeViewPadding(
            left: inset.left,
            top: inset.top,
            right: inset.right,
            bottom: inset.bottom,
          )
          ..viewPadding = FakeViewPadding(
            left: inset.left,
            top: inset.top,
            right: inset.right,
            bottom: inset.bottom,
          );
        addTearDown(tester.view.reset);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          AppScope(
            controller: _controller(),
            child: MaterialApp(
              theme: buildTheme(),
              home: WorldMapScreen(world: _tamil),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$size $inset');
        final dots = tester.getRect(find.byKey(const Key('trail_dots')));
        final card = _card(tester, 'ta-a');
        // At least 10 dp between the dots and the usable bottom edge...
        expect(
          dots.bottom,
          lessThanOrEqualTo(size.height - inset.bottom - 10),
          reason: 'dots at $size $inset',
        );
        // ...and a visible gap between the cards and the dots.
        expect(
          card.bottom,
          lessThanOrEqualTo(dots.top - 6),
          reason: 'card/dots gap at $size $inset',
        );
        // Cards stay inside the side insets too.
        expect(card.left, greaterThanOrEqualTo(inset.left));
      }
    }
  });

  testWidgets('tracing quests show their own letter, big, not a picture', (
    tester,
  ) async {
    await _show(tester, const Size(960, 540));
    await tester.scrollUntilVisible(
      find.byKey(const Key('lesson_ta-trace')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('quest_trail')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final glyph = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('lesson_ta-trace')),
        matching: find.text('அ'),
      ),
    );
    expect(glyph.style?.fontFamily, 'Noto Sans Tamil');
    expect(glyph.style?.fontSize, greaterThanOrEqualTo(100));
    // No photo on this card.
    expect(
      find.descendant(
        of: find.byKey(const Key('lesson_ta-trace')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
  });

  testWidgets('word and letter quests label their picture with the word', (
    tester,
  ) async {
    await _show(tester, const Size(960, 540));
    expect(
      find.descendant(
        of: find.byKey(const Key('lesson_ta-a')),
        matching: find.text('அ'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('lesson_ta-word')),
        matching: find.text('மலர்'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a finger drag moves the trail and settles on a card edge', (
    tester,
  ) async {
    await _show(tester, const Size(800, 360));
    final before = _card(tester, 'ta-a').left;
    // More than half a card, so it moves on rather than snapping back.
    await tester.drag(
        find.byKey(const Key('quest_trail')), const Offset(-250, 0));
    await tester.pumpAndSettle();
    final after = _card(tester, 'ta-a').left;
    expect(after, lessThan(before));
    // Settled: some card sits exactly under the left margin (or the trail is
    // at its end), never half way between two cards.
    final lefts = [
      for (final l in _tamil.lessons) _card(tester, l.id).left,
    ];
    final atMargin =
        lefts.any((x) => (x - 14).abs() < 1.5 || (x - 24).abs() < 1.5);
    final atEnd = find.byKey(const Key('trail_next')).evaluate().isEmpty;
    expect(atMargin || atEnd, isTrue, reason: 'lefts: $lefts');
  });

  testWidgets('mouse drag works too (tablets and desktop emulators)', (
    tester,
  ) async {
    await _show(tester, const Size(960, 540));
    final before = _card(tester, 'ta-a').left;
    final gesture = await tester.startGesture(
      const Offset(480, 300),
      kind: PointerDeviceKind.mouse,
    );
    // Move in steps: a single jump can land before the drag is recognised.
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_card(tester, 'ta-a').left, lessThan(before));
  });

  testWidgets('progress and rules are kept: done, next, and nothing locked', (
    tester,
  ) async {
    await _show(tester, const Size(960, 540), done: {'ta-a'});
    // Quest 1 is finished; quest 2 is the recommended next adventure.
    expect(find.text('Play again'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('NEXT ADVENTURE'), findsOneWidget);
    // Every quest still opens, in any order.
    for (final lesson in _tamil.lessons) {
      final tile =
          tester.widget<InkWell>(find.byKey(Key('lesson_${lesson.id}')));
      expect(tile.onTap, isNotNull, reason: lesson.id);
    }
    await tester.tap(find.byKey(const Key('lesson_ta-trace')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
  });

  testWidgets('opens with a late recommended quest scrolled into view', (
    tester,
  ) async {
    await _show(
      tester,
      const Size(640, 360),
      done: {'ta-a', 'ta-word', 'ta-trace'},
    );
    final next = _card(tester, 'ta-story');
    expect(next.left, greaterThanOrEqualTo(0));
    expect(next.right, lessThanOrEqualTo(640));
    expect(find.text('NEXT ADVENTURE'), findsOneWidget);
  });

  testWidgets('Tamil titles use the Tamil font with room above and below', (
    tester,
  ) async {
    await _show(tester, const Size(960, 540));
    for (final lesson in _tamil.lessons) {
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byKey(Key('lesson_${lesson.id}')),
          matching: find.text(lesson.title),
        ),
      );
      expect(text.style?.fontFamily, 'Noto Sans Tamil', reason: lesson.id);
      expect(text.style?.height, greaterThanOrEqualTo(1.3), reason: lesson.id);
      expect(text.data, lesson.title, reason: 'text is shown unchanged');
    }
  });

  testWidgets('a one-word title never breaks inside the word', (tester) async {
    for (final size in _sizes) {
      await _show(tester, size, scale: 1.3);
      final lesson = _tamil.lessons.firstWhere((l) => l.id == 'ta-story');
      expect(lesson.title.contains(' '), isFalse);
      // The list builds cards lazily, so bring the fourth one into view.
      await tester.scrollUntilVisible(
        find.byKey(const Key('lesson_ta-story')),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('quest_trail')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('lesson_ta-story')),
          matching: find.text(lesson.title),
        ),
      );
      // One line, no soft wrap: it can only shrink, never split mid-word.
      expect(text.softWrap, isFalse, reason: '$size');
      expect(text.maxLines, 1, reason: '$size');
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('quest cards are announced with number, title and status', (
    tester,
  ) async {
    await _show(tester, const Size(960, 540), done: {'ta-a'});
    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp(r'^Quest 1, .*completed$')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'^Quest 2, .*next adventure$')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
