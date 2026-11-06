import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/batch/level5_numbers.dart';
import 'package:flutter_test/flutter_test.dart';

int _g(int a, int b) => b == 0 ? a : _g(b, a % b);
String _f(int n, int d) => '${n ~/ _g(n, d)}/${d ~/ _g(n, d)}';
int _pow10(int k) => k == 0 ? 1 : 10 * _pow10(k - 1);

/// v / 10^dp with trailing zeros trimmed.
String _scaled(int v, int dp) {
  if (dp == 0) return '$v';
  final p = _pow10(dp);
  final frac =
      (v % p).toString().padLeft(dp, '0').replaceFirst(RegExp(r'0+$'), '');
  return frac.isEmpty ? '${v ~/ p}' : '${v ~/ p}.$frac';
}

/// Evaluates "6 + 4 x 3" style text with brackets, x, ÷, + and -.
int _eval(String s) {
  final t =
      RegExp(r'\d+|[()+\-x÷]').allMatches(s).map((m) => m.group(0)!).toList();
  var i = 0;
  late int Function() expr;
  late int Function() term;
  late int Function() factor;
  factor = () {
    if (t[i] == '(') {
      i++;
      final v = expr();
      i++;
      return v;
    }
    return int.parse(t[i++]);
  };
  term = () {
    var v = factor();
    while (i < t.length && (t[i] == 'x' || t[i] == '÷')) {
      final op = t[i++];
      final r = factor();
      if (op == 'x') {
        v *= r;
      } else {
        expect(v % r, 0, reason: 'inexact division in $s');
        v ~/= r;
      }
    }
    return v;
  };
  expr = () {
    var v = term();
    while (i < t.length && (t[i] == '+' || t[i] == '-')) {
      final op = t[i++];
      final r = term();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  };
  return expr();
}

/// Hand-written items: prompt -> answer.
const _hand = <String, String>{
  'A four-sided shape has two pairs of parallel sides and four right angles. '
      'Its sides are not all equal. What is it?': 'Rectangle',
  'Which shape has exactly one pair of parallel sides?': 'Trapezium',
  'A fair die shows the numbers 1 to 6. You roll it. Rolling a number less '
      'than 7 is...': 'Certain',
  'A bag holds only green marbles. You pick one without looking. Picking a '
      'yellow marble is...': 'Impossible',
  'You toss a fair coin. Landing on heads is...': 'Even chance',
};

/// Recomputes the answer straight from the prompt text (and, for "pick the
/// one that ..." items, from the options), without using the builder code.
String? recompute(int lesson, String p, List<String> options) {
  RegExpMatch? m;
  int n(int i) => int.parse(m!.group(i)!);
  RegExpMatch? re(String pattern) => m = RegExp(pattern).firstMatch(p);
  switch (lesson) {
    case 1:
      if (re(r'^Which sign fits\? (-?\d+) \? (-?\d+)$') != null) {
        return n(1) > n(2) ? '>' : (n(1) < n(2) ? '<' : '=');
      }
      if (p == 'Which of these numbers is the smallest?') {
        final v = options.map(int.parse).toList()..sort();
        return '${v.first}';
      }
      if (re(r'^At night the temperature is (-?\d+)°C\. By noon it rises by (\d+) degrees\.') !=
          null) {
        return '${n(1) + n(2)}°C';
      }
      if (re(r'^What is (-?\d+) \+ (\d+)\?$') != null) return '${n(1) + n(2)}';
      if (re(r'^How many steps is it from (-?\d+) to (\d+) on the number line\?$') !=
          null) {
        return '${n(2) - n(1)}';
      }
    case 2:
      if (re(r'^What is ([\d ()+\-x÷]+)\?$') != null) {
        return '${_eval(m!.group(1)!)}';
      }
    case 3:
      if (re(r'^What is (\d+)/(\d+) ([+-]) (\d+)/(\d+)\? Give the answer in lowest terms\.$') !=
          null) {
        final l = n(2) * n(5) ~/ _g(n(2), n(5));
        final x = n(1) * (l ~/ n(2)), y = n(4) * (l ~/ n(5));
        return _f(m!.group(3) == '+' ? x + y : x - y, l);
      }
    case 4:
      if (re(r'^What is (\d+)/(\d+) (?:of|x) (\d+)/(\d+)\? Give the answer in lowest terms\.$') !=
          null) {
        return _f(n(1) * n(3), n(2) * n(4));
      }
      if (re(r'^A recipe needs (\d+)/(\d+) cup of sugar\. Meera makes (\d+)/(\d+) of the recipe\.') !=
          null) {
        return _f(n(1) * n(3), n(2) * n(4));
      }
      if (re(r'^What is (\d+)/(\d+) of (\d+)\?$') != null) {
        expect(n(3) % n(2), 0);
        return '${n(3) * n(1) ~/ n(2)}';
      }
    case 5:
      final nums = RegExp(r'\d+(?:\.\d+)?')
          .allMatches(p)
          .map((e) => e.group(0)!)
          .toList();
      if (re(r'^What is ([\d.]+) x ([\d.]+)\?$') != null ||
          re(r'^A car uses ([\d.]+) litres of petrol per km\. How many litres does it use for ([\d.]+) km\?$') !=
              null) {
        final a = m!.group(1)!, b = m!.group(2)!;
        int dp(String s) => s.contains('.') ? s.split('.')[1].length : 0;
        final prod =
            int.parse(a.replaceAll('.', '')) * int.parse(b.replaceAll('.', ''));
        expect(nums, hasLength(2));
        return _scaled(prod, dp(a) + dp(b));
      }
    case 6:
      if (re(r'^What is (\d+)% of (\d+)\?$') != null ||
          re(r'^In a school of (\d+) students, (\d+)% are girls\.') != null) {
        final isGirls = p.startsWith('In a school');
        final pct = isGirls ? n(2) : n(1), q = isGirls ? n(1) : n(2);
        expect(pct * q % 100, 0);
        return '${pct * q ~/ 100}';
      }
      if (re(r'^A shirt costs ₹(\d+)\. The shop gives (\d+)% off\.') != null) {
        expect(n(1) * n(2) % 100, 0);
        return '₹${n(1) * n(2) ~/ 100}';
      }
      if (re(r'^What percent of (\d+) is (\d+)\?$') != null) {
        expect(n(2) * 100 % n(1), 0);
        return '${n(2) * 100 ~/ n(1)}%';
      }
    case 7:
      if (re(r'^Which ratio is equal to (\d+) : (\d+)\?$') != null) {
        final ok = options.where((o) {
          final t = o.split(' : ').map(int.parse).toList();
          return t[0] * n(2) == n(1) * t[1];
        }).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
      if (re(r'^A recipe uses (\d+) [a-z ]+ for (\d+) [a-z]+\. How many [a-z ]+ are needed for (\d+) [a-z]+\?$') !=
          null) {
        expect(n(3) * n(1) % n(2), 0);
        return '${n(3) * n(1) ~/ n(2)}';
      }
      if (re(r'^Find the missing number: (\d+) : (\d+) = (\d+) : \?$') !=
          null) {
        expect(n(3) % n(1), 0);
        return '${n(2) * n(3) ~/ n(1)}';
      }
      if (re(r'^Write the ratio (\d+) : (\d+) in its simplest form\.$') !=
          null) {
        return '${n(1) ~/ _g(n(1), n(2))} : ${n(2) ~/ _g(n(1), n(2))}';
      }
      if (re(r'^(\d+) pens cost ₹(\d+)\. How much do (\d+) pens cost\?$') !=
          null) {
        expect(n(2) % n(1), 0);
        return '₹${n(2) ~/ n(1) * n(3)}';
      }
    case 8:
      if (re(r'^(\w+) has (\w) marbles and wins (\d+) more\.') != null) {
        return '${m!.group(2)} + ${m!.group(3)}';
      }
      if (re(r'^A pen costs (\w) rupees\. Which expression shows the cost of (\d+) pens\?$') !=
          null) {
        return '${m!.group(2)}${m!.group(1)}';
      }
      if (re(r'^What is the value of (\w) \+ (\d+) when \1 = (\d+)\?$') !=
          null) {
        return '${n(2) + n(3)}';
      }
      if (re(r'^What is the value of (\d+)(\w) when \2 = (\d+)\?$') != null) {
        return '${n(1) * n(3)}';
      }
      if (re(r'^Meena has (\w) sweets and gives away (\d+)\.') != null) {
        return '${m!.group(1)} - ${m!.group(2)}';
      }
    case 9:
      if (re(r'^Solve (\w) \+ (\d+) = (\d+)\.$') != null) {
        return '${m!.group(1)} = ${n(3) - n(2)}';
      }
      if (re(r'^Solve (\w) - (\d+) = (\d+)\.$') != null) {
        return '${m!.group(1)} = ${n(3) + n(2)}';
      }
      if (re(r'^Solve (\d+)(\w) = (\d+)\.$') != null) {
        expect(n(3) % n(1), 0);
        return '${m!.group(2)} = ${n(3) ~/ n(1)}';
      }
      if (re(r'^Solve (\w) ÷ (\d+) = (\d+)\.$') != null) {
        return '${m!.group(1)} = ${n(3) * n(2)}';
      }
      if (re(r'^I think of a number and add (\d+)\. The answer is (\d+)\.') !=
          null) {
        return '${n(2) - n(1)}';
      }
    case 10:
      if (re(r'^Point A is (\d+) units to the right of the origin and (\d+) units up\.') !=
          null) {
        return '(${n(1)}, ${n(2)})';
      }
      if (re(r'^The points \((\d+), (\d+)\) and \((\d+), \2\) are joined') !=
          null) {
        return '${n(3) - n(1)}';
      }
      if (re(r'^Start at \((\d+), (\d+)\)\. Move (\d+) units right and (\d+) unit up\.') !=
          null) {
        return '(${n(1) + n(3)}, ${n(2) + n(4)})';
      }
      if (p == 'Which ordered pair is a point on the x-axis?') {
        final ok = options.where((o) => o.endsWith(', 0)')).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
      if (re(r'^A treasure is (\d+) steps east and (\d+) steps north of the start\.') !=
          null) {
        return '(${n(1)}, ${n(2)})';
      }
    case 11:
      if (re(r'^A triangle has sides of (\d+) cm, (\d+) cm and (\d+) cm\.') !=
          null) {
        expect(n(1) + n(2) > n(3) && n(1) + n(3) > n(2) && n(2) + n(3) > n(1),
            isTrue);
        final eq = (n(1) == n(2) ? 1 : 0) +
            (n(2) == n(3) ? 1 : 0) +
            (n(1) == n(3) ? 1 : 0);
        return eq == 3 ? 'Equilateral' : (eq == 1 ? 'Isosceles' : 'Scalene');
      }
      return _hand[p];
    case 12:
      if (re(r'^A (?:cuboid|box) is (\d+) cm long, (\d+) cm wide and (\d+) cm high\.') !=
          null) {
        return '${n(1) * n(2) * n(3)} cm³';
      }
      if (re(r'^A cube has edges of (\d+) cm\.') != null) {
        return '${n(1) * n(1) * n(1)} cm³';
      }
      if (re(r'^A cuboid has a volume of (\d+) cm³\. Its length is (\d+) cm and its width is (\d+) cm\.') !=
          null) {
        expect(n(1) % (n(2) * n(3)), 0);
        return '${n(1) ~/ (n(2) * n(3))} cm';
      }
      if (re(r'^A box is packed with 1 cm cubes in (\d+) layers\. Each layer has (\d+) rows of (\d+) cubes\.') !=
          null) {
        return '${n(1) * n(2) * n(3)}';
      }
    case 13:
      if (re(r'^(?:Find the mean of|Scores in 5 matches were) ([\d, ]+)\. What is the mean\?$') !=
          null) {
        final v = RegExp(r'\d+')
            .allMatches(m!.group(1)!)
            .map((e) => int.parse(e.group(0)!))
            .toList();
        final sum = v.fold<int>(0, (a, b) => a + b);
        expect(sum % v.length, 0);
        return '${sum ~/ v.length}';
      }
      if (re(r'^Find the median of ([\d, ]+)\.$') != null) {
        final v = RegExp(r'\d+')
            .allMatches(m!.group(1)!)
            .map((e) => int.parse(e.group(0)!))
            .toList()
          ..sort();
        expect(v.length.isEven, isTrue);
        final h = v.length ~/ 2;
        return _scaled((v[h - 1] + v[h]) * 5, 1);
      }
      if (p.startsWith('Shoe sizes of')) {
        final entries = RegExp(r'size (\d+) \((\d+) children\)')
            .allMatches(p)
            .map(
                (e) => MapEntry(int.parse(e.group(1)!), int.parse(e.group(2)!)))
            .toList();
        expect(entries.fold<int>(0, (a, e) => a + e.value),
            int.parse(RegExp(r'of (\d+) children:').firstMatch(p)!.group(1)!));
        final top = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
        final best = entries.where((e) => e.value == top).toList();
        expect(best, hasLength(1));
        return 'Size ${best.single.key}';
      }
      if (re(r'^The mean of 4 numbers is (\d+)\. Three of them are (\d+), (\d+) and (\d+)\.') !=
          null) {
        return '${n(1) * 4 - n(2) - n(3) - n(4)}';
      }
    case 14:
      if (re(r'^A bag holds (\d+) red marbles? and (\d+) blue marbles?\. You pick one without looking\. Picking a (red|blue) marble is\.\.\.$') !=
          null) {
        final fav = m!.group(3) == 'red' ? n(1) : n(2);
        final total = n(1) + n(2);
        if (fav == 0) return 'Impossible';
        if (fav == total) return 'Certain';
        if (fav * 2 == total) return 'Even chance';
        return fav * 2 > total ? 'Likely' : 'Unlikely';
      }
      return _hand[p];
    case 15:
      if (re(r'^You have ₹(\d+)\. You spend ₹(\d+) on food, ₹(\d+) on books and ₹(\d+) on a bus pass\.') !=
          null) {
        return '₹${n(1) - n(2) - n(3) - n(4)}';
      }
      if (re(r'^One shop sells (\d+) notebooks for ₹(\d+)\. Another shop sells (\d+) notebooks for ₹(\d+)\.') !=
          null) {
        final x = n(2) * n(3), y = n(4) * n(1);
        expect(x == y, isFalse);
        return x < y ? '${n(1)} for ₹${n(2)}' : '${n(3)} for ₹${n(4)}';
      }
      if (re(r'^Meena saves ₹(\d+) every month\. In how many months will she save ₹(\d+)\?$') !=
          null) {
        expect(n(2) % n(1), 0);
        return '${n(2) ~/ n(1)}';
      }
      if (re(r'^Of a monthly budget of ₹(\d+), ₹(\d+) is spent on travel\.') !=
          null) {
        expect(n(2) * 100 % n(1), 0);
        return '${n(2) * 100 ~/ n(1)}%';
      }
      if (re(r'^A game costs ₹(\d+)\. It is sold at (\d+)% off\.') != null) {
        expect(n(1) * n(2) % 100, 0);
        return '₹${n(1) - n(1) * n(2) ~/ 100}';
      }
  }
  return null;
}

bool _answerInPrompt(String answer, String prompt) =>
    RegExp('(?<![\\w.,/₹])${RegExp.escape(answer)}(?![\\w/]|[.,]\\d)')
        .hasMatch(prompt);

void main() {
  test('15 lessons with the right ids in order', () {
    expect(numbersLevel5Lessons, hasLength(15));
    for (var i = 0; i < 15; i++) {
      final lesson = numbersLevel5Lessons[i];
      expect(lesson.id, 'numbers-l5-${(i + 1).toString().padLeft(3, '0')}');
      expect(lesson.title, isNotEmpty);
      expect(lesson.ageBand, '10-12');
    }
  });

  for (var i = 0; i < 15; i++) {
    final no = i + 1;
    test('lesson $no structure and answers', () {
      final lesson = numbersLevel5Lessons[i];
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
        expect(s.prompt.length, lessThanOrEqualTo(170), reason: s.prompt);
        expect(s.options, hasLength(3), reason: s.prompt);
        expect(s.options.toSet(), hasLength(3), reason: s.prompt);
        expect(s.options.every((o) => o.trim().isNotEmpty), isTrue);
        expect(s.options.where((o) => o == s.answer), hasLength(1),
            reason: s.prompt);
        expect(_answerInPrompt(s.answer, s.prompt), isFalse,
            reason: 'answer inside prompt: ${s.prompt}');
        final expected = recompute(no, s.prompt, s.options);
        expect(expected, isNotNull, reason: 'cannot parse: ${s.prompt}');
        expect(s.answer, expected, reason: s.prompt);

        // No second option may be mathematically equal to the answer.
        final fr = RegExp(r'^(\d+)/(\d+)$');
        if (fr.hasMatch(s.answer)) {
          final vals = s.options.map((o) {
            final t = fr.firstMatch(o)!;
            return int.parse(t.group(1)!) / int.parse(t.group(2)!);
          }).toSet();
          expect(vals, hasLength(3), reason: 'equal fractions: ${s.prompt}');
        }
      }
      final positions = choices.map((s) => s.options.indexOf(s.answer)).toSet();
      expect(positions.length, greaterThan(1),
          reason: 'answer position never varies');
    });
  }

  test('answer position varies across the whole set', () {
    final counts = <int, int>{};
    for (final lesson in numbersLevel5Lessons) {
      for (final s in lesson.steps.where((s) => s.kind == StepKind.choice)) {
        counts.update(s.options.indexOf(s.answer), (c) => c + 1,
            ifAbsent: () => 1);
      }
    }
    expect(counts.keys.toSet(), {0, 1, 2});
    for (final c in counts.values) {
      expect(c, greaterThan(15));
    }
  });
}
