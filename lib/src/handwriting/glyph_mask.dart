/// Shape check for glyphs that have no stroke template yet.
///
/// The glyph is drawn once from the real font into a [GlyphMask] (a grid of
/// "ink here" cells, see glyph_mask_raster.dart). The child's strokes must
/// cover the glyph and stay on it. This proves the child drew *this shape*, so
/// a scribble or a random line fails. It cannot know stroke order or direction,
/// so it never awards mastery: that needs a verified [StrokeTemplate].
library;

import 'dart:math' as math;

import 'stroke_template.dart';
import 'stroke_validator.dart' show FitBox;

class GlyphMask {
  GlyphMask(this.size, this.cells)
      : assert(cells.length == size * size, 'cells must be size x size');

  /// Cells per side; the mask covers the unit square.
  final int size;

  /// Row-major, true where the glyph has ink.
  final List<bool> cells;

  bool at(int x, int y) => cells[y * size + x];

  int get inkCount => cells.where((c) => c).length;

  /// Centres of the inked cells, in the unit square.
  List<Pt> get points => [
        for (var y = 0; y < size; y++)
          for (var x = 0; x < size; x++)
            if (at(x, y)) Pt((x + .5) / size, (y + .5) / size),
      ];

  /// A mask built from a picture of ASCII art, for tests ('#' is ink).
  factory GlyphMask.fromRows(List<String> rows) {
    final n = rows.length;
    return GlyphMask(n, [
      for (final r in rows)
        for (var i = 0; i < n; i++) i < r.length && r[i] == '#',
    ]);
  }
}

enum MaskProblem {
  nothing,

  /// Parts of the glyph were never covered.
  incomplete,

  /// Ink strays away from the glyph.
  offShape,

  /// Far more ink than the glyph needs (colouring in or scribbling).
  tooMuchInk,
}

class MaskCheck {
  const MaskCheck({
    required this.problem,
    this.coverage = 0,
    this.precision = 0,
  });

  final MaskProblem? problem;

  /// Share of the glyph's ink cells the child covered (0..1).
  final double coverage;

  /// Share of the child's ink that lies on the glyph (0..1).
  final double precision;

  bool get passed => problem == null;
}

class MaskValidator {
  const MaskValidator({
    this.reach = 0.075,
    this.minCoverage = 0.72,
    this.minPrecision = 0.85,
    this.maxInkRatio = 3.0,
    this.strokeWidth = 0.08,
  });

  /// How far (unit square) ink may be from a cell and still count as on it.
  final double reach;
  final double minCoverage;
  final double minPrecision;

  /// Most ink length allowed, as a multiple of the glyph's own length.
  final double maxInkRatio;

  /// Typical stroke thickness of the glyph, used to estimate its length.
  final double strokeWidth;

  MaskCheck check(
    GlyphMask mask,
    List<Stroke> drawn, {
    WritingMode mode = WritingMode.guided,
  }) {
    final strokes = [
      for (final s in drawn)
        if (s.length >= 2 && pathLength(s) >= 0.04) s,
    ];
    if (strokes.isEmpty) return const MaskCheck(problem: MaskProblem.nothing);

    var glyph = mask.points;
    if (glyph.isEmpty) return const MaskCheck(problem: MaskProblem.nothing);
    var ink = <Pt>[
      for (final s in strokes)
        ...resample(s, math.max(8, (pathLength(s) / 0.012).ceil())),
    ];
    var inkLength = strokes.fold<double>(0, (n, s) => n + pathLength(s));

    var reachNow = reach;
    if (mode == WritingMode.independent) {
      final gBox = FitBox.of(glyph);
      final kBox = FitBox.of(ink);
      glyph = [
        for (final p in glyph)
          Pt((p.x - gBox.minX) * gBox.scale + gBox.offX,
              (p.y - gBox.minY) * gBox.scale + gBox.offY),
      ];
      ink = [
        for (final p in ink)
          Pt((p.x - kBox.minX) * kBox.scale + kBox.offX,
              (p.y - kBox.minY) * kBox.scale + kBox.offY),
      ];
      inkLength *= kBox.scale;
      reachNow = reach * 1.25;
    }

    final covered =
        glyph.where((g) => ink.any((i) => i.distanceTo(g) <= reachNow)).length;
    final onShape =
        ink.where((i) => glyph.any((g) => g.distanceTo(i) <= reachNow)).length;
    final coverage = covered / glyph.length;
    final precision = onShape / ink.length;

    // Glyph length is roughly its area divided by the pen thickness.
    final cell = 1.0 / mask.size;
    final glyphLength = mask.inkCount * cell * cell / strokeWidth;
    final tooMuch = inkLength > glyphLength * maxInkRatio &&
        inkLength > 0.5; // never judge a tiny glyph by length alone

    MaskProblem? problem;
    if (precision < minPrecision) {
      problem = MaskProblem.offShape;
    } else if (coverage < minCoverage) {
      problem = MaskProblem.incomplete;
    } else if (tooMuch) {
      problem = MaskProblem.tooMuchInk;
    }
    return MaskCheck(
        problem: problem, coverage: coverage, precision: precision);
  }
}
