import 'batch_lesson.dart';
import 'level3_support.dart';

/// Level 6 numbers: 10 lessons (numbers-l6-001 .. 010), about age 13.
///
/// All arithmetic is done in code with exact integer maths (fractions through
/// an integer gcd, decimals as scaled integers, money in whole rupees), so the
/// answers are correct by construction; test/level6_numbers_test.dart
/// recomputes every answer from the prompt text. Distractors are typical
/// mistakes.
final List<BatchLesson> numbersLevel6Lessons = List.unmodifiable(<BatchLesson>[
  _lesson(
    1,
    'Operations with integers',
    'Add, subtract, multiply and divide positive and negative numbers.',
    'integers',
    'operations with integers',
    'Same signs add; different signs subtract. Minus a negative adds. Two negatives multiply to a positive.',
    '-6 x 7 = -42',
    [
      _intQ(-9, '+', 4, 0),
      _intQ(6, '-', -9, 1),
      _intQ(-6, 'x', 7, 2),
      _intQ(-48, '÷', -6, 1),
      _tempQ('Shimla', -4, true, 11, 0),
    ],
  ),
  _lesson(
    2,
    'Rational numbers',
    'Compare and operate on fractions and decimals.',
    'rational numbers',
    'fractions and decimals',
    'Make denominators equal to add, subtract or compare. To divide by a fraction, multiply by its flip: 1/2 ÷ 1/4 = 2.',
    '2/5 + 1/3',
    [
      _fracOpQ(2, 5, '+', 1, 3, 1),
      _greaterQ(5, 6, 7, 9, 2),
      _fracOpQ(5, 6, '-', 3, 8, 0),
      _fracOpQ(2, 3, '÷', 4, 5, 2),
      _decOpQ('3.6', 'x', '0.5', 1),
    ],
  ),
  _lesson(
    3,
    'Ratio and rates',
    'Find speed, unit rates and shares in a ratio.',
    'ratio and rate',
    'speed and unit rate',
    'Speed = distance ÷ time. A unit rate is the amount for one: ₹60 for 4 kg is ₹15 per kg. Share a total by adding the ratio parts.',
    'Speed = distance ÷ time',
    [
      _speedQ(180, 3, 2),
      _unitRateQ(6, 240, 0),
      _bestBuyQ(5, 60, 8, 80, 1),
      _distanceQ(75, 4, 2),
      _shareQ(3, 5, 40, 0),
    ],
  ),
  _lesson(
    4,
    'Discount, profit and loss',
    'Use percent to find discount, profit and loss.',
    'percentage',
    'discount, profit and loss',
    'Discount = % of marked price; selling price = marked price - discount. Profit % = profit ÷ cost price x 100.',
    'Profit % = profit ÷ CP x 100',
    [
      _discountQ('bag', 800, 15, false, 1),
      _discountQ('shirt', 1200, 20, true, 0),
      _profitQ(400, 500, 2),
      _lossQ(1500, 1200, 1),
      _profitSpQ(3000, 10, 0),
    ],
  ),
  _lesson(
    5,
    'Simple interest',
    'Use SI = P x R x T ÷ 100 and rearrange it.',
    'percentage',
    'simple interest',
    'Simple interest = P x R x T ÷ 100: P is the sum, R the rate per year, T the years. Amount = P + interest.',
    'SI = P x R x T ÷ 100',
    [
      _siQ(5000, 8, 3, 2),
      _amountQ(4000, 5, 2, 0),
      _rateQ(6000, 900, 3, 1),
      _timeQ(2500, 6, 450, 2),
      _principalQ(360, 4, 3, 1),
    ],
  ),
  _lesson(
    6,
    'Algebraic expressions',
    'Simplify like terms and substitute values.',
    'algebra',
    'expressions',
    'Like terms have the same letter: 3x + 5x = 8x. To substitute, put the number in place of the letter, then calculate.',
    '3x + 5x = 8x',
    [
      _likeQ(3, 5, 2, 1),
      _subOneQ(4, 3, 5, 0),
      _twoVarQ(5, 6, 3, 3, 2),
      _marblesQ(2, 3, 1),
      _twoSubQ(3, 2, 6, 4, 0),
    ],
  ),
  _lesson(
    7,
    'Two-step linear equations',
    'Solve equations by undoing each step.',
    'algebra',
    'linear equations',
    'Undo the steps in reverse order. 2x + 3 = 11: subtract 3 to get 2x = 8, then divide by 2 to get x = 4.',
    '2x + 3 = 11',
    [
      _eq1Q(3, 5, 5, 1),
      _eq2Q(4, 2, 3, 2),
      _eq3Q(5, 7, 18, 0),
      _thinkQ(3, 7, 9, 2),
      _taxiQ(20, 12, 6, 1),
    ],
  ),
  _lesson(
    8,
    'Triangle angles and angle pairs',
    'Use angle sums and pairs to find missing angles.',
    'geometry',
    'angle sum and angle pairs',
    'Angles of a triangle add up to 180°. Complementary angles add to 90°. Vertically opposite angles are equal.',
    '180° in a triangle',
    [
      _thirdAngleQ(55, 65, 1),
      _isoscelesQ(40, 2),
      _vertOppQ(0),
      _ratioAngleQ(2, 3, 4, 1),
      _complementQ(38, 2),
    ],
  ),
  _lesson(
    9,
    'Area of triangle, parallelogram, circle',
    'Find areas with the standard formulas, using 22/7.',
    'mensuration',
    'area formulas',
    'Triangle = ½ x base x height. Parallelogram = base x height. Circle = πr², with π = 22/7.',
    'πr² with π = 22/7',
    [
      _triQ(14, 9, 0),
      _circQ(7, 2),
      _paraQ(12, 7, 1),
      _circDQ(28, 0),
      _triHeightQ(60, 12, 2),
    ],
  ),
  _lesson(
    10,
    'Mean, median, range and probability',
    'Summarise a small data set and find a simple probability.',
    'data and chance',
    'statistics and probability',
    'Mean = sum ÷ count. Median = middle value of the sorted list. Range = largest - smallest. Probability = favourable ÷ total.',
    'Mean, median, range',
    [
      _meanQ([6, 9, 7, 11, 17], 1),
      _medianQ([8, 3, 11, 5, 14, 9], 2),
      _rangeQ([14, 22, 9, 17, 25], 0),
      _bagQ(4, 5, 3, 1),
      _dieQ(4, 2),
    ],
  ),
]);

