import 'package:aksharamala/src/teaching/teaching_flow.dart';
import 'package:aksharamala/src/teaching/teaching_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final lib = pilotLibrary();
  TeachingFlow flowFor(
    String id, {
    TeachingProgress initial = TeachingProgress.empty,
    int seed = 3,
  }) =>
      TeachingFlow(plan: lib.planFor(id)!, initial: initial, seed: seed);

  test('phases come in order and no independent question precedes teaching',
      () {
    for (final id in lib.plansById.keys) {
      final f = flowFor(id);
      final seen = <TeachingPhase>[];
      var guard = 0;
      while (!f.phase.isTerminal && guard++ < 200) {
        if (seen.isEmpty || seen.last != f.phase) seen.add(f.phase);
        if (f.phase == TeachingPhase.practice) {
          expect(
            f.progress.phasesDone,
            containsAll(['introduce', 'demonstrate', 'guided']),
            reason: '$id practice began before teaching finished',
          );
        }
        if (f.phase.isCheck) {
          expect(f.progress.phasesDone, contains('practice'));
        }
        finishPhase(f);
      }
      expect(seen, [
        TeachingPhase.introduce,
        TeachingPhase.demonstrate,
        TeachingPhase.guided,
        TeachingPhase.practice,
        TeachingPhase.check,
        TeachingPhase.checkResult,
      ]);
      expect(f.phase, TeachingPhase.mastered);
    }
  });

  test('the first screen is a teaching step, never a question', () {
    final f = flowFor('en-a');
    expect(f.phase, TeachingPhase.introduce);
    expect(f.step, isNotNull);
    expect(f.question, isNull);
  });

  test('guided: hint ladder reveals in order, wrong tries cost nothing', () {
    final f = flowFor('en-a');
    while (f.phase != TeachingPhase.guided) {
      finishPhase(f);
    }
    final q = f.question!;
    expect(f.hintsAllowed, isTrue);
    expect(f.shownHints, isEmpty);
    expect(f.showHint(), q.hints[0]);
    expect(f.shownHints, [q.hints[0]]);
    expect(f.showHint(), q.hints[1]);
    expect(f.hasMoreHints, isFalse);
    expect(f.showHint(), isNull);
    for (final o in q.options.where((o) => o != q.answer)) {
      final r = f.pick(o);
      expect(r.correct, isFalse);
      expect(r.feedback, q.wrongFeedback[o]);
      expect(f.canAdvance, isFalse);
    }
    expect(f.pick(q.answer).correct, isTrue);
    expect(f.canAdvance, isTrue);
    expect(f.progress.checkBestScore, isNull, reason: 'no score in guided');
  });

  test('practice has no hints; a wrong tap shows only the plan feedback', () {
    final f = flowFor('num-add');
    while (f.phase != TeachingPhase.practice) {
      finishPhase(f);
    }
    expect(f.hintsAllowed, isFalse);
    final q = f.question!;
    final wrong = wrongOf(q);
    final r = f.pick(wrong);
    expect(r.feedback, q.wrongFeedback[wrong]);
    expect(f.solved, isFalse);
    expect(f.canAdvance, isFalse);
  });

  test('practice goes easy to hard', () {
    for (final id in lib.plansById.keys) {
      final f = flowFor(id);
      while (f.phase != TeachingPhase.practice) {
        finishPhase(f);
      }
      final d = [for (final q in f.questions) q.difficulty];
      expect(d, [...d]..sort(), reason: id);
    }
  });

  test('check: no hints, no feedback; a pick is pending until Next', () {
    final f = flowFor('te-a');
    while (f.phase != TeachingPhase.check) {
      finishPhase(f);
    }
    final q = f.question!;
    expect(f.hintsAllowed, isFalse);
    expect(f.showHint(), isNull);
    final r = f.pick(wrongOf(q));
    expect(r.feedback, isNull);
    expect(f.wrongFeedback, isNull);
    expect(f.tried, isEmpty);
    expect(f.canAdvance, isTrue);
    f.pick(q.answer);
    f.next();
    expect(f.checkAnswers.first, q.answer);
  });

  test('check pass goes straight to mastered', () {
    final f = flowFor('hi-a');
    toCheckResult(f, correct: true);
    expect(f.checkScore, 3);
    expect(f.resultPassed, isTrue);
    f.next();
    expect(f.phase, TeachingPhase.mastered);
    expect(f.progress.mastery, MasteryStatus.mastered);
    expect(f.progress.checkBestScore, 3);
  });

  test('exactly the pass mark passes', () {
    final f = flowFor('en-a');
    while (f.phase != TeachingPhase.check) {
      finishPhase(f);
    }
    final qs = f.questions;
    f.pick(qs[0].answer);
    f.next();
    f.pick(qs[1].answer);
    f.next();
    f.pick(wrongOf(qs[2]));
    f.next();
    expect(f.checkScore, 2);
    expect(f.resultPassed, isTrue);
  });

  test('one below the pass mark fails', () {
    final f = flowFor('en-a');
    while (f.phase != TeachingPhase.check) {
      finishPhase(f);
    }
    final qs = f.questions;
    f.pick(qs[0].answer);
    f.next();
    f.pick(wrongOf(qs[1]));
    f.next();
    f.pick(wrongOf(qs[2]));
    f.next();
    expect(f.checkScore, 1);
    expect(f.resultPassed, isFalse);
  });

  test('fail -> remediation (explain, guided, alternate check) -> pass', () {
    final f = flowFor('ta-a');
    toCheckResult(f, correct: false);
    expect(f.resultPassed, isFalse);
    expect(f.remediationLeft, isTrue);
    f.next();
    expect(f.phase, TeachingPhase.remediationExplain);
    expect(f.remediationCycle, 1);
    expect(f.steps, f.plan.remediation.explain);
    finishPhase(f);
    expect(f.phase, TeachingPhase.remediationGuided);
    expect(f.questions, f.plan.remediation.guided);
    expect(f.hintsAllowed, isTrue);
    finishPhase(f);
    expect(f.phase, TeachingPhase.remediationCheck);
    expect(
      f.questions.map((q) => q.id).toSet(),
      f.plan.remediation.check.map((q) => q.id).toSet(),
    );
    expect(
      f.questions.map((q) => q.id).toSet().intersection(
            f.plan.check.map((q) => q.id).toSet(),
          ),
      isEmpty,
      reason: 'the remediation check is a different check',
    );
    expect(f.hintsAllowed, isFalse);
    finishPhase(f, correct: true);
    expect(f.phase, TeachingPhase.remediationResult);
    expect(f.resultPassed, isTrue);
    f.next();
    expect(f.phase, TeachingPhase.mastered);
    expect(f.progress.remediationCycles, 1);
  });

  test('limit reached -> needsSupport, never mastered, never loops', () {
    final f = flowFor('num-add');
    toCheckResult(f, correct: false);
    f.next();
    var cycles = 0;
    while (f.phase == TeachingPhase.remediationExplain) {
      cycles++;
      finishPhase(f);
      finishPhase(f);
      finishPhase(f, correct: false);
      expect(f.phase, TeachingPhase.remediationResult);
      f.next();
      expect(cycles, lessThanOrEqualTo(2));
    }
    expect(cycles, 2);
    expect(f.phase, TeachingPhase.needsSupport);
    expect(f.progress.mastery, MasteryStatus.needsSupport);
    expect(f.progress.phase, isNull);
    // Restarting is allowed and begins a fresh run.
    f.restart();
    expect(f.phase, TeachingPhase.introduce);
    expect(f.remediationCycle, 0);
  });

  test('a second remediation cycle shows its check in another order', () {
    final f = flowFor('en-a');
    toCheckResult(f, correct: false);
    f.next();
    finishPhase(f);
    finishPhase(f);
    final first = [for (final q in f.questions) q.id];
    finishPhase(f, correct: false);
    f.next();
    expect(f.remediationCycle, 2);
    finishPhase(f);
    finishPhase(f);
    final second = [for (final q in f.questions) q.id];
    expect(second.toSet(), first.toSet());
    expect(second, isNot(first));
  });

  test(
      'options are shuffled: the answer is never in its stored slot, and '
      'not always in one slot', () {
    for (final id in lib.plansById.keys) {
      final plan = lib.planFor(id)!;
      final slots = <int>{};
      for (final seed in [1, 2, 3]) {
        final f = TeachingFlow(plan: plan, seed: seed);
        for (final q in plan.allQuestions) {
          final shown = f.optionsFor(q);
          expect(shown.toSet(), q.options.toSet());
          if (q.options.length > 1) {
            expect(
              shown.indexOf(q.answer),
              isNot(q.options.indexOf(q.answer)),
              reason: '${q.id} seed $seed',
            );
          }
          slots.add(shown.indexOf(q.answer));
        }
      }
      expect(slots.length, greaterThan(1), reason: id);
    }
  });

  test('same seed gives the same order, and it is stable while on screen', () {
    final plan = lib.planFor('en-a')!;
    final a = TeachingFlow(plan: plan, seed: 9);
    final b = TeachingFlow(plan: plan, seed: 9);
    final q = plan.guided.first;
    expect(a.optionsFor(q), b.optionsFor(q));
    expect(a.optionsFor(q), a.optionsFor(q));
  });

  test('resume starts at the beginning of the saved phase', () {
    final f = flowFor('en-a');
    while (f.phase != TeachingPhase.practice) {
      finishPhase(f);
    }
    f.pick(f.question!.answer);
    f.next();
    expect(f.index, 1);
    final saved = f.progress;
    expect(saved.phase, 'practice');
    final again = flowFor('en-a', initial: saved);
    expect(again.phase, TeachingPhase.practice);
    expect(again.index, 0);
    expect(again.progress.phasesDone, containsAll(['introduce', 'guided']));
  });

  test('resume inside remediation keeps the cycle', () {
    final f = flowFor('en-a');
    toCheckResult(f, correct: false);
    f.next();
    final saved = f.progress;
    expect(saved.phase, 'remediation');
    expect(saved.remediationCycles, 1);
    final again = flowFor('en-a', initial: saved);
    expect(again.phase, TeachingPhase.remediationExplain);
    expect(again.remediationCycle, 1);
  });

  test('a mastered lesson replays from the start and stays mastered', () {
    final f = flowFor(
      'en-a',
      initial: const TeachingProgress(
        mastery: MasteryStatus.mastered,
        checkBestScore: 3,
        phase: 'check',
      ),
    );
    expect(f.phase, TeachingPhase.introduce);
    expect(f.progress.mastery, MasteryStatus.mastered);
    toCheckResult(f, correct: false);
    expect(f.progress.mastery, MasteryStatus.mastered);
    expect(f.progress.checkBestScore, 3, reason: 'best score is never lowered');
    expect(f.progress.checkLastScore, 0);
  });

  test('back works inside and between introduce and demonstrate only', () {
    final f = flowFor('en-a');
    expect(f.canGoBack, isFalse);
    finishPhase(f);
    expect(f.phase, TeachingPhase.demonstrate);
    expect(f.canGoBack, isTrue);
    f.back();
    expect(f.phase, TeachingPhase.introduce);
    expect(f.index, f.plan.introduce.length - 1);
    while (f.phase != TeachingPhase.guided) {
      finishPhase(f);
    }
    expect(f.canGoBack, isFalse);
  });
}
