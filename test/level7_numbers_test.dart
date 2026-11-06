import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/batch/level7_numbers.dart';
import 'package:flutter_test/flutter_test.dart';

const _sups = '⁰¹²³⁴⁵⁶⁷⁸⁹';
const _supClass = '[⁰¹²³⁴⁵⁶⁷⁸⁹]';

int _g(int a, int b) => b == 0 ? a : _g(b, a % b);
int _i(String s) => int.parse(s.replaceAll(',', ''));
int _pw(int b, int n) => n == 0 ? 1 : b * _pw(b, n - 1);
int _unsup(String s) =>
    int.parse(s.split('').map((c) => '${_sups.indexOf(c)}').join());
String _sp(int n) =>
    n.toString().split('').map((c) => _sups[int.parse(c)]).join();
String _commaOf(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String _rup(int v) => '₹${_commaOf(v)}';
String _fr(int n, int d) {
  final g = _g(n, d);
  return d ~/ g == 1 ? '${n ~/ g}' : '${n ~/ g}/${d ~/ g}';
}

String _half(int twice) => twice.isEven ? '${twice ~/ 2}' : '${twice ~/ 2}.5';

/// Facts that are hand-set (language of geometry, proportion type, impossible).
const _handKeys = <String, String>{
  'Which pair of quantities is in inverse proportion?':
      'Speed and time taken for a fixed distance',
  'A quadrilateral has four equal sides and equal opposite angles, but no right angles. What is it called?':
      'Rhombus',
  'Which is always true for the diagonals of a parallelogram?':
      'They bisect each other',
  'A bag has only red balls. What is the probability of drawing a green ball?':
      '0',
};

/// Recomputes the answer straight from the prompt (or options).
String? recompute(int lesson, String p, List<String> options) {
  RegExpMatch? m;
  int n(int i) => int.parse(m!.group(i)!);
  RegExpMatch? re(String pattern) => m = RegExp(pattern).firstMatch(p);
  if (_handKeys.containsKey(p)) return _handKeys[p];
  switch (lesson) {
    case 1:
      if (re('^What is (\\d+)($_supClass+)\\?\$') != null) {
        return '${_pw(n(1), _unsup(m!.group(2)!))}';
      }
      if (re('^Write (\\d+)($_supClass+) × (\\d+)($_supClass+) as a single power of (\\d+)\\.\$') !=
          null) {
        return '${n(5)}${_sp(_unsup(m!.group(2)!) + _unsup(m!.group(4)!))}';
      }
      if (re('^Write (\\d+)($_supClass+) ÷ (\\d+)($_supClass+) as a single power of (\\d+)\\.\$') !=
          null) {
        return '${n(5)}${_sp(_unsup(m!.group(2)!) - _unsup(m!.group(4)!))}';
      }
      if (re('^Simplify \\((\\d+)($_supClass+)\\)($_supClass+) and write it as a power of (\\d+)\\.\$') !=
          null) {
        return '${n(4)}${_sp(_unsup(m!.group(2)!) * _unsup(m!.group(3)!))}';
      }
    case 2:
      if (re('^What is (\\d+)²\\?\$') != null) return '${n(1) * n(1)}';
      if (re('^What is (\\d+)³\\?\$') != null) return '${n(1) * n(1) * n(1)}';
      if (re(r'^What is the square root of (\d+)\?$') != null) {
        final r = [
          for (var i = 0; i <= n(1); i++)
            if (i * i == n(1)) i
        ];
        expect(r, hasLength(1));
        return '${r.single}';
      }
      if (re(r'^What is the cube root of (\d+)\?$') != null) {
        final r = [
          for (var i = 0; i <= n(1); i++)
            if (i * i * i == n(1)) i
        ];
        expect(r, hasLength(1));
        return '${r.single}';
      }
      if (p == 'Which number is a perfect square?') {
        final ok = options.where((o) {
          final v = int.parse(o);
          return [
            for (var i = 0; i <= v; i++)
              if (i * i == v) i
          ].isNotEmpty;
        }).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
    case 3:
      if (re(r'^Solve for x: (\d+)x ([+-]) (\d+) = (\d+)x \+ (\d+)$') != null) {
        final b = m!.group(2) == '+' ? n(3) : -n(3);
        expect((n(5) - b) % (n(1) - n(4)), 0);
        return 'x = ${(n(5) - b) ~/ (n(1) - n(4))}';
      }
      if (re(r'^Which value of x satisfies (\d+)x ([+-]) (\d+) = (\d+)x \+ (\d+)\?$') !=
          null) {
        final b = m!.group(2) == '+' ? n(3) : -n(3);
        final ok = options.where((o) {
          final t = RegExp(r'^x = (\d+)(?:/(\d+))?$').firstMatch(o)!;
          final num = int.parse(t.group(1)!);
          final den = t.group(2) == null ? 1 : int.parse(t.group(2)!);
          return (n(1) - n(4)) * num == (n(5) - b) * den;
        }).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
      if (re(r'^A number is multiplied by (\d+) and (\d+) is added\. The result equals the number multiplied by (\d+), plus (\d+)\. Find the number\.$') !=
          null) {
        expect((n(4) - n(2)) % (n(1) - n(3)), 0);
        return '${(n(4) - n(2)) ~/ (n(1) - n(3))}';
      }
    case 4:
      if (re(r'^Factorise (\d+)x ([+-]) (\d+)\.$') != null) {
        final sign = m!.group(2) == '+' ? 1 : -1;
        final ok = options.where((o) {
          final t = RegExp(r'^(\d+)\((\d*)x ([+-]) (\d+)\)$').firstMatch(o)!;
          final g = int.parse(t.group(1)!);
          final s2 = t.group(3) == '+' ? 1 : -1;
          return g * (t.group(2)!.isEmpty ? 1 : int.parse(t.group(2)!)) ==
                  n(1) &&
              s2 * g * int.parse(t.group(4)!) == sign * n(3);
        }).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
      if (re(r'^Factorise (\d*)x² - (\d+)\.$') != null) {
        final lead = m!.group(1)!.isEmpty ? 1 : n(1);
        final c = n(2);
        final ok = options.where((o) {
          final t = RegExp(r'^\((\d*)x ([+-]) (\d+)\)\((\d*)x ([+-]) (\d+)\)$')
              .firstMatch(o)!;
          final k = t.group(1)!.isEmpty ? 1 : int.parse(t.group(1)!);
          final l = t.group(4)!.isEmpty ? 1 : int.parse(t.group(4)!);
          final s = t.group(2) == '+' ? 1 : -1;
          final t2 = t.group(5) == '+' ? 1 : -1;
          final u = int.parse(t.group(3)!), v = int.parse(t.group(6)!);
          return k * l == lead &&
              k * t2 * v + l * s * u == 0 &&
              s * u * t2 * v == -c;
        }).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
      if (re(r'^What is the highest common factor of (\d+)a and (\d+)\?$') !=
          null) {
        return '${_g(n(1), n(2))}';
      }
    case 5:
      if (re(r'^(\d+) notebooks cost ₹(\d+)\. What is the cost of (\d+) notebooks\?$') !=
          null) {
        expect(n(2) % n(1), 0);
        return '₹${n(2) ~/ n(1) * n(3)}';
      }
      if (re(r'^(\d+) workers finish a job in (\d+) days\. If (\d+) workers') !=
          null) {
        expect(n(1) * n(2) % n(3), 0);
        return '${n(1) * n(2) ~/ n(3)} days';
      }
      if (re(r'^A car moves at a steady speed and covers (\d+) km in (\d+) hours\. How far will it go in (\d+) hours\?$') !=
          null) {
        expect(n(1) % n(2), 0);
        return '${n(1) ~/ n(2) * n(3)} km';
      }
      if (re(r'^A bus at (\d+) km/h takes (\d+) hours for a trip\. How long will it take at (\d+) km/h\?$') !=
          null) {
        expect(n(1) * n(2) % n(3), 0);
        return '${n(1) * n(2) ~/ n(3)} hours';
      }
    case 6:
      final f = RegExp(r'₹([\d,]+) for 2 years at (\d+)%').firstMatch(p);
      if (f != null) {
        final pr = _i(f.group(1)!), r = int.parse(f.group(2)!);
        final a = pr * (100 + r) * (100 + r);
        expect(a % 10000, 0);
        final amount = a ~/ 10000;
        final si = pr * r * 2 ~/ 100;
        if (p.startsWith('What is the difference')) {
          return _rup(amount - pr - si);
        }
        if (p.startsWith('Find the compound interest')) {
          return _rup(amount - pr);
        }
        if (p.startsWith('What is the amount')) return _rup(amount);
      }
    case 7:
      if (re(r'^What is the sum of the interior angles of a (\w+)\?$') !=
          null) {
        const sides = {'pentagon': 5, 'hexagon': 6, 'octagon': 8};
        return '${(sides[m!.group(1)]! - 2) * 180}°';
      }
      if (re(r'^Each exterior angle of a regular polygon with (\d+) sides') !=
          null) {
        expect(360 % n(1), 0);
        return '${360 ~/ n(1)}°';
      }
      if (re(r'^Three angles of a quadrilateral are (\d+)°, (\d+)° and (\d+)°\.') !=
          null) {
        return '${360 - n(1) - n(2) - n(3)}°';
      }
    case 8:
      if (re(r'^A cuboid is (\d+) cm long, (\d+) cm wide and (\d+) cm high\. What is its volume\?$') !=
          null) {
        return '${n(1) * n(2) * n(3)} cm³';
      }
      if (re(r'^A cuboid is (\d+) cm long, (\d+) cm wide and (\d+) cm high\. What is its total surface area\?$') !=
          null) {
        return '${2 * (n(1) * n(2) + n(2) * n(3) + n(3) * n(1))} cm²';
      }
      if (re(r'^A cylinder has radius (\d+) cm and height (\d+) cm\. Using π = 22/7, what is its volume\?$') !=
          null) {
        expect(n(1) % 7, 0);
        return '${22 * n(1) ~/ 7 * n(1) * n(2)} cm³';
      }
      if (re(r'^A cylinder has radius (\d+) cm and height (\d+) cm\. Using π = 22/7, what is its curved surface area\?$') !=
          null) {
        expect(n(1) % 7, 0);
        return '${2 * 22 * (n(1) ~/ 7) * n(2)} cm²';
      }
      if (re(r'^A tank is (\d+) cm long, (\d+) cm wide and (\d+) cm high\. How many litres') !=
          null) {
        expect(n(1) * n(2) * n(3) % 1000, 0);
        return '${n(1) * n(2) * n(3) ~/ 1000} L';
      }
    case 9:
      if (re(r'^The marks of five students are ([\d, and]+)\. What is the mean mark\?$') !=
          null) {
        final v = RegExp(r'\d+')
            .allMatches(m!.group(1)!)
            .map((e) => int.parse(e.group(0)!))
            .toList();
        final s = v.fold<int>(0, (a, b) => a + b);
        expect(v, hasLength(5));
        expect(s % 5, 0);
        return '${s ~/ 5}';
      }
      if (re(r'^The number of books read by four students are ([\d, and]+)\. What is the median\?$') !=
          null) {
        final v = RegExp(r'\d+')
            .allMatches(m!.group(1)!)
            .map((e) => int.parse(e.group(0)!))
            .toList()
          ..sort();
        expect(v, hasLength(4));
        return _half(v[1] + v[2]);
      }
      if (re(r'^A bar graph shows books read by four children: (.*)\. How many did the two lowest readers read together\?$') !=
          null) {
        final v = RegExp(r'[A-Z][a-z]+ (\d+)')
            .allMatches(m!.group(1)!)
            .map((e) => int.parse(e.group(1)!))
            .toList()
          ..sort();
        expect(v, hasLength(4));
        return '${v[0] + v[1]}';
      }
      if (re(r'^Tickets sold: (.*)\. What is the difference between the best day and the worst day\?$') !=
          null) {
        final v = RegExp(r'[A-Z][a-z]+ (\d+)')
            .allMatches(m!.group(1)!)
            .map((e) => int.parse(e.group(1)!))
            .toList()
          ..sort();
        return '${v.last - v.first}';
      }
      if (re(r'^\w+ scored (\d+), (\d+) and (\d+) in three tests\. What must she score in the fourth test to have an average of (\d+)\?$') !=
          null) {
        return '${n(4) * 4 - n(1) - n(2) - n(3)}';
      }
    case 10:
      if (re(r'^A bag has (\d+) red, (\d+) blue and (\d+) green balls\.') !=
          null) {
        return _fr(n(1), n(1) + n(2) + n(3));
      }
      if (re(r'^A fair die is rolled once\. What is the probability of getting a multiple of (\d+)\?$') !=
          null) {
        return _fr(
            [
              for (var i = 1; i <= 6; i++)
                if (i % n(1) == 0) i
            ].length,
            6);
      }
      if (re(r'^A card is drawn at random from cards numbered 1 to (\d+)\. What is the probability that the number is divisible by (\d+)\?$') !=
          null) {
        return _fr(
            [
              for (var i = 1; i <= n(1); i++)
                if (i % n(2) == 0) i
            ].length,
            n(1));
      }
      if (re(r'^The probability that it rains tomorrow is (\d+)/(\d+)\.') !=
          null) {
        return _fr(n(2) - n(1), n(2));
      }
  }
  return null;
}

bool _answerInPrompt(String answer, String prompt) =>
    RegExp('(?<![\\w.,/₹])${RegExp.escape(answer)}(?![\\w/]|[.,]\\d)')
        .hasMatch(prompt);

void main() {
  test('10 lessons with the right ids in order', () {
    expect(numbersLevel7Lessons, hasLength(10));
    for (var i = 0; i < 10; i++) {
      final lesson = numbersLevel7Lessons[i];
      expect(lesson.id, 'numbers-l7-${(i + 1).toString().padLeft(3, '0')}');
      expect(lesson.title, isNotEmpty);
      expect(lesson.ageBand, '10-12');
      expect(lesson.levelSet, {7});
    }
  });

  for (var i = 0; i < 10; i++) {
    final no = i + 1;
    test('lesson $no structure and answers', () {
      final lesson = numbersLevel7Lessons[i];
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
        expect(s.prompt.length, lessThanOrEqualTo(240), reason: s.prompt);
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
    for (final lesson in numbersLevel7Lessons) {
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
