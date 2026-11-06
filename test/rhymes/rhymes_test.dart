import 'dart:io';

import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
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

class _FakeSpeech extends SpeechService {
  _FakeSpeech({this.supported = true});
  final bool supported;
  final calls = <(String, String)>[];
  int stops = 0;

  @override
  Future<bool> speak(String text, String locale) async {
    calls.add((text, locale));
    return supported;
  }

  @override
  Future<void> stop() async => stops++;
}

final _json = File('content/rhymes/rhymes.json').readAsStringSync();
final _library = RhymeLibrary.parse(_json);

Duration _quick(RhymeLine _) => const Duration(milliseconds: 100);

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

Future<AppController> _pumpRhyme(
  WidgetTester tester,
  Rhyme rhyme, {
  _FakeSpeech? speech,
  AppController? controller,
  Size size = const Size(800, 1280),
  double scale = 1.0,
}) async {
  await _view(tester, size, scale);
  final c = controller ?? _controller();
  await tester.pumpWidget(
    AppScope(
      controller: c,
      child: MaterialApp(
        theme: buildTheme(),
        home: RhymeScreen(
          rhyme: rhyme,
          speech: speech ?? _FakeSpeech(),
          lineDuration: _quick,
        ),
      ),
    ),
  );
  await tester.pump();
  return c;
}

