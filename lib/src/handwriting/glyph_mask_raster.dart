/// Draws a glyph from the app's real font into a [GlyphMask]. The only part of
/// the handwriting engine that needs Flutter's drawing layer.
library;

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'glyph_mask.dart';

/// Where and how big a glyph is drawn inside the writing pad. The same numbers
/// are used to paint the guide on screen, so the mask and the guide agree.
const double glyphBoxFraction = 0.78;

TextStyle glyphStyle(double fontSize) => TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      height: 1.0,
      color: const Color(0xFF000000),
    );

/// Rasterises [glyph] centred in a [size] x [size] grid.
Future<GlyphMask> rasteriseGlyph(
  String glyph, {
  int size = 48,
  double scale = 4,
}) async {
  final side = size * scale;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, side, side));
  final painter = TextPainter(
    text: TextSpan(text: glyph, style: glyphStyle(side * glyphBoxFraction)),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    Offset((side - painter.width) / 2, (side - painter.height) / 2),
  );
  final image =
      await recorder.endRecording().toImage(side.round(), side.round());
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  if (data == null) return GlyphMask(size, List.filled(size * size, false));

  final px = side.round();
  final cells = List<bool>.filled(size * size, false);
  for (var cy = 0; cy < size; cy++) {
    for (var cx = 0; cx < size; cx++) {
      var ink = 0;
      for (var dy = 0; dy < scale; dy++) {
        for (var dx = 0; dx < scale; dx++) {
          final x = (cx * scale + dx).round();
          final y = (cy * scale + dy).round();
          final alpha = data.getUint8((y * px + x) * 4 + 3);
          if (alpha > 128) ink++;
        }
      }
      cells[cy * size + cx] = ink * 2 >= scale * scale;
    }
  }
  return GlyphMask(size, cells);
}
