import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';
import '../batch/batch_content.dart' show batchQuestArt;
import '../batch/batch_lesson.dart';
import '../levels.dart';
import '../models.dart';
import '../quest_art.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/level_picker.dart';
import '../alphabet/alphabet_data.dart';
import 'alphabet_screen.dart';
import 'lesson_navigation.dart';

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
    if (world.lessons.isEmpty) return _ComingSoon(world: world);
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

/// A world with no lessons at the child's level yet (Level 5 today, and the
/// worlds whose later levels are still being written). It says so plainly and
/// shows the way to a level that has lessons; nothing is locked.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.world});
  final LearningWorld world;

  @override
  Widget build(BuildContext context) {
    final level = AppScope.of(context).activeProfile?.level ?? firstLevel;
    return Scaffold(
      appBar: AppBar(
        title: Text(world.name),
        backgroundColor: const Color(0xCC13213A),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              world.color.withValues(alpha: .35),
              const Color(0xFFFFFBF4)
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_top_rounded,
                      size: 56, color: world.darkColor),
                  const SizedBox(height: 12),
                  Text(
                    '${levelInfo(level).label} lessons for ${world.name} are '
                    'coming soon.',
                    key: const Key('coming_soon'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You can choose another level to keep learning. Your stars '
                    'and finished quests are kept.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('choose_level'),
                    onPressed: () => showLevelDialog(
                      context,
                      current: level,
                      onPicked: AppScope.of(context).setLevel,
                    ),
                    icon: const Icon(Icons.stairs_rounded),
                    label: const Text('Choose a level'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      backgroundColor: world.darkColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

/// The quest list, a page of cards at a time: as many as the screen holds,
/// with arrows (or a swipe) to turn the page and a dot per page.
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
  /// The page being shown. Null until the first layout, which opens on the
  /// page that holds the recommended quest.
  int? _page;
  double _dragged = 0;

  void _go(int page, int pages) =>
      setState(() => _page = page.clamp(0, pages - 1));

  @override
  Widget build(BuildContext context) {
    final lessons = widget.world.lessons;
    // Writing (tracing every letter) belongs to Level 1 only.
    final atLevelOne = AppScope.of(context).activeProfile?.level == firstLevel;
    final letters = atLevelOne ? alphabets[widget.world.id] : null;
    // The first card is "All letters" (for the languages that have a script).
    final lead = letters == null ? 0 : 1;
    final total = lessons.length + lead;
    return LayoutBuilder(
      builder: (context, constraints) {
        const dotsHeight = 34.0;
        const gap = 14.0;
        const arrowSlot = 58.0;
        // Room under the dots (on top of any system inset the SafeArea took)
        // and between the cards and the dots, so nothing hugs the edge.
        final bottomGap = constraints.maxHeight < 390 ? 12.0 : 18.0;
        final areaHeight = constraints.maxHeight - dotsHeight - bottomGap - 14;
        final cardHeight = areaHeight.clamp(120.0, 440.0);
        final horizontal = cardHeight < 270;
        final minCard = horizontal ? 300.0 : 230.0;
        final maxCard = horizontal ? 460.0 : 320.0;
        int fits(double room) =>
            math.max(1, ((room + gap) / (minCard + gap)).floor());

        // Quests are shown a page at a time, as many cards as the screen holds,
        // with arrows to turn the page. Nothing scrolls.
        var room = constraints.maxWidth - 2 * widget.pad;
        var perPage = fits(room);
        var pages = (total / perPage).ceil();
        if (pages > 1) {
          room -= 2 * arrowSlot;
          perPage = fits(room);
          pages = (total / perPage).ceil();
        }
        final cardWidth = ((room - gap * (perPage - 1)) / perPage)
            .clamp(0.0, maxCard)
            .toDouble();

        // While letters are still being learned, open on the All letters card
        // (the first option) instead of jumping on to a later quest.
        final lettersDone = letters == null ||
            [
              for (var i = 0; i < letters.letters.length; i++)
                widget.completed.contains(letters.lessonId(i)),
            ].every((d) => d);
        final recommendedAt =
            lead + lessons.indexWhere((l) => l.id == widget.recommended.id);
        final openOn = lettersDone && recommendedAt >= 0 ? recommendedAt : 0;
        final page = (_page ?? openOn ~/ perPage).clamp(0, pages - 1);
        final first = page * perPage;
        final last = math.min(total, first + perPage);

        Widget card(int position) {
          if (letters != null && position == 0) {
            return _AlphabetCard(
              world: widget.world,
              letters: letters,
              done: [
                for (var i = 0; i < letters.letters.length; i++)
                  if (widget.completed.contains(letters.lessonId(i))) i,
              ].length,
              horizontal: horizontal,
            );
          }
          final index = position - lead;
          final lesson = lessons[index];
          return _QuestCard(
            world: widget.world,
            lesson: lesson,
            number: index + 1,
            complete: widget.completed.contains(lesson.id),
            recommended: lesson.id == widget.recommended.id,
            unlocked: AppScope.of(context).isLessonUnlocked(lesson),
            horizontal: horizontal,
          );
        }

        Widget arrow(bool show, bool forward) => SizedBox(
              width: arrowSlot,
              child: show
                  ? Center(
                      child: _ArrowButton(
                        key: Key(forward ? 'trail_next' : 'trail_prev'),
                        icon: forward
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                        label: forward ? 'Later quests' : 'Earlier quests',
                        color: widget.world.darkColor,
                        onTap: () => _go(page + (forward ? 1 : -1), pages),
                      ),
                    )
                  : null,
            );

        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  widget.pad,
                  4,
                  widget.pad,
                  4,
                ),
                // A swipe turns the page too.
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) => _dragged = 0,
                  onHorizontalDragUpdate: (d) => _dragged += d.delta.dx,
                  onHorizontalDragEnd: (d) {
                    // A long enough pull, or a quick flick, turns the page.
                    final v = d.primaryVelocity ?? 0;
                    if (_dragged < -60 || v < -300) _go(page + 1, pages);
                    if (_dragged > 60 || v > 300) _go(page - 1, pages);
                  },
                  child: Row(
                    children: [
                      if (pages > 1) arrow(page > 0, false),
                      Expanded(
                        child: Center(
                          child: Row(
                            key: const Key('quest_trail'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var p = first; p < last; p++) ...[
                                if (p > first) const SizedBox(width: gap),
                                SizedBox(
                                  width: cardWidth,
                                  height: cardHeight,
                                  child: card(p),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (pages > 1) arrow(page < pages - 1, true),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: dotsHeight,
              child: _Dots(
                key: const Key('trail_dots'),
                count: pages,
                current: page,
                done: [
                  for (var p = 0; p < pages; p++)
                    [
                      for (var i = p * perPage;
                          i < math.min(total, (p + 1) * perPage);
                          i++)
                        if (letters != null && i == 0)
                          [
                            for (var k = 0; k < letters.letters.length; k++)
                              widget.completed.contains(letters.lessonId(k))
                          ].every((d) => d)
                        else
                          widget.completed.contains(lessons[i - lead].id),
                    ].every((d) => d),
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

/// A compact position indicator. Small trails show one dot per quest; complete
/// alphabet trails use a readable counter so dozens of dots never overflow.
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
          label: 'Page ${current + 1} of $count',
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xB313213A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: count > 12
                  ? Text(
                      '${current + 1} / $count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : Row(
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

/// The first card of a language's trail: every letter on one page.
class _AlphabetCard extends StatelessWidget {
  const _AlphabetCard({
    required this.world,
    required this.letters,
    required this.done,
    required this.horizontal,
  });

  final LearningWorld world;
  final AlphabetSet letters;
  final int done;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final total = letters.letters.length;
    final sample = letters.letters.take(3).map((l) => l.glyph).join('  ');
    final finished = done >= total;
    final art = ClipRRect(
      borderRadius: BorderRadius.circular(horizontal ? 16 : 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [world.darkColor, world.color],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                sample,
                maxLines: 1,
                style: scriptStyle(
                  sample,
                  const TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All letters',
          maxLines: 1,
          style: TextStyle(
            color: world.darkColor,
            fontSize: horizontal ? 18 : 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          'See, hear and trace every letter, one after another.',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF3A2A33),
            fontSize: 14,
            height: 1.25,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          finished ? 'All $total traced' : '$done of $total traced',
          key: const Key('all_letters_progress'),
          style: TextStyle(
            color: world.darkColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
    final button = FilledButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.abc_rounded),
      label: Text(done == 0
          ? 'Start'
          : finished
              ? 'Open'
              : 'Continue'),
      style: FilledButton.styleFrom(
        backgroundColor: world.darkColor,
        minimumSize: const Size.fromHeight(48),
      ),
    );
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'All letters. $done of $total traced',
      child: Material(
        color: const Color(0xFFFFF6E5),
        elevation: 6,
        shadowColor: const Color(0x99000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: world.darkColor, width: 4),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('all_letters'),
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: horizontal
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 118, child: art),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                  child: SingleChildScrollView(child: text)),
                              const SizedBox(height: 6),
                              button,
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 5, child: art),
                        const SizedBox(height: 8),
                        Expanded(flex: 4, child: _fitTop(text)),
                        const SizedBox(height: 6),
                        button,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shrinks the text to fit the space it is given, rather than scrolling
  /// inside the card (the trail itself is the only thing that scrolls).
  Widget _fitTop(Widget child) => LayoutBuilder(
        builder: (context, box) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: SizedBox(width: box.maxWidth, child: child),
        ),
      );

  void _open(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => AlphabetScreen(world: world, letters: letters),
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
    required this.unlocked,
    required this.horizontal,
  });
  final LearningWorld world;
  final Lesson lesson;
  final int number;
  final bool complete;
  final bool recommended;
  final bool unlocked;

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
    final play =
        _PlayButton(world: world, complete: complete, unlocked: unlocked);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'Quest $number, ${lesson.title}. ${lesson.subtitle}'
          '${complete ? ', completed' : ''}'
          '${unlocked ? '' : ', locked'}'
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
          onTap: unlocked
              ? () {
                  // A lesson with a teaching plan is taught step by step;
                  // every other lesson keeps its existing screen.
                  final controller = AppScope.of(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          lessonScreenFor(controller, world, lesson),
                    ),
                  );
                }
              : null,
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
  const _PlayButton({
    required this.world,
    required this.complete,
    required this.unlocked,
  });
  final LearningWorld world;
  final bool complete;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: unlocked ? world.darkColor : Colors.grey.shade600,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              unlocked ? Icons.play_arrow_rounded : Icons.lock_rounded,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                unlocked ? (complete ? 'Play again' : 'Play') : 'Locked',
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