BatchLesson _lesson(
  int no,
  String title,
  String objective,
  String topic,
  String skill,
  String teach,
  String example,
  List<L3Q> questions,
) =>
    level3Lesson(
      id: 'numbers-l6-${no.toString().padLeft(3, '0')}',
      module: 'numbers',
      title: title,
      objective: objective,
      topic: topic,
      skill: skill,
      teach: teach,
      examples: [example],
      questions: questions,
      ageBand: '10-12',
      level: 6,
    );

// ---------------------------------------------------------------- helpers

/// Builds a question with the answer placed at [pos] among three options.
/// [wrong] is a list of candidate distractors, tried in order; ones equal to
/// the answer or to an earlier one are skipped.
L3Q _mc(String prompt, String answer, List<String> wrong, int pos) {
  final w = <String>[];
  for (final x in wrong) {
    if (x != answer && !w.contains(x)) w.add(x);
  }
  if (w.length < 2) throw StateError('Not enough distractors: $prompt');
  final options = w.take(2).toList()..insert(pos, answer);
  return L3Q(prompt, options, answer);
}

int _gcd(int a, int b) => b == 0 ? a.abs() : _gcd(b, a % b);

int _p10(int k) {
  var r = 1;
  for (var i = 0; i < k; i++) {
    r *= 10;
  }
  return r;
}

