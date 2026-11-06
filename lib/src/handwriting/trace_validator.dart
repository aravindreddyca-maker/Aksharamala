/// Judges a child tracing a letter on top of its guide.
///
/// Beginner tracing is about drawing the letter's SHAPE, so this check does not
/// care how the child got there: one unbroken movement or many, any starting
/// point, any direction, any stroke order. It asks only whether the pooled ink
///
///  1. covers the letter (coverage of the whole shape),
///  2. covers every essential part of it (each template stroke on its own),
///  3. stays on the letter, within a child-sized tolerance (accuracy), and
///  4. is not a scribble (far more ink than the letter needs).
///
/// A dot, a stray line, a half letter or a scribble fails. Pure Dart.
library;

import 'stroke_template.dart';
import 'stroke_validator.dart' show StrokeCheck, StrokeProblem;

class TraceValidator {
  const TraceValidator({
    this.reach = 0.09,
    this.driftReach = 0.12,
    this.minCoverage = 0.82,
    this.minPartCoverage = 0.62,
    this.minPrecision = 0.8,
    this.maxInkRatio = 3.2,
    this.minStrokeLength = 0.03,
  });

  /// How close (unit square) ink must come to a point of the letter to cover it.
  final double reach;

  /// How far ink may be from the letter and still count as on it.
  final double driftReach;

  /// Share of the whole letter that must be covered.
  final double minCoverage;

  /// Share of every single stroke of the letter that must be covered, so a
  /// missing bar or tail cannot hide behind the rest of the letter.
  final double minPartCoverage;

  /// Share of the child's ink that must lie on the letter.
  final double minPrecision;

  /// Most ink allowed, as a multiple of the letter's own length.
  final double maxInkRatio;

  /// Shorter than this is a dot, not part of a movement.
  final double minStrokeLength;

  StrokeCheck check(StrokeTemplate template, List<Stroke> drawn) {
    final strokes = [
      for (final s in drawn)
        if (s.length >= 2 && pathLength(s) >= minStrokeLength) s,
    ];
    if (strokes.isEmpty) {
      return const StrokeCheck(problem: StrokeProblem.nothing);
    }
    final ink = <Pt>[
      for (final s in strokes) ...resample(s, _count(pathLength(s))),
    ];
    final inkLength = strokes.fold<double>(0, (n, s) => n + pathLength(s));

    final parts = [
      for (final s in template.strokes) resample(s, _count(pathLength(s))),
    ];
    final letterLength =
        template.strokes.fold<double>(0, (n, s) => n + pathLength(s));
    final all = [for (final p in parts) ...p];

    bool near(Pt p, List<Pt> to, double d) =>
        to.any((q) => q.distanceTo(p) <= d);

    var covered = 0;
    var weakest = 1.0;
    for (final part in parts) {
      final hit = part.where((p) => near(p, ink, reach)).length;
      covered += hit;
      final share = hit / part.length;
      if (share < weakest) weakest = share;
    }
    final coverage = covered / all.length;
    final onLetter = ink.where((p) => near(p, all, driftReach)).length;
    final precision = onLetter / ink.length;
    final scribble = inkLength > letterLength * maxInkRatio && inkLength > 0.5;

    StrokeProblem? problem;
    if (precision < minPrecision || scribble) {
      problem = StrokeProblem.wrongShape;
    } else if (coverage < minCoverage || weakest < minPartCoverage) {
      problem = StrokeProblem.tooFewStrokes;
    }
    return StrokeCheck(
      problem: problem,
      meanError: 1 - coverage,
      strokesDrawn: strokes.length,
    );
  }

  int _count(double length) => (length / 0.012).ceil().clamp(8, 400);
}
