/// The rules of a taught lesson, with no widgets: which phase comes next, what
/// a hint reveals, when a check passes, when remediation is offered and when
/// the lesson settles as "needs support". [TeachingLessonScreen] only draws it.
library;

import 'dart:math';

import 'teaching_plan.dart';
import 'teaching_progress.dart';

enum TeachingPhase {
  introduce,
  demonstrate,
  guided,
  practice,
  check,
  checkResult,
  remediationExplain,
  remediationGuided,
  remediationCheck,
  remediationResult,
  mastered,
  needsSupport,
}

extension TeachingPhaseX on TeachingPhase {
  bool get isStep =>
      this == TeachingPhase.introduce ||
      this == TeachingPhase.demonstrate ||
      this == TeachingPhase.remediationExplain;

  /// Guided or practice style: answered at once, with feedback.
  bool get isFeedbackQuestion =>
      this == TeachingPhase.guided ||
      this == TeachingPhase.practice ||
      this == TeachingPhase.remediationGuided;

  /// A scored check: no hints, no feedback until the end.
  bool get isCheck =>
      this == TeachingPhase.check || this == TeachingPhase.remediationCheck;

  bool get isQuestion => isFeedbackQuestion || isCheck;

  bool get isResult =>
      this == TeachingPhase.checkResult ||
      this == TeachingPhase.remediationResult;

  bool get isTerminal =>
      this == TeachingPhase.mastered || this == TeachingPhase.needsSupport;

  bool get isRemediation =>
      this == TeachingPhase.remediationExplain ||
      this == TeachingPhase.remediationGuided ||
      this == TeachingPhase.remediationCheck ||
      this == TeachingPhase.remediationResult;

  /// 1..5 for the five main phases, 0 otherwise.
  int get mainNumber => switch (this) {
        TeachingPhase.introduce => 1,
        TeachingPhase.demonstrate => 2,
        TeachingPhase.guided => 3,
        TeachingPhase.practice => 4,
        TeachingPhase.check || TeachingPhase.checkResult => 5,
        _ => 0,
      };
}

class PickResult {
  const PickResult(
      {required this.correct, this.feedback, this.ignored = false});

  /// Right answer (guided/practice). Always false for a check pick.
  final bool correct;

  /// The plan's wrong_feedback for this option, when it was wrong.
  final String? feedback;

  /// The tap changed nothing (already solved, or an option already tried).
  final bool ignored;
}

class TeachingFlow {
  TeachingFlow({
    required this.plan,
    TeachingProgress initial = TeachingProgress.empty,
    this.seed = 0,
    bool resume = true,
  })  : _initial = initial,
        _done = {...initial.phasesDone},
        _guidedDone = initial.guidedDone,
        _practiceDone = initial.practiceDone,
        _best = initial.checkBestScore,
        _last = initial.checkLastScore {
    final saved = initial.phase;
    if (resume && saved != null && !initial.isMastered) {
      switch (saved) {
        case 'remediation':
          remediationCycle = max(1, initial.remediationCycles);
          _enter(TeachingPhase.remediationExplain);
        case 'demonstrate':
          _enter(TeachingPhase.demonstrate);
        case 'guided':
          _enter(TeachingPhase.guided);
        case 'practice':
          _enter(TeachingPhase.practice);
        case 'check':
          _enter(TeachingPhase.check);
        default:
          _enter(TeachingPhase.introduce);
      }
    } else {
      _enter(TeachingPhase.introduce);
    }
  }

  final TeachingPlan plan;
  final int seed;
  final TeachingProgress _initial;

  TeachingPhase phase = TeachingPhase.introduce;
  int index = 0;

  /// Remediation cycles started so far in this run (0 = none).
  int remediationCycle = 0;

  // per-question state
  final Set<String> tried = {};
  String? lastWrong;
  int hintsShown = 0;
  bool solved = false;

  /// The option chosen on a check question, not yet confirmed.
  String? pending;
  List<String?> checkAnswers = [];

  final Set<String> _done;
  bool _guidedDone;
  bool _practiceDone;
  int? _best;
  int? _last;
  final Map<String, List<String>> _orders = {};
  int _prevAnswerIndex = -1;

  // -- what is on screen -------------------------------------------------------

  List<TeachingStep> get steps => switch (phase) {
        TeachingPhase.introduce => plan.introduce,
        TeachingPhase.demonstrate => plan.demonstrate,
        TeachingPhase.remediationExplain => plan.remediation.explain,
        _ => const [],
      };

  List<TeachingQuestion> get questions => switch (phase) {
        TeachingPhase.guided => plan.guided,
        TeachingPhase.practice => _easyToHard(plan.practice),
        TeachingPhase.check || TeachingPhase.checkResult => plan.check,
        TeachingPhase.remediationGuided => plan.remediation.guided,
        TeachingPhase.remediationCheck ||
        TeachingPhase.remediationResult =>
          _rotated(plan.remediation.check),
        _ => const [],
      };

