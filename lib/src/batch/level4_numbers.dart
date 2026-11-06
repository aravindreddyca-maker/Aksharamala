import 'batch_lesson.dart';
import 'level3_support.dart';

/// Level 4 numbers: 15 lessons (numbers-l4-001 .. 015), ages 10-12
/// (`ageBand: '10-12'`).
///
/// Arithmetic answers are computed with integer maths (decimals and money are
/// kept as scaled integers, never doubles), so they are correct by
/// construction. Distractors are typical mistakes. Angle, chart-reading and
/// unit-choice items are hand-set, with their answers still derived in code.
final List<BatchLesson> numbersLevel4Lessons = List.unmodifiable(<BatchLesson>[
  _lesson(
    1,
    'Place value to millions',
    'Read, compare and round large whole numbers.',
    'place value',
    'place value to millions',
    'Each digit has a place value. In 4,506,210 the 4 is 4 million and the 5 is '
        '5 hundred thousand. Compare digits from the left.',
    '4,506,210',
    [
      _valueQ(4506210, 5, 0),
      _signInts(3450120, 3405999, 2),
      _roundBigQ(4506210, 100000, 1),
      _expandQ([3000000, 400000, 5000, 60], 0),
      _roundBigQ(8264731, 1000, 2),
    ],
  ),
  _lesson(
    2,
    'Multi-digit multiplication',
    'Multiply multi-digit whole numbers accurately.',
    'multiplication',
    'multi-digit multiplication',
    'Multiply by the ones digit, then by the tens digit (shift one place left), '
        'then add. 326 x 24 = 1304 + 6520 = 7824.',
    '326 x 24',
    [
      _mulQ(326, 24, 1),
      _mulQ(145, 12, 0),
      _mulQ(48, 37, 2),
      _packsQ(36, 125, 1),
      _mulQ(253, 31, 0),
    ],
  ),
  _lesson(
    3,
    'Long division',
    'Divide larger whole numbers, with remainders.',
    'division',
    'long division with remainders',
    'Divide, multiply, subtract, bring down. 936 ÷ 12 = 78. What is left '
        'over is the remainder (r).',
    '936 ÷ 12',
    [
      _divQ(936, 12, 2),
      _divQ(457, 12, 1),
      _divQ(853, 25, 0),
      _divQ(1000, 14, 2),
      _divQ(648, 18, 1),
    ],
  ),
  _lesson(
    4,
    'Factors and multiples',
    'Identify factors, multiples and prime numbers.',
    'number theory',
    'factors, multiples and primes',
    'A factor divides a number exactly: 1, 2, 3, 4, 6, 8, 12 and 24 are the '
        'factors of 24. A prime has only two factors.',
    'Factors of 24',
    [
      _factorQ(36, 9, [8, 14], 0),
      _multipleQ(7, 56, [45, 51], 1),
      _primeQ(29, [27, 33], 2),
      _countFactorsQ(20, 0),
      _nthMultipleQ(6, 7, 1),
    ],
  ),
  _lesson(
    5,
    'Equivalent fractions',
    'Make and simplify equivalent fractions.',
    'fractions',
    'equivalent fractions',
    'Multiply top and bottom by the same number: 2/3 = 4/6. Divide both by '
        'the same number to simplify.',
    '2/3 = 4/6',
    [
      _equalFracQ(2, 3, 2, 1),
      _missingTopQ(3, 4, 12, 2),
      _missingBottomQ(3, 5, 12, 0),
      _simplifyQ(16, 40, 1),
      _compareFracQ(3, 4, 5, 8, 2),
    ],
  ),
  _lesson(
    6,
    'Fraction addition',
    'Add and subtract simple fractions.',
    'fractions',
    'adding and subtracting fractions',
    'Same bottom: add the tops, keep the bottom, 1/4 + 2/4 = 3/4. Different '
        'bottoms: make them equal first, 1/2 = 2/4.',
    '1/4 + 2/4',
    [
      _fracOpQ(1, 4, '+', 2, 4, 2),
      _fracOpQ(7, 9, '-', 2, 9, 0),
      _fracOpQ(1, 2, '+', 1, 6, 1),
      _fracOpQ(3, 4, '-', 1, 8, 2),
      _fracOpQ(5, 6, '-', 1, 3, 0),
    ],
  ),
  _lesson(
    7,
    'Decimals and place value',
    'Read, compare and round decimals.',
    'decimals',
    'decimal place value',
    'Compare decimals from the left: 3.45 has 4 tenths and 3.5 has 5 tenths, '
        'so 3.45 < 3.5. To round, look at the next digit.',
    '3.45 versus 3.5',
    [
      _decDigitQ('6.248', 1, 0),
      _signDec('3.45', '3.5', 2),
      _roundDecQ('4.76', 1, 1),
      _betweenQ('0.4', '0.5', '0.45', ['0.54', '0.35'], 2),
      _roundDecQ('12.347', 2, 0),
    ],
  ),
  _lesson(
    8,
    'Decimal operations',
    'Add and subtract decimals in rupees.',
    'decimals',
    'adding and subtracting decimals',
    'Line up the decimal points, then add or subtract. ₹12.50 + ₹7.25 = '
        '₹19.75.',
    '₹12.50 + ₹7.25',
    [
      _moneyQ('What is ${_rs(1250)} + ${_rs(725)}?', 1250 + 725, 1250 - 725, 1),
      _moneyQ(
          'What is ${_rs(5000)} - ${_rs(1875)}?', 5000 - 1875, 5000 + 1875, 0),
      _moneyQ(
          'A pen costs ${_rs(1475)} and a notebook costs ${_rs(2850)}. '
          'What is the total cost?',
          1475 + 2850,
          2850 - 1475,
          2),
      _moneyQ(
          'Ravi pays ${_rs(10000)} for a bag that costs ${_rs(6340)}. '
          'How much change does he get?',
          10000 - 6340,
          10000 + 6340,
          0),
      _moneyQ('What is ${_rs(560)} + ${_rs(1245)} + ${_rs(330)}?',
          560 + 1245 + 330, 1245 - 560 - 330 + 100, 1),
    ],
  ),
  _lesson(
    9,
    'Percent as hundredths',
    'Connect fractions, decimals and percentages.',
    'percentages',
    'percent as hundredths',
    'Percent means out of 100. 25% = 25/100 = 1/4 = 0.25. To find 25% of 80, '
        'find a quarter of 80.',
    '25% = 1/4',
    [
      _percentFracQ(40, 2),
      _percentDecimalQ(7, 1),
      _percentOfQ(25, 80, 0),
      _classQ(40, 30, 1),
      _fracToPercentQ(7, 20, 2),
    ],
  ),
  _lesson(
    10,
    'Ratio introduction',
    'Write simple part-to-part ratios.',
    'ratio',
    'simple ratios',
    'A ratio compares two amounts. 2 red and 3 blue balls give the ratio '
        '2 : 3 (red to blue). Keep the order you are asked.',
    '2 red : 3 blue',
    [
      _ratioQ(2, 3, 0),
      _simplestRatioQ(12, 8, 1),
      _scaleBeadsQ(3, 4, 4, 2),
      _drinkQ(2, 5, 3, 1),
      _partWholeQ(3, 5, 0),
    ],
  ),
  _lesson(
    11,
    'Angles and measurement',
    'Identify acute, right and obtuse angles.',
    'geometry',
    'angles',
    'An acute angle is less than 90°, a right angle is exactly 90°, and an '
        'obtuse angle is between 90° and 180°.',
    '45°, 90°, 120°',
    [
      _angleTypeQ(45, 1),
      _angleTypeQ(120, 2),
      _straightQ(65, 0),
      _typeQ('The corner of a book is what kind of angle?', 'Right', 2),
      _mc('Which of these angles is obtuse?', '110°', ['75°', '90°'], 1),
    ],
  ),
  _lesson(
    12,
    'Perimeter and area',
    'Calculate the perimeter and area of rectangles.',
    'measurement',
    'perimeter and area',
    'Perimeter is the distance around: 2 x (length + width). Area is the '
        'space inside: length x width. 6 x 4 = 24 cm².',
    '6 cm x 4 cm',
    [
      _perimeterQ(7, 5, 2),
      _areaQ(8, 5, 0),
      _fenceQ(15, 9, 1),
      _squareAreaQ(9, 0),
      _widthQ(48, 8, 2),
    ],
  ),
  _lesson(
    13,
    'Units and conversions',
    'Convert within metric length, mass and capacity.',
    'measurement',
    'metric conversions',
    '1 m = 100 cm, 1 km = 1000 m, 1 kg = 1000 g, 1 L = 1000 mL. Big to small: '
        'multiply. Small to big: divide.',
    '1 m = 100 cm',
    [
      _convertUpQ('cm', 'm', 100, 7, 0),
      _convertUpQ('g', 'kg', 1000, 3, 2),
      _convertUpQ('m', 'km', 1000, 5, 1),
      _convertDownQ('m', 'cm', 100, 600, 1),
      _convertDownQ('kg', 'g', 1000, 2500, 2),
    ],
  ),
  _lesson(
    14,
    'Tables and bar charts',
    'Read and compare values in a small table.',
    'data',
    'reading tables and charts',
    'A bar chart shows each group as a bar. Read the numbers, then add or '
        'subtract to answer. 12 + 8 = 20.',
    'Favourite fruit survey',
    [
      _totalQ(
          'Votes for favourite fruit',
          {'Mango': 12, 'Apple': 8, 'Banana': 15, 'Orange': 5},
          'How many children voted in all?',
          1),
      _moreQ('Pets owned by the class',
          {'Dogs': 9, 'Cats': 14, 'Fish': 6, 'Birds': 3}, 'Cats', 'Dogs', 0),
      _fewestDayQ('Books read this week',
          {'Mon': 4, 'Tue': 7, 'Wed': 3, 'Thu': 9, 'Fri': 6}, 2),
      _moreQ(
          'Favourite sport',
          {'Football': 18, 'Cricket': 25, 'Kabaddi': 12, 'Hockey': 9},
          'Cricket',
          'Hockey',
          2,
          children: true),
      _togetherQ('Rainfall (mm)',
          {'Jun': 120, 'Jul': 210, 'Aug': 180, 'Sep': 90}, 'Jul', 'Aug', 0),
    ],
  ),
  _lesson(
    15,
    'Multi-step word problems',
    'Solve two-step real-world problems.',
    'problem solving',
    'two-step word problems',
    'Read carefully and split the problem into steps. Step 1: find the total '
        'cost. Step 2: subtract it from the money paid.',
    'Shopping with change',
    [
      _changeQ('Asha', 3, 'notebooks', 45, 200, 2),
      _shopLeftQ(240, 90, 70, 1),
      _emptySeatsQ(5, 48, 212, 0),
      _saveQ(25, 12, 120, 0),
      _packCostQ(6, 90, 9, 1),
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
      id: 'numbers-l4-${no.toString().padLeft(3, '0')}',
      module: 'numbers',
      title: title,
      objective: objective,
      topic: topic,
      skill: skill,
      teach: teach,
      examples: [example],
      questions: questions,
      ageBand: '10-12',
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

String _comma(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

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

/// Rupees from paise, always two decimals.
String _rs(int paise) =>
    '₹${paise ~/ 100}.${(paise % 100).toString().padLeft(2, '0')}';

L3Q _signQ(String a, String b, int cmp, int pos) {
  final ans = cmp < 0 ? '<' : (cmp > 0 ? '>' : '=');
  final wrong = ['<', '>', '='].where((s) => s != ans).toList();
  return _mc('Which sign fits? $a ? $b', ans, wrong, pos);
}

// ------------------------------------------------------------ lesson 1

L3Q _valueQ(int n, int d, int pos) {
  final s = n.toString();
  if (s.indexOf('$d') != s.lastIndexOf('$d')) throw StateError('repeat digit');
  final place = _p10(s.length - 1 - s.indexOf('$d'));
  return _mc(
    'What is the value of the digit $d in ${_comma(n)}?',
    _comma(d * place),
    [_comma(d * place * 10), _comma(d * place ~/ 10), '$d'],
    pos,
  );
}

L3Q _signInts(int a, int b, int pos) =>
    _signQ(_comma(a), _comma(b), a.compareTo(b), pos);

L3Q _roundBigQ(int n, int unit, int pos) {
  const names = {
    1000: 'thousand',
    10000: 'ten thousand',
    100000: 'hundred thousand',
    1000000: 'million',
  };
  int round(int u) {
    final fl = n ~/ u * u;
    return (n - fl) * 2 >= u ? fl + u : fl;
  }

  final fl = n ~/ unit * unit;
  return _mc(
    'Round ${_comma(n)} to the nearest ${names[unit]}.',
    _comma(round(unit)),
    [
      _comma(fl + unit),
      _comma(fl),
      _comma(round(unit * 10)),
      _comma(round(unit ~/ 10))
    ],
    pos,
  );
}

L3Q _expandQ(List<int> t, int pos) {
  final ans = t.fold<int>(0, (a, b) => a + b);
  return _mc(
    'What is ${t.map(_comma).join(' + ')}?',
    _comma(ans),
    [
      _comma(ans + t[2] * 9),
      _comma(ans + t.last * 9),
      _comma(ans - t[1] + t[1] ~/ 10),
    ],
    pos,
  );
}

// ------------------------------------------------------------ lesson 2

L3Q _mulQ(int a, int b, int pos) {
  final tens = b ~/ 10, ones = b % 10;
  final ans = a * b;
  return _mc(
    'What is $a x $b?',
    '$ans',
    [
      '${a * ones + a * tens}',
      '${a * ones + a * tens * 100}',
      '${ans + 100}',
      '${ans - 10}',
    ],
    pos,
  );
}

L3Q _packsQ(int boxes, int each, int pos) {
  final ans = boxes * each;
  return _mc(
    'A school buys $boxes boxes with $each chalks each. '
        'How many chalks in all?',
    '$ans',
    ['${boxes + each}', '${ans + 1000}', '${ans - 100}'],
    pos,
  );
}

// ------------------------------------------------------------ lesson 3

String _qr(int q, int r) => r == 0 ? '$q' : '$q r $r';

L3Q _divQ(int n, int d, int pos) {
  final q = n ~/ d, r = n % d;
  final r2 = r + 1 < d ? r + 1 : r - 1;
  return _mc(
    'What is $n ÷ $d? Write r for any remainder.',
    _qr(q, r),
    [
      _qr(q + 1, r),
      _qr(q, r2),
      _qr(q - 1, r),
      if (r > 0) _qr(q, d - r),
      _qr(q + 10, r),
    ],
    pos,
  );
}

// ------------------------------------------------------------ lesson 4

bool _isPrime(int n) {
  if (n < 2) return false;
  for (var i = 2; i * i <= n; i++) {
    if (n % i == 0) return false;
  }
  return true;
}

L3Q _factorQ(int n, int f, List<int> non, int pos) {
  if (n % f != 0 || non.any((x) => n % x == 0)) throw StateError('factor $n');
  return _mc('Which number is a factor of $n?', '$f',
      non.map((x) => '$x').toList(), pos);
}

L3Q _multipleQ(int k, int m, List<int> non, int pos) {
  if (m % k != 0 || non.any((x) => x % k == 0)) throw StateError('multiple $k');
  return _mc('Which number is a multiple of $k?', '$m',
      non.map((x) => '$x').toList(), pos);
}

L3Q _primeQ(int p, List<int> composites, int pos) {
  if (!_isPrime(p) || composites.any(_isPrime)) throw StateError('prime $p');
  return _mc('Which number is prime?', '$p',
      composites.map((x) => '$x').toList(), pos);
}

L3Q _countFactorsQ(int n, int pos) {
  var c = 0;
  for (var i = 1; i <= n; i++) {
    if (n % i == 0) c++;
  }
  return _mc('How many factors does $n have?', '$c',
      ['${c + 1}', '${c - 1}', '${c ~/ 2}'], pos);
}

L3Q _nthMultipleQ(int k, int n, int pos) => _mc(
      'What is the ${n}th multiple of $k?',
      '${k * n}',
      ['${n + k}', '${k * (n - 1)}', '${k * (n + 1)}'],
      pos,
    );

// ------------------------------------------------------------ lesson 5

L3Q _equalFracQ(int a, int b, int k, int pos) => _mc(
      'Which fraction is equal to $a/$b?',
      '${a * k}/${b * k}',
      ['${a + k}/${b + k}', '$a/${b * k}', '${a * k}/$b'],
      pos,
    );

L3Q _missingTopQ(int a, int b, int d2, int pos) {
  final k = d2 ~/ b;
  return _mc(
    'What number makes the fractions equal? $a/$b = ?/$d2',
    '${a * k}',
    ['${a + d2 - b}', '${a + k}', '${a * k + 1}'],
    pos,
  );
}

L3Q _missingBottomQ(int a, int b, int n2, int pos) {
  final k = n2 ~/ a;
  return _mc(
    'What number makes the fractions equal? $a/$b = $n2/?',
    '${b * k}',
    ['${n2 + b - a}', '${b + k}', '${n2 + b}'],
    pos,
  );
}

L3Q _simplifyQ(int a, int b, int pos) {
  final g = _gcd(a, b);
  var p = 2;
  while (g % p != 0) {
    p++;
  }
  return _mc(
    'Write $a/$b in its simplest form.',
    '${a ~/ g}/${b ~/ g}',
    ['${a ~/ p}/${b ~/ p}', '${a ~/ g}/${b ~/ g + 1}', '${a ~/ g}/$b'],
    pos,
  );
}

L3Q _compareFracQ(int a, int b, int c, int d, int pos) {
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

// ------------------------------------------------------------ lesson 6

L3Q _fracOpQ(int a, int b, String op, int c, int d, int pos) {
  final l = b * d ~/ _gcd(b, d);
  final x = a * (l ~/ b), y = c * (l ~/ d);
  final num = op == '+' ? x + y : x - y;
  final raw = op == '+' ? a + c : a - c;
  return _mc(
    'What is $a/$b $op $c/$d? Give the answer in lowest terms.',
    _frac(num, l),
    [
      '$raw/${b + d}',
      '$raw/$l',
      if (num - 1 > 0) _frac(num - 1, l),
      _frac(num + 1, l),
    ],
    pos,
  );
}

// ------------------------------------------------------------ lesson 7

/// Decimal text such as "6.248" as an integer in thousandths.
int _thousandths(String s) {
  final p = s.split('.');
  final f = (p.length > 1 ? p[1] : '').padRight(3, '0');
  return int.parse(p[0]) * 1000 + int.parse(f.substring(0, 3));
}

L3Q _decDigitQ(String s, int index, int pos) {
  const places = ['tenths', 'hundredths', 'thousandths'];
  final digits = s.split('.')[1].split('');
  final ans = digits[index];
  return _mc(
    'Which digit is in the ${places[index]} place of $s?',
    ans,
    digits,
    pos,
  );
}

L3Q _signDec(String a, String b, int pos) =>
    _signQ(a, b, _thousandths(a).compareTo(_thousandths(b)), pos);

L3Q _roundDecQ(String s, int dp, int pos) {
  final v = _thousandths(s);
  int round(int u) {
    final fl = v ~/ u * u;
    return (v - fl) * 2 >= u ? fl + u : fl;
  }

  final unit = _p10(3 - dp);
  final fl = v ~/ unit * unit;
  return _mc(
    'Round $s to the nearest ${dp == 1 ? 'tenth' : 'hundredth'}.',
    _fmtScaled(round(unit), 3),
    [
      _fmtScaled(fl, 3),
      _fmtScaled(fl + unit, 3),
      _fmtScaled(round(unit * 10), 3),
      _fmtScaled(round(unit) + unit, 3),
    ],
    pos,
  );
}

L3Q _betweenQ(String lo, String hi, String ans, List<String> wrong, int pos) {
  bool inside(String s) =>
      _thousandths(s) > _thousandths(lo) && _thousandths(s) < _thousandths(hi);
  if (!inside(ans) || wrong.any(inside)) throw StateError('between $lo');
  return _mc('Which number lies between $lo and $hi?', ans, wrong, pos);
}

// ------------------------------------------------------------ lesson 8

/// [other] is the answer to the opposite operation (a typical mistake).
L3Q _moneyQ(String prompt, int ans, int other, int pos) {
  final wrong = <int>[other, ans + 100, ans - 100, ans + 10, ans - 10]
      .where((v) => v > 0)
      .map(_rs)
      .toList();
  return _mc(prompt, _rs(ans), wrong, pos);
}

// ------------------------------------------------------------ lesson 9

L3Q _percentFracQ(int p, int pos) => _mc(
      'Which fraction is the same as $p%?',
      _frac(p, 100),
      ['1/$p', _frac(100 - p, 100), _frac(p, 1000)],
      pos,
    );

L3Q _percentDecimalQ(int p, int pos) => _mc(
      'Write $p% as a decimal.',
      _fmtScaled(p, 2),
      [_fmtScaled(p, 1), _fmtScaled(p, 3), _fmtScaled(p, 0)],
      pos,
    );

L3Q _percentOfQ(int p, int n, int pos) {
  if (p * n % 100 != 0) throw StateError('percent $p of $n');
  final ans = p * n ~/ 100;
  return _mc('What is $p% of $n?', '$ans',
      ['${n - ans}', '${ans * 10}', '$p', '${ans + 10}'], pos);
}

L3Q _classQ(int n, int p, int pos) {
  if (p * n % 100 != 0) throw StateError('class $p of $n');
  final ans = p * n ~/ 100;
  return _mc('In a class of $n, $p% are girls. How many girls are there?',
      '$ans', ['${n - ans}', '$p', '${ans * 10}'], pos);
}

L3Q _fracToPercentQ(int n, int d, int pos) {
  if (100 % d != 0) throw StateError('percent $n/$d');
  final p = n * 100 ~/ d;
  return _mc(
      'Write $n/$d as a percent.', '$p%', ['$n%', '${100 - p}%', '$d%'], pos);
}

// ----------------------------------------------------------- lesson 10

L3Q _ratioQ(int a, int b, int pos) => _mc(
      'A bag has $a red and $b blue balls. What is the ratio of red to blue?',
      '$a : $b',
      ['$b : $a', '$a : ${a + b}', '${a + b} : $b'],
      pos,
    );

L3Q _simplestRatioQ(int a, int b, int pos) {
  final g = _gcd(a, b);
  return _mc(
    'There are $a boys and $b girls. What is the ratio of boys to girls in '
        'simplest form?',
    '${a ~/ g} : ${b ~/ g}',
    ['$a : $b', '${b ~/ g} : ${a ~/ g}', '${a ~/ 2} : ${b ~/ 2}'],
    pos,
  );
}

L3Q _scaleBeadsQ(int a, int b, int k, int pos) {
  final red = a * k;
  return _mc(
    'The ratio of red to blue beads is $a : $b. There are $red red beads. '
        'How many blue beads are there?',
    '${b * k}',
    ['${red + b - a}', '${red + b}', '${b * k + a}'],
    pos,
  );
}

L3Q _drinkQ(int a, int b, int k, int pos) => _mc(
      'A drink mixes $a cups of syrup with $b cups of water. How much water '
          'is needed for ${a * k} cups of syrup?',
      '${b * k}',
      ['${b + a * k - a}', '${a * k + b}', '${b * k * 2}'],
      pos,
    );

L3Q _partWholeQ(int g, int b, int pos) => _mc(
      'In a group there are $g girls and $b boys. What is the ratio of girls '
          'to all the children?',
      '$g : ${g + b}',
      ['$g : $b', '$b : ${g + b}', '${g + b} : $g'],
      pos,
    );

// ----------------------------------------------------------- lesson 11

String _angleType(int d) => d < 90 ? 'Acute' : (d == 90 ? 'Right' : 'Obtuse');

L3Q _typeQ(String prompt, String ans, int pos) => _mc(prompt, ans,
    ['Acute', 'Right', 'Obtuse'].where((s) => s != ans).toList(), pos);

L3Q _angleTypeQ(int deg, int pos) => _typeQ(
    'An angle measures $deg°. What kind of angle is it?', _angleType(deg), pos);

L3Q _straightQ(int x, int pos) => _mc(
      'Two angles on a straight line add up to 180°. One is $x°. What is '
          'the other?',
      '${180 - x}°',
      ['${90 - x}°', '${360 - x}°', '${180 - x - 10}°'],
      pos,
    );

// ----------------------------------------------------------- lesson 12

L3Q _perimeterQ(int l, int w, int pos) => _mc(
      'A rectangle is $l cm long and $w cm wide. What is its perimeter?',
      '${2 * (l + w)} cm',
      ['${l + w} cm', '${l * w} cm', '${2 * l + w} cm'],
      pos,
    );

L3Q _areaQ(int l, int w, int pos) => _mc(
      'A rectangle is $l cm long and $w cm wide. What is its area?',
      '${l * w} cm²',
      ['${2 * (l + w)} cm²', '${l + w} cm²', '${2 * l * w} cm²'],
      pos,
    );

L3Q _fenceQ(int l, int w, int pos) => _mc(
      'A field is $l m long and $w m wide. How long is the fence all round it?',
      '${2 * (l + w)} m',
      ['${l + w} m', '${l * w} m', '${2 * l + w} m'],
      pos,
    );

L3Q _squareAreaQ(int s, int pos) => _mc(
      'A square has sides of $s cm. What is its area?',
      '${s * s} cm²',
      ['${4 * s} cm²', '${2 * s} cm²', '${s * s + s} cm²'],
      pos,
    );

L3Q _widthQ(int area, int l, int pos) {
  if (area % l != 0) throw StateError('width');
  return _mc(
    'A rectangle has an area of $area cm² and a length of $l cm. What is its '
        'width?',
    '${area ~/ l} cm',
    ['${area - l} cm', '${area + l} cm', '${area ~/ l + l} cm'],
    pos,
  );
}

// ----------------------------------------------------------- lesson 13

/// Big unit to small unit: multiply.
L3Q _convertUpQ(String small, String big, int f, int n, int pos) {
  final ans = n * f;
  final other = f == 100 ? 1000 : 100;
  return _mc(
    'How many $small are in $n $big?',
    '$ans',
    ['${ans * 10}', '${ans ~/ 10}', '${n * other}'],
    pos,
  );
}

/// Small unit to big unit: divide (result may be a decimal).
L3Q _convertDownQ(String big, String small, int f, int n, int pos) {
  var k = 0;
  for (var x = f; x > 1; x ~/= 10) {
    k++;
  }
  return _mc(
    'How many $big are in $n $small?',
    _fmtScaled(n, k),
    [_fmtScaled(n, k - 1), _fmtScaled(n, k + 1), _fmtScaled(n, 0)],
    pos,
  );
}

// ----------------------------------------------------------- lesson 14

String _table(String intro, Map<String, int> rows) =>
    '$intro: ${rows.entries.map((e) => '${e.key} ${e.value}').join(', ')}.';

L3Q _totalQ(String intro, Map<String, int> rows, String question, int pos) {
  final total = rows.values.fold<int>(0, (a, b) => a + b);
  return _mc(
    '${_table(intro, rows)} $question',
    '$total',
    [
      '${total - rows.values.last}',
      '${total - rows.values.first}',
      '${total + 10}',
    ],
    pos,
  );
}

L3Q _moreQ(String intro, Map<String, int> rows, String a, String b, int pos,
    {bool children = false}) {
  final diff = rows[a]! - rows[b]!;
  final other = rows.keys.firstWhere((k) => k != a && k != b);
  final who = children ? 'children chose ' : '';
  return _mc(
    '${_table(intro, rows)} How many more $who$a than $b?',
    '$diff',
    ['${rows[a]! + rows[b]!}', '${rows[a]! - rows[other]!}', '${diff + 2}'],
    pos,
  );
}

L3Q _fewestDayQ(String intro, Map<String, int> rows, int pos) {
  const full = {
    'Mon': 'Monday',
    'Tue': 'Tuesday',
    'Wed': 'Wednesday',
    'Thu': 'Thursday',
    'Fri': 'Friday',
  };
  final sorted = rows.entries.toList()..sort((x, y) => x.value - y.value);
  return _mc(
    '${_table(intro, rows)} On which day were the fewest books read?',
    full[sorted.first.key]!,
    [full[sorted.last.key]!, full[sorted[1].key]!],
    pos,
  );
}

L3Q _togetherQ(
    String intro, Map<String, int> rows, String a, String b, int pos) {
  final keys = rows.keys.toList();
  final total = rows.values.fold<int>(0, (x, y) => x + y);
  return _mc(
    '${_table(intro, rows)} How many mm of rain fell in $a and $b together?',
    '${rows[a]! + rows[b]!}',
    [
      '${rows[keys[0]]! + rows[keys[1]]!}',
      '${rows[keys[2]]! + rows[keys[3]]!}',
      '$total',
    ],
    pos,
  );
}

// ----------------------------------------------------------- lesson 15

L3Q _changeQ(String who, int n, String item, int price, int pays, int pos) {
  final cost = n * price;
  return _mc(
    '$who buys $n $item at ₹$price each and pays with ₹$pays. How much '
        'change does she get?',
    '₹${pays - cost}',
    ['₹${pays - price}', '₹$cost', '₹${pays + cost}'],
    pos,
  );
}

L3Q _shopLeftQ(int total, int s1, int s2, int pos) => _mc(
      'A shop has $total mangoes. It sells $s1 in the morning and $s2 in the '
          'evening. How many are left?',
      '${total - s1 - s2}',
      ['${total - s1}', '${total - s2}', '${s1 + s2}'],
      pos,
    );

L3Q _emptySeatsQ(int buses, int seats, int carried, int pos) => _mc(
      '$buses buses with $seats seats each carry $carried children. How many '
          'seats are empty?',
      '${buses * seats - carried}',
      ['${buses * seats}', '${carried - seats}', '${buses * seats + carried}'],
      pos,
    );

L3Q _saveQ(int weekly, int weeks, int spend, int pos) {
  final total = weekly * weeks;
  return _mc(
    'Ravi saves ₹$weekly every week for $weeks weeks and then spends '
        '₹$spend. How much is left?',
    '₹${total - spend}',
    ['₹$total', '₹${total + spend}', '₹${total - spend - weekly}'],
    pos,
  );
}

L3Q _packCostQ(int pack, int price, int k, int pos) {
  if (price % pack != 0) throw StateError('pack');
  final unit = price ~/ pack;
  return _mc(
    'A pack of $pack pens costs ₹$price. What is the cost of $k pens?',
    '₹${unit * k}',
    ['₹$unit', '₹${unit * k + unit}', '₹${unit * k - unit}'],
    pos,
  );
}
