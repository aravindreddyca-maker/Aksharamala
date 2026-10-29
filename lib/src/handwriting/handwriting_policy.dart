/// The one place that decides what a handwriting attempt is worth.
///
/// Rule: **mastery needs a verified stroke template and a passed stroke check.**
/// A shape that merely looks right earns encouragement, never mastery; so does
/// anything judged against an unverified template or only a glyph mask.
library;

import 'glyph_mask.dart';
import 'stroke_template.dart';
import 'stroke_validator.dart';

enum WritingOutcome {
  /// Nothing usable was drawn.
  nothing,

  /// Not the right shape yet; show a hint and let the child try again.
  tryAgain,

  /// The shape is right, but nothing has been verified by a teacher, so it
  /// counts as practice only.
  goodShape,

  /// Right shape, order and direction against a teacher-verified template.
  mastered,
}

class WritingResult {
  const WritingResult(this.outcome, {this.stroke, this.mask});

  final WritingOutcome outcome;
  final StrokeCheck? stroke;
  final MaskCheck? mask;

  bool get awardsMastery => outcome == WritingOutcome.mastered;

  /// The shape was accepted (practice or mastery).
  bool get shapeOk =>
      outcome == WritingOutcome.goodShape || outcome == WritingOutcome.mastered;
}

class HandwritingPolicy {
  const HandwritingPolicy({
    this.strokes = const StrokeValidator(),
    this.masks = const MaskValidator(),
  });

  final StrokeValidator strokes;
  final MaskValidator masks;

  /// Judge [drawn] for a glyph. [template] is used when there is one, else
  /// [mask] (the glyph drawn from the font). With neither, nothing can be judged
  /// and the result is [WritingOutcome.nothing].
  WritingResult judge({
    required List<Stroke> drawn,
    StrokeTemplate? template,
    GlyphMask? mask,
    WritingMode mode = WritingMode.guided,
  }) {
    if (template != null && template.isUsable) {
      final r = strokes.check(template, drawn, mode: mode);
      if (r.problem == StrokeProblem.nothing) {
        return WritingResult(WritingOutcome.nothing, stroke: r);
      }
      if (!r.passed) return WritingResult(WritingOutcome.tryAgain, stroke: r);
      return WritingResult(
        template.strokeOrderVerified
            ? WritingOutcome.mastered
            : WritingOutcome.goodShape,
        stroke: r,
      );
    }
    if (mask != null) {
      final r = masks.check(mask, drawn, mode: mode);
      if (r.problem == MaskProblem.nothing) {
        return WritingResult(WritingOutcome.nothing, mask: r);
      }
      return WritingResult(
        r.passed ? WritingOutcome.goodShape : WritingOutcome.tryAgain,
        mask: r,
      );
    }
    return const WritingResult(WritingOutcome.nothing);
  }
}
