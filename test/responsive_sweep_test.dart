import 'package:aksharamala/src/alphabet/alphabet_data.dart';
import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/handwriting/glyph_mask.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/result_text.dart';
import 'package:aksharamala/src/screens/achievements_screen.dart';
import 'package:aksharamala/src/screens/alphabet_screen.dart';
import 'package:aksharamala/src/screens/batch_lesson_screen.dart';
import 'package:aksharamala/src/screens/home_screen.dart';
import 'package:aksharamala/src/screens/lesson_screen.dart';
import 'package:aksharamala/src/screens/parent_dashboard.dart';
import 'package:aksharamala/src/screens/profile_screen.dart';
import 'package:aksharamala/src/screens/world_map_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Every essential control is visible without scrolling": each screen is
/// opened on phones and tablets, upright and on its side, and must lay out
/// without an overflow error and without anything it could scroll to.
class _Store extends LocalStore {
  @override
  Future<LocalSnapshot> load() async =>
      const LocalSnapshot(profiles: [], progress: {});
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

const sizes = <String, Size>{
  'phone landscape 640x360': Size(640, 360),
  'phone landscape 844x390': Size(844, 390),
  'phone portrait 390x844': Size(390, 844),
  'phone portrait 360x640': Size(360, 640),
  'tablet landscape 1280x800': Size(1280, 800),
  'tablet portrait 800x1280': Size(800, 1280),
};

Future<AppController> newController() async {
  final c = AppController(store: _Store());
  await c.initialise();
  await c.addProfile('Kid', 5, 'lion');
  return c;
}

/// Things a child could scroll: any Scrollable with somewhere to go.
List<String> scrollables(WidgetTester tester) {
  final out = <String>[];
  for (final s in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
    final p = s.position;
    if (p.hasContentDimensions && p.maxScrollExtent > 1) {
      out.add(
          '${s.axisDirection.name} scroll of ${p.maxScrollExtent.round()}px');
    }
  }
  return out;
}

/// Opens [screen], reports every layout error and every scrollable.
Future<List<String>> inspect(
  WidgetTester tester,
  AppController c,
  Size size,
  Widget screen, {
  Future<void> Function()? then,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  await tester.pumpWidget(
    AppScope(
      controller: c,
      child: MaterialApp(theme: buildTheme(), home: screen),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  if (then != null) await then();
  final found = <String>[];
  // Drain every layout error (a screen can raise several in one frame).
  for (var e = tester.takeException(); e != null; e = tester.takeException()) {
    final deep =
        (e is FlutterError ? e.toStringDeep() : e.toString()).split('\n');
    final at = deep.indexWhere((l) => l.contains('file:///'));
    found.add('error: ${e.toString().split('\n').first} '
        '${at < 0 ? '' : deep[at].trim()}');
  }
  found.addAll(scrollables(tester));
  return found;
}

void main() {
  tearDown(() {});

  Lesson? firstOf(LearningWorld w, bool Function(Lesson) test) {
    for (final l in w.lessons) {
      if (test(l)) return l;
    }
    return null;
  }

  // Every lesson of every level, first step, at the awkward sizes.
  testWidgets('every lesson at every level opens without scrolling',
      (tester) async {
    addTearDown(tester.view.reset);
    final c = await newController();
    final problems = <String>[];
    var n = 0;
    for (final size in const [
      Size(640, 360),
      Size(360, 640),
      Size(1024, 768),
    ]) {
      for (final w in c.allWorlds) {
        for (final l in w.lessons) {
          n++;
          final found = await inspect(
            tester,
            c,
            size,
            l is BatchLesson
                ? BatchLessonScreen(
                    world: w,
                    lesson: l,
                    maskLoader: (g) async =>
                        GlyphMask.fromRows(const ['##', '##']),
                  )
                : LessonScreen(world: w, lesson: l),
          );
          for (final f in found) {
            problems.add(
                '${l.id} @ ${size.width.toInt()}x${size.height.toInt()}: $f');
          }
        }
      }
    }
    // ignore: avoid_print
    print('LESSONS opened: $n, problems: ${problems.length}');
    // ignore: avoid_print
    print(problems.take(40).join('\n'));
    expect(problems, isEmpty, reason: '${problems.length} problems');
  });

  testWidgets('screens fit every phone and tablet without scrolling',
      (tester) async {
    addTearDown(tester.view.reset);
    final c = await newController();
    final report = <String>[];

    Future<void> check(String name, Widget Function() screen,
        {Future<void> Function()? then}) async {
      for (final e in sizes.entries) {
        final found = await inspect(tester, c, e.value, screen(), then: then);
        for (final f in found) {
          report.add('$name @ ${e.key}: $f');
        }
      }
    }

    await check('home', () => const HomeScreen());
    await check('profile', () => const ProfileScreen(allowSkip: true));
    await check('rewards', () => const AchievementsScreen());
    await check('parent dashboard', () => const ParentDashboard());
    for (final w in c.worlds) {
      await check('lesson list ${w.id}', () => WorldMapScreen(world: w));
    }
    final english = c.worlds.firstWhere((w) => w.id == 'english');
    await check(
        'alphabet list',
        () => AlphabetScreen(
              world: english,
              letters: alphabets['english']!,
              maskLoader: (g) async => GlyphMask.fromRows(const ['##', '##']),
            ));
    await check(
        'letter',
        () => LetterScreen(
              world: english,
              letters: alphabets['english']!,
              index: 0,
              maskLoader: (g) async => GlyphMask.fromRows(const ['##', '##']),
            ));
    final seen = <String>{};
    for (final w in c.worlds) {
      for (final l in w.lessons) {
        final key = '${w.id}/${l.runtimeType}/${l.kind.name}';
        if (!seen.add(key)) continue;
        await check(
          'lesson ${l.id} (${l.kind.name})',
          () => l is BatchLesson
              ? BatchLessonScreen(
                  world: w,
                  lesson: l,
                  maskLoader: (g) async =>
                      GlyphMask.fromRows(const ['##', '##']))
              : LessonScreen(world: w, lesson: l),
        );
      }
    }
    final tracing =
        firstOf(c.worlds.first, (l) => l.kind == LessonKind.tracing);
    if (tracing != null) {
      await check('tracing ${tracing.id}',
          () => LessonScreen(world: c.worlds.first, lesson: tracing));
    }
    await check(
        'result popup',
        () => Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: LessonResultDialog(
                    correct: true,
                    text: ResultText.forLocale('en-IN'),
                    gained: 3,
                    onNext: () {},
                    onAgain: () {},
                    onBack: () {},
                  ),
                ),
              ),
            ));

    // ignore: avoid_print
    print('SWEEP\n${report.join('\n')}');
    expect(report, isEmpty, reason: '${report.length} problems');
  });
}
