import 'dart:async';

import 'package:flutter/material.dart';

import '../../exam/exam_controller.dart';
import '../../exam/models.dart';
import '../../services/speech_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/fit_content.dart';
import 'exam_scope.dart';
import 'exam_widgets.dart';

String _localeForWorld(String world) => switch (world) {
      'telugu' => 'te-IN',
      'hindi' => 'hi-IN',
      'tamil' => 'ta-IN',
      _ => 'en-US',
    };

enum _Phase { question, review, done }

/// The child's exam. Opened only after the parent presses Start (or Resume).
/// One question per screen; no right or wrong is shown, no hints; every
/// answer is saved at once. Leaving always asks first and keeps the attempt
/// resumable.
class ChildExamScreen extends StatefulWidget {
  const ChildExamScreen({
    required this.attemptId,
    super.key,
    this.speech = const SpeechService(),
    this.now,
  });

  final String attemptId;
  final SpeechService speech;

  /// The clock used for the timer (tests move it). Defaults to `DateTime.now`.
  final DateTime Function()? now;

  @override
  State<ChildExamScreen> createState() => _ChildExamScreenState();
}

class _ChildExamScreenState extends State<ChildExamScreen> {
  _Phase _phase = _Phase.question;
  int _index = 0;
  bool _submitting = false;
  bool _timeUp = false;
  Timer? _timer;
  ExamResult? _result;
  late final ExamController _exams;
  bool _ready = false;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _exams = ExamScope.of(context);
    final attempt = _exams.attemptById(widget.attemptId);
    if (attempt != null) {
      final first = attempt.questions.indexWhere(
        (q) => !q.isParentMarked && !attempt.answers.containsKey(q.id),
      );
      _index = first < 0 ? 0 : first;
      if (attempt.config.timeLimitSeconds != null) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
        WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.speech.stop();
    super.dispose();
  }

  int? _remaining(ExamAttempt a) {
    final limit = a.config.timeLimitSeconds;
    if (limit == null) return null;
    return limit - _now().difference(a.startedAt).inSeconds;
  }