/// The fraction n/d in lowest terms.
String _frac(int n, int d) {
  final g = _gcd(n, d);
  return '${n ~/ g}/${d ~/ g}';
}

/// v / 10^dp written as a decimal with trailing zeros removed.
String _fmtScaled(int v, int dp) {
  if (dp == 0) return '$v';
  final p = _p10(dp);
  var frac = (v % p).toString().padLeft(dp, '0');
  frac = frac.replaceFirst(RegExp(r'0+$'), '');
  return frac.isEmpty ? '${v ~/ p}' : '${v ~/ p}.$frac';
}

String _par(int v) => v < 0 ? '($v)' : '$v';

// ------------------------------------------------------------ lesson 1

L3Q _intQ(int a, String op, int b, int pos) {
  late final int ans;
  late final List<int> wrong;
  switch (op) {
    case '+':
      ans = a + b;
      wrong = [-ans, a.abs() + b.abs(), -(a.abs() + b.abs()), ans + 2];
    case '-':
      ans = a - b;
      wrong = [a + b, -ans, ans - 2, ans + 2];
    case 'x':
      ans = a * b;
      wrong = [-ans, a + b, a * b + b, ans + 2];
    default:
      if (a % b != 0) throw StateError('divide');
      ans = a ~/ b;
      wrong = [-ans, ans - 2, ans + 2, ans + 10];
  }
  return _mc('What is $a $op ${_par(b)}?', '$ans',
      wrong.map((v) => '$v').toList(), pos);
}

L3Q _tempQ(String town, int t, bool rise, int d, int pos) {
  final ans = rise ? t + d : t - d;
  return _mc(
    'At night the temperature in $town was $t°C. By noon it ${rise ? 'rose' : 'fell'} by $d°C. What is the temperature at noon?',
    '$ans°C',
    ['${t - d}°C', '${d - t}°C', '${t.abs() + d}°C', '${ans + 2}°C'],
    pos,
  );
}

// ------------------------------------------------------------ lesson 2

L3Q _greaterQ(int a, int b, int c, int d, int pos) {
  final x = a * d, y = c * b;
  final ans = x > y
      ? '$a/$b is greater'
      : (x < y ? '$c/$d is greater' : 'They are equal');
  return _mc(
    'Which is greater, $a/$b or $c/$d?',
    ans,
    ['$a/$b is greater', '$c/$d is greater', 'They are equal'],
    pos,
  );
}

L3Q _fracOpQ(int a, int b, String op, int c, int d, int pos) {
  late final int n, den;
  late final List<String> wrong;
  switch (op) {
    case '+':
      n = a * d + c * b;
      den = b * d;
      wrong = [_frac(a + c, b + d), _frac(a + c, b * d), _frac(n + 1, den)];
    case '-':
      n = a * d - c * b;
      den = b * d;
      wrong = [_frac(a - c, b + d), _frac(a - c, b * d), _frac(n + 1, den)];
    default:
      n = a * d;
      den = b * c;
      wrong = [_frac(a * c, b * d), _frac(b * c, a * d), _frac(n + 1, den)];
  }
  if (n <= 0) throw StateError('fraction result');
  return _mc(
    'What is $a/$b $op $c/$d? Give the answer in lowest terms.',
    _frac(n, den),
    wrong,
    pos,
  );
}

/// Decimal text with at most two places, as an integer in hundredths.
int _hundredths(String s) {
  final p = s.split('.');
  final f = (p.length > 1 ? p[1] : '').padRight(2, '0');
  return int.parse(p[0]) * 100 + int.parse(f.substring(0, 2));
}

L3Q _decOpQ(String a, String op, String b, int pos) {
  final x = _hundredths(a), y = _hundredths(b);
  if (op == 'x') {
    final v = x * y;
    return _mc(
      'What is $a x $b?',
      _fmtScaled(v, 4),
      [_fmtScaled(v, 3), _fmtScaled(v, 5), _fmtScaled(v, 2)],
      pos,
    );
  }
  final v = op == '+' ? x + y : x - y;
  return _mc(
    'What is $a $op $b?',
    _fmtScaled(v, 2),
    [_fmtScaled(v + 10, 2), _fmtScaled(v - 10, 2), _fmtScaled(v, 1)],
    pos,
  );
}

