import 'dart:convert';
import 'dart:io';

import 'package:aksharamala/src/teaching/teaching_plan.dart';
import 'package:flutter_test/flutter_test.dart';

const _file = 'content/teaching/level5_numbers_b.json';

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
    for (var n = 9; n <= 15; n++) 'numbers-l5-0${n < 10 ? '0$n' : n}'
  ];

  test('file header and the seven lesson ids', () {
    expect(data['status'], 'draft_unverified');
    expect([for (final l in lessons) l['lesson_id']], ids);
    for (final l in lessons) {
      expect(l['world'], 'numbers');
      expect(l['level'], 5);
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

  test('hint 1 never gives the answer and feedback is specific', () {
    for (final l in lessons) {
      for (final q in _questions(l)) {
        final a = q['answer'] as String;
        final hints = q['hints'] as List;
        if (hints.isNotEmpty && a.length >= 3) {
          expect(hints[0] as String, isNot(contains(a)),
              reason: '${q['id']}: hint 1 contains the answer');
        }
        final fb = Map<String, dynamic>.from(q['wrong_feedback'] as Map);
        expect(fb.values.toSet(), hasLength(fb.length),
            reason: '${q['id']}: identical wrong feedback');
      }
    }
  });

  test('arithmetic answers recomputed independently', () {
    var checked = 0;
    int n(RegExpMatch m, int g) => int.parse(m.group(g)!);
    String pt(int a, int b) => '($a, $b)';
    List<int> nums(String s) => [for (final x in s.split(', ')) int.parse(x)];
    int mean(List<int> v) {
      final t = v.fold<int>(0, (s, x) => s + x);
      expect(t % v.length, 0);
      return t ~/ v.length;
    }

    int median(List<int> v) {
      final s = [...v]..sort();
      if (s.length.isOdd) return s[s.length ~/ 2];
      final t = s[s.length ~/ 2 - 1] + s[s.length ~/ 2];
      expect(t % 2, 0);
      return t ~/ 2;
    }

    int mode(List<int> v) {
      final counts = <int, int>{};
      for (final x in v) {
        counts[x] = (counts[x] ?? 0) + 1;
      }
      final best = counts.values.reduce((a, b) => a > b ? a : b);
      final modes = counts.entries.where((e) => e.value == best).toList();
      expect(modes, hasLength(1));
      return modes.first.key;
    }

    String chance(int f, int o) => f == 0
        ? 'Impossible'
        : o == 0
            ? 'Certain'
            : f == o
                ? 'Even chance'
                : f > o
                    ? 'Likely'
                    : 'Unlikely';
    String kind(int a, int b, int c) {
      final k = {a, b, c}.length;
      return k == 1 ? 'Equilateral' : (k == 2 ? 'Isosceles' : 'Scalene');
    }

    for (final l in lessons) {
      for (final q in _questions(l)) {
        final p = q['prompt'] as String;
        final a = q['answer'] as String;
        final qid = q['id'];
        RegExpMatch? m;
        String? want;
        if ((m = RegExp(r'^Solve (\w) \+ (\d+) = (\d+)\.$').firstMatch(p)) !=
            null) {
          want = '${m!.group(1)} = ${n(m, 3) - n(m, 2)}';
        } else if ((m = RegExp(r'^Solve (\w) - (\d+) = (\d+)\.$').firstMatch(p)) !=
            null) {
          want = '${m!.group(1)} = ${n(m, 3) + n(m, 2)}';
        } else if ((m = RegExp(r'^Solve (\d+)(\w) = (\d+)\.$').firstMatch(p)) !=
            null) {
          expect(n(m!, 3) % n(m, 1), 0, reason: '$qid');
          want = '${m.group(2)} = ${n(m, 3) ~/ n(m, 1)}';
        } else if ((m = RegExp(r'^Solve (\w) ÷ (\d+) = (\d+)\.$').firstMatch(p)) !=
            null) {
          want = '${m!.group(1)} = ${n(m, 3) * n(m, 2)}';
        } else if ((m = RegExp(r'^I think of a number, add (\d+) and get (\d+)\. What is my number\?$')
                .firstMatch(p)) !=
            null) {
          want = '${n(m!, 2) - n(m, 1)}';
        } else if ((m =
                RegExp(r'^To solve x \+ (\d+) = (\d+), what do you do to both sides\?$')
                    .firstMatch(p)) !=
            null) {
          want = 'Take away ${m!.group(1)}';
        } else if ((m =
                RegExp(r'^Start at the origin \(0, 0\)\. Go (\d+) across and (\d+) up\. Which point')
                    .firstMatch(p)) !=
            null) {
          want = pt(n(m!, 1), n(m, 2));
        } else if ((m =
                RegExp(r'^Which ordered pair shows a point (\d+) across and (\d+) up\?$')
                    .firstMatch(p)) !=
            null) {
          want = pt(n(m!, 1), n(m, 2));
        } else if ((m = RegExp(r'^In the point \((\d+), (\d+)\), how far (across|up) is the point from the origin\?$').firstMatch(p)) != null) {
          want = m!.group(3) == 'across' ? '${n(m, 1)}' : '${n(m, 2)}';
        } else if ((m = RegExp(r'^Point A is at \((\d+), (\d+)\)\. Point B is (\d+) more across and the same height\.').firstMatch(p)) != null) {
          want = pt(n(m!, 1) + n(m, 3), n(m, 2));
        } else if ((m = RegExp(r'^Point A is at \((\d+), (\d+)\)\. Point B is (\d+) more up and the same distance across\.').firstMatch(p)) != null) {
          want = pt(n(m!, 1), n(m, 2) + n(m, 3));
        } else if ((m = RegExp(r'^P is at \((\d+), (\d+)\) and Q is at \((\d+), (\d+)\)\. How many units apart').firstMatch(p)) != null) {
          expect(n(m!, 1) == n(m, 3) || n(m, 2) == n(m, 4), isTrue,
              reason: '$qid');
          want = '${(n(m, 1) - n(m, 3)).abs() + (n(m, 2) - n(m, 4)).abs()}';
        } else if ((m = RegExp(r'^A triangle has sides (\d+) cm, (\d+) cm and (\d+) cm\. What kind').firstMatch(p)) != null) {
          final x = n(m!, 1), y = n(m, 2), z = n(m, 3);
          expect(x + y > z && x + z > y && y + z > x, isTrue, reason: '$qid');
          want = kind(x, y, z);
        } else if ((m = RegExp(r'^Two angles of a triangle are (\d+)° and (\d+)°\. What is the third angle\?$').firstMatch(p)) != null) {
          want = '${180 - n(m!, 1) - n(m, 2)}°';
        } else if ((m = RegExp(r'^A cuboid is (\d+) cm long, (\d+) cm wide and (\d+) cm high\. What is its volume\?$').firstMatch(p)) != null) {
          want = '${n(m!, 1) * n(m, 2) * n(m, 3)} cm³';
        } else if ((m = RegExp(r'^A cube has edges of (\d+) cm\. What is its volume\?$').firstMatch(p)) != null) {
          final s = n(m!, 1);
          want = '${s * s * s} cm³';
        } else if ((m = RegExp(r'^A box is filled with (\d+) layers of (\d+) cubes\.').firstMatch(p)) != null) {
          want = '${n(m!, 1) * n(m, 2)}';
        } else if ((m = RegExp(r'^A cuboid has a volume of (\d+) cm³ and a base area of (\d+) cm²\. What is its height\?$').firstMatch(p)) != null) {
          expect(n(m!, 1) % n(m, 2), 0, reason: '$qid');
          want = '${n(m, 1) ~/ n(m, 2)} cm';
        } else if ((m = RegExp(r'^What is the (mean|median|mode) of (\d+(?:, \d+)*)\?$').firstMatch(p)) != null) {
          final v = nums(m!.group(2)!);
          final w = m.group(1);
          want =
              '${w == 'mean' ? mean(v) : (w == 'median' ? median(v) : mode(v))}';
        } else if ((m = RegExp(r'^The mean of 3 numbers is (\d+)\. Two of them are (\d+) and (\d+)\.').firstMatch(p)) != null) {
          want = '${3 * n(m!, 1) - n(m, 2) - n(m, 3)}';
        } else if ((m = RegExp(r'^A bag has (\d+) red marbles and (\d+) blue marbles\. You pick one without looking\. How likely is it to pick (red|blue)\?$').firstMatch(p)) != null) {
          final r = n(m!, 1), b = n(m, 2);
          want = m.group(3) == 'red' ? chance(r, b) : chance(b, r);
        } else if ((m = RegExp(r'^A bag has (\d+) red marbles and (\d+) blue marbles\. What is the chance of picking (red|blue) as a fraction\?$').firstMatch(p)) != null) {
          final r = n(m!, 1), b = n(m, 2);
          final f = m.group(3) == 'red' ? r : b;
          final g = f.gcd(r + b);
          want = '${f ~/ g}/${(r + b) ~/ g}';
        } else if ((m = RegExp(r'^A budget is ₹(\d+)\. Spending: \w+ ₹(\d+), \w+ ₹(\d+) and \w+ ₹(\d+)\. How much is left\?$').firstMatch(p)) != null) {
          want = '₹${n(m!, 1) - n(m, 2) - n(m, 3) - n(m, 4)}';
        } else if ((m = RegExp(r'^\w+ buys (\d+) \w+ at ₹(\d+) each and pays ₹(\d+)\. How much change').firstMatch(p)) != null) {
          want = '₹${n(m!, 3) - n(m, 1) * n(m, 2)}';
        } else if ((m = RegExp(r'^(\d+) (\w+) cost ₹(\d+)\. How much do (\d+) \2 cost\?$').firstMatch(p)) != null) {
          expect(n(m!, 3) % n(m, 1), 0, reason: '$qid');
          want = '₹${n(m, 3) ~/ n(m, 1) * n(m, 4)}';
        } else if ((m = RegExp(r'^Shop A sells (\d+) \w+ for ₹(\d+)\. Shop B sells (\d+) \w+ for ₹(\d+)\.').firstMatch(p)) != null) {
          final na = n(m!, 1), pa = n(m, 2), nb = n(m, 3), pb = n(m, 4);
          expect(pa % na, 0, reason: '$qid');
          expect(pb % nb, 0, reason: '$qid');
          final ua = pa ~/ na, ub = pb ~/ nb;
          expect(ua == ub, isFalse, reason: '$qid');
          want = ua < ub ? 'Shop A' : 'Shop B';
        } else if ((m = RegExp(r'^Arun saves ₹(\d+) a week\. How many weeks will Arun need to save ₹(\d+)\?$').firstMatch(p)) != null) {
          expect(n(m!, 2) % n(m, 1), 0, reason: '$qid');
          want = '${n(m, 2) ~/ n(m, 1)} weeks';
        } else if ((m = RegExp(r'^A (\w+) costs ₹(\d+)\. It is sold at (\d+)% off\. What is the sale price\?$').firstMatch(p)) != null) {
          expect(n(m!, 2) * n(m, 3) % 100, 0, reason: '$qid');
          want = '₹${n(m, 2) - n(m, 2) * n(m, 3) ~/ 100}';
        }
        if (want != null) {
          expect(a, want, reason: '$qid: $p');
          checked++;
        }
      }
    }
    expect(checked, greaterThanOrEqualTo(75));
  });
}
