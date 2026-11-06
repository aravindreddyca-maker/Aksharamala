// Verifier sweep: play every rolled-out numbers lesson (and every 4th letter
// lesson) through the UI at two sizes; fail on any layout exception, or on a
// missing quest card/lesson. Layout only (test font), no visual judgement.
import 'dart:io';

import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/teaching/teaching_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teaching/helpers.dart';

TeachingQuestion? current(WidgetTester t, List<TeachingQuestion> pool) {
  final p = find.byKey(const Key('question_prompt'));
  if (p.evaluate().isEmpty) return null;
  final prompt = (t.widget(p) as Text).data!;
  final shown = <String>{};
  for (final w in t.widgetList(
      find.byWidgetPredicate((w) => w.key.toString().contains("[<'option_")))) {
    final k = w.key.toString();
    shown.add(k.substring(k.indexOf('option_') + 7, k.lastIndexOf("'")));
  }
  for (final q in pool) {
    if (q.prompt == prompt &&
        q.options.toSet().containsAll(shown) &&
        shown.isNotEmpty) return q;
  }
  return null;
}

int reachedEnd = 0;
int stepsTotal = 0;
Future<void> play(WidgetTester t, TeachingPlan plan,
    {required bool fail}) async {
  final pool = [
    ...plan.guided,
    ...plan.practice,
    ...plan.check,
    ...plan.remediation.guided,
    ...plan.remediation.check
  ];
  for (var i = 0; i < 90; i++) {
    if (find.byKey(const Key('mastered_card')).evaluate().isNotEmpty ||
        find.byKey(const Key('needs_support_card')).evaluate().isNotEmpty) {
      reachedEnd++;
      return;
    }
    stepsTotal++;
    final q = current(t, pool);
    if (q != null) {
      final isCheck = find.byKey(const Key('hint_button')).evaluate().isEmpty &&
          (t.widget(find.byKey(const Key('phase_label'))) as Text)
              .data!
              .contains('Check');
      final pick = (isCheck && fail)
          ? q.options.firstWhere((o) => o != q.answer)
          : q.answer;
      final f = find.byKey(Key('option_$pick'));
      await t.ensureVisible(f);
      await t.tap(f);
      await t.pump(const Duration(milliseconds: 60));
    }
    final cont = find.byKey(const Key('continue_button'));
    final next = find.byKey(const Key('next_button'));
    if (cont.evaluate().isNotEmpty) {
      await t.pump(const Duration(milliseconds: 700));
      await t.tap(cont);
    } else if (next.evaluate().isNotEmpty) {
      await t.ensureVisible(next);
      await t.tap(next);
    } else {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.pump(const Duration(milliseconds: 80));
    expect(t.takeException(), isNull, reason: '${plan.lessonId} step $i');
  }
}

void main() {
  final texts = [
    File('content/teaching/rollout_numbers.json').readAsStringSync(),
    File('content/teaching/rollout_letters.json').readAsStringSync(),
    pilotJson(),
  ];
  final lib = TeachingPlanLibrary.parse(texts);
  final ids = <String>[];
  for (final f in texts) {
    for (final m in RegExp(r'"lesson_id":\s*"([^"]+)"').allMatches(f)) {
      ids.add(m.group(1)!);
    }
  }
  final sizes = {
    'phone landscape': const Size(915, 410),
    'phone small': const Size(360, 800)
  };
  for (final e in sizes.entries) {
    testWidgets('sweep ${e.key}', (tester) async {
      final c = AppController(
          store: NoDiskStore(), teachingPlanLoader: () async => texts);
      await c.initialise();
      await c.createProfile(name: 'Kid', level: 1, avatar: 'lion');
      var n = 0;
      final problems = <String>[];
      for (var k = 0; k < ids.length; k++) {
        final id = ids[k];
        final plan = lib.planFor(id);
        if (plan == null) {
          problems.add('$id: no plan');
          continue;
        }
        if (!id.startsWith('numbers') && !id.startsWith('num-') && k % 4 != 0)
          continue;
        try {
          await tester.pumpWidget(const SizedBox());
          await pumpLesson(tester, c, id, size: e.value, textScale: 1.0);
          final before = reachedEnd;
          await play(tester, plan, fail: k % 3 == 0);
          if (reachedEnd == before) {
            final lab = find.byKey(const Key('phase_label')).evaluate().isEmpty
                ? '?'
                : (tester.widget(find.byKey(const Key('phase_label'))) as Text)
                    .data;
            final pr =
                find.byKey(const Key('question_prompt')).evaluate().isEmpty
                    ? '-'
                    : (tester.widget(find.byKey(const Key('question_prompt')))
                            as Text)
                        .data;
            problems.add('$id: no end; stuck at [$lab] [$pr]');
          }
          n++;
        } catch (err) {
          problems.add('$id: ${err.toString().split('\n').first}');
        }
      }
      // ignore: avoid_print
      print(
          'SWEEP ${e.key}: played $n lessons, reachedEnd=$reachedEnd steps=$stepsTotal, ${problems.length} problems');
      for (final p in problems) {
        // ignore: avoid_print
        print('  PROBLEM $p');
      }
      expect(problems, isEmpty);
    }, timeout: const Timeout(Duration(minutes: 20)));
  }
}
