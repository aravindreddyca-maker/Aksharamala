import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../batch/batch_content.dart' show BatchText;
import '../batch/batch_lesson.dart' show WriteMode;
import '../handwriting/glyph_mask.dart';
import '../handwriting/glyph_mask_raster.dart';
import '../handwriting/handwriting_policy.dart';
import '../handwriting/stroke_template.dart';
import '../handwriting/stroke_validator.dart' show StrokeProblem;
import '../theme.dart';

/// A square writing pad that judges what the child draws with the shared
/// handwriting engine. Guided: the guide (stroke numbers and arrows for a
/// template, or the glyph itself) is shown. Independent: nothing is shown.
///
/// It reports each check through [onResult]; the pad itself never awards
/// anything, the [HandwritingPolicy] decides what an attempt is worth.
class WritingPad extends StatefulWidget {
  const WritingPad({
    required this.glyph,
    required this.mode,
    required this.text,
    required this.color,
    required this.onResult,
    super.key,
    this.template,
    this.mask,
    this.policy = const HandwritingPolicy(),
    this.locale = 'en-IN',
    this.padKey = const Key('writing_pad'),
    this.finish,
  });

  final String glyph;
  final WriteMode mode;
  final BatchText text;
  final Color color;
  final StrokeTemplate? template;

  /// The glyph drawn from the font; used when there is no template.
  final GlyphMask? mask;
  final HandwritingPolicy policy;
  final String locale;
  final ValueChanged<WritingResult> onResult;

  /// Key of the drawing surface (tests and the older tracing quests use it).
  final Key padKey;

  /// An extra button shown beside Clear and Check (the older tracing quests
  /// finish with it, once a letter has been accepted).
  final Widget? finish;

  @override
  State<WritingPad> createState() => _WritingPadState();
}

class _WritingPadState extends State<WritingPad> {
  final List<List<Offset>> _strokes = [];
  WritingResult? _result;
  Size _size = Size.zero;

  bool get _guided => widget.mode == WriteMode.guided;

  void _clear() => setState(() {
        _strokes.clear();
        _result = null;
      });

  void _check() {
    if (_size.isEmpty) return;
    final drawn = [
      for (final s in _strokes)
        [for (final o in s) Pt(o.dx / _size.width, o.dy / _size.height)],
    ];
    final result = widget.policy.judge(
      drawn: drawn,
      template: widget.template,
      mask: widget.mask,
      mode: _guided ? WritingMode.guided : WritingMode.independent,
    );
    setState(() => _result = result);
    widget.onResult(result);
  }

  String? get _message {
    final r = _result;
    if (r == null) return null;
    if (r.shapeOk) return widget.text.goodWriting;
    final p = r.stroke?.problem;
    return switch (p) {
      StrokeProblem.wrongDirection => widget.text.directionHint,
      StrokeProblem.wrongOrder => widget.text.orderHint,
      StrokeProblem.tooFewStrokes ||
      StrokeProblem.tooManyStrokes =>
        widget.text.strokesHint,
      _ => r.outcome == WritingOutcome.nothing
          ? widget.text.writeAgain
          : widget.text.strokeHint,
    };
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    final ok = _result?.shapeOk ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ok ? const Color(0xFF2E9D57) : widget.color,
                    width: ok ? 4 : 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      _size = Size(box.maxWidth, box.maxHeight);
                      return GestureDetector(
                        key: widget.padKey,
                        behavior: HitTestBehavior.opaque,
                        // Start the stroke at the finger's first touch, not
                        // where the drag was recognised a few pixels later,
                        // so the ink begins on the guide's start dot.
                        onPanDown: (d) => setState(() {
                          _result = null;
                          _strokes.add([d.localPosition]);
                        }),
                        onPanCancel: () => setState(() {
                          if (_strokes.isNotEmpty && _strokes.last.length < 2) {
                            _strokes.removeLast();
                          }
                        }),
                        onPanUpdate: (d) => setState(
                          () => _strokes.last.add(d.localPosition),
                        ),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _PadPainter(
                            strokes: _strokes,
                            guided: _guided,
                            glyph: widget.glyph,
                            template: widget.template,
                            ink: widget.color,
                            guideColor: widget.color.withValues(alpha: .13),
                            revision: _strokes.fold<int>(
                              _strokes.length,
                              (n, s) => n + s.length,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 22,
          child: message == null
              ? null
              : Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    key: const Key('writing_message'),
                    textAlign: TextAlign.center,
                    style: scriptStyle(
                      message,
                      TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ok
                            ? const Color(0xFF1B7A41)
                            : const Color(0xFF8A4B00),
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('write_clear'),
                onPressed: _strokes.isEmpty ? null : _clear,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Clear'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const Key('write_check'),
                onPressed: _strokes.isEmpty ? null : _check,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Check'),
              ),
            ),
            if (widget.finish != null) ...[
              const SizedBox(width: 10),
              Expanded(child: widget.finish!),
            ],
          ],
        ),
      ],
    );
  }
}

