import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../app.dart';
import '../batch/batch_content.dart' show batchQuestArt;
import '../batch/batch_lesson.dart';
import '../models.dart';
import '../quest_art.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'batch_lesson_screen.dart';
import 'lesson_screen.dart';

/// Warm cream for quest cards: dark text on it clears 7:1, and it reads as
/// paper against the garden art behind.
const _cream = Color(0xFFFFF6E5);

class WorldMapScreen extends StatelessWidget {
  const WorldMapScreen({required this.world, super.key});

  final LearningWorld world;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final progress = controller.activeProgress;
    final recommended = controller.recommendedLesson(world);
    return Scaffold(
      appBar: AppBar(
        title: Text(world.name),
        backgroundColor: const Color(0xCC13213A),
        foregroundColor: Colors.white,
      ),
      // The artwork runs edge to edge (under any notch); only the content is
      // kept inside the safe area.
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: AssetImage(world.assetPath),
            fit: BoxFit.cover,
            semanticLabel: '${world.name} adventure landscape',
          ),
          // Light scrim: the header, cards and dots carry their own contrast,
          // so the garden stays visible between them.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .35, 1],
                colors: [
                  Color(0x4D13213A),
                  Color(0x1413213A),
                  Color(0x6613213A)
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 390;
                final pad = constraints.maxWidth < 720 ? 14.0 : 24.0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      world: world,
                      recommended: recommended,
                      stars: controller.activeProfile?.stars ?? 0,
                      compact: compact,
                      pad: pad,
                    ),
                    Expanded(
                      child: _QuestTrail(
                        world: world,
                        completed: progress.completedWithLegacy,
                        recommended: recommended,
                        pad: pad,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.world,
    required this.recommended,
    required this.stars,
    required this.compact,
    required this.pad,
  });
  final LearningWorld world;
  final Lesson recommended;
  final int stars;
  final bool compact;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final emblem = compact ? 44.0 : 56.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, compact ? 6 : 12, pad, compact ? 2 : 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC13213A),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: compact ? 5 : 8,
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/emblems/${world.id}.png',
                width: emblem,
                height: emblem,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => SizedBox(width: emblem),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      world.description,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Recommended quest: '),
                          TextSpan(
                            text: recommended.title,
                            style: scriptStyle(
                              recommended.title,
                              const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFE36E),
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StarPill(stars),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settles on a card boundary after a fling, so cards line up under the left
/// margin instead of stopping half cut off. The final stop is the last card
/// flush with the right margin.
class _CardSnapPhysics extends ScrollPhysics {
  const _CardSnapPhysics({required this.step, super.parent});
  final double step;

  @override
  _CardSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _CardSnapPhysics(step: step, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Out of range (overscroll): let the default physics spring it back.
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final projected = position.pixels + velocity * .2;
    // Stops are every card edge plus the true end of the list, so the last
    // card is always reachable even when the overhang is under half a card.
    final onCard = ((projected / step).round() * step).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    final end = position.maxScrollExtent;
    final target =
        (end - projected).abs() < (onCard - projected).abs() ? end : onCard;
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}

/// The horizontally scrolling quest list, with previous/next arrows and a dot
/// per quest so it is always clear there is more to the right.
class _QuestTrail extends StatefulWidget {
  const _QuestTrail({
    required this.world,
    required this.completed,
    required this.recommended,
    required this.pad,
  });
  final LearningWorld world;
  final Set<String> completed;
  final Lesson recommended;
  final double pad;

  @override
  State<_QuestTrail> createState() => _QuestTrailState();
}

class _QuestTrailState extends State<_QuestTrail> {
  final _controller = ScrollController();
  double _step = 1;
  bool _positioned = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _ready =>
      _controller.hasClients && _controller.position.hasContentDimensions;

  double get _offset => _ready ? _controller.offset : 0;
  double get _max => _ready ? _controller.position.maxScrollExtent : 0;

  /// Moves to the next (or previous) whole-card stop, never to a position that
  /// leaves a card half cut off. The last stop is the true end of the list.
  void _scrollBy(int direction) {
    if (!_ready) return;
    const slack = 2.0;
    final stops = <double>[
      for (var i = 0; i * _step < _max - slack; i++) i * _step,
      _max,
    ];
    final double target;
    if (direction > 0) {
      target = stops.firstWhere((s) => s > _offset + slack, orElse: () => _max);
    } else {
      target = stops.lastWhere((s) => s < _offset - slack, orElse: () => 0);
    }
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// Opens with the recommended quest in view (it can be quest 4 of 4).
  void _revealRecommended(double viewport, double cardWidth, int index) {
    if (_positioned || index <= 0) return;
    _positioned = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_ready) return;
      final centred = index * _step - (viewport - cardWidth) / 2 + widget.pad;
      _controller.jumpTo(centred.clamp(0.0, _max));
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessons = widget.world.lessons;
    return LayoutBuilder(
      builder: (context, constraints) {
        const dotsHeight = 34.0;
        const gap = 14.0;
        // Room under the dots (on top of any system inset the SafeArea took)
        // and between the cards and the dots, so nothing hugs the edge.
        final bottomGap = constraints.maxHeight < 390 ? 12.0 : 18.0;
        final areaHeight = constraints.maxHeight - dotsHeight - bottomGap - 14;
        final cardHeight = areaHeight.clamp(120.0, 440.0);
        final horizontal = cardHeight < 270;
        final cardWidth =
            (horizontal ? 330.0 : (cardHeight * .66).clamp(230.0, 310.0))
                .clamp(0.0, constraints.maxWidth - 2 * widget.pad);
        _step = cardWidth + gap;
        _revealRecommended(
          constraints.maxWidth,
          cardWidth,
          lessons.indexWhere((l) => l.id == widget.recommended.id),
        );
        final canLeft = _offset > 2;
        final canRight = _ready && _offset < _max - 2;
        final current = (_offset / _step).round().clamp(0, lessons.length - 1);
        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  NotificationListener<ScrollMetricsNotification>(
                    // The scroll extent is only known after layout (and changes
                    // on rotation or text size), so refresh the arrows and dots
                    // once it is.
                    onNotification: (_) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() {});
                      });
                      return false;
                    },
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        // Touch, plus mouse and stylus so tablets and desktop
                        // emulators drag the same way.
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.stylus,
                          PointerDeviceKind.trackpad,
                        },
                        scrollbars: false,
                      ),
                      child: ListView.separated(
                        key: const Key('quest_trail'),
                        controller: _controller,
                        scrollDirection: Axis.horizontal,
                        physics: _CardSnapPhysics(step: _step),
                        clipBehavior: Clip.none,
                        padding: EdgeInsets.fromLTRB(
                          widget.pad,
                          4,
                          widget.pad,
                          4,
                        ),
                        itemCount: lessons.length,
                        separatorBuilder: (_, __) => const SizedBox(width: gap),
                        itemBuilder: (context, index) {
                          final lesson = lessons[index];
                          return Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: cardWidth,
                              height: cardHeight,
                              child: _QuestCard(
                                world: widget.world,
                                lesson: lesson,
                                number: index + 1,
                                complete: widget.completed.contains(lesson.id),
                                recommended: lesson.id == widget.recommended.id,
                                horizontal: horizontal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (canLeft)
                    Positioned(
                      left: 4,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _ArrowButton(
                          key: const Key('trail_prev'),
                          icon: Icons.chevron_left_rounded,
                          label: 'Earlier quests',
                          color: widget.world.darkColor,
                          onTap: () => _scrollBy(-1),
                        ),
                      ),
                    ),
                  if (canRight)
                    Positioned(
                      right: 4,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _ArrowButton(
                          key: const Key('trail_next'),
                          icon: Icons.chevron_right_rounded,
                          label: 'Later quests',
                          color: widget.world.darkColor,
                          onTap: () => _scrollBy(1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: dotsHeight,
              child: _Dots(
                key: const Key('trail_dots'),
                count: lessons.length,
                current: current,
                done: [
                  for (final l in lessons) widget.completed.contains(l.id)
                ],
                color: widget.world.color,
              ),
            ),
            SizedBox(height: bottomGap),
          ],
        );
      },
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: Material(
          color: color,
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white, width: 2.5),
          ),
          elevation: 4,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, color: Colors.white, size: 34),
            ),
          ),
        ),
      );
}

