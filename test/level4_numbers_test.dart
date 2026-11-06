import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/batch/level4_numbers.dart';
import 'package:flutter_test/flutter_test.dart';

int _i(String s) => int.parse(s.replaceAll(',', ''));
int _g(int a, int b) => b == 0 ? a : _g(b, a % b);
String _f(int n, int d) => '${n ~/ _g(n, d)}/${d ~/ _g(n, d)}';
String _rupees(int p) => '₹${p ~/ 100}.${(p % 100).toString().padLeft(2, '0')}';
bool _isPrime(int n) {
  if (n < 2) return false;
  for (var i = 2; i * i <= n; i++) {
    if (n % i == 0) return false;
  }
  return true;
}

/// Recomputes the answer straight from the prompt text (and, for "pick the
/// one that ..." items, from the options), without using the builder code.
String? recompute(int lesson, String p, List<String> options) {
  RegExpMatch? m;
  int n(int i) => int.parse(m!.group(i)!);
  RegExpMatch? re(String pattern) => m = RegExp(pattern).firstMatch(p);
  switch (lesson) {
    case 1:
      if (re(r'^What is the value of the digit (\d) in ([\d,]+)\?$') != null) {
        final s = m!.group(2)!.replaceAll(',', '');
        return _commaOf(n(1) * _pow10(s.length - 1 - s.indexOf(m!.group(1)!)));
      }
      if (re(r'^Which sign fits\? ([\d,.]+) \? ([\d,.]+)$') != null) {
        final a = double.parse(m!.group(1)!.replaceAll(',', ''));
        final b = double.parse(m!.group(2)!.replaceAll(',', ''));
        return a > b ? '>' : (a < b ? '<' : '=');
      }
      if (re(r'^Round ([\d,]+) to the nearest (ten thousand|hundred thousand|thousand|million)\.$') !=
          null) {
        final u = {
          'thousand': 1000,
          'ten thousand': 10000,
          'hundred thousand': 100000,
          'million': 1000000
        }[m!.group(2)]!;
        final v = _i(m!.group(1)!);
        return _commaOf(((v + u ~/ 2) ~/ u) * u);
      }
      if (re(r'^What is ([\d, +]+)\?$') != null) {
        final sum = RegExp(r'\d[\d,]*')
            .allMatches(m!.group(1)!)
            .map((e) => _i(e.group(0)!))
            .fold<int>(0, (a, b) => a + b);
        return _commaOf(sum);
      }
    case 2:
      if (re(r'^What is (\d+) x (\d+)\?$') != null) return '${n(1) * n(2)}';
      if (re(r'^A school buys (\d+) boxes with (\d+) chalks each\.') != null) {
        return '${n(1) * n(2)}';
      }
    case 3:
      if (re(r'^What is (\d+) ÷ (\d+)\? Write r for any remainder\.$') !=
          null) {
        final q = n(1) ~/ n(2), r = n(1) % n(2);
        expect(q * n(2) + r, n(1));
        return r == 0 ? '$q' : '$q r $r';
      }
    case 4:
      if (re(r'^Which number is a factor of (\d+)\?$') != null) {
        final ok = options.where((o) => n(1) % int.parse(o) == 0).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
      if (re(r'^Which number is a multiple of (\d+)\?$') != null) {
        final ok = options.where((o) => int.parse(o) % n(1) == 0).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
      if (re(r'^Which number is prime\?$') != null) {
        final ok = options.where((o) => _isPrime(int.parse(o))).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
      if (re(r'^How many factors does (\d+) have\?$') != null) {
        return '${[
          for (var i = 1; i <= n(1); i++)
            if (n(1) % i == 0) i
        ].length}';
      }
      if (re(r'^What is the (\d+)th multiple of (\d+)\?$') != null) {
        return '${n(1) * n(2)}';
      }
    case 5:
      if (re(r'^Which fraction is equal to (\d+)/(\d+)\?$') != null) {
        final ok = options.where((o) {
          final t = o.split('/').map(int.parse).toList();
          return t[0] * n(2) == n(1) * t[1];
        }).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
      if (re(r'^What number makes the fractions equal\? (\d+)/(\d+) = \?/(\d+)$') !=
          null) {
        expect(n(3) % n(2), 0);
        return '${n(1) * n(3) ~/ n(2)}';
      }
      if (re(r'^What number makes the fractions equal\? (\d+)/(\d+) = (\d+)/\?$') !=
          null) {
        expect(n(3) % n(1), 0);
        return '${n(2) * n(3) ~/ n(1)}';
      }
      if (re(r'^Write (\d+)/(\d+) in its simplest form\.$') != null) {
        return _f(n(1), n(2));
      }
      if (re(r'^Which is greater, (\d+)/(\d+) or (\d+)/(\d+)\?$') != null) {
        final x = n(1) * n(4), y = n(3) * n(2);
        return x > y
            ? '${n(1)}/${n(2)} is greater'
            : (x < y ? '${n(3)}/${n(4)} is greater' : 'They are equal');
      }
    case 6:
      if (re(r'^What is (\d+)/(\d+) ([+-]) (\d+)/(\d+)\? Give the answer in lowest terms\.$') !=
          null) {
        final l = n(2) * n(5) ~/ _g(n(2), n(5));
        final x = n(1) * (l ~/ n(2)), y = n(4) * (l ~/ n(5));
        return _f(m!.group(3) == '+' ? x + y : x - y, l);
      }
    case 7:
      if (re(r'^Which digit is in the (tenths|hundredths|thousandths) place of ([\d.]+)\?$') !=
          null) {
        final idx =
            ['tenths', 'hundredths', 'thousandths'].indexOf(m!.group(1)!);
        return m!.group(2)!.split('.')[1][idx];
      }
      if (re(r'^Which sign fits\? ([\d.]+) \? ([\d.]+)$') != null) {
        final a = double.parse(m!.group(1)!), b = double.parse(m!.group(2)!);
        return a > b ? '>' : (a < b ? '<' : '=');
      }
      if (re(r'^Round ([\d.]+) to the nearest (tenth|hundredth)\.$') != null) {
        final dp = m!.group(2) == 'tenth' ? 1 : 2;
        final parts = m!.group(1)!.split('.');
        final frac = parts[1].padRight(dp + 1, '0');
        var scaled =
            int.parse(parts[0]) * _pow10(dp) + int.parse(frac.substring(0, dp));
        if (int.parse(frac[dp]) >= 5) scaled++;
        return _trim(
            '${scaled ~/ _pow10(dp)}.${(scaled % _pow10(dp)).toString().padLeft(dp, '0')}');
      }
      if (re(r'^Which number lies between ([\d.]+) and ([\d.]+)\?$') != null) {
        final lo = double.parse(m!.group(1)!), hi = double.parse(m!.group(2)!);
        final ok = options
            .where((o) => double.parse(o) > lo && double.parse(o) < hi)
            .toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
    case 8:
      final amounts = RegExp(r'₹(\d+)\.(\d\d)')
          .allMatches(p)
          .map((e) => int.parse(e.group(1)!) * 100 + int.parse(e.group(2)!))
          .toList();
      if (p.contains('change')) return _rupees(amounts[0] - amounts[1]);
      if (p.startsWith('What is') && p.contains(' - ')) {
        return _rupees(amounts[0] - amounts[1]);
      }
      return _rupees(amounts.fold<int>(0, (a, b) => a + b));
    case 9:
      if (re(r'^Which fraction is the same as (\d+)%\?$') != null) {
        final ok = options.where((o) {
          final t = o.split('/').map(int.parse).toList();
          return t[0] * 100 == n(1) * t[1];
        }).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
      if (re(r'^Write (\d+)% as a decimal\.$') != null) {
        final ok = options
            .where((o) => (double.parse(o) * 100 - n(1)).abs() < 1e-9)
            .toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
      if (re(r'^What is (\d+)% of (\d+)\?$') != null) {
        expect(n(1) * n(2) % 100, 0);
        return '${n(1) * n(2) ~/ 100}';
      }
      if (re(r'^In a class of (\d+), (\d+)% are girls\.') != null) {
        expect(n(1) * n(2) % 100, 0);
        return '${n(1) * n(2) ~/ 100}';
      }
      if (re(r'^Write (\d+)/(\d+) as a percent\.$') != null) {
        expect(100 % n(2), 0);
        return '${n(1) * 100 ~/ n(2)}%';
      }
    case 10:
      if (re(r'^A bag has (\d+) red and (\d+) blue balls\.') != null) {
        return '${n(1)} : ${n(2)}';
      }
      if (re(r'^There are (\d+) boys and (\d+) girls\.') != null) {
        return '${n(1) ~/ _g(n(1), n(2))} : ${n(2) ~/ _g(n(1), n(2))}';
      }
      if (re(r'^The ratio of red to blue beads is (\d+) : (\d+)\. There are (\d+) red beads\.') !=
          null) {
        expect(n(3) % n(1), 0);
        return '${n(3) ~/ n(1) * n(2)}';
      }
      if (re(r'^A drink mixes (\d+) cups of syrup with (\d+) cups of water\. How much water is needed for (\d+) cups of syrup\?$') !=
          null) {
        expect(n(3) % n(1), 0);
        return '${n(3) ~/ n(1) * n(2)}';
      }
      if (re(r'^In a group there are (\d+) girls and (\d+) boys\.') != null) {
        return '${n(1)} : ${n(1) + n(2)}';
      }
    case 11:
      if (re(r'^An angle measures (\d+)°\.') != null) {
        return n(1) < 90 ? 'Acute' : (n(1) == 90 ? 'Right' : 'Obtuse');
      }
      if (re(r'^Two angles on a straight line add up to 180°\. One is (\d+)°\.') !=
          null) {
        return '${180 - n(1)}°';
      }
      if (p.startsWith('The corner of a book')) return 'Right';
      if (p == 'Which of these angles is obtuse?') {
        final ok = options.where((o) {
          final d = int.parse(o.replaceAll('°', ''));
          return d > 90 && d < 180;
        }).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
    case 12:
      if (re(r'^A rectangle is (\d+) cm long and (\d+) cm wide\. What is its perimeter\?$') !=
          null) {
        return '${2 * (n(1) + n(2))} cm';
      }
      if (re(r'^A rectangle is (\d+) cm long and (\d+) cm wide\. What is its area\?$') !=
          null) {
        return '${n(1) * n(2)} cm²';
      }
      if (re(r'^A field is (\d+) m long and (\d+) m wide\.') != null) {
        return '${2 * (n(1) + n(2))} m';
      }
      if (re(r'^A square has sides of (\d+) cm\. What is its area\?$') !=
          null) {
        return '${n(1) * n(1)} cm²';
      }
      if (re(r'^A rectangle has an area of (\d+) cm² and a length of (\d+) cm\.') !=
          null) {
        expect(n(1) % n(2), 0);
        return '${n(1) ~/ n(2)} cm';
      }
    case 13:
      if (re(r'^How many (cm|g|m|mL|kg|L) are in (\d+) (m|kg|km|L|cm|g|mL)\?$') !=
          null) {
        const factors = {'cm/m': 100, 'g/kg': 1000, 'm/km': 1000, 'mL/L': 1000};
        final to = m!.group(1)!, from = m!.group(3)!, v = n(2);
        if (factors.containsKey('$to/$from'))
          return '${v * factors['$to/$from']!}';
        final f = factors['$from/$to']!;
        final q = v / f;
        // Compare numerically to avoid formatting differences.
        final ok =
            options.where((o) => (double.parse(o) - q).abs() < 1e-9).toList();
        expect(ok, hasLength(1), reason: p);
        return ok.single;
      }
    case 14:
      final rows = <String, int>{
        for (final e in RegExp(r'([A-Z][a-z]+) (\d+)').allMatches(p))
          e.group(1)!: int.parse(e.group(2)!)
      };
      if (p.endsWith('How many children voted in all?')) {
        return '${rows.values.fold<int>(0, (a, b) => a + b)}';
      }
      if (re(r'How many more (?:children chose )?(\w+) than (\w+)\?$') !=
          null) {
        return '${rows[m!.group(1)]! - rows[m!.group(2)]!}';
      }
      if (p.endsWith('On which day were the fewest books read?')) {
        final low = rows.entries.reduce((a, b) => a.value <= b.value ? a : b);
        return {
          'Mon': 'Monday',
          'Tue': 'Tuesday',
          'Wed': 'Wednesday',
          'Thu': 'Thursday',
          'Fri': 'Friday'
        }[low.key];
      }
      if (re(r'How many mm of rain fell in (\w+) and (\w+) together\?$') !=
          null) {
        return '${rows[m!.group(1)]! + rows[m!.group(2)]!}';
      }
    case 15:
      if (re(r'^\w+ buys (\d+) notebooks at ₹(\d+) each and pays with ₹(\d+)\.') !=
          null) {
        return '₹${n(3) - n(1) * n(2)}';
      }
      if (re(r'^A shop has (\d+) mangoes\. It sells (\d+) in the morning and (\d+) in the evening\.') !=
          null) {
        return '${n(1) - n(2) - n(3)}';
      }
      if (re(r'^(\d+) buses with (\d+) seats each carry (\d+) children\.') !=
          null) {
        return '${n(1) * n(2) - n(3)}';
      }
      if (re(r'^Ravi saves ₹(\d+) every week for (\d+) weeks and then spends ₹(\d+)\.') !=
          null) {
        return '₹${n(1) * n(2) - n(3)}';
      }
      if (re(r'^A pack of (\d+) pens costs ₹(\d+)\. What is the cost of (\d+) pens\?$') !=
          null) {
        expect(n(2) % n(1), 0);
        return '₹${n(2) ~/ n(1) * n(3)}';
      }
  }
  return null;
}

int _pow10(int k) => k == 0 ? 1 : 10 * _pow10(k - 1);

String _commaOf(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String _trim(String s) =>
    s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;

bool _answerInPrompt(String answer, String prompt) =>
    RegExp('(?<![\\w.,/₹])${RegExp.escape(answer)}(?![\\w/]|[.,]\\d)')
        .hasMatch(prompt);

void main() {
  test('15 lessons with the right ids in order', () {
    expect(numbersLevel4Lessons, hasLength(15));
    for (var i = 0; i < 15; i++) {
      final lesson = numbersLevel4Lessons[i];
      expect(lesson.id, 'numbers-l4-${(i + 1).toString().padLeft(3, '0')}');
      expect(lesson.title, isNotEmpty);
      expect(lesson.ageBand, '10-12');
    }
  });

  for (var i = 0; i < 15; i++) {
    final no = i + 1;
    test('lesson $no structure and answers', () {
      final lesson = numbersLevel4Lessons[i];
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
      }
      final positions = choices.map((s) => s.options.indexOf(s.answer)).toSet();
      expect(positions.length, greaterThan(1),
          reason: 'answer position never varies');
    });
  }

  test('answer position varies across the whole set', () {
    final counts = <int, int>{};
    for (final lesson in numbersLevel4Lessons) {
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
