import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../app.dart';
import '../art/art_picture.dart';
import '../models.dart';
import '../result_text.dart';
import '../screens/lesson_navigation.dart';
import '../widgets/fit_content.dart';
import '../screens/lesson_screen.dart' show LessonResultDialog;
import '../services/speech_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'teaching_flow.dart';
import 'teaching_plan.dart';
import 'teaching_progress.dart';
import 'teaching_visuals.dart';

/// Plays a taught lesson one step at a time: introduce, demonstrate, guided
/// try, independent practice, understanding check, then mastery or remediation.
/// All the rules live in [TeachingFlow]; this draws them.
///
/// Lessons with no plan never reach this screen (see world_map_screen.dart).
/// How long the score page ignores taps after it appears.
const resultDebounce = Duration(milliseconds: 600);

class TeachingLessonScreen extends StatefulWidget {
  const TeachingLessonScreen({
    required this.world,
    required this.lesson,
    required this.plan,
    super.key,
    this.speech = const SpeechService(),
    this.seed,
  });

  final LearningWorld world;
  final Lesson lesson;
  final TeachingPlan plan;
  final SpeechService speech;

  /// Seeds the answer shuffle (tests pass one; the app picks its own).
  final int? seed;

  @override
  State<TeachingLessonScreen> createState() => _TeachingLessonScreenState();
}

class _TeachingLessonScreenState extends State<TeachingLessonScreen> {
  late TeachingFlow _flow;
  bool _speaking = false;
  bool _voiceMissing = false;
  bool _handled = false;
  int _gained = 0;
  bool _started = false;
  TeachingPhase? _savedPhase;
  int _savedCycle = -1;

  /// The score page ignores taps for a moment after it appears, so a quick
  /// double tap on the last check answer cannot skip it.
  bool _resultLocked = false;
  bool _wasResult = false;
  Timer? _lockTimer;

  Color get _color => widget.world.darkColor;
  String get _locale => widget.plan.locale;

  @override
  void initState() {
    super.initState();
    _flow = TeachingFlow(
      plan: widget.plan,
      initial: TeachingProgress.empty,
      seed: widget.seed ?? DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Resume from what was saved for this child.
    final saved = AppScope.of(context).teachingProgressFor(widget.lesson.id);
    _flow = TeachingFlow(
      plan: widget.plan,
      initial: saved,
      seed: widget.seed ?? DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterChange());
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    widget.speech.stop();
    super.dispose();
  }

  // -- state changes ------------------------------------------------------------

  void _change(VoidCallback action) {
    setState(action);
    _afterChange();
  }

  /// Saves where the child is whenever a phase begins, and records the end.
  void _afterChange() {
    if (!mounted) return;
    final controller = AppScope.of(context);
    final phase = _flow.phase;
    if (phase.isResult && !_wasResult) {
      _resultLocked = true;
      _lockTimer?.cancel();
      _lockTimer = Timer(resultDebounce, () {
        if (mounted) setState(() => _resultLocked = false);
      });
    }
    _wasResult = phase.isResult;
    if (phase != _savedPhase || _flow.remediationCycle != _savedCycle) {
      _savedPhase = phase;
      _savedCycle = _flow.remediationCycle;
      if (!phase.isTerminal) {
        unawaited(
          controller.saveTeachingProgress(widget.lesson.id, _flow.progress),
        );
      }
    }
    if (phase.isTerminal && !_handled) {
      _handled = true;
      unawaited(_finish());
    }
  }

  Future<void> _finish() async {
    final controller = AppScope.of(context);
    if (_flow.phase == TeachingPhase.mastered) {
      final gained = await controller.recordTeachingMastery(
        world: widget.world,
        lesson: widget.lesson,
        teaching: _flow.progress,
      );
      if (!mounted) return;
      setState(() => _gained = gained);
      final onNext = nextLessonAction(
        context,
        widget.world,
        widget.lesson,
        correct: true,
      );
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => LessonResultDialog(
          correct: true,
          text: ResultText.forLocale(_locale),
          gained: gained,
          onNext: onNext,
          onBack: () {
            Navigator.pop(dialogContext);
            Navigator.pop(context);
          },
          onAgain: () {
            Navigator.pop(dialogContext);
            _restart();
          },
        ),
      );
    } else {
      await controller.recordTeachingNeedsSupport(
        lesson: widget.lesson,
        teaching: _flow.progress,
      );
    }
  }