  void _tick() {
    if (!mounted) return;
    final a = _exams.attemptById(widget.attemptId);
    if (a == null || !a.isInProgress || _phase == _Phase.done) {
      _timer?.cancel();
      return;
    }
    final left = _remaining(a);
    if (left != null && left <= 0) {
      _timer?.cancel();
      _timeUp = true;
      _submit();
    } else {
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final result = await _exams.submit(widget.attemptId);
    if (!mounted) return;
    _timer?.cancel();
    await widget.speech.stop();
    setState(() {
      _result = result;
      _phase = _Phase.done;
      _submitting = false;
    });
  }

  void _handBack() => Navigator.of(context).popUntil((route) => route.isFirst);

  Future<void> _confirmLeave() async {
    if (_phase == _Phase.done) {
      _handBack();
      return;
    }
    final leave = await confirmDialog(
      context,
      title: 'Leave the exam?',
      message: 'Your answers are saved. A grown-up can continue this exam '
          'later from the Examination Centre.',
      confirmLabel: 'Leave',
      cancelLabel: 'Keep going',
      confirmKey: const Key('confirm_leave'),
      cancelKey: const Key('keep_going'),
    );
    if (leave && mounted) _handBack();
  }

  Future<void> _choose(ExamAttempt a, ExamQuestion q, String option) async {
    final saved = await _exams.answer(a.id, q.id, option);
    if (!saved && mounted) {
      final fresh = _exams.attemptById(a.id);
      if (fresh != null && _exams.isExpired(fresh)) {
        _timeUp = true;
        _submit();
      }
    }
  }

  Future<void> _askSubmit(ExamAttempt a) async {
    final markable = a.questions.where((q) => !q.isParentMarked).toList();
    final blank = markable.where((q) => !a.answers.containsKey(q.id)).length;
    final ok = await confirmDialog(
      context,
      title: 'Hand in your exam?',
      message: blank == 0
          ? 'You answered every question. After you hand in, you cannot change your answers.'
          : '$blank question${blank == 1 ? ' is' : 's are'} not answered. '
              'After you hand in, you cannot change your answers.',
      confirmLabel: 'Hand in',
      cancelLabel: 'Keep checking',
      confirmKey: const Key('confirm_submit'),
      cancelKey: const Key('keep_checking'),
    );
    if (ok && mounted) await _submit();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _exams,
      builder: (context, _) {
        final attempt = _exams.attemptById(widget.attemptId);
        if (attempt == null) {
          return GradientScaffold(
            appBar: AppBar(title: const Text('Exam')),
            child: const Center(child: Text('This exam could not be found.')),
          );
        }
        final body = switch (_phase) {
          _Phase.question => _questionPage(attempt),
          _Phase.review => _reviewPage(attempt),
          _Phase.done => _donePage(),
        };
        final left = _phase == _Phase.done ? null : _remaining(attempt);
        final title = switch (_phase) {
          _Phase.question =>
            'Question ${_index + 1} of ${attempt.questions.length}',
          _Phase.review => 'Check your answers',
          _Phase.done => 'All done',
        };
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmLeave();
          },
          child: GradientScaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              leading: IconButton(
                key: const Key('exam_back'),
                tooltip: 'Leave the exam',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _confirmLeave,
              ),
              title: Text(title, key: const Key('exam_title')),
              actions: [
                if (left != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Semantics(
                        label: 'Time left ${formatClock(left)}',
                        child: ExcludeSemantics(
                          child: Text(
                            formatClock(left),
                            key: const Key('exam_timer'),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            child: PageBody(child: body),
          ),
        );
      },
    );
  }

  // -- Question ---------------------------------------------------------------

  Widget _questionPage(ExamAttempt a) {
    final q = a.questions[_index];
    final selected = a.answers[q.id]?.answer;
    final last = _index == a.questions.length - 1;
    final promptCard = _promptCard(q);
    final optionTiles = <Widget>[
      if (q.isParentMarked)
        const Notice(
          'Do this one on paper or out loud with a grown-up. '
          'The grown-up will check it.',
          icon: Icons.edit_note_rounded,
        )
      else
        for (var i = 0; i < q.options.length; i++)
          _OptionTile(
            key: Key('option_$i'),
            question: q,
            option: q.options[i],
            selected: selected == q.options[i],
            onTap: () => _choose(a, q, q.options[i]),
          ),
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: LinearProgressIndicator(
            value: (_index + 1) / a.questions.length,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              // Short landscape screens: question on the left, answers on the
              // right. Each side is scaled to its room, so the whole question
              // and every answer stay on screen and nothing scrolls.
              if (box.maxHeight < 420 && box.maxWidth >= 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        key: const Key('question_list'),
                        padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                        child: FitContent(child: promptCard),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        key: const Key('answer_list'),
                        padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
                        child: FitContent(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: optionTiles,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Padding(
                key: const Key('question_list'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FitContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      promptCard,
                      const SizedBox(height: 12),
                      ...optionTiles,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('prev_question'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, GameTokens.minTouch)),
                onPressed: _index == 0
                    ? null
                    : () => setState(() {
                          _index -= 1;
                          widget.speech.stop();
                        }),
                child: const Text('Back'),
              ),
              FilledButton(
                key: Key(last ? 'go_review' : 'next_question'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(48, GameTokens.minTouch)),
                onPressed: () => setState(() {
                  widget.speech.stop();
                  if (last) {
                    _phase = _Phase.review;
                  } else {
                    _index += 1;
                  }
                }),
                child: Text(last ? 'Check answers' : 'Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _promptCard(ExamQuestion q) {
    final promptStyle = scriptStyle(
      q.prompt,
      Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (q.passage != null && q.passage!.isNotEmpty) ...[
              Text(
                q.passage!,
                key: const Key('passage'),
                style: scriptStyle(
                    q.passage!, const TextStyle(fontSize: 18, height: 1.4)),
              ),
              const SizedBox(height: 12),
            ],
            if (q.promptPicture != null)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: Image.asset(
                    q.promptPicture!,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            if (q.glyph != null && q.glyph!.isNotEmpty)
              Center(
                child: Text(
                  q.glyph!,
                  key: const Key('glyph'),
                  style: scriptStyle(
                      q.glyph!,
                      const TextStyle(
                          fontSize: 72, fontWeight: FontWeight.w900)),
                ),
              ),
            if (q.quantity != null)
              Semantics(
                label: '${q.quantity} stars',
                child: ExcludeSemantics(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < q.quantity!; i++)
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFF6A623), size: 36),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(q.prompt, key: const Key('prompt'), style: promptStyle),
            if (q.speech != null && q.speech!.isNotEmpty) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('listen'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, GameTokens.minTouch)),
                onPressed: () =>
                    widget.speech.speak(q.speech!, _localeForWorld(q.world)),
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Listen'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -- Review ----------------------------------------------------------------

  Widget _reviewPage(ExamAttempt a) {
    final blank = a.questions
        .where((q) => !q.isParentMarked && !a.answers.containsKey(q.id))
        .length;
    return Column(
      children: [
        Expanded(
          child: ListView(
            key: const Key('review_list'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Text(
                blank == 0
                    ? 'You answered every question.'
                    : '$blank question${blank == 1 ? '' : 's'} not answered yet.',
                key: const Key('review_summary'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < a.questions.length; i++) _reviewRow(a, i),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('review_back'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, GameTokens.minTouch)),
                onPressed: () => setState(() => _phase = _Phase.question),
                child: const Text('Back to questions'),
              ),
              FilledButton(
                key: const Key('submit_exam'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(48, GameTokens.minTouch)),
                onPressed: _submitting ? null : () => _askSubmit(a),
                child: const Text('Hand in'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(ExamAttempt a, int i) {
    final q = a.questions[i];
    final answered = a.answers.containsKey(q.id);
    final status = q.isParentMarked
        ? 'For a grown-up to check'
        : answered
            ? 'Answered'
            : 'Not answered';
    return Card(
      child: InkWell(
        key: Key('review_$i'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          _index = i;
          _phase = _Phase.question;
        }),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Semantics(
              label: 'Question ${i + 1}, $status',
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Text('${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        q.prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: scriptStyle(q.prompt, const TextStyle()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      answered || q.isParentMarked
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: answered ? const Color(0xFF2E7D32) : null,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        status,
                        key: Key('review_status_$i'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -- Done ------------------------------------------------------------------

  Widget _donePage() {
    final r = _result;
    // Pass or try again only: no marks, no questions, no answers.
    final passed = r != null && r.passed && !r.isProvisional;
    final String headline;
    final String body;
    if (r != null && r.isProvisional) {
      headline = 'You finished!';
      body = 'A grown-up will look at your work.';
    } else if (passed) {
      headline = 'Well done!';
      body = 'You finished your exam and passed. Great work!';
    } else {
      headline = 'Good try!';
      body =
          'You finished your exam. Every try helps you learn. Let us practise and try again soon.';
    }
    return Padding(
      key: const Key('done_list'),
      padding: const EdgeInsets.all(24),
      child: FitContent(
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Icon(
              passed ? Icons.emoji_events_rounded : Icons.favorite_rounded,
              size: 88,
              color: const Color(0xFFF6A623),
            ),
            const SizedBox(height: 16),
            Text(headline,
                key: const Key('done_headline'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(body,
                key: const Key('done_body'), textAlign: TextAlign.center),
            if (_timeUp)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                    'Time was up, so your answers so far were handed in.',
                    key: Key('time_up_note'),
                    textAlign: TextAlign.center),
              ),
            const SizedBox(height: 16),
            const Text('Please give the device back to a grown-up.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('hand_back'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(GameTokens.minTouch)),
              onPressed: _handBack,
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.question,
    required this.option,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final ExamQuestion question;
  final String option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final picture = question.optionPictures[option];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Semantics(
        button: true,
        selected: selected,
        label: option,
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: selected ? scheme.primaryContainer : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? scheme.primary : const Color(0xFFCFC8EA),
              width: selected ? 3 : 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    if (picture != null) ...[
                      Image.asset(
                        picture,
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(width: 56, height: 56),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        option,
                        style: scriptStyle(
                          option,
                          const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(Icons.radio_button_checked_rounded,
                          color: scheme.primary)
                    else
                      const Icon(Icons.radio_button_unchecked_rounded),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
