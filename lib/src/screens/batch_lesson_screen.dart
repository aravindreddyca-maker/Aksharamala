import 'dart:math';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../app.dart';
import '../batch/batch_content.dart';
import '../batch/batch_lesson.dart';
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

typedef GlyphMaskLoader = Future<GlyphMask> Function(String glyph);

/// Plays a [BatchLesson]: its steps one after another. Questions must be
/// answered correctly to move on; a wrong tap costs the "first try" (the lesson
/// then pays 1 star instead of 3, like every other quest). Writing is practice:
/// it is checked by the handwriting engine but never blocks or pays.
class BatchLessonScreen extends StatefulWidget {
  const BatchLessonScreen({
    required this.world,
    required this.lesson,
    super.key,
    this.random,
    this.maskLoader,
  });

  final LearningWorld world;
  final BatchLesson lesson;
  final Random? random;

  /// Draws a glyph from the font; tests pass a stand-in.
  final GlyphMaskLoader? maskLoader;

  @override
  State<BatchLessonScreen> createState() => _BatchLessonScreenState();
}

class _BatchLessonScreenState extends State<BatchLessonScreen> {
  final _speech = const SpeechService();
  late final Random _random = widget.random ?? Random();
  final Map<int, List<String>> _shuffled = {};
  final Map<String, Future<GlyphMask>> _masks = {};

  int _index = 0;
  int _mistakes = 0;
  bool _speaking = false;
  bool _finished = false;

  /// Options already tried wrongly on the current step.
  final Set<String> _wrong = {};
  String? _right;
  final List<int> _counted = [];
  bool _wroteOk = false;
  int _writeRound = 0;

  BatchStep get _step => widget.lesson.steps[_index];
  bool get _isLast => _index == widget.lesson.steps.length - 1;
  BatchText get _text => BatchText.forLocale(widget.lesson.locale);
  Color get _color => widget.world.darkColor;

  List<String> _optionsFor(int index) => _shuffled.putIfAbsent(index, () {
        final options = [...widget.lesson.steps[index].options];
        if (options.length < 2) return options;
        final before = [...options];
        for (var i = 0; i < 8; i++) {
          options.shuffle(_random);
          // Never leave the right answer in the slot where the pack lists it.
          if (!listEquals(options, before)) break;
        }
        return options;
      });

  Future<GlyphMask> _maskFor(String glyph) => _masks.putIfAbsent(
        glyph,
        () => (widget.maskLoader ?? rasteriseGlyph)(glyph),
      );