// ------------------------------------------------------------ lesson 3

L3Q _speedQ(int d, int t, int pos) {
  if (d % t != 0) throw StateError('speed');
  final ans = d ~/ t;
  return _mc(
    'A bus covers $d km in $t hours. What is its average speed?',
    '$ans km/h',
    ['${d * t} km/h', '${d + t} km/h', '${ans * 2} km/h'],
    pos,
  );
}

L3Q _distanceQ(int v, int t, int pos) => _mc(
      'A train runs at $v km/h for $t hours. How far does it go?',
      '${v * t} km',
      ['${v + t} km', '${v * t - v} km', '${v * t + v} km'],
      pos,
    );

L3Q _unitRateQ(int n, int p, int pos) {
  if (p % n != 0) throw StateError('unit rate');
  final u = p ~/ n;
  return _mc(
    '$n notebooks cost ₹$p. What is the cost of one notebook?',
    '₹$u',
    ['₹${p * n}', '₹${p - n}', '₹${u + n}'],
    pos,
  );
}

L3Q _bestBuyQ(int n1, int p1, int n2, int p2, int pos) {
  if (p1 % n1 != 0 || p2 % n2 != 0 || p1 ~/ n1 == p2 ~/ n2) {
    throw StateError('best buy');
  }
  final u1 = p1 ~/ n1, u2 = p2 ~/ n2;
  final a = 'Pack A, ₹$u1 per pen', b = 'Pack B, ₹$u2 per pen';
  return _mc(
    'Pack A has $n1 pens for ₹$p1. Pack B has $n2 pens for ₹$p2. Which pack is cheaper per pen?',
    u1 < u2 ? a : b,
    [u1 < u2 ? b : a, 'Both cost the same per pen'],
    pos,
  );
}

L3Q _shareQ(int a, int b, int n, int pos) {
  if (n % (a + b) != 0) throw StateError('share');
  final part = n ~/ (a + b);
  return _mc(
    'The ratio of boys to girls in a class is $a : $b. There are $n students. How many girls are there?',
    '${part * b}',
    ['${part * a}', '${n - b}', '${n ~/ b}'],
    pos,
  );
}

// ------------------------------------------------------------ lesson 4

L3Q _discountQ(String item, int mp, int pct, bool price, int pos) {
  if (mp * pct % 100 != 0) throw StateError('discount');
  final disc = mp * pct ~/ 100;
  final ask = price ? 'the selling price' : 'the discount in rupees';
  return _mc(
    'A $item marked at ₹$mp is sold at a $pct% discount. What is $ask?',
    price ? '₹${mp - disc}' : '₹$disc',
    price
        ? ['₹$disc', '₹${mp + disc}', '₹${mp - pct}']
        : ['₹${mp - disc}', '₹$pct', '₹${disc * 10}'],
    pos,
  );
}

L3Q _profitQ(int cp, int sp, int pos) {
  final profit = sp - cp;
  if (profit <= 0 || profit * 100 % cp != 0) throw StateError('profit');
  final p = profit * 100 ~/ cp;
  return _mc(
    'Ravi buys a cycle for ₹$cp and sells it for ₹$sp. What is his profit percent?',
    '$p%',
    ['${profit * 100 ~/ sp}%', '${100 + p}%', '$profit%'],
    pos,
  );
}

L3Q _lossQ(int cp, int sp, int pos) {
  final loss = cp - sp;
  if (loss <= 0 || loss * 100 % cp != 0) throw StateError('loss');
  final p = loss * 100 ~/ cp;
  return _mc(
    'A fan bought for ₹$cp is sold for ₹$sp. What is the loss percent?',
    '$p%',
    ['${loss * 100 ~/ sp}%', '${100 - p}%', '$loss%'],
    pos,
  );
}

