import 'dart:convert';
import 'dart:io';

import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/teaching/teaching_plan.dart';
import 'package:aksharamala/src/teaching/teaching_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _minus = '−';

TeachingVisual _obj(
  List<int> counts,
  String op, {
  int? reveal,
  bool countAll = false,
  bool showResult = false,
  int? result,
  int takeAway = 0,
  List<String> labels = const [],
}) =>
    TeachingVisual(
      type: VisualType.objects,
      groups: [for (final c in counts) ObjectGroup(emoji: '⭐', count: c)],
      operator: op,
      revealCount: reveal,
      countAll: countAll,
      showResult: showResult,
      result: result,
      takeAway: takeAway,
      labels: labels,
    );

TeachingVisual _line(int start, int jump,
        {bool hops = true, int from = 0, int to = 10}) =>
    TeachingVisual(
      type: VisualType.numberLine,
      from: from,
      to: to,
      start: start,
      jump: jump,
      showHops: hops,
    );

Future<void> _show(WidgetTester t, TeachingVisual v,
    {Size size = const Size(400, 400), double scale = 1.0}) async {
  t.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearAllTestValues);
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(child: TeachingVisualView(visual: v)),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Map<String, dynamic> _plan({Map<String, dynamic>? visual}) {
  final root = jsonDecode(pilotJson()) as Map<String, dynamic>;
  final l = Map<String, dynamic>.from(
    jsonDecode(jsonEncode((root['lessons'] as List).last)) as Map,
  );
  if (visual != null) (l['demonstrate'] as List).first['visual'] = visual;
  return l;
}

TeachingPlanLibrary _lib(Map<String, dynamic> lesson) =>
    TeachingPlanLibrary.parse([
      jsonEncode({
        'schema_version': 1,
        'status': 't',
        'lessons': [lesson],
      }),
    ]);

