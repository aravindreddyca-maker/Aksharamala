import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/batch/level6_numbers.dart';
import 'package:flutter_test/flutter_test.dart';

int _g(int a, int b) => b == 0 ? a.abs() : _g(b, a % b);
String _f(int n, int d) => '${n ~/ _g(n, d)}/${d ~/ _g(n, d)}';

/// A decimal text (at most two places) in hundredths.
int _h(String s) {
  final p = s.split('.');
  final f = (p.length > 1 ? p[1] : '').padRight(2, '0');
  return int.parse(p[0]) * 100 + int.parse(f.substring(0, 2));
}

/// v / 10^dp as a decimal text without trailing zeros.
String _dec(int v, int dp) {
  var p = 1;
  for (var i = 0; i < dp; i++) {
    p *= 10;
  }
  final frac =
      (v % p).toString().padLeft(dp, '0').replaceFirst(RegExp(r'0+$'), '');
  return frac.isEmpty ? '${v ~/ p}' : '${v ~/ p}.$frac';
}

List<int> _nums(String s) =>
    RegExp(r'\d+').allMatches(s).map((e) => int.parse(e.group(0)!)).toList();

/// Recomputes the answer straight from the prompt text, without using the
/// builder code.
String? recompute(int lesson, String p, List<String> options) {
  RegExpMatch? m;
  int n(int i) => int.parse(m!.group(i)!);
  RegExpMatch? re(String pattern) => m = RegExp(pattern).firstMatch(p);
  switch (lesson) {
    case 1:
      if (re(r'^What is (-?\d+) ([+x÷-]) \(?(-?\d+)\)?\?$') != null) {
        final a = n(1), b = n(3);
        switch (m!.group(2)) {
          case '+':
            return '${a + b}';
          case '-':
            return '${a - b}';
          case 'x':
            return '${a * b}';
          default:
            expect(a % b, 0);
            return '${a ~/ b}';
        }
      }
      if (re(r'^At night the temperature in \w+ was (-?\d+)°C\. By noon it (rose|fell) by (\d+)°C\. What is the temperature at noon\?$') !=
          null) {
        return '${m!.group(2) == 'rose' ? n(1) + n(3) : n(1) - n(3)}°C';
      }
    case 2:
      if (re(r'^What is (\d+)/(\d+) ([+÷-]) (\d+)/(\d+)\? Give the answer in lowest terms\.$') !=
          null) {
        final a = n(1), b = n(2), c = n(4), d = n(5);
        switch (m!.group(3)) {
          case '+':
            return _f(a * d + c * b, b * d);
          case '-':
            return _f(a * d - c * b, b * d);
          default:
            return _f(a * d, b * c);
        }
      }
      if (re(r'^Which is greater, (\d+)/(\d+) or (\d+)/(\d+)\?$') != null) {
        final x = n(1) * n(4), y = n(3) * n(2);
        return x > y
            ? '${n(1)}/${n(2)} is greater'
            : (x < y ? '${n(3)}/${n(4)} is greater' : 'They are equal');
      }
      if (re(r'^What is ([\d.]+) ([+x-]) ([\d.]+)\?$') != null) {
        final x = _h(m!.group(1)!), y = _h(m!.group(3)!);
        switch (m!.group(2)) {
          case 'x':
            return _dec(x * y, 4);
          case '+':
            return _dec(x + y, 2);
          default:
            return _dec(x - y, 2);
        }
      }
    case 3:
      if (re(r'^A bus covers (\d+) km in (\d+) hours\. What is its average speed\?$') !=
          null) {
        expect(n(1) % n(2), 0);
        return '${n(1) ~/ n(2)} km/h';
      }
      if (re(r'^A train runs at (\d+) km/h for (\d+) hours\. How far does it go\?$') !=
          null) {
        return '${n(1) * n(2)} km';
      }
      if (re(r'^(\d+) notebooks cost ₹(\d+)\. What is the cost of one notebook\?$') !=
          null) {
        expect(n(2) % n(1), 0);
        return '₹${n(2) ~/ n(1)}';
      }
      if (re(r'^Pack A has (\d+) pens for ₹(\d+)\. Pack B has (\d+) pens for ₹(\d+)\. Which pack is cheaper per pen\?$') !=
          null) {
        expect(n(2) % n(1), 0);
        expect(n(4) % n(3), 0);
        final u1 = n(2) ~/ n(1), u2 = n(4) ~/ n(3);
        expect(u1 == u2, isFalse);
        return u1 < u2 ? 'Pack A, ₹$u1 per pen' : 'Pack B, ₹$u2 per pen';
      }
      if (re(r'^The ratio of boys to girls in a class is (\d+) : (\d+)\. There are (\d+) students\. How many girls are there\?$') !=
          null) {
        expect(n(3) % (n(1) + n(2)), 0);
        return '${n(3) ~/ (n(1) + n(2)) * n(2)}';
      }
    case 4:
      if (re(r'^A \w+ marked at ₹(\d+) is sold at a (\d+)% discount\. What is (the discount in rupees|the selling price)\?$') !=
          null) {
        expect(n(1) * n(2) % 100, 0);
        final d = n(1) * n(2) ~/ 100;
        return m!.group(3) == 'the selling price' ? '₹${n(1) - d}' : '₹$d';
      }
      if (re(r'^Ravi buys a cycle for ₹(\d+) and sells it for ₹(\d+)\. What is his profit percent\?$') !=
          null) {
        expect((n(2) - n(1)) * 100 % n(1), 0);
        return '${(n(2) - n(1)) * 100 ~/ n(1)}%';
      }
      if (re(r'^A fan bought for ₹(\d+) is sold for ₹(\d+)\. What is the loss percent\?$') !=
          null) {
        expect((n(1) - n(2)) * 100 % n(1), 0);
        return '${(n(1) - n(2)) * 100 ~/ n(1)}%';
      }
      if (re(r'^A trader buys a table for ₹(\d+) and sells it at a (\d+)% profit\. What is the selling price\?$') !=
          null) {
        expect(n(1) * n(2) % 100, 0);
        return '₹${n(1) + n(1) * n(2) ~/ 100}';
      }
    case 5:
      if (re(r'^What is the simple interest on ₹(\d+) at (\d+)% per year for (\d+) years\?$') !=
          null) {
        expect(n(1) * n(2) * n(3) % 100, 0);
        return '₹${n(1) * n(2) * n(3) ~/ 100}';
      }
      if (re(r'^Asha deposits ₹(\d+) at (\d+)% simple interest per year for (\d+) years\.') !=
          null) {
        expect(n(1) * n(2) * n(3) % 100, 0);
        return '₹${n(1) + n(1) * n(2) * n(3) ~/ 100}';
      }
      if (re(r'^A sum of ₹(\d+) earns ₹(\d+) simple interest in (\d+) years\. What is the rate per year\?$') !=
          null) {
        expect(n(2) * 100 % (n(1) * n(3)), 0);
        return '${n(2) * 100 ~/ (n(1) * n(3))}%';
      }
      if (re(r'^₹(\d+) at (\d+)% simple interest per year earns ₹(\d+)\. For how many years was it kept\?$') !=
          null) {
        expect(n(3) * 100 % (n(1) * n(2)), 0);
        return '${n(3) * 100 ~/ (n(1) * n(2))} years';
      }
      if (re(r'^A sum earns ₹(\d+) simple interest at (\d+)% per year in (\d+) years\. What is the sum\?$') !=
          null) {
        expect(n(1) * 100 % (n(2) * n(3)), 0);
        return '₹${n(1) * 100 ~/ (n(2) * n(3))}';
      }
    case 6:
      if (re(r'^Simplify: (\d+)x \+ (\d+)x - (\d+)x$') != null) {
        return '${n(1) + n(2) - n(3)}x';
      }
      if (re(r'^Find the value of (\d+)a \+ (\d+) when a = (\d+)\.$') != null) {
        return '${n(1) * n(3) + n(2)}';
      }
      if (re(r'^Simplify: (\d+)x \+ (\d+)y \+ (\d+)x - (\d+)y$') != null) {
        return '${n(1) + n(3)}x + ${n(2) - n(4)}y';
      }
      if (re(r"^Ravi has x marbles\. Meena has (\d+) more than (\d+) times Ravi's marbles\.") !=
          null) {
        return '${n(2)}x + ${n(1)}';
      }
      if (re(r'^Find the value of (\d+)p - (\d+)q when p = (\d+) and q = (\d+)\.$') !=
          null) {
        return '${n(1) * n(3) - n(2) * n(4)}';
      }
    case 7:
      if (re(r'^Solve: (\d+)x \+ (\d+) = (\d+)$') != null) {
        expect((n(3) - n(2)) % n(1), 0);
        return 'x = ${(n(3) - n(2)) ~/ n(1)}';
      }
      if (re(r'^Solve: x/(\d+) - (\d+) = (\d+)$') != null) {
        return 'x = ${(n(3) + n(2)) * n(1)}';
      }
      if (re(r'^Solve: (\d+)x - (\d+) = (\d+)$') != null) {
        expect((n(3) + n(2)) % n(1), 0);
        return 'x = ${(n(3) + n(2)) ~/ n(1)}';
      }
      if (re(r'^Meena thinks of a number, multiplies it by (\d+) and adds (\d+)\. The result is (\d+)\. What is the number\?$') !=
          null) {
        expect((n(3) - n(2)) % n(1), 0);
        return '${(n(3) - n(2)) ~/ n(1)}';
      }
      if (re(r'^A taxi charges ₹(\d+) plus ₹(\d+) for each km\. A ride costs ₹(\d+)\. How many km was the ride\?$') !=
          null) {
        expect((n(3) - n(1)) % n(2), 0);
        return '${(n(3) - n(1)) ~/ n(2)} km';
      }
    case 8:
      if (re(r'^Two angles of a triangle are (\d+)° and (\d+)°\. What is the third angle\?$') !=
          null) {
        return '${180 - n(1) - n(2)}°';
      }
      if (re(r'^In an isosceles triangle the angle between the two equal sides is (\d+)°\. What is each of the other two angles\?$') !=
          null) {
        expect((180 - n(1)) % 2, 0);
        return '${(180 - n(1)) ~/ 2}°';
      }
      if (p.startsWith('Two straight lines cross. The angles opposite')) {
        return 'They are equal';
      }
      if (re(r'^The angles of a triangle are in the ratio (\d+) : (\d+) : (\d+)\. What is the largest angle\?$') !=
          null) {
        final t = n(1) + n(2) + n(3);
        expect(180 % t, 0);
        final big = [n(1), n(2), n(3)].reduce((a, b) => a > b ? a : b);
        return '${180 ~/ t * big}°';
      }
      if (re(r'^Two angles are complementary \(they add up to 90°\)\. One is (\d+)°\. What is the other\?$') !=
          null) {
        return '${90 - n(1)}°';
      }
    case 9:
      if (re(r'^A triangle has a base of (\d+) cm and a height of (\d+) cm\. What is its area\?$') !=
          null) {
        expect(n(1) * n(2) % 2, 0);
        return '${n(1) * n(2) ~/ 2} cm²';
      }
      if (re(r'^A parallelogram has a base of (\d+) cm and a height of (\d+) cm\. What is its area\?$') !=
          null) {
        return '${n(1) * n(2)} cm²';
      }
      if (re(r'^A circle has a radius of (\d+) cm\. Use 22/7 for π\. What is its area\?$') !=
          null) {
        expect(22 * n(1) * n(1) % 7, 0);
        return '${22 * n(1) * n(1) ~/ 7} cm²';
      }
      if (re(r'^A circular table top has a diameter of (\d+) cm\. Use 22/7 for π\. What is its area\?$') !=
          null) {
        expect(n(1) % 2, 0);
        final r = n(1) ~/ 2;
        expect(22 * r * r % 7, 0);
        return '${22 * r * r ~/ 7} cm²';
      }
      if (re(r'^A triangle has an area of (\d+) cm² and a base of (\d+) cm\. What is its height\?$') !=
          null) {
        expect(2 * n(1) % n(2), 0);
        return '${2 * n(1) ~/ n(2)} cm';
      }
    case 10:
      if (re(r'^The marks of five students are ([\d, ]+)\. What is the mean mark\?$') !=
          null) {
        final v = _nums(m!.group(1)!);
        final sum = v.fold<int>(0, (a, b) => a + b);
        expect(sum % v.length, 0);
        return '${sum ~/ v.length}';
      }
      if (re(r'^Find the median of ([\d, ]+)\.$') != null) {
        final v = _nums(m!.group(1)!)..sort();
        if (v.length.isOdd) return '${v[v.length ~/ 2]}';
        final x = v[v.length ~/ 2 - 1] + v[v.length ~/ 2];
        return x.isEven ? '${x ~/ 2}' : '${x ~/ 2}.5';
      }
      if (re(r'^The heights \(in cm\) of five plants are ([\d, ]+)\. What is the range\?$') !=
          null) {
        final v = _nums(m!.group(1)!)..sort();
        return '${v.last - v.first}';
      }
      if (re(r'^A bag has (\d+) red, (\d+) blue and (\d+) green marbles\. One marble is picked at random\. What is the probability that it is blue\?$') !=
          null) {
        return _f(n(2), n(1) + n(2) + n(3));
      }
      if (re(r'^A fair die is rolled\. What is the probability of getting a number greater than (\d)\?$') !=
          null) {
        return _f(6 - n(1), 6);
      }
  }
  return null;
}

