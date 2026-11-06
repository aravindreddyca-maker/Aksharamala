import 'batch_lesson.dart';
import 'level3_support.dart';

/// Level 8 numbers: 10 lessons (numbers-l8-001 .. 010), about age 15
/// (`ageBand: '10-12', level: 8`; levels above 5 have no age band of their
/// own).
///
/// Every number is computed with exact integer maths (no doubles); the
/// distractors are typical mistakes. Hand-set items (irrational numbers,
/// congruence rules, ...) are listed in test/level8_numbers_test.dart.
final List<BatchLesson> numbersLevel8Lessons = List.unmodifiable(<BatchLesson>[
  _lesson(
    1,
    'Real numbers',
    'Tell rational from irrational numbers and place them on the number line.',
    'real numbers',
    'rational and irrational numbers',
    'Rational numbers are fractions p/q or end/repeat as decimals. Roots of non-squares, like √2, are irrational.',
    '√2',
    [
      _q('Which of these is an irrational number?', '√2', ['0.25', '3/4'], 1),
      _q('Which of these is a rational number?', '√16', ['√3', '√7'], 2),
      _betweenSqrt(40, 0),
      _q('Which fraction has a terminating decimal expansion?', '3/8',
          ['1/3', '5/6'], 1),
      _q('Every integer is also a ____ number.', 'rational',
          ['irrational', 'imaginary'], 2),
    ],
  ),
  _lesson(
    2,
    'Polynomials',
    'Find the degree and add, subtract and multiply simple polynomials.',
    'polynomials',
    'polynomial operations',
    'The degree is the highest power of x. Add or subtract like terms only: 3x² + 2x² = 5x². (x+a)(x+b) = x² + (a+b)x + ab.',
    '3x² + 2x² = 5x²',
    [
      _degreeQ([6, 0, 1, 0, -5], 0),
      _valueQ([2, -3, 5], 3, 1),
      _addQ([3, 5, -2], [1, -7, 6], 2),
      _subQ([3, 5, -2], [1, -7, 6], 0),
      _mulQ(3, -5, 1),
    ],
  ),
  _lesson(
    3,
    'Linear equations in two variables',
    'Find solutions of equations like ax + by = c.',
    'linear equations',
    'solutions of ax + by = c',
    'A solution of ax + by = c is a pair (x, y) that makes it true. There are infinitely many; their graph is a line.',
    '2x + 3y = 12',
    [
      _pairQ(2, 3, 12, 3, 2, 2),
      _findYQ(3, 2, 18, 4, 0),
      _interceptQ(2, 5, 20, 1),
      _q('How many solutions does a linear equation in two variables have?',
          'Infinitely many', ['Exactly one', 'Exactly two'], 2),
      _q('Which is a linear equation in two variables?', 'x + 2y = 5',
          ['x² + y = 5', 'x + 5 = 9'], 0),
    ],
  ),
  _lesson(
    4,
    'Coordinate geometry',
    'Name quadrants and measure distances along the axes.',
    'coordinate geometry',
    'quadrants and axes distances',
    'Quadrants go anticlockwise: I (+,+), II (-,+), III (-,-), IV (+,-). A point (x, 0) is on the x-axis.',
    '(x, y)',
    [
      _quadrantQ(-3, 5, 'In which quadrant does the point (-3, 5) lie?', 1),
      _quadrantQ(4, -6, 'The point (4, -6) lies in which quadrant?', 2),
      _axisDistQ(5, -8, 0),
      _axesGapQ(-3, 5, 1),
      _q('A point has coordinates (6, 0). On which line does it lie?',
          'On the x-axis', ['On the y-axis', 'In the first quadrant'], 0),
    ],
  ),
  _lesson(
    5,
    'Pythagoras theorem',
    'Use hypotenuse² = base² + height² in right triangles.',
    'geometry',
    'Pythagoras theorem',
    'In a right triangle, hypotenuse² = sum of squares of the other two sides. 3, 4, 5 works: 9 + 16 = 25.',
    '3² + 4² = 5²',
    [
      _hypQ(5, 12, 13, 0),
      _legQ(17, 8, 15, 2),
      _checkQ(7, 24, 25, 1),
      _ladderQ(10, 6, 8, 2),
      _checkQ(6, 7, 9, 0),
    ],
  ),
  _lesson(
    6,
    'Congruence of triangles',
    'Use SSS, SAS and ASA to decide when triangles are congruent.',
    'geometry',
    'congruence of triangles',
    'Triangles are congruent if SSS, SAS (angle between the two sides) or ASA holds. AAA only gives the same shape.',
    'SSS, SAS, ASA',
    [
      _q('Triangles ABC and PQR have AB = PQ, BC = QR and CA = RP. Which rule shows they are congruent?',
          'SSS', ['SAS', 'ASA'], 1),
      _q('In triangles ABC and DEF, AB = DE, AC = DF and angle A = angle D. Which rule applies?',
          'SAS', ['SSS', 'ASA'], 0),
      _q('In triangles ABC and PQR, angle B = angle Q, BC = QR and angle C = angle R. Which rule applies?',
          'ASA', ['SAS', 'SSS'], 2),
      _q('Which condition does NOT prove two triangles congruent?', 'AAA',
          ['SSS', 'SAS'], 1),
      _thirdAngleQ(60, 50, 0),
    ],
  ),
  _lesson(
    7,
    'Statistics',
    'Find the mean, median and mode and read a frequency table.',
    'statistics',
    'mean, median and mode',
    'Mean = sum ÷ count. Median = middle value of the ordered data. Mode = the value that occurs most often.',
    'mean, median, mode',
    [
      _meanQ([12, 18, 15, 21, 9], 1),
      _medianOddQ([14, 9, 21, 11, 17, 6, 19], 0),
      _modeQ([24, 31, 24, 18, 24, 31, 40, 18], 2),
      _freqTotalQ([4, 7, 9, 5], 1),
      _medianEvenQ([8, 3, 12, 5, 9, 15], 2),
    ],
  ),
  _lesson(
    8,
    'Algebraic identities',
    'Use (a+b)², (a-b)² and a²-b² to work with numbers.',
    'algebra',
    'algebraic identities',
    '(a+b)² = a²+2ab+b²; (a-b)² = a²-2ab+b²; a²-b² = (a+b)(a-b). They make big squares easy.',
    '(a + b)²',
    [
      _sqPlusQ(100, 3, 1),
      _sqMinusQ(100, 3, 0),
      _diffSqQ(63, 37, 2),
      _sumProdQ(9, 20, 1),
      _expandQ(6, 0),
    ],
  ),
  _lesson(
    9,
    'Surface area and volume',
    'Use cone and sphere formulas with π = 22/7.',
    'mensuration',
    'cone and sphere',
    'Cone: volume 1/3 πr²h, curved area πrl. Sphere: area 4πr², volume 4/3 πr³. Use π = 22/7.',
    '4/3 πr³',
    [
      _coneVolQ(7, 6, 2),
      _coneVolQ(14, 3, 0),
      _sphereAreaQ(14, 1),
      _sphereVolQ(21, 2),
      _coneCsaQ(7, 25, 0),
    ],
  ),
  _lesson(
    10,
    'Probability',
    'Find theoretical and experimental probability.',
    'probability',
    'experimental and theoretical probability',
    'Probability = favourable outcomes ÷ all outcomes, from 0 (impossible) to 1 (sure). Experimental uses trials done.',
    '3/10',
    [
      _bagQ(3, 5, 2, 1),
      _dieQ(2),
      _coinQ(20, 12, 0),
      _notRedQ(4, 6, 1),
      _q('What is the probability of an event that cannot happen?', '0',
          ['1', '1/2'], 2),
    ],
  ),
]);

