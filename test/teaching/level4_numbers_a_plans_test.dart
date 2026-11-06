import 'dart:convert';
import 'dart:io';

import 'package:aksharamala/src/teaching/teaching_plan.dart';
import 'package:flutter_test/flutter_test.dart';

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

int _plain(String s) => int.parse(s.replaceAll(',', ''));

/// A decimal text such as 12.5 as an integer scaled by 10^3.
int _scaled(String s) {
  final t = s.replaceAll(',', '').split('.');
  final frac = t.length > 1 ? t[1] : '';
  return int.parse(t[0] + frac.padRight(3, '0'));
}

int _rupees(String whole, String paise) =>
    _plain(whole) * 100 + int.parse(paise);

String _rs(int p) {
  final r = (p ~/ 100)
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '₹$r.${(p % 100).toString().padLeft(2, '0')}';
}

String _commas(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

bool _prime(int n) {
  if (n < 2) return false;
  for (var k = 2; k * k <= n; k++) {
    if (n % k == 0) return false;
  }
  return true;
}

String _frac(int a, int b) {
  final g = _gcd(a, b);
  return '${a ~/ g}/${b ~/ g}';
}

void main() {
  final text =
      File('content/teaching/level4_numbers_a.json').readAsStringSync();
  final raw = jsonDecode(text) as Map<String, dynamic>;
  final lessons = (raw['lessons'] as List).cast<Map<String, dynamic>>();
  final lib = TeachingPlanLibrary.parse([text]);

  List<Map<String, dynamic>> qs(Map<String, dynamic> l, String k) =>
      (l[k] as List).cast<Map<String, dynamic>>();

  Iterable<Map<String, dynamic>> allQuestions() sync* {
    for (final l in lessons) {
      final rem = l['remediation'] as Map<String, dynamic>;
      yield* qs(l, 'guided');
      yield* qs(l, 'practice');
      yield* qs(l, 'check');
      yield* qs(rem, 'guided');
      yield* qs(rem, 'check');
    }
  }

  test('file header and the 8 lessons parse with zero issues', () {
    expect(raw['status'], 'draft_unverified');
    expect(lessons.map((l) => l['lesson_id']),
        [for (var i = 1; i <= 8; i++) 'numbers-l4-00$i']);
    expect(lib.plansById.length, 8);
    expect(lib.issues, isEmpty);
    for (final l in lessons) {
      expect(l['world'], 'numbers');
      expect(l['level'], 4);
      expect(l['locale'], 'en-IN');
      final m = l['mastery'] as Map<String, dynamic>;
      expect(m['check_total'], 3);
      expect(m['check_pass'], 2);
      expect(m['remediation_pass'], 2);
      expect(m['max_remediation_cycles'], 2);
      expect(m['after_limit'], 'offer_parent_support');
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
      expect((rem['explain'] as List).length, 3, reason: '$id');
      expect((rem['guided'] as List).length, 2, reason: '$id');
      expect((rem['check'] as List).length, 3, reason: '$id');
      for (final phase in ['guided', 'practice', 'check']) {
        for (final q in [
          ...qs(l, phase),
          ...(phase == 'guided'
              ? qs(rem, 'guided')
              : phase == 'check'
                  ? qs(rem, 'check')
                  : <Map<String, dynamic>>[])
        ]) {
          final opts = (q['options'] as List).cast<String>();
          expect(opts.length, 3);
          expect(opts.toSet().length, 3);
          expect(opts, contains(q['answer']), reason: q['id']);
          final wrong = opts.where((o) => o != q['answer']).toSet();
          final fb = (q['wrong_feedback'] as Map).cast<String, String>();
          expect(fb.keys.toSet(), wrong, reason: q['id']);
          // Specific feedback: every wrong option has its own message.
          expect(fb.values.toSet().length, 2, reason: q['id']);
          for (final v in fb.values) {
            expect(v.trim().length, greaterThan(15), reason: q['id']);
          }
          final hints = q['hints'] as List;
          if (phase == 'check') {
            expect(hints, isEmpty, reason: q['id']);
          } else {
            expect(hints.length, 2, reason: q['id']);
            expect((hints[0] as String).contains('${q['answer']}'), isFalse,
                reason: 'hint 1 leaks answer in ${q['id']}');
            expect(hints[0], isNot(hints[1]), reason: q['id']);
          }
        }
      }
    }
  });

  test('answer positions vary and prompts never repeat in a lesson', () {
    final positions = <int>{};
    for (final l in lessons) {
      final rem = l['remediation'] as Map<String, dynamic>;
      final prompts = <String>{};
      var n = 0;
      for (final q in [
        ...qs(l, 'guided'),
        ...qs(l, 'practice'),
        ...qs(l, 'check'),
        ...qs(rem, 'guided'),
        ...qs(rem, 'check'),
      ]) {
        positions.add((q['options'] as List).indexOf(q['answer']));
        prompts.add('${q['prompt']} ${q['options']}');
        n++;
      }
      expect(prompts.length, n, reason: '${l['lesson_id']}');
    }
    expect(positions, {0, 1, 2});
  });

  test('multiplication, division and money prompts re-derived independently',
      () {
    final mul = RegExp(r'^What is ([\d,]+) x ([\d,]+)\?$');
    final div = RegExp(r'^What is ([\d,]+) ÷ ([\d,]+)\?$');
    final money = RegExp(r'^What is (₹[\d,]+\.\d\d)( [+-] ₹[\d,]+\.\d\d)+\?$');
    final amount = RegExp(r'₹([\d,]+)\.(\d\d)');
    var nm = 0, nd = 0, nr = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      var m = mul.firstMatch(p);
      if (m != null) {
        expect(q['answer'], _commas(_plain(m[1]!) * _plain(m[2]!)), reason: p);
        nm++;
      }
      m = div.firstMatch(p);
      if (m != null) {
        final a = _plain(m[1]!), b = _plain(m[2]!);
        final want = a % b == 0
            ? _commas(a ~/ b)
            : '${_commas(a ~/ b)} r ${_commas(a % b)}';
        expect(q['answer'], want, reason: p);
        nd++;
      }
      if (money.hasMatch(p)) {
        final amts =
            amount.allMatches(p).map((x) => _rupees(x[1]!, x[2]!)).toList();
        final ops =
            RegExp(r' ([+-]) ₹').allMatches(p).map((x) => x[1]).toList();
        var v = amts[0];
        for (var i = 0; i < ops.length; i++) {
          v = ops[i] == '+' ? v + amts[i + 1] : v - amts[i + 1];
        }
        expect(q['answer'], _rs(v), reason: p);
        nr++;
      }
    }
    // Money word problems: operation chosen from the wording.
    var nw = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      if (p.startsWith('What is') || !p.contains('₹')) continue;
      final a = amount.allMatches(p).map((x) => _rupees(x[1]!, x[2]!)).toList();
      expect(a.length, 2, reason: p);
      final add = p.contains('total cost') || p.contains('altogether');
      final sub = p.contains('change') || p.contains('left?');
      expect(add != sub, isTrue, reason: p);
      expect(q['answer'], _rs(add ? a[0] + a[1] : a[0] - a[1]), reason: p);
      nw++;
    }
    expect(nw, greaterThanOrEqualTo(4));
    expect(nm, greaterThanOrEqualTo(8));
    expect(nd, greaterThanOrEqualTo(8));
    expect(nr, greaterThanOrEqualTo(8));
  });

  test('word problems re-derived', () {
    final pack = RegExp(r'^([\d,]+) \w+ are packed into boxes of (\d+)\. '
        r'How many (full boxes|\w+) are (there|left over)\?$');
    var n = 0;
    for (final q in allQuestions()) {
      final m = pack.firstMatch(q['prompt'] as String);
      if (m == null) continue;
      final a = _plain(m[1]!), b = int.parse(m[2]!);
      final want = m[4] == 'there' ? a ~/ b : a % b;
      expect(q['answer'], _commas(want), reason: q['prompt']);
      n++;
    }
    expect(n, greaterThanOrEqualTo(3));
    // Multiplication word problems: the answer is the product of the two
    // numbers in the question.
    var nw = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      if (!(p.contains('packet') ||
          p.contains('crayons') ||
          p.contains('passengers'))) {
        continue;
      }
      final nums =
          RegExp(r'[\d,]+').allMatches(p).map((x) => _plain(x[0]!)).toList();
      expect(nums.length, 2, reason: p);
      expect(q['answer'], _commas(nums[0] * nums[1]), reason: p);
      nw++;
    }
    expect(nw, greaterThanOrEqualTo(3));
  });

  test('fractions re-derived in lowest terms', () {
    final op = RegExp(r'^What is (\d+)/(\d+) ([+-]) (\d+)/(\d+)\?$');
    var n = 0;
    for (final q in allQuestions()) {
      final m = op.firstMatch(q['prompt'] as String);
      if (m == null) continue;
      final a = int.parse(m[1]!), b = int.parse(m[2]!);
      final c = int.parse(m[4]!), d = int.parse(m[5]!);
      final top = m[3] == '+' ? a * d + c * b : a * d - c * b;
      expect(q['answer'], _frac(top, b * d), reason: q['prompt']);
      n++;
    }
    expect(n, greaterThanOrEqualTo(8));

    // Fraction word problems: the two fractions in the prompt.
    final two = RegExp(r'(\d+)/(\d+)');
    var nw = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      if (!(p.contains('cake') || p.contains('jug'))) continue;
      final f = two.allMatches(p).toList();
      expect(f.length, 2, reason: p);
      final a = int.parse(f[0][1]!), b = int.parse(f[0][2]!);
      final c = int.parse(f[1][1]!), d = int.parse(f[1][2]!);
      final top = p.contains('left') ? a * d - c * b : a * d + c * b;
      expect(q['answer'], _frac(top, b * d), reason: p);
      nw++;
    }
    expect(nw, 2);

    final simp = RegExp(r'^Simplify (\d+)/(\d+) to lowest terms\.$');
    final eq = RegExp(r'^Which fraction is equal to (\d+)/(\d+)\?$');
    final top =
        RegExp(r'^Find the missing top number: (\d+)/(\d+) = \?/(\d+)$');
    final bot =
        RegExp(r'^Find the missing bottom number: (\d+)/(\d+) = (\d+)/\?$');
    final cmp = RegExp(r'^Which is greater: (\d+)/(\d+) or (\d+)/(\d+)\?$');
    var k = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      var m = simp.firstMatch(p);
      if (m != null) {
        expect(q['answer'], _frac(int.parse(m[1]!), int.parse(m[2]!)));
        k++;
      }
      m = eq.firstMatch(p);
      if (m != null) {
        final a = int.parse(m[1]!), b = int.parse(m[2]!);
        final r = (q['answer'] as String).split('/').map(int.parse).toList();
        expect(r[0] * b, a * r[1], reason: p);
        for (final o in (q['options'] as List)) {
          final x = (o as String).split('/').map(int.parse).toList();
          expect(x[0] * b == a * x[1], o == q['answer'], reason: '$p $o');
        }
        k++;
      }
      m = top.firstMatch(p);
      if (m != null) {
        final a = int.parse(m[1]!), b = int.parse(m[2]!), d = int.parse(m[3]!);
        expect(int.parse(q['answer'] as String) * b, a * d, reason: p);
        k++;
      }
      m = bot.firstMatch(p);
      if (m != null) {
        final a = int.parse(m[1]!), b = int.parse(m[2]!), n2 = int.parse(m[3]!);
        expect(int.parse(q['answer'] as String) * a, b * n2, reason: p);
        k++;
      }
      m = cmp.firstMatch(p);
      if (m != null) {
        final a = int.parse(m[1]!), b = int.parse(m[2]!);
        final c = int.parse(m[3]!), d = int.parse(m[4]!);
        expect(q['answer'], a * d > c * b ? '$a/$b' : '$c/$d', reason: p);
        k++;
      }
    }
    expect(k, greaterThanOrEqualTo(10));
  });

  test('place value, rounding and sign prompts re-derived', () {
    const place = {
      'ones': 0,
      'tens': 1,
      'hundreds': 2,
      'thousands': 3,
      'ten thousands': 4,
      'hundred thousands': 5,
      'millions': 6
    };
    const sing = {
      'ten': 10,
      'hundred': 100,
      'thousand': 1000,
      'ten thousand': 10000,
      'hundred thousand': 100000,
      'million': 1000000
    };
    final value = RegExp(r'^In ([\d,]+), what is the value of the (\d)\?$');
    final which = RegExp(r'^In ([\d,]+), which digit is in the (.+) place\?$');
    final round = RegExp(r'^Round ([\d,]+) to the nearest (.+)\.$');
    final sign = RegExp(r'^Which sign fits: ([\d,.]+) \? ([\d,.]+)$');
    final expand = RegExp(r'^Which number is ([\d, +]+)\?$');
    var n = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      var m = value.firstMatch(p);
      if (m != null && !m[1]!.contains('.')) {
        final s = m[1]!.replaceAll(',', '');
        final d = m[2]!;
        expect(s.indexOf(d), s.lastIndexOf(d), reason: p);
        final v = int.parse(d) *
            (BigInt.from(10).pow(s.length - 1 - s.indexOf(d)).toInt());
        expect(q['answer'], _commas(v), reason: p);
        n++;
      }
      m = which.firstMatch(p);
      if (m != null && place.containsKey(m[2])) {
        final s = m[1]!.replaceAll(',', '');
        expect(q['answer'], s[s.length - 1 - place[m[2]]!], reason: p);
        n++;
      }
      m = round.firstMatch(p);
      if (m != null) {
        final v = _plain(m[1]!), unit = sing[m[2]]!;
        expect(q['answer'], _commas((v + unit ~/ 2) ~/ unit * unit), reason: p);
        n++;
      }
      m = sign.firstMatch(p);
      if (m != null) {
        final a = _scaled(m[1]!), b = _scaled(m[2]!);
        expect(
            q['answer'],
            a > b
                ? '>'
                : a < b
                    ? '<'
                    : '=',
            reason: p);
        n++;
      }
      m = expand.firstMatch(p);
      if (m != null) {
        final sum =
            m[1]!.split(' + ').map(_plain).fold<int>(0, (x, y) => x + y);
        expect(q['answer'], _commas(sum), reason: p);
        n++;
      }
    }
    expect(n, greaterThanOrEqualTo(15));
  });

  test('factors, multiples and primes re-derived', () {
    final factor = RegExp(r'^Which of these is a factor of (\d+)\?$');
    final multiple = RegExp(r'^Which of these is a multiple of (\d+)\?$');
    final primeQ = RegExp(r'^Which of these is a prime number\?$');
    final count = RegExp(r'^How many factors does (\d+) have\?$');
    final nth =
        RegExp(r'^What is the (\d+)(?:st|nd|rd|th) multiple of (\d+)\?$');
    var n = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      final opts = (q['options'] as List).cast<String>();
      var m = factor.firstMatch(p);
      if (m != null) {
        final t = int.parse(m[1]!);
        for (final o in opts) {
          expect(t % int.parse(o) == 0, o == q['answer'], reason: '$p $o');
        }
        n++;
      }
      m = multiple.firstMatch(p);
      if (m != null) {
        final t = int.parse(m[1]!);
        for (final o in opts) {
          expect(int.parse(o) % t == 0, o == q['answer'], reason: '$p $o');
        }
        n++;
      }
      if (primeQ.hasMatch(p)) {
        for (final o in opts) {
          expect(_prime(int.parse(o)), o == q['answer'], reason: '$p $o');
        }
        n++;
      }
      m = count.firstMatch(p);
      if (m != null) {
        final t = int.parse(m[1]!);
        final c = [
          for (var k = 1; k <= t; k++)
            if (t % k == 0) k
        ].length;
        expect(q['answer'], '$c', reason: p);
        n++;
      }
      m = nth.firstMatch(p);
      if (m != null) {
        expect(q['answer'], '${int.parse(m[1]!) * int.parse(m[2]!)}',
            reason: p);
        n++;
      }
    }
    expect(n, greaterThanOrEqualTo(10));
  });

  test('decimal prompts re-derived', () {
    final round = RegExp(r'^Round (\d+\.\d+) to (\d) decimal places?\.$');
    final between =
        RegExp(r'^Which number lies between ([\d.]+) and ([\d.]+)\?$');
    final greatest =
        RegExp(r'^Which is the greatest: ([\d.]+), ([\d.]+) or ([\d.]+)\?$');
    final fracdec = RegExp(r'^Write (\d+)/(\d+) as a decimal\.$');
    final digit = RegExp(
        r'^In (\d+\.\d+), which digit is in the (tenths|hundredths|thousandths) place\?$');
    final val = RegExp(r'^In (\d+\.\d+), what is the value of the (\d)\?$');
    var n = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      var m = round.firstMatch(p);
      if (m != null) {
        final dp = int.parse(m[2]!);
        final v = _scaled(m[1]!); // scaled by 1000
        final unit = [1000, 100, 10, 1][dp]; // size of one rounding step
        final r = (v + unit ~/ 2) ~/ unit; // count of steps
        final s = r.toString().padLeft(dp + 1, '0');
        final want =
            '${s.substring(0, s.length - dp)}.${s.substring(s.length - dp)}';
        expect(q['answer'], want, reason: p);
        n++;
      }
      m = between.firstMatch(p);
      if (m != null) {
        final a = _scaled(m[1]!), b = _scaled(m[2]!);
        for (final o in (q['options'] as List)) {
          final x = _scaled(o as String);
          expect(x > a && x < b, o == q['answer'], reason: '$p $o');
        }
        n++;
      }
      m = greatest.firstMatch(p);
      if (m != null) {
        final xs = [m[1]!, m[2]!, m[3]!];
        xs.sort((a, b) => _scaled(b).compareTo(_scaled(a)));
        expect(q['answer'], xs.first, reason: p);
        n++;
      }
      m = fracdec.firstMatch(p);
      if (m != null) {
        final num = int.parse(m[1]!), den = int.parse(m[2]!);
        final dp = den.toString().length - 1;
        final s = num.toString().padLeft(dp + 1, '0');
        expect(q['answer'],
            '${s.substring(0, s.length - dp)}.${s.substring(s.length - dp)}',
            reason: p);
        n++;
      }
      m = digit.firstMatch(p);
      if (m != null) {
        final i = {'tenths': 1, 'hundredths': 2, 'thousandths': 3}[m[2]]!;
        expect(q['answer'], m[1]!.split('.')[1][i - 1], reason: p);
        n++;
      }
      m = val.firstMatch(p);
      if (m != null) {
        final frac = m[1]!.split('.')[1];
        final d = m[2]!;
        expect(frac.indexOf(d), frac.lastIndexOf(d), reason: p);
        final i = frac.indexOf(d) + 1;
        final want = '0.${'0' * (i - 1)}$d';
        expect(q['answer'], want, reason: p);
        n++;
      }
    }
    expect(n, greaterThanOrEqualTo(10));
  });

  test('every wrong option really differs from the answer in value', () {
    final frac = RegExp(r'^(\d+)/(\d+)$');
    for (final q in allQuestions()) {
      final ans = q['answer'] as String;
      final am = frac.firstMatch(ans);
      if (am == null) continue;
      final a = int.parse(am[1]!), b = int.parse(am[2]!);
      for (final o in (q['options'] as List).cast<String>()) {
        if (o == ans) continue;
        final om = frac.firstMatch(o);
        if (om == null) continue;
        expect(int.parse(om[1]!) * b == a * int.parse(om[2]!), isFalse,
            reason: '${q['id']}: $o equals $ans in value');
      }
    }
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
        expect(v['type'], 'none');
      }
    }
  });
}
