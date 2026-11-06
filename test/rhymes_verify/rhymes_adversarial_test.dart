// Independent ui-verifier tests for the Rhymes feature. Fakes only, no disk.
import 'dart:async';
import 'dart:io';

import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/rhymes/rhyme_models.dart';
import 'package:aksharamala/src/screens/home_screen.dart';
import 'package:aksharamala/src/screens/rhyme_screen.dart';
import 'package:aksharamala/src/screens/rhymes_list_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/services/speech_service.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoDiskStore extends LocalStore {
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

class _Speech extends SpeechService {
  _Speech({this.supported = true, this.delay = Duration.zero});
  final bool supported;
  final Duration delay;
  final calls = <String>[];
  int stops = 0;
  @override
  Future<bool> speak(String text, String locale) async {
    calls.add(text);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return supported;
  }

  @override
  Future<void> stop() async => stops++;
}

final _json = File('content/rhymes/rhymes.json').readAsStringSync();
final _lib = RhymeLibrary.parse(_json);
Rhyme _r(String id) => _lib.byId(id)!;

AppController _controller() {
  const profile = ChildProfile(id: 'p', name: 'Ananya', age: 6, avatar: 'lion');
  return AppController(store: _NoDiskStore())
    ..profiles = [profile]
    ..progress = {'p': ProgressRecord.empty()}
    ..activeProfile = profile
    ..loaded = true;
}

Future<void> _view(WidgetTester tester, Size size, double scale) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

Duration _d(RhymeLine l) => const Duration(milliseconds: 1000);

