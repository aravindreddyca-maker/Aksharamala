import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/batch/level8_numbers.dart';
import 'package:flutter_test/flutter_test.dart';

int _g(int a, int b) => b == 0 ? a : _g(b, a % b);
String _f(int n, int d) => '${n ~/ _g(n, d)}/${d ~/ _g(n, d)}';

const _sups = {'²': 2, '³': 3, '⁴': 4, '⁵': 5};

/// Parses "3x² + 5x - 2" into {power: coefficient}.
Map<int, int> _parsePoly(String s) {
  final out = <int, int>{};
  final terms = s.replaceAll(' ', '').replaceAll('-', '+-').split('+');
  for (final t in terms.where((e) => e.isNotEmpty)) {
    final xi = t.indexOf('x');
    if (xi < 0) {
      out.update(0, (v) => v + int.parse(t), ifAbsent: () => int.parse(t));
      continue;
    }
    final cs = t.substring(0, xi);
    final c = cs.isEmpty ? 1 : (cs == '-' ? -1 : int.parse(cs));
    final p = xi + 1 < t.length ? _sups[t[xi + 1]]! : 1;
    out.update(p, (v) => v + c, ifAbsent: () => c);
  }
  return out;
}

String _fmtPoly(Map<int, int> m) {
  final powers = m.keys.where((p) => m[p] != 0).toList()
    ..sort((a, b) => b.compareTo(a));
  const sup = {1: '', 2: '²', 3: '³', 4: '⁴', 5: '⁵'};
  final b = StringBuffer();
  for (var i = 0; i < powers.length; i++) {
    final p = powers[i], c = m[p]!;
    if (i == 0) {
      if (c < 0) b.write('-');
    } else {
      b.write(c < 0 ? ' - ' : ' + ');
    }
    final a = c.abs();
    if (p == 0) {
      b.write('$a');
    } else {
      b.write('${a == 1 ? '' : a}x${sup[p]}');
    }
  }
  return b.toString();
}

Map<int, int> _combine(Map<int, int> a, Map<int, int> b, int sign) {
  final out = Map<int, int>.of(a);
  b.forEach(
      (p, c) => out.update(p, (v) => v + sign * c, ifAbsent: () => sign * c));
  return out;
}

List<int> _ints(String s) =>
    RegExp(r'\d+').allMatches(s).map((m) => int.parse(m.group(0)!)).toList();

String _halfOf(int twice) => twice.isEven ? '${twice ~/ 2}' : '${twice ~/ 2}.5';

int _isqrt(int n) {
  var r = 0;
  while ((r + 1) * (r + 1) <= n) {
    r++;
  }
  return r;
}

bool _perfect(int n) => _isqrt(n) * _isqrt(n) == n;

/// Hand-set items, typed independently of the lesson file.
const _hand = <String, String>{
  'Every integer is also a ____ number.': 'rational',
  'How many solutions does a linear equation in two variables have?':
      'Infinitely many',
  'Which is a linear equation in two variables?': 'x + 2y = 5',
  'A point has coordinates (6, 0). On which line does it lie?': 'On the x-axis',
  'Triangles ABC and PQR have AB = PQ, BC = QR and CA = RP. Which rule shows they are congruent?':
      'SSS',
  'In triangles ABC and DEF, AB = DE, AC = DF and angle A = angle D. Which rule applies?':
      'SAS',
  'In triangles ABC and PQR, angle B = angle Q, BC = QR and angle C = angle R. Which rule applies?':
      'ASA',
  'Which condition does NOT prove two triangles congruent?': 'AAA',
  'What is the probability of an event that cannot happen?': '0',
};

