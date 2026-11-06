import 'batch_lesson.dart';
import 'level3_support.dart';

/// Level 7 numbers: 10 lessons (numbers-l7-001 .. 010), about age 14 (Class 8).
/// Uses `ageBand: '10-12', level: 7` (levels above 5 have no age band of their
/// own).
///
/// All arithmetic is done with integers in code (answers are correct by
/// construction) and distractors are typical mistakes. Geometry facts and the
/// proportion-type item are hand-set. test/level7_numbers_test.dart recomputes
/// every answer from the prompt text.
final List<BatchLesson> numbersLevel7Lessons = List.unmodifiable(<BatchLesson>[
  _lesson(
    1,
    'Exponents',
    'Use the laws of exponents.',
    'exponents',
    'laws of exponents',
    'a^n means a multiplied n times. Same base: add powers to multiply, '
        'subtract to divide, and a^0 = 1.',
    '2^3 x 2^4 = 2^7',
    [
      _powerQ(3, 4, 1),
      _mulPowQ(5, 3, 4, 2),
      _divPowQ(7, 9, 4, 0),
      _powPowQ(2, 3, 4, 1),
      _zeroQ(9, 2),
    ],
  ),
  _lesson(
    2,
    'Squares, roots and cubes',
    'Find squares, square roots, cubes and cube roots.',
    'powers',
    'squares, roots and cubes',
    '12 squared is 144, so the square root of 144 is 12. 3 cubed is 27, so '
        'the cube root of 27 is 3.',
    '12² = 144',
    [
      _squareQ(17, 0),
      _sqrtQ(196, 2),
      _cubeQ(6, 1),
      _perfectSquareQ(225, [220, 230], 0),
      _cbrtQ(729, 2),
    ],
  ),
  _lesson(
    3,
    'Equations with x on both sides',
    'Solve linear equations with x on both sides.',
    'algebra',
    'linear equations',
    'Move x terms to one side and numbers to the other, changing signs as '
        'you cross =. 3x + 2 = x + 8 gives 2x = 6, x = 3.',
    '3x + 2 = x + 8',
    [
      _eqQ(5, 5, 3, 2, false, 2),
      _eqQ(3, 7, -4, 3, false, 0),
      _eqWordQ(6, 4, 5, 2, 1),
      _eqQ(4, 9, -7, 4, false, 2),
      _eqQ(7, 6, 2, 3, true, 1),
    ],
  ),
  _lesson(
    4,
    'Factorisation',
    'Factorise using a common factor and a² - b².',
    'algebra',
    'factorisation',
    'Take out the common factor: 6x + 9 = 3(2x + 3). Difference of squares: '
        'a² - b² = (a + b)(a - b).',
    'a² - b² = (a + b)(a - b)',
    [
      _commonQ(3, 2, 3, true, 1),
      _diffSqQ(1, 7, 0),
      _hcfQ(14, 21, 2),
      _commonQ(5, 3, 2, false, 0),
      _diffSqQ(2, 5, 2),
    ],
  ),
  _lesson(
    5,
    'Direct and inverse proportion',
    'Solve direct and inverse proportion problems.',
    'proportion',
    'direct and inverse proportion',
    'Direct: both rise together, so the ratio stays fixed. Inverse: one rises '
        'as the other falls, so the product stays fixed.',
    '5 notebooks : ₹60',
    [
      _directQ(5, 60, 8, 1),
      _inverseWorkersQ(6, 12, 9, 2),
      _hand(
          'Which pair of quantities is in inverse proportion?',
          'Speed and time taken for a fixed distance',
          [
            'Number of pens and their total cost',
            'Length of cloth and its price'
          ],
          0),
      _directKmQ(90, 2, 5, 2),
      _inverseSpeedQ(40, 6, 60, 0),
    ],
  ),
  _lesson(
    6,
    'Compound interest',
    'Find the amount and compound interest for 2 years.',
    'money',
    'compound interest',
    'Compound interest is charged on interest too. Amount = P x (1 + r/100)^2 '
        'for 2 years, and CI = Amount - P.',
    '₹5,000 at 10% for 2 years',
    [
      _ciQ(5000, 10, 1),
      _amountQ(4000, 10, 0),
      _ciQ(8000, 5, 2),
      _diffQ(10000, 8, 1),
      _amountQ(2500, 20, 2),
    ],
  ),
  _lesson(
    7,
    'Polygons and quadrilaterals',
    'Use angle sums and properties of quadrilaterals.',
    'geometry',
    'polygon angles',
    'Angles of an n-sided polygon add up to (n - 2) x 180°. A quadrilateral '
        'adds to 360°. Parallelogram diagonals bisect.',
    '(n - 2) x 180°',
    [
      _polySumQ('pentagon', 5, 0),
      _extAngleQ(9, 2),
      _quadMissingQ(80, 95, 75, 1),
      _hand(
          'A quadrilateral has four equal sides and equal opposite angles, but '
              'no right angles. What is it called?',
          'Rhombus',
          ['Rectangle', 'Trapezium'],
          1),
      _hand(
          'Which is always true for the diagonals of a parallelogram?',
          'They bisect each other',
          ['They are equal in length', 'They meet at right angles'],
          2),
    ],
  ),
  _lesson(
    8,
    'Surface area and volume',
    'Find the volume and surface area of a cuboid and a cylinder.',
    'mensuration',
    'cuboid and cylinder',
    'Cuboid: volume = lbh, surface area = 2(lb + bh + hl). Cylinder: volume = '
        'πr²h, curved area = 2πrh, with π = 22/7.',
    'V = πr²h',
    [
      _cuboidVolQ(12, 5, 4, 2),
      _cuboidAreaQ(8, 5, 3, 0),
      _cylVolQ(7, 10, 1),
      _cylCurvedQ(7, 15, 2),
      _tankQ(100, 60, 50, 0),
    ],
  ),
  _lesson(
    9,
    'Data handling and averages',
    'Read tables and bar graphs, and find averages.',
    'data',
    'tables and averages',
    'Mean = sum ÷ number of items. Median = middle value of the sorted list '
        '(average the two middle ones if there are two).',
    'mean = sum ÷ count',
    [
      _meanQ([11, 14, 18, 20, 12], 1),
      _medianQ([8, 3, 20, 5], 2),
      _barQ('Asha', 14, 'Ravi', 9, 'Meena', 17, 'Kabir', 12, 0),
      _tableQ({'Mon': 40, 'Tue': 55, 'Wed': 35, 'Thu': 60}, 1),
      _missingQ('Asha', 13, 16, 17, 15, 2),
    ],
  ),
  _lesson(
    10,
    'Probability',
    'Find the probability of simple events.',
    'probability',
    'simple probability',
    'Probability = favourable outcomes ÷ all equally likely outcomes. It lies '
        'from 0 (impossible) to 1 (certain).',
    'P = favourable ÷ total',
    [
      _bagQ(3, 5, 2, 0),
      _dieMultipleQ(3, 2),
      _hand(
          'A bag has only red balls. What is the probability of drawing a '
              'green ball?',
          '0',
          ['1', '1/2'],
          1),
      _cardsQ(20, 5, 1),
      _notQ(2, 7, 2),
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
      id: 'numbers-l7-${no.toString().padLeft(3, '0')}',
      module: 'numbers',
      title: title,
      objective: objective,
      topic: topic,
      skill: skill,
      teach: teach,
      examples: [example],
      questions: questions,
      ageBand: '10-12',
      level: 7,
    );

// ---------------------------------------------------------------- helpers

/// Builds a question with the answer placed at [pos] among three options.
L3Q _mc(String prompt, String answer, List<String> wrong, int pos) {
  final w = <String>[];
  for (final x in wrong) {
    if (x != answer && !w.contains(x)) w.add(x);
  }
  if (w.length < 2) throw StateError('Not enough distractors: $prompt');
  final options = w.take(2).toList()..insert(pos, answer);
  return L3Q(prompt, options, answer);
}

/// A hand-set item (geometry facts, proportion type, impossible event).
L3Q _hand(String prompt, String answer, List<String> wrong, int pos) =>
    _mc(prompt, answer, wrong, pos);

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

int _pow(int b, int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= b;
  }
  return r;
}

const _sups = '⁰¹²³⁴⁵⁶⁷⁸⁹';

String _sup(int n) =>
    n.toString().split('').map((c) => _sups[int.parse(c)]).join();

String _comma(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String _rs(int n) => '₹${_comma(n)}';

/// n/d in lowest terms; a whole number when d divides n.
String _rat(int n, int d) {
  if (d < 0) {
    n = -n;
    d = -d;
  }
  final g = _gcd(n.abs(), d);
  n ~/= g;
  d ~/= g;
  return d == 1 ? '$n' : '$n/$d';
}

// ------------------------------------------------------------ lesson 1

L3Q _powerQ(int a, int n, int pos) => _mc(
      'What is $a${_sup(n)}?',
      '${_pow(a, n)}',
      ['${a * n}', '${_pow(n, a)}', '${_pow(a, n - 1)}'],
      pos,
    );

L3Q _mulPowQ(int a, int m, int n, int pos) => _mc(
      'Write $a${_sup(m)} × $a${_sup(n)} as a single power of $a.',
      '$a${_sup(m + n)}',
      ['$a${_sup(m * n)}', '${a * a}${_sup(m + n)}', '$a${_sup(n - m)}'],
      pos,
    );

L3Q _divPowQ(int a, int m, int n, int pos) => _mc(
      'Write $a${_sup(m)} ÷ $a${_sup(n)} as a single power of $a.',
      '$a${_sup(m - n)}',
      ['$a${_sup(m + n)}', '1${_sup(m - n)}', '$a${_sup(m * n)}'],
      pos,
    );

L3Q _powPowQ(int a, int m, int n, int pos) => _mc(
      'Simplify ($a${_sup(m)})${_sup(n)} and write it as a power of $a.',
      '$a${_sup(m * n)}',
      ['$a${_sup(m + n)}', '$a${_sup(_pow(m, n))}', '${a * a}${_sup(m * n)}'],
      pos,
    );

L3Q _zeroQ(int a, int pos) =>
    _mc('What is $a${_sup(0)}?', '1', ['0', '$a'], pos);

// ------------------------------------------------------------ lesson 2

L3Q _squareQ(int n, int pos) => _mc(
      'What is $n²?',
      '${n * n}',
      ['${2 * n}', '${n * n - 10}', '${n * n + 10}'],
      pos,
    );

L3Q _sqrtQ(int sq, int pos) {
  var r = 0;
  while (r * r < sq) {
    r++;
  }
  if (r * r != sq) throw StateError('not a square $sq');
  return _mc('What is the square root of $sq?', '$r',
      ['${sq ~/ 2}', '${r + 2}', '${r - 1}'], pos);
}

L3Q _cubeQ(int n, int pos) => _mc(
      'What is $n³?',
      '${n * n * n}',
      ['${3 * n}', '${n * n}', '${n * n * n + n}'],
      pos,
    );

bool _isSquare(int n) {
  for (var i = 0; i * i <= n; i++) {
    if (i * i == n) return true;
  }
  return false;
}

L3Q _perfectSquareQ(int sq, List<int> non, int pos) {
  if (!_isSquare(sq) || non.any(_isSquare)) throw StateError('square $sq');
  return _mc('Which number is a perfect square?', '$sq',
      non.map((x) => '$x').toList(), pos);
}

L3Q _cbrtQ(int cube, int pos) {
  var r = 0;
  while (r * r * r < cube) {
    r++;
  }
  if (r * r * r != cube) throw StateError('not a cube $cube');
  return _mc('What is the cube root of $cube?', '$r',
      ['${cube ~/ 3}', '${3 * r}', '${cube ~/ 9}'], pos);
}

// ------------------------------------------------------------ lesson 3

/// ax + b = cx + d, with x the whole-number solution; d is worked out here.
L3Q _eqQ(int x, int a, int b, int c, bool which, int pos) {
  final d = (a - c) * x + b;
  if (d <= 0 || a <= c) throw StateError('equation');
  final eq = '${a}x ${b >= 0 ? '+' : '-'} ${b.abs()} = ${c}x + $d';
  return _mc(
    which ? 'Which value of x satisfies $eq?' : 'Solve for x: $eq',
    'x = $x',
    [
      'x = ${_rat(d + b, a - c)}',
      'x = ${_rat(d - b, a + c)}',
      'x = ${x + 1}',
    ],
    pos,
  );
}

L3Q _eqWordQ(int x, int a, int b, int c, int pos) {
  final d = (a - c) * x + b;
  return _mc(
    'A number is multiplied by $a and $b is added. The result equals the '
        'number multiplied by $c, plus $d. Find the number.',
    '$x',
    [_rat(d - b, a + c), _rat(d + b, a - c), '${x + 1}'],
    pos,
  );
}

// ------------------------------------------------------------ lesson 4

String _cx(int k) => k == 1 ? 'x' : '${k}x';

L3Q _commonQ(int g, int p, int q, bool plus, int pos) {
  final s = plus ? '+' : '-';
  return _mc(
    'Factorise ${g * p}x $s ${g * q}.',
    '$g(${p}x $s $q)',
    [
      '$g(${p}x $s ${g * q})',
      '${g * p}(x $s $q)',
      '$g(${g}x $s $q)',
    ],
    pos,
  );
}

L3Q _diffSqQ(int k, int r, int pos) {
  final lead = k == 1 ? '' : '${k * k}';
  final t = _cx(k);
  return _mc(
    'Factorise $lead' 'x² - ${r * r}.',
    '($t + $r)($t - $r)',
    [
      '($t - $r)($t - $r)',
      '($t + $r)($t + $r)',
      '($t + ${r * r})($t - 1)',
    ],
    pos,
  );
}

L3Q _hcfQ(int a, int b, int pos) {
  final g = _gcd(a, b);
  return _mc('What is the highest common factor of ${a}a and $b?', '$g',
      ['$a', '${g ~/ 7 + 2}'], pos);
}

// ------------------------------------------------------------ lesson 5

L3Q _directQ(int n1, int price, int n2, int pos) {
  if (price % n1 != 0) throw StateError('direct');
  final ans = price ~/ n1 * n2;
  return _mc(
    '$n1 notebooks cost ₹$price. What is the cost of $n2 notebooks?',
    '₹$ans',
    ['₹${price + n2 - n1}', '₹${price * n2}', '₹${ans - price ~/ n1}'],
    pos,
  );
}

L3Q _inverseWorkersQ(int w1, int days, int w2, int pos) {
  if (w1 * days % w2 != 0 || days * w2 % w1 != 0) throw StateError('inverse');
  final ans = w1 * days ~/ w2;
  return _mc(
    '$w1 workers finish a job in $days days. If $w2 workers of the same '
        'speed do it, how many days will it take?',
    '$ans days',
    ['${days + w2 - w1} days', '${days * w2 ~/ w1} days'],
    pos,
  );
}

L3Q _directKmQ(int km, int h1, int h2, int pos) {
  if (km % h1 != 0) throw StateError('km');
  final ans = km ~/ h1 * h2;
  return _mc(
    'A car moves at a steady speed and covers $km km in $h1 hours. How far '
        'will it go in $h2 hours?',
    '$ans km',
    ['${km + h2 - h1} km', '${km * h2} km', '${ans - km ~/ h1} km'],
    pos,
  );
}

L3Q _inverseSpeedQ(int s1, int t1, int s2, int pos) {
  if (s1 * t1 % s2 != 0 || t1 * s2 % s1 != 0) throw StateError('speed');
  final ans = s1 * t1 ~/ s2;
  return _mc(
    'A bus at $s1 km/h takes $t1 hours for a trip. How long will it take at '
        '$s2 km/h?',
    '$ans hours',
    ['${t1 * s2 ~/ s1} hours', '$t1 hours'],
    pos,
  );
}

// ------------------------------------------------------------ lesson 6

int _amount(int p, int r) {
  final n = p * (100 + r) * (100 + r);
  if (n % 10000 != 0) throw StateError('amount $p $r');
  return n ~/ 10000;
}

int _si(int p, int r) {
  if (p * r * 2 % 100 != 0) throw StateError('si $p $r');
  return p * r * 2 ~/ 100;
}

L3Q _ciQ(int p, int r, int pos) {
  final a = _amount(p, r);
  final ci = a - p;
  final second = ci - p * r ~/ 100;
  return _mc(
    'Find the compound interest on ${_rs(p)} for 2 years at $r% per annum, '
    'compounded yearly.',
    _rs(ci),
    [_rs(_si(p, r)), _rs(a), _rs(second)],
    pos,
  );
}

L3Q _amountQ(int p, int r, int pos) {
  final a = _amount(p, r);
  return _mc(
    'What is the amount on ${_rs(p)} for 2 years at $r% per annum, compounded '
    'yearly?',
    _rs(a),
    [_rs(p + _si(p, r)), _rs(a - p), _rs(p * (100 + r) ~/ 100)],
    pos,
  );
}

L3Q _diffQ(int p, int r, int pos) {
  final ci = _amount(p, r) - p;
  final si = _si(p, r);
  return _mc(
    'What is the difference between the compound interest and the simple '
    'interest on ${_rs(p)} for 2 years at $r% per annum?',
    _rs(ci - si),
    [_rs(ci), _rs(si), _rs(2 * (ci - si))],
    pos,
  );
}

// ------------------------------------------------------------ lesson 7

L3Q _polySumQ(String name, int n, int pos) => _mc(
      'What is the sum of the interior angles of a $name?',
      '${(n - 2) * 180}°',
      ['${n * 180}°', '${(n - 1) * 180}°', '${(n - 2) * 90}°'],
      pos,
    );

L3Q _extAngleQ(int n, int pos) {
  if (360 % n != 0 || 180 % n != 0) throw StateError('ext');
  final e = 360 ~/ n;
  return _mc(
    'Each exterior angle of a regular polygon with $n sides measures how '
        'many degrees?',
    '$e°',
    ['${180 - e}°', '${180 ~/ n}°', '${360 ~/ (n + 1)}°'],
    pos,
  );
}

L3Q _quadMissingQ(int a, int b, int c, int pos) {
  final s = a + b + c;
  return _mc(
    'Three angles of a quadrilateral are $a°, $b° and $c°. What is the '
        'fourth angle?',
    '${360 - s}°',
    ['${360 - a - b}°', '${360 - s + 10}°', '$s°'],
    pos,
  );
}

// ------------------------------------------------------------ lesson 8

L3Q _cuboidVolQ(int l, int b, int h, int pos) => _mc(
      'A cuboid is $l cm long, $b cm wide and $h cm high. What is its volume?',
      '${l * b * h} cm³',
      [
        '${l * b} cm³',
        '${2 * (l * b + b * h + h * l)} cm³',
        '${l + b + h} cm³'
      ],
      pos,
    );

L3Q _cuboidAreaQ(int l, int b, int h, int pos) => _mc(
      'A cuboid is $l cm long, $b cm wide and $h cm high. What is its total '
          'surface area?',
      '${2 * (l * b + b * h + h * l)} cm²',
      [
        '${l * b + b * h + h * l} cm²',
        '${l * b * h} cm²',
        '${2 * (l + b) * h} cm²'
      ],
      pos,
    );

L3Q _cylVolQ(int r, int h, int pos) {
  if (r % 7 != 0) throw StateError('r');
  return _mc(
    'A cylinder has radius $r cm and height $h cm. Using π = 22/7, what is '
        'its volume?',
    '${22 * r * r * h ~/ 7} cm³',
    [
      '${2 * 22 * r * h ~/ 7} cm³',
      '${22 * r * r ~/ 7} cm³',
      '${22 * r * h ~/ 7} cm³'
    ],
    pos,
  );
}

L3Q _cylCurvedQ(int r, int h, int pos) {
  if (r % 7 != 0) throw StateError('r');
  return _mc(
    'A cylinder has radius $r cm and height $h cm. Using π = 22/7, what is '
        'its curved surface area?',
    '${2 * 22 * r * h ~/ 7} cm²',
    [
      '${22 * r * r * h ~/ 7} cm²',
      '${2 * 22 * r * (r + h) ~/ 7} cm²',
    ],
    pos,
  );
}

L3Q _tankQ(int l, int b, int h, int pos) {
  final cm3 = l * b * h;
  if (cm3 % 1000 != 0) throw StateError('tank');
  return _mc(
    'A tank is $l cm long, $b cm wide and $h cm high. How many litres of '
        'water can it hold? (1 L = 1000 cm³)',
    '${cm3 ~/ 1000} L',
    ['$cm3 L', '${cm3 ~/ 10000} L'],
    pos,
  );
}

// ------------------------------------------------------------ lesson 9

String _list(List<int> v) =>
    '${v.sublist(0, v.length - 1).join(', ')} and ${v.last}';

L3Q _meanQ(List<int> v, int pos) {
  final s = v.fold<int>(0, (a, b) => a + b);
  if (s % v.length != 0) throw StateError('mean');
  final sorted = [...v]..sort();
  return _mc(
    'The marks of five students are ${_list(v)}. What is the mean mark?',
    '${s ~/ v.length}',
    ['$s', '${sorted[v.length ~/ 2]}', '${s ~/ v.length + 1}'],
    pos,
  );
}

String _half(int twice) => twice.isEven ? '${twice ~/ 2}' : '${twice ~/ 2}.5';

L3Q _medianQ(List<int> v, int pos) {
  final s = [...v]..sort();
  final med = s[1] + s[2];
  final mean = v.fold<int>(0, (a, b) => a + b);
  return _mc(
    'The number of books read by four students are ${_list(v)}. What is the '
    'median?',
    _half(med),
    [
      _half(v[1] + v[2]),
      mean % 4 == 0 ? '${mean ~/ 4}' : _rat(mean, 4),
      '${med ~/ 2 + 1}',
    ],
    pos,
  );
}

L3Q _barQ(String n1, int v1, String n2, int v2, String n3, int v3, String n4,
    int v4, int pos) {
  final vals = [v1, v2, v3, v4]..sort();
  return _mc(
    'A bar graph shows books read by four children: $n1 $v1, $n2 $v2, '
        '$n3 $v3, $n4 $v4. How many did the two lowest readers read together?',
    '${vals[0] + vals[1]}',
    [
      '${vals[2] + vals[3]}',
      '${vals[0] + vals[3]}',
      '${vals.fold<int>(0, (a, b) => a + b)}',
    ],
    pos,
  );
}

L3Q _tableQ(Map<String, int> rows, int pos) {
  final v = rows.values.toList()..sort();
  return _mc(
    'Tickets sold: ${rows.entries.map((e) => '${e.key} ${e.value}').join(', ')}. '
        'What is the difference between the best day and the worst day?',
    '${v.last - v.first}',
    [
      '${v.last + v.first}',
      '${v.last - rows.values.first}',
      '${v.last - v[v.length - 2]}',
    ],
    pos,
  );
}

L3Q _missingQ(String who, int a, int b, int c, int avg, int pos) {
  final need = avg * 4 - a - b - c;
  return _mc(
    '$who scored $a, $b and $c in three tests. What must she score in the '
        'fourth test to have an average of $avg?',
    '$need',
    ['$avg', '${avg * 4}', '${need + 1}'],
    pos,
  );
}

// ----------------------------------------------------------- lesson 10

L3Q _bagQ(int r, int b, int g, int pos) => _mc(
      'A bag has $r red, $b blue and $g green balls. One ball is drawn at '
      'random. What is the probability that it is red?',
      _rat(r, r + b + g),
      [_rat(r, b + g), _rat(1, 3), _rat(r, b)],
      pos,
    );

L3Q _dieMultipleQ(int k, int pos) {
  final n = [
    for (var i = 1; i <= 6; i++)
      if (i % k == 0) i
  ].length;
  return _mc(
    'A fair die is rolled once. What is the probability of getting a multiple '
    'of $k?',
    _rat(n, 6),
    ['1/2', '1/6', '2/3'],
    pos,
  );
}

L3Q _cardsQ(int total, int k, int pos) {
  final n = [
    for (var i = 1; i <= total; i++)
      if (i % k == 0) i
  ].length;
  return _mc(
    'A card is drawn at random from cards numbered 1 to $total. What is the '
    'probability that the number is divisible by $k?',
    _rat(n, total),
    [_rat(1, k - 1), _rat(1, total), _rat(n, k)],
    pos,
  );
}

L3Q _notQ(int n, int d, int pos) => _mc(
      'The probability that it rains tomorrow is $n/$d. What is the '
      'probability that it does not rain?',
      _rat(d - n, d),
      [_rat(n, d - n), _rat(1, d), _rat(d, d - n)],
      pos,
    );