// ---------------------------------------------------------------- plumbing

L3Q _q(String prompt, String answer, List<String> wrong, int pos) {
  assert(wrong.length == 2 && !wrong.contains(answer) && wrong[0] != wrong[1],
      prompt);
  final o = List<String>.of(wrong)..insert(pos, answer);
  return L3Q(prompt, o, answer);
}

BatchLesson _lesson(int n, String title, String objective, String topic,
        String skill, String teach, String symbol, List<L3Q> questions) =>
    level3Lesson(
      id: 'numbers-l8-${n.toString().padLeft(3, '0')}',
      module: 'numbers',
      title: title,
      objective: objective,
      topic: topic,
      skill: skill,
      teach: teach,
      questions: questions,
      examples: [symbol],
      symbol: symbol,
      ageBand: '10-12',
      level: 8,
    );

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
String _fr(int n, int d) => '${n ~/ _gcd(n, d)}/${d ~/ _gcd(n, d)}';
int _isqrt(int n) {
  var r = 0;
  while ((r + 1) * (r + 1) <= n) {
    r++;
  }
  return r;
}

// ---------------------------------------------------------------- lesson 1

L3Q _betweenSqrt(int n, int pos) {
  final s = _isqrt(n);
  assert(s * s != n);
  return _q('Between which two consecutive whole numbers does √$n lie?',
      '$s and ${s + 1}', ['${s - 1} and $s', '${s + 1} and ${s + 2}'], pos);
}