  List<TeachingQuestion> _easyToHard(List<TeachingQuestion> list) {
    final indexed = list.asMap().entries.toList()
      ..sort((a, b) {
        final byDifficulty = a.value.difficulty.compareTo(b.value.difficulty);
        return byDifficulty != 0 ? byDifficulty : a.key.compareTo(b.key);
      });
    return [for (final e in indexed) e.value];
  }

  /// A later remediation cycle shows the same alternate check in another
  /// order, so it is not a replay of the last one.
  List<TeachingQuestion> _rotated(List<TeachingQuestion> list) {
    if (list.length < 2 || remediationCycle <= 1) return list;
    final by = (remediationCycle - 1) % list.length;
    return [...list.skip(by), ...list.take(by)];
  }

  TeachingStep? get step =>
      phase.isStep && index < steps.length ? steps[index] : null;

  TeachingQuestion? get question {
    if (!phase.isQuestion) return null;
    final list = questions;
    return index < list.length ? list[index] : null;
  }

  int get itemCount => phase.isStep ? steps.length : questions.length;

  bool get isLastItem => index >= itemCount - 1;

  // -- options, hints ----------------------------------------------------------

  /// Options in a seeded shuffle. The right answer is never left in the slot
  /// the file lists it in, and never in the same slot as the question before.
  List<String> optionsFor(TeachingQuestion q) {
    final key = '${q.id}#$remediationCycle';
    final cached = _orders[key];
    if (cached != null) {
      return cached;
    }
    final stored = q.options;
    var order = [...stored];
    if (order.length > 1) {
      final random = Random(_fnv('$seed|${plan.lessonId}|$key'));
      for (var attempt = 0; attempt < 24; attempt++) {
        order = [...stored]..shuffle(random);
        final at = order.indexOf(q.answer);
        final sameAsStored = at == stored.indexOf(q.answer);
        final sameAsBefore = at == _prevAnswerIndex && order.length > 2;
        if (!sameAsStored && !sameAsBefore) break;
      }
    }
    _prevAnswerIndex = order.indexOf(q.answer);
    return _orders[key] = order;
  }

  static int _fnv(String text) {
    var h = 0x811C9DC5;
    for (final unit in text.codeUnits) {
      h = ((h ^ unit) * 0x01000193) & 0x7FFFFFFF;
    }
    return h;
  }

  bool get hintsAllowed =>
      phase == TeachingPhase.guided || phase == TeachingPhase.remediationGuided;

  /// Hints shown so far for the current question (the ladder, in order).
  List<String> get shownHints {
    final q = question;
    if (q == null || !hintsAllowed) return const [];
    return q.hints.take(hintsShown).toList();
  }

  bool get hasMoreHints {
    final q = question;
    return q != null && hintsAllowed && !solved && hintsShown < q.hints.length;
  }

  /// Reveals the next hint; hint 1 is a nudge, later ones may reveal.
  String? showHint() {
    if (!hasMoreHints) return null;
    hintsShown++;
    return question!.hints[hintsShown - 1];
  }

  // -- answering ---------------------------------------------------------------

  PickResult pick(String option) {
    final q = question;
    if (q == null || !q.options.contains(option)) {
      return const PickResult(correct: false, ignored: true);
    }
    if (phase.isCheck) {
      pending = option;
      return const PickResult(correct: false);
    }
    if (solved || tried.contains(option)) {
      return const PickResult(correct: false, ignored: true);
    }
    if (option == q.answer) {
      solved = true;
      return const PickResult(correct: true);
    }
    // A wrong try costs nothing: no score, no lock.
    tried.add(option);
    lastWrong = option;
    return PickResult(
      correct: false,
      feedback: q.wrongFeedback[option] ?? 'Not quite. Try again.',
    );
  }

  String? get wrongFeedback {
    final q = question;
    if (q == null || lastWrong == null || solved) return null;
    return q.wrongFeedback[lastWrong] ?? 'Not quite. Try again.';
  }

  bool get canAdvance {
    if (phase.isStep || phase.isResult) return true;
    if (phase.isFeedbackQuestion) return solved;
    if (phase.isCheck) return pending != null;
    return false;
  }

  bool get canGoBack => switch (phase) {
        TeachingPhase.introduce ||
        TeachingPhase.remediationExplain =>
          index > 0,
        TeachingPhase.demonstrate => true,
        _ => false,
      };

  void back() {
    if (!canGoBack) return;
    if (phase == TeachingPhase.demonstrate && index == 0) {
      phase = TeachingPhase.introduce;
      index = plan.introduce.length - 1;
      _resetQuestion();
      return;
    }
    index--;
  }