  Future<void> _speak(String text) async {
    setState(() => _speaking = true);
    final supported = await _speech.speak(text, widget.lesson.locale);
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

  void _pick(String option) {
    if (_right != null || _wrong.contains(option)) return;
    if (option == _step.answer) {
      setState(() => _right = option);
    } else {
      setState(() {
        _wrong.add(option);
        _mistakes++;
      });
    }
  }

  bool get _canContinue => switch (_step.kind) {
        StepKind.listen || StepKind.write => true,
        _ => _right != null,
      };

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _wrong.clear();
      _right = null;
      _counted.clear();
      _wroteOk = false;
      _writeRound++;
    });
  }

  Future<void> _finish() async {
    if (_finished) return;
    setState(() => _finished = true);
    final correct = _mistakes == 0;
    final gained = await AppScope.of(context).recordResult(
      world: widget.world,
      lesson: widget.lesson,
      correct: correct,
    );
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
            _finished = false;
            _index = 0;
            _mistakes = 0;
            _wrong.clear();
            _right = null;
            _counted.clear();
            _wroteOk = false;
            _writeRound++;
            _shuffled.clear();
          });
        },
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
        title: Text(
          lesson.title,
          style: scriptStyle(lesson.title, const TextStyle()),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StarPill(AppScope.of(context).activeProfile?.stars ?? 0),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 600;
          final pad = box.maxHeight < 400 ? 10.0 : 16.0;
          final prompt = _promptCard();
          final visual = _visual();
          final activity = _activity();
          if (!wide) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  prompt,
                  const SizedBox(height: 10),
                  SizedBox(height: 170, child: visual),
                  const SizedBox(height: 10),
                  activity,
                  const SizedBox(height: 10),
                  _nextButton(),
                ],
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(pad, 4, pad, pad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      prompt,
                      const SizedBox(height: 10),
                      Expanded(child: visual),
                    ],
                  ),
                ),
                SizedBox(width: pad),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(child: activity),
                      ),
                      const SizedBox(height: 8),
                      _nextButton(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // -- prompt ---------------------------------------------------------------

  Widget _promptCard() {
    final step = _step;
    final total = widget.lesson.steps.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var i = 0; i < total; i++)
                  Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color:
                            i <= _index ? _color : _color.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Semantics(
              header: true,
              child: Text(
                step.prompt,
                key: const Key('step_prompt'),
                textAlign: TextAlign.center,
                style: scriptStyle(
                  step.prompt,
                  Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                        color: GameTokens.ink,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: FilledButton.tonalIcon(
                key: const Key('speak_button'),
                onPressed: _speaking ? null : () => _speak(step.speech),
                icon: Icon(
                  _speaking
                      ? Icons.graphic_eq_rounded
                      : Icons.volume_up_rounded,
                ),
                label: Text(_speaking ? 'Speaking…' : 'Listen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- left side: what to look at ---------------------------------------------

  Widget _visual() {
    final step = _step;
    final glyph = step.glyph;
    final isNumbers = widget.lesson.kind == LessonKind.numbers;
    final showStars = step.kind == StepKind.listen && isNumbers;
    if (step.kind == StepKind.count) {
      return Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _countBoard(step.quantity ?? 0),
        ),
      );
    }
    if (step.kind == StepKind.compare || step.kind == StepKind.pickQuantity) {
      return Card(
        color: Colors.white,
        child: Center(
          child: step.kind == StepKind.pickQuantity
              ? _bigGlyph(glyph ?? '')
              : const Icon(Icons.compare_arrows_rounded, size: 72),
        ),
      );
    }
    if (step.kind == StepKind.write) {
      return Card(
        color: Colors.white,
        child: Center(
          child: _guidedHidden()
              ? Icon(Icons.edit_rounded, size: 80, color: _color)
              : _bigGlyph(glyph ?? ''),
        ),
      );
    }
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(child: Center(child: _bigGlyph(glyph ?? ''))),
            if (showStars)
              SizedBox(height: 60, child: _starsRow(step.quantity ?? 0, 36)),
          ],
        ),
      ),
    );
  }

  bool _guidedHidden() => _step.writeMode == WriteMode.independent;

  Widget _bigGlyph(String glyph, {bool faint = false}) => Semantics(
        label: glyph,
        excludeSemantics: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              glyph,
              key: const Key('big_glyph'),
              style: scriptStyle(
                glyph,
                TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  color: faint ? _color.withValues(alpha: .18) : _color,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _starsRow(int n, double size) {
    if (n == 0) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < n; i++)
          Image.asset(
            'assets/images/rewards/star.png',
            width: size,
            height: size,
            excludeFromSemantics: true,
          ),
      ],
    );
  }

  Widget _countBoard(int n) {
    if (n == 0) {
      return Center(
        child: Semantics(
          label: 'An empty box',
          child: Icon(
            Icons.inbox_outlined,
            size: 96,
            color: _color.withValues(alpha: .5),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final perRow = n <= 5 ? n : 5;
        final rows = (n / perRow).ceil();
        final size = min(
          (box.maxWidth / perRow) - 10,
          (box.maxHeight / rows) - 10,
        ).clamp(34.0, 88.0).toDouble();
        return Column(
          children: [
            Expanded(
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < n; i++) _countStar(i, size),
                  ],
                ),
              ),
            ),
            Text(
              '${_counted.length}',
              key: const Key('count_so_far'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _color,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _countStar(int i, double size) {
    final order = _counted.indexOf(i);
    final done = order >= 0;
    return Semantics(
      button: true,
      label: done ? 'Star counted, number ${order + 1}' : 'Star, tap to count',
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('count_star_$i'),
        onTap: done || _right != null
            ? null
            : () => setState(() => _counted.add(i)),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: done ? 1 : .5,
                child: Image.asset(
                  'assets/images/rewards/star.png',
                  width: size,
                  height: size,
                  excludeFromSemantics: true,
                ),
              ),
              if (done)
                Container(
                  width: size * .55,
                  height: size * .55,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${order + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -- right side: what to do -------------------------------------------------

  Widget _activity() {
    final step = _step;
    switch (step.kind) {
      case StepKind.listen:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            // What the Listen button says, so the letter and its word are
            // read as well as heard.
            child: Text(
              step.speech,
              key: const Key('listen_line'),
              textAlign: TextAlign.center,
              style: scriptStyle(
                step.speech,
                const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        );
      case StepKind.write:
        return _writeActivity(step);
      default:
        return _answers(step);
    }
  }

  Widget _answers(BatchStep step) {
    final options = _optionsFor(_index);
    final message = _right != null
        ? _text.rightMessage
        : _wrong.isNotEmpty
            ? _text.tryAgainMessage
            : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AnswerCard(
                  key: Key('answer_$option'),
                  label: option,
                  kind: step.kind,
                  picture: step.pictures[option],
                  color: _color,
                  state: _right == option
                      ? _Mark.correct
                      : _wrong.contains(option)
                          ? _Mark.wrong
                          : _Mark.idle,
                  enabled: _right == null && !_wrong.contains(option),
                  onTap: () => _pick(option),
                ),
              ),
            SizedBox(
              height: 26,
              child: message == null
                  ? null
                  : Semantics(
                      liveRegion: true,
                      child: Text(
                        message,
                        key: const Key('feedback_message'),
                        textAlign: TextAlign.center,
                        style: scriptStyle(
                          message,
                          TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _right != null
                                ? const Color(0xFF1B7A41)
                                : const Color(0xFF8A4B00),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _writeActivity(BatchStep step) {
    final glyph = step.glyph ?? '';
    final template = templateFor(glyph);
    final padSize = MediaQuery.sizeOf(context).height < 480 ? 230.0 : 300.0;
    Widget pad(GlyphMask? mask) => SizedBox(
          height: padSize,
          child: WritingPad(
            key: ValueKey('pad_${_index}_$_writeRound'),
            glyph: glyph,
            mode: step.writeMode,
            text: _text,
            color: _color,
            template: template,
            mask: mask,
            locale: widget.lesson.locale,
            onResult: (r) => setState(() => _wroteOk = r.shapeOk),
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: template != null
            ? pad(null)
            : FutureBuilder<GlyphMask>(
                future: _maskFor(glyph),
                builder: (context, snap) => snap.hasData
                    ? pad(snap.data)
                    : SizedBox(
                        height: padSize,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
              ),
      ),
    );
  }

  Widget _nextButton() {
    final writing = _step.kind == StepKind.write;
    final label = _isLast ? 'Finish' : (writing && !_wroteOk ? 'Skip' : 'Next');
    return FilledButton(
      key: const Key('batch_next'),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: _canContinue && !_finished ? _next : null,
      child: Text(label),
    );
  }
}

enum _Mark { idle, correct, wrong }

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.label,
    required this.kind,
    required this.color,
    required this.state,
    required this.enabled,
    required this.onTap,
    super.key,
    this.picture,
  });

  final String label;
  final StepKind kind;
  final String? picture;
  final Color color;
  final _Mark state;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = switch (state) {
      _Mark.correct => const Color(0xFF2E9D57),
      _Mark.wrong => const Color(0xFFD9822B),
      _Mark.idle => color,
    };
    final fill = switch (state) {
      _Mark.correct => const Color(0xFFE3F6E9),
      _Mark.wrong => const Color(0xFFF1EEEA),
      _Mark.idle => Colors.white,
    };
    final stars = kind == StepKind.pickQuantity ? int.tryParse(label) : null;
    final semantic =
        stars != null ? '$stars ${stars == 1 ? 'star' : 'stars'}' : label;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '$semantic${state == _Mark.correct ? ', correct' : ''}'
          '${state == _Mark.wrong ? ', try another' : ''}',
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: state == _Mark.idle ? 2 : 3),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: GameTokens.minTouch + 24,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (picture != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          picture!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 64,
                            height: 64,
                          ),
                        ),
                      ),
                    ),
                  if (stars != null)
                    Flexible(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 3,
                        runSpacing: 3,
                        children: [
                          for (var i = 0; i < stars; i++)
                            Image.asset(
                              'assets/images/rewards/star.png',
                              width: 30,
                              height: 30,
                              excludeFromSemantics: true,
                            ),
                          if (stars == 0)
                            Text(
                              '—',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: scriptStyle(
                          label,
                          TextStyle(
                            fontSize: kind == StepKind.pickWord ? 30 : 38,
                            fontWeight: FontWeight.w900,
                            color: GameTokens.ink,
                          ),
                        ),
                      ),
                    ),
                  if (state == _Mark.correct)
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF2E9D57),
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