Future<void> _pumpList(
  WidgetTester tester, {
  RhymeLoader? loader,
  _FakeSpeech? speech,
  AppController? controller,
  Size size = const Size(800, 1280),
  double scale = 1.0,
}) async {
  await _view(tester, size, scale);
  await tester.pumpWidget(
    AppScope(
      controller: controller ?? _controller(),
      child: MaterialApp(
        theme: buildTheme(),
        home: RhymesListScreen(
          loader: loader ?? () async => _json,
          speech: speech ?? _FakeSpeech(),
          lineDuration: _quick,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rhyme _r(String id) => _library.byId(id)!;

Future<void> _hearAndOpenGame(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('rhyme_line_0')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  // At very large text the page scrolls instead of shrinking.
  await tester.ensureVisible(find.byKey(const Key('rhyme_try_button')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('rhyme_try_button')));
  await tester.pump();
}

String _labelOf(WidgetTester tester, Finder f) => tester
    .widget<Text>(find.descendant(of: f, matching: find.byType(Text)))
    .data!;

String _lineJson(String text) => '{"text":"$text"}';

String _one(String id, {String? lines, String? activity}) {
  final ls = lines ?? '[${_lineJson('a b c')},${_lineJson('d e f')}]';
  final act = activity ??
      '{"kind":"missing_word","items":[{"line_index":0,"blank_word":"b","options":["b","x","y"],"answer":"b"}]}';
  return '{"id":"$id","language":"english","locale":"en-US","title":"T $id","lines":$ls,"activity":$act}';
}

String _item(int index, String answer, String options) =>
    '{"kind":"missing_word","items":[{"line_index":$index,"blank_word":"$answer","options":$options,"answer":"$answer"}]}';

void main() {
  group('loader and validation', () {
    test('the real rhymes file loads clean', () {
      expect(_library.issues, isEmpty);
      expect(_library.rhymes.length, 15);
      expect({for (final r in _library.rhymes) r.id}.length, 15);
      for (final l in rhymeLanguages) {
        expect(_library.forLanguage(l), isNotEmpty);
      }
      for (final r in _library.rhymes) {
        expect(r.lines.length, inInclusiveRange(2, 6));
        expect(r.items, isNotEmpty);
        for (final i in r.items) {
          expect(r.blankedLine(i), contains('____'));
          expect(r.blankedLine(i), isNot(equals(r.lines[i.lineIndex].text)));
        }
      }
    });

    test('bad rhymes are skipped and reported, good ones survive', () {
      final seven = List.filled(7, _lineJson('a b')).join(',');
      final text = '{"rhymes":['
          '${_one("ok-1")},'
          '${_one("ok-1")},'
          '${_one("one-line", lines: '[${_lineJson('a b')}]')},'
          '${_one("seven", lines: '[$seven]')},'
          '${_one("ans-not-in-options", activity: _item(0, "b", '["x","y","z"]'))},'
          '${_one("word-not-in-line", activity: _item(1, "b", '["b","x","y"]'))},'
          '${_one("bad-index", activity: _item(9, "b", '["b","x","y"]'))},'
          '${_one("ok-2")},'
          '42'
          ']}';
      final lib = RhymeLibrary.parse(text);
      expect(lib.rhymes.map((r) => r.id), ['ok-1', 'ok-2']);
      expect(lib.issues.length, 7);
      expect(
        lib.issues.map((i) => i.rhymeId),
        containsAll(['ok-1', 'one-line', 'seven', 'ans-not-in-options']),
      );
      for (final i in lib.issues) {
        expect(i.toString(), isNot(contains('T ok')));
      }
    });

    test('broken file, wrong shape and failing loader never throw', () async {
      expect(RhymeLibrary.parse('not json').rhymes, isEmpty);
      expect(RhymeLibrary.parse('{"rhymes": 3}').issues, isNotEmpty);
      expect(RhymeLibrary.parse('[]').issues, isNotEmpty);
      final lib = await loadRhymeLibrary(() async => throw StateError('x'));
      expect(lib.rhymes, isEmpty);
      expect(lib.issues, isNotEmpty);
    });

    test('hiding fields are read, default false', () {
      for (final r in _library.rhymes) {
        expect(r.meaningHiddenDuringActivity, isTrue, reason: r.id);
        expect(r.hideTitleDuringActivity, r.id == 'rhyme-te-002', reason: r.id);
      }
      final lib = RhymeLibrary.parse('{"rhymes":[${_one("d")}]}');
      expect(lib.rhymes.single.meaningHiddenDuringActivity, isFalse);
      expect(lib.rhymes.single.hideTitleDuringActivity, isFalse);
    });
  });

  group('progress', () {
    test('old saves load unchanged and re-save without a rhymes key', () {
      final old = <String, Object>{
        'completedLessons': ['a'],
        'attempts': {'english': 1},
        'correct': {'english': 1},
        'lastPlayed': {'english': 'a'},
        'earnedBadges': ['first-step'],
        'questStars': {'a': 3},
        'levelAttempts': <String, int>{},
        'levelCorrect': <String, int>{},
      };
      final rec = ProgressRecord.fromJson(old);
      expect(rec.rhymes, isEmpty);
      expect(rec.toJson().containsKey('rhymes'), isFalse);
      expect(rec.toJson(), old);
      expect(saveFormatVersion, 2);
    });

    test('round trip, junk entries skipped', () {
      final rec = ProgressRecord.empty()
          .withRhymes({'r1': const RhymeProgress(heard: true, done: true)});
      final back =
          ProgressRecord.fromJson(Map<String, dynamic>.from(rec.toJson()));
      expect(back.rhymes['r1']!.done, isTrue);
      final junk = ProgressRecord.fromJson({
        'rhymes': {
          'x': 5,
          'y': {'heard': true},
        },
      });
      expect(junk.rhymes.keys, ['y']);
      expect(junk.rhymes['y']!.done, isFalse);
    });

    test('heard/done persist, pay no stars, survive level change and results',
        () async {
      final dir = Directory.systemTemp.createTempSync('rhyme_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/progress.json');
      final c = AppController(store: LocalStore(fileOverride: file));
      await c.createProfile(name: 'Ana', level: 1, avatar: 'lion');
      final stars = c.activeProfile!.stars;
      await c.markRhymeHeard('rhyme-en-001');
      expect(c.rhymeProgressFor('rhyme-en-001').heard, isTrue);
      expect(c.rhymeProgressFor('rhyme-en-001').done, isFalse);
      expect(c.activeProfile!.stars, stars);
      await c.markRhymeDone('rhyme-en-001');
      expect(c.activeProfile!.stars, stars);
      await c.setLevel(3);
      final world = curriculum.first;
      await c.recordResult(
        world: world,
        lesson: world.lessons.first,
        correct: true,
      );
      expect(c.rhymeProgressFor('rhyme-en-001').done, isTrue);
      expect(
        c.activeProfile!.stars - stars,
        3,
        reason: 'only the lesson paid, never the rhyme',
      );
      final c2 = AppController(store: LocalStore(fileOverride: file));
      await c2.initialise();
      expect(c2.rhymeProgressFor('rhyme-en-001').done, isTrue);
      expect(c2.rhymeProgressFor('rhyme-en-002').heard, isFalse);
    });
  });

  group('list screen', () {
    testWidgets('English by default, filters switch language', (tester) async {
      await _pumpList(tester);
      for (final r in _library.forLanguage('english')) {
        expect(find.byKey(Key('rhyme_card_${r.id}')), findsOneWidget);
      }
      expect(find.byKey(const Key('rhyme_card_rhyme-te-001')), findsNothing);
      await tester.tap(find.byKey(const Key('rhyme_filter_telugu')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('rhyme_card_rhyme-te-001')), findsOneWidget);
      expect(find.byKey(const Key('rhyme_card_rhyme-en-001')), findsNothing);
      for (final l in ['hindi', 'tamil']) {
        await tester.tap(find.byKey(Key('rhyme_filter_$l')));
        await tester.pumpAndSettle();
        for (final r in _library.forLanguage(l)) {
          expect(find.byKey(Key('rhyme_card_${r.id}')), findsOneWidget);
        }
      }
    });

    testWidgets('pictures: placeholder is labelled, never a broken image', (
      tester,
    ) async {
      await _pumpList(tester);
      expect(find.byKey(const Key('art_placeholder')), findsWidgets);
      expect(find.text('Artwork coming soon'), findsWidgets);
    });

    testWidgets('card opens the rhyme; done and heard marks show',
        (tester) async {
      final c = _controller();
      await c.markRhymeDone('rhyme-en-002');
      await c.markRhymeHeard('rhyme-en-003');
      await _pumpList(tester, controller: c);
      expect(find.byKey(const Key('rhyme_done_mark')), findsOneWidget);
      expect(find.byKey(const Key('rhyme_heard_mark')), findsOneWidget);
      await tester.tap(find.byKey(const Key('rhyme_card_rhyme-en-001')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('rhyme_line_0')), findsOneWidget);
    });

    testWidgets(
        'a language with no rhymes says coming soon; broken file is calm',
        (tester) async {
      await _pumpList(tester, loader: () async => '{"rhymes":[${_one("e1")}]}');
      await tester.tap(find.byKey(const Key('rhyme_filter_tamil')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('rhymes_empty')), findsOneWidget);
      await _pumpList(tester, loader: () async => 'garbage');
      expect(find.byKey(const Key('rhymes_empty')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('rhyme screen', () {
    testWidgets('tapping a line speaks that line with the rhyme locale', (
      tester,
    ) async {
      final speech = _FakeSpeech();
      final rhyme = _r('rhyme-te-001');
      await _pumpRhyme(tester, rhyme, speech: speech);
      await tester.tap(find.byKey(const Key('rhyme_line_1')));
      await tester.pump();
      expect(speech.calls, [(rhyme.lines[1].speech, 'te-IN')]);
      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.graphic_eq_rounded), findsNothing);
      expect(
        find.textContaining('does not sing'),
        findsOneWidget,
        reason: 'honest note that the phone voice reads, no singing',
      );
    });

    testWidgets('Hear all plays lines in order, highlights, can stop', (
      tester,
    ) async {
      final speech = _FakeSpeech();
      final rhyme = _r('rhyme-en-001');
      await _pumpRhyme(tester, rhyme, speech: speech);
      await tester.tap(find.byKey(const Key('rhyme_hear_all')));
      await tester.pump();
      expect(speech.calls.length, 1);
      expect(find.byKey(const Key('rhyme_stop')), findsOneWidget);
      for (var i = 1; i < rhyme.lines.length; i++) {
        expect(
          find.descendant(
            of: find.byKey(Key('rhyme_line_${i - 1}')),
            matching: find.byIcon(Icons.graphic_eq_rounded),
          ),
          findsOneWidget,
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();
        expect(speech.calls.length, i + 1);
      }
      expect(speech.calls.map((c) => c.$1), rhyme.lines.map((l) => l.speech));
      expect(speech.calls.every((c) => c.$2 == 'en-US'), isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.byKey(const Key('rhyme_hear_all')), findsOneWidget);
      expect(find.byIcon(Icons.graphic_eq_rounded), findsNothing);

      // Stop part-way: nothing more is spoken.
      speech.calls.clear();
      await tester.tap(find.byKey(const Key('rhyme_hear_all')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('rhyme_stop')));
      await tester.pump();
      expect(speech.stops, greaterThan(0));
      await tester.pump(const Duration(seconds: 2));
      expect(speech.calls.length, 1);
      expect(find.byKey(const Key('rhyme_hear_all')), findsOneWidget);
    });

    testWidgets('game is gated until the rhyme is heard', (tester) async {
      await _pumpRhyme(tester, _r('rhyme-en-004'));
      FilledButton button() => tester
          .widget<FilledButton>(find.byKey(const Key('rhyme_try_button')));
      expect(button().onPressed, isNull);
      expect(find.byKey(const Key('rhyme_try_hint')), findsOneWidget);
      await tester.tap(find.byKey(const Key('rhyme_hear_all')));
      await tester.pump();
      expect(button().onPressed, isNotNull);
      expect(find.byKey(const Key('rhyme_try_hint')), findsNothing);
      await tester.tap(find.byKey(const Key('rhyme_stop')));
      await tester.pump();
    });

    testWidgets('right, wrong, retry; no answer before answering; no stars', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final rhyme = _r('rhyme-en-001');
      final item = rhyme.items.single;
      final full = rhyme.lines[item.lineIndex].text;
      final c = await _pumpRhyme(tester, rhyme);
      await _hearAndOpenGame(tester);
      expect(c.rhymeProgressFor(rhyme.id).heard, isTrue);
      expect(find.text(full), findsNothing);
      expect(find.bySemanticsLabel(full), findsNothing);
      expect(find.textContaining('____'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('____')), findsOneWidget);
      expect(find.byKey(const Key('rhyme_feedback')), findsNothing);

      Finder optionFor(String word) =>
          find.byWidgetPredicate((w) => w is Text && w.data == word);
      final wrong = item.options.firstWhere((o) => o != item.answer);
      await tester.tap(optionFor(wrong));
      await tester.pump();
      expect(find.byKey(const Key('rhyme_feedback')), findsOneWidget);
      expect(find.text(full), findsNothing,
          reason: 'wrong answer reveals nothing');
      expect(c.rhymeProgressFor(rhyme.id).done, isFalse);
      // Retry the same wrong word again, then the right one.
      await tester.tap(optionFor(wrong));
      await tester.pump();
      final stars = c.activeProfile!.stars;
      await tester.tap(optionFor(item.answer));
      await tester.pump();
      expect(find.text(full), findsOneWidget);
      expect(find.byKey(const Key('rhyme_revealed_line')), findsOneWidget);
      expect(find.textContaining('Well done'), findsOneWidget);
      expect(c.rhymeProgressFor(rhyme.id).done, isTrue);
      expect(c.activeProfile!.stars, stars);
      expect(c.activeProgress.completedLessons, isEmpty);
      handle.dispose();
    });

    for (final rhyme in _library.rhymes) {
      testWidgets(
        'options of ${rhyme.id} are shuffled, answer never in slot 0; hidden fields honoured',
        (tester) async {
          final c = await _pumpRhyme(tester, rhyme);
          await _hearAndOpenGame(tester);
          final item = rhyme.items.first;
          final shown = [
            for (var i = 0; i < item.options.length; i++)
              _labelOf(tester, find.byKey(Key('rhyme_option_$i'))),
          ];
          expect(shown.toSet(), item.options.toSet());
          expect(shown.first, isNot(item.answer));
          expect(shown, isNot(equals(item.options)));
          expect(c.rhymeProgressFor(rhyme.id).heard, isTrue);
          // meaning_en and the picture concept stay off screen in the game.
          for (final line in rhyme.lines) {
            if (line.meaningEn != null) {
              expect(find.textContaining(line.meaningEn!), findsNothing);
            }
          }
          if (rhyme.pictureConcept.isNotEmpty) {
            expect(find.textContaining(rhyme.pictureConcept), findsNothing);
          }
          if (rhyme.hideTitleDuringActivity) {
            expect(find.byKey(const Key('rhyme_title')), findsNothing);
            expect(find.text(rhyme.title), findsNothing);
            expect(find.byKey(const Key('rhyme_title_hidden')), findsOneWidget);
          } else {
            expect(find.byKey(const Key('rhyme_title')), findsOneWidget);
          }
          // Back on the rhyme the title is shown again.
          await tester.tap(find.byKey(const Key('rhyme_back')));
          await tester.pump();
          expect(find.byKey(const Key('rhyme_title')), findsOneWidget);
        },
      );
    }

    testWidgets('same seed gives the same order', (tester) async {
      final rhyme = _r('rhyme-en-001');
      List<String> order() => [
            for (var i = 0; i < 3; i++)
              _labelOf(tester, find.byKey(Key('rhyme_option_$i'))),
          ];
      await _pumpRhyme(tester, rhyme);
      await _hearAndOpenGame(tester);
      final a = order();
      await tester.pumpWidget(const SizedBox());
      await _pumpRhyme(tester, rhyme);
      await _hearAndOpenGame(tester);
      expect(order(), a);
    });

    testWidgets(
        'voice unavailable: friendly notice, no rhyme text, game still opens', (
      tester,
    ) async {
      final rhyme = _r('rhyme-hi-001');
      await _pumpRhyme(tester, rhyme, speech: _FakeSpeech(supported: false));
      await tester.tap(find.byKey(const Key('rhyme_line_0')));
      await tester.pumpAndSettle();
      expect(find.text('Voice unavailable'), findsOneWidget);
      expect(find.textContaining('Hindi voice'), findsOneWidget);
      for (final l in rhyme.lines) {
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.textContaining(l.text),
          ),
          findsNothing,
        );
      }
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('rhyme_voice_missing')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('rhyme_try_button')))
            .onPressed,
        isNotNull,
      );
    });
  });

  group('layouts', () {
    const sizes = <Size>[
      Size(360, 800),
      Size(390, 844),
      Size(800, 1280),
      Size(1024, 768),
      Size(800, 360),
    ];
    for (final size in sizes) {
      for (final scale in [1.0, 1.6]) {
        final tag = '${size.width.toInt()}x${size.height.toInt()} text $scale';
        testWidgets('list fits at $tag', (tester) async {
          for (final lang in rhymeLanguages) {
            await _pumpList(tester, size: size, scale: scale);
            await tester.tap(find.byKey(Key('rhyme_filter_$lang')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            for (final s
                in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
              expect(s.position.maxScrollExtent, lessThan(1));
            }
            final first = _library.forLanguage(lang).first;
            final rect =
                tester.getRect(find.byKey(Key('rhyme_card_${first.id}')));
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.bottom, lessThanOrEqualTo(size.height));
            expect(rect.right, lessThanOrEqualTo(size.width));
          }
        });
        for (final id in ['rhyme-en-006', 'rhyme-te-001', 'rhyme-hi-001']) {
          testWidgets('$id fits at $tag (both stages)', (tester) async {
            await _pumpRhyme(tester, _r(id), size: size, scale: scale);
            expect(tester.takeException(), isNull);
            final rect = tester.getRect(find.byKey(const Key('rhyme_line_0')));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.width));
            if (scale <= 1.3) {
              final b = tester.getRect(find.byKey(const Key('rhyme_hear_all')));
              expect(b.bottom, lessThanOrEqualTo(size.height));
              expect(b.top, greaterThanOrEqualTo(0));
            }
            await _hearAndOpenGame(tester);
            expect(tester.takeException(), isNull);
            final o = tester.getRect(find.byKey(const Key('rhyme_option_0')));
            expect(o.right, lessThanOrEqualTo(size.width));
            if (scale <= 1.3) {
              expect(o.bottom, lessThanOrEqualTo(size.height));
            }
          });
        }
      }
    }
  });

  group('home entry', () {
    const sizes = <Size>[
      Size(360, 800),
      Size(390, 844),
      Size(640, 360),
      Size(800, 360),
      Size(960, 540),
      Size(1280, 800),
    ];
    for (final size in sizes) {
      for (final scale in [1.0, 1.6]) {
        testWidgets(
          'Rhymes button is visible, 48dp+, no overflow at ${size.width.toInt()}x${size.height.toInt()} text $scale',
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
            final rect = tester.getRect(find.byKey(const Key('rhymes_button')));
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.width));
            expect(rect.bottom, lessThanOrEqualTo(size.height));
            expect(find.byTooltip('Rhymes'), findsWidgets);
            expect(find.byKey(const Key('level_button')), findsOneWidget);
            expect(find.byTooltip('Rewards'), findsWidgets);
            expect(find.byTooltip('Parents'), findsWidgets);
          },
        );
      }
    }

    testWidgets('tapping Rhymes opens the list', (tester) async {
      await _view(tester, const Size(960, 540), 1.0);
      await tester.pumpWidget(
        AppScope(
          controller: _controller(),
          child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rhymes_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(RhymesListScreen), findsOneWidget);
      expect(find.byKey(const Key('rhyme_filter_english')), findsOneWidget);
    });
  });
}