L3Q _profitSpQ(int cp, int pct, int pos) {
  if (cp * pct % 100 != 0) throw StateError('profit sp');
  final profit = cp * pct ~/ 100;
  return _mc(
    'A trader buys a table for ₹$cp and sells it at a $pct% profit. What is the selling price?',
    '₹${cp + profit}',
    ['₹$profit', '₹${cp - profit}', '₹${cp + pct}'],
    pos,
  );
}

// ------------------------------------------------------------ lesson 5

L3Q _siQ(int p, int r, int t, int pos) {
  final si = p * r * t ~/ 100;
  return _mc(
    'What is the simple interest on ₹$p at $r% per year for $t years?',
    '₹$si',
    ['₹${p * r * t}', '₹${p + si}', '₹${p * r ~/ 100}'],
    pos,
  );
}

L3Q _amountQ(int p, int r, int t, int pos) {
  final si = p * r * t ~/ 100;
  return _mc(
    'Asha deposits ₹$p at $r% simple interest per year for $t years. How much does she get back in all?',
    '₹${p + si}',
    ['₹$si', '₹${p + r * t}', '₹${p + si * 2}'],
    pos,
  );
}

L3Q _rateQ(int p, int si, int t, int pos) {
  if (si * 100 % (p * t) != 0) throw StateError('rate');
  final r = si * 100 ~/ (p * t);
  return _mc(
    'A sum of ₹$p earns ₹$si simple interest in $t years. What is the rate per year?',
    '$r%',
    ['${si * 100 ~/ p}%', '$t%', '${r * 2}%'],
    pos,
  );
}

L3Q _timeQ(int p, int r, int si, int pos) {
  if (si * 100 % (p * r) != 0) throw StateError('time');
  final t = si * 100 ~/ (p * r);
  return _mc(
    '₹$p at $r% simple interest per year earns ₹$si. For how many years was it kept?',
    '$t years',
    ['${si * 100 ~/ p} years', '${t * 2} years', '${t + 1} years'],
    pos,
  );
}

L3Q _principalQ(int si, int r, int t, int pos) {
  if (si * 100 % (r * t) != 0) throw StateError('principal');
  final p = si * 100 ~/ (r * t);
  return _mc(
    'A sum earns ₹$si simple interest at $r% per year in $t years. What is the sum?',
    '₹$p',
    ['₹${si * 100 ~/ r}', '₹${si * 100 ~/ t}', '₹${si * t}'],
    pos,
  );
}

// ------------------------------------------------------------ lesson 6

L3Q _likeQ(int a, int b, int c, int pos) => _mc(
      'Simplify: ${a}x + ${b}x - ${c}x',
      '${a + b - c}x',
      ['${a + b + c}x', '${a + b - c}', '${a + b - c}x²'],
      pos,
    );

L3Q _subOneQ(int k, int m, int a, int pos) => _mc(
      'Find the value of ${k}a + $m when a = $a.',
      '${k * a + m}',
      ['${k * a}', '${k + m + a}', '${k * (a + m)}'],
      pos,
    );

L3Q _twoVarQ(int a, int b, int c, int d, int pos) {
  if (b - d < 2) throw StateError('two var');
  return _mc(
    'Simplify: ${a}x + ${b}y + ${c}x - ${d}y',
    '${a + c}x + ${b - d}y',
    [
      '${a + c}x + ${b + d}y',
      '${a + b + c - d}xy',
      '${a + c}x - ${b - d}y',
    ],
    pos,
  );
}

L3Q _marblesQ(int k, int m, int pos) => _mc(
      "Ravi has x marbles. Meena has $m more than $k times Ravi's marbles. Which expression shows Meena's marbles?",
      '${k}x + $m',
      ['${m}x + $k', '$k(x + $m)'],
      pos,
    );

