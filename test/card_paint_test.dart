import 'dart:ui' as ui;

import 'package:aksharamala/src/app.dart';
import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/screens/home_screen.dart';
import 'package:aksharamala/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrastWithWhite(int r, int g, int b) {
  final lum = Color.fromARGB(255, r, g, b).computeLuminance();
  return 1.05 / (lum + 0.05);
}

void main() {
  testWidgets(
    'every world card actually paints a dark enough gradient behind its white text',
    (tester) async {
      final controller = AppController();
      const profile = ChildProfile(
        id: 'test',
        name: 'Asha',
        age: 4,
        avatar: '🦁',
      );
      controller
        ..profiles = [profile]
        ..progress = {'test': ProgressRecord.empty()}
        ..activeProfile = profile
        ..loaded = true;
      final boundaryKey = GlobalKey();
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(411, 1700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: AppScope(
            controller: controller,
            child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = (await tester.runAsync(
        () => boundary.toImage(pixelRatio: 1),
      ))!;
      final data = (await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      final scaleX = image.width / boundary.size.width;
      final scaleY = image.height / boundary.size.height;

      final weak = <String>[];
      for (final world in curriculum) {
        final rect = tester.getRect(find.byKey(Key('world_${world.id}')));
        // Sample two points inside the opaque lower text panel.
        for (final p in [
          Offset(rect.left + 40, rect.top + rect.height * .65),
          Offset(rect.right - 40, rect.bottom - 30),
        ]) {
          final px = (p.dx * scaleX).round().clamp(0, image.width - 1);
          final py = (p.dy * scaleY).round().clamp(0, image.height - 1);
          final i = ((py * image.width) + px) * 4;
          final ratio = _contrastWithWhite(
            data.getUint8(i),
            data.getUint8(i + 1),
            data.getUint8(i + 2),
          );
          if (ratio < 4.5) {
            weak.add(
              '${world.id} at ${p.dx.round()},${p.dy.round()} contrast ${ratio.toStringAsFixed(2)}',
            );
          }
        }
      }
      expect(weak, isEmpty, reason: weak.join('\n'));
    },
  );
}