  /// Moves on: next step, next question, next phase or the result.
  void next() {
    if (!canAdvance || phase.isTerminal) return;
    if (phase.isResult) {
      _afterResult();
      return;
    }
    if (phase.isCheck) {
      checkAnswers[index] = pending;
    }
    if (!isLastItem) {
      index++;
      _resetQuestion();
      return;
    }
    switch (phase) {
      case TeachingPhase.introduce:
        _complete(TeachingPhaseName.introduce);
        _enter(TeachingPhase.demonstrate);
      case TeachingPhase.demonstrate:
        _complete(TeachingPhaseName.demonstrate);
        _enter(TeachingPhase.guided);
      case TeachingPhase.guided:
        _guidedDone = true;
        _complete(TeachingPhaseName.guided);
        _enter(TeachingPhase.practice);
      case TeachingPhase.practice:
        _practiceDone = true;
        _complete(TeachingPhaseName.practice);
        _enter(TeachingPhase.check);
      case TeachingPhase.check:
        _complete(TeachingPhaseName.check);
        final score = checkScore;
        _last = score;
        _best = max(_best ?? 0, score);
        _enter(TeachingPhase.checkResult);
      case TeachingPhase.remediationExplain:
        _enter(TeachingPhase.remediationGuided);
      case TeachingPhase.remediationGuided:
        _enter(TeachingPhase.remediationCheck);
      case TeachingPhase.remediationCheck:
        _enter(TeachingPhase.remediationResult);
      default:
        break;
    }
  }

  void _afterResult() {
    if (resultPassed) {
      phase = TeachingPhase.mastered;
      _resetQuestion();
      return;
    }
    if (remediationCycle < plan.mastery.maxRemediationCycles) {
      remediationCycle++;
      _enter(TeachingPhase.remediationExplain);
    } else {
      phase = TeachingPhase.needsSupport;
      _resetQuestion();
    }
  }

  /// Starts the whole lesson again from the introduction. Nothing saved is
  /// erased; this only resets the run.
  void restart() {
    remediationCycle = 0;
    _orders.clear();
    _prevAnswerIndex = -1;
    _enter(TeachingPhase.introduce);
  }

  // -- results -----------------------------------------------------------------

  /// Right answers in the check being played (or just finished).
  int get checkScore {
    final list = questions;
    var score = 0;
    for (var i = 0; i < list.length && i < checkAnswers.length; i++) {
      if (checkAnswers[i] == list[i].answer) score++;
    }
    return score;
  }

  int get checkTotal => questions.length;

  int get passMark => phase == TeachingPhase.remediationResult
      ? plan.mastery.remediationPass
      : plan.mastery.checkPass;

  bool get resultPassed => checkScore >= passMark;

  /// Whether another remediation cycle is still allowed after a fail.
  bool get remediationLeft =>
      remediationCycle < plan.mastery.maxRemediationCycles;

  // -- bookkeeping -------------------------------------------------------------

  void _resetQuestion() {
    tried.clear();
    lastWrong = null;
    hintsShown = 0;
    solved = false;
    pending = null;
  }

  void _enter(TeachingPhase next) {
    phase = next;
    index = 0;
    _resetQuestion();
    if (next.isCheck) {
      checkAnswers = List<String?>.filled(questions.length, null);
    }
  }

  void _complete(TeachingPhaseName name) => _done.add(name.name);

  String? get _phaseKey => switch (phase) {
        TeachingPhase.introduce => 'introduce',
        TeachingPhase.demonstrate => 'demonstrate',
        TeachingPhase.guided => 'guided',
        TeachingPhase.practice => 'practice',
        TeachingPhase.check || TeachingPhase.checkResult => 'check',
        TeachingPhase.remediationExplain ||
        TeachingPhase.remediationGuided ||
        TeachingPhase.remediationCheck ||
        TeachingPhase.remediationResult =>
          'remediation',
        _ => null,
      };

  /// What to save now. A lesson that was already mastered stays mastered while
  /// it is replayed.
  TeachingProgress get progress {
    final status = _initial.isMastered || phase == TeachingPhase.mastered
        ? MasteryStatus.mastered
        : phase == TeachingPhase.needsSupport
            ? MasteryStatus.needsSupport
            : _initial.mastery == MasteryStatus.needsSupport
                ? MasteryStatus.needsSupport
                : MasteryStatus.learning;
    final key = _phaseKey;
    return TeachingProgress(
      viewed: true,
      phasesDone: {..._done},
      guidedDone: _guidedDone,
      practiceDone: _practiceDone,
      checkBestScore: _best,
      checkLastScore: _last,
      mastery: status,
      remediationCycles: remediationCycle,
      updatedAt: _initial.updatedAt,
      phase: key,
    );
  }
}
