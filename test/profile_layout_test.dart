import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/home_screen.dart';
import 'package:aksharamala/src/screens/profile_screen.dart';
import 'package:aksharamala/src/services/local_store.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:aksharamala/src/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Saving is real file IO, which never completes inside a widget test.
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

AppController _controller({List<ChildProfile> profiles = const []}) {
  final result = AppController(store: _NoDiskStore());
  return result
    ..profiles = [...profiles]
    ..progress = {for (final p in profiles) p.id: ProgressRecord.empty()}
    ..activeProfile = profiles.isEmpty ? null : profiles.first
    ..loaded = true;
}

const _saved = [
  ChildProfile(id: 'a', name: 'Ananya', age: 4, avatar: 'lion'),
  ChildProfile(
    id: 'b',
    name: 'Venkata Subrahmanyam Reddy',
    age: 7,
    avatar: 'panda',
  ),
  ChildProfile(id: 'c', name: 'Kabir', age: 11, avatar: '🦄'),
];

Future<void> _show(
  WidgetTester tester,
  Size size, {
  double scale = 1.0,
  EdgeInsets safe = EdgeInsets.zero,
  AppController? controller,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size
    ..padding = FakeViewPadding(
      left: safe.left,
      top: safe.top,
      right: safe.right,
      bottom: safe.bottom,
    )
    ..viewPadding = FakeViewPadding(
      left: safe.left,
      top: safe.top,
      right: safe.right,
      bottom: safe.bottom,
    );
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  // Start from an empty tree so repeated calls never stack screens.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    AppScope(
      controller: controller ?? _controller(profiles: _saved),
      child: MaterialApp(theme: buildTheme(), home: const ProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// The tick inside a level tile: shows which level is chosen.
Finder _ticked(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byIcon(Icons.check_circle_rounded),
    );

void main() {
  for (final size in _sizes) {
    for (final scale in [1.0, 1.3]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()} text $scale';

      testWidgets('profile screen fits with no overflow at $tag', (
        tester,
      ) async {
        await _show(tester, size, scale: scale);
        expect(tester.takeException(), isNull);

        // Create & Play is fully on screen and large enough to tap.
        final create = tester.getRect(find.byKey(const Key('create_profile')));
        expect(create.height, greaterThanOrEqualTo(48));
        expect(create.top, greaterThanOrEqualTo(0));
        expect(create.bottom, lessThanOrEqualTo(size.height));
        expect(create.right, lessThanOrEqualTo(size.width));

        // All six avatars are visible, in one row, and each is a real target.
        final rects = [
          for (final v in GameAvatar.options)
            tester.getRect(find.byKey(Key('avatar_$v'))),
        ];
        for (final r in rects) {
          expect(r.width, greaterThanOrEqualTo(48));
          expect(r.height, greaterThanOrEqualTo(48));
          expect(r.top, greaterThanOrEqualTo(0));
          expect(r.bottom, lessThanOrEqualTo(size.height));
          expect(r.right, lessThanOrEqualTo(size.width));
        }
        expect(rects.map((r) => r.top.round()).toSet().length, 1);

        // Level tiles are big enough for a thumb and all four are on screen.
        for (final key in ['level_1', 'level_2', 'level_3', 'level_4']) {
          final r = tester.getRect(find.byKey(Key(key)));
          expect(r.width, greaterThanOrEqualTo(44), reason: key);
          expect(r.height, greaterThanOrEqualTo(44), reason: key);
          expect(r.bottom, lessThanOrEqualTo(size.height));
          expect(r.right, lessThanOrEqualTo(size.width));
        }

        // Nothing is hidden behind (or scrolled under) Create & Play: every
        // field ends above the button, so no scrolling is needed to use them.
        final above = [
          ...rects,
          tester.getRect(find.byKey(const Key('profile_name'))),
          for (final k in ['level_1', 'level_2', 'level_3', 'level_4'])
            tester.getRect(find.byKey(Key(k))),
        ];
        for (final r in above) {
          expect(r.bottom, lessThanOrEqualTo(create.top + 0.5),
              reason: 'field $r above Create');
        }
        // And a tap at the middle of each really reaches it.
        await tester.tap(find.byKey(const Key('level_2')));
        await tester.pump();
        expect(_ticked('level_2'), findsOneWidget);
      });

      testWidgets('saved-profile descriptions are not cut off at $tag', (
        tester,
      ) async {
        await _show(tester, size, scale: scale);
        expect(tester.takeException(), isNull);
        for (final text in [
          'Level 1 • ${_saved[0].stage.label}',
          'Level 3 • ${_saved[1].stage.label}',
          'Level 4 • ${_saved[2].stage.label}',
        ]) {
          // The crew panel scrolls, so bring each tile into view first.
          await tester.scrollUntilVisible(
            find.text(text),
            80,
            scrollable: find.byType(Scrollable).first,
          );
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(text),
          );
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: '"$text" is truncated',
          );
        }
      });
    }
  }

  testWidgets('no profiles yet: empty crew panel still fits at 640x360', (
    tester,
  ) async {
    await _show(tester, _sizes.first, controller: _controller());
    expect(tester.takeException(), isNull);
    final create = tester.getRect(find.byKey(const Key('create_profile')));
    expect(create.bottom, lessThanOrEqualTo(360));
  });

  testWidgets('respects notch and gesture-bar insets in landscape', (
    tester,
  ) async {
    const safe = EdgeInsets.fromLTRB(48, 24, 48, 16);
    for (final size in _sizes) {
      await _show(tester, size, safe: safe);
      expect(tester.takeException(), isNull);
      final create = tester.getRect(find.byKey(const Key('create_profile')));
      expect(create.left, greaterThanOrEqualTo(safe.left));
      expect(create.right, lessThanOrEqualTo(size.width - safe.right));
      expect(create.bottom, lessThanOrEqualTo(size.height - safe.bottom));
      final first = tester.getRect(find.byKey(const Key('avatar_lion')));
      expect(first.top, greaterThanOrEqualTo(safe.top));
      // With 96 dp lost to the notch, all six avatars still fit side by side
      // with targets of at least 44 dp (the WCAG minimum).
      for (final v in GameAvatar.options) {
        final r = tester.getRect(find.byKey(Key('avatar_$v')));
        expect(r.width, greaterThanOrEqualTo(44), reason: '$v at $size');
        expect(r.right, lessThanOrEqualTo(size.width - safe.right));
        expect(r.bottom, lessThanOrEqualTo(create.top + 0.5));
      }
    }
  });

  testWidgets('portrait width stacks the panels and still scrolls to Create', (
    tester,
  ) async {
    await _show(tester, const Size(411, 800));
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const Key('create_profile')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('create_profile')), findsOneWidget);
  });

  testWidgets('selected avatar shows a ring, a check and is announced', (
    tester,
  ) async {
    await _show(tester, const Size(960, 540));
    final handle = tester.ensureSemantics();
    // Lion is selected by default; panda is not.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('avatar_lion'))),
      isSemantics(
        label: 'lion avatar',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
      ),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('avatar_panda'))),
      isSemantics(
        label: 'panda avatar',
        isButton: true,
        isSelected: false,
        hasSelectedState: true,
      ),
    );
    await tester.tap(find.byKey(const Key('avatar_panda')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    // The first AnimatedContainer inside the choice is the selection ring
    // (the avatar artwork inside has its own).
    final ring = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byKey(const Key('avatar_panda')),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final border = (ring.decoration! as BoxDecoration).border! as Border;
    expect(border.top.width, 3);
    expect(border.top.color, const Color(0xFF4B3DBA));
    handle.dispose();
  });

  testWidgets('any level can be chosen, in any order, with no lock', (
    tester,
  ) async {
    await _show(tester, const Size(800, 360));
    // Level 1 (ages 3-4) is the starting choice.
    expect(_ticked('level_1'), findsOneWidget);
    for (final level in [4, 2, 3, 1]) {
      await tester.tap(find.byKey(Key('level_$level')));
      await tester.pump();
      expect(_ticked('level_$level'), findsOneWidget);
      // Only one level is chosen at a time.
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    }
    // There is no age control any more.
    expect(find.byKey(const Key('age_up')), findsNothing);
    expect(find.byKey(const Key('age_down')), findsNothing);
  });

  testWidgets('creating a profile still saves it and opens the home screen', (
    tester,
  ) async {
    final controller = _controller();
    await _show(tester, const Size(800, 360), controller: controller);
    await tester.tap(find.byKey(const Key('avatar_tiger')));
    await tester.tap(find.byKey(const Key('level_2')));
    await tester.enterText(find.byKey(const Key('profile_name')), 'Meera');
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_profile')));
    await tester.pumpAndSettle();
    expect(controller.profiles.single.name, 'Meera');
    expect(controller.profiles.single.avatar, 'tiger');
    expect(controller.profiles.single.age, 6);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('an empty name asks for one and does not save', (tester) async {
    final controller = _controller();
    await _show(tester, const Size(800, 360), controller: controller);
    await tester.tap(find.byKey(const Key('create_profile')));
    await tester.pumpAndSettle();
    expect(find.text('What is your name?'), findsOneWidget);
    expect(controller.profiles, isEmpty);
  });

  testWidgets('tapping a saved learner selects it and opens the home screen', (
    tester,
  ) async {
    final controller = _controller(profiles: _saved);
    await _show(tester, const Size(960, 540), controller: controller);
    await tester.tap(find.byKey(const Key('profile_b')));
    await tester.pumpAndSettle();
    expect(controller.activeProfile?.id, 'b');
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
