import 'package:aksharamala/src/alphabet/alphabet_data.dart';
import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/handwriting/glyph_mask.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/alphabet_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Store extends LocalStore {
  @override
  Future<void> save(LocalSnapshot snapshot) async {}
}

AppController _controller() {
  const profile = ChildProfile(id: 'p', name: 'Meena', age: 4, avatar: 'lion');
  return AppController(store: _Store())
    ..profiles = [profile]
    ..progress = {'p': ProgressRecord.empty()}
    ..activeProfile = profile
    ..loaded = true;
}

void main() {
  for (final world in ['english', 'telugu', 'hindi', 'tamil']) {
    for (final size in const [
      Size(640, 360),
      Size(390, 844),
      Size(1280, 800),
      Size(800, 1280),
    ]) {
      testWidgets(
          '$world letters: every letter is reachable by pages at '
          '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = size;
        addTearDown(tester.view.reset);
        final set = alphabets[world]!;
        await tester.pumpWidget(
          AppScope(
            controller: _controller(),
            child: MaterialApp(
              theme: buildTheme(),
              home: AlphabetScreen(
                world: curriculum.firstWhere((w) => w.id == world),
                letters: set,
                maskLoader: (_) async => GlyphMask.fromRows(const ['##', '##']),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final seen = <int>{};
        for (var guard = 0; guard < 40; guard++) {
          expect(tester.takeException(), isNull, reason: '$world $size');
          for (var i = 0; i < set.letters.length; i++) {
            final f = find.byKey(Key('letter_tile_$i'));
            if (f.evaluate().isEmpty) continue;
            seen.add(i);
            final r = tester.getRect(f);
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(size.width));
            expect(r.bottom, lessThanOrEqualTo(size.height));
            expect(r.width, greaterThanOrEqualTo(60), reason: 'tappable');
          }
          final next = find.byKey(const Key('letters_next_page'));
          if (next.evaluate().isEmpty ||
              tester.widget<IconButton>(next).onPressed == null) {
            break;
          }
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
        expect(seen.length, set.letters.length, reason: '$world $size');
        for (final s in tester.stateList<ScrollableState>(
          find.byType(Scrollable),
        )) {
          expect(s.position.maxScrollExtent, lessThan(1));
        }
      });
    }
  }
}