// ---------------------------------------------------------------- lesson 2

const _sup = {2: '²', 3: '³', 4: '⁴', 5: '⁵'};

/// Formats coefficients, highest power first, e.g. [3, 5, -2] -> 3x² + 5x - 2.
String _poly(List<int> c) {
  final b = StringBuffer();
  final deg = c.length - 1;
  var first = true;
  for (var i = 0; i < c.length; i++) {
    final k = c[i];
    if (k == 0) continue;
    final p = deg - i;
    final a = k.abs();
    if (first) {
      if (k < 0) b.write('-');
    } else {
      b.write(k < 0 ? ' - ' : ' + ');
    }
    first = false;
    if (p == 0) {
      b.write('$a');
    } else {
      if (a != 1) b.write('$a');
      b.write('x');
      if (p > 1) b.write(_sup[p]);
    }
  }
  return first ? '0' : b.toString();
}

L3Q _degreeQ(List<int> c, int pos) {
  final deg = c.length - 1;
  final terms = c.where((k) => k != 0).length;
  return _q('What is the degree of the polynomial ${_poly(c)}?', '$deg',
      ['${c[0]}', '$terms'], pos);
}

L3Q _valueQ(List<int> c, int k, int pos) {
  int ev(int x) => c[0] * x * x + c[1] * x + c[2];
  final right = ev(k);
  final noSquare = c[0] * k + c[1] * k + c[2];
  final signSlip = ev(-k);
  return _q('If p(x) = ${_poly(c)}, find p($k).', '$right',
      ['$noSquare', '$signSlip'], pos);
}

L3Q _addQ(List<int> a, List<int> b, int pos) {
  final s = [for (var i = 0; i < 3; i++) a[i] + b[i]];
  final diff = [for (var i = 0; i < 3; i++) a[i] - b[i]];
  final slip = [s[0], s[1], a[2] - b[2]];
  return _q('Add (${_poly(a)}) and (${_poly(b)}).', _poly(s),
      [_poly(diff), _poly(slip)], pos);
}

L3Q _subQ(List<int> a, List<int> b, int pos) {
  final d = [for (var i = 0; i < 3; i++) a[i] - b[i]];
  final rev = [for (var i = 0; i < 3; i++) b[i] - a[i]];
  final noFlip = [a[0] - b[0], a[1] + b[1], a[2] + b[2]];
  return _q('Subtract (${_poly(b)}) from (${_poly(a)}).', _poly(d),
      [_poly(rev), _poly(noFlip)], pos);
}

L3Q _mulQ(int a, int b, int pos) {
  String lin(int k) => k < 0 ? '(x - ${-k})' : '(x + $k)';
  return _q(
      'Multiply ${lin(a)}${lin(b)}.',
      _poly([1, a + b, a * b]),
      [
        _poly([1, 0, a * b]),
        _poly([1, a + b, -a * b])
      ],
      pos);
}

// ---------------------------------------------------------------- lesson 3

String _eq(int a, int b, int c) => '${a}x + ${b}y = $c';

L3Q _pairQ(int a, int b, int c, int x, int y, int pos) {
  assert(a * x + b * y == c);
  assert(a * y + b * x != c && a * (x + 1) + b * y != c);
  return _q('Which pair (x, y) is a solution of ${_eq(a, b, c)}?', '($x, $y)',
      ['($y, $x)', '(${x + 1}, $y)'], pos);
}

L3Q _findYQ(int a, int b, int c, int x, int pos) {
  assert((c - a * x) % b == 0);
  final y = (c - a * x) ~/ b;
  return _q('In ${_eq(a, b, c)}, if x = $x, what is y?', '$y',
      ['${(c - x) ~/ b}', '${c - a * x}'], pos);
}

L3Q _interceptQ(int a, int b, int c, int pos) {
  assert(c % a == 0 && c % b == 0);
  return _q('At which point does the line ${_eq(a, b, c)} cut the x-axis?',
      '(${c ~/ a}, 0)', ['(0, ${c ~/ b})', '($c, 0)'], pos);
}

// ---------------------------------------------------------------- lesson 4

String _quad(int x, int y) => x > 0 && y > 0
    ? 'First quadrant'
    : x < 0 && y > 0
        ? 'Second quadrant'
        : x < 0 && y < 0
            ? 'Third quadrant'
            : 'Fourth quadrant';

