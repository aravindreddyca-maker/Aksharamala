import 'package:aksharamala/src/batch/batch_content.dart';
import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/handwriting/handwriting_policy.dart';
import 'package:aksharamala/src/handwriting/letter_templates.dart';
import 'package:aksharamala/src/handwriting/stroke_template.dart';
import 'package:aksharamala/src/widgets/writing_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pad sitting inside a scroll view, the worst case for gestures: a drag
/// that starts on the pad must draw, never scroll the page.
Future<List<WritingResult>> pumpPad(
  WidgetTester tester, {
  required String glyph,
  Size size = const Size(900, 500),
  bool inScrollView = true,
  double padHeight = 420,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  final results = <WritingResult>[];
  final pad = SizedBox(
    height: padHeight,
    child: WritingPad(
      glyph: glyph,
      mode: WriteMode.guided,
      text: BatchText.forGlyph('en-IN', glyph),
      color: Colors.indigo,
      template: letterTemplates[glyph],
      onResult: results.add,
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: inScrollView
            ? ListView(
                key: const Key('page'),
                children: [pad, const SizedBox(height: 2000)],
              )
            : pad,
      ),
    ),
  );
  return results;
}

/// Points of the template as screen positions on the pad.
List<List<Offset>> onScreen(WidgetTester tester, StrokeTemplate t) {
  final rect = tester.getRect(find.byKey(const Key('writing_pad')));
  return [
    for (final s in t.strokes)
      [
        for (var i = 0; i < s.length - 1; i++)
          for (var k = 0; k < 6; k++)
            Offset(
              rect.left + rect.width * (s[i].x + (s[i + 1].x - s[i].x) * k / 6),
              rect.top + rect.height * (s[i].y + (s[i + 1].y - s[i].y) * k / 6),
            ),
        Offset(rect.left + rect.width * s.last.x,
            rect.top + rect.height * s.last.y),
      ],
  ];
}

Future<void> drag(WidgetTester tester, List<Offset> pts) async {
  final g = await tester.startGesture(pts.first);
  for (final p in pts.skip(1)) {
    await g.moveTo(p);
    await tester.pump();
  }
  await g.up();
  await tester.pump();
}