  void _restart() {
    if (!mounted) return;
    _handled = false;
    _savedPhase = null;
    _change(() {
      _flow.restart();
      _voiceMissing = false;
    });
  }

  Future<void> _speak(String text) async {
    setState(() => _speaking = true);
    final ok = await widget.speech.speak(text, _locale);
    if (!mounted) return;
    setState(() {
      _speaking = false;
      _voiceMissing = !ok;
    });
  }

  void _onPick(String option) {
    final result = _flow.pick(option);
    if (result.ignored) return;
    if (_flow.phase.isFeedbackQuestion) {
      result.correct
          ? HapticFeedback.lightImpact()
          : HapticFeedback.mediumImpact();
    }
    setState(() {});
  }

  // -- build ---------------------------------------------------------------------

  /// The lesson title would name the answer of a check (or a practice item),
  /// so those phases show a neutral title.
  String get _title {
    switch (_flow.phase) {
      case TeachingPhase.practice:
        return 'Practise';
      case TeachingPhase.check:
      case TeachingPhase.checkResult:
      case TeachingPhase.remediationCheck:
      case TeachingPhase.remediationResult:
        return 'Show what you know';
      default:
        return widget.plan.title.isEmpty
            ? widget.lesson.title
            : widget.plan.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _title;
    final size = MediaQuery.sizeOf(context);
    // A phone held sideways: every dp counts.
    final compact = size.height < 500 && size.width >= 560;
    return GradientScaffold(
      colors: [
        widget.world.color.withValues(alpha: .18),
        const Color(0xFFFFFBF4),
      ],
      appBar: AppBar(
        key: const Key('teaching_screen'),
        toolbarHeight: compact ? 44 : null,
        title: Text(
          title,
          key: const Key('teaching_title'),
          style: scriptStyle(title, const TextStyle()),
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
          final pad = box.maxWidth < 420 ? 12.0 : 16.0;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, compact ? 0 : 4),
                child: _PhaseIndicator(
                    flow: _flow, color: _color, compact: compact),
              ),
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey(
                    '${_flow.phase.name}_${_flow.index}_${_flow.remediationCycle}',
                  ),
                  child: _body(box, pad, compact),
                ),
              ),
              if (!_flow.phase.isTerminal)
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, 2, pad, compact ? 4 : 8),
                  child: _actionBar(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BoxConstraints box, double pad, bool compact) {
    final phase = _flow.phase;
    if (phase == TeachingPhase.mastered) return _masteredCard();
    if (phase == TeachingPhase.needsSupport) return _supportCard();
    if (phase.isResult) {
      return _scroll(pad, _resultPanel());
    }
    final step = _flow.step;
    final q = _flow.question;
    final visual = step?.visual ?? q?.visual ?? TeachingVisual.none;
    final isQuestion = q != null;
    final audioOnly = q != null && visual.type == VisualType.none;
    final itemId = step?.id ?? q?.id ?? '';
    final Widget? visualWidget = audioOnly
        ? _audioTile(q)
        : visual.type == VisualType.none
            ? null
            : _visualCard(visual, itemId, isQuestion);
    if (compact) {
      // Phone on its side: picture on the left, scaled to fit with its
      // caption; prompt pinned above the options on the right.
      final bigPicture = visual.type != VisualType.none && !audioOnly;
      final right = q != null
          ? _compactQuestion(q)
          : FitContent(
              alignment: Alignment.center,
              child: _stepPanel(step!),
            );
      return Padding(
        padding: EdgeInsets.fromLTRB(pad, 2, pad, 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (visualWidget != null) ...[
              Expanded(
                flex: bigPicture ? 5 : 3,
                child: bigPicture
                    ? _visualCard(visual, itemId, isQuestion, fill: true)
                    : _scaled(visualWidget),
              ),
              SizedBox(width: pad),
            ],
            Expanded(flex: bigPicture ? 5 : 7, child: right),
          ],
        ),
      );
    }
    final panel = step != null ? _stepPanel(step) : _questionPanel(q!);
    final wide = box.maxWidth >= 700 && visualWidget != null;
    if (wide) {
      return Padding(
        padding: EdgeInsets.fromLTRB(pad, 4, pad, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: _scaled(visualWidget)),
            SizedBox(width: pad),
            Expanded(
              flex: 6,
              child: FitContent(child: panel),
            ),
          ],
        ),
      );
    }
    return _scroll(
      pad,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (visualWidget != null) ...[
            visualWidget,
            const SizedBox(height: 10),
          ],
          panel,
        ],
      ),
    );
  }

  /// Shrinks [child] (never enlarges it) so all of it, caption included, fits
  /// the pane.
  Widget _scaled(Widget child) => LayoutBuilder(
        builder: (context, c) => Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(width: c.maxWidth, child: child),
          ),
        ),
      );

  /// Short wide screens: a compact prompt row, a pinned strip for hints and
  /// feedback, and the options in two columns in the space that is left.
  Widget _compactQuestion(TeachingQuestion q) {
    final audioOnly = q.visual.type == VisualType.none;
    final options = _flow.optionsFor(q);
    final hints = _hintTexts(compact: true);
    final feedback = _feedback(q, compact: true);
    final hasStrip = _flow.shownHints.isNotEmpty ||
        _flow.solved && _flow.phase.isFeedbackQuestion ||
        _flow.wrongFeedback != null;
    return LayoutBuilder(
      builder: (context, space) => MediaQuery.withClampedTextScaling(
        // Phone on its side: past 130% the question, hint, note and options
        // cannot share a 360dp-tall screen, so this pane stops growing there
        // (the same limit the quest cards use).
        maxScaleFactor: 1.3,
        child: _compactColumn(
          space.maxHeight,
          q,
          audioOnly: audioOnly,
          options: options,
          hints: hints,
          feedback: feedback,
          hasStrip: hasStrip,
        ),
      ),
    );
  }

  Widget _compactColumn(
    double height,
    TeachingQuestion q, {
    required bool audioOnly,
    required List<String> options,
    required Widget hints,
    required Widget feedback,
    required bool hasStrip,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_flow.phase.isRemediation)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              "Let's look at it another way.",
              key: Key('remediation_banner'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: GameTokens.ink,
              ),
            ),
          ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height * .26),
          child: FitContent(
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 2),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          q.prompt,
                          key: const Key('question_prompt'),
                          style: scriptStyle(
                            q.prompt,
                            const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: GameTokens.ink,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!audioOnly)
                      IconButton.filledTonal(
                        key: const Key('listen_button'),
                        tooltip: 'Listen',
                        onPressed: _speaking ? null : () => _speak(q.speech),
                        icon: Icon(
                          _speaking
                              ? Icons.graphic_eq_rounded
                              : Icons.volume_up_rounded,
                        ),
                      ),
                    if (_flow.hintsAllowed &&
                        q.hints.isNotEmpty &&
                        !_flow.solved)
                      IconButton.outlined(
                        key: const Key('hint_button'),
                        tooltip: _flow.hasMoreHints ? 'Hint' : 'No more hints',
                        onPressed: _flow.hasMoreHints
                            ? () => setState(_flow.showHint)
                            : null,
                        icon: const Icon(Icons.lightbulb_outline_rounded),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_voiceMissing && !audioOnly) _voiceNotice(),
        if (hasStrip)
          // Takes what its text needs and no more, but never so much that the
          // options (which get the whole rest of the pane) fall below one
          // row of tappable height. Not a Flexible: a Flexible would keep its
          // unused share as an empty gap under the options.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (height * .74 - 72).clamp(40.0, height),
            ),
            child: FitContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [hints, feedback],
              ),
            ),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final n = options.length;
              // The options are laid out to fill the pane: one tall tile per
              // row when each row can still be a finger-sized target, else two
              // columns, and only when even that is too tight do they shrink
              // together (FitContent) instead.
              final cols = n > 0 && c.maxHeight / n >= 64 ? 1 : 2;
              final rows = n == 0 ? 0 : (n / cols).ceil();
              if (rows > 0 && c.maxHeight / rows >= 52) {
                return Column(
                  key: const Key('options_area'),
                  children: [
                    for (var r = 0; r < rows; r++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var k = 0; k < cols; k++) ...[
                              if (k > 0) const SizedBox(width: 8),
                              Expanded(
                                child: r * cols + k < n
                                    ? _optionTile(
                                        q,
                                        options[r * cols + k],
                                        compact: true,
                                        minHeight: 0,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                );
              }
              final w = (c.maxWidth - 8) / 2;
              return FitContent(
                key: const Key('options_area'),
                // On the shortest screens with a hint and a wrong answer
                // showing, the options are drawn smaller rather than scrolled.
                minScale: 0.3,
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final o in options)
                      SizedBox(
                        width: w,
                        child: _optionTile(q, o, compact: true),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _scroll(double pad, Widget child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, 4, pad, 8),
            child: FitContent(child: child),
          ),
        ),
      );

  Widget _visualCard(
    TeachingVisual visual,
    String id,
    bool isQuestion, {
    bool fill = false,
  }) {
    final view = TeachingVisualView(
      key: ValueKey('visual_$id'),
      visual: visual,
      isQuestion: isQuestion,
      color: _color,
    );
    if (fill) {
      // The picture takes the whole pane and is drawn as large as it can be.
      return Card(
        color: Colors.white,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox.expand(
            child: FittedBox(fit: BoxFit.contain, child: view),
          ),
        ),
      );
    }
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 110),
          child: Center(child: view),
        ),
      ),
    );
  }

  /// For items that are heard, not seen: a large listen tile is the thing to
  /// look at (and press), and it says so plainly if the voice is missing.
  Widget _audioTile(TeachingQuestion q) => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              FilledButton.tonalIcon(
                key: const Key('replay_button'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 84),
                  textStyle: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                onPressed: _speaking ? null : () => _speak(q.speech),
                icon: Icon(
                  _speaking
                      ? Icons.graphic_eq_rounded
                      : Icons.volume_up_rounded,
                  size: 40,
                ),
                label: Text(_speaking ? 'Listening…' : 'Listen again'),
              ),
              if (_voiceMissing) _voiceNotice(),
            ],
          ),
        ),
      );

  Widget _voiceNotice() => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          'The voice is not available on this device. '
          'Ask a grown-up to read this to you.',
          key: const Key('voice_notice'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF7A3E00),
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _listenButton(String speech) => FilledButton.tonalIcon(
        key: const Key('listen_button'),
        onPressed: _speaking ? null : () => _speak(speech),
        icon: Icon(
          _speaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
        ),
        label: Text(_speaking ? 'Listening…' : 'Listen'),
      );

  // -- steps ---------------------------------------------------------------------

  Widget _stepPanel(TeachingStep step) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_flow.phase.isRemediation) _remediationBanner(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    step.text,
                    key: const Key('step_text'),
                    textAlign: TextAlign.center,
                    style: scriptStyle(
                      step.text,
                      Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.w800,
                            color: GameTokens.ink,
                            height: 1.3,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(child: _listenButton(step.speech)),
                  if (_voiceMissing) _voiceNotice(),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _remediationBanner() => Container(
        key: const Key('remediation_banner'),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0C9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "Let's look at it another way.",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, color: GameTokens.ink),
        ),
      );

  // -- questions -------------------------------------------------------------------

  Widget _questionPanel(TeachingQuestion q) {
    final audioOnly = q.visual.type == VisualType.none;
    final options = _flow.optionsFor(q);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_flow.phase.isRemediation) _remediationBanner(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    q.prompt,
                    key: const Key('question_prompt'),
                    textAlign: TextAlign.center,
                    style: scriptStyle(
                      q.prompt,
                      Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.w800,
                            color: GameTokens.ink,
                            height: 1.3,
                          ),
                    ),
                  ),
                ),
                // Audio-only items already have their big listen tile.
                if (!audioOnly) ...[
                  const SizedBox(height: 10),
                  Center(child: _listenButton(q.speech)),
                  if (_voiceMissing) _voiceNotice(),
                ],
              ],
            ),
          ),
        ),
        if (_flow.hintsAllowed) _hintArea(q),
        const SizedBox(height: 8),
        for (final option in options) _optionTile(q, option),
        _feedback(q),
      ],
    );
  }

  Widget _hintTexts({bool compact = false}) {
    final shown = _flow.shownHints;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < shown.length; i++)
          Container(
            key: Key('hint_text_$i'),
            margin: EdgeInsets.only(top: compact ? 3 : 8),
            padding: EdgeInsets.all(compact ? 6 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, color: Color(0xFF2B6CB0)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shown[i],
                    style: scriptStyle(
                      shown[i],
                      TextStyle(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: GameTokens.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _hintArea(TeachingQuestion q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hintTexts(),
        if (q.hints.isNotEmpty && !_flow.solved)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              child: OutlinedButton.icon(
                key: const Key('hint_button'),
                style: OutlinedButton.styleFrom(
                  minimumSize:
                      const Size(GameTokens.minTouch, GameTokens.minTouch),
                ),
                onPressed:
                    _flow.hasMoreHints ? () => setState(_flow.showHint) : null,
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: Text(
                  !_flow.hasMoreHints
                      ? 'No more hints'
                      : _flow.hintsShown == 0
                          ? 'Hint'
                          : 'Another hint',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _optionTile(TeachingQuestion q, String option,
      {bool compact = false, double? minHeight}) {
    final check = _flow.phase.isCheck;
    final right = !check && _flow.solved && option == q.answer;
    final wrong = !check && _flow.tried.contains(option);
    final selected = check && _flow.pending == option;
    final picture = q.optionPictures[option];
    final bg = right
        ? const Color(0xFFD9F5DF)
        : wrong
            ? const Color(0xFFFFE1DC)
            : selected
                ? _color.withValues(alpha: .18)
                : Colors.white;
    final border = right
        ? const Color(0xFF2E8B57)
        : wrong
            ? const Color(0xFFC0392B)
            : selected
                ? _color
                : const Color(0xFFCFC8E6);
    final state = right
        ? ', correct'
        : wrong
            ? ', not this one'
            : selected
                ? ', chosen'
                : '';
    final enabled = check || (!_flow.solved && !wrong);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        label: '$option$state',
        excludeSemantics: true,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: border, width: selected || right ? 3 : 2),
          ),
          child: InkWell(
            key: Key('option_$option'),
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? () => _onPick(option) : null,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: minHeight ?? (compact ? 52 : 60)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    // Whenever the plan gives a picture for an option, show it.
                    if (picture != null) ...[
                      SizedBox(
                        width: compact ? 44 : 72,
                        height: compact ? 44 : 72,
                        child: ArtPicture(
                          asset: picture,
                          conceptLabel: option,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        option,
                        textAlign: picture == null
                            ? TextAlign.center
                            : TextAlign.start,
                        style: scriptStyle(
                          option,
                          TextStyle(
                            fontSize: compact ? 21 : 24,
                            fontWeight: FontWeight.w800,
                            color: GameTokens.ink,
                          ),
                        ),
                      ),
                    ),
                    if (right)
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF2E8B57)),
                    if (wrong)
                      const Icon(Icons.cancel_rounded,
                          color: Color(0xFFC0392B)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Guided and practice only: a check shows nothing until the end.
  Widget _feedback(TeachingQuestion q, {bool compact = false}) {
    if (!_flow.phase.isFeedbackQuestion) return const SizedBox.shrink();
    if (_flow.solved) {
      return _note(
        key: 'feedback_text',
        color: const Color(0xFFD9F5DF),
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF2E8B57),
        text: 'Well done!',
        extra: q.explanation,
        compact: compact,
      );
    }
    final wrong = _flow.wrongFeedback;
    if (wrong == null) return const SizedBox.shrink();
    return _note(
      key: 'feedback_text',
      color: const Color(0xFFFFEDD5),
      icon: Icons.tips_and_updates_rounded,
      iconColor: const Color(0xFFB45309),
      text: wrong,
      compact: compact,
    );
  }

  Widget _note({
    required String key,
    required Color color,
    required IconData icon,
    required Color iconColor,
    required String text,
    String? extra,
    bool compact = false,
  }) =>
      Container(
        margin: const EdgeInsets.only(top: 4),
        padding: EdgeInsets.all(compact ? 6 : 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    key: Key(key),
                    style: scriptStyle(
                      text,
                      TextStyle(
                        fontSize: compact ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        color: GameTokens.ink,
                      ),
                    ),
                  ),
                  if (extra != null && extra.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      extra,
                      key: const Key('explanation_text'),
                      style: scriptStyle(
                        extra,
                        TextStyle(
                          fontSize: compact ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: GameTokens.ink,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  // -- results ---------------------------------------------------------------------

  Widget _resultPanel() {
    final flow = _flow;
    final passed = flow.resultPassed;
    final list = flow.questions;
    final message = passed
        ? 'Great work! You understand this.'
        : flow.remediationLeft
            ? "Let's practise it another way."
            : 'This one is tricky. We will get some help.';
    return Column(
      key: const Key('check_result'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${flow.checkScore} out of ${flow.checkTotal}',
                  key: const Key('check_score'),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: GameTokens.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  key: const Key('check_message'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: GameTokens.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (var i = 0; i < list.length; i++) _reviewRow(i, list[i]),
      ],
    );
  }

  Widget _reviewRow(int i, TeachingQuestion q) {
    final mine = i < _flow.checkAnswers.length ? _flow.checkAnswers[i] : null;
    final ok = mine == q.answer;
    final note = ok ? q.explanation : (q.wrongFeedback[mine] ?? '');
    return Container(
      key: Key('check_review_$i'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFE5F7EA) : const Color(0xFFFFEDE9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: ok ? const Color(0xFF2E8B57) : const Color(0xFFC0392B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.prompt,
                  style: scriptStyle(
                    q.prompt,
                    const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: GameTokens.ink,
                    ),
                  ),
                ),
                if (note.isNotEmpty)
                  Text(
                    note,
                    style: scriptStyle(
                      note,
                      const TextStyle(color: GameTokens.ink),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _masteredCard() => _scroll(
        12,
        Card(
          key: const Key('mastered_card'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.star_rounded,
                    size: 72, color: Color(0xFFF5B301)),
                const SizedBox(height: 8),
                const Text(
                  'You did it!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                if (_gained > 0) Text('+$_gained stars'),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('mastered_back'),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to lessons'),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _supportCard() => _scroll(
        12,
        Card(
          key: const Key('needs_support_card'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.favorite_rounded,
                    size: 56, color: Color(0xFFE57373)),
                const SizedBox(height: 8),
                const Text(
                  'This one is tricky, and that is okay.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'A grown-up can help you practise it. You can try again '
                  'any time, or carry on with the next quest.',
                  key: Key('support_message'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  key: const Key('support_back'),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to the map'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('support_retry'),
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(GameTokens.minTouch, GameTokens.minTouch),
                  ),
                  onPressed: _restart,
                  child: const Text('Try again from the start'),
                ),
              ],
            ),
          ),
        ),
      );

  // -- actions ---------------------------------------------------------------------

  Widget _actionBar() {
    final flow = _flow;
    if (flow.phase.isResult) {
      // A different button in a different state from the last answer's Next,
      // inert for a moment, so the score page cannot be tapped past.
      return Row(
        children: [
          const Spacer(),
          FilledButton(
            key: const Key('continue_button'),
            onPressed: _resultLocked ? null : () => _change(_flow.next),
            child: const Text('Continue'),
          ),
        ],
      );
    }
    final label =
        flow.phase.isCheck && flow.isLastItem ? 'See my score' : 'Next';
    return Row(
      children: [
        if (flow.canGoBack)
          OutlinedButton.icon(
            key: const Key('back_button'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(GameTokens.minTouch, GameTokens.minTouch),
            ),
            onPressed: () => _change(_flow.back),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back'),
          ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('next_button'),
              onPressed: flow.canAdvance ? () => _change(_flow.next) : null,
              child: Text(label, textAlign: TextAlign.center),
            ),
          ),
        ),
      ],
    );
  }
}

/// The phase bar: five segments, which one is current, and the item inside it.
class _PhaseIndicator extends StatelessWidget {
  const _PhaseIndicator({
    required this.flow,
    required this.color,
    this.compact = false,
  });
  final TeachingFlow flow;
  final Color color;
  final bool compact;

  static const _names = [
    'Learn',
    'Watch',
    'Try with help',
    'Practise',
    'Check'
  ];

  @override
  Widget build(BuildContext context) {
    final phase = flow.phase;
    final remediation = phase.isRemediation;
    final current = remediation ? 5 : phase.mainNumber;
    final label = remediation
        ? 'Extra help'
        : current >= 1
            ? '$current of 5: ${_names[current - 1]}'
            : '';
    final items = flow.itemCount;
    final inside = phase.isTerminal || phase.isResult || items == 0
        ? ''
        : ' • ${flow.index + 1} / $items';
    return Semantics(
      container: true,
      label: 'Lesson stage. $label$inside',
      child: compact
          ? Row(
              key: const Key('phase_indicator'),
              children: [
                SizedBox(
                  width: 150,
                  child: Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Expanded(
                          child: Container(
                            key: Key('phase_segment_$i'),
                            height: 8,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: i <= current
                                  ? (remediation
                                      ? const Color(0xFFE59E00)
                                      : color)
                                  : color.withValues(alpha: .2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$label$inside',
                    key: const Key('phase_label'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: GameTokens.ink,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              key: const Key('phase_indicator'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Expanded(
                        child: Container(
                          key: Key('phase_segment_$i'),
                          height: 8,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: i <= current
                                ? (remediation
                                    ? const Color(0xFFE59E00)
                                    : color)
                                : color.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$label$inside',
                  key: const Key('phase_label'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: GameTokens.ink,
                  ),
                ),
              ],
            ),
    );
  }
}