L3Q _quadrantQ(int x, int y, String prompt, int pos) {
  final right = _quad(x, y);
  final wrong = [
    'First quadrant',
    'Second quadrant',
    'Third quadrant',
    'Fourth quadrant'
  ].where((e) => e != right).take(2).toList();
  return _q(prompt, right, wrong, pos);
}

L3Q _axisDistQ(int x, int y, int pos) => _q(
    'What is the distance of the point ($x, $y) from the x-axis?',
    '${y.abs()} units',
    ['${x.abs()} units', '${x.abs() + y.abs()} units'],
    pos);

L3Q _axesGapQ(int x1, int x2, int pos) => _q(
    'Find the distance between the points ($x1, 0) and ($x2, 0).',
    '${(x2 - x1).abs()} units',
    ['${(x2.abs() - x1.abs()).abs()} units', '${x2.abs()} units'],
    pos);

// ---------------------------------------------------------------- lesson 5

L3Q _hypQ(int a, int b, int c, int pos) {
  assert(a * a + b * b == c * c);
  return _q(
      'A right triangle has legs $a cm and $b cm. What is its hypotenuse?',
      '$c cm',
      ['${a + b} cm', '${c * c} cm'],
      pos);
}

L3Q _legQ(int c, int a, int b, int pos) {
  assert(a * a + b * b == c * c);
  return _q(
      'The hypotenuse of a right triangle is $c cm and one leg is $a cm. Find the other leg.',
      '$b cm',
      ['${c - a} cm', '${c + a} cm'],
      pos);
}

L3Q _checkQ(int a, int b, int c, int pos) {
  final right = a * a + b * b == c * c;
  return _q('Is a triangle with sides $a cm, $b cm and $c cm right-angled?',
      right ? 'Yes' : 'No', [right ? 'No' : 'Yes', 'Cannot say'], pos);
}

L3Q _ladderQ(int l, int d, int h, int pos) {
  assert(d * d + h * h == l * l);
  return _q(
      'A $l m ladder leans on a wall with its foot $d m from the wall. How high up the wall does it reach?',
      '$h m',
      ['${l - d} m', '${l + d} m'],
      pos);
}

// ---------------------------------------------------------------- lesson 6

L3Q _thirdAngleQ(int a, int b, int pos) => _q(
    'Triangle ABC is congruent to triangle PQR. In ABC, ∠A = $a° and ∠B = $b°. What is ∠R?',
    '${180 - a - b}°',
    ['${a + b}°', '${180 - a}°'],
    pos);

// ---------------------------------------------------------------- lesson 7

String _list(List<int> d) => d.join(', ');

String _half(int twice) => twice.isEven ? '${twice ~/ 2}' : '${twice ~/ 2}.5';

L3Q _meanQ(List<int> d, int pos) {
  final s = d.fold<int>(0, (a, b) => a + b);
  assert(s % d.length == 0);
  final range =
      d.reduce((a, b) => a > b ? a : b) - d.reduce((a, b) => a < b ? a : b);
  return _q('Find the mean of the marks ${_list(d)}.', '${s ~/ d.length} marks',
      ['$s marks', '$range marks'], pos);
}

L3Q _medianOddQ(List<int> d, int pos) {
  final s = List<int>.of(d)..sort();
  final mid = s[s.length ~/ 2];
  final unsortedMid = d[d.length ~/ 2];
  final upper = s[s.length ~/ 2 + 1];
  assert(unsortedMid != mid && upper != mid && unsortedMid != upper);
  return _q('Find the median of the marks ${_list(d)}.', '$mid marks',
      ['$unsortedMid marks', '$upper marks'], pos);
}

L3Q _modeQ(List<int> d, int pos) {
  final counts = <int, int>{};
  for (final v in d) {
    counts.update(v, (c) => c + 1, ifAbsent: () => 1);
  }
  final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  final others = counts.keys.where((k) => k != top.key).toList()..sort();
  final s = d.fold<int>(0, (a, b) => a + b);
  assert(counts.values.where((c) => c == top.value).length == 1);
  return _q(
      'Runs scored in ${d.length} matches: ${_list(d)}. What is the mode?',
      '${top.key} runs',
      ['${others.last} runs', '${s ~/ d.length} runs'],
      pos);
}

L3Q _freqTotalQ(List<int> f, int pos) {
  final s = f.fold<int>(0, (a, b) => a + b);
  return _q(
      'A frequency table has ${f.length} values with frequencies ${_list(f.sublist(0, f.length - 1))} and ${f.last}. How many observations are there?',
      '$s',
      ['${s - f.last}', '${s + f.length}'],
      pos);
}

