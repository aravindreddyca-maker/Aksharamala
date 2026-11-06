/// Flutter-drawn renderers for the plan's visual types. Nothing here depends
/// on an image file except [ArtPicture], which has its own placeholder.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../art/art_picture.dart';
import '../theme.dart';
import 'teaching_plan.dart';

class TeachingVisualView extends StatelessWidget {
  const TeachingVisualView({
    required this.visual,
    super.key,
    this.isQuestion = false,
    this.color = const Color(0xFF6657D9),
  });

  final TeachingVisual visual;

  /// Question visuals never print the answer: a picture with no caption stays
  /// uncaptioned and its placeholder carries no concept label.
  final bool isQuestion;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final child = switch (visual.type) {
      VisualType.none => const SizedBox.shrink(),
      VisualType.glyph => _Glyph(visual.glyph, color),
      VisualType.picture => _Picture(visual: visual, isQuestion: isQuestion),
      VisualType.letterWord => _LetterWord(visual: visual, color: color),
      VisualType.objects => ObjectsVisual(visual: visual, color: color),
      VisualType.numberLine => NumberLineVisual(visual: visual, color: color),
      VisualType.baseTen => BaseTenVisual(visual: visual, color: color),
    };
    if (visual.type == VisualType.none) return child;
    return Semantics(
      container: true,
      label: visual.semanticLabel,
      excludeSemantics: visual.type != VisualType.picture,
      child: child,
    );
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph(this.glyph, this.color);
  final String glyph;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            glyph,
            key: const Key('visual_glyph'),
            style: scriptStyle(
              glyph,
              TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
      );
}

class _Picture extends StatelessWidget {
  const _Picture({required this.visual, required this.isQuestion});
  final TeachingVisual visual;
  final bool isQuestion;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 280),
            child: AspectRatio(
              aspectRatio: 1,
              child: ArtPicture(
                asset: visual.asset,
                conceptLabel: visual.caption,
                hideConcept: isQuestion && visual.caption.isEmpty,
              ),
            ),
          ),
          // An empty caption means: print nothing (it would be the answer).
          if (visual.caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              visual.caption,
              key: const Key('visual_caption'),
              textAlign: TextAlign.center,
              style: scriptStyle(
                visual.caption,
                const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: GameTokens.ink,
                ),
              ),
            ),
          ],
        ],
      );
}