/// Recomputes the answer from the prompt text (and the options, for
/// "pick the one that ..." items) without using the builder code.
String? recompute(int lesson, String p, List<String> options) {
  if (_hand.containsKey(p)) return _hand[p];
  RegExpMatch? m;
  int n(int i) => int.parse(m!.group(i)!);
  RegExpMatch? re(String pattern) => m = RegExp(pattern).firstMatch(p);
  switch (lesson) {
    case 1:
      if (p == 'Which of these is an irrational number?') {
        final ok = options.where((o) {
          if (o.startsWith('√')) return !_perfect(int.parse(o.substring(1)));
          return false; // decimals and fractions here are all rational
        }).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
      if (p == 'Which of these is a rational number?') {
        final ok = options
            .where(
                (o) => o.startsWith('√') && _perfect(int.parse(o.substring(1))))
            .toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
      if (re(r'^Between which two consecutive whole numbers does √(\d+) lie\?$') !=
          null) {
        return '${_isqrt(n(1))} and ${_isqrt(n(1)) + 1}';
      }
      if (p == 'Which fraction has a terminating decimal expansion?') {
        final ok = options.where((o) {
          final t = o.split('/').map(int.parse).toList();
          var d = t[1] ~/ _g(t[0], t[1]);
          while (d % 2 == 0) {
            d ~/= 2;
          }
          while (d % 5 == 0) {
            d ~/= 5;
          }
          return d == 1;
        }).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
    case 2:
      if (re(r'^What is the degree of the polynomial (.+)\?$') != null) {
        final poly = _parsePoly(m!.group(1)!);
        return '${poly.keys.where((k) => poly[k] != 0).reduce((a, b) => a > b ? a : b)}';
      }
      if (re(r'^If p\(x\) = (.+), find p\((\d+)\)\.$') != null) {
        final poly = _parsePoly(m!.group(1)!);
        final k = n(2);
        var v = 0;
        poly.forEach((pw, c) {
          var t = c;
          for (var i = 0; i < pw; i++) {
            t *= k;
          }
          v += t;
        });
        return '$v';
      }
      if (re(r'^Add \((.+)\) and \((.+)\)\.$') != null) {
        return _fmtPoly(
            _combine(_parsePoly(m!.group(1)!), _parsePoly(m!.group(2)!), 1));
      }
      if (re(r'^Subtract \((.+)\) from \((.+)\)\.$') != null) {
        return _fmtPoly(
            _combine(_parsePoly(m!.group(2)!), _parsePoly(m!.group(1)!), -1));
      }
      if (re(r'^Multiply \(x ([+-]) (\d+)\)\(x ([+-]) (\d+)\)\.$') != null) {
        final a = m!.group(1) == '-' ? -n(2) : n(2);
        final b = m!.group(3) == '-' ? -n(4) : n(4);
        return _fmtPoly({2: 1, 1: a + b, 0: a * b});
      }
    case 3:
      if (re(r'^Which pair \(x, y\) is a solution of (\d+)x \+ (\d+)y = (\d+)\?$') !=
          null) {
        final a = n(1), b = n(2), c = n(3);
        final ok = options.where((o) {
          final t = _ints(o);
          return a * t[0] + b * t[1] == c;
        }).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
      if (re(r'^In (\d+)x \+ (\d+)y = (\d+), if x = (\d+), what is y\?$') !=
          null) {
        expect((n(3) - n(1) * n(4)) % n(2), 0);
        return '${(n(3) - n(1) * n(4)) ~/ n(2)}';
      }
      if (re(r'^At which point does the line (\d+)x \+ (\d+)y = (\d+) cut the x-axis\?$') !=
          null) {
        expect(n(3) % n(1), 0);
        return '(${n(3) ~/ n(1)}, 0)';
      }
    case 4:
      if (re(r'\((-?\d+), (-?\d+)\)') != null &&
          (p.startsWith('In which quadrant') ||
              p.contains('lies in which quadrant'))) {
        final x = n(1), y = n(2);
        return x > 0 && y > 0
            ? 'First quadrant'
            : (x < 0 && y > 0
                ? 'Second quadrant'
                : (x < 0 && y < 0 ? 'Third quadrant' : 'Fourth quadrant'));
      }
      if (re(r'^What is the distance of the point \((-?\d+), (-?\d+)\) from the x-axis\?$') !=
          null) {
        return '${n(2).abs()} units';
      }
      if (re(r'^Find the distance between the points \((-?\d+), 0\) and \((-?\d+), 0\)\.$') !=
          null) {
        return '${(n(2) - n(1)).abs()} units';
      }
    case 5:
      if (re(r'^A right triangle has legs (\d+) cm and (\d+) cm\. What is its hypotenuse\?$') !=
          null) {
        final s = n(1) * n(1) + n(2) * n(2);
        expect(_perfect(s), isTrue);
        return '${_isqrt(s)} cm';
      }
      if (re(r'^The hypotenuse of a right triangle is (\d+) cm and one leg is (\d+) cm\. Find the other leg\.$') !=
          null) {
        final s = n(1) * n(1) - n(2) * n(2);
        expect(_perfect(s), isTrue);
        return '${_isqrt(s)} cm';
      }
      if (re(r'^Is a triangle with sides (\d+) cm, (\d+) cm and (\d+) cm right-angled\?$') !=
          null) {
        final s = [n(1), n(2), n(3)]..sort();
        return s[0] * s[0] + s[1] * s[1] == s[2] * s[2] ? 'Yes' : 'No';
      }
      if (re(r'^A (\d+) m ladder leans on a wall with its foot (\d+) m from the wall\.') !=
          null) {
        final s = n(1) * n(1) - n(2) * n(2);
        expect(_perfect(s), isTrue);
        return '${_isqrt(s)} m';
      }
    case 6:
      if (re(r'^Triangle ABC is congruent to triangle PQR\. In ABC, ∠A = (\d+)° and ∠B = (\d+)°\. What is ∠R\?$') !=
          null) {
        return '${180 - n(1) - n(2)}°';
      }
    case 7:
      if (re(r'^Find the (mean|median) of the marks ([\d, ]+)\.$') != null) {
        final d = _ints(m!.group(2)!);
        final s = d.fold<int>(0, (a, b) => a + b);
        if (m!.group(1) == 'mean') {
          expect(s % d.length, 0);
          return '${s ~/ d.length} marks';
        }
        final sorted = List<int>.of(d)..sort();
        expect(d.length.isOdd, isTrue);
        return '${sorted[d.length ~/ 2]} marks';
      }
      if (re(r'^Runs scored in (\d+) matches: ([\d, ]+)\. What is the mode\?$') !=
          null) {
        final d = _ints(m!.group(2)!);
        expect(d.length, n(1));
        final counts = <int, int>{};
        for (final v in d) {
          counts[v] = (counts[v] ?? 0) + 1;
        }
        final best = counts.values.reduce((a, b) => a > b ? a : b);
        final modes = counts.keys.where((k) => counts[k] == best).toList();
        expect(modes, hasLength(1));
        return '${modes.single} runs';
      }
      if (re(r'^A frequency table has (\d+) values with frequencies ([\d, ]+) and (\d+)\. How many observations are there\?$') !=
          null) {
        final f = [..._ints(m!.group(2)!), n(3)];
        expect(f.length, n(1));
        return '${f.fold<int>(0, (a, b) => a + b)}';
      }
      if (re(r'^The marks of (\d+) students are ([\d, ]+) and (\d+)\. What is the median\?$') !=
          null) {
        final d = [..._ints(m!.group(2)!), n(3)]..sort();
        expect(d.length, n(1));
        expect(d.length.isEven, isTrue);
        return '${_halfOf(d[d.length ~/ 2 - 1] + d[d.length ~/ 2])} marks';
      }
    case 8:
      if (re(r'^Using \(a \+ b\)² = a² \+ 2ab \+ b², find (\d+)²\.$') != null) {
        return '${n(1) * n(1)}';
      }
      if (re(r'^Using \(a - b\)² = a² - 2ab \+ b², find (\d+)²\.$') != null) {
        return '${n(1) * n(1)}';
      }
      if (re(r'^Using a² - b² = \(a \+ b\)\(a - b\), find (\d+)² - (\d+)²\.$') !=
          null) {
        return '${(n(1) + n(2)) * (n(1) - n(2))}';
      }
      if (re(r'^If a \+ b = (\d+) and ab = (\d+), what is a² \+ b²\?$') !=
          null) {
        return '${n(1) * n(1) - 2 * n(2)}';
      }
      if (re(r'^Expand \(x - (\d+)\)² using an identity\.$') != null) {
        return _fmtPoly({2: 1, 1: -2 * n(1), 0: n(1) * n(1)});
      }
    case 9:
      // pi = 22/7 as an exact fraction: value = 22 * k / (7 * d).
      String exact(int num, int den) {
        expect(num % den, 0, reason: p);
        return '${num ~/ den}';
      }
      if (re(r'^A cone has base radius (\d+) cm and height (\d+) cm\. What is its volume\?') !=
          null) {
        return '${exact(22 * n(1) * n(1) * n(2), 21)} cm³';
      }
      if (re(r'^A sphere has radius (\d+) cm\. What is its surface area\?') !=
          null) {
        return '${exact(4 * 22 * n(1) * n(1), 7)} cm²';
      }
      if (re(r'^A sphere has radius (\d+) cm\. What is its volume\?') != null) {
        return '${exact(4 * 22 * n(1) * n(1) * n(1), 21)} cm³';
      }
      if (re(r'^A cone has base radius (\d+) cm and slant height (\d+) cm\. What is its curved surface area\?') !=
          null) {
        return '${exact(22 * n(1) * n(2), 7)} cm²';
      }
    case 10:
      if (re(r'^A bag has (\d+) red, (\d+) blue and (\d+) green balls\.') !=
          null) {
        return _f(n(1), n(1) + n(2) + n(3));
      }
      if (p ==
          'A fair die is rolled. What is the probability of getting a prime number?') {
        final primes = [
          for (var v = 1; v <= 6; v++)
            if (v > 1 &&
                [for (var d = 2; d < v; d++) v % d].every((r) => r != 0))
              v
        ];
        return _f(primes.length, 6);
      }
      if (re(r'^A coin was tossed (\d+) times and showed heads (\d+) times\.') !=
          null) {
        return _f(n(2), n(1));
      }
      if (re(r'^A bag has (\d+) red and (\d+) white balls\. What is the probability of NOT drawing a red ball\?$') !=
          null) {
        return _f(n(2), n(1) + n(2));
      }
  }
  return null;
}

bool _answerInPrompt(String answer, String prompt) =>
    RegExp('(?<![\\w.,/₹])${RegExp.escape(answer)}(?![\\w/]|[.,]\\d)')
        .hasMatch(prompt);

void main() {
  test('10 lessons with the right ids in order', () {
    expect(numbersLevel8Lessons, hasLength(10));
    for (var i = 0; i < 10; i++) {
      final lesson = numbersLevel8Lessons[i];
      expect(lesson.id, 'numbers-l8-${(i + 1).toString().padLeft(3, '0')}');
      expect(lesson.title, isNotEmpty);
      expect(lesson.ageBand, '10-12');
      expect(lesson.levelSet, {8});
    }
  });

  for (var i = 0; i < 10; i++) {
    final no = i + 1;
    test('lesson $no structure and answers', () {
      final lesson = numbersLevel8Lessons[i];
      expect(lesson.steps, hasLength(6));
      expect(lesson.steps.first.kind, StepKind.listen);
      expect(lesson.steps.first.prompt.length, lessThanOrEqualTo(130),
          reason: lesson.steps.first.prompt);
      final choices = lesson.steps.skip(1).toList();
      expect(choices.every((s) => s.kind == StepKind.choice), isTrue);
      expect(choices, hasLength(5));

      final prompts = <String>{};
      for (final s in choices) {
        expect(prompts.add(s.prompt), isTrue, reason: 'duplicate ${s.prompt}');
        expect(s.prompt.length, lessThanOrEqualTo(250), reason: s.prompt);
        expect(s.options, hasLength(3), reason: s.prompt);
        expect(s.options.toSet(), hasLength(3), reason: s.prompt);
        expect(s.options.every((o) => o.trim().isNotEmpty && o.length <= 45),
            isTrue,
            reason: s.prompt);
        expect(s.options.where((o) => o == s.answer), hasLength(1),
            reason: s.prompt);
        expect(_answerInPrompt(s.answer!, s.prompt), isFalse,
            reason: 'answer inside prompt: ${s.prompt}');
        final expected = recompute(no, s.prompt, s.options);
        expect(expected, isNotNull, reason: 'cannot parse: ${s.prompt}');
        expect(s.answer, expected, reason: s.prompt);
      }
      final positions =
          choices.map((s) => s.options.indexOf(s.answer!)).toSet();
      expect(positions.length, greaterThan(1),
          reason: 'answer position never varies');
    });
  }

  test('answer position varies across the whole set', () {
    final counts = <int, int>{};
    for (final lesson in numbersLevel8Lessons) {
      for (final s in lesson.steps.where((s) => s.kind == StepKind.choice)) {
        counts.update(s.options.indexOf(s.answer!), (c) => c + 1,
            ifAbsent: () => 1);
      }
    }
    expect(counts.keys.toSet(), {0, 1, 2});
    for (final c in counts.values) {
      expect(c, greaterThan(10));
    }
  });
}
