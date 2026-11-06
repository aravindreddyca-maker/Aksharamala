// Independent adversarial checks of the teaching flow (ui-verifier).
// Uses only injected plan loader + in-memory store; nothing touches the disk
// except reading the pilot JSON. Infrastructure helpers come from
// test/teaching/helpers.dart; every assertion here is the verifier's own.
import 'dart:convert';

import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/models.dart';
import 'package:aksharamala/src/teaching/teaching_flow.dart';
import 'package:aksharamala/src/teaching/teaching_plan.dart';
import 'package:aksharamala/src/teaching/teaching_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teaching/helpers.dart';

const lessons = ['en-a', 'te-a', 'hi-a', 'ta-a', 'num-add'];

void collect(SemanticsNode n, List<String> out) {
  final d = n.getSemanticsData();
  final parts = [d.label, d.value, d.hint].where((s) => s.isNotEmpty);
  if (parts.isNotEmpty) out.add(parts.join(' | '));
  n.visitChildren((c) {
    collect(c, out);
    return true;
  });
}

List<String> allSemantics(WidgetTester tester) {
  final out = <String>[];
  collect(tester.getSemantics(find.byType(Scaffold).first), out);
  return out;
}

Future<void> tapKey(WidgetTester t, String key) async {
  final f = find.byKey(Key(key));
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

/// The question on screen, matched by prompt AND the exact option set (prompts
/// repeat across phases, e.g. 'How many altogether?').
TeachingQuestion onScreen(WidgetTester t, List<TeachingQuestion> pool) {
  final prompt =
      (t.widget(find.byKey(const Key('question_prompt'))) as Text).data!;
  final shown = <String>{};
  for (final e in t.widgetList(find.byWidgetPredicate(
      (w) => w.key is Key && (w.key.toString().contains("[<'option_"))))) {
    final k = e.key.toString();
    shown.add(k.substring(k.indexOf("option_") + 7, k.lastIndexOf("'")));
  }
  return pool.firstWhere((x) =>
      x.prompt == prompt &&
      x.options.toSet().length == shown.length &&
      x.options.toSet().containsAll(shown));
}

/// Plays steps/guided/practice via the UI until the check phase's first item.
Future<void> toCheck(WidgetTester t, TeachingPlan plan) async {
  for (var guard = 0; guard < 80; guard++) {
    if (find.byKey(const Key('phase_label')).evaluate().isEmpty) break;
    final label =
        (t.widget(find.byKey(const Key('phase_label'))) as Text).data!;
    if (label.startsWith('5 of 5')) return;
    final q = find.byKey(const Key('question_prompt'));
    if (q.evaluate().isNotEmpty) {
      final item = onScreen(t, [...plan.guided, ...plan.practice]);
      await tapKey(t, 'option_${item.answer}');
    }
    await tapNext(t);
  }
}

void main() {
  for (final id in lessons) {
    testWidgets(
        '$id: check items never leak the answer via Semantics/visible text',
        (tester) async {
      final handle = tester.ensureSemantics();
      final c = await makeController(level: id == 'num-add' ? 2 : 1);
      final plan = c.planFor(id)!;
      final allLeaks = <String>[];
      await pumpLesson(tester, c, id, size: const Size(1024, 768));
      await toCheck(tester, plan);
      for (var i = 0; i < plan.check.length; i++) {
        final q = onScreen(tester, plan.check);
        final sem = allSemantics(tester);
        final optionLabels = q.options.toSet();
        // Any semantics node that mentions the answer must be an option node
        // (label == option text) or the prompt itself.
        final leaks = sem.where((s) {
          // One-letter answers: a label leaks only if some segment IS the
          // letter (exact) - 'a' is inside nearly every English sentence.
          final segs = s.split(' | ');
          final hit = q.answer.runes.length == 1
              ? segs.any((x) => x.trim() == q.answer)
              : s.contains(q.answer);
          if (!hit) return false;
          final first = s.split(' | ').first;
          if (optionLabels.contains(first)) return false;
          if (s.contains(q.prompt)) return false;
          return true;
        }).toList();
        // Visible Text widgets outside options/prompt must not show answer.
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data ?? '')
            .where((s) => s == q.answer)
            .length;
        // option tile contains it once (the tile text). Anything more leaks.
        expect(texts, lessThanOrEqualTo(1),
            reason: '${q.id}: answer printed outside its option tile');
        // No feedback widgets, hint button or correctness icon in a check.
        expect(find.byKey(const Key('hint_button')), findsNothing);
        expect(find.byKey(const Key('feedback_text')), findsNothing);
        expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
        // Tap wrong then right: still no state revealed.
        await tapKey(tester, 'option_${wrongOf(q)}');
        expect(find.byKey(const Key('feedback_text')), findsNothing);
        expect(find.byIcon(Icons.cancel_rounded), findsNothing);
        final afterTap = allSemantics(tester).join('\n');
        expect(afterTap.contains('correct'), isFalse,
            reason: '${q.id}: semantic state says correct');
        expect(afterTap.contains('not this one'), isFalse);
        if (leaks.isNotEmpty) allLeaks.add('${q.id}: $leaks');
        await tapKey(tester, 'option_${q.answer}');
        await tapNext(tester);
      }
      handle.dispose();
      expect(allLeaks, isEmpty,
          reason:
              'answer text found outside option tile/prompt (app bar title?)');
    });
  }

  testWidgets('double-tap on the last check Next does not skip the score page',
      (tester) async {
    final c = await makeController();
    final plan = c.planFor('en-a')!;
    await pumpLesson(tester, c, 'en-a');
    await toCheck(tester, plan);
    for (var i = 0; i < plan.check.length - 1; i++) {
      final q = onScreen(tester, plan.check);
      await tapKey(tester, 'option_${q.answer}');
      await tapNext(tester);
    }
    final q = onScreen(tester, plan.check);
    await tapKey(tester, 'option_${q.answer}');
    final next = find.byKey(const Key('next_button'));
    await tester.tap(next);
    await tester.pump(const Duration(milliseconds: 80)); // realistic double tap
    final stillThere = next.evaluate().isNotEmpty;
    if (stillThere) {
      await tester.tap(next);
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Score page should still be showing after two taps.
    expect(find.byKey(const Key('check_score')), findsOneWidget,
        reason: 'second quick tap skipped the score page');
  });

  testWidgets(
      'wrong answers everywhere -> remediation -> fail -> needsSupport; '
      'nothing paid, not completed, child can leave', (tester) async {
    final c = await makeController();
    final plan = c.planFor('te-a')!;
    await pumpLesson(tester, c, 'te-a');
    await toCheck(tester, plan);
    Future<void> failCheck(List<TeachingQuestion> qs) async {
      for (var i = 0; i < qs.length; i++) {
        final q = onScreen(tester, qs);
        await tapKey(tester, 'option_${wrongOf(q)}');
        await tapNext(tester);
      }
    }

    Future<void> playGuided(List<TeachingQuestion> qs) async {
      for (var i = 0; i < qs.length; i++) {
        final q = onScreen(tester, qs);
        await tapKey(tester, 'option_${wrongOf(q)}');
        await tapKey(tester, 'option_${q.answer}');
        await tapNext(tester);
      }
    }

    await failCheck(plan.check);
    expect(find.byKey(const Key('check_score')), findsOneWidget);
    expect(find.text('0 out of 3'), findsOneWidget);
    for (var cycle = 1; cycle <= plan.mastery.maxRemediationCycles; cycle++) {
      await tapNext(tester); // Get extra help
      expect(find.byKey(const Key('remediation_banner')), findsOneWidget);
      while (find.byKey(const Key('question_prompt')).evaluate().isEmpty) {
        await tapNext(tester);
      }
      await playGuided(plan.remediation.guided);
      await failCheck(plan.remediation.check);
      expect(find.byKey(const Key('check_score')), findsOneWidget);
    }
    await tapNext(tester); // Continue
    expect(find.byKey(const Key('needs_support_card')), findsOneWidget);
    expect(c.activeProgress.completedLessons, isNot(contains('te-a')));
    expect(c.activeProfile!.stars, 0);
    expect(c.teachingProgressFor('te-a').mastery, MasteryStatus.needsSupport);
    expect(find.byKey(const Key('support_back')), findsOneWidget);
    expect(find.byKey(const Key('next_button')), findsNothing);
  });

  testWidgets(
      'replay of a completed lesson pays no extra stars; mastered '
      'is never downgraded by a failed replay', (tester) async {
    final c = await makeController();
    final world = worldOf(c, 'en-a');
    final lesson = lessonOf(c, 'en-a');
    await c.recordTeachingMastery(
        world: world,
        lesson: lesson,
        teaching: const TeachingProgress(viewed: true, checkBestScore: 3));
    final stars = c.activeProfile!.stars;
    final plan = c.planFor('en-a')!;
    await pumpLesson(tester, c, 'en-a');
    // Fail the replayed check twice over (all cycles).
    await toCheck(tester, plan);
    for (var round = 0;
        round < 1 + plan.mastery.maxRemediationCycles;
        round++) {
      final qs = round == 0 ? plan.check : plan.remediation.check;
      for (var i = 0; i < qs.length; i++) {
        final q = onScreen(tester, qs);
        await tapKey(tester, 'option_${wrongOf(q)}');
        await tapNext(tester);
      }
      await tapNext(tester); // result -> remediation / support
      if (round < plan.mastery.maxRemediationCycles) {
        while (find.byKey(const Key('question_prompt')).evaluate().isEmpty) {
          await tapNext(tester);
        }
        for (var i = 0; i < plan.remediation.guided.length; i++) {
          final q = onScreen(tester, plan.remediation.guided);
          await tapKey(tester, 'option_${q.answer}');
          await tapNext(tester);
        }
      }
    }
    expect(find.byKey(const Key('needs_support_card')), findsOneWidget);
    expect(c.teachingProgressFor('en-a').mastery, MasteryStatus.mastered);
    expect(c.activeProgress.completedLessons, contains('en-a'));
    expect(c.activeProfile!.stars, stars);
  });

  testWidgets('pass path pays 3 stars once; replay and pass pays 0',
      (tester) async {
    final c = await makeController();
    final plan = c.planFor('en-a')!;
    await pumpLesson(tester, c, 'en-a');
    await toCheck(tester, plan);
    for (var i = 0; i < plan.check.length; i++) {
      final q = onScreen(tester, plan.check);
      await tapKey(tester, 'option_${q.answer}');
      await tapNext(tester);
    }
    await tapNext(tester); // Finish
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.activeProfile!.stars, 3);
    expect(c.activeProgress.attempts.values.fold<int>(0, (a, b) => a + b), 1);
    // replay
    final again = await c.recordTeachingMastery(
        world: worldOf(c, 'en-a'),
        lesson: lessonOf(c, 'en-a'),
        teaching: c.teachingProgressFor('en-a'));
    expect(again, 0);
    expect(c.activeProfile!.stars, 3);
  });

  testWidgets('backgrounding mid-guided keeps hints and tried options',
      (tester) async {
    final c = await makeController();
    final plan = c.planFor('te-a')!;
    await pumpLesson(tester, c, 'te-a');
    while (find.byKey(const Key('question_prompt')).evaluate().isEmpty) {
      await tapNext(tester);
    }
    final q = onScreen(tester, plan.guided);
    await tapKey(tester, 'hint_button');
    await tapKey(tester, 'option_${wrongOf(q)}');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('hint_text_0')), findsOneWidget);
    expect(find.byKey(const Key('feedback_text')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hint 1 of every guided question does not contain the answer',
      (tester) async {
    final c = await makeController();
    for (final id in lessons) {
      final p = c.planFor(id)!;
      for (final q in [...p.guided, ...p.remediation.guided]) {
        if (q.hints.isEmpty) continue;
        // Single-character answers (letters/digits) would match by chance in
        // long text; only flag whole-token matches.
        final tokens = RegExp(r'[^\s,.:;!?()]+').allMatches(q.hints.first);
        final hit =
            tokens.any((m) => m.group(0) == q.answer && q.answer.length > 1);
        expect(hit, isFalse, reason: '${q.id} hint 1 reveals the answer');
      }
    }
  });

  test('option shuffle: answer never in stored slot, across 200 seeds', () {
    final lib = pilotLibrary();
    for (final id in lessons) {
      final plan = lib.planFor(id)!;
      for (var seed = 0; seed < 200; seed++) {
        final f = TeachingFlow(plan: plan, seed: seed);
        for (final q in [
          ...plan.guided,
          ...plan.practice,
          ...plan.check,
          ...plan.remediation.guided,
          ...plan.remediation.check,
        ]) {
          final o = f.optionsFor(q);
          expect(o.toSet(), q.options.toSet());
          expect(o.indexOf(q.answer), isNot(q.options.indexOf(q.answer)),
              reason: '$id ${q.id} seed $seed');
        }
      }
    }
  });

  test('no independent question before teaching; order is strict', () {
    final lib = pilotLibrary();
    for (final id in lessons) {
      final f = TeachingFlow(plan: lib.planFor(id)!, seed: 1);
      final seen = <TeachingPhase>[f.phase];
      var guard = 0;
      while (f.phase != TeachingPhase.checkResult && guard++ < 100) {
        final q = f.question;
        if (q != null) f.pick(q.answer);
        f.next();
        if (seen.last != f.phase) seen.add(f.phase);
      }
      expect(seen, [
        TeachingPhase.introduce,
        TeachingPhase.demonstrate,
        TeachingPhase.guided,
        TeachingPhase.practice,
        TeachingPhase.check,
        TeachingPhase.checkResult,
      ]);
    }
  });

  test('old save without teaching round-trips; corrupt teaching field loads',
      () {
    final old = {
      'completedLessons': ['en-a'],
      'attempts': {'english': 1},
      'correct': {'english': 1},
      'lastPlayed': <String, String>{},
      'earnedBadges': <String>[],
      'questStars': {'en-a': 3},
      'levelAttempts': <String, int>{},
      'levelCorrect': <String, int>{},
    };
    final rec = ProgressRecord.fromJson(old);
    expect(rec.teaching, isEmpty);
    expect(rec.toJson().containsKey('teaching'), isFalse);
    for (final bad in <Object?>[
      {'en-a': 'oops'},
      {'en-a': null}
    ]) {
      final r = ProgressRecord.fromJson({...old, 'teaching': bad});
      expect(r.completedLessons, ['en-a']);
    }
    final weird = ProgressRecord.fromJson({
      ...old,
      'teaching': {
        'en-a': {'mastery': 'bogus', 'phasesDone': 'x', 'phase': 7},
      },
    });
    expect(weird.teaching['en-a']!.mastery, MasteryStatus.notStarted);
  }, skip: false);

  test('level switching keeps teaching progress; lesson with no plan has none',
      () async {
    final c = await makeController(level: 1);
    await c.saveTeachingProgress(
        'te-a', const TeachingProgress(viewed: true, phase: 'guided'));
    await c.setLevel(2);
    await c.setLevel(5);
    await c.setLevel(1);
    expect(c.teachingProgressFor('te-a').phase, 'guided');
    expect(c.planFor('te-b'), isNull);
    expect(c.planFor('te-a'), isNotNull);
    // A bad plan file: no plan, controller still loads.
    final broken = AppController(
        store: NoDiskStore(), teachingPlanLoader: () async => ['{not json']);
    await broken.initialise();
    expect(broken.loaded, isTrue);
    expect(broken.planFor('te-a'), isNull);
    // Round trip through JSON string.
    final js = jsonEncode(c.activeProgress.toJson());
    expect(
        ProgressRecord.fromJson(jsonDecode(js) as Map<String, dynamic>)
            .teaching['te-a']!
            .phase,
        'guided');
  });

  test('every pilot picture with empty caption is a question visual', () {
    final lib = pilotLibrary();
    for (final id in lessons) {
      final p = lib.planFor(id)!;
      for (final s in [...p.introduce, ...p.demonstrate]) {
        if (s.visual.type == VisualType.picture) {
          expect(s.visual.caption, isNotEmpty,
              reason: '$id step ${s.id}: teaching picture lacks caption');
        }
      }
      for (final q in [...p.check, ...p.remediation.check, ...p.practice]) {
        if (q.visual.type == VisualType.picture) {
          expect(q.visual.caption, isEmpty,
              reason: '${q.id} caption prints answer');
        }
      }
    }
  });
}
