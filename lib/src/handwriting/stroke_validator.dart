/// Judges whether a child's strokes really write a glyph, using the glyph's
/// [StrokeTemplate]. It is a shape check, not a recogniser: it needs the right
/// number of strokes, in the right order, in the right direction, each close to
/// the template. A scribble, a dot or a straight line fails.
library;

import 'dart:math' as math;

import 'stroke_template.dart';

enum StrokeProblem {
  /// Nothing was drawn (or only dots).
  nothing,

  /// Fewer strokes than the glyph needs: unfinished.
  tooFewStrokes,

  /// More strokes than the glyph needs: scribbling or over-writing.
  tooManyStrokes,

  /// A stroke has the right shape but belongs earlier or later.
  wrongOrder,

  /// A stroke has the right shape but was drawn the wrong way round.
  wrongDirection,

  /// A stroke does not follow the glyph's shape.
  wrongShape,

  /// A stroke is far too long or too short for its shape (scribbling).
  wrongLength,
}

class StrokeCheck {
  const StrokeCheck({
    required this.problem,
    this.badStroke,
    this.meanError = 0,
    this.strokesDrawn = 0,
  });

  /// Null when the glyph was written correctly.
  final StrokeProblem? problem;

  /// Index (in the child's strokes) of the first stroke that is wrong.
  final int? badStroke;

  /// Mean distance from the template, in unit-square units (0 = perfect).
  final double meanError;

  final int strokesDrawn;

  bool get passed => problem == null;
}

class StrokeValidator {
  const StrokeValidator({
    this.guidedTolerance = 0.11,
    this.independentTolerance = 0.16,
    this.maxFactor = 2.4,
    this.maxAspectChange = 1.7,
    this.minLengthRatio = 0.55,
    this.maxLengthRatio = 1.8,
    this.minStrokeLength = 0.06,
    this.samples = 24,
  });

  /// Mean allowed distance from the template.
  final double guidedTolerance;
  final double independentTolerance;

  /// No single point may stray further than tolerance times this.
  final double maxFactor;

  /// Independent writing: how far the figure's width/height may differ from the
  /// template's.
  final double maxAspectChange;

  final double minLengthRatio;
  final double maxLengthRatio;

  /// Shorter than this (in unit-square units) is a dot, not a stroke.
  final double minStrokeLength;
  final int samples;

  StrokeCheck check(
    StrokeTemplate template,
    List<Stroke> drawn, {
    WritingMode mode = WritingMode.guided,
  }) {
    final child = [
      for (final s in drawn)
        if (s.length >= 2 && pathLength(s) >= minStrokeLength) s,
    ];
    if (child.isEmpty) {
      return const StrokeCheck(problem: StrokeProblem.nothing);
    }
    final want = template.strokes;
    if (child.length < want.length) {
      return StrokeCheck(
        problem: StrokeProblem.tooFewStrokes,
        strokesDrawn: child.length,
      );
    }
    if (child.length > want.length) {
      return StrokeCheck(
        problem: StrokeProblem.tooManyStrokes,
        badStroke: want.length,
        strokesDrawn: child.length,
      );
    }

    var tmpl = want;
    var kid = child;
    var tol = guidedTolerance;
    if (mode == WritingMode.independent) {
      tol = independentTolerance;
      // Without a guide, size is free but proportions are not: a tall thin
      // "1" is not a wide "7".
      final wantAspect = _aspect([...want.expand((s) => s)]);
      final childAspect = _aspect([...child.expand((s) => s)]);
      final ratio = childAspect / wantAspect;
      if (ratio < 1 / maxAspectChange || ratio > maxAspectChange) {
        return StrokeCheck(
          problem: StrokeProblem.wrongShape,
          badStroke: 0,
          strokesDrawn: child.length,
        );
      }
      final box = FitBox.of([...want.expand((s) => s)]);
      tmpl = [for (final s in want) box.normalise(s)];
      final kidBox = FitBox.of([...child.expand((s) => s)]);
      kid = [for (final s in child) kidBox.normalise(s)];
    }

    final tr = [for (final s in tmpl) resample(s, samples)];
    final kr = [for (final s in kid) resample(s, samples)];

    var errorSum = 0.0;
    for (var i = 0; i < kr.length; i++) {
      final forward = _meanAndMax(kr[i], tr[i]);
      final lengthRatio = pathLength(kid[i]) / pathLength(tmpl[i]);
      final fits = forward.mean <= tol && forward.max <= tol * maxFactor;
      if (fits) {
        if (lengthRatio < minLengthRatio || lengthRatio > maxLengthRatio) {
          return StrokeCheck(
            problem: StrokeProblem.wrongLength,
            badStroke: i,
            meanError: forward.mean,
            strokesDrawn: kr.length,
          );
        }
        errorSum += forward.mean;
        continue;
      }
      // Does it fit the same stroke written backwards?
      final back = _meanAndMax(kr[i], tr[i].reversed.toList());
      if (back.mean <= tol && back.max <= tol * maxFactor) {
        return StrokeCheck(
          problem: StrokeProblem.wrongDirection,
          badStroke: i,
          meanError: back.mean,
          strokesDrawn: kr.length,
        );
      }
      // Does it fit a different stroke of the glyph (wrong order)?
      for (var j = 0; j < tr.length; j++) {
        if (j == i) continue;
        final other = _meanAndMax(kr[i], tr[j]);
        if (other.mean <= tol && other.max <= tol * maxFactor) {
          return StrokeCheck(
            problem: StrokeProblem.wrongOrder,
            badStroke: i,
            meanError: other.mean,
            strokesDrawn: kr.length,
          );
        }
      }
      return StrokeCheck(
        problem: StrokeProblem.wrongShape,
        badStroke: i,
        meanError: forward.mean,
        strokesDrawn: kr.length,
      );
    }
    return StrokeCheck(
      problem: null,
      meanError: errorSum / kr.length,
      strokesDrawn: kr.length,
    );
  }

  /// Width over height of everything drawn, with a floor so a thin upright
  /// stroke still has a sensible shape.
  double _aspect(List<Pt> pts) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in pts) {
      minX = math.min(minX, p.x);
      minY = math.min(minY, p.y);
      maxX = math.max(maxX, p.x);
      maxY = math.max(maxY, p.y);
    }
    return math.max(maxX - minX, 0.12) / math.max(maxY - minY, 0.12);
  }

  ({double mean, double max}) _meanAndMax(Stroke a, Stroke b) {
    var sum = 0.0;
    var max = 0.0;
    for (var k = 0; k < a.length; k++) {
      final d = a[k].distanceTo(b[k]);
      sum += d;
      if (d > max) max = d;
    }
    return (mean: sum / a.length, max: max);
  }
}

/// Fits a figure into the unit square, keeping its proportions and centring it.
class FitBox {
  FitBox(this.minX, this.minY, this.scale, this.offX, this.offY);

  factory FitBox.of(List<Pt> pts) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in pts) {
      minX = math.min(minX, p.x);
      minY = math.min(minY, p.y);
      maxX = math.max(maxX, p.x);
      maxY = math.max(maxY, p.y);
    }
    final w = maxX - minX;
    final h = maxY - minY;
    final size = math.max(math.max(w, h), 1e-6);
    return FitBox(minX, minY, 1 / size, (1 - w / size) / 2, (1 - h / size) / 2);
  }

  final double minX;
  final double minY;
  final double scale;
  final double offX;
  final double offY;

  Stroke normalise(Stroke s) => [
        for (final p in s)
          Pt((p.x - minX) * scale + offX, (p.y - minY) * scale + offY),
      ];
}
