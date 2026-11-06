// Level 1 English starts with writing: big A, then small a. These tests cover
// the lesson order and ids, old saves, the practice-only rule for small
// letters, the two-step "All letters" path and the layout of the tracing
// screen. Everything runs against fakes: no disk, no real font.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aksharamala/src/alphabet/alphabet_data.dart';
import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/batch/batch_content.dart' show BatchText;
import 'package:aksharamala/src/batch/batch_lesson.dart' show WriteMode;
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/handwriting/glyph_mask.dart';
import 'package:aksharamala/src/handwriting/handwriting_policy.dart';
import 'package:aksharamala/src/handwriting/handwriting_registry.dart';
import 'package:aksharamala/src/handwriting/stroke_template.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/alphabet_screen.dart';
import 'package:aksharamala/src/screens/lesson_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:aksharamala/src/widgets/writing_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStore extends LocalStore {
  _FakeStore([this.snapshot = const LocalSnapshot(profiles: [], progress: {})]);
  final LocalSnapshot snapshot;
  @override
  Future<LocalSnapshot> load() async => snapshot;
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

const _profile = ChildProfile(
  id: 'p',
  name: 'Meena',
  age: 4,
  avatar: 'lion',
  level: 1,
);

AppController _controller({Set<String> done = const {}, int level = 1}) {
  final profile = _profile.copyWith(level: level);
  return AppController(store: _FakeStore())
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

/// A stand-in for the font: a plain ring, so a drawn circle traces it.
Future<GlyphMask> _ring(String glyph) async {
  const n = 32;
  return GlyphMask(n, [
    for (var y = 0; y < n; y++)
      for (var x = 0; x < n; x++)
        ((math.sqrt(math.pow((x + .5) / n - .5, 2) +
                        math.pow((y + .5) / n - .5, 2)) -
                    .28)
                .abs() <=
            .04),
  ]);
}

List<Pt> _circle() => [
      for (var k = 0; k <= 40; k++)
        Pt(.5 + .28 * math.sin(2 * math.pi * k / 40),
            .5 - .28 * math.cos(2 * math.pi * k / 40)),
    ];

void main() {
  setUp(() => feedbackPause = Duration.zero);
  tearDown(() => feedbackPause = defaultFeedbackPause);

  final english = curriculum.firstWhere((w) => w.id == 'english');
  Lesson lessonOf(String id) => english.lessons.firstWhere((l) => l.id == id);

  group('English Level 1 lesson order', () {
    test('big A, small a, then A is for Apple', () {
      final level1 = _controller().worlds.firstWhere((w) => w.id == 'english');
      expect(
        level1.lessons.take(3).map((l) => l.id).toList(),
        ['en-trace', 'en-trace-a-lower', 'en-a'],
      );
      expect(level1.lessons[0].title, 'Trace big A');
      expect(
        level1.lessons[0].subtitle,
        'Draw the big letter A with your finger',
      );
      expect(level1.lessons[1].title, 'Trace small a');
      expect(level1.lessons[0].symbol, 'A');
      expect(level1.lessons[1].symbol, 'a');
      expect(level1.lessons[1].kind, LessonKind.tracing);
    });

    test('prerequisites: big A has none, small a needs big A', () {
      expect(lessonOf('en-trace').prerequisites, isEmpty);
      expect(lessonOf('en-trace-a-lower').prerequisites, ['en-trace']);
    });

    test('the rest of the English order is unchanged', () {
      final ids = english.lessons.map((l) => l.id).toList();
      expect(ids[2], 'en-a');
      expect(ids.sublist(3, 28), [
        for (var i = 2; i <= 26; i++)
          'en-letter-${i.toString().padLeft(3, '0')}'
      ]);
      expect(ids.indexOf('en-word'), 28);
      expect(ids.indexOf('en-story'), 29);
      expect(ids.toSet().length, ids.length, reason: 'ids stay unique');
    });

    test('tracing is Level 1 only (no tracing at Levels 2 to 5)', () {
      for (final level in [2, 3, 4, 5]) {
        final w = _controller(level: level)
            .worlds
            .firstWhere((w) => w.id == 'english');
        expect(w.lessons.where((l) => l.kind == LessonKind.tracing), isEmpty,
            reason: 'level $level');
      }
      expect(lessonOf('en-trace-a-lower').levels, {1});
      expect(lessonOf('en-trace').levels, {1});
    });

    test('the quest map recommends big A first for a new child', () {
      final c = _controller();
      final w = c.worlds.firstWhere((w) => w.id == 'english');
      expect(c.recommendedLesson(w).id, 'en-trace');
      expect(c.isLessonUnlocked(lessonOf('en-trace')), isTrue);
    });
  });

  group('old progress', () {
    test('a save with en-a and en-trace done keeps both done', () async {
      final record = ProgressRecord.fromJson({
        'completedLessons': ['en-a', 'en-trace', 'alpha-english-001'],
        'attempts': {'english': 2},
        'correct': {'english': 2},
        'lastPlayed': {'english': 'en-trace'},
        'earnedBadges': ['first-step'],
        'questStars': {'en-a': 3, 'en-trace': 3},
      });
      final store = _FakeStore(LocalSnapshot(
        profiles: const [_profile],
        progress: {'p': record},
      ));
      final c = AppController(store: store);
      await c.initialise();
      final done = c.activeProgress.completedWithLegacy;
      expect(done, containsAll(['en-a', 'en-trace', 'alpha-english-001']));
      expect(c.activeProgress.questStars['en-trace'], 3);
      final w = c.worlds.firstWhere((w) => w.id == 'english');
      // The new small-a quest simply shows as not done yet, and is next.
      expect(done.contains('en-trace-a-lower'), isFalse);
      expect(c.recommendedLesson(w).id, 'en-trace-a-lower');
    });
  });

  group('small letters are practice only', () {
    test('there is no stroke template for lowercase a, but one for A', () {
      expect(templateFor('a'), isNull);
      expect(templateFor('A'), isNotNull);
      for (final g in 'abcdefghijklmnopqrstuvwxyz'.split('')) {
        expect(templateFor(g), isNull, reason: g);
      }
    });

    test('a good small a earns goodShape, never mastery', () async {
      final mask = await _ring('a');
      final result = const HandwritingPolicy().judge(
        drawn: [_circle()],
        template: templateFor('a'),
        mask: mask,
      );
      expect(result.outcome, WritingOutcome.goodShape);
      expect(result.shapeOk, isTrue);
      expect(result.awardsMastery, isFalse);
    });

    test('even the capital A is practice only (template unverified)', () {
      final t = templateFor('A')!;
      expect(t.strokeOrderVerified, isFalse);
      final r = const HandwritingPolicy().judge(
        drawn: t.strokes,
        template: t,
      );
      expect(r.awardsMastery, isFalse);
    });
  });

  group('the All letters path (English)', () {
    test('ids: big ids unchanged, small ids distinct, only English has them',
        () {
      expect(englishAlphabet.lessonId(0), 'alpha-english-001');
      expect(englishAlphabet.lowerLessonId(0), 'alpha-english-001-lower');
      expect(englishAlphabet.lowerGlyph(25), 'z');
      expect(englishAlphabet.hasLowercase, isTrue);
      for (final s in alphabets.values.where((s) => s != englishAlphabet)) {
        expect(s.hasLowercase, isFalse, reason: s.worldId);
        expect(s.lowerGlyph(0), isNull, reason: s.worldId);
      }
      final ids = {
        for (var i = 0; i < 26; i++) ...[
          englishAlphabet.lessonId(i),
          englishAlphabet.lowerLessonId(i),
        ],
      };
      expect(ids.length, 52);
    });

    Future<AppController> open(
      WidgetTester tester, {
      String world = 'english',
      Set<String> done = const {},
      Size size = const Size(960, 540),
    }) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      addTearDown(tester.view.reset);
      final c = _controller(done: done);
      final w = curriculum.firstWhere((w) => w.id == world);
      await tester.pumpWidget(AppScope(
        controller: c,
        child: MaterialApp(
          theme: buildTheme(),
          home: AlphabetScreen(
            world: w,
            letters: alphabets[world]!,
            maskLoader: _ring,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return c;
    }

    Future<void> drawCircle(WidgetTester tester) async {
      final rect = tester.getRect(find.byKey(const Key('letter_pad')));
      final pts = [
        for (final p in _circle())
          Offset(rect.left + rect.width * p.x, rect.top + rect.height * p.y),
      ];
      final g = await tester.startGesture(pts.first);
      for (final p in pts.skip(1)) {
        await g.moveTo(p);
        await tester.pump();
      }
      await g.up();
      await tester.pump();
      await tester.tap(find.byKey(const Key('write_check')));
      await tester.pump();
    }

    String bigText(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('letter_big'))).data!;

    testWidgets('big X first, then small x, saved under separate ids',
        (tester) async {
      final c = await open(tester, done: {'alpha-english-001'});
      // Open B (index 1) from the grid.
      await tester.tap(find.byKey(const Key('letter_tile_1')));
      await tester.pumpAndSettle();
      expect(bigText(tester), 'B');
      expect(find.text('2 / 26 · big'), findsOneWidget);
      // B has a stroke template, so draw it as the template says.
      final t = templateFor('B')!;
      final rect = tester.getRect(find.byKey(const Key('letter_pad')));
      for (final s in t.strokes) {
        final g = await tester.startGesture(Offset(
            rect.left + rect.width * s.first.x,
            rect.top + rect.height * s.first.y));
        for (final p in s.skip(1)) {
          await g.moveTo(Offset(
              rect.left + rect.width * p.x, rect.top + rect.height * p.y));
          await tester.pump();
        }
        await g.up();
        await tester.pump();
      }
      await tester.tap(find.byKey(const Key('write_check')));
      await tester.pump();
      expect(c.activeProgress.completedLessons, contains('alpha-english-002'));
      expect(c.activeProgress.completedLessons,
          isNot(contains('alpha-english-002-lower')));
      expect(find.text('Next: b'), findsOneWidget);

      await tester.pumpAndSettle(); // the celebration popup
      await tester.tap(find.byKey(const Key('result_next')));
      await tester.pumpAndSettle();
      expect(bigText(tester), 'b');
      expect(find.text('2 / 26 · small'), findsOneWidget);
      // The small letter has no stroke template: the pad judges it by the
      // font outline only.
      final pad = tester.widget<WritingPad>(find.byType(WritingPad));
      expect(pad.template, isNull);
      expect(pad.glyph, 'b');
      await drawCircle(tester);
      expect(c.activeProgress.completedLessons,
          contains('alpha-english-002-lower'));
      expect(find.text('Next: C'), findsOneWidget);
      await tester.pumpAndSettle(); // the celebration popup
      await tester.tap(find.byKey(const Key('result_next')));
      await tester.pumpAndSettle();
      expect(bigText(tester), 'C');
    });

    testWidgets('counters: big count unchanged, small letters counted apart',
        (tester) async {
      await open(tester, done: {
        'alpha-english-001',
        'alpha-english-002',
        'alpha-english-001-lower',
      });
      expect(find.text('2 of 26 letters traced'), findsOneWidget);
      expect(
        find.text('1 of 26 small letters traced'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('alphabet_lower_progress_text')),
          findsOneWidget);
    });

    testWidgets('Next letter opens the small letter when the big one is done',
        (tester) async {
      await open(tester, done: {'alpha-english-001'});
      await tester.tap(find.byKey(const Key('alphabet_continue')));
      await tester.pumpAndSettle();
      expect(bigText(tester), 'a');
    });

    testWidgets('Telugu has no small-letter step or counter', (tester) async {
      await open(tester, world: 'telugu');
      expect(
          find.byKey(const Key('alphabet_lower_progress_text')), findsNothing);
      await tester.tap(find.byKey(const Key('alphabet_continue')));
      await tester.pumpAndSettle();
      expect(find.textContaining('·'), findsNothing);
    });

    for (final size in const [
      Size(360, 800),
      Size(800, 360),
      Size(1024, 768),
    ]) {
      testWidgets('small-letter step has no overflow at $size', (tester) async {
        await open(tester, done: {'alpha-english-001'}, size: size);
        await tester.tap(find.byKey(const Key('alphabet_continue')));
        await tester.pumpAndSettle();
        expect(bigText(tester), 'a');
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the Level 1 tracing lessons', () {
    Future<void> pump(
      WidgetTester tester,
      String id,
      Size size, {
      double scale = 1,
    }) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await tester.pumpWidget(AppScope(
        controller: _controller(),
        child: MaterialApp(
          theme: buildTheme(),
          home: LessonScreen(world: english, lesson: lessonOf(id)),
        ),
      ));
      await tester.pump();
    }

    for (final id in ['en-trace', 'en-trace-a-lower']) {
      for (final size in const [
        Size(360, 800),
        Size(800, 360),
        Size(1024, 768),
      ]) {
        testWidgets('$id lays out without overflow at $size', (tester) async {
          await pump(tester, id, size);
          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('trace_pad')), findsOneWidget);
          expect(find.text(lessonOf(id).title), findsWidgets);
        });
      }
    }

    testWidgets('big A uses its route map, small a has no template',
        (tester) async {
      await pump(tester, 'en-trace', const Size(800, 600));
      var pad = tester.widget<WritingPad>(find.byType(WritingPad));
      expect(pad.glyph, 'A');
      expect(pad.template, isNotNull);
      await pump(tester, 'en-trace-a-lower', const Size(800, 600));
      pad = tester.widget<WritingPad>(find.byType(WritingPad));
      expect(pad.glyph, 'a');
      expect(pad.template, isNull);
    });

    testWidgets('the big-A lesson still works at a large text size',
        (tester) async {
      await pump(tester, 'en-trace-a-lower', const Size(360, 800), scale: 1.6);
      expect(tester.takeException(), isNull);
    });
  });

  group('small a is one task from two places', () {
    ProgressRecord rec(Set<String> done, [Map<String, int> stars = const {}]) =>
        ProgressRecord(
          completedLessons: done,
          attempts: const {},
          correct: const {},
          lastPlayed: const {},
          earnedBadges: const {},
          questStars: stars,
        );

    test('finishing the quest finishes the path step, and back', () {
      expect(rec({'en-trace-a-lower'}).completedWithLegacy,
          contains('alpha-english-001-lower'));
      expect(rec({'alpha-english-001-lower'}).completedWithLegacy,
          contains('en-trace-a-lower'));
      expect(rec({'en-trace'}).completedWithLegacy,
          isNot(contains('en-trace-a-lower')));
      // Nothing in the save itself is rewritten.
      expect(rec({'en-trace-a-lower'}).completedLessons, {'en-trace-a-lower'});
    });

    test('the second place does not pay the stars again', () {
      final r = rec({'en-trace-a-lower'}, {'en-trace-a-lower': 3});
      expect(r.starsPaidBy('alpha-english-001-lower'), 3);
      expect(
          rec({'alpha-english-001-lower'}).starsPaidBy('en-trace-a-lower'), 3);
      expect(rec({}).starsPaidBy('en-trace-a-lower'), 0);
    });

    testWidgets('the small-letter counter includes a done quest small a',
        (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(960, 540);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(AppScope(
        controller: _controller(done: {'en-trace-a-lower'}),
        child: MaterialApp(
          theme: buildTheme(),
          home: AlphabetScreen(
              world: english, letters: englishAlphabet, maskLoader: _ring),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('1 of 26 small letters traced'), findsOneWidget);
      expect(find.text('0 of 26 letters traced'), findsOneWidget);
    });
  });

  group('wording and guide', () {
    test('English letters get letter wording; digits keep number wording', () {
      expect(BatchText.forGlyph('en-US', 'a').strokeHint, contains('letter'));
      expect(BatchText.forGlyph('en-US', 'A').strokesHint, contains('letter'));
      expect(BatchText.forGlyph('en-IN', '5').strokeHint, contains('number'));
      expect(BatchText.forGlyph('te-IN', 'అ'), BatchText.telugu);
    });

    testWidgets('a glyph with no template is guided at the named strength',
        (tester) async {
      expect(nonTemplateGuideOpacity, greaterThan(.13),
          reason: 'stronger than the old guide');
      expect(nonTemplateGuideOpacity, lessThan(.6),
          reason: 'clearly lighter than the opaque ink');
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 500);
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      const ink = Color(0xFF177A45);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 400,
              height: 500,
              child: WritingPad(
                glyph: 'a',
                mode: WriteMode.guided,
                text: BatchText.englishLetter,
                color: ink,
                onResult: (_) {},
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      final pad = tester.getRect(find.byKey(const Key('writing_pad')));
      // Centre of the pad: inside the (test font) glyph block.
      final c = pad.center;
      Color? px;
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = (await image.toByteData())!;
        final o = ((c.dy.round()) * image.width + c.dx.round()) * 4;
        px = Color.fromARGB(
            255, data.getUint8(o), data.getUint8(o + 1), data.getUint8(o + 2));
      });
      const bg = Color(0xFFFFFDF7);
      int mix(int b, int i) =>
          (b * (1 - nonTemplateGuideOpacity) + i * nonTemplateGuideOpacity)
              .round();
      expect((px!.r * 255).round(), closeTo(mix(0xFF, 0x17), 3));
      expect((px!.g * 255).round(), closeTo(mix(0xFD, 0x7A), 3));
      expect((px!.b * 255).round(), closeTo(mix(0xF7, 0x45), 3));
      expect(bg.a, 1);
      expect(nonTemplateGuideOutline, greaterThan(0));
    });
  });
}
