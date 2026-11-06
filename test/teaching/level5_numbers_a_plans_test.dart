import 'dart:convert';
import 'dart:io';

import 'package:aksharamala/src/teaching/teaching_plan.dart';
import 'package:flutter_test/flutter_test.dart';

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

String _frac(int a, int b) {
  final g = _gcd(a, b);
  return '${a ~/ g}/${b ~/ g}';
}

int _lcm(int a, int b) => a ~/ _gcd(a, b) * b;

/// A decimal text such as 12.5 as (digits as an integer, decimal places).
(int, int) _dec(String s) {
  final t = s.split('.');
  final f = t.length > 1 ? t[1] : '';
  return (int.parse(t[0] + f), f.length);
}

/// An integer scaled by 10^places, written as a decimal with no trailing zeros.
String _fmt(int v, int places) {
  final s = v.toString().padLeft(places + 1, '0');
  if (places == 0) return s;
  final w = s.substring(0, s.length - places);
  final f = s.substring(s.length - places).replaceAll(RegExp(r'0+$'), '');
  return f.isEmpty ? w : '$w.$f';
}

/// Evaluates + - x ÷ and brackets in the usual order, in exact integers.
/// Throws if a division is not exact.
class _Expr {
  _Expr(String s)
      : _t = RegExp(r'\d+|[()+\-x÷]').allMatches(s).map((m) => m[0]!).toList();
  final List<String> _t;
  int _p = 0;

  int run() {
    final v = _sum();
    if (_p != _t.length) throw StateError('unparsed');
    return v;
  }

  int _sum() {
    var v = _prod();
    while (_p < _t.length && (_t[_p] == '+' || _t[_p] == '-')) {
      final op = _t[_p++];
      final w = _prod();
      v = op == '+' ? v + w : v - w;
    }
    return v;
  }

  int _prod() {
    var v = _atom();
    while (_p < _t.length && (_t[_p] == 'x' || _t[_p] == '÷')) {
      final op = _t[_p++];
      final w = _atom();
      if (op == 'x') {
        v *= w;
      } else {
        if (v % w != 0) throw StateError('inexact division');
        v ~/= w;
      }
    }
    return v;
  }

  int _atom() {
    final x = _t[_p++];
    if (x == '(') {
      final v = _sum();
      _p++;
      return v;
    }
    return int.parse(x);
  }
}