L3Q _twoSubQ(int a, int b, int p, int q, int pos) => _mc(
      'Find the value of ${a}p - ${b}q when p = $p and q = $q.',
      '${a * p - b * q}',
      ['${a * p + b * q}', '${(a - b) * (p - q)}', '${a * p - b}'],
      pos,
    );

// ------------------------------------------------------------ lesson 7

L3Q _eq1Q(int a, int b, int s, int pos) {
  final c = a * s + b;
  return _mc(
    'Solve: ${a}x + $b = $c',
    'x = $s',
    ['x = ${c - b}', 'x = ${c + b}', 'x = ${s + 1}'],
    pos,
  );
}

L3Q _eq2Q(int d, int b, int c, int pos) => _mc(
      'Solve: x/$d - $b = $c',
      'x = ${(c + b) * d}',
      ['x = ${c + b}', 'x = ${(c - b) * d}', 'x = ${c * d - b}'],
      pos,
    );

L3Q _eq3Q(int a, int b, int c, int pos) {
  if ((c + b) % a != 0) throw StateError('eq3');
  final s = (c + b) ~/ a;
  return _mc(
    'Solve: ${a}x - $b = $c',
    'x = $s',
    ['x = ${c - b}', 'x = ${c + b}', 'x = ${(c - b) ~/ a}'],
    pos,
  );
}

L3Q _thinkQ(int k, int m, int s, int pos) {
  final r = k * s + m;
  return _mc(
    'Meena thinks of a number, multiplies it by $k and adds $m. The result is $r. What is the number?',
    '$s',
    ['${r - m}', '${r ~/ k - m}', '${(r + m) ~/ k}'],
    pos,
  );
}

L3Q _taxiQ(int f, int k, int s, int pos) {
  final r = f + k * s;
  return _mc(
    'A taxi charges ₹$f plus ₹$k for each km. A ride costs ₹$r. How many km was the ride?',
    '$s km',
    ['${r - f} km', '${r ~/ k} km', '${(r + f) ~/ k} km'],
    pos,
  );
}

// ------------------------------------------------------------ lesson 8

L3Q _thirdAngleQ(int a, int b, int pos) => _mc(
      'Two angles of a triangle are $a° and $b°. What is the third angle?',
      '${180 - a - b}°',
      ['${a + b}°', '${180 - a}°', '${360 - a - b}°'],
      pos,
    );

L3Q _isoscelesQ(int x, int pos) {
  if ((180 - x) % 2 != 0) throw StateError('isosceles');
  return _mc(
    'In an isosceles triangle the angle between the two equal sides is $x°. What is each of the other two angles?',
    '${(180 - x) ~/ 2}°',
    ['${180 - x}°', '$x°', '${(90 - x)}°'],
    pos,
  );
}

L3Q _vertOppQ(int pos) => _mc(
      'Two straight lines cross. The angles opposite each other are called vertically opposite angles. How do they compare?',
      'They are equal',
      ['They add up to 180°', 'They add up to 90°'],
      pos,
    );

L3Q _ratioAngleQ(int a, int b, int c, int pos) {
  final total = a + b + c;
  if (180 % total != 0) throw StateError('ratio angle');
  final k = 180 ~/ total;
  final big = [a, b, c].reduce((x, y) => x > y ? x : y) * k;
  return _mc(
    'The angles of a triangle are in the ratio $a : $b : $c. What is the largest angle?',
    '$big°',
    ['$k°', '${b * k}°', '${180 - big}°'],
    pos,
  );
}

L3Q _complementQ(int x, int pos) => _mc(
      'Two angles are complementary (they add up to 90°). One is $x°. What is the other?',
      '${90 - x}°',
      ['${180 - x}°', '$x°', '${90 - x - 10}°'],
      pos,
    );

// ------------------------------------------------------------ lesson 9

