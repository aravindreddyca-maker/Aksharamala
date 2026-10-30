import 'package:flutter/material.dart';

import '../alphabet/alphabet_data.dart';
import '../app.dart';
import '../batch/batch_content.dart' show BatchText;
import '../batch/batch_lesson.dart' show WriteMode;
import '../handwriting/glyph_mask.dart';
import '../handwriting/glyph_mask_raster.dart';
import '../handwriting/handwriting_registry.dart';
import '../models.dart';
import '../services/speech_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/writing_pad.dart';

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
    final next = [
      for (var i = 0; i < total; i++)
        if (!done.contains(letters.lessonId(i))) i,
    ].firstOrNull;
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  finished.length == total
                      ? 'All $total letters traced. Well done!'
                      : '${finished.length} of $total letters traced',
                  key: const Key('alphabet_progress_text'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (next != null)
                FilledButton.icon(
                  key: const Key('alphabet_continue'),
                  onPressed: () => _open(context, next),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    finished.isEmpty
                        ? 'Start with the first letter'
                        : 'Next letter',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: total == 0 ? 0 : finished.length / total,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
            color: world.darkColor,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < total; i++)
                _LetterTile(
                  key: Key('letter_tile_$i'),
                  letter: letters.letters[i],
                  done: done.contains(letters.lessonId(i)),
                  isNext: i == next,
                  color: world.darkColor,
                  onTap: () => _open(context, i),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, int index) => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LetterScreen(
            world: world,
            letters: letters,
            index: index,
            maskLoader: maskLoader,
          ),
        ),
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
  });

  final AlphabetLetter letter;
  final bool done;
  final bool isNext;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${letter.glyph}${done ? ', traced' : ''}'
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
                            fontWeight: FontWeight.w900,
                            color: GameTokens.ink,
                          ),
                        ),
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
  });

  final LearningWorld world;
  final AlphabetSet letters;
  final int index;
  final LetterMaskLoader? maskLoader;

  @override
  State<LetterScreen> createState() => _LetterScreenState();
}

class _LetterScreenState extends State<LetterScreen> {
  final _speech = const SpeechService();
  GlyphMask? _mask;
  bool _traced = false;
  int _gained = 0;
  bool _speaking = false;

  AlphabetLetter get _letter => widget.letters.letters[widget.index];
  String get _lessonId => widget.letters.lessonId(widget.index);
  bool get _last => widget.index == widget.letters.letters.length - 1;

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
      subtitle: 'Trace the letter',
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
    if (mounted) setState(() => _gained = gained);
  }

  void _go(int index) {
    if (index < 0 || index >= widget.letters.letters.length) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LetterScreen(
          world: widget.world,
          letters: widget.letters,
          index: index,
          maskLoader: widget.maskLoader,
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
    final text = BatchText.forLocale(widget.letters.locale);
    final nextLabel =
        _last ? 'All letters' : 'Next: ${letters[widget.index + 1].glyph}';
    return GradientScaffold(
      colors: [
        widget.world.color.withValues(alpha: .18),
        const Color(0xFFFFFBF4),
      ],
      appBar: AppBar(
        title: Text('${widget.index + 1} / ${letters.length}'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            key: const Key('prev_letter'),
            tooltip: 'Previous letter',
            onPressed: widget.index > 0 ? () => _go(widget.index - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded, size: 32),
          ),
          IconButton(
            key: const Key('next_arrow'),
            tooltip: 'Next letter',
            onPressed: _last ? null : () => _go(widget.index + 1),
            icon: const Icon(Icons.chevron_right_rounded, size: 32),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StarPill(controller.activeProfile?.stars ?? 0),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 600;
          final show = _ShowLetter(
            letter: _letter,
            color: widget.world.darkColor,
            speaking: _speaking,
            onSpeak: _speak,
            earned: _gained,
            done: finished,
          );
          final pad = SizedBox(
            height: wide ? (box.maxHeight < 420 ? 250.0 : 330.0) : 320.0,
            child: WritingPad(
              key: ValueKey('trace_${widget.index}'),
              padKey: const Key('letter_pad'),
              glyph: _letter.glyph,
              mode: WriteMode.guided,
              text: text,
              color: widget.world.darkColor,
              template: templateFor(_letter.glyph),
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
                ),
                onPressed: finished
                    ? () =>
                        _last ? Navigator.pop(context) : _go(widget.index + 1)
                    : null,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: Text(
                  nextLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: scriptStyle(nextLabel, const TextStyle()),
                ),
              ),
            ),
          );
          if (!wide) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 230, child: show),
                  const SizedBox(height: 10),
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(12), child: pad))
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 4, child: show),
                const SizedBox(width: 14),
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: pad,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The picture word, with the letter it starts with picked out in colour.
TextSpan _wordSpan(AlphabetLetter letter, Color color) {
  final word = letter.word!;
  if (!word.startsWith(letter.glyph)) return TextSpan(text: word);
  return TextSpan(
    children: [
      TextSpan(text: letter.glyph, style: TextStyle(color: color)),
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
                              fontWeight: FontWeight.w900,
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
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                      )
                    : null,
              ),
            ],
          ),
        ),
      );
}
