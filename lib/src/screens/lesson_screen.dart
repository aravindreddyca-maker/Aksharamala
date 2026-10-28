import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../services/speech_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({required this.world, required this.lesson, super.key});

  final LearningWorld world;
  final Lesson lesson;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final _speech = const SpeechService();
  String? _selected;
  bool _submitted = false;
  bool _speaking = false;
  int _storyPage = 0;
  List<Offset?> _tracePoints = [];

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
    final supported = await _speech.speak(
      widget.lesson.speech,
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
    final gained = await AppScope.of(context).recordResult(
      world: widget.world,
      lesson: widget.lesson,
      correct: correct,
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          correct ? Icons.celebration_rounded : Icons.eco_rounded,
          color: correct ? const Color(0xFFF2A900) : Colors.green,
          size: 54,
        ),
        title: Text(correct ? 'Wonderful!' : 'Good try!'),
        content: Text(
          correct
              ? 'You earned $gained stars and completed this quest.'
              : 'You earned a courage star. Try the quest again to master it!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to map'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _submitted = false;
                _selected = null;
                _tracePoints = [];
              });
            },
            child: const Text('Play again'),
          ),
        ],
      ),
    );
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
                  ? _buildStory()
                  : _buildQuestion();
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
                  child: SingleChildScrollView(child: activity),
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
        for (final option in lesson.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MathTile(
              key: Key('answer_$option'),
              label: option,
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

  Widget _buildQuestion() => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.lesson.challenge,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ...widget.lesson.options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChoiceChip(
                    key: Key('answer_$option'),
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
                    selected: _selected == option,
                    onSelected: _submitted
                        ? null
                        : (_) => setState(() => _selected = option),
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('check_answer'),
                onPressed: _selected == null || _submitted
                    ? null
                    : () => _finish(_selected == widget.lesson.answer),
                child: const Text('Check Answer'),
              ),
            ],
          ),
        ),
      );

  Widget _buildStory() {
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
    return _buildQuestion();
  }

  Widget _buildTracing() => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Text(
                widget.lesson.challenge,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.world.color, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    key: const Key('trace_pad'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) =>
                        setState(() => _tracePoints.add(details.localPosition)),
                    onPanUpdate: (details) =>
                        setState(() => _tracePoints.add(details.localPosition)),
                    onPanEnd: (_) => setState(() => _tracePoints.add(null)),
                    child: CustomPaint(
                      painter: _TracePainter(
                        points: _tracePoints,
                        guide: widget.lesson.symbol,
                        color: widget.world.darkColor,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _tracePoints = []),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('finish_trace'),
                      onPressed: _tracePoints.whereType<Offset>().length < 12 ||
                              _submitted
                          ? null
                          : () => _finish(true),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('I traced it!'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

enum _TileState { idle, correct, wrong }

class _MathTile extends StatelessWidget {
  const _MathTile({
    required this.label,
    required this.height,
    required this.state,
    required this.onTap,
    super.key,
  });

  final String label;
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
            child: Center(
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
            ),
          ),
        ),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  const _TracePainter({
    required this.points,
    required this.guide,
    required this.color,
  });

  final List<Offset?> points;
  final String guide;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePainter = TextPainter(
      text: TextSpan(
        text: guide,
        style: TextStyle(
          fontSize: 240,
          fontWeight: FontWeight.w900,
          color: color.withValues(alpha: .13),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    guidePainter.paint(
      canvas,
      Offset(
        (size.width - guidePainter.width) / 2,
        (size.height - guidePainter.height) / 2,
      ),
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) =>
      oldDelegate.points != points;
}