void main() {
  final text =
      File('content/teaching/level5_numbers_a.json').readAsStringSync();
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
        [for (var i = 1; i <= 8; i++) 'numbers-l5-00$i']);
    expect(lib.plansById.length, 8);
    expect(lib.issues, isEmpty);
    for (final l in lessons) {
      expect(l['world'], 'numbers');
      expect(l['level'], 5);
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

  test('integer prompts re-derived', () {
    final cmp = RegExp(r'^Which sign fits: (-?\d+) \? (-?\d+)$');
    final small =
        RegExp(r'^Which is the smallest: (-?\d+), (-?\d+) or (-?\d+)\?$');
    final add = RegExp(r'^What is (-?\d+) ([+-]) (\d+)\?$');
    final temp = RegExp(
        r'^At night the temperature is (-?\d+) degrees\. It (rises|falls) by (\d+) degrees\. What is the temperature now\?$');
    final dist =
        RegExp(r'^How far is (-?\d+) from (-?\d+) on the number line\?$');
    var n = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      var m = cmp.firstMatch(p);
      if (m != null) {
        final a = int.parse(m[1]!), b = int.parse(m[2]!);
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
      m = small.firstMatch(p);
      if (m != null) {
        final xs = [for (var i = 1; i <= 3; i++) int.parse(m[i]!)]..sort();
        expect(q['answer'], '${xs.first}', reason: p);
        n++;
      }
      m = add.firstMatch(p);
      if (m != null) {
        final a = int.parse(m[1]!), b = int.parse(m[3]!);
        expect(q['answer'], '${m[2] == '+' ? a + b : a - b}', reason: p);
        n++;
      }
      m = temp.firstMatch(p);
      if (m != null) {
        final a = int.parse(m[1]!), d = int.parse(m[3]!);
        expect(q['answer'], '${m[2] == 'rises' ? a + d : a - d}', reason: p);
        n++;
      }
      m = dist.firstMatch(p);
      if (m != null) {
        expect(q['answer'], '${(int.parse(m[1]!) - int.parse(m[2]!)).abs()}',
            reason: p);
        n++;
      }
    }
    expect(n, 13);
  });

  test('order of operations re-derived with an independent evaluator', () {
    final ev = RegExp(r'^What is ([\d ()+\-x÷]+)\?$');
    final first = RegExp(r'^Which part do you work out first in (.+)\?$');
    var n = 0, k = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      var m = ev.firstMatch(p);
      if (m != null && RegExp(r'[x÷(]').hasMatch(m[1]!)) {
        final want = _Expr(m[1]!).run();
        expect(q['answer'], '$want', reason: p);
        // The tempting wrong answers really are different values.
        for (final o in (q['options'] as List).cast<String>()) {
          if (o != q['answer']) expect(int.parse(o) == want, isFalse);
        }
        n++;
      }
      m = first.firstMatch(p);
      if (m != null) {
        final s = m[1]!;
        final a = RegExp(r'^\((\d+ [+-] \d+)\)').firstMatch(s);
        final b = RegExp(r'^\d+ [+-] (\d+ [x÷] \d+)$').firstMatch(s);
        expect(a != null || b != null, isTrue, reason: s);
        expect(q['answer'], a != null ? a[1] : b![1], reason: p);
        k++;
      }
    }
    expect(n, greaterThanOrEqualTo(11));
    expect(k, greaterThanOrEqualTo(2));
  });

  test('unlike fractions re-derived in lowest terms', () {
    final op = RegExp(r'^What is (\d+)/(\d+) ([+-]) (\d+)/(\d+)\?$');
    final lcd = RegExp(
        r'^Which is the smallest common denominator of (\d+) and (\d+)\?$');
    final two = RegExp(r'(\d+)/(\d+)');
    var n = 0, w = 0, l = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      var m = op.firstMatch(p);
      if (m != null) {
        final a = int.parse(m[1]!), b = int.parse(m[2]!);
        final c = int.parse(m[4]!), d = int.parse(m[5]!);
        final top = m[3] == '+' ? a * d + c * b : a * d - c * b;
        expect(q['answer'], _frac(top, b * d), reason: p);
        n++;
      }
      m = lcd.firstMatch(p);
      if (m != null) {
        final b = int.parse(m[1]!), d = int.parse(m[2]!);
        expect(q['answer'], '${_lcm(b, d)}', reason: p);
        l++;
      }
      if (p.contains('altogether') || p.contains('is left?')) {
        final f = two.allMatches(p).toList();
        expect(f.length, 2, reason: p);
        final a = int.parse(f[0][1]!), b = int.parse(f[0][2]!);
        final c = int.parse(f[1][1]!), d = int.parse(f[1][2]!);
        final sub = p.contains('left');
        expect(sub != p.contains('altogether'), isTrue, reason: p);
        expect(q['answer'], _frac(sub ? a * d - c * b : a * d + c * b, b * d),
            reason: p);
        w++;
      }
    }
    expect(n, greaterThanOrEqualTo(9));
    expect(l, greaterThanOrEqualTo(2));
    expect(w, greaterThanOrEqualTo(2));
  });

  test('fraction multiplication re-derived in lowest terms', () {
    final mul = RegExp(r'^What is (\d+)/(\d+) x (\d+)/(\d+)\?$');
    final of = RegExp(r'^What is (\d+)/(\d+) of (\d+)\?$');
    final rec = RegExp(
        r'^A recipe needs (\d+)/(\d+) cup of sugar\. Meena makes (\d+)/(\d+) of the recipe\. How many cups of sugar does she need\?$');
    var n = 0, o = 0, r = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      var m = mul.firstMatch(p) ?? rec.firstMatch(p);
      if (m != null) {
        final v = [for (var i = 1; i <= 4; i++) int.parse(m[i]!)];
        expect(q['answer'], _frac(v[0] * v[2], v[1] * v[3]), reason: p);
        if (rec.hasMatch(p)) {
          r++;
        } else {
          n++;
        }
      }
      m = of.firstMatch(p);
      if (m != null) {
        final a = int.parse(m[1]!), b = int.parse(m[2]!), t = int.parse(m[3]!);
        expect(t % b, 0, reason: p);
        expect(q['answer'], '${t ~/ b * a}', reason: p);
        o++;
      }
    }
    expect(n, greaterThanOrEqualTo(5));
    expect(o, greaterThanOrEqualTo(4));
    expect(r, greaterThanOrEqualTo(3));
  });

  test('decimal multiplication re-derived from scaled integers', () {
    final mul = RegExp(r'^What is ([\d.]+) x ([\d.]+)\?$');
    final bottle = RegExp(
        r'^A bottle holds ([\d.]+) litres\. How many litres do (\d+) bottles hold\?$');
    final rope = RegExp(
        r'^A rope is ([\d.]+) metres long\. Ravi uses ([\d.]+) of it\. How many metres does he use\?$');
    final places = RegExp(
        r'^How many digits come after the point in the answer to ([\d.]+) x ([\d.]+)\?$');
    var n = 0, k = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      final m = mul.firstMatch(p) ?? bottle.firstMatch(p) ?? rope.firstMatch(p);
      if (m != null) {
        final (x, px) = _dec(m[1]!);
        final (y, py) = _dec(m[2]!);
        expect(q['answer'], _fmt(x * y, px + py), reason: p);
        // Every wrong option is a different value (compared as scaled ints).
        for (final o in (q['options'] as List).cast<String>()) {
          if (o == q['answer']) continue;
          final (z, pz) = _dec(o);
          final scale = px + py > pz ? px + py : pz;
          int up(int v, int pl) {
            var r = v;
            for (var i = pl; i < scale; i++) {
              r *= 10;
            }
            return r;
          }

          expect(up(z, pz) == up(x * y, px + py), isFalse, reason: '$p $o');
        }
        n++;
      }
      final pm = places.firstMatch(p);
      if (pm != null) {
        final (x, px) = _dec(pm[1]!);
        final (y, py) = _dec(pm[2]!);
        // The true product has exactly px+py digits after the point only
        // when its last digit is not 0.
        expect((x * y) % 10 != 0, isTrue, reason: p);
        expect(q['answer'], '${px + py}', reason: p);
        k++;
      }
    }
    expect(n, greaterThanOrEqualTo(11));
    expect(k, greaterThanOrEqualTo(2));
  });

  test('percent prompts re-derived', () {
    final of = RegExp(r'^What is (\d+)% of (\d+)\?$');
    final disc = RegExp(
        r'^A \w+ costs ₹(\d+)\. The discount is (\d+)%\. What is the sale price in rupees\?$');
    final what = RegExp(r'^What percent of (\d+) is (\d+)\?$');
    final girls = RegExp(
        r'^A school has (\d+) students\. (\d+)% of them are girls\. How many girls are there\?$');
    var n = 0, d = 0, w = 0, g = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      var m = of.firstMatch(p);
      if (m != null) {
        final pc = int.parse(m[1]!), t = int.parse(m[2]!);
        expect(t * pc % 100, 0, reason: p);
        expect(q['answer'], '${t * pc ~/ 100}', reason: p);
        n++;
      }
      m = disc.firstMatch(p);
      if (m != null) {
        final t = int.parse(m[1]!), pc = int.parse(m[2]!);
        expect(t * pc % 100, 0, reason: p);
        expect(q['answer'], '${t - t * pc ~/ 100}', reason: p);
        d++;
      }
      m = what.firstMatch(p);
      if (m != null) {
        final whole = int.parse(m[1]!), part = int.parse(m[2]!);
        expect(part * 100 % whole, 0, reason: p);
        expect(q['answer'], '${part * 100 ~/ whole}%', reason: p);
        w++;
      }
      m = girls.firstMatch(p);
      if (m != null) {
        final t = int.parse(m[1]!), pc = int.parse(m[2]!);
        expect(q['answer'], '${t * pc ~/ 100}', reason: p);
        g++;
      }
    }
    expect(n, greaterThanOrEqualTo(5));
    expect(d, greaterThanOrEqualTo(3));
    expect(w, greaterThanOrEqualTo(3));
    expect(g, greaterThanOrEqualTo(2));
  });

  test('ratio and proportion re-derived', () {
    final miss1 = RegExp(r'^Complete the ratio: (\d+) : (\d+) = (\d+) : \?$');
    final miss0 = RegExp(r'^Complete the ratio: (\d+) : (\d+) = \? : (\d+)$');
    final recipe = RegExp(
        r'^A recipe uses (\d+) cups of rice for (\d+) people\. How many cups of rice are needed for (\d+) people\?$');
    final price = RegExp(
        r'^(\d+) pens cost ₹(\d+)\. How much do (\d+) pens cost, in rupees\?$');
    final simp = RegExp(r'^Write (\d+) : (\d+) in simplest form\.$');
    final share = RegExp(
        r'^Share ₹(\d+) in the ratio (\d+) : (\d+)\. What is the (larger|smaller) share in rupees\?$');
    var a = 0, b = 0, c = 0, d = 0, e = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      var m = miss1.firstMatch(p);
      if (m != null) {
        final x = int.parse(m[1]!), y = int.parse(m[2]!), z = int.parse(m[3]!);
        final r = int.parse(q['answer'] as String);
        expect(x * r, y * z, reason: p);
        a++;
      }
      m = miss0.firstMatch(p);
      if (m != null) {
        final x = int.parse(m[1]!), y = int.parse(m[2]!), z = int.parse(m[3]!);
        final r = int.parse(q['answer'] as String);
        expect(r * y, x * z, reason: p);
        a++;
      }
      m = recipe.firstMatch(p);
      if (m != null) {
        final x = int.parse(m[1]!), y = int.parse(m[2]!), z = int.parse(m[3]!);
        expect(x * z % y, 0, reason: p);
        expect(q['answer'], '${x * z ~/ y}', reason: p);
        b++;
      }
      m = price.firstMatch(p);
      if (m != null) {
        final n = int.parse(m[1]!),
            cost = int.parse(m[2]!),
            k = int.parse(m[3]!);
        expect(cost % n, 0, reason: p);
        expect(q['answer'], '${cost ~/ n * k}', reason: p);
        c++;
      }
      m = simp.firstMatch(p);
      if (m != null) {
        final x = int.parse(m[1]!), y = int.parse(m[2]!);
        final g = _gcd(x, y);
        expect(q['answer'], '${x ~/ g} : ${y ~/ g}', reason: p);
        d++;
      }
      m = share.firstMatch(p);
      if (m != null) {
        final t = int.parse(m[1]!), x = int.parse(m[2]!), y = int.parse(m[3]!);
        expect(t % (x + y), 0, reason: p);
        final part = m[4] == 'larger' ? (x > y ? x : y) : (x < y ? x : y);
        expect(q['answer'], '${t ~/ (x + y) * part}', reason: p);
        e++;
      }
    }
    expect(a, greaterThanOrEqualTo(5));
    expect(b, greaterThanOrEqualTo(1));
    expect(c, greaterThanOrEqualTo(2));
    expect(d, greaterThanOrEqualTo(3));
    expect(e, greaterThanOrEqualTo(2));
  });

  test('variable and equation prompts re-derived', () {
    final one =
        RegExp(r'^If ([a-z]) = (\d+), what is (\d+)([a-z]) ([+-]) (\d+)\?$');
    final two = RegExp(
        r'^What is the value of (\d+)a \+ b when a = (\d+) and b = (\d+)\?$');
    final phrase =
        RegExp(r"^Which expression means '(\d+) (more|less) than x'\?$");
    final times = RegExp(r"^Which expression means '(\d+) times x'\?$");
    final share =
        RegExp(r"^Which expression means 'x shared equally among (\d+)'\?$");
    final pack = RegExp(
        r'^A pack has p pencils\. Which expression gives the number of pencils in (\d+) packs\?$');
    final add = RegExp(r'^Solve: ([a-z]) \+ (\d+) = (\d+)$');
    final sub = RegExp(r'^Solve: ([a-z]) - (\d+) = (\d+)$');
    final mul = RegExp(r'^Solve: (\d+)([a-z]) = (\d+)$');
    var n = 0, k = 0, s = 0;
    for (final q in allQuestions()) {
      final p = q['prompt'] as String;
      var m = one.firstMatch(p);
      if (m != null) {
        expect(m[1], m[4], reason: p);
        final v = int.parse(m[2]!), c = int.parse(m[3]!), t = int.parse(m[6]!);
        expect(q['answer'], '${m[5] == '+' ? c * v + t : c * v - t}',
            reason: p);
        n++;
      }
      m = two.firstMatch(p);
      if (m != null) {
        expect(q['answer'],
            '${int.parse(m[1]!) * int.parse(m[2]!) + int.parse(m[3]!)}',
            reason: p);
        n++;
      }
      m = phrase.firstMatch(p);
      if (m != null) {
        expect(q['answer'], m[2] == 'more' ? 'x + ${m[1]}' : 'x - ${m[1]}',
            reason: p);
        k++;
      }
      m = times.firstMatch(p);
      if (m != null) {
        expect(q['answer'], '${m[1]}x', reason: p);
        k++;
      }
      m = share.firstMatch(p);
      if (m != null) {
        expect(q['answer'], 'x ÷ ${m[1]}', reason: p);
        k++;
      }
      m = pack.firstMatch(p);
      if (m != null) {
        expect(q['answer'], '${m[1]}p', reason: p);
        k++;
      }
      m = add.firstMatch(p);
      if (m != null) {
        expect(q['answer'], '${int.parse(m[3]!) - int.parse(m[2]!)}',
            reason: p);
        s++;
      }
      m = sub.firstMatch(p);
      if (m != null) {
        expect(q['answer'], '${int.parse(m[3]!) + int.parse(m[2]!)}',
            reason: p);
        s++;
      }
      m = mul.firstMatch(p);
      if (m != null) {
        final c = int.parse(m[1]!), t = int.parse(m[3]!);
        expect(t % c, 0, reason: p);
        expect(q['answer'], '${t ~/ c}', reason: p);
        s++;
      }
    }
    expect(n, greaterThanOrEqualTo(3));
    expect(k, greaterThanOrEqualTo(6));
    expect(s, greaterThanOrEqualTo(4));
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
