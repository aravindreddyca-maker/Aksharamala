import 'dart:convert';
import 'dart:io';

import 'package:aksharamala/src/teaching/teaching_plan.dart';
import 'package:flutter_test/flutter_test.dart';

const _file = 'content/teaching/level4_numbers_b.json';

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
    for (var n = 9; n <= 15; n++) 'numbers-l4-0${n < 10 ? '0$n' : n}'
  ];

  test('file header and the seven lesson ids', () {
    expect(data['status'], 'draft_unverified');
    expect([for (final l in lessons) l['lesson_id']], ids);
    for (final l in lessons) {
      expect(l['world'], 'numbers');
      expect(l['level'], 4);
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
    String cls(int d) => d < 90 ? 'Acute' : (d == 90 ? 'Right' : 'Obtuse');
    const factors = {
      'm>cm': 100,
      'km>m': 1000,
      'kg>g': 1000,
      'L>mL': 1000,
    };
    for (final l in lessons) {
      for (final q in _questions(l)) {
        final p = q['prompt'] as String;
        final a = q['answer'] as String;
        final qid = q['id'];
        RegExpMatch? m;
        String? want;
        if ((m = RegExp(r'^What is (\d+)% of (\d+)\?$').firstMatch(p)) != null ||
            (m = RegExp(r'^A class has (\d+) children\. (\d+)% of them walk').firstMatch(p)) !=
                null) {
          final isClass = p.startsWith('A class');
          final t = isClass ? n(m!, 1) : n(m!, 2);
          final pc = isClass ? n(m, 2) : n(m, 1);
          expect(t * pc % 100, 0, reason: '$qid');
          want = '${t * pc ~/ 100}';
        } else if ((m = RegExp(r'^(\d+) beads: (\d+) are red\.').firstMatch(p)) !=
            null) {
          expect(100 % n(m!, 1), 0, reason: '$qid');
          want = '${n(m, 2) * 100 ~/ n(m, 1)}%';
        } else if ((m =
                RegExp(r'^Write (\d+)/(\d+) as a percent\.$').firstMatch(p)) !=
            null) {
          expect(100 % n(m!, 2), 0, reason: '$qid');
          want = '${n(m, 1) * 100 ~/ n(m, 2)}%';
        } else if ((m = RegExp(r'^Write (\d+)% as a decimal\.$').firstMatch(p)) !=
            null) {
          expect((double.parse(a) * 100 - n(m!, 1)).abs() < 1e-9, isTrue,
              reason: '$qid');
          want = a;
        } else if ((m = RegExp(r'^Which fraction is the same as (\d+)%\?$').firstMatch(p)) !=
            null) {
          final parts = a.split('/');
          expect(int.parse(parts[0]) * 100, n(m!, 1) * int.parse(parts[1]),
              reason: '$qid');
          want = a;
        } else if ((m =
                RegExp(r'^A bag has (\d+) red balls and (\d+) blue balls\. What is the ratio of red to blue\?$')
                    .firstMatch(p)) !=
            null) {
          want = '${n(m!, 1)} : ${n(m, 2)}';
        } else if ((m =
                RegExp(r'^Write the ratio (\d+) : (\d+) in its simplest form\.$')
                    .firstMatch(p)) !=
            null) {
          final g = n(m!, 1).gcd(n(m, 2));
          want = '${n(m, 1) ~/ g} : ${n(m, 2) ~/ g}';
        } else if ((m =
                RegExp(r'^Milk and water are mixed in the ratio (\d+) : (\d+)\. There are (\d+) cups of milk\.').firstMatch(p)) !=
            null) {
          expect(n(m!, 3) % n(m, 1), 0, reason: '$qid');
          want = '${n(m, 3) ~/ n(m, 1) * n(m, 2)}';
        } else if ((m = RegExp(r'^In the ratio (\d+) : (\d+), how many equal parts').firstMatch(p)) != null) {
          want = '${n(m!, 1) + n(m, 2)}';
        } else if ((m = RegExp(r'^A basket has (\d+) apples and (\d+) oranges\.').firstMatch(p)) != null) {
          want = '${n(m!, 1)}/${n(m, 1) + n(m, 2)}';
        } else if ((m = RegExp(r'^What kind of angle is (\d+)°\?$').firstMatch(p)) != null) {
          want = cls(n(m!, 1));
        } else if ((m = RegExp(r'^Which of these angles is (acute|a right angle|obtuse)\?$').firstMatch(p)) != null) {
          final kind = {
            'acute': 'Acute',
            'a right angle': 'Right',
            'obtuse': 'Obtuse'
          }[m!.group(1)]!;
          int deg(String s) => int.parse(s.replaceAll('°', ''));
          for (final o in List<String>.from(q['options'] as List)) {
            expect(cls(deg(o)) == kind, o == a, reason: '$qid $o');
          }
          want = a;
        } else if ((m = RegExp(r'One angle is (\d+)°\. What is the other').firstMatch(p)) != null) {
          want = '${180 - n(m!, 1)}°';
        } else if ((m = RegExp(r'^An angle of (\d+)° and another angle together make a right angle').firstMatch(p)) != null) {
          want = '${90 - n(m!, 1)}°';
        } else if ((m = RegExp(r'^A rectangle is (\d+) cm long and (\d+) cm wide\. What is its (perimeter|area)\?$').firstMatch(p)) != null) {
          want = m!.group(3) == 'perimeter'
              ? '${2 * (n(m, 1) + n(m, 2))} cm'
              : '${n(m, 1) * n(m, 2)} cm²';
        } else if ((m = RegExp(r'field (\d+) m long and (\d+) m wide\. How many metres of fence').firstMatch(p)) != null) {
          want = '${2 * (n(m!, 1) + n(m, 2))} m';
        } else if ((m = RegExp(r'^A square has sides of (\d+) cm\. What is its (perimeter|area)\?$').firstMatch(p)) != null) {
          want = m!.group(2) == 'perimeter'
              ? '${4 * n(m, 1)} cm'
              : '${n(m, 1) * n(m, 1)} cm²';
        } else if ((m = RegExp(r'^A rectangle has an area of (\d+) cm² and a length of (\d+) cm\.').firstMatch(p)) != null) {
          expect(n(m!, 1) % n(m, 2), 0, reason: '$qid');
          want = '${n(m, 1) ~/ n(m, 2)} cm';
        } else if ((m = RegExp(r'^Convert (\d+) (\w+) to (\w+)\.$').firstMatch(p)) != null) {
          final v = n(m!, 1);
          final from = m.group(2)!, to = m.group(3)!;
          if (factors.containsKey('$from>$to')) {
            want = '${v * factors['$from>$to']!} $to';
          } else {
            final f = factors['$to>$from']!;
            expect(v % f, 0, reason: '$qid');
            want = '${v ~/ f} $to';
          }
        } else if (p == 'Which is longer: 2 m or 150 cm?') {
          expect(2 * 100 > 150, isTrue);
          want = '2 m';
        } else if (RegExp(r'^[A-Za-z ]+: (\w+ \d+, )+\w+ \d+\. ').hasMatch(p)) {
          final colon = p.indexOf(': ');
          final dot = p.indexOf('. ', colon);
          final table = p.substring(colon + 2, dot);
          final question = p.substring(dot + 2);
          final d = <String, int>{
            for (final e in RegExp(r'(\w+) (\d+)').allMatches(table))
              e.group(1)!: int.parse(e.group(2)!)
          };
          final total = d.values.fold<int>(0, (s, v) => s + v);
          RegExpMatch? q2;
          if (question.contains(' in all?')) {
            want = '$total';
          } else if ((q2 = RegExp(r'^How many more for (\w+) than for (\w+)\?$')
                  .firstMatch(question)) !=
              null) {
            want = '${d[q2!.group(1)]! - d[q2.group(2)]!}';
          } else if ((q2 =
                  RegExp(r'^How many fewer for (\w+) than for (\w+)\?$')
                      .firstMatch(question)) !=
              null) {
            want = '${d[q2!.group(2)]! - d[q2.group(1)]!}';
          } else if ((q2 = RegExp(r'^How many for (\w+) and (\w+) together\?$')
                  .firstMatch(question)) !=
              null) {
            want = '${d[q2!.group(1)]! + d[q2.group(2)]!}';
          } else if (question == 'Which has the highest number?') {
            want = d.entries.reduce((x, y) => x.value >= y.value ? x : y).key;
          } else if (question == 'Which has the lowest number?') {
            want = d.entries.reduce((x, y) => x.value <= y.value ? x : y).key;
          }
        } else if ((m = RegExp(r'^\w+ buys (\d+) \w+ at ₹(\d+) each\. \w+ pays ₹(\d+)\. How much change').firstMatch(p)) != null) {
          want = '₹${n(m!, 3) - n(m, 1) * n(m, 2)}';
        } else if ((m = RegExp(r'^\w+ has ₹(\d+)\. \w+ buys a \w+ for ₹(\d+) and a \w+ for ₹(\d+)\. How much money is left').firstMatch(p)) != null) {
          want = '₹${n(m!, 1) - n(m, 2) - n(m, 3)}';
        } else if ((m = RegExp(r'^A hall has (\d+) rows of (\d+) seats\. (\d+) people').firstMatch(p)) != null) {
          want = '${n(m!, 1) * n(m, 2) - n(m, 3)}';
        } else if ((m = RegExp(r'^Ravi saves ₹(\d+) every week for (\d+) weeks\. Then he spends ₹(\d+)\.').firstMatch(p)) != null) {
          want = '₹${n(m!, 1) * n(m, 2) - n(m, 3)}';
        } else if ((m = RegExp(r'^A pack of (\d+) pens costs ₹(\d+)\. How much do (\d+) pens cost\?$').firstMatch(p)) != null) {
          expect(n(m!, 2) % n(m, 1), 0, reason: '$qid');
          want = '₹${n(m, 2) ~/ n(m, 1) * n(m, 3)}';
        } else if ((m = RegExp(r'^\w+ has (\d+) marbles\. \w+ wins (\d+) more and then shares all the marbles equally among (\d+) friends').firstMatch(p)) != null) {
          expect((n(m!, 1) + n(m, 2)) % n(m, 3), 0, reason: '$qid');
          want = '${(n(m, 1) + n(m, 2)) ~/ n(m, 3)}';
        }
        if (want != null) {
          expect(a, want, reason: '$qid: $p');
          checked++;
        }
      }
    }
    expect(checked, greaterThanOrEqualTo(80));
  });
}
