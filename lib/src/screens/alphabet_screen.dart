import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../alphabet/alphabet_data.dart';
import '../app.dart';
import '../batch/batch_content.dart' show BatchText;
import '../batch/batch_lesson.dart' show WriteMode;
import '../handwriting/glyph_mask.dart';
import '../handwriting/glyph_mask_raster.dart';
import '../handwriting/handwriting_registry.dart';
import '../models.dart';
import '../result_text.dart';
import '../services/speech_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/writing_pad.dart';
import 'lesson_screen.dart' show LessonResultDialog;

typedef LetterMaskLoader = Future<GlyphMask> Function(String glyph);

/// Every letter of a language on one page. Start at the first and go on, or
/// tap any letter: nothing is locked. A tick shows the letters already traced.
class AlphabetScreen extends StatelessWidget {
  const AlphabetScreen({
    required this.world,
    required this.letters,
    super.key,
    this.maskLoader,
  });

  final LearningWorld world;
  final AlphabetSet letters;
  final LetterMaskLoader? maskLoader;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final done = controller.activeProgress.completedWithLegacy;
    final total = letters.letters.length;
    final finished = [
      for (var i = 0; i < total; i++)
        if (done.contains(letters.lessonId(i))) i,
    ];
    // English also has a small letter after each big one. The big-letter
    // count above stays exactly as it was; the small letters are counted apart.
    final hasLower = letters.hasLowercase;
    bool bigDone(int i) => done.contains(letters.lessonId(i));
    bool smallDone(int i) => done.contains(letters.lowerLessonId(i));
    final lowerFinished = hasLower
        ? [
            for (var i = 0; i < total; i++)
              if (smallDone(i)) i,
          ]
        : const <int>[];
    final next = [
      for (var i = 0; i < total; i++)
        if (!bigDone(i) || (hasLower && !smallDone(i))) i,
    ].firstOrNull;
    final nextIsSmall = next != null && hasLower && bigDone(next);
    return GradientScaffold(
      colors: [
        world.color.withValues(alpha: .18),
        const Color(0xFFFFFBF4),
      ],
      appBar: AppBar(
        title: Text(
          letters.title,
          style: scriptStyle(letters.title, const TextStyle()),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StarPill(controller.activeProfile?.stars ?? 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      finished.length == total
                          ? 'All $total letters traced. Well done!'
                          : '${finished.length} of $total letters traced',
                      key: const Key('alphabet_progress_text'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                if (next != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: FilledButton.icon(
                      key: const Key('alphabet_continue'),
                      onPressed: () => _open(context, next, lower: nextIsSmall),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48)),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          finished.isEmpty && lowerFinished.isEmpty
                              ? 'Start with the first letter'
                              : 'Next letter',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (hasLower) ...[
              const SizedBox(height: 4),
              Text(
                lowerFinished.length == total
                    ? 'All $total small letters traced. Well done!'
                    : '${lowerFinished.length} of $total small letters traced',
                key: const Key('alphabet_lower_progress_text'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: total == 0 ? 0 : finished.length / total,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
              color: world.darkColor,
            ),
            const SizedBox(height: 10),
            // The letters are shown a page at a time, as many as the screen
            // holds, so the list never scrolls.
            Expanded(
              child: _LetterPages(
                count: total,
                startAt: next ?? 0,
                color: world.darkColor,
                tile: (i) => _LetterTile(
                  key: Key('letter_tile_$i'),
                  letter: letters.letters[i],
                  done: done.contains(letters.lessonId(i)),
                  lowerGlyph: letters.lowerGlyph(i),
                  lowerDone: hasLower && smallDone(i),
                  isNext: i == next,
                  color: world.darkColor,
                  onTap: () => _open(context, i),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, int index, {bool lower = false}) =>
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LetterScreen(
            world: world,
            letters: letters,
            index: index,
            lower: lower,
            maskLoader: maskLoader,
          ),
        ),
      );
}

/// Lays letter tiles out in as many rows and columns as fit, and turns pages
/// with arrows (or a swipe) when there are more letters than room.
class _LetterPages extends StatefulWidget {
  const _LetterPages({
    required this.count,
    required this.tile,
    required this.startAt,
    required this.color,
  });

  final int count;
  final Widget Function(int index) tile;

  /// The letter the child will learn next: its page is the one first shown.
  final int startAt;
  final Color color;

  @override
  State<_LetterPages> createState() => _LetterPagesState();
}

class _LetterPagesState extends State<_LetterPages> {
  static const _tile = 68.0;
  static const _gap = 10.0;
  static const _bar = 48.0;
  int? _page;
  double _dragged = 0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          int fit(double room) =>
              math.max(1, ((room + _gap) / (_tile + _gap)).floor());
          final columns = fit(box.maxWidth);
          // First try everything on one page; if it does not fit, reserve a
          // row for the page controls.
          var rows = fit(box.maxHeight);
          var perPage = columns * rows;
          var pages = (widget.count / perPage).ceil();
          if (pages > 1) {
            rows = fit(box.maxHeight - _bar);
            perPage = columns * rows;
            pages = (widget.count / perPage).ceil();
          }
          final page = (_page ?? widget.startAt ~/ perPage).clamp(0, pages - 1);
          final first = page * perPage;
          final last = math.min(widget.count, first + perPage);
          void go(int to) => setState(() => _page = to.clamp(0, pages - 1));
          return Column(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) => _dragged = 0,
                  onHorizontalDragUpdate: (d) => _dragged += d.delta.dx,
                  onHorizontalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (_dragged < -60 || v < -300) go(page + 1);
                    if (_dragged > 60 || v > 300) go(page - 1);
                  },
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Wrap(
                      key: const Key('letter_grid'),
                      spacing: _gap,
                      runSpacing: _gap,
                      alignment: WrapAlignment.center,
                      children: [
                        for (var i = first; i < last; i++) widget.tile(i),
                      ],
                    ),
                  ),
                ),
              ),
              if (pages > 1)
                SizedBox(
                  height: _bar,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        key: const Key('letters_prev_page'),
                        tooltip: 'Earlier letters',
                        onPressed: page > 0 ? () => go(page - 1) : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Page ${page + 1} of $pages',
                          key: const Key('letters_page_label'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton.filledTonal(
                        key: const Key('letters_next_page'),
                        tooltip: 'Later letters',
                        onPressed: page < pages - 1 ? () => go(page + 1) : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      );
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.letter,
    required this.done,
    required this.isNext,
    required this.color,
    required this.onTap,
    super.key,
    this.lowerGlyph,
    this.lowerDone = false,
  });

  final AlphabetLetter letter;

  /// The small letter step (English only), shown as a little badge.
  final String? lowerGlyph;
  final bool lowerDone;
  final bool done;
  final bool isNext;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${letter.glyph}${done ? ', traced' : ''}'
            '${lowerGlyph == null ? '' : ', small $lowerGlyph${lowerDone ? ' traced' : ''}'}'
            '${isNext ? ', next to learn' : ''}',
        excludeSemantics: true,
        child: Material(
          color: done ? const Color(0xFFE3F6E9) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isNext
                  ? color
                  : done
                      ? const Color(0xFF2E9D57)
                      : const Color(0xFFCFC8E6),
              width: isNext ? 4 : 2,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: SizedBox(
              width: 68,
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        letter.glyph,
                        style: scriptStyle(
                          letter.glyph,
                          const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w500,
                            color: GameTokens.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (lowerGlyph != null)
                    Positioned(
                      left: 6,
                      bottom: 3,
                      child: Text(
                        lowerGlyph!,
                        key: ValueKey('lower_badge_${letter.glyph}'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: lowerDone
                              ? const Color(0xFF2E9D57)
                              : const Color(0xFF8C86A8),
                        ),
                      ),
                    ),
                  if (done)
                    const Positioned(
                      right: 3,
                      top: 3,
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: Color(0xFF2E9D57),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// One letter: see it, hear it, trace it. A traced letter is saved, and the
/// next letter is then one tap away. Arrows move to any other letter freely.
class LetterScreen extends StatefulWidget {
  const LetterScreen({
    required this.world,
    required this.letters,
    required this.index,
    super.key,
    this.maskLoader,
    this.lower = false,
  });

  final LearningWorld world;
  final AlphabetSet letters;
  final int index;
  final LetterMaskLoader? maskLoader;

  /// The second step of an English letter: the small letter. Never true for
  /// the other languages.
  final bool lower;

  @override
  State<LetterScreen> createState() => _LetterScreenState();
}

class _LetterScreenState extends State<LetterScreen> {
  final _speech = const SpeechService();
  GlyphMask? _mask;
  bool _traced = false;
  int _gained = 0;
  bool _speaking = false;
  int _round = 0;

  bool get _lower => widget.lower && widget.letters.hasLowercase;

  /// The letter as shown and traced: for the small step, its small form.
  AlphabetLetter get _letter {
    final big = widget.letters.letters[widget.index];
    if (!_lower) return big;
    return AlphabetLetter(
      widget.letters.lowerGlyph(widget.index)!,
      word: big.word,
      meaning: big.meaning,
      picture: big.picture,
    );
  }

  String get _lessonId => _lower
      ? widget.letters.lowerLessonId(widget.index)
      : widget.letters.lessonId(widget.index);
  bool get _lastLetter => widget.index == widget.letters.letters.length - 1;

  /// English: the big letter is followed by its small letter, and only the
  /// small letter is followed by the next big one.
  bool get _bigThenSmall => widget.letters.hasLowercase && !_lower;
  bool get _last => _lastLetter && !_bigThenSmall;

  @override
  void initState() {
    super.initState();
    final glyph = _letter.glyph;
    (widget.maskLoader ?? rasteriseGlyph)(glyph).then((m) {
      if (mounted) setState(() => _mask = m);
    });
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _speak() async {
    setState(() => _speaking = true);
    await _speech.speak(_letter.speech, widget.letters.locale);
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _onTraced() async {
    if (_traced) return;
    setState(() => _traced = true);
    final lesson = Lesson(
      id: _lessonId,
      title: _letter.glyph,
      subtitle: _lower ? 'Trace the small letter' : 'Trace the letter',
      kind: LessonKind.tracing,
      symbol: _letter.glyph,
      speech: _letter.speech,
      locale: widget.letters.locale,
      challenge: 'Trace the letter',
      options: const [],
      answer: '',
    );
    final gained = await AppScope.of(context).recordResult(
      world: widget.world,
      lesson: lesson,
      correct: true,
    );
    if (!mounted) return;
    setState(() => _gained = gained);
    await _celebrate(gained);
  }

  /// Where "Next Lesson" goes from this letter: the small letter after a big
  /// English one, otherwise the next letter. Null after the last letter.
  VoidCallback? get _onNextLetter {
    if (_bigThenSmall) return () => _go(widget.index, lower: true);
    if (_last) return null;
    return () => _go(widget.index + 1);
  }

  /// The celebration popup once a letter is traced (progress is already saved).
  Future<void> _celebrate(int gained) async {
    final next = _onNextLetter;
    final navigator = Navigator.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => LessonResultDialog(
        correct: true,
        text: ResultText.forLocale(widget.letters.locale),
        gained: gained,
        onNext: next == null
            ? null
            : () {
                navigator.pop(); // the popup
                next(); // replaces this letter with the next one
              },
        onAgain: () {
          navigator.pop();
          setState(() {
            _traced = false;
            _round++;
          });
        },
        onBack: () {
          navigator.pop(); // the popup
          navigator.pop(); // this letter, back to the letters
        },
      ),
    );
  }

  void _go(int index, {bool lower = false}) {
    if (index < 0 || index >= widget.letters.letters.length) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LetterScreen(
          world: widget.world,
          letters: widget.letters,
          index: index,
          maskLoader: widget.maskLoader,
          lower: lower,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final alreadyDone =
        controller.activeProgress.completedWithLegacy.contains(_lessonId);
    final finished = _traced || alreadyDone;
    final letters = widget.letters.letters;
    final text = BatchText.forGlyph(widget.letters.locale, _letter.glyph);
    final nextLabel = _bigThenSmall
        ? 'Next: ${widget.letters.lowerGlyph(widget.index)}'
        : _last
            ? 'All letters'
            : 'Next: ${letters[widget.index + 1].glyph}';
    final scaffold = GradientScaffold(
      colors: [
        widget.world.color.withValues(alpha: .18),
        const Color(0xFFFFFBF4),
      ],
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= 600;
                // No top bar: every pixel of height goes to the canvas. Back,
                // previous and next sit in a slim row above the letter card.
                final bar = SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      // Room for the back button, which sits in the very corner.
                      const SizedBox(width: 44),
                      Expanded(
                        child: Text(
                          '${widget.index + 1} / ${letters.length}'
                          '${widget.letters.hasLowercase ? (_lower ? ' · small' : ' · big') : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        key: const Key('prev_letter'),
                        tooltip: 'Previous letter',
                        onPressed: _lower
                            ? () => _go(widget.index)
                            : widget.index > 0
                                ? () => _go(widget.index - 1)
                                : null,
                        icon: const Icon(Icons.chevron_left_rounded, size: 32),
                      ),
                      IconButton(
                        key: const Key('next_arrow'),
                        tooltip: 'Next letter',
                        onPressed:
                            _lastLetter ? null : () => _go(widget.index + 1),
                        icon: const Icon(Icons.chevron_right_rounded, size: 32),
                      ),
                    ],
                  ),
                );
                final show = _ShowLetter(
                  letter: _letter,
                  color: widget.world.darkColor,
                  speaking: _speaking,
                  onSpeak: _speak,
                  earned: _gained,
                  done: finished,
                );
                final pad = WritingPad(
                  key: ValueKey(
                      'trace_${widget.index}${_lower ? '_lower' : ''}_$_round'),
                  padKey: const Key('letter_pad'),
                  glyph: _letter.glyph,
                  mode: WriteMode.guided,
                  text: text,
                  color: widget.world.darkColor,
                  // Small letters have no stroke template: they are checked
                  // against the font outline and count as practice only.
                  template: _lower ? null : templateFor(_letter.glyph),
                  mask: _mask,
                  locale: widget.letters.locale,
                  onResult: (r) {
                    if (r.shapeOk) _onTraced();
                  },
                  finish: FilledButton.icon(
                    key: const Key('next_letter'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E9D57),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: finished
                        ? () {
                            if (_bigThenSmall) {
                              _go(widget.index, lower: true);
                            } else if (_last) {
                              Navigator.pop(context);
                            } else {
                              _go(widget.index + 1);
                            }
                          }
                        : null,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        nextLabel,
                        maxLines: 1,
                        style: scriptStyle(nextLabel, const TextStyle()),
                      ),
                    ),
                  ),
                );
                // The tracing card takes everything the letter card leaves.
                final padCard = Card(
                  child: Padding(padding: const EdgeInsets.all(10), child: pad),
                );
                if (!wide) {
                  final showHeight = (box.maxHeight * .27).clamp(150.0, 210.0);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        bar,
                        SizedBox(height: showHeight, child: show),
                        const SizedBox(height: 8),
                        Expanded(child: padCard),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [bar, Expanded(child: show)],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(flex: 8, child: padCard),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
    // Back sits in the very corner of the SCREEN, past any notch or cut-out,
    // and its touch area runs right to the edges.
    final inset = MediaQuery.paddingOf(context);
    return Stack(
      children: [
        scaffold,
        Positioned(
          left: 0,
          top: 0,
          child: Semantics(
            button: true,
            label: 'Back',
            child: Material(
              color: Colors.transparent,
              child: InkResponse(
                key: const Key('corner_back'),
                onTap: () => Navigator.maybePop(context),
                radius: 40,
                containedInkWell: false,
                child: SizedBox(
                  width: 72 + inset.left,
                  height: 64 + inset.top,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Icon(Icons.arrow_back_rounded, size: 30),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The picture word, with the letter it starts with picked out in colour.
TextSpan _wordSpan(AlphabetLetter letter, Color color) {
  final word = letter.word!;
  if (!word.toLowerCase().startsWith(letter.glyph.toLowerCase())) {
    return TextSpan(text: word);
  }
  return TextSpan(
    children: [
      TextSpan(
        text: word.substring(0, letter.glyph.length),
        style: TextStyle(color: color),
      ),
      TextSpan(text: word.substring(letter.glyph.length)),
    ],
  );
}

class _ShowLetter extends StatelessWidget {
  const _ShowLetter({
    required this.letter,
    required this.color,
    required this.speaking,
    required this.onSpeak,
    required this.earned,
    required this.done,
  });

  final AlphabetLetter letter;
  final Color color;
  final bool speaking;
  final VoidCallback onSpeak;
  final int earned;
  final bool done;

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          letter.glyph,
                          key: const Key('letter_big'),
                          style: scriptStyle(
                            letter.glyph,
                            TextStyle(
                              fontSize: 120,
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (letter.picture != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            letter.picture!,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox(width: 84, height: 84),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (letter.word != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    _wordSpan(letter, color),
                    key: const Key('letter_word'),
                    style: scriptStyle(
                      letter.word!,
                      const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: GameTokens.ink,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              FilledButton.tonalIcon(
                key: const Key('speak_button'),
                onPressed: speaking ? null : onSpeak,
                icon: Icon(
                  speaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                ),
                label: Text(speaking ? 'Speaking…' : 'Listen'),
              ),
              SizedBox(
                height: 26,
                child: done
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: Color(0xFF2E9D57),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              earned > 0 ? 'Traced! +$earned stars' : 'Traced!',
                              key: const Key('traced_message'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B7A41),
                              ),
                            ),
                          ],
                        ))
                    : null,
              ),
            ],
          ),
        ),
      );
}