class _PadPainter extends CustomPainter {
  _PadPainter({
    required this.strokes,
    required this.guided,
    required this.glyph,
    required this.template,
    required this.ink,
    required this.guideColor,
    required this.revision,
  });

  final List<List<Offset>> strokes;
  final bool guided;
  final String glyph;
  final StrokeTemplate? template;
  final Color ink;
  final Color guideColor;
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    if (guided) {
      final t = template;
      if (t != null && t.isUsable) {
        _paintTemplate(canvas, size, t);
      } else {
        final tp = TextPainter(
          text: TextSpan(
            text: glyph,
            style: glyphStyle(size.height * glyphBoxFraction)
                .copyWith(color: guideColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas,
            Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
      }
    }
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(s.first, 6, Paint()..color = ink);
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final o in s.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  /// The "route map": the letter's outline, a dashed path along each stroke in
  /// the order it is written, an arrow showing the way, and a numbered dot
  /// where each stroke starts (1 in green, the others in blue).
  void _paintTemplate(Canvas canvas, Size size, StrokeTemplate t) {
    Offset at(Pt p) => Offset(p.x * size.width, p.y * size.height);
    // The letter as a wide, pale road drawn from the template itself, so the
    // route always sits exactly on it.
    final road = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.115
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in t.strokes) {
      final p = Path()..moveTo(at(s.first).dx, at(s.first).dy);
      for (final q in s.skip(1)) {
        p.lineTo(at(q).dx, at(q).dy);
      }
      canvas.drawPath(p, road);
    }
    final route = Paint()
      ..color = const Color(0xFF6B7280)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < t.strokes.length; i++) {
      final s = t.strokes[i];
      final path = Path()..moveTo(at(s.first).dx, at(s.first).dy);
      for (final p in s.skip(1)) {
        path.lineTo(at(p).dx, at(p).dy);
      }
      // Dashes along the whole stroke.
      for (final metric in path.computeMetrics()) {
        var d = 0.0;
        while (d < metric.length) {
          final end = math.min(d + 9, metric.length);
          canvas.drawPath(metric.extractPath(d, end), route);
          d += 16;
        }
      }
      // An arrowhead near the end, pointing the way the pen travels.
      final metric = path.computeMetrics().first;
      final tipAt = metric.length - 6;
      final tip = metric.getTangentForOffset(tipAt)!;
      final angle = math.atan2(tip.vector.dy, tip.vector.dx);
      final p = tip.position;
      final arrow = Path()
        ..moveTo(p.dx, p.dy)
        ..lineTo(
            p.dx - 12 * math.cos(angle - .5), p.dy - 12 * math.sin(angle - .5))
        ..lineTo(
            p.dx - 12 * math.cos(angle + .5), p.dy - 12 * math.sin(angle + .5))
        ..close();
      canvas.drawPath(arrow, Paint()..color = const Color(0xFF6B7280));
    }
    // Numbered start dots on top, so they are never hidden by a dash. Strokes
    // that start in the same place (B, D, P, R) get their dots set a little
    // way along the stroke, so every number can be read.
    final placed = <Offset>[];
    for (var i = 0; i < t.strokes.length; i++) {
      final s = t.strokes[i];
      var start = at(s.first);
      final next = at(s[math.min(3, s.length - 1)]);
      final dir = next - start;
      final unit = dir.distance == 0 ? Offset.zero : dir / dir.distance;
      var guard = 0;
      while (placed.any((o) => (o - start).distance < 26) && guard++ < 4) {
        start += unit * 24;
      }
      placed.add(start);
      canvas.drawCircle(
        start,
        13,
        Paint()
          ..color = i == 0 ? const Color(0xFF2E9D57) : const Color(0xFF2F7CF6),
      );
      final label = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, start - Offset(label.width / 2, label.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _PadPainter old) =>
      old.revision != revision ||
      old.guided != guided ||
      old.glyph != glyph ||
      old.template != template;
}
