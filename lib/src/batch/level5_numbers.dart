import 'batch_lesson.dart';
import 'level3_support.dart';

/// Level 5 numbers: 15 lessons (numbers-l5-001 .. 015). Level 5: pass
/// `ageBand: '10-12', level: 5`.
///
/// Arithmetic answers are computed with exact integer maths (fractions via
/// gcd, decimals as scaled integers, never doubles). Distractors are typical
/// mistakes. Shape-classification and probability-language items are
/// hand-written, with side/angle and marble-count items still derived in code.
final List<BatchLesson> numbersLevel5Lessons = List.unmodifiable(<BatchLesson>[
  _lesson(
    1,
    'Integers and the number line',
    'Compare and add negative and positive numbers.',
    'integers',
    'integers on the number line',
    'Numbers left of 0 are negative. The further left, the smaller: -8 < -3. '
        'Moving right adds, moving left subtracts.',
    '-4, 0, +6',
    [
      _signIntQ(-3, -8, 2),
      _smallestQ([-2, 5, -9], 0),
      _tempQ(-4, 9, 1),
      _addIntQ(-7, 3, 2),
      _distQ(-4, 6, 0),
    ],
  ),
  _lesson(
    2,
    'Order of operations',
    'Evaluate expressions in the correct order.',
    'operations',
    'order of operations',
    'Brackets first, then x and ÷, then + and -. So 6 + 4 x 3 = 6 + 12 = 18, '
        'not 30.',
    '(8 + 4) x 3',
    [
      _opMulQ(6, 4, 3, 1),
      _opParenQ(8, 4, 3, 2),
      _opDivQ(20, 12, 4, 0),
      _opTwoProdQ(5, 6, 2, 4, 2),
      _opMixQ(7, 3, 5, 4, 1),
    ],
  ),
  _lesson(
    3,
    'Fractions with unlike denominators',
    'Add and subtract fractions with different bottoms.',
    'fractions',
    'adding and subtracting unlike fractions',
    'Make the bottoms equal first: 1/2 + 1/3 = 3/6 + 2/6 = 5/6. Then add or '
        'subtract the tops and simplify.',
    '1/2 + 1/3',
    [
      _fracOpQ(1, 2, '+', 1, 3, 1),
      _fracOpQ(3, 4, '-', 1, 6, 0),
      _fracOpQ(2, 5, '+', 1, 3, 2),
      _fracOpQ(5, 6, '-', 3, 8, 1),
      _fracOpQ(1, 4, '+', 3, 10, 0),
    ],
  ),
  _lesson(
    4,
    'Fraction multiplication',
    'Multiply fractions: a part of a part.',
    'fractions',
    'multiplying fractions',
    'Multiply tops, multiply bottoms, then simplify. 2/3 of 3/4 = 6/12 = 1/2. '
        'For 3/4 of 24, divide by 4, times 3.',
    '2/3 of 3/4',
    [
      _fracMulQ(2, 3, 3, 4, true, 2),
      _fracMulQ(3, 4, 2, 5, false, 0),
      _recipeQ(5, 6, 3, 4, 1),
      _fracMulQ(4, 7, 2, 5, false, 2),
      _fracOfWholeQ(3, 4, 24, 0),
    ],
  ),
  _lesson(
    5,
    'Decimal multiplication',
    'Multiply decimals and place the point correctly.',
    'decimals',
    'multiplying decimals',
    'Multiply as whole numbers, then count the decimal places. 1.2 x 0.5: '
        '12 x 5 = 60, two places, so 0.60 = 0.6.',
    '1.2 x 0.5',
    [
      _decMulQ('1.2', '0.5', 0),
      _decMulQ('3.2', '0.6', 2),
      _decMulQ('0.7', '0.8', 1),
      _decMulQ('0.25', '12', 2),
      _decWordQ('0.8', '3.5', 0),
    ],
  ),
  _lesson(
    6,
    'Percent of a quantity',
    'Find a percentage of an amount.',
    'percentages',
    'percent of a quantity',
    'Percent means out of 100. 10% of 150 is 15, so 20% is 30. Find 10% first, '
        'then scale up.',
    '20% of 150',
    [
      _pctOfQ(20, 150, 1),
      _discountQ(800, 25, 2),
      _pctOfQ(35, 240, 0),
      _whatPctQ(10, 50, 1),
      _girlsQ(600, 45, 2),
    ],
  ),
  _lesson(
    7,
    'Ratio and proportion',
    'Scale ratios and solve direct proportion.',
    'ratio',
    'ratio and proportion',
    'Multiply both parts by the same number: 2 : 3 = 4 : 6. In a recipe, '
        'double the flour means double the milk.',
    '2 : 3 = 4 : 6',
    [
      _equalRatioQ(3, 5, 4, 0),
      _scaleQ('cups of flour', 'biscuits', 3, 12, 20, 2),
      _missingRatioQ(4, 7, 12, 1),
      _simplestRatioQ(18, 24, 2),
      _penPriceQ(5, 40, 8, 0),
    ],
  ),
  _lesson(
    8,
    'Introduction to variables',
    'Write and evaluate simple expressions.',
    'algebra',
    'variables and expressions',
    'A letter stands for an unknown number. x + 5 means "5 more than x". 3x '
        'means 3 times x. If x = 4, then x + 5 = 9.',
    'x + 5',
    [
      _marblesQ('Ravi', 'x', 5, 1),
      _penCostQ('y', 4, 0),
      _evalAddQ('x', 9, 4, 2),
      _evalMulQ('x', 3, 7, 1),
      _sweetsQ('n', 8, 0),
    ],
  ),
  _lesson(
    9,
    'One-step equations',
    'Solve equations by balancing both sides.',
    'algebra',
    'one-step equations',
    'Do the opposite to both sides. x + 7 = 15: take away 7 from both sides, '
        'so x = 8. For 4n = 28, divide by 4.',
    'x + 7 = 15',
    [
      _eqAddQ('x', 7, 8, 0),
      _eqSubQ('y', 6, 15, 2),
      _eqMulQ('n', 4, 7, 1),
      _eqDivQ('m', 5, 6, 2),
      _thinkQ(9, 14, 0),
    ],
  ),
  _lesson(
    10,
    'The coordinate grid',
    'Read and write ordered pairs in the first quadrant.',
    'geometry',
    'ordered pairs on a grid',
    'An ordered pair is (across, up). The point (3, 4) is 3 right and 4 up '
        'from the origin (0, 0). Across first, then up.',
    '(3, 4)',
    [
      _gridDescQ(3, 4, 1),
      _segmentQ(2, 9, 4, 2),
      _moveQ(2, 3, 4, 1, 0),
      _axisQ(5, 1),
      _eastQ(7, 2, 2),
    ],
  ),
  _lesson(
    11,
    'Triangles and quadrilaterals',
    'Classify shapes by their sides and parallel lines.',
    'geometry',
    'classifying triangles and quadrilaterals',
    'Equilateral: 3 equal sides. Isosceles: exactly 2. Scalene: none. A '
        'rectangle has 4 right angles; a trapezium 1 parallel pair.',
    'Isosceles, parallelogram',
    [
      _triSidesQ(9, 9, 9, 1),
      _triSidesQ(8, 8, 5, 2),
      _triSidesQ(4, 6, 9, 0),
      _mc(
          'A four-sided shape has two pairs of parallel sides and four right '
              'angles. Its sides are not all equal. What is it?',
          'Rectangle',
          ['Rhombus', 'Trapezium'],
          1),
      _mc('Which shape has exactly one pair of parallel sides?', 'Trapezium',
          ['Parallelogram', 'Rectangle'], 2),
    ],
  ),
  _lesson(
    12,
    'Volume of cuboids',
    'Find the volume of a cuboid with length x width x height.',
    'measurement',
    'volume of cuboids',
    'Volume is the space inside: length x width x height. A 5 x 4 x 3 cuboid '
        'holds 60 unit cubes, so 60 cm³.',
    '3 x 4 x 5 cubes',
    [
      _cuboidQ('cuboid', 6, 4, 3, 1),
      _cubeQ(4, 2),
      _cuboidQ('box', 8, 5, 2, 0),
      _missingHeightQ(120, 6, 5, 1),
      _layersQ(4, 6, 2, 2),
    ],
  ),
  _lesson(
    13,
    'Mean, median and mode',
    'Find the average, middle and most common value.',
    'data',
    'mean, median and mode',
    'Mean: add all, divide by how many. Median: the middle value when sorted. '
        'Mode: the value that appears most.',
    '4, 6, 6, 8',
    [
      _meanQ('Find the mean of', [3, 5, 9, 11], 1),
      _medianQ([12, 3, 9, 6, 20, 15], 2),
      _modeQ({5: 2, 6: 5, 7: 2, 9: 1}, 0),
      _meanQ('Scores in 5 matches were', [12, 15, 9, 20, 24], 2),
      _fourthQ(7, [6, 9, 8], 1),
    ],
  ),
  _lesson(
    14,
    'Probability language',
    'Describe how likely an event is.',
    'probability',
    'probability words',
    'Chance runs from impossible, unlikely, even chance, likely to certain. '
        'Compare the favourite outcomes with all outcomes.',
    'Likely or unlikely',
    [
      _mc(
          'A fair die shows the numbers 1 to 6. You roll it. Rolling a number '
              'less than 7 is...',
          'Certain',
          ['Likely', 'Impossible'],
          1),
      _marbleQ(9, 1, 'red', 2),
      _mc(
          'A bag holds only green marbles. You pick one without looking. '
              'Picking a yellow marble is...',
          'Impossible',
          ['Unlikely', 'Certain'],
          0),
      _marbleQ(7, 1, 'blue', 1),
      _mc('You toss a fair coin. Landing on heads is...', 'Even chance',
          ['Certain', 'Unlikely'], 2),
    ],
  ),
  _lesson(
    15,
    'Budget and money',
    'Plan spending and compare costs.',
    'money',
    'budgets and best buys',
    'Add the costs, then subtract from your money. To compare prices, find '
        'the cost of one: ₹60 for 4 is ₹15 each.',
    '₹500 spending plan',
    [
      _budgetLeftQ(500, [120, 85, 60], 1),
      _cheaperQ(4, 60, 6, 84, 2),
      _monthsQ(900, 150, 0),
      _pctSpentQ(2000, 500, 1),
      _saleQ(800, 15, 2),
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
      id: 'numbers-l5-${no.toString().padLeft(3, '0')}',
      module: 'numbers',
      title: title,
      objective: objective,
      topic: topic,
      skill: skill,
      teach: teach,
      examples: [example],
      questions: questions,
      ageBand: '10-12',
      level: 5,
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

int _p10(int k) {
  var r = 1;
  for (var i = 0; i < k; i++) {
    r *= 10;
  }
  return r;
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

/// The fraction n/d in lowest terms, written like 3/4.
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

L3Q _signQ(String a, String b, int cmp, int pos) {
  final ans = cmp < 0 ? '<' : (cmp > 0 ? '>' : '=');
  final wrong = ['<', '>', '='].where((s) => s != ans).toList();
  return _mc('Which sign fits? $a ? $b', ans, wrong, pos);
}

// ------------------------------------------------------------ lesson 1

L3Q _signIntQ(int a, int b, int pos) => _signQ('$a', '$b', a.compareTo(b), pos);

L3Q _smallestQ(List<int> v, int pos) {
  final ans = (List<int>.of(v)..sort()).first;
  return _mc(
    'Which of these numbers is the smallest?',
    '$ans',
    v.where((x) => x != ans).map((x) => '$x').toList(),
    pos,
  );
}

L3Q _tempQ(int start, int rise, int pos) {
  final ans = start + rise;
  return _mc(
    'At night the temperature is $start°C. By noon it rises by $rise '
        'degrees. What is the temperature at noon?',
    '$ans°C',
    ['${start - rise}°C', '${start.abs() + rise}°C', '${-ans}°C'],
    pos,
  );
}

L3Q _addIntQ(int a, int b, int pos) {
  final ans = a + b;
  return _mc(
    'What is $a + $b?',
    '$ans',
    ['${-ans}', '${a.abs() + b}', '${-(a.abs() + b)}'],
    pos,
  );
}

L3Q _distQ(int a, int b, int pos) {
  final ans = b - a;
  return _mc(
    'How many steps is it from $a to $b on the number line?',
    '$ans',
    ['${b + a}', '${a.abs() * b}', '${ans - 2}'],
    pos,
  );
}

// ------------------------------------------------------------ lesson 2

L3Q _opMulQ(int a, int b, int c, int pos) => _mc(
      'What is $a + $b x $c?',
      '${a + b * c}',
      ['${(a + b) * c}', '${a + b + c}', '${a * b + c}'],
      pos,
    );

L3Q _opParenQ(int a, int b, int c, int pos) => _mc(
      'What is ($a + $b) x $c?',
      '${(a + b) * c}',
      ['${a + b * c}', '${a + b + c}', '${a * b + c}'],
      pos,
    );

L3Q _opDivQ(int a, int b, int c, int pos) {
  if (b % c != 0 || (a - b) % c != 0) throw StateError('div $a $b $c');
  return _mc(
    'What is $a - $b ÷ $c?',
    '${a - b ~/ c}',
    ['${(a - b) ~/ c}', '${a - b - c}', '${a - b + c}'],
    pos,
  );
}

L3Q _opTwoProdQ(int a, int b, int c, int d, int pos) => _mc(
      'What is $a x $b - $c x $d?',
      '${a * b - c * d}',
      ['${(a * b - c) * d}', '${a * (b - c) * d}', '${a * b + c * d}'],
      pos,
    );

L3Q _opMixQ(int a, int b, int c, int d, int pos) => _mc(
      'What is $a + $b x $c - $d?',
      '${a + b * c - d}',
      ['${(a + b) * c - d}', '${a + b * (c - d)}', '${a + b * c + d}'],
      pos,
    );

// ------------------------------------------------------------ lesson 3

L3Q _fracOpQ(int a, int b, String op, int c, int d, int pos) {
  final l = b * d ~/ _gcd(b, d);
  final x = a * (l ~/ b), y = c * (l ~/ d);
  final num = op == '+' ? x + y : x - y;
  final raw = op == '+' ? a + c : a - c;
  return _mc(
    'What is $a/$b $op $c/$d? Give the answer in lowest terms.',
    _frac(num, l),
    [
      _frac(raw, b + d),
      _frac(raw, l),
      if (num - 1 > 0) _frac(num - 1, l),
      _frac(num + 1, l),
    ],
    pos,
  );
}

// ------------------------------------------------------------ lesson 4

L3Q _fracMulQ(int a, int b, int c, int d, bool of, int pos) => _mc(
      'What is $a/$b ${of ? 'of' : 'x'} $c/$d? Give the answer in lowest '
      'terms.',
      _frac(a * c, b * d),
      [
        _frac(a * c, b + d),
        _frac(a * d, b * c),
        _frac(a + c, b * d),
      ],
      pos,
    );

L3Q _recipeQ(int a, int b, int c, int d, int pos) => _mc(
      'A recipe needs $a/$b cup of sugar. Meera makes $c/$d of the recipe. '
      'How many cups of sugar does she use? Give the answer in lowest '
      'terms.',
      _frac(a * c, b * d),
      [
        _frac(a * c, b + d),
        _frac(a * d, b * c),
        _frac(a + c, b * d),
      ],
      pos,
    );

L3Q _fracOfWholeQ(int a, int b, int n, int pos) {
  if (n % b != 0) throw StateError('whole $n');
  return _mc(
    'What is $a/$b of $n?',
    '${n ~/ b * a}',
    ['${n ~/ b}', '${n * a}', '${n - a}'],
    pos,
  );
}

// ------------------------------------------------------------ lesson 5

({int v, int dp}) _dec(String s) {
  final p = s.split('.');
  final f = p.length > 1 ? p[1] : '';
  return (v: int.parse('${p[0]}$f'), dp: f.length);
}

List<String> _decProductOptions(String a, String b) {
  final x = _dec(a), y = _dec(b);
  final prod = x.v * y.v, dp = x.dp + y.dp;
  return [
    _fmtScaled(prod, dp),
    _fmtScaled(prod, dp - 1),
    _fmtScaled(prod, dp + 1),
    _fmtScaled(prod, 0),
  ];
}

L3Q _decMulQ(String a, String b, int pos) {
  final o = _decProductOptions(a, b);
  return _mc('What is $a x $b?', o[0], o.sublist(1), pos);
}

L3Q _decWordQ(String rate, String km, int pos) {
  final o = _decProductOptions(rate, km);
  return _mc(
    'A car uses $rate litres of petrol per km. How many litres does it use '
    'for $km km?',
    o[0],
    o.sublist(1),
    pos,
  );
}

// ------------------------------------------------------------ lesson 6

L3Q _pctOfQ(int p, int n, int pos) {
  if (p * n % 100 != 0) throw StateError('percent $p of $n');
  final ans = p * n ~/ 100;
  return _mc('What is $p% of $n?', '$ans',
      ['${n - ans}', '${ans * 10}', '$p', '${ans + 10}'], pos);
}

L3Q _discountQ(int price, int p, int pos) {
  if (p * price % 100 != 0) throw StateError('discount');
  final d = p * price ~/ 100;
  return _mc(
    'A shirt costs ₹$price. The shop gives $p% off. How much is the '
        'discount?',
    '₹$d',
    ['₹${price - d}', '₹$p', '₹${d * 10}'],
    pos,
  );
}

L3Q _whatPctQ(int part, int whole, int pos) {
  if (part * 100 % whole != 0) throw StateError('what percent');
  final p = part * 100 ~/ whole;
  return _mc(
    'What percent of $whole is $part?',
    '$p%',
    ['$part%', '${100 - p}%', '${p * 2}%'],
    pos,
  );
}

L3Q _girlsQ(int n, int p, int pos) {
  if (p * n % 100 != 0) throw StateError('class $p of $n');
  final ans = p * n ~/ 100;
  return _mc(
    'In a school of $n students, $p% are girls. How many girls are there?',
    '$ans',
    ['${n - ans}', '$p', '${ans * 10}'],
    pos,
  );
}

// ------------------------------------------------------------ lesson 7

L3Q _equalRatioQ(int a, int b, int k, int pos) => _mc(
      'Which ratio is equal to $a : $b?',
      '${a * k} : ${b * k}',
      [
        '${a + k} : ${b + k}',
        '${a * k} : ${b + k}',
        '${a + k} : ${b * k}',
      ],
      pos,
    );

L3Q _scaleQ(String what, String per, int a, int b, int c, int pos) {
  if (c * a % b != 0) throw StateError('scale');
  final ans = c * a ~/ b;
  return _mc(
    'A recipe uses $a $what for $b $per. How many $what are needed for $c '
        '$per?',
    '$ans',
    ['${a + c - b}', '${c * b ~/ a}', '${a * c}'],
    pos,
  );
}

L3Q _missingRatioQ(int a, int b, int c, int pos) {
  if (c % a != 0) throw StateError('missing ratio');
  return _mc(
    'Find the missing number: $a : $b = $c : ?',
    '${b * (c ~/ a)}',
    ['${b + c - a}', '${b + c}', '${c * a}'],
    pos,
  );
}

L3Q _simplestRatioQ(int a, int b, int pos) {
  final g = _gcd(a, b);
  if (g % 6 != 0) throw StateError('simplest ratio');
  return _mc(
    'Write the ratio $a : $b in its simplest form.',
    '${a ~/ g} : ${b ~/ g}',
    [
      '${a ~/ 2} : ${b ~/ 2}',
      '${a ~/ 3} : ${b ~/ 3}',
      '${b ~/ g} : ${a ~/ g}',
    ],
    pos,
  );
}

L3Q _penPriceQ(int n, int price, int k, int pos) {
  if (price % n != 0) throw StateError('pen price');
  return _mc(
    '$n pens cost ₹$price. How much do $k pens cost?',
    '₹${price ~/ n * k}',
    ['₹${price + k - n}', '₹${price * k}', '₹${price ~/ n}'],
    pos,
  );
}

// ------------------------------------------------------------ lesson 8

L3Q _marblesQ(String who, String v, int k, int pos) => _mc(
      '$who has $v marbles and wins $k more. Which expression shows how many '
          'marbles he has now?',
      '$v + $k',
      ['$k$v', '$v - $k', '$k - $v'],
      pos,
    );

L3Q _penCostQ(String v, int k, int pos) => _mc(
      'A pen costs $v rupees. Which expression shows the cost of $k pens?',
      '$k$v',
      ['$v + $k', '$v ÷ $k', '$v - $k'],
      pos,
    );

L3Q _evalAddQ(String v, int a, int val, int pos) => _mc(
      'What is the value of $v + $a when $v = $val?',
      '${val + a}',
      ['${a - val}', '$a$val', '${val * a}'],
      pos,
    );

L3Q _evalMulQ(String v, int a, int val, int pos) => _mc(
      'What is the value of $a$v when $v = $val?',
      '${a * val}',
      ['$a$val', '${a + val}', '${val - a}'],
      pos,
    );

L3Q _sweetsQ(String v, int k, int pos) => _mc(
      'Meena has $v sweets and gives away $k. Which expression shows how '
          'many sweets she has left?',
      '$v - $k',
      ['$k - $v', '$v + $k', '$k$v'],
      pos,
    );

// ------------------------------------------------------------ lesson 9

L3Q _eqAddQ(String v, int a, int ans, int pos) {
  final r = ans + a;
  return _mc('Solve $v + $a = $r.', '$v = $ans',
      ['$v = ${r + a}', '$v = $a', '$v = $r'], pos);
}

L3Q _eqSubQ(String v, int a, int ans, int pos) {
  final r = ans - a;
  return _mc('Solve $v - $a = $r.', '$v = $ans',
      ['$v = ${r - a}', '$v = $a', '$v = $r'], pos);
}

L3Q _eqMulQ(String v, int a, int ans, int pos) {
  final r = a * ans;
  return _mc('Solve $a$v = $r.', '$v = $ans',
      ['$v = ${r - a}', '$v = $a', '$v = ${r * a}'], pos);
}

L3Q _eqDivQ(String v, int a, int r, int pos) => _mc(
      'Solve $v ÷ $a = $r.',
      '$v = ${r * a}',
      ['$v = ${r + a}', '$v = ${r - a}', '$v = $r'],
      pos,
    );

L3Q _thinkQ(int add, int ans, int pos) {
  final r = ans + add;
  return _mc(
    'I think of a number and add $add. The answer is $r. What is my number?',
    '$ans',
    ['${r + add}', '$add', '$r'],
    pos,
  );
}

// ----------------------------------------------------------- lesson 10

L3Q _gridDescQ(int r, int u, int pos) => _mc(
      'Point A is $r units to the right of the origin and $u units up. Which '
          'ordered pair names point A?',
      '($r, $u)',
      ['($u, $r)', '($r, 0)', '(0, $u)'],
      pos,
    );

L3Q _segmentQ(int x1, int x2, int y, int pos) {
  final d = x2 - x1;
  return _mc(
    'The points ($x1, $y) and ($x2, $y) are joined by a straight line. How '
        'long is the line, in units?',
    '$d',
    ['${x1 + x2}', '${d + 1}', '${d - 2}'],
    pos,
  );
}

L3Q _moveQ(int x, int y, int dx, int dy, int pos) => _mc(
      'Start at ($x, $y). Move $dx units right and $dy unit up. Where do you '
          'land?',
      '(${x + dx}, ${y + dy})',
      ['(${x + dx}, $y)', '(${x + dy}, ${y + dx})', '(${x + dx + dy}, $y)'],
      pos,
    );

L3Q _axisQ(int v, int pos) => _mc(
      'Which ordered pair is a point on the x-axis?',
      '($v, 0)',
      ['(0, $v)', '($v, $v)'],
      pos,
    );

L3Q _eastQ(int e, int n, int pos) => _mc(
      'A treasure is $e steps east and $n steps north of the start. Which '
          'ordered pair gives its position if the start is (0, 0)?',
      '($e, $n)',
      ['($n, $e)', '($e, 0)', '(${e + n}, ${e + n})'],
      pos,
    );

// ----------------------------------------------------------- lesson 11

L3Q _triSidesQ(int a, int b, int c, int pos) {
  final eq = (a == b ? 1 : 0) + (b == c ? 1 : 0) + (a == c ? 1 : 0);
  final ans = eq == 3 ? 'Equilateral' : (eq == 1 ? 'Isosceles' : 'Scalene');
  if (a + b <= c || a + c <= b || b + c <= a) throw StateError('triangle');
  return _mc(
    'A triangle has sides of $a cm, $b cm and $c cm. What kind of triangle '
    'is it?',
    ans,
    ['Equilateral', 'Isosceles', 'Scalene'].where((s) => s != ans).toList(),
    pos,
  );
}

// ----------------------------------------------------------- lesson 12

L3Q _cuboidQ(String name, int l, int w, int h, int pos) => _mc(
      'A $name is $l cm long, $w cm wide and $h cm high. What is its volume?',
      '${l * w * h} cm³',
      [
        '${l * w + h} cm³',
        '${2 * (l * w + w * h + h * l)} cm³',
        '${l + w + h} cm³',
      ],
      pos,
    );

L3Q _cubeQ(int e, int pos) => _mc(
      'A cube has edges of $e cm. What is its volume?',
      '${e * e * e} cm³',
      ['${3 * e} cm³', '${e * e} cm³', '${6 * e * e} cm³'],
      pos,
    );

L3Q _missingHeightQ(int v, int l, int w, int pos) {
  if (v % (l * w) != 0) throw StateError('height');
  final h = v ~/ (l * w);
  return _mc(
    'A cuboid has a volume of $v cm³. Its length is $l cm and its width is '
        '$w cm. What is its height?',
    '$h cm',
    ['${v ~/ l} cm', '${l * w} cm', '${h + 2} cm'],
    pos,
  );
}

L3Q _layersQ(int rows, int per, int layers, int pos) => _mc(
      'A box is packed with 1 cm cubes in $layers layers. Each layer has '
          '$rows rows of $per cubes. How many cubes are in the box?',
      '${rows * per * layers}',
      [
        '${rows * per}',
        '${rows + per + layers}',
        '${rows * per * layers * 2}',
      ],
      pos,
    );

// ----------------------------------------------------------- lesson 13

L3Q _meanQ(String intro, List<int> v, int pos) {
  final sum = v.fold<int>(0, (a, b) => a + b);
  if (sum % v.length != 0) throw StateError('mean');
  final mean = sum ~/ v.length;
  return _mc(
    '$intro ${v.join(', ')}. What is the mean?',
    '$mean',
    ['$sum', '${mean + 2}', '${mean - 1}'],
    pos,
  );
}

L3Q _medianQ(List<int> v, int pos) {
  final s = List<int>.of(v)..sort();
  final h = s.length ~/ 2;
  if (s.length.isOdd) throw StateError('median needs an even count');
  final mid = v.length ~/ 2;
  return _mc(
    'Find the median of ${v.join(', ')}.',
    _fmtScaled((s[h - 1] + s[h]) * 5, 1),
    [
      _fmtScaled((v[mid - 1] + v[mid]) * 5, 1),
      '${s[h - 1]}',
      '${s[h]}',
    ],
    pos,
  );
}

L3Q _modeQ(Map<int, int> counts, int pos) {
  final total = counts.values.fold<int>(0, (a, b) => a + b);
  final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  final tied = counts.values.where((c) => c == best.value).length;
  if (tied != 1) throw StateError('mode must be unique');
  return _mc(
    'Shoe sizes of $total children: '
        '${counts.entries.map((e) => 'size ${e.key} (${e.value} children)').join(', ')}. '
        'Which shoe size is the mode?',
    'Size ${best.key}',
    counts.keys.where((k) => k != best.key).map((k) => 'Size $k').toList(),
    pos,
  );
}

L3Q _fourthQ(int mean, List<int> three, int pos) {
  final sum3 = three.fold<int>(0, (a, b) => a + b);
  final fourth = mean * 4 - sum3;
  return _mc(
    'The mean of 4 numbers is $mean. Three of them are '
        '${three.sublist(0, 2).join(', ')} and ${three.last}. What is the '
        'fourth number?',
    '$fourth',
    ['${mean * 4}', '$sum3', '$mean'],
    pos,
  );
}

// ----------------------------------------------------------- lesson 14

/// Likelihood word for [fav] favourable outcomes out of [total].
String _likelihood(int fav, int total) {
  if (fav == 0) return 'Impossible';
  if (fav == total) return 'Certain';
  if (fav * 2 == total) return 'Even chance';
  return fav * 2 > total ? 'Likely' : 'Unlikely';
}

L3Q _marbleQ(int red, int blue, String target, int pos) {
  final fav = target == 'red' ? red : blue;
  final ans = _likelihood(fav, red + blue);
  const neighbours = {
    'Likely': ['Certain', 'Unlikely'],
    'Unlikely': ['Likely', 'Impossible'],
  };
  return _mc(
    'A bag holds $red red marbles and $blue blue marble${blue == 1 ? '' : 's'}'
    '. You pick one without looking. Picking a $target marble is...',
    ans,
    neighbours[ans]!,
    pos,
  );
}

// ----------------------------------------------------------- lesson 15

L3Q _budgetLeftQ(int total, List<int> costs, int pos) {
  final spent = costs.fold<int>(0, (a, b) => a + b);
  return _mc(
    'You have ₹$total. You spend ₹${costs[0]} on food, ₹${costs[1]} on books '
        'and ₹${costs[2]} on a bus pass. How much money is left?',
    '₹${total - spent}',
    ['₹$spent', '₹${total - spent + costs.last}', '₹${total - costs[0]}'],
    pos,
  );
}

L3Q _cheaperQ(int n1, int p1, int n2, int p2, int pos) {
  final x = p1 * n2, y = p2 * n1;
  if (x == y) throw StateError('same price');
  final a = '$n1 for ₹$p1', b = '$n2 for ₹$p2';
  return _mc(
    'One shop sells $n1 notebooks for ₹$p1. Another shop sells $n2 notebooks '
    'for ₹$p2. Which is cheaper per notebook?',
    x < y ? a : b,
    [x < y ? b : a, 'Both cost the same'],
    pos,
  );
}

L3Q _monthsQ(int goal, int monthly, int pos) {
  if (goal % monthly != 0) throw StateError('months');
  final m = goal ~/ monthly;
  return _mc(
    'Meena saves ₹$monthly every month. In how many months will she save '
        '₹$goal?',
    '$m',
    ['${m - 1}', '${m + 1}', '${goal ~/ 100}'],
    pos,
  );
}

L3Q _pctSpentQ(int budget, int spent, int pos) {
  if (spent * 100 % budget != 0) throw StateError('pct spent');
  final p = spent * 100 ~/ budget;
  return _mc(
    'Of a monthly budget of ₹$budget, ₹$spent is spent on travel. What '
        'percent of the budget is that?',
    '$p%',
    ['${spent ~/ 100}%', '${100 - p}%', '${p * 2}%'],
    pos,
  );
}

L3Q _saleQ(int price, int p, int pos) {
  if (p * price % 100 != 0) throw StateError('sale');
  final d = p * price ~/ 100;
  return _mc(
    'A game costs ₹$price. It is sold at $p% off. What is the sale price?',
    '₹${price - d}',
    ['₹$d', '₹${price + d}', '₹${price - p}'],
    pos,
  );
}