Future<AppController> _pump(
  WidgetTester tester,
  Rhyme rhyme, {
  required _Speech speech,
  Size size = const Size(800, 360),
  double scale = 1.0,
  AppController? c,
}) async {
  await _view(tester, size, scale);
  final ctl = c ?? _controller();
  await tester.pumpWidget(
    AppScope(
      controller: ctl,
      child: MaterialApp(
        theme: buildTheme(),
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('open'),
                onPressed: () => Navigator.push(
                  ctx,
                  MaterialPageRoute<void>(
                    builder: (_) => RhymeScreen(
                      rhyme: rhyme,
                      speech: speech,
                      lineDuration: _d,
                    ),
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
  return ctl;
}

void main() {
  testWidgets('Hear all: stop mid-way, re-enter, no ghost playback',
      (tester) async {
    final s = _Speech();
    await _pump(tester, _r('rhyme-en-001'), speech: s);
    await tester.tap(find.byKey(const Key('rhyme_hear_all')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byKey(const Key('rhyme_stop')), findsOneWidget);
    final before = s.calls.length;
    await tester.tap(find.byKey(const Key('rhyme_stop')));
    await tester.pump();
    expect(find.byKey(const Key('rhyme_hear_all')), findsOneWidget);
    expect(s.stops, greaterThan(0));
    await tester.pump(const Duration(seconds: 10));
    expect(s.calls.length, before, reason: 'no lines after Stop');
    // Hear all again from the top.
    await tester.tap(find.byKey(const Key('rhyme_hear_all')));
    await tester.pump();
    expect(s.calls.length, before + 1);
    expect(s.calls.last, _r('rhyme-en-001').lines.first.speech);
    // Leave the screen mid-playback: stop is called, no exception later.
    final stopsBefore = s.stops;
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(s.stops, greaterThan(stopsBefore));
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('double tap on a line and on Hear all', (tester) async {
    final s = _Speech();
    await _pump(tester, _r('rhyme-en-001'), speech: s);
    await tester.tap(find.byKey(const Key('rhyme_line_1')));
    await tester.tap(find.byKey(const Key('rhyme_line_1')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
    // Highlight cleared after the estimated time.
    s.calls.clear();
    await tester.tap(find.byKey(const Key('rhyme_hear_all')));
    // second tap lands on whatever is now at that spot (Stop button).
    await tester.tap(find.byKey(const Key('rhyme_hear_all'),
        skipOffstage: true).evaluate().isNotEmpty
        ? find.byKey(const Key('rhyme_hear_all'))
        : find.byKey(const Key('rhyme_stop')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    expect(tester.takeException(), isNull);
    // Direct double invoke of Hear all (same frame) must not run two loops.
    s.calls.clear();
    final hear = tester.widget<FilledButton>(
        find.byKey(const Key('rhyme_hear_all')));
    hear.onPressed!();
    hear.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(seconds: 12));
    final lines = _r('rhyme-en-001').lines.length;
    // If two loops ran, calls would be 2x.
    expect(s.calls.length, lines,
        reason: 'two same-frame Hear all presses started parallel loops?');
  });

  testWidgets('app backgrounded mid-speech: is speech stopped?',
      (tester) async {
    final s = _Speech();
    await _pump(tester, _r('rhyme-en-001'), speech: s);
    await tester.tap(find.byKey(const Key('rhyme_hear_all')));
    await tester.pump();
    final stopsBefore = s.stops;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    final calledWhilePaused = s.calls.length;
    // Report, do not fail: expectation is that speech stops / loop halts.
    // ignore: avoid_print
    print('LIFECYCLE stops added=${s.stops - stopsBefore} '
        'calls while paused=$calledWhilePaused');
    expect(s.stops - stopsBefore, greaterThan(0),
        reason: 'backgrounding should stop speech');
  });

  testWidgets('voice unavailable: dialog, then child still reaches the game',
      (tester) async {
    final s = _Speech(supported: false);
    final c = await _pump(tester, _r('rhyme-hi-001'), speech: s);
    await tester.tap(find.byKey(const Key('rhyme_hear_all')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Voice unavailable'), findsOneWidget);
    // dialog never carries Hindi text
    expect(find.textContaining('Hindi'), findsWidgets);
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rhyme_voice_missing')), findsOneWidget);
    expect(c.rhymeProgressFor('rhyme-hi-001').heard, isTrue);
    await tester.ensureVisible(find.byKey(const Key('rhyme_try_button')));
    await tester.tap(find.byKey(const Key('rhyme_try_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rhyme_blank_line')), findsOneWidget);
    expect(tester.takeException(), isNull);
    // line tap second time: no second dialog
    await tester.tap(find.byKey(const Key('rhyme_back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rhyme_line_0')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Voice unavailable'), findsNothing);
  });

  testWidgets('slow speech call: stop while speak is pending', (tester) async {
    final s = _Speech(delay: const Duration(seconds: 2));
    await _pump(tester, _r('rhyme-en-001'), speech: s);
    await tester.tap(find.byKey(const Key('rhyme_hear_all')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('rhyme_stop')));
    await tester.pump(const Duration(seconds: 6));
    expect(s.calls.length, 1, reason: 'loop abandoned after Stop');
    expect(tester.takeException(), isNull);
  });

  testWidgets('6-line rhyme 800x360 text 1.6: scrolls, nothing overflows',
      (tester) async {
    final r = _r('rhyme-hi-001');
    expect(r.lines.length, 6);
    final s = _Speech();
    await _pump(tester, r, speech: s, scale: 1.6);
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 6; i++) {
      await tester.ensureVisible(find.byKey(Key('rhyme_line_$i')));
      await tester.pump();
      final rect = tester.getRect(find.byKey(Key('rhyme_line_$i')));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.right, lessThanOrEqualTo(800));
    }
    await tester.ensureVisible(find.byKey(const Key('rhyme_hear_all')));
    await tester.pump();
    final hear = tester.getRect(find.byKey(const Key('rhyme_hear_all')));
    expect(hear.height, greaterThanOrEqualTo(48));
    await tester.ensureVisible(find.byKey(const Key('rhyme_try_button')));
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(360, 800), Size(800, 360)]) {
    testWidgets('long titles ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      const te =
          'చిట్టి చిలకమ్మా అమ్మ కొట్టిందా తోట కెళ్ళావా పండు తెచ్చావా నాకు పెట్టావా';
      const ta =
          'நிலா நிலா ஓடி வா நில்லாமல் ஓடி வா மலை மேல் ஏறி வா மல்லிகைப் பூ கொண்டு வா';
      for (final title in [te, ta]) {
        final src = {
          'rhymes': [
            {
              'id': 'long',
              'language': title == te ? 'telugu' : 'tamil',
              'locale': title == te ? 'te-IN' : 'ta-IN',
              'title': title,
              'lines': [
                {'text': 'a b c d'},
                {'text': 'e f g h'},
              ],
              'activity': {
                'kind': 'missing_word',
                'items': [
                  {
                    'line_index': 0,
                    'answer': 'b',
                    'options': ['b', 'x', 'y'],
                  }
                ],
              },
            }
          ],
        };
        final r = RhymeLibrary.parse(jsonEncodeForTest(src)).rhymes.single;
        for (final scale in [1.0, 1.6]) {
          await _pump(tester, r, speech: _Speech(), size: size, scale: scale);
          expect(tester.takeException(), isNull,
              reason: '${size} $scale detail');
          final t = tester.getRect(find.byKey(const Key('rhyme_title')));
          expect(t.left, greaterThanOrEqualTo(0));
          expect(t.right, lessThanOrEqualTo(size.width + 0.5),
              reason: 'title clipped at $size $scale');
          // list card too
          await tester.pumpWidget(const SizedBox());
        }
      }
    });
  }

  testWidgets('list cards with long titles at 360x800 text 1.6',
      (tester) async {
    await _view(tester, const Size(360, 800), 1.6);
    await tester.pumpWidget(
      AppScope(
        controller: _controller(),
        child: MaterialApp(
          theme: buildTheme(),
          home: RhymesListScreen(loader: () async => _json, speech: _Speech()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final l in ['english', 'telugu', 'hindi', 'tamil']) {
      await tester.tap(find.byKey(Key('rhyme_filter_$l')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: l);
      for (final r in _lib.forLanguage(l)) {
        final f = find.byKey(Key('rhyme_card_${r.id}'));
        if (f.evaluate().isEmpty) continue;
        final rect = tester.getRect(f);
        expect(rect.height, greaterThanOrEqualTo(48), reason: r.id);
        expect(rect.right, lessThanOrEqualTo(360.5), reason: r.id);
      }
      // chips target size
      for (final ll in ['english', 'telugu', 'hindi', 'tamil']) {
        final chip = tester.getRect(find.byKey(Key('rhyme_filter_$ll')));
        // report the real chip box
        // ignore: avoid_print
        print('CHIP $ll ${chip.width.round()}x${chip.height.round()} at 360x800 1.6');
      }
    }
  });

  group('home matrix', () {
    const sizes = [
      Size(360, 800),
      Size(390, 844),
      Size(800, 360),
      Size(960, 540),
      Size(1024, 768),
      Size(1280, 800),
    ];
    for (final size in sizes) {
      for (final scale in [1.0, 1.3, 1.6]) {
        testWidgets('home ${size.width.toInt()}x${size.height.toInt()} t$scale',
            (tester) async {
          await _view(tester, size, scale);
          await tester.pumpWidget(
            AppScope(
              controller: _controller(),
              child:
                  MaterialApp(theme: buildTheme(), home: const HomeScreen()),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final targets = <String, Finder>{
            'level': find.byKey(const Key('level_button')),
            'rhymes': find.byKey(const Key('rhymes_button')),
            'rewards': find.byTooltip('Rewards').first,
            'parents': find.byTooltip('Parents').first,
          };
          final rects = <String, Rect>{};
          for (final e in targets.entries) {
            expect(e.value, findsWidgets, reason: e.key);
            final rect = tester.getRect(e.value.first);
            rects[e.key] = rect;
            expect(rect.height, greaterThanOrEqualTo(47.99),
                reason: '${e.key} height $rect at $size $scale');
            expect(rect.width, greaterThanOrEqualTo(47.99),
                reason: '${e.key} width $rect at $size $scale');
            expect(rect.left, greaterThanOrEqualTo(-0.01));
            expect(rect.right, lessThanOrEqualTo(size.width + 0.01),
                reason: '${e.key} off right at $size $scale');
            expect(rect.bottom, lessThanOrEqualTo(size.height));
          }
          final keys = rects.keys.toList();
          for (var i = 0; i < keys.length; i++) {
            for (var j = i + 1; j < keys.length; j++) {
              final inter = rects[keys[i]]!.intersect(rects[keys[j]]!);
              expect(inter.width <= 0.5 || inter.height <= 0.5, isTrue,
                  reason: '${keys[i]} overlaps ${keys[j]} at $size $scale');
            }
          }
          // worlds still visible and not squashed
          final worlds = find.byKey(const Key('home_worlds'));
          if (worlds.evaluate().isNotEmpty) {
            final w = tester.getRect(worlds);
            // ignore: avoid_print
            print(
                'WORLDS ${size.width.toInt()}x${size.height.toInt()} t$scale area=${w.width.round()}x${w.height.round()}');
            expect(w.height, greaterThan(100),
                reason: 'worlds strip squashed at $size $scale');
          }
        });
      }
    }
  });
}

String jsonEncodeForTest(Object o) => _enc(o);

String _enc(Object? o) {
  if (o is Map) {
    return '{${o.entries.map((e) => '${_enc(e.key)}:${_enc(e.value)}').join(',')}}';
  }
  if (o is List) return '[${o.map(_enc).join(',')}]';
  if (o is String) {
    return '"${o.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
  }
  return '$o';
}
