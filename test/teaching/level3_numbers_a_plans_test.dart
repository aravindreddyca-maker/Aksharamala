import 'dart:convert';
import 'dart:io';

import 'package:aksharamala/src/teaching/teaching_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final text =
      File('content/teaching/level3_numbers_a.json').readAsStringSync();
  final raw = jsonDecode(text) as Map<String, dynamic>;
  final lessons = (raw['lessons'] as List).cast<Map<String, dynamic>>();
  final lib = TeachingPlanLibrary.parse([text]);

  List<Map<String, dynamic>> qs(Map<String, dynamic> l, String k) =>
      (l[k] as List).cast<Map<String, dynamic>>();

  test('file header and the 8 lessons parse with zero issues', () {
    expect(raw['status'], 'draft_unverified');
    expect(lessons.map((l) => l['lesson_id']),
        [for (var i = 1; i <= 8; i++) 'numbers-l3-00$i']);
    expect(lib.plansById.length, 8);
    expect(lib.issues, isEmpty);
    for (final l in lessons) {
      expect(l['world'], 'numbers');
      expect(l['level'], 3);
      expect(l['locale'], 'en-IN');
    }
  });

  test('phase counts, answers, wrong_feedback and hint ladders', () {
    for (final l in lessons) {
      final id = l['lesson_id'];
      expect((l['introduce'] as List).length, 2, reason: '$id');
      expect((l['demonstrate'] as List).length, 2, reason: '$id');
      expect((l['guided'] as List).length, 2, reason: '$id');
      expect((l['practice'] as List).length, 3, reason: '$id');
      expect((l['check'] as List).length, 3, reason: '$id');
      final rem = l['remediation'] as Map<String, dynamic>;
      expect((rem['guided'] as List).length, 2, reason: '$id');
      expect((rem['check'] as List).length, 3, reason: '$id');
      for (final phase in ['guided', 'practice', 'check']) {
        for (final q in [
          ...qs(l, phase),
          ...(phase == 'guided'
              ? qs(rem, 'guided')
              : phase == 'check'
                  ? qs(rem, 'check')
                  : [])
        ]) {
          final opts = (q['options'] as List).cast<String>();
          expect(opts.length, 3);
          expect(opts.toSet().length, 3);
          expect(opts, contains(q['answer']), reason: q['id']);
          final wrong = opts.where((o) => o != q['answer']).toSet();
          expect((q['wrong_feedback'] as Map).keys.toSet(), wrong,
              reason: q['id']);
          final hints = q['hints'] as List;
          if (phase == 'check') {
            expect(hints, isEmpty, reason: q['id']);
          } else {
            expect(hints.length, 2, reason: q['id']);
            expect((hints[0] as String).contains('${q['answer']}'), isFalse,
                reason: 'hint 1 leaks answer in ${q['id']}');
          }
        }
      }
    }
  });

  test('plain arithmetic prompts re-derived independently', () {
    final pat = RegExp(r'^(\d+) ([+x-]) (\d+) = \?$');
    var n = 0;
    final positions = <int>{};
    for (final l in lessons) {
      final rem = l['remediation'] as Map<String, dynamic>;
      for (final q in [
        ...qs(l, 'guided'),
        ...qs(l, 'practice'),
        ...qs(l, 'check'),
        ...qs(rem, 'guided'),
        ...qs(rem, 'check'),
      ]) {
        positions.add((q['options'] as List).indexOf(q['answer']));
        final m = pat.firstMatch(q['prompt'] as String);
        if (m == null) continue;
        final a = int.parse(m[1]!), b = int.parse(m[3]!);
        final want = switch (m[2]) { '+' => a + b, '-' => a - b, _ => a * b };
        expect(q['answer'], '$want', reason: q['prompt']);
        n++;
      }
    }
    expect(n, greaterThan(50));
    expect(positions, {0, 1, 2});
  });

  test('skip counting and group questions re-derived', () {
    final group = RegExp(
        r'^There are (\d+) \w+\. Each has (\d+) \w+\. How many \w+ are there altogether\?$');
    var n = 0;
    for (final l in lessons) {
      for (final q in [
        ...qs(l, 'guided'),
        ...qs(l, 'practice'),
        ...qs(l, 'check')
      ]) {
        final m = group.firstMatch(q['prompt'] as String);
        if (m == null) continue;
        expect(q['answer'], '${int.parse(m[1]!) * int.parse(m[2]!)}');
        n++;
      }
    }
    expect(n, greaterThan(4));
  });

  test('question visuals do not leak the answer', () {
    for (final l in lessons) {
      final rem = l['remediation'] as Map<String, dynamic>;
      for (final q in [
        ...qs(l, 'practice'),
        ...qs(l, 'check'),
        ...qs(rem, 'check'),
      ]) {
        final v = q['visual'] as Map<String, dynamic>;
        if (v['type'] == 'numberLine') expect(v['showHops'], false);
        if (v['type'] == 'objects') expect(v['showResult'], false);
        if (v['type'] == 'baseTen') expect(v['showTotal'], false);
      }
    }
  });
}
