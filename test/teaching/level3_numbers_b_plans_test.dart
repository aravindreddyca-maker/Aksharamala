import 'dart:convert';
import 'dart:io';

import 'package:aksharamala/src/teaching/teaching_plan.dart';
import 'package:flutter_test/flutter_test.dart';

const _file = 'content/teaching/level3_numbers_b.json';

Iterable<Map<String, dynamic>> _questions(Map<String, dynamic> lesson) sync* {
  Iterable<Map<String, dynamic>> list(dynamic v) =>
      (v as List).map((e) => Map<String, dynamic>.from(e as Map));
  for (final k in ['guided', 'practice', 'check']) {
    yield* list(lesson[k]);
  }
  final r = lesson['remediation'] as Map;
  yield* list(r['guided']);
  yield* list(r['check']);
}

void main() {
  final text = File(_file).readAsStringSync();
  final data = jsonDecode(text) as Map<String, dynamic>;
  final lessons = [
    for (final l in data['lessons'] as List) Map<String, dynamic>.from(l as Map)
  ];
  final ids = [
    for (var n = 9; n <= 15; n++) 'numbers-l3-0${n < 10 ? '0$n' : n}'
  ];

  test('file header and the seven lesson ids', () {
    expect(data['status'], 'draft_unverified');
    expect([for (final l in lessons) l['lesson_id']], ids);
    for (final l in lessons) {
      expect(l['world'], 'numbers');
      expect(l['level'], 3);
      expect(l['locale'], 'en-IN');
    }
  });

  test('all seven plans pass the plan validator', () {
    final lib = TeachingPlanLibrary.parse([text]);
    final plans = lib.plansById;
    expect(lib.issues, isEmpty);
    expect(plans.keys.toSet(), ids.toSet());
  });

  test('phase counts, hints, answers and wrong feedback', () {
    for (final l in lessons) {
      final id = l['lesson_id'];
      expect((l['introduce'] as List), hasLength(2), reason: id);
      expect((l['demonstrate'] as List), hasLength(2), reason: id);
      expect((l['guided'] as List), hasLength(2), reason: id);
      expect((l['practice'] as List), hasLength(3), reason: id);
      expect((l['check'] as List), hasLength(3), reason: id);
      final rem = l['remediation'] as Map;
      expect((rem['explain'] as List), hasLength(3), reason: id);
      expect((rem['guided'] as List), hasLength(2), reason: id);
      expect((rem['check'] as List), hasLength(3), reason: id);
      final prompts = <String>{};
      for (final q in _questions(l)) {
        final qid = q['id'];
        final options = List<String>.from(q['options'] as List);
        expect(options, hasLength(3), reason: '$qid');
        expect(options.toSet(), hasLength(3), reason: '$qid');
        expect(options, contains(q['answer']), reason: '$qid');
        final wrong = options.where((o) => o != q['answer']).toSet();
        final fb = Map<String, dynamic>.from(q['wrong_feedback'] as Map);
        expect(fb.keys.toSet(), wrong, reason: '$qid');
        for (final v in fb.values) {
          expect((v as String).trim(), isNotEmpty);
        }
        expect(prompts.add(q['prompt'] as String), isTrue,
            reason: 'duplicate prompt $qid');
        final hints = q['hints'] as List;
        final isCheck =
            '$qid'.contains('.check.') || '$qid'.contains('remediation_check');
        if (isCheck) {
          expect(hints, isEmpty, reason: '$qid');
        } else {
          expect(hints, hasLength(2), reason: '$qid');
        }
      }
    }
  });

  test('answer positions are varied in every lesson', () {
    for (final l in lessons) {
      final pos = <int>{
        for (final q in _questions(l))
          List<String>.from(q['options'] as List).indexOf(q['answer'] as String)
      };
      expect(pos.length, 3, reason: '${l['lesson_id']}');
    }
  });

  test('arithmetic answers recomputed independently', () {
    var checked = 0;
    int n(RegExpMatch m, int g) => int.parse(m.group(g)!);
    for (final l in lessons) {
      for (final q in _questions(l)) {
        final p = q['prompt'] as String;
        final a = q['answer'] as String;
        final qid = q['id'];
        RegExpMatch? m;
        int? want;
        String? wantText;
        if ((m = RegExp(r'^(\d+) ÷ (\d+) = \?$').firstMatch(p)) != null) {
          expect(n(m!, 1) % n(m, 2), 0, reason: '$qid');
          want = n(m, 1) ~/ n(m, 2);
        } else if ((m = RegExp(r'^(\d+) x (\d+) = \?$').firstMatch(p)) !=
            null) {
          want = n(m!, 1) * n(m, 2);
        } else if ((m = RegExp(r'^(\d+) x (\d+) = (\d+), so (\d+) ÷ (\d+) = \?$')
                .firstMatch(p)) !=
            null) {
          expect(n(m!, 1) * n(m, 2), n(m, 3), reason: '$qid');
          expect(n(m, 4), n(m, 3), reason: '$qid');
          expect(n(m, 5), n(m, 2), reason: '$qid');
          want = n(m, 3) ~/ n(m, 5);
        } else if ((m = RegExp(r'^(\d+) x \? = (\d+)$').firstMatch(p)) !=
            null) {
          expect(n(m!, 2) % n(m, 1), 0, reason: '$qid');
          want = n(m, 2) ~/ n(m, 1);
        } else if ((m = RegExp(r'^₹(\d+) - ₹(\d+) = \?$').firstMatch(p)) !=
            null) {
          wantText = '₹${n(m!, 1) - n(m, 2)}';
        } else if ((m = RegExp(r'pays ₹(\d+) for a .* costs ₹(\d+)\. ').firstMatch(p)) !=
            null) {
          wantText = '₹${n(m!, 1) - n(m, 2)}';
        } else if ((m =
                RegExp(r'costs ₹(\d+) and a .* costs ₹(\d+)\. What is the total')
                    .firstMatch(p)) !=
            null) {
          wantText = '₹${n(m!, 1) + n(m, 2)}';
        } else if ((m =
                RegExp(r'^(\d+) \w+ are shared equally (?:among|between) (\d+) .*How many')
                    .firstMatch(p)) !=
            null) {
          expect(n(m!, 1) % n(m, 2), 0, reason: '$qid');
          want = n(m, 1) ~/ n(m, 2);
        } else if ((m =
                RegExp(r'^(\d+) eggs are packed equally into (\d+) boxes')
                    .firstMatch(p)) !=
            null) {
          expect(n(m!, 1) % n(m, 2), 0, reason: '$qid');
          want = n(m, 1) ~/ n(m, 2);
        } else if ((m = RegExp(r'^(\d+) bags have (\d+) apples each').firstMatch(p)) != null) {
          want = n(m!, 1) * n(m, 2);
        } else if ((m = RegExp(r'had (\d+) stickers\. He gave (\d+) stickers').firstMatch(p)) != null) {
          want = n(m!, 1) - n(m, 2);
        } else if ((m = RegExp(r'has (\d+) marbles and Tom has (\d+) marbles').firstMatch(p)) != null) {
          want = n(m!, 1) + n(m, 2);
        } else if ((m = RegExp(r'has (\d+) pencils\. He buys (\d+) more and then gives (\d+) pencils').firstMatch(p)) != null) {
          want = n(m!, 1) + n(m, 2) - n(m, 3);
        }
        if (want != null) {
          expect(a, '$want', reason: '$qid: $p');
          checked++;
        } else if (wantText != null) {
          expect(a, wantText, reason: '$qid: $p');
          checked++;
        }
      }
    }
    expect(checked, greaterThan(40));
  });
}