class _LetterWord extends StatelessWidget {
  const _LetterWord({required this.visual, required this.color});
  final TeachingVisual visual;
  final Color color;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Text(
            visual.glyph,
            key: const Key('visual_glyph'),
            style: scriptStyle(
              visual.glyph,
              TextStyle(
                fontSize: 84,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: ArtPicture(
                  asset: visual.asset,
                  conceptLabel: visual.word,
                ),
              ),
              Text(
                visual.word,
                key: const Key('visual_word'),
                style: scriptStyle(
                  visual.word,
                  const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: GameTokens.ink,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Emoji size by how many objects are on screen, so 98 of them (nine tens and
/// some ones) still fit.
double _cellSize(int total) => total <= 12
    ? 32
    : total <= 30
        ? 26
        : total <= 60
            ? 20
            : 15;

/// Emoji groups (at most 20 objects in all).
///
/// * `+`: groups side by side with a plus between them.
/// * `-` or the minus sign: ONE group; the last `takeAway` objects are faded
///   and struck through (animated, instant with reduced motion) with
///   "- n" beside it. `countAll` numbers the objects that are left. Show the
///   start with `takeAway` 0 in one step and the take-away in the next.
/// * `vs`: two groups compared, nothing added or removed. With `labels` (two
///   strings) they are drawn as two labelled rows with a "vs" between;
///   without, side by side with a "vs" mark. `countAll` numbers each group on
///   its own.
///
/// `revealCount` is how many GROUPS are revealed, `result` is drawn as "= n"
/// only when `showResult` is true (never for `vs`).
class ObjectsVisual extends StatelessWidget {
  const ObjectsVisual({required this.visual, required this.color, super.key});
  final TeachingVisual visual;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final visible = visual.visibleGroups;
    final single = visual.groups.length == 1;
    final reduce = _reduceMotion(context);
    final subtract = visual.isSubtract;
    final compare = visual.isCompare;
    var total = 0;
    for (var g = 0; g < visible; g++) {
      total += visual.groups[g].count;
    }
    final cell = _cellSize(total);
    final taken = subtract && visible >= 1
        ? visual.takeAway.clamp(0, visual.groups.first.count)
        : 0;
    final rows = compare && visual.labels.length == 2;
    var counter = 0;
    final boxes = <Widget>[];
    for (var g = 0; g < visible; g++) {
      final group = visual.groups[g];
      final kept = group.count - (subtract ? taken : 0);
      if (compare) counter = 0; // each side is counted on its own
      final cells = <Widget>[];
      for (var i = 0; i < group.count; i++) {
        final removed = i >= kept;
        if (!removed) counter++;
        cells.add(
          _ObjectCell(
            key: Key(
              removed
                  ? 'object_removed_${i - kept + 1}'
                  : (compare
                      ? 'object_cell_${g}_$counter'
                      : 'object_cell_$counter'),
            ),
            emoji: group.emoji,
            number: visual.countAll && !removed ? counter : null,
            color: color,
            size: cell,
            removed: removed,
            animate: removed && !reduce,
          ),
        );
      }
      final isNewest = g == visible - 1 && visible > 1;
      Widget groupBox = Container(
        key: Key('object_group_$g'),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .35), width: 2),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 3,
          runSpacing: 3,
          children: cells,
        ),
      );
      if (isNewest && !reduce) {
        groupBox = TweenAnimationBuilder<double>(
          key: ValueKey('reveal_${visual.revealCount}_$g'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          builder: (_, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: .7 + .3 * t, child: child),
          ),
          child: groupBox,
        );
      }
      if (rows) {
        boxes.add(
          Column(
            key: Key('object_row_$g'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                visual.labels[g],
                key: Key('object_label_$g'),
                textAlign: TextAlign.center,
                style: scriptStyle(
                  visual.labels[g],
                  const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GameTokens.ink,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              groupBox,
            ],
          ),
        );
        continue;
      }
      // The sign travels with the group after it, so it never wraps alone.
      boxes.add(
        g > 0 && !single
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  compare ? const _CompareMark() : _Sign(visual.operator),
                  const SizedBox(width: 8),
                  Flexible(child: groupBox),
                ],
              )
            : groupBox,
      );
    }
    final tail = <Widget>[];
    final equation = subtract && taken > 0;
    if (equation) {
      // The whole sum: "N - k = ?" (the result only when showResult is true).
      final sum = TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        color: color,
      );
      final known = visual.showResult && visual.result != null;
      tail.add(
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            key: const Key('objects_equation'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${visual.groups.first.count} − $taken',
                key: const Key('objects_taken'),
                style: sum,
              ),
              const SizedBox(width: 8),
              const _Sign('='),
              const SizedBox(width: 8),
              Text(
                known ? '${visual.result}' : '?',
                key: Key(known ? 'objects_result' : 'objects_placeholder'),
                style: sum.copyWith(fontSize: 44),
              ),
            ],
          ),
        ),
      );
    }
    if (!compare && !equation && visual.showResult && visual.result != null) {
      tail.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Sign('='),
            const SizedBox(width: 8),
            Text(
              '${visual.result}',
              key: const Key('objects_result'),
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      );
    }
    if (rows) {
      return Center(
        child: Column(
          key: const Key('objects_visual'),
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < boxes.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: _CompareMark(),
                ),
              boxes[i],
            ],
          ],
        ),
      );
    }
    return Center(
      child: Wrap(
        key: const Key('objects_visual'),
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 10,
        children: [...boxes, ...tail],
      ),
    );
  }
}

/// Base-ten blocks: a bar of ten for each ten, a single cube for each one
/// (at most 9 and 9). The total is written only when `showTotal` is true.
class BaseTenVisual extends StatelessWidget {
  const BaseTenVisual({required this.visual, required this.color, super.key});
  final TeachingVisual visual;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tens = visual.tens.clamp(0, 9);
    final ones = visual.ones.clamp(0, 9);
    Widget rod(int i) => Container(
          key: Key('baseten_rod_$i'),
          width: 18,
          height: 88,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Column(
            children: [
              for (var s = 0; s < 10; s++)
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: s.isEven ? .55 : .35),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: .8),
                          width: .5,
                        ),
                      ),
                    ),
                    child: const SizedBox(width: double.infinity),
                  ),
                ),
            ],
          ),
        );
    Widget cube(int i) => Container(
          key: Key('baseten_one_$i'),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFF2B33D),
            border: Border.all(color: const Color(0xFFB07A10), width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        );
    Widget part(String caption, Widget body, Key key) => Container(
          key: key,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: .3), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              body,
              const SizedBox(height: 4),
              Text(
                caption,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: GameTokens.ink,
                ),
              ),
            ],
          ),
        );
    final children = <Widget>[
      if (tens > 0)
        part(
          'tens',
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [for (var i = 1; i <= tens; i++) rod(i)],
          ),
          const Key('baseten_tens'),
        ),
      if (ones > 0)
        part(
          'ones',
          SizedBox(
            // three cubes to a row
            width: 3 * 22.0,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [for (var i = 1; i <= ones; i++) cube(i)],
            ),
          ),
          const Key('baseten_ones'),
        ),
      if (visual.showTotal)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Sign('='),
            const SizedBox(width: 8),
            Text(
              '${tens * 10 + ones}',
              key: const Key('baseten_total'),
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
    ];
    return Center(
      child: Wrap(
        key: const Key('baseten_visual'),
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: children,
      ),
    );
  }
}