void main() {
  testWidgets('a top-to-bottom drag on the pad draws and does not scroll',
      (tester) async {
    await pumpPad(tester, glyph: 'I');
    final rect = tester.getRect(find.byKey(const Key('writing_pad')));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    final x = rect.center.dx;
    await drag(tester, [
      for (var k = 0; k <= 30; k++)
        Offset(x, rect.top + rect.height * (.15 + .7 * k / 30)),
    ]);
    expect(scrollable.position.pixels, 0, reason: 'the page must not move');
    // And what was drawn is on the pad.
    final paint = find.descendant(
        of: find.byKey(const Key('writing_pad')),
        matching: find.byType(CustomPaint));
    expect(paint, findsWidgets);
  });

  testWidgets('horizontal and diagonal drags draw too', (tester) async {
    await pumpPad(tester, glyph: 'Z');
    final rect = tester.getRect(find.byKey(const Key('writing_pad')));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    await drag(tester, [
      for (var k = 0; k <= 20; k++)
        Offset(rect.left + rect.width * (.2 + .6 * k / 20),
            rect.top + rect.height * .2),
    ]);
    await drag(tester, [
      for (var k = 0; k <= 20; k++)
        Offset(rect.left + rect.width * (.8 - .6 * k / 20),
            rect.top + rect.height * (.2 + .6 * k / 20)),
    ]);
    expect(scrollable.position.pixels, 0);
    // Both movements stayed: Clear is now available.
    final clear =
        tester.widget<OutlinedButton>(find.byKey(const Key('write_clear')));
    expect(clear.onPressed, isNotNull);
  });

  testWidgets(
      'one continuous movement over the whole letter is accepted '
      'when Check is pressed', (tester) async {
    final results = await pumpPad(tester, glyph: 'E');
    final strokes = onScreen(tester, letterTemplates['E']!);
    // The finger never leaves the pad: every stroke joined into one path.
    await drag(tester, [for (final s in strokes) ...s]);
    // Nothing is accepted until the child presses Check.
    expect(results, isEmpty);
    await tester.tap(find.byKey(const Key('write_check')));
    await tester.pump();
    expect(results.last.shapeOk, isTrue);
    expect(find.byKey(const Key('trace_success')), findsOneWidget);
  });

  testWidgets('separate movements in any order are accepted too',
      (tester) async {
    final results = await pumpPad(tester, glyph: 'H');
    final strokes = onScreen(tester, letterTemplates['H']!);
    await drag(tester, strokes[1].reversed.toList());
    expect(results, isEmpty, reason: 'half a letter says nothing yet');
    await drag(tester, strokes[2]);
    await drag(tester, strokes[0].reversed.toList());
    expect(results, isEmpty, reason: 'no Check, no verdict');
    await tester.tap(find.byKey(const Key('write_check')));
    await tester.pump();
    expect(results.last.shapeOk, isTrue);
  });

  testWidgets('an unfinished letter is not accepted, and Check explains',
      (tester) async {
    final results = await pumpPad(tester, glyph: 'E');
    final strokes = onScreen(tester, letterTemplates['E']!);
    await drag(tester, strokes.first);
    expect(results, isEmpty);
    await tester.tap(find.byKey(const Key('write_check')));
    await tester.pump();
    expect(results.single.shapeOk, isFalse);
    expect(find.byKey(const Key('writing_message')), findsOneWidget);
    expect(find.byKey(const Key('trace_success')), findsOneWidget);
    final badge = tester.widget<AnimatedScale>(find.ancestor(
        of: find.byKey(const Key('trace_success')),
        matching: find.byType(AnimatedScale)));
    expect(badge.scale, 0, reason: 'no success badge for a wrong letter');
  });

  testWidgets('a scribble is rejected', (tester) async {
    final results = await pumpPad(tester, glyph: 'L');
    final rect = tester.getRect(find.byKey(const Key('writing_pad')));
    await drag(tester, [
      for (var k = 0; k < 40; k++)
        Offset(rect.left + rect.width * (k.isEven ? .1 : .9),
            rect.top + rect.height * (.1 + k * .02)),
    ]);
    await tester.tap(find.byKey(const Key('write_check')));
    await tester.pump();
    expect(results.every((r) => !r.shapeOk), isTrue);
  });

  testWidgets('the guide is hit-tested at the right place after a resize',
      (tester) async {
    // Draw in one size, then draw again in another: each is judged against
    // the pad it is on.
    for (final size in [const Size(900, 500), const Size(500, 900)]) {
      final results = await pumpPad(
        tester,
        glyph: 'L',
        size: size,
        inScrollView: false,
        padHeight: size.height - 40,
      );
      await tester.pumpAndSettle();
      final strokes = onScreen(tester, letterTemplates['L']!);
      await drag(tester, [for (final s in strokes) ...s]);
      await tester.tap(find.byKey(const Key('write_check')));
      await tester.pump();
      expect(results.last.shapeOk, isTrue, reason: '$size');
    }
  });

  group('the canvas takes the room', () {
    Future<double> side(WidgetTester tester, Size size) async {
      await pumpPad(tester,
          glyph: 'A',
          size: size,
          inScrollView: false,
          padHeight: size.height - 16);
      return tester.getSize(find.byKey(const Key('writing_pad'))).shortestSide;
    }

    testWidgets('phone landscape: nearly the full height', (tester) async {
      final s = await side(tester, const Size(780, 360));
      expect(s, greaterThan(300));
    });

    testWidgets('tablet landscape: well over 500', (tester) async {
      final s = await side(tester, const Size(1280, 800));
      expect(s, greaterThan(700));
    });

    testWidgets('phone portrait: nearly the full width', (tester) async {
      final s = await side(tester, const Size(360, 780));
      expect(s, greaterThan(300));
    });

    testWidgets('Clear and Check stay on screen in every shape',
        (tester) async {
      for (final size in const [
        Size(780, 360),
        Size(1280, 800),
        Size(360, 780),
        Size(800, 1280),
      ]) {
        await pumpPad(tester,
            glyph: 'A',
            size: size,
            inScrollView: false,
            padHeight: size.height - 16);
        for (final key in ['write_clear', 'write_check']) {
          final r = tester.getRect(find.byKey(Key(key)));
          expect(r.top, greaterThanOrEqualTo(0), reason: '$key $size');
          expect(r.bottom, lessThanOrEqualTo(size.height),
              reason: '$key $size');
          expect(r.right, lessThanOrEqualTo(size.width), reason: '$key $size');
          expect(r.height, greaterThanOrEqualTo(44), reason: '$key $size');
        }
      }
    });
  });
}
