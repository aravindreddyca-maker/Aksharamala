import 'package:flutter/material.dart';

import '../batch/batch_lesson.dart';
import '../models.dart';
import '../theme.dart';

Duration learningMotionDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 450);

class LearningVisualPanel extends StatelessWidget {
  const LearningVisualPanel({
    required this.lesson,
    required this.step,
    required this.color,
    super.key,
  });

  final BatchLesson lesson;
  final BatchStep step;
  final Color color;

  @override
  Widget build(BuildContext context) => switch (lesson.media.activity) {
        LearningVisualActivity.pictureWordMatch => PictureWordMatchingVisual(
            words: lesson.examples,
            images: lesson.media.images,
            color: color,
          ),
        LearningVisualActivity.phonicsBlend => PhonicsBlendingVisual(
            title: lesson.title,
            examples: lesson.examples,
            color: color,
          ),
        LearningVisualActivity.letterCombination =>
          LetterCombinationVisual(expression: lesson.title, color: color),
        LearningVisualActivity.wordBuilding => WordBuildingVisual(
            sentence:
                lesson.examples.isEmpty ? step.prompt : lesson.examples.first,
            color: color,
          ),
        LearningVisualActivity.counting => CountingLearningVisual(
            expression: lesson.title,
            color: color,
          ),
        LearningVisualActivity.dragArithmetic => DragArithmeticVisual(
            expression: lesson.title,
            color: color,
          ),
        LearningVisualActivity.guidedTracing => GuidedTracingVisual(
            glyph: lesson.symbol,
            color: color,
            child: const SizedBox.shrink(),
          ),
        LearningVisualActivity.none => _ConceptCard(
            text: lesson.symbol,
            color: color,
          ),
      };
}

class PictureWordMatchingVisual extends StatelessWidget {
  const PictureWordMatchingVisual({
    required this.words,
    required this.images,
    required this.color,
    super.key,
  });

  final List<String> words;
  final Map<String, String> images;
  final Color color;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final word in words.take(4))
            Semantics(
              image: images.containsKey(word),
              label: word,
              child: Container(
                width: 112,
                constraints: const BoxConstraints(minHeight: 112),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (images[word] case final path?)
                      Image.asset(
                        path,
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                        cacheWidth: 216,
                        errorBuilder: (_, __, ___) =>
                            _MissingPicture(color: color),
                      )
                    else
                      _MissingPicture(color: color),
                    const SizedBox(height: 4),
                    Text(
                      word,
                      textAlign: TextAlign.center,
                      style: scriptStyle(
                        word,
                        const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
}

class PhonicsBlendingVisual extends StatelessWidget {
  const PhonicsBlendingVisual({
    required this.title,
    required this.examples,
    required this.color,
    super.key,
  });

  final String title;
  final List<String> examples;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final word = examples.isEmpty ? title : examples.first;
    final letters = word.split('');
    return AnimatedSwitcher(
      duration: learningMotionDuration(context),
      child: Column(
        key: ValueKey(word),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              for (final letter in letters)
                _SoundTile(text: letter, color: color),
            ],
          ),
          const SizedBox(height: 14),
          const Icon(Icons.arrow_downward_rounded),
          Text(
            word,
            style: TextStyle(
              color: color,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class LetterCombinationVisual extends StatelessWidget {
  const LetterCombinationVisual({
    required this.expression,
    required this.color,
    super.key,
  });

  final String expression;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final equals = expression.split('=');
    final inputs = equals.first.split('+').map((part) => part.trim()).toList();
    final result = equals.length > 1 ? equals.last.trim() : expression;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            for (var i = 0; i < inputs.length; i++) ...[
              AnimatedSlide(
                duration:
                    reduced ? Duration.zero : const Duration(milliseconds: 500),
                offset: reduced ? Offset.zero : Offset(i == 0 ? .08 : -.08, 0),
                child: _ScriptTile(text: inputs[i], color: color),
              ),
              if (i < inputs.length - 1)
                const Text('+', style: TextStyle(fontSize: 34)),
            ],
          ],
        ),
        const SizedBox(height: 12),
        const Icon(Icons.arrow_downward_rounded),
        const SizedBox(height: 6),
        _ScriptTile(text: result, color: color, emphasized: true),
      ],
    );
  }
}

class WordBuildingVisual extends StatelessWidget {
  const WordBuildingVisual({
    required this.sentence,
    required this.color,
    super.key,
  });

  final String sentence;
  final Color color;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final word
              in sentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty))
            _ScriptTile(text: word, color: color),
        ],
      );
}

class CountingLearningVisual extends StatelessWidget {
  const CountingLearningVisual({
    required this.expression,
    required this.color,
    super.key,
  });

  final String expression;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final values = RegExp(r'\d+')
        .allMatches(expression)
        .map((m) => int.parse(m.group(0)!))
        .toList();
    final count = values.isEmpty ? 5 : values.last.clamp(1, 20);
    return Semantics(
      label: '$count counters',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 7,
        runSpacing: 7,
        children: [
          for (var i = 0; i < count; i++)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

class DragArithmeticVisual extends StatefulWidget {
  const DragArithmeticVisual({
    required this.expression,
    required this.color,
    super.key,
  });

  final String expression;
  final Color color;

  @override
  State<DragArithmeticVisual> createState() => _DragArithmeticVisualState();
}

class _DragArithmeticVisualState extends State<DragArithmeticVisual> {
  int? placed;

  @override
  Widget build(BuildContext context) {
    final values = RegExp(r'\d+')
        .allMatches(widget.expression)
        .map((m) => int.parse(m.group(0)!))
        .toList();
    final draggable = values.isEmpty ? 1 : values.first;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Draggable<int>(
          data: draggable,
          feedback: Material(
            color: Colors.transparent,
            child: _NumberTile(value: draggable, color: widget.color),
          ),
          childWhenDragging: const SizedBox(width: 64, height: 64),
          child: _NumberTile(value: draggable, color: widget.color),
        ),
        const SizedBox(height: 16),
        DragTarget<int>(
          onAcceptWithDetails: (details) =>
              setState(() => placed = details.data),
          builder: (context, candidates, rejects) => Container(
            width: 132,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: candidates.isEmpty
                  ? Colors.white
                  : widget.color.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: widget.color, width: 3),
            ),
            child: Text(
              placed == null ? 'Drag here' : '$placed',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class GuidedTracingVisual extends StatelessWidget {
  const GuidedTracingVisual({
    required this.glyph,
    required this.color,
    required this.child,
    super.key,
  });

  final String glyph;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Guided tracing practice for $glyph; practice only',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: child,
        ),
      );
}

class _MissingPicture extends StatelessWidget {
  const _MissingPicture({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 72,
        height: 72,
        child: Icon(Icons.image_not_supported_rounded, color: color, size: 38),
      );
}

class _ConceptCard extends StatelessWidget {
  const _ConceptCard({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
        child: _ScriptTile(text: text, color: color, emphasized: true),
      );
}

class _SoundTile extends StatelessWidget {
  const _SoundTile({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      );
}

class _ScriptTile extends StatelessWidget {
  const _ScriptTile({
    required this.text,
    required this.color,
    this.emphasized = false,
  });
  final String text;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: emphasized ? color : color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: scriptStyle(
            text,
            TextStyle(
              color: emphasized ? Colors.white : GameTokens.ink,
              fontSize: 28,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.value, required this.color});
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(18)),
        child: Text('$value',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900)),
      );
}