class _Sign extends StatelessWidget {
  const _Sign(this.sign);
  final String sign;

  @override
  Widget build(BuildContext context) => Text(
        sign == '-' ? '−' : sign,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: GameTokens.ink,
        ),
      );
}

/// The neutral mark between two groups being compared: no plus, no minus.
class _CompareMark extends StatelessWidget {
  const _CompareMark();

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('compare_mark'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEAF8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8A7FB8), width: 2),
        ),
        child: const Text(
          'vs',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: GameTokens.ink,
          ),
        ),
      );
}

class _ObjectCell extends StatelessWidget {
  const _ObjectCell({
    required this.emoji,
    required this.number,
    required this.color,
    required this.size,
    this.removed = false,
    this.animate = false,
    super.key,
  });
  final String emoji;
  final int? number;
  final Color color;
  final double size;
  final bool removed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    Widget face(double t) => Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 1 - .75 * t,
              child: Text(emoji, style: TextStyle(fontSize: size)),
            ),
            if (removed && t > 0)
              CustomPaint(
                size: Size(size * 1.1, size * 1.1),
                painter: _CrossPainter(progress: t),
              ),
          ],
        );
    final Widget body = removed
        ? (animate
            ? TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 450),
                builder: (_, t, __) => face(t),
              )
            : face(1))
        : face(0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        body,
        if (number != null)
          Text(
            '$number',
            key: Key('object_number_$number'),
            style: TextStyle(
              fontSize: size >= 26 ? 16 : 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
      ],
    );
  }
}

class _CrossPainter extends CustomPainter {
  _CrossPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC0392B)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final a = Offset(size.width * .12, size.height * .12);
    final b = Offset(size.width * .88, size.height * .88);
    final c = Offset(size.width * .88, size.height * .12);
    final d = Offset(size.width * .12, size.height * .88);
    final t1 = (progress * 2).clamp(0.0, 1.0);
    final t2 = (progress * 2 - 1).clamp(0.0, 1.0);
    canvas.drawLine(a, Offset.lerp(a, b, t1)!, paint);
    if (t2 > 0) canvas.drawLine(c, Offset.lerp(c, d, t2)!, paint);
  }

  @override
  bool shouldRepaint(_CrossPainter old) => old.progress != progress;
}

/// A number line with ticks, a start dot and (when showHops) animated hops.
/// A positive jump hops right, a negative jump hops left, and a jump of 0
/// stays on the start number (a small loop above it).
class NumberLineVisual extends StatefulWidget {
  const NumberLineVisual({
    required this.visual,
    required this.color,
    super.key,
  });
  final TeachingVisual visual;
  final Color color;

  @override
  State<NumberLineVisual> createState() => _NumberLineVisualState();
}

class _NumberLineVisualState extends State<NumberLineVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hops = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds:
          450 * (widget.visual.jump.abs() < 1 ? 1 : widget.visual.jump.abs()) +
              200,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.visual.showHops && !_reduceMotion(context)) {
      if (!_hops.isAnimating && _hops.value < 1) _hops.forward();
    } else {
      _hops.value = 1;
    }
  }

  @override
  void dispose() {
    _hops.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.visual;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.hasBoundedWidth ? box.maxWidth : 320.0;
        return AnimatedBuilder(
          animation: _hops,
          builder: (_, __) => CustomPaint(
            key: const Key('number_line'),
            size: Size(width, 120),
            painter: NumberLinePainter(
              from: v.from,
              to: v.to,
              start: v.start,
              // The second number is ignored when hops are not shown.
              jump: v.showHops ? v.jump : 0,
              showHops: v.showHops,
              progress: _hops.value,
              color: widget.color,
              ink: GameTokens.ink,
            ),
          ),
        );
      },
    );
  }
}

class NumberLinePainter extends CustomPainter {
  NumberLinePainter({
    required this.from,
    required this.to,
    required this.start,
    required this.jump,
    required this.progress,
    required this.color,
    required this.ink,
    this.showHops = true,
  });

  final int from;
  final int to;
  final int start;

  /// Steps to hop: positive right, negative left, 0 stay.
  final int jump;
  final bool showHops;
  final double progress;
  final Color color;
  final Color ink;