L3Q _medianEvenQ(List<int> d, int pos) {
  final s = List<int>.of(d)..sort();
  final lo = s[s.length ~/ 2 - 1], hi = s[s.length ~/ 2];
  return _q(
      'The marks of ${d.length} students are ${_list(d.sublist(0, d.length - 1))} and ${d.last}. What is the median?',
      '${_half(lo + hi)} marks',
      ['$lo marks', '$hi marks'],
      pos);
}

// ---------------------------------------------------------------- lesson 8

L3Q _sqPlusQ(int a, int b, int pos) => _q(
    'Using (a + b)² = a² + 2ab + b², find ${a + b}².',
    '${(a + b) * (a + b)}',
    ['${a * a + b * b}', '${a * a + a * b + b * b}'],
    pos);

L3Q _sqMinusQ(int a, int b, int pos) => _q(
    'Using (a - b)² = a² - 2ab + b², find ${a - b}².',
    '${(a - b) * (a - b)}',
    ['${a * a + b * b}', '${a * a - b * b}'],
    pos);

L3Q _diffSqQ(int p, int q, int pos) => _q(
    'Using a² - b² = (a + b)(a - b), find $p² - $q².',
    '${p * p - q * q}',
    ['${p - q}', '${p + q}'],
    pos);

L3Q _sumProdQ(int s, int pr, int pos) => _q(
    'If a + b = $s and ab = $pr, what is a² + b²?',
    '${s * s - 2 * pr}',
    ['${s * s - pr}', '${s * s + 2 * pr}'],
    pos);

L3Q _expandQ(int k, int pos) => _q(
    'Expand (x - $k)² using an identity.',
    _poly([1, -2 * k, k * k]),
    [
      _poly([1, 0, k * k]),
      _poly([1, -k, k * k])
    ],
    pos);

// ---------------------------------------------------------------- lesson 9

L3Q _coneVolQ(int r, int h, int pos) {
  assert((22 * r * r * h) % 21 == 0);
  final v = 22 * r * r * h ~/ 21;
  return _q(
      'A cone has base radius $r cm and height $h cm. What is its volume? (Use π = 22/7)',
      '$v cm³',
      ['${3 * v} cm³', '${4 * v} cm³'],
      pos);
}

L3Q _sphereAreaQ(int r, int pos) {
  assert((88 * r * r) % 7 == 0);
  final a = 88 * r * r ~/ 7;
  return _q(
      'A sphere has radius $r cm. What is its surface area? (Use π = 22/7)',
      '$a cm²',
      ['${a ~/ 4} cm²', '${a ~/ 2} cm²'],
      pos);
}

L3Q _sphereVolQ(int r, int pos) {
  assert((88 * r * r * r) % 21 == 0);
  final v = 88 * r * r * r ~/ 21;
  return _q('A sphere has radius $r cm. What is its volume? (Use π = 22/7)',
      '$v cm³', ['${v ~/ 2} cm³', '${88 * r * r ~/ 7} cm³'], pos);
}

L3Q _coneCsaQ(int r, int l, int pos) {
  assert((22 * r * l) % 7 == 0);
  final a = 22 * r * l ~/ 7;
  return _q(
      'A cone has base radius $r cm and slant height $l cm. What is its curved surface area? (Use π = 22/7)',
      '$a cm²',
      ['${2 * a} cm²', '${22 * r * r ~/ 7} cm²'],
      pos);
}

// --------------------------------------------------------------- lesson 10

L3Q _bagQ(int red, int blue, int green, int pos) {
  final t = red + blue + green;
  return _q(
      'A bag has $red red, $blue blue and $green green balls. One ball is drawn at random. What is the probability that it is red?',
      _fr(red, t),
      [_fr(red, blue + green), _fr(red, blue)],
      pos);
}

L3Q _dieQ(int pos) {
  // primes on a die: 2, 3, 5 -> 3/6; counting 1 as prime gives 4/6.
  return _q(
      'A fair die is rolled. What is the probability of getting a prime number?',
      _fr(3, 6),
      [_fr(4, 6), _fr(1, 6)],
      pos);
}

L3Q _coinQ(int n, int h, int pos) => _q(
    'A coin was tossed $n times and showed heads $h times. What is the experimental probability of heads?',
    _fr(h, n),
    [_fr(h, n - h), _fr(1, 2)],
    pos);

L3Q _notRedQ(int red, int white, int pos) => _q(
    'A bag has $red red and $white white balls. What is the probability of NOT drawing a red ball?',
    _fr(white, red + white),
    [_fr(red, red + white), _fr(white, red)],
    pos);