bool _answerInPrompt(String answer, String prompt) =>
    RegExp('(?<![\\w.,/₹])${RegExp.escape(answer)}(?![\\w/]|[.,]\\d)')
        .hasMatch(prompt);

void main() {
  test('10 lessons with the right ids in order', () {
    expect(numbersLevel6Lessons, hasLength(10));
    for (var i = 0; i < 10; i++) {
      final lesson = numbersLevel6Lessons[i];
      expect(lesson.id, 'numbers-l6-${(i + 1).toString().padLeft(3, '0')}');
      expect(lesson.title, isNotEmpty);
      expect(lesson.ageBand, '10-12');
      expect(lesson.levelSet, {6});
    }
  });

  for (var i = 0; i < 10; i++) {
    final no = i + 1;
    test('lesson $no structure and answers', () {
      final lesson = numbersLevel6Lessons[i];
      expect(lesson.steps, hasLength(6));
      expect(lesson.steps.first.kind, StepKind.listen);
      expect(lesson.steps.first.prompt.trim(), isNotEmpty);
      expect(lesson.steps.first.prompt.length, lessThanOrEqualTo(130),
          reason: lesson.steps.first.prompt);
      final choices = lesson.steps.skip(1).toList();
      expect(choices.every((s) => s.kind == StepKind.choice), isTrue);
      expect(choices, hasLength(5));

      final prompts = <String>{};
      for (final s in choices) {
        expect(prompts.add(s.prompt), isTrue, reason: 'duplicate ${s.prompt}');
        expect(s.prompt.length, lessThanOrEqualTo(235), reason: s.prompt);
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
    for (final lesson in numbersLevel6Lessons) {
      for (final s in lesson.steps.where((s) => s.kind == StepKind.choice)) {
        counts.update(s.options.indexOf(s.answer!), (c) => c + 1,
            ifAbsent: () => 1);
      }
    }
    expect(counts.keys.toSet(), {0, 1, 2});
    for (final c in counts.values) {
      expect(c, greaterThan(8));
    }
  });
}