L3Q _triQ(int b, int h, int pos) {
  if (b * h % 2 != 0) throw StateError('tri');
  return _mc(
    'A triangle has a base of $b cm and a height of $h cm. What is its area?',
    '${b * h ~/ 2} cm²',
    ['${b * h} cm²', '${b + h} cm²', '${b * h ~/ 2 + b} cm²'],
    pos,
  );
}

L3Q _paraQ(int b, int h, int pos) => _mc(
      'A parallelogram has a base of $b cm and a height of $h cm. What is its area?',
      '${b * h} cm²',
      ['${b * h ~/ 2} cm²', '${2 * (b + h)} cm²', '${b + h} cm²'],
      pos,
    );

L3Q _circQ(int r, int pos) {
  if (r % 7 != 0) throw StateError('circle');
  final area = 22 * r * r ~/ 7;
  return _mc(
    'A circle has a radius of $r cm. Use 22/7 for π. What is its area?',
    '$area cm²',
    ['${area * 4} cm²', '${44 * r ~/ 7} cm²', '${22 * r ~/ 7} cm²'],
    pos,
  );
}

L3Q _circDQ(int d, int pos) {
  final r = d ~/ 2;
  if (d % 2 != 0 || r % 7 != 0) throw StateError('circle d');
  final area = 22 * r * r ~/ 7;
  return _mc(
    'A circular table top has a diameter of $d cm. Use 22/7 for π. What is its area?',
    '$area cm²',
    ['${22 * d * d ~/ 7} cm²', '${44 * r ~/ 7} cm²', '${22 * r ~/ 7} cm²'],
    pos,
  );
}

L3Q _triHeightQ(int area, int b, int pos) {
  if (2 * area % b != 0) throw StateError('height');
  return _mc(
    'A triangle has an area of $area cm² and a base of $b cm. What is its height?',
    '${2 * area ~/ b} cm',
    ['${area ~/ b} cm', '${area - b} cm', '${2 * area} cm'],
    pos,
  );
}

// ----------------------------------------------------------- lesson 10

String _list(List<int> v) => v.join(', ');

L3Q _meanQ(List<int> v, int pos) {
  final sum = v.fold<int>(0, (a, b) => a + b);
  if (sum % v.length != 0) throw StateError('mean');
  final mean = sum ~/ v.length;
  final s = [...v]..sort();
  return _mc(
    'The marks of five students are ${_list(v)}. What is the mean mark?',
    '$mean',
    ['${s[s.length ~/ 2]}', '${s.last - s.first}', '${mean + 1}'],
    pos,
  );
}

L3Q _medianQ(List<int> v, int pos) {
  final s = [...v]..sort();
  if (s.length % 2 != 0) throw StateError('even count expected');
  final lo = s[s.length ~/ 2 - 1], hi = s[s.length ~/ 2];
  return _mc(
    'Find the median of ${_list(v)}.',
    _fmtScaled((lo + hi) * 5, 1),
    ['$lo', '$hi', '${s.last - s.first}'],
    pos,
  );
}

L3Q _rangeQ(List<int> v, int pos) {
  final s = [...v]..sort();
  return _mc(
    'The heights (in cm) of five plants are ${_list(v)}. What is the range?',
    '${s.last - s.first}',
    ['${s.last}', '${s.last + s.first}', '${s.first}'],
    pos,
  );
}

L3Q _bagQ(int r, int b, int g, int pos) => _mc(
      'A bag has $r red, $b blue and $g green marbles. One marble is picked at random. What is the probability that it is blue?',
      _frac(b, r + b + g),
      [_frac(b, r + g), _frac(1, r + b + g), _frac(r + g, r + b + g)],
      pos,
    );

L3Q _dieQ(int k, int pos) {
  final fav = 6 - k;
  return _mc(
    'A fair die is rolled. What is the probability of getting a number greater than $k?',
    _frac(fav, 6),
    [_frac(1, 6), _frac(k, 6), _frac(fav, k)],
    pos,
  );
}