void main() {
  group('validation', () {
    Map<String, dynamic> objects(String op, int groups, {int count = 3}) => {
          'type': 'objects',
          'groups': [
            for (var i = 0; i < groups; i++) {'emoji': 'x', 'count': count},
          ],
          'operator': op,
          'revealCount': groups,
          'countAll': false,
        };

    List<String> issues(Map<String, dynamic> visual) =>
        _lib(_plan(visual: visual)).issues;

    test('+, vs, and - with one group are accepted', () {
      expect(issues(objects('+', 2)), isEmpty);
      expect(issues(objects('vs', 2)), isEmpty);
      for (final op in ['-', _minus]) {
        expect(issues(objects(op, 1, count: 9)..['takeAway'] = 4), isEmpty,
            reason: op);
      }
    });

    test('other operators are refused', () {
      expect(issues(objects('x', 2)).join(), contains('operator "x"'));
      expect(_lib(_plan(visual: objects('*', 2))).planFor('num-add'), isNull);
    });

    test('subtraction is ONE group with takeAway', () {
      expect(issues(objects('-', 2)).join(), contains('ONE group'));
      expect(issues(objects(_minus, 2)).join(), contains('ONE group'));
      expect(issues(objects('-', 1, count: 5)..['takeAway'] = 6).join(),
          contains('takeAway 6'));
      expect(issues(objects('-', 1, count: 5)..['takeAway'] = -1).join(),
          contains('takeAway -1'));
      expect(issues(objects('+', 1)..['takeAway'] = 1).join(),
          contains('needs operator'));
    });

    test('vs needs two groups and, if given, two non-empty labels', () {
      expect(issues(objects('vs', 1)).join(), contains('exactly two groups'));
      expect(
          issues(objects('vs', 2)..['labels'] = ['Pencil', 'Rubber']), isEmpty);
      expect(issues(objects('vs', 2)..['labels'] = ['Pencil']).join(),
          contains('two non-empty'));
      expect(issues(objects('vs', 2)..['labels'] = ['Pencil', ' ']).join(),
          contains('two non-empty'));
    });

    test('objects are capped at 20 in all', () {
      expect(issues(objects('+', 2, count: 10)), isEmpty);
      expect(issues(objects('+', 2, count: 11)).join(), contains('22 objects'));
      expect(issues(objects('+', 10)).join(), contains('30 objects'));
      expect(issues(objects('-', 1, count: 21)).join(), contains('21 objects'));
    });

    test('revealCount is within the groups', () {
      final bad = objects('+', 2)..['revealCount'] = 5;
      expect(issues(bad).join(), contains('revealCount'));
    });

    test('baseTen: 0-9 tens and 0-9 ones', () {
      Map<String, dynamic> bt(int t, int o) =>
          {'type': 'baseTen', 'tens': t, 'ones': o, 'showTotal': false};
      expect(issues(bt(9, 9)), isEmpty);
      expect(issues(bt(0, 0)), isEmpty);
      expect(issues(bt(10, 0)).join(), contains('baseTen'));
      expect(issues(bt(2, 10)).join(), contains('baseTen'));
      expect(issues(bt(-1, 3)).join(), contains('baseTen'));
    });

    test('number line: negative and zero jumps are fine, off-line is not', () {
      Map<String, dynamic> nl(int start, int jump) => {
            'type': 'numberLine',
            'from': 0,
            'to': 10,
            'start': start,
            'jump': jump,
            'showHops': true,
          };
      expect(issues(nl(7, -3)), isEmpty);
      expect(issues(nl(4, 0)), isEmpty);
      expect(issues(nl(2, -3)).join(), contains('off the line'));
      expect(issues(nl(12, 0)).join(), contains('off the line'));
      expect(issues(nl(2, -3)..['showHops'] = false), isEmpty);
    });
  });

  group('the real rollout files', () {
    // The numbers file is being regenerated for the one-group subtraction and
    // the 20-object cap; until then only those two kinds of issue are
    // tolerated here (and counted in the printout).
    bool legacy(String issue) =>
        issue.contains('ONE group') || issue.contains('is more than 20');

    for (final name in ['rollout_numbers', 'rollout_letters']) {
      final file = File('content/teaching_pending/$name.json');
      test('$name.json loads through the plan parser', () {
        final text = file.readAsStringSync();
        final sw = Stopwatch()..start();
        final lib = TeachingPlanLibrary.parse([text]);
        final all = lib.plansById;
        final issues = lib.issues;
        sw.stop();
        final old = issues.where(legacy).length;
        // ignore: avoid_print
        print('$name.json: ${text.length} bytes, ${all.length} plans valid, '
            '${issues.length} issues ($old legacy-shape), '
            '${sw.elapsedMilliseconds} ms to index and validate everything');
        if (name == 'rollout_letters') {
          expect(issues, isEmpty);
          expect(all, hasLength(149));
        } else {
          expect(issues.where((i) => !legacy(i)), isEmpty);
        }
      }, skip: file.existsSync() ? false : '$name.json is absent');
    }

    test('indexing is cheap and a lesson is decoded only when asked for', () {
      final file = File('content/teaching_pending/rollout_letters.json');
      final text = file.readAsStringSync();
      final sw = Stopwatch()..start();
      final lib = TeachingPlanLibrary.fromIndex(indexPlanFiles([text]));
      final indexed = sw.elapsedMilliseconds;
      sw
        ..reset()
        ..start();
      final id = lib.lessonIds.first;
      final plan = lib.planFor(id);
      final one = sw.elapsedMilliseconds;
      // ignore: avoid_print
      print('letters ${text.length} bytes: index $indexed ms, first lesson '
          'decode+validate $one ms');
      expect(plan, isNotNull);
      expect(lib.hasPlan(id), isTrue);
    },
        skip: File('content/teaching_pending/rollout_letters.json').existsSync()
            ? false
            : 'rollout_letters.json is absent');
  });

  group('lazy library', () {
    test('planFor decodes once, keeps the plan, reports a bad one', () {
      final good = _plan();
      final bad = _plan()..['lesson_id'] = 'bad-one';
      (bad['guided'] as List).first['answer'] = 'ZZZ';
      final text = jsonEncode({
        'schema_version': 1,
        'status': 's',
        'lessons': [good, bad],
      });
      final lib = TeachingPlanLibrary.fromIndex(indexPlanFiles([text]));
      expect(lib.hasPlan('bad-one'), isTrue, reason: 'not validated yet');
      final a = lib.planFor('num-add');
      expect(a, isNotNull);
      expect(identical(a, lib.planFor('num-add')), isTrue);
      expect(a!.status, 's');
      expect(lib.planFor('bad-one'), isNull);
      expect(lib.hasPlan('bad-one'), isFalse);
      expect(lib.issues.join(), contains('bad-one'));
      expect(lib.planFor('nothing'), isNull);
    });

    test('duplicate lesson ids across files keep the first', () {
      final one = jsonEncode({
        'lessons': [_plan()],
      });
      final lib = TeachingPlanLibrary.parse([one, one]);
      expect(lib.plansById, hasLength(1));
      expect(lib.issues.join(), contains('duplicate'));
    });

    test('the controller can index on another isolate without blocking start',
        () async {
      final c = AppController(
        store: NoDiskStore(),
        teachingPlanLoader: () async => [pilotJson()],
        parseTeachingPlansInBackground: true,
      );
      await c.initialise();
      expect(c.loaded, isTrue);
      await c.teachingPlansReady;
      expect(c.planFor('en-a'), isNotNull);
      expect(c.planFor('num-add')!.title, isNotEmpty);
    });
  });

  group('subtraction (one group, takeAway)', () {
    testWidgets('start: nothing crossed out; then the last n are', (t) async {
      await _show(t, _obj([12], _minus, countAll: true));
      expect(find.byKey(const Key('object_cell_12')), findsOneWidget);
      expect(find.byKey(const Key('object_removed_1')), findsNothing);
      expect(find.byKey(const Key('objects_taken')), findsNothing);

      await _show(t, _obj([12], _minus, countAll: true, takeAway: 5));
      for (var i = 1; i <= 5; i++) {
        expect(find.byKey(Key('object_removed_$i')), findsOneWidget);
      }
      expect(find.byKey(const Key('object_removed_6')), findsNothing);
      expect(find.byKey(const Key('object_cell_7')), findsOneWidget);
      expect(find.byKey(const Key('object_cell_8')), findsNothing);
      // Only the objects that are left are numbered.
      expect(find.byKey(const Key('object_number_7')), findsOneWidget);
      expect(find.byKey(const Key('object_number_8')), findsNothing);
      expect(find.byKey(const Key('object_group_1')), findsNothing,
          reason: 'one group, not two side by side');
      expect(find.text('12 $_minus 5'), findsOneWidget,
          reason: 'the whole sum, with the starting number');
      expect(find.byKey(const Key('objects_result')), findsNothing);
      expect(find.byKey(const Key('objects_placeholder')), findsOneWidget);
      expect(t.widget<Text>(find.byKey(const Key('objects_placeholder'))).data,
          '?');
    });

    testWidgets('crossing animates in (fades over time, instant when done)',
        (t) async {
      t.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 400);
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: TeachingVisualView(
              visual: _obj([9], '-', takeAway: 4),
            ),
          ),
        ),
      ));
      double opacity() => t
          .widget<Opacity>(find
              .descendant(
                  of: find.byKey(const Key('object_removed_1')),
                  matching: find.byType(Opacity))
              .first)
          .opacity;
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      final early = opacity();
      await t.pumpAndSettle();
      expect(early, greaterThan(opacity()));
      expect(opacity(), closeTo(.25, .01));
    });

    testWidgets('ASCII hyphen means the same; result only with showResult',
        (t) async {
      await _show(t, _obj([9], '-', takeAway: 4, result: 5));
      expect(find.byKey(const Key('object_removed_4')), findsOneWidget);
      expect(find.byKey(const Key('objects_result')), findsNothing,
          reason: 'a placeholder, never the result, while showResult is false');
      expect(find.text('5'), findsNothing);
      expect(find.text('9 $_minus 4'), findsOneWidget);
      await _show(t, _obj([9], '-', takeAway: 4, result: 5, showResult: true));
      expect(find.byKey(const Key('objects_result')), findsOneWidget);
      expect(find.byKey(const Key('objects_placeholder')), findsNothing);
    });

    testWidgets('no takeAway yet: no equation', (t) async {
      await _show(t, _obj([9], '-'));
      expect(find.byKey(const Key('objects_equation')), findsNothing);
    });

    testWidgets('taking away more than there is never crashes', (t) async {
      await _show(t, _obj([3], _minus, takeAway: 8));
      expect(find.byKey(const Key('object_removed_3')), findsOneWidget);
      expect(find.byKey(const Key('object_removed_4')), findsNothing);
    });
  });

  group('compare (vs)', () {
    testWidgets('two groups, neutral mark, no plus, nothing removed',
        (t) async {
      await _show(
          t,
          _obj([4, 7], 'vs',
              reveal: 2, countAll: true, result: 11, showResult: true));
      expect(find.byKey(const Key('object_group_0')), findsOneWidget);
      expect(find.byKey(const Key('object_group_1')), findsOneWidget);
      expect(find.byKey(const Key('compare_mark')), findsOneWidget);
      expect(find.text('+'), findsNothing);
      expect(find.textContaining(_minus), findsNothing);
      // Each side is counted on its own.
      expect(find.byKey(const Key('object_number_1')), findsNWidgets(2));
      expect(find.byKey(const Key('object_number_7')), findsOneWidget);
      expect(find.byKey(const Key('objects_result')), findsNothing,
          reason: 'a comparison has no sum');
    });

    testWidgets('labels make two labelled rows, one above the other',
        (t) async {
      await _show(
          t, _obj([4, 7], 'vs', reveal: 2, labels: const ['Pencil', 'Rubber']));
      final r0 = t.getRect(find.byKey(const Key('object_row_0')));
      final r1 = t.getRect(find.byKey(const Key('object_row_1')));
      expect(r1.top, greaterThanOrEqualTo(r0.bottom), reason: 'stacked rows');
      expect(find.text('Pencil'), findsOneWidget);
      expect(find.text('Rubber'), findsOneWidget);
      expect(
          t.getRect(find.byKey(const Key('object_label_0'))).bottom,
          lessThanOrEqualTo(
              t.getRect(find.byKey(const Key('object_group_0'))).top + 1));
      expect(find.byKey(const Key('compare_mark')), findsOneWidget);
    });

    testWidgets('revealCount 1 shows only the first side', (t) async {
      await _show(t, _obj([4, 7], 'vs', reveal: 1));
      expect(find.byKey(const Key('object_group_1')), findsNothing);
      expect(find.byKey(const Key('compare_mark')), findsNothing);
    });
  });

  group('baseTen', () {
    TeachingVisual bt(int tens, int ones, {bool total = false}) =>
        TeachingVisual(
          type: VisualType.baseTen,
          tens: tens,
          ones: ones,
          showTotal: total,
        );

    testWidgets('a bar per ten, a cube per one', (t) async {
      await _show(t, bt(3, 4));
      expect(find.byKey(const Key('baseten_rod_3')), findsOneWidget);
      expect(find.byKey(const Key('baseten_rod_4')), findsNothing);
      expect(find.byKey(const Key('baseten_one_4')), findsOneWidget);
      expect(find.byKey(const Key('baseten_one_5')), findsNothing);
      expect(find.byKey(const Key('baseten_total')), findsNothing,
          reason: 'total only when showTotal');
    });

    testWidgets('showTotal writes tens*10+ones', (t) async {
      await _show(t, bt(3, 4, total: true));
      expect(t.widget<Text>(find.byKey(const Key('baseten_total'))).data, '34');
      await _show(t, bt(0, 7, total: true));
      expect(find.byKey(const Key('baseten_tens')), findsNothing);
      expect(t.widget<Text>(find.byKey(const Key('baseten_total'))).data, '7');
    });

    testWidgets('semantics describe it without the total', (t) async {
      expect(bt(3, 4).semanticLabel, 'Base ten blocks: 3 tens and 4 ones');
    });
  });

  group('number line hops', () {
    Future<void> line(WidgetTester t, TeachingVisual v) async {
      await _show(t, v, size: const Size(400, 300));
    }

    PaintPattern lands(double x) => paints
      ..circle(x: x, radius: 10.0)
      ..circle(x: x, radius: 6.0);

    RenderBox box(WidgetTester t) =>
        t.renderObject<RenderBox>(find.byKey(const Key('number_line')));

    testWidgets('positive jump lands to the right of the start', (t) async {
      await line(t, _line(5, 3));
      // width 400: 36 px per unit, margin 20.
      expect(box(t), lands(20 + 8 * 36.0));
    });

    testWidgets('negative jump lands to the LEFT of the start', (t) async {
      await line(t, _line(5, -3));
      expect(box(t), lands(20 + 2 * 36.0));
    });

    testWidgets('jump 0 with hops stays on the start number', (t) async {
      await line(t, _line(5, 0));
      // The landing dot sits on the start number (a loop is drawn above it).
      expect(box(t), lands(20 + 5 * 36.0));
    });

    testWidgets('no hops: no landing dot whatever the jump is', (t) async {
      await line(t, _line(5, -3, hops: false));
      expect(box(t), paintsExactlyCountTimes(#drawCircle, 2));
      await line(t, _line(5, 4, hops: false));
      expect(box(t), paintsExactlyCountTimes(#drawCircle, 2));
    });

    testWidgets('hops animate in order (landing dot only when finished)',
        (t) async {
      t.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 300);
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: TeachingVisualView(visual: _line(8, -4)),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 200));
      expect(box(t), paintsExactlyCountTimes(#drawCircle, 2));
      await t.pumpAndSettle();
      expect(box(t), lands(20 + 4 * 36.0));
    });

    testWidgets('a long line (0 to 80) thins its ticks and still renders',
        (t) async {
      await line(t, _line(30, -10, from: 0, to: 80));
      expect(t.takeException(), isNull);
      expect(find.byKey(const Key('number_line')), findsOneWidget);
    });

    test('start, landing and both ends are always labelled (R3-3)', () {
      List<int> labels(int from, int to, int start, int jump, bool hops,
              {double width = 400}) =>
          NumberLinePainter.labelledNumbers(
            from: from,
            to: to,
            start: start,
            jump: hops ? jump : 0,
            showHops: hops,
            width: width,
          );
      // The device case: 0 to 10 in a narrow line used to show 0 2 5 8 10.
      for (final w in [200.0, 260.0, 400.0]) {
        final l = labels(0, 10, 7, -2, true, width: w);
        expect(l, containsAll([0, 10, 7, 5]), reason: 'width $w');
      }
      // A long line thins the rest but keeps start and landing.
      final long = labels(0, 80, 33, 4, true);
      expect(long, containsAll([0, 80, 33, 37]));
      expect(long, isNot(contains(30)), reason: 'thinned around the start');
      expect(long, isNot(contains(40)), reason: 'thinned around the landing');
      expect(long.length, lessThan(15));
      // Without hops the landing is not named.
      expect(labels(0, 80, 33, 4, false), isNot(contains(37)));
      // Zero jump: landing is the start.
      expect(labels(0, 10, 4, 0, true), contains(4));
    });

    test('tick and label spacing grows with the span', () {
      expect(NumberLinePainter.stepFor(36, 22), 1);
      expect(NumberLinePainter.stepFor(4.5, 26), 10);
      expect(NumberLinePainter.stepFor(1, 6), 10);
    });
  });

  group('no overflow', () {
    const sizes = [Size(360, 800), Size(800, 360)];
    final visuals = <String, TeachingVisual>{
      'subtract 19 take 9 counted': _obj([19], _minus,
          countAll: true, takeAway: 9, showResult: true, result: 10),
      'subtract 20 take 2': _obj([20], '-', takeAway: 2),
      'compare 9 vs 11': _obj([9, 11], 'vs', reveal: 2, countAll: true),
      'compare rows': _obj([9, 11], 'vs',
          reveal: 2, countAll: true, labels: const ['Pencil', 'Rubber']),
      'nine tens nine ones': TeachingVisual(
          type: VisualType.baseTen, tens: 9, ones: 9, showTotal: true),
      'one ten': TeachingVisual(type: VisualType.baseTen, tens: 1, ones: 0),
      'hop left': _line(12, -5, from: 0, to: 20),
      'stay': _line(0, 0),
      'long line': _line(60, -30, from: 0, to: 90),
    };
    for (final size in sizes) {
      for (final scale in [1.0, 1.6]) {
        for (final e in visuals.entries) {
          testWidgets(
              '${e.key} at ${size.width.toInt()}x${size.height.toInt()} '
              'text $scale', (t) async {
            await _show(t, e.value, size: size, scale: scale);
            expect(t.takeException(), isNull);
          });
        }
      }
    }
  });
}