  /// Smallest of 1, 2, 5, 10, 20, 50, 100 that is at least [need] long.
  static int stepFor(double pxPerUnit, double need) {
    const steps = [1, 2, 5, 10, 20, 50, 100];
    for (final s in steps) {
      if (pxPerUnit * s >= need) return s;
    }
    return steps.last;
  }

  /// Numbers that are always ticked and labelled: both ends, the start and,
  /// when hops are shown, where they land.
  static Set<int> mustLabel({
    required int from,
    required int to,
    required int start,
    required int jump,
    required bool showHops,
  }) {
    final landing = start + jump;
    return {
      from,
      to,
      start,
      if (showHops && landing >= from && landing <= to) landing,
    };
  }

  /// Every number that gets a label on a line [width] wide: the must-have
  /// ones, plus regular ones thinned (1, 2, 5, 10 ...) and dropped when they
  /// would sit within 22 px of a must-have one.
  static List<int> labelledNumbers({
    required int from,
    required int to,
    required int start,
    required int jump,
    required bool showHops,
    required double width,
  }) {
    const margin = 20.0;
    final span = max(1, to - from);
    final px = (width - 2 * margin) / span;
    final step = stepFor(px, span > 12 ? 26 : 22);
    final must = mustLabel(
        from: from, to: to, start: start, jump: jump, showHops: showHops);
    return [
      for (var n = from; n <= to; n++)
        if (must.contains(n) ||
            ((n - from) % step == 0 &&
                must.every((m) => ((n - m) * px).abs() > 22)))
          n,
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 20.0;
    final span = max(1, to - from);
    final y = size.height * .68;
    final pxPerUnit = (size.width - 2 * margin) / span;
    double x(num n) => margin + (n - from) * pxPerUnit;
    final line = Paint()
      ..color = ink
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x(from), y), Offset(x(to), y), line);
    // Long lines: fewer ticks and labels, so nothing piles up.
    final tickStep = stepFor(pxPerUnit, 6);
    final tickLabelSize = span > 12 ? 11.0 : 15.0;
    final must = mustLabel(
        from: from, to: to, start: start, jump: jump, showHops: showHops);
    final labelled = labelledNumbers(
      from: from,
      to: to,
      start: start,
      jump: jump,
      showHops: showHops,
      width: size.width,
    ).toSet();
    for (var n = from; n <= to; n++) {
      final special = must.contains(n);
      if ((n - from) % tickStep == 0 || special) {
        canvas.drawLine(Offset(x(n), y - 7), Offset(x(n), y + 7), line);
      }
      if (labelled.contains(n)) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$n',
            style: TextStyle(
              color: ink,
              fontSize: tickLabelSize,
              fontWeight: must.contains(n) && n != from && n != to
                  ? FontWeight.w900
                  : FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x(n) - tp.width / 2, y + 10));
      }
    }
    if (showHops) {
      final hopPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      final dir = jump < 0 ? -1 : 1;
      final count = jump.abs();
      final shown = progress * count;
      for (var h = 0; h < count; h++) {
        final part = (shown - h).clamp(0.0, 1.0);
        if (part <= 0) break;
        final a = x(start + dir * h);
        final b = x(start + dir * (h + 1));
        final lift = min(34.0, (b - a).abs() * .8 + 6);
        final path = Path()..moveTo(a, y);
        const steps = 16;
        for (var i = 1; i <= steps * part; i++) {
          final t = i / steps;
          path.lineTo(a + (b - a) * t, y - sin(pi * t) * lift);
        }
        canvas.drawPath(path, hopPaint);
        // An arrow head on the last hop makes the direction plain.
        if (h == count - 1 && part >= 1) {
          final arrow = Path()
            ..moveTo(b, y)
            ..lineTo(b - dir * 8, y - 9)
            ..lineTo(b - dir * 2, y - 11)
            ..close();
          canvas.drawPath(arrow, Paint()..color = color);
        }
      }
      if (count == 0) {
        // Zero: stay put. A little loop over the start number.
        final loop = Path()
          ..addArc(
            Rect.fromCircle(center: Offset(x(start), y - 24), radius: 12),
            pi / 2,
            2 * pi * progress,
          );
        canvas.drawPath(loop, hopPaint);
      }
      if (progress >= 1) {
        final land = Offset(x(start + jump), y);
        canvas.drawCircle(
          land,
          10,
          Paint()..color = color.withValues(alpha: .25),
        );
        canvas.drawCircle(land, 6, Paint()..color = color);
      }
    }
    // Start marker on top.
    canvas.drawCircle(Offset(x(start), y), 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(x(start), y),
      9,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(NumberLinePainter old) =>
      old.from != from ||
      old.to != to ||
      old.start != start ||
      old.jump != jump ||
      old.showHops != showHops ||
      old.progress != progress ||
      old.color != color;
}