/// One dot per quest: the one at the left edge is the long pill; finished
/// quests are filled with the world colour.
class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.current,
    required this.done,
    required this.color,
    super.key,
  });
  final int count;
  final int current;
  final List<bool> done;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
        child: Semantics(
          label: 'Quest ${current + 1} of $count',
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xB313213A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < count; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == current ? 26 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: i == current
                            ? Colors.white
                            : done[i]
                                ? color
                                : Colors.white38,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.world,
    required this.lesson,
    required this.number,
    required this.complete,
    required this.recommended,
    required this.horizontal,
  });
  final LearningWorld world;
  final Lesson lesson;
  final int number;
  final bool complete;
  final bool recommended;

  /// Short screens: picture on the left, text on the right.
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final art = questArt[lesson.id] ?? batchQuestArt[lesson.id];
    final item = lesson;
    final label =
        questLabel[lesson.id] ?? (item is BatchLesson ? item.symbol : null);
    final picture = ClipRRect(
      borderRadius: BorderRadius.circular(horizontal ? 16 : 18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Tracing quests teach one letter: show that letter, big, instead of
          // a picture of something else.
          if (lesson.kind == LessonKind.tracing ||
              (item is BatchLesson && art == null))
            _GlyphArt(world: world, glyph: lesson.symbol)
          else if (art != null)
            Image.asset(
              art,
              fit: BoxFit.cover,
              cacheWidth: 720,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => _ArtFallback(
                world: world,
                kind: lesson.kind,
              ),
            )
          else
            _ArtFallback(world: world, kind: lesson.kind),
          Positioned(
            top: 6,
            left: 6,
            child: _NumberBadge(number: number, color: world.darkColor),
          ),
          if (complete) const Positioned(top: 6, right: 6, child: _DoneBadge()),
          if (recommended && !horizontal)
            const Positioned(left: 6, bottom: 6, child: _NextChip()),
          if (label != null)
            Positioned(
              right: 6,
              bottom: 6,
              child: _LabelChip(text: label, world: world),
            ),
        ],
      ),
    );
    // A one-word title must never break inside the word (a Tamil conjunct
    // split over two lines is unreadable), so it stays on one line and the
    // card scales it down to fit. Multi-word titles wrap between words.
    final singleWord = !lesson.title.trim().contains(' ');
    final titleText = Text(
      lesson.title,
      maxLines: singleWord ? 1 : 2,
      softWrap: !singleWord,
      overflow: singleWord ? TextOverflow.visible : TextOverflow.ellipsis,
      style: scriptStyle(
        lesson.title,
        TextStyle(
          color: world.darkColor,
          fontSize: horizontal ? 17 : 19,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
    final title = singleWord
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: titleText,
          )
        : titleText;
    final subtitle = Text(
      lesson.subtitle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: scriptStyle(
        lesson.subtitle,
        const TextStyle(
          color: Color(0xFF3A2A33),
          fontSize: 14,
          height: 1.25,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    final play = _PlayButton(world: world, complete: complete);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'Quest $number, ${lesson.title}. ${lesson.subtitle}'
          '${complete ? ', completed' : ''}'
          '${recommended ? ', next adventure' : ''}',
      child: Material(
        color: _cream,
        elevation: 6,
        shadowColor: const Color(0x99000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(
            color: recommended ? world.darkColor : world.color,
            width: recommended ? 4 : 2.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('lesson_${lesson.id}'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => item is BatchLesson
                  ? BatchLessonScreen(world: world, lesson: item)
                  : LessonScreen(world: world, lesson: lesson),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            // Card text follows the system size up to 130%; beyond that the
            // fixed-height cards would have to cut words off.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: horizontal
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 118, child: picture),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and instruction shrink a little rather
                              // than overflow, and the play button always sits
                              // on the same line across cards.
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, box) => FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.topLeft,
                                    child: SizedBox(
                                      width: box.maxWidth,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          title,
                                          const SizedBox(height: 2),
                                          subtitle,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (recommended) const _NextChip(),
                              if (recommended) const SizedBox(height: 4),
                              play,
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: picture),
                        const SizedBox(height: 8),
                        title,
                        const SizedBox(height: 2),
                        subtitle,
                        const SizedBox(height: 8),
                        play,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtFallback extends StatelessWidget {
  const _ArtFallback({required this.world, required this.kind});
  final LearningWorld world;
  final LessonKind kind;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: world.color.withValues(alpha: .25),
        child: Center(
          child: Icon(lessonIcon(kind), size: 48, color: world.darkColor),
        ),
      );
}

/// The letter being traced, large, inside a dashed guide ring.
class _GlyphArt extends StatelessWidget {
  const _GlyphArt({required this.world, required this.glyph});
  final LearningWorld world;
  final String glyph;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(Colors.white, world.color, .25)!,
              Color.lerp(Colors.white, world.color, .55)!,
            ],
          ),
        ),
        child: CustomPaint(
          painter: _DashedRingPainter(color: world.darkColor),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  glyph,
                  maxLines: 1,
                  style: scriptStyle(
                    glyph,
                    TextStyle(
                      color: world.darkColor,
                      fontSize: 120,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide / 2) - 12;
    if (radius <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final centre = size.center(Offset.zero);
    const dashes = 28;
    for (var i = 0; i < dashes; i++) {
      final start = i * 2 * 3.141592653589793 / dashes;
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        start,
        2 * 3.141592653589793 / dashes * .5,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The letter or word a quest teaches, on its picture.
class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.text, required this.world});
  final String text;
  final LearningWorld world;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 110),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: world.color, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                maxLines: 1,
                style: scriptStyle(
                  text,
                  TextStyle(
                    color: world.darkColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number, required this.color});
  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            height: 1,
          ),
        ),
      );
}

class _DoneBadge extends StatelessWidget {
  const _DoneBadge();

  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF1E8A4C),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
      );
}

class _NextChip extends StatelessWidget {
  const _NextChip();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: GameTokens.gold,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            'NEXT ADVENTURE',
            maxLines: 1,
            style: TextStyle(
              color: GameTokens.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
      );
}

/// The big play target. It looks like a button; the whole card is what taps.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.world, required this.complete});
  final LearningWorld world;
  final bool complete;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: world.darkColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                complete ? 'Play again' : 'Play',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
}
