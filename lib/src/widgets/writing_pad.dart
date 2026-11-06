import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../batch/batch_content.dart' show BatchText;
import '../batch/batch_lesson.dart' show WriteMode;
import '../handwriting/glyph_dots.dart';
import '../handwriting/glyph_mask.dart';
import '../handwriting/glyph_mask_raster.dart';
import '../handwriting/handwriting_policy.dart';
import '../handwriting/trace_validator.dart';
import '../handwriting/stroke_template.dart';
import '../handwriting/stroke_validator.dart' show StrokeProblem;
import '../theme.dart';

/// How strong the guide is for a glyph with no stroke template (small letters
/// and the Telugu, Hindi and Tamil letters, drawn from the font): an opacity of
/// the pad colour, clearly lighter than the child's ink (which is opaque), plus
/// an outline that thickens the thin font strokes a little.
/// Connect-the-dots guide for letters without a stroke template. Built and
/// working in code, but switched off until it has been checked on a device.
const bool showGuideDots = false;

/// A finished letter is accepted only when the child presses Check. (Set to
/// true to accept a correct letter the moment the finger lifts.)
const bool autoAcceptTracing = false;

const double nonTemplateGuideOpacity = .34;
const double nonTemplateGuideOutline = 1.5;

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
  GlyphMask? _dotsFor;
  List<Pt> _dots = const [];

  bool get _guided => widget.mode == WriteMode.guided;

  void _clear() => setState(() {
        _strokes.clear();
        _result = null;
      });

  /// Accepting a letter by itself needs more proof than the Check button: the
  /// whole letter, closely followed. A half letter never passes this, so no
  /// popup appears until the child has really finished.
  static const _defaultPolicy = HandwritingPolicy();
  static const _autoPolicy = HandwritingPolicy(
    trace: TraceValidator(
      reach: 0.07,
      minCoverage: 0.94,
      minPartCoverage: 0.85,
      minPrecision: 0.85,
    ),
    masks: MaskValidator(reach: 0.05, minCoverage: 0.93, minPrecision: 0.88),
  );

  /// What the Check button asks of a letter drawn from the font outline: the
  /// bold outline is wide, so a part of the letter must not pass as all of it.
  static const _checkPolicy = HandwritingPolicy(
    masks: MaskValidator(reach: 0.055, minCoverage: 0.85, minPrecision: 0.85),
  );

  /// Dots to connect for a letter drawn from the font (no stroke template):
  /// along the middle of the letter, worked out once per mask.
  List<Pt> get _guideDots {
    if (!showGuideDots) return const [];
    final mask = widget.mask;
    final hasRoute = widget.template?.isUsable ?? false;
    if (!_guided || hasRoute || mask == null) return const [];
    if (!identical(mask, _dotsFor)) {
      _dotsFor = mask;
      _dots = dotsFromMask(mask);
    }
    return _dots;
  }

  WritingResult? _judge({bool strict = false}) {
    if (_size.isEmpty) return null;
    final drawn = [
      for (final s in _strokes)
        [for (final o in s) Pt(o.dx / _size.width, o.dy / _size.height)],
    ];
    final policy = strict
        ? _autoPolicy
        : (_guided && identical(widget.policy, _defaultPolicy)
            ? _checkPolicy
            : widget.policy);
    return policy.judge(
      drawn: drawn,
      template: widget.template,
      mask: widget.mask,
      // Beginner tracing judges the finished shape only: one movement or many,
      // any start, direction or order. Independent writing stays strict.
      mode: _guided ? WritingMode.trace : WritingMode.independent,
    );
  }

  void _check() {
    final result = _judge();
    if (result == null) return;
    setState(() => _result = result);
    widget.onResult(result);
  }

  /// Whenever a finger lifts, a correctly finished letter is accepted at once.
  /// An unfinished or wrong one says nothing: the child keeps going, and the
  /// Check button still gives the hint.
  void _autoCheck() {
    if (!autoAcceptTracing || !_guided || _strokes.isEmpty) return;
    final result = _judge(strict: true);
    if (result == null || !result.shapeOk) return;
    setState(() => _result = result);
    widget.onResult(result);
  }

  void _penDown(Offset at) => setState(() {
        _result = null;
        _strokes.add([at]);
      });

  void _penMove(Offset at) {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.last.add(at));
  }

  void _penUp() => _autoCheck();

  void _penCancel() {
    if (_strokes.isNotEmpty && _strokes.last.length < 2) {
      setState(() => _strokes.removeLast());
    }
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
        _guided ? widget.text.strokeHint : widget.text.strokesHint,
      _ => r.outcome == WritingOutcome.nothing
          ? widget.text.writeAgain
          : widget.text.strokeHint,
    };
  }

  Widget _canvas(double side) {
    final ok = _result?.shapeOk ?? false;
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ok ? const Color(0xFF2E9D57) : widget.color,
                  width: ok ? 5 : 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: LayoutBuilder(
                  builder: (context, box) {
                    _size = Size(box.maxWidth, box.maxHeight);
                    // The ink is drawn by a recogniser that claims the touch
                    // the moment the finger lands, so a drag that starts on
                    // the pad draws and can never scroll the page.
                    return RawGestureDetector(
                      key: widget.padKey,
                      behavior: HitTestBehavior.opaque,
                      gestures: {
                        _InkRecognizer: GestureRecognizerFactoryWithHandlers<
                            _InkRecognizer>(
                          _InkRecognizer.new,
                          (r) => r
                            ..onDown = _penDown
                            ..onMove = _penMove
                            ..onUp = _penUp
                            ..onCancel = _penCancel,
                        ),
                      },
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _PadPainter(
                          strokes: _strokes,
                          guided: _guided,
                          glyph: widget.glyph,
                          template: widget.template,
                          dots: _guideDots,
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
          Positioned(
            top: 10,
            right: 10,
            child: IgnorePointer(
              child: AnimatedScale(
                scale: ok ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.elasticOut,
                child: const CircleAvatar(
                  key: Key('trace_success'),
                  radius: 20,
                  backgroundColor: Color(0xFF2E9D57),
                  child: Icon(Icons.check_rounded, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageLine(bool ok, {required double height}) {
    final message = _message;
    return SizedBox(
      height: height,
      child: message == null
          ? null
          : Semantics(
              liveRegion: true,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
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
            ),
    );
  }

  Widget _clearButton() => OutlinedButton.icon(
        key: const Key('write_clear'),
        onPressed: _strokes.isEmpty ? null : _clear,
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Clear'),
      );

  Widget _checkButton() => FilledButton.icon(
        key: const Key('write_check'),
        onPressed: _strokes.isEmpty ? null : _check,
        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
        icon: const Icon(Icons.check_rounded),
        label: const Text('Check'),
      );

  @override
  Widget build(BuildContext context) {
    final ok = _result?.shapeOk ?? false;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth.isFinite ? box.maxWidth : 400.0;
        final h = box.maxHeight.isFinite ? box.maxHeight : 400.0;
        // Wide room: the canvas takes the full height and the buttons sit in a
        // column beside it. Tall room: canvas on top, buttons underneath.
        final sideBySide = w >= h * 1.25 && w - h >= 150;
        if (sideBySide) {
          final side = math.min(h, w - 150);
          return Row(
            children: [
              Expanded(child: Center(child: _canvas(side))),
              // The buttons shrink a little rather than overflow when the
              // text is large and the room is short.
              SizedBox(
                width: 150,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 150,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _messageLine(ok, height: 44),
                        const SizedBox(height: 6),
                        _checkButton(),
                        const SizedBox(height: 10),
                        _clearButton(),
                        if (widget.finish != null) ...[
                          const SizedBox(height: 10),
                          widget.finish!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        const controls = 60.0;
        const messageHeight = 24.0;
        final side = math.max(
          120.0,
          math.min(w, h - controls - messageHeight - 8),
        );
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _canvas(side)),
            const SizedBox(height: 4),
            _messageLine(ok, height: messageHeight),
            const SizedBox(height: 4),
            SizedBox(
              height: controls - 8,
              child: Row(
                children: [
                  Expanded(child: _clearButton()),
                  const SizedBox(width: 10),
                  Expanded(child: _checkButton()),
                  if (widget.finish != null) ...[
                    const SizedBox(width: 10),
                    Expanded(child: widget.finish!),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Claims the touch the instant a finger lands and reports every move, so
/// nothing around the pad (a scroll view, a page swipe) can take the gesture.
class _InkRecognizer extends OneSequenceGestureRecognizer {
  ValueChanged<Offset>? onDown;
  ValueChanged<Offset>? onMove;
  VoidCallback? onUp;
  VoidCallback? onCancel;
  int? _pointer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_pointer != null) return; // one finger draws; others are ignored
    startTrackingPointer(event.pointer, event.transform);
    _pointer = event.pointer;
    resolve(GestureDisposition.accepted);
    onDown?.call(event.localPosition);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      onMove?.call(event.localPosition);
    } else if (event is PointerUpEvent) {
      _pointer = null;
      stopTrackingPointer(event.pointer);
      onUp?.call();
    } else if (event is PointerCancelEvent) {
      _pointer = null;
      stopTrackingPointer(event.pointer);
      onCancel?.call();
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'ink';
}

class _PadPainter extends CustomPainter {
  _PadPainter({
    required this.strokes,
    required this.guided,
    required this.glyph,
    required this.template,
    required this.dots,
    required this.ink,
    required this.guideColor,
    required this.revision,
  });

  final List<List<Offset>> strokes;
  final bool guided;
  final String glyph;
  final StrokeTemplate? template;
  final List<Pt> dots;
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
        // Drawn opaque inside one layer, then the layer is faded, so the fill
        // and its outline do not double up where they overlap.
        final style = glyphStyle(size.height * glyphBoxFraction);
        TextPainter painter(Paint paint) => TextPainter(
              text: TextSpan(
                text: glyph,
                style: style.copyWith(color: null, foreground: paint),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
        final fill = painter(Paint()..color = ink);
        final edge = painter(
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = nonTemplateGuideOutline
            ..strokeJoin = StrokeJoin.round,
        );
        final at = Offset(
          (size.width - fill.width) / 2,
          (size.height - fill.height) / 2 + size.height * glyphDrop,
        );
        canvas.saveLayer(
          Offset.zero & size,
          Paint()..color = Color.fromRGBO(0, 0, 0, nonTemplateGuideOpacity),
        );
        fill.paint(canvas, at);
        edge.paint(canvas, at);
        canvas.restore();
      }
    }
    _paintDots(canvas, size);
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.width * .035).clamp(10.0, 24.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(s.first, (size.width * .018).clamp(5.0, 12.0),
            Paint()..color = ink);
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final o in s.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  /// Dots along the letter. A dot the child has drawn over turns green, so the
  /// dots left show what is still to be traced.
  void _paintDots(Canvas canvas, Size size) {
    if (dots.isEmpty) return;
    final r = (size.width * .016).clamp(5.0, 11.0);
    final reach = size.width * .05;
    final done = Paint()..color = const Color(0xFF2E9D57);
    final todo = Paint()..color = const Color(0xFF6B7280);
    for (final d in dots) {
      final c = Offset(d.x * size.width, d.y * size.height);
      final covered =
          strokes.any((s) => s.any((o) => (o - c).distance <= reach));
      canvas.drawCircle(c, covered ? r * .8 : r, covered ? done : todo);
      if (!covered) {
        canvas.drawCircle(c, r * .45, Paint()..color = Colors.white);
      }
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
      old.template != template ||
      old.dots != dots;
}
