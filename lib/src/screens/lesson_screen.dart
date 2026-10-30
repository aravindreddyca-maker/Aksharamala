import 'dart:math';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../app.dart';
import '../batch/batch_content.dart' show BatchText;
import '../batch/batch_lesson.dart' show WriteMode;
import '../curriculum.dart' show numberNames;
import '../handwriting/glyph_mask.dart';
import '../handwriting/glyph_mask_raster.dart';
import '../handwriting/handwriting_registry.dart';
import '../models.dart';
import '../result_text.dart';
import '../services/speech_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/writing_pad.dart';

/// What the result pop-up says, in the quest's language. [gained] is what the
/// quest actually paid, which is 0 once a quest has already paid its stars, so
/// the words must not promise stars that were not given.
String questResultMessage({
  required bool correct,
  required int gained,
  String locale = 'en-US',
}) =>
    ResultText.forLocale(locale).message(correct: correct, gained: gained);

/// How long the right and wrong answers stay on screen before the result
/// pop-up appears.
const defaultFeedbackPause = Duration(milliseconds: 1100);

/// Tests set this to zero to reach the pop-up without waiting.
Duration feedbackPause = defaultFeedbackPause;

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    required this.world,
    required this.lesson,
    super.key,
    this.random,
  });

  final LearningWorld world;
  final Lesson lesson;

  /// Source of the answer shuffle. Tests pass a seeded one; the app uses its
  /// own.
  final Random? random;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final _speech = const SpeechService();
  late final Random _random = widget.random ?? Random();
  late List<String> _options = _shuffled(widget.lesson.options);
  String? _selected;
  bool _submitted = false;
  bool _speaking = false;
  int _storyPage = 0;
  bool _traceOk = false;
  int _traceRound = 0;
  GlyphMask? _glyphMask;

  /// The answers in a fresh random order, never the order just shown. Quests
  /// list the right answer first, so without this a child learns "tap the
  /// first one", and after a mistake could win by ruling one out in place.
  List<String> _shuffled(List<String> options, {List<String>? avoid}) {
    final result = [...options];
    if (result.length < 2) return result;
    for (var attempt = 0; attempt < 8; attempt++) {
      result.shuffle(_random);
      if (avoid == null || !listEquals(result, avoid)) return result;
    }
    // Vanishingly unlikely; rotate so it still differs from the last order.
    return [...result.skip(1), result.first];
  }

  bool get _isTracing => widget.lesson.kind == LessonKind.tracing;
  bool get _isStory => widget.lesson.kind == LessonKind.story;

  /// Counting and sums in Number Galaxy: one picture, one question, three big
  /// answers, English only. "Number Names" keeps the multilingual layout
  /// because matching the Telugu/Hindi/Tamil words is its whole point.
  bool get _isMath =>
      widget.world.id == 'numbers' &&
      widget.lesson.id != 'num-names' &&
      (widget.lesson.kind == LessonKind.numbers ||
          widget.lesson.kind == LessonKind.game);

  Future<void> _speak() async {
    setState(() => _speaking = true);
    final speech = widget.lesson.id == 'num-names'
        ? '${numberNames[5]!['en']}.'
        : widget.lesson.speech;
    final supported = await _speech.speak(
      speech,
      widget.lesson.locale,
    );
    if (!mounted) return;
    setState(() => _speaking = false);
    if (!supported) {
      await showInfoDialog(
        context,
        title: 'Voice unavailable',
        message:
            'This device does not have the ${widget.lesson.locale} voice installed. The lesson remains fully playable offline.',
      );
    }
  }

  Future<void> _finish(bool correct) async {
    if (_submitted) return;
    setState(() => _submitted = true);
    // A buzz the child can feel the moment they answer: light for right,
    // firm for wrong.
    if (correct) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    final gained = await AppScope.of(context).recordResult(
      world: widget.world,
      lesson: widget.lesson,
      correct: correct,
    );
    if (!mounted) return;
    // Hold on the coloured answers so the child sees which one was right
    // before the pop-up covers them.
    await Future<void>.delayed(feedbackPause);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LessonResultDialog(
        correct: correct,
        text: ResultText.forLocale(widget.lesson.locale),
        gained: gained,
        onBack: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        onAgain: () {
          Navigator.pop(context);
          setState(() {
            _submitted = false;
            _selected = null;
            _traceOk = false;
            _traceRound++;
            // A new order each time, so the same slot is not the answer.
            _options = _shuffled(widget.lesson.options, avoid: _options);
          });
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMask();
  }

  /// The traced letter drawn from the font, used to check the child's shape.
  void _loadMask() {
    if (!_isTracing) return;
    final glyph = widget.lesson.symbol;
    _glyphMask = null;
    rasteriseGlyph(glyph).then((m) {
      if (mounted && widget.lesson.symbol == glyph) {
        setState(() => _glyphMask = m);
      }
    });
  }

  @override
  void didUpdateWidget(covariant LessonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The same screen handed a different lesson must not keep the old
    // lesson's answers or progress.
    if (oldWidget.lesson.id != widget.lesson.id) {
      _options = _shuffled(widget.lesson.options);
      _selected = null;
      _submitted = false;
      _storyPage = 0;
      _traceOk = false;
      _traceRound++;
      _loadMask();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return GradientScaffold(
      colors: [
        widget.world.color.withValues(alpha: .18),
        const Color(0xFFFFFBF4),
      ],
      appBar: AppBar(
        title: Text(lesson.title),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StarPill(AppScope.of(context).activeProfile?.stars ?? 0),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoPanel = constraints.maxWidth >= 600;
          final padding = constraints.maxHeight < 400 ? 10.0 : 18.0;
          if (_isMath) return _buildMath(twoPanel: twoPanel, padding: padding);
          final activity = _isTracing
              ? _buildTracing()
              : _isStory
                  ? _buildStory(pinned: twoPanel)
                  : _buildQuestion(pinned: twoPanel);
          if (!twoPanel) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildIntro(lesson),
                  const SizedBox(height: 12),
                  activity,
                ],
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(padding, 4, padding, padding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(child: _buildIntro(lesson)),
                ),
                SizedBox(width: padding),
                Expanded(
                  flex: 6,
                  // A text-only quiz pins its Check Answer button under a
                  // scrolling list of answers, so the button is always on
                  // screen. Everything else scrolls as one piece.
                  child: _pinsCheck
                      ? Align(alignment: Alignment.topCenter, child: activity)
                      : SingleChildScrollView(child: activity),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMath({required bool twoPanel, required double padding}) {
    final visual = _mathVisual();
    if (!twoPanel) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 230, child: visual),
            const SizedBox(height: 12),
            _mathAnswers(tileHeight: 68),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 4, padding, padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: visual),
          SizedBox(width: padding),
          Expanded(
            flex: 5,
            child: LayoutBuilder(
              builder: (context, box) {
                // The question (which grows with text size) and the gaps come
                // off the top; the three tiles share what is left.
                final title =
                    MediaQuery.textScalerOf(context).scale(24) * 1.3 + 12;
                final tile = ((box.maxHeight - title - 36) / 3).clamp(
                  56.0,
                  120.0,
                );
                return SingleChildScrollView(
                  child: _mathAnswers(tileHeight: tile),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Stars to count (bundled image) or the sum to solve, plus Listen.
  Widget _mathVisual() {
    final lesson = widget.lesson;
    final stars = '★'.allMatches(lesson.symbol).length;
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: stars > 0
                    ? LayoutBuilder(
                        builder: (context, box) {
                          final perRow = stars <= 5 ? stars : 5;
                          final rows = (stars / perRow).ceil();
                          final size = ((box.maxWidth / perRow) - 10)
                              .clamp(32.0, 96.0)
                              .toDouble();
                          final fit = (box.maxHeight / rows) - 10;
                          return Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var i = 0; i < stars; i++)
                                Image.asset(
                                  'assets/images/rewards/star.png',
                                  width: size < fit ? size : fit,
                                  height: size < fit ? size : fit,
                                  excludeFromSemantics: true,
                                ),
                            ],
                          );
                        },
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          lesson.symbol,
                          style: TextStyle(
                            fontSize: 84,
                            fontWeight: FontWeight.w900,
                            color: widget.world.darkColor,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: const Key('speak_button'),
              onPressed: _speaking ? null : _speak,
              icon: Icon(
                _speaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
              ),
              label: Text(_speaking ? 'Speaking…' : 'Listen'),
            ),
          ],
        ),
      ),
    );
  }

  /// The question and three big tiles. Tapping an answer ends the quest
  /// straight away, so there is no separate Check button to hunt for.
  Widget _mathAnswers({required double tileHeight}) {
    final lesson = widget.lesson;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 2),
          // One line, shrunk to fit, so the tile sizing below stays exact.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              lesson.challenge,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    color: GameTokens.ink,
                  ),
            ),
          ),
        ),
        for (final option in _options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AnswerTile(
              key: Key('answer_$option'),
              label: option,
              picture: lesson.pictures[option],
              height: tileHeight,
              state: !_submitted
                  ? _TileState.idle
                  : option == lesson.answer
                      ? _TileState.correct
                      : option == _selected
                          ? _TileState.wrong
                          : _TileState.idle,
              onTap: _submitted
                  ? null
                  : () {
                      setState(() => _selected = option);
                      _finish(option == lesson.answer);
                    },
            ),
          ),
      ],
    );
  }

  Widget _buildIntro(Lesson lesson) => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              if (lesson.cover != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    lesson.cover!,
                    fit: BoxFit.cover,
                    cacheWidth: 640,
                    semanticLabel: lesson.title,
                    errorBuilder: (_, __, ___) => const SizedBox(height: 80),
                  ),
                )
              else
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    lesson.symbol,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: lesson.symbol.length > 5 ? 48 : 78,
                      fontWeight: FontWeight.w900,
                      color: widget.world.darkColor,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                lesson.subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                key: const Key('speak_button'),
                onPressed: _speaking ? null : _speak,
                icon: Icon(
                  _speaking
                      ? Icons.graphic_eq_rounded
                      : Icons.volume_up_rounded,
                ),
                label: Text(_speaking ? 'Speaking…' : 'Listen'),
              ),
            ],
          ),
        ),
      );

  /// True when this screen shows a text-only question whose Check Answer button
  /// is pinned below a scrolling answer list (the side-by-side layout only).
  bool get _pinsCheck =>
      !_isTracing &&
      (!_isStory || _storyPage >= widget.lesson.story.length) &&
      widget.lesson.pictures.isEmpty;

  /// Picture quizzes answer on a tap (no Check button), like the math quests;
  /// text-only quizzes keep select-then-check.
  Widget _buildQuestion({required bool pinned}) =>
      widget.lesson.pictures.isEmpty
          ? _buildChoiceQuestion(pinned: pinned)
          : Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
                child: _mathAnswers(tileHeight: 72),
              ),
            );

  /// Select an answer, then press Check Answer. When [pinned] (side-by-side
  /// layout) the button stays under the answers and only the answers scroll,
  /// so a 360 dp-high screen never hides it.
  Widget _buildChoiceQuestion({required bool pinned}) {
    // On a short landscape screen (a 360 dp phone) everything is compacted so
    // the question, three answers and the button all fit; answers stay at
    // least 44 dp tall.
    final short = pinned && MediaQuery.sizeOf(context).height < 420;
    final body = <Widget>[
      Text(
        widget.lesson.challenge,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: short ? 18 : null,
            ),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: short ? 6 : (pinned ? 12 : 18)),
      ..._options.map(
        (option) {
          final right = _submitted && option == widget.lesson.answer;
          final wrong = _submitted && option == _selected && !right;
          final tone = right
              ? const Color(0xFF1E8A4C)
              : wrong
                  ? const Color(0xFFC0392B)
                  : null;
          return Padding(
            padding: EdgeInsets.only(bottom: short ? 6 : 10),
            child: ChoiceChip(
              materialTapTargetSize:
                  short ? MaterialTapTargetSize.shrinkWrap : null,
              key: Key('answer_$option'),
              // Colour is never the only signal: a tick or a cross too.
              avatar: tone == null
                  ? null
                  : Icon(
                      right ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: tone,
                    ),
              label: SizedBox(
                width: double.infinity,
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              selected: _selected == option || right,
              selectedColor: right
                  ? const Color(0xFFC8F2D2)
                  : wrong
                      ? const Color(0xFFFFD9D2)
                      : null,
              side: tone == null ? null : BorderSide(color: tone, width: 3),
              onSelected:
                  _submitted ? null : (_) => setState(() => _selected = option),
              padding: EdgeInsets.symmetric(
                vertical: short ? 9 : (pinned ? 9 : 13),
                horizontal: 10,
              ),
            ),
          );
        },
      ),
      if (_submitted)
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 4),
          child: Semantics(
            liveRegion: true,
            child: Text(
              _selected == widget.lesson.answer
                  ? BatchText.forLocale(widget.lesson.locale).rightMessage
                  : BatchText.forLocale(widget.lesson.locale).tryAgainMessage,
              key: const Key('answer_feedback'),
              textAlign: TextAlign.center,
              style: scriptStyle(
                BatchText.forLocale(widget.lesson.locale).rightMessage,
                TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _selected == widget.lesson.answer
                      ? const Color(0xFF1B7A41)
                      : const Color(0xFF9C2C20),
                ),
              ),
            ),
          ),
        ),
    ];
    final check = FilledButton(
      style: short
          ? FilledButton.styleFrom(minimumSize: const Size.fromHeight(48))
          : null,
      key: const Key('check_answer'),
      onPressed: _selected == null || _submitted
          ? null
          : () => _finish(_selected == widget.lesson.answer),
      child: const Text('Check Answer'),
    );
    return Card(
      child: Padding(
        padding: EdgeInsets.all(short ? 10 : (pinned ? 14 : 20)),
        child: pinned
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: body,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  check,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [...body, const SizedBox(height: 8), check],
              ),
      ),
    );
  }

  Widget _buildStory({required bool pinned}) {
    if (_storyPage < widget.lesson.story.length) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                [
                  Icons.park_rounded,
                  Icons.auto_stories_rounded,
                  Icons.diversity_1_rounded,
                ][_storyPage % 3],
                color: widget.world.darkColor,
                size: 64,
              ),
              const SizedBox(height: 14),
              Text(
                widget.lesson.story[_storyPage],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              LinearProgressIndicator(
                value: (_storyPage + 1) / widget.lesson.story.length,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => setState(() => _storyPage++),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _storyPage == widget.lesson.story.length - 1
                      ? 'Answer a Question'
                      : 'Next Page',
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _buildQuestion(pinned: pinned);
  }

  /// Tracing: the shared handwriting engine checks the shape against the
  /// letter's font outline, so a scribble cannot finish the quest. The quest
  /// is finished by a letter that was really traced; mastery is a separate
  /// matter (see HandwritingPolicy) and is not awarded here.
  Widget _buildTracing() {
    final lesson = widget.lesson;
    final height = MediaQuery.sizeOf(context).height < 480 ? 255.0 : 320.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              lesson.challenge,
              textAlign: TextAlign.center,
              style: scriptStyle(
                lesson.challenge,
                Theme.of(context).textTheme.titleLarge!,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: height,
              child: WritingPad(
                key: ValueKey('trace_${lesson.id}_$_traceRound'),
                padKey: const Key('trace_pad'),
                glyph: lesson.symbol,
                mode: WriteMode.guided,
                text: BatchText.forLocale(lesson.locale),
                color: widget.world.darkColor,
                template: templateFor(lesson.symbol),
                mask: _glyphMask,
                locale: lesson.locale,
                onResult: (r) => setState(() => _traceOk = r.shapeOk),
                finish: FilledButton(
                  key: const Key('finish_trace'),
                  onPressed:
                      _traceOk && !_submitted ? () => _finish(true) : null,
                  child: const Text('I traced it!'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// After a quest: the cheering or winking lion (its words are painted in the
/// artwork, so they are announced through the image's label), what was earned,
/// and the two ways on. Side by side in landscape, scroll-safe on short screens.
class LessonResultDialog extends StatelessWidget {
  const LessonResultDialog({
    required this.correct,
    required this.text,
    required this.gained,
    required this.onBack,
    required this.onAgain,
    super.key,
  });

  final bool correct;
  final ResultText text;
  final int gained;
  final VoidCallback onBack;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final imageHeight = (size.height * .62).clamp(150.0, 320.0);
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: size.height - 32,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Semantics(
                image: true,
                label: correct ? 'Wonderful!' : 'Good try!',
                child: Image.asset(
                  correct
                      ? 'assets/images/feedback/wonderful.png'
                      : 'assets/images/feedback/good_try.png',
                  height: imageHeight,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                  errorBuilder: (_, __, ___) => SizedBox(
                    height: imageHeight,
                    child: Center(
                      child: Text(
                        correct ? 'Wonderful!' : 'Good try!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Builder(builder: (context) {
                      final message =
                          text.message(correct: correct, gained: gained);
                      return Text(
                        message,
                        style: scriptStyle(
                          message,
                          Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: GameTokens.ink,
                              ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('result_again'),
                      onPressed: onAgain,
                      child: Text(
                        text.playAgain,
                        textAlign: TextAlign.center,
                        style: scriptStyle(
                          text.playAgain,
                          const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const Key('result_back'),
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          GameTokens.minTouch,
                          GameTokens.minTouch,
                        ),
                      ),
                      child: Text(
                        text.backToMap,
                        textAlign: TextAlign.center,
                        style: scriptStyle(
                          text.backToMap,
                          const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TileState { idle, correct, wrong }

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.label,
    required this.height,
    required this.state,
    required this.onTap,
    this.picture,
    super.key,
  });

  final String label;

  /// Bundled picture shown beside the word; null for number answers.
  final String? picture;
  final double height;
  final _TileState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Colour is never the only signal: right/wrong also get an icon.
    final (fill, border, icon) = switch (state) {
      _TileState.idle => (Colors.white, const Color(0xFFCFC8E6), null),
      _TileState.correct => (
          const Color(0xFFC8F2D2),
          const Color(0xFF1E8A4C),
          Icons.check_circle_rounded,
        ),
      _TileState.wrong => (
          const Color(0xFFFFD9D2),
          const Color(0xFFC0392B),
          Icons.cancel_rounded,
        ),
    };
    return Semantics(
      button: true,
      label: switch (state) {
        _TileState.idle => 'Answer $label',
        _TileState.correct => 'Answer $label, correct',
        _TileState.wrong => 'Answer $label, not this one',
      },
      excludeSemantics: true,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: border, width: state == _TileState.idle ? 1.5 : 3),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: height,
            child: picture == null
                ? Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: border, size: 30),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: GameTokens.ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            picture!,
                            width: height - 12,
                            height: height - 12,
                            fit: BoxFit.cover,
                            cacheWidth: 240,
                            excludeFromSemantics: true,
                            errorBuilder: (_, __, ___) =>
                                SizedBox(width: height - 12),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: GameTokens.ink,
                              ),
                            ),
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(icon, color: border, size: 30),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
