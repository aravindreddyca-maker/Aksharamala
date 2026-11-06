import 'batch_lesson.dart';
import 'level3_support.dart';

/// Level 3 Number Galaxy: 15 lessons (ids numbers-l3-001 .. 015).
///
/// The arithmetic questions are built from numbers, and their answers are
/// computed with integer maths, so they are correct by construction.
/// Distractors are common mistakes (forgetting to regroup, off by ten, the
/// wrong operation). Lessons 11, 13 and 14 are hand-written.
final List<BatchLesson> numbersLevel3Lessons = List.unmodifiable(<BatchLesson>[
  level3Lesson(
    id: 'numbers-l3-001',
    module: 'numbers',
    title: 'Place value to 1000',
    objective: 'Read a three-digit number as hundreds, tens and ones.',
    topic: 'place value',
    skill: 'place value to 1000',
    teach: 'In 245, the 2 means 2 hundreds, the 4 means 4 tens and the 5 '
        'means 5 ones. So 245 = 200 + 40 + 5.',
    examples: ['245'],
    questions: [
      _composeQ(4, 3, 7, 0),
      _countQ('tens', 245, 2),
      _composeQ(6, 0, 9, 1),
      _countQ('hundreds', 782, 2),
      _composeQ(2, 5, 8, 0),
    ],
  ),
  level3Lesson(
    id: 'numbers-l3-002',
    module: 'numbers',
    title: 'Compare three-digit numbers',
    objective: 'Compare three-digit numbers using hundreds, tens and ones.',
    topic: 'comparing numbers',
    skill: 'compare numbers to 1000',
    teach: 'Compare the hundreds first. If they are the same, compare the '
        'tens, then the ones. So 408 is less than 480.',
    examples: ['408 < 480'],
    questions: [
      _moreLessQ(true, 408, 480, 1),
      _signQ(562, 526, 0),
      _extremeQ(false, [732, 372, 723], 2),
      _moreLessQ(false, 615, 651, 1),
      _extremeQ(true, [819, 891, 189], 2),
    ],
  ),
  level3Lesson(
    id: 'numbers-l3-003',
    module: 'numbers',
    title: 'Addition with regrouping',
    objective: 'Add two numbers when the ones make ten or more.',
    topic: 'addition',
    skill: 'addition with regrouping',
    teach: 'Add the ones first. If they make 10 or more, regroup 10 ones as '
        '1 ten. For 47 + 38: 7 + 8 = 15, so write 5 and carry 1 ten. '
        'Then 4 + 3 + 1 = 8 tens, so the answer is 85.',
    examples: ['47 + 38'],
    questions: [
      _addQ(47, 38, 2),
      _addQ(56, 27, 1),
      _addQ(138, 45, 0),
      _addQ(29, 64, 0),
      _addQ(265, 79, 1),
    ],
  ),
  level3Lesson(
    id: 'numbers-l3-004',
    module: 'numbers',
    title: 'Subtraction with regrouping',
    objective: 'Subtract two numbers when the ones need to be regrouped.',
    topic: 'subtraction',
    skill: 'subtraction with regrouping',
    teach: 'Not enough ones? Take 1 ten and make 10 ones. '
        '82 - 46: use 12 ones. 12 - 6 = 6. 7 tens - 4 tens = 3. Answer: 36.',
    examples: ['82 - 46'],
    questions: [
      _subQ(82, 46, 0),
      _subQ(71, 25, 2),
      _subQ(90, 37, 1),
      _subQ(143, 68, 2),
      _subQ(305, 128, 1),
    ],
  ),
  level3Lesson(
    id: 'numbers-l3-005',
    module: 'numbers',
    title: 'Skip counting and patterns',
    objective: 'Find the next number in a skip-counting pattern.',
    topic: 'patterns',
    skill: 'skip counting',
    teach: 'Skip counting jumps by the same number each time. In 3, 6, 9, '
        '12 we jump by 3, so the next number is 15.',
    examples: ['3, 6, 9'],
    questions: [
      _skipQ(3, 3, 1),
      _skipQ(5, 5, 0),
      _skipQ(100, -10, 2),
      _skipQ(2, 4, 2),
      _skipQ(20, 10, 0),
    ],
  ),
  level3Lesson(
    id: 'numbers-l3-006',
    module: 'numbers',
    title: 'Equal groups and arrays',
    objective: 'Find the total of equal groups and rows.',
    topic: 'multiplication',
    skill: 'equal groups and arrays',
    teach: 'Equal groups have the same number of things in each group. '
        '4 groups of 3 mangoes is 3 + 3 + 3 + 3 = 12 mangoes. '
        'A row-and-column picture is called an array.',
    examples: ['4 groups of 3'],
    questions: [
      _groupQ(4, 3, 'groups', 'mangoes', 2),
      _groupQ(5, 2, 'rows', 'laddoos', 0),
      _groupQ(3, 6, 'groups', 'bananas', 1),
      _groupQ(4, 5, 'rows', 'chairs', 0),
      _groupQ(6, 3, 'groups', 'pencils', 2),
    ],
  ),
  level3Lesson(
    id: 'numbers-l3-007',
    module: 'numbers',
    title: 'Multiplication facts 2, 5, 10',
    objective: 'Recall the multiplication facts for 2, 5 and 10.',
    topic: 'multiplication facts',
    skill: 'times tables 2, 5, 10',
    teach: 'Facts of 2 are doubles. Facts of 5 end in 0 or 5. Facts of 10 '
        'end in 0. So 5 x 4 = 20.',
    examples: ['5 x 4'],
    questions: [
      _mulQ(2, 7, 0),
      _mulQ(5, 6, 1),
      _mulQ(10, 8, 2),
      _mulQ(7, 5, 0),
      _mulQ(9, 2, 2),
    ],
  ),
  level3Lesson(
    id: 'numbers-l3-008',
    module: 'numbers',
    title: 'Multiplication facts 3, 4',
    objective: 'Recall the multiplication facts for 3 and 4.',
    topic: 'multiplication facts',
    skill: 'times tables 3, 4',
    teach: 'Facts of 3 count up by 3: 3, 6, 9, 12. Facts of 4 are double '
        'the double. So 3 x 4 = 12.',
    examples: ['3 x 4'],
    questions: [
      _mulQ(3, 7, 1),
      _mulQ(4, 6, 2),
      _mulQ(9, 3, 0),
      _mulQ(4, 8, 2),
      _mulQ(7, 4, 0),
    ],
  ),
  level3Lesson(
    id: 'numbers-l3-009',
    module: 'numbers',
    title: 'Division as sharing',
    objective: 'Share a number of things equally.',
    topic: 'division',
    skill: 'division as sharing',
    teach: 'Division means sharing equally. If 12 laddoos are shared among '
        '3 children, each child gets 4. We write 12 ÷ 3 = 4.',
    examples: ['12 ÷ 3'],
    questions: [
      _shareQ(12, 3, 'laddoos', 2),
      _shareQ(20, 5, 'mangoes', 0),
      _shareQ(18, 6, 'pencils', 1),
      _shareQ(24, 4, 'bananas', 1),
      _shareQ(35, 5, 'stickers', 0),
    ],
  ),
  level3Lesson(
    id: 'numbers-l3-010',
    module: 'numbers',
    title: 'Multiplication and division fact families',
    objective: 'Use one multiplication fact to find a division fact.',
    topic: 'fact families',
    skill: 'fact families',
    teach: 'Multiplication and division go together. 3 x 4 = 12, so '
        '12 ÷ 4 = 3 and 12 ÷ 3 = 4.',
    examples: ['3 x 4 = 12'],
    questions: [
      _familyQ(6, 3, 1),
      _missingQ(4, 28, 0),
      _familyQ(4, 5, 2),
      _missingQ(5, 45, 2),
      _familyQ(3, 4, 1),
    ],
  ),
  level3Lesson(
    id: 'numbers-l3-011',
    module: 'numbers',
    title: 'Halves, quarters and thirds',
    objective: 'Name equal parts of a whole as halves, quarters and thirds.',
    topic: 'fractions',
    skill: 'halves, quarters, thirds',
    teach: 'Equal parts are the same size. 2 equal parts are halves, '
        '3 equal parts are thirds and 4 equal parts are quarters. '
        'Each part of a roti cut in 2 is one half.',
    examples: ['1/2', '1/4', '1/3'],
    questions: [
      _q('A roti is cut into 2 equal parts. What is each part called?',
          'A half', ['A quarter', 'A third'], 0),
      _q(
          'A pizza is cut into 4 equal parts. Rahul eats 1 part. '
              'What fraction did he eat?',
          'One quarter',
          ['One half', 'One third'],
          2),
      _q(
          'A cake is cut into 3 equal parts. 1 part is coloured. '
              'What fraction is coloured?',
          'One third',
          ['One half', 'One quarter'],
          1),
      _q('Which is bigger on the same chapati: one half or one quarter?',
          'One half', ['One quarter', 'They are the same'], 0),
      _q(
          'Priya has 8 mangoes. She gives half of them to her friend. '
              'How many mangoes does she give?',
          '4',
          ['2', '6'],
          2),
    ],
  ),
  level3Lesson(
    id: 'numbers-l3-012',
    module: 'numbers',
    title: 'Money and change',
    objective: 'Add prices and find change in rupees.',
    topic: 'money',
    skill: 'money and change',
    teach: 'To find change, take the price away from the money you give. '
        'If you give ₹20 and the price is ₹7, the change is '
        '20 - 7 = ₹13.',
    examples: ['₹20 - ₹7'],
    questions: [
      _changeQ(20, 7, 'laddoo', 2),
      _changeQ(50, 35, 'kite', 1),
      _totalQ(12, 25, 0),
      _changeQ(100, 64, 'notebook', 1),
      _changeQ(30, 18, 'pencil box', 0),
    ],
  ),
  level3Lesson(
    id: 'numbers-l3-013',
    module: 'numbers',
    title: 'Time to five minutes',
    objective: 'Tell the time to five minutes from a clock described in words.',
    topic: 'time',
    skill: 'telling time',
    teach: 'The short hand shows the hour. The long hand shows minutes: '
        'each number is 5 minutes, so 3 is 15 and 6 is 30.',
    examples: ['3:15'],
    questions: [
      _q(
          'The hour hand is just past 3 and the minute hand points to 3. '
              'What time is it?',
          '3:15',
          ['3:03', '3:30'],
          1),
      _q(
          'The hour hand is exactly on 7 and the minute hand points to 12. '
              'What time is it?',
          '7:00',
          ['12:07', '7:12'],
          0),
      _q(
          'The hour hand is between 5 and 6 and the minute hand points to 6. '
              'What time is it?',
          '5:30',
          ['6:05', '6:30'],
          2),
      _q('Which time is the same as quarter to 8?', '7:45', ['8:15', '7:15'],
          2),
      _q('The minute hand points to 4. How many minutes past the hour is it?',
          '20', ['4', '40'], 1),
    ],
  ),
  level3Lesson(
    id: 'numbers-l3-014',
    module: 'numbers',
    title: 'Length and mass',
    objective: 'Choose a sensible unit and compare lengths and masses.',
    topic: 'measurement',
    skill: 'length and mass',
    teach: 'We measure length in centimetres (cm) and metres (m). '
        '1 m = 100 cm. We measure mass in grams (g) and kilograms (kg). '
        '1 kg = 1000 g.',
    examples: ['1 m = 100 cm', '1 kg = 1000 g'],
    questions: [
      _q('Which unit is best to measure the length of a pencil?',
          'centimetres (cm)', ['metres (m)', 'kilograms (kg)'], 0),
      _q('Which unit is best to measure the mass of a bag of rice?',
          'kilograms (kg)', ['centimetres (cm)', 'metres (m)'], 2),
      _q('Which is the longest?', '1 metre',
          ['50 centimetres', '80 centimetres'], 1),
      _q('Which is the heaviest?', '1 kilogram', ['500 grams', '900 grams'], 1),
      _q('Which unit is best to measure the height of a door?', 'metres (m)',
          ['grams (g)', 'kilograms (kg)'], 2),
    ],
  ),
  level3Lesson(
    id: 'numbers-l3-015',
    module: 'numbers',
    title: 'Word problems and reasoning',
    objective: 'Choose the right operation to solve a short story problem.',
    topic: 'word problems',
    skill: 'word problems',
    teach: 'Add to put together, subtract to take away, multiply for equal '
        'groups, divide to share. 3 bags of 4 apples is 3 x 4 = 12.',
    examples: ['3 bags with 4 apples each'],
    questions: [
      _bagsQ(3, 4, 2),
      _leftQ(45, 18, 0),
      _moreQ(36, 27, 1),
      _packQ(20, 4, 0),
      _twoStepQ(10, 3, 5, 2),
    ],
  ),
]);

// ---------------------------------------------------------------------------
// Builders. Every function takes the numbers and a position (0-2) for the
// right answer, and computes the answer with integer maths.
// ---------------------------------------------------------------------------

/// Builds a question with the right answer at index [pos] of three options.
/// Throws if the options are not three distinct, non-empty strings, so a bad
/// distractor is caught the first time the lessons load.
L3Q _q(String prompt, String answer, List<String> wrong, int pos) {
  final all = <String>[...wrong]..insert(pos, answer);
  if (wrong.length != 2 ||
      all.toSet().length != 3 ||
      all.any((o) => o.isEmpty)) {
    throw StateError('Bad options for: $prompt');
  }
  return L3Q(prompt, all, answer);
}

/// A numeric question: the answer and two wrong numbers (all non-negative).
L3Q _n(String prompt, int answer, int w1, int w2, int pos,
    {String prefix = ''}) {
  if (answer < 0 || w1 < 0 || w2 < 0) {
    throw StateError('Negative option for: $prompt');
  }
  return _q(prompt, '$prefix$answer', ['$prefix$w1', '$prefix$w2'], pos);
}

L3Q _composeQ(int h, int t, int o, int pos) => _n(
      'What is $h hundreds + $t tens + $o ones?',
      h * 100 + t * 10 + o,
      h * 100 + o * 10 + t, // swapped tens and ones
      o * 100 + t * 10 + h, // digits reversed
      pos,
    );

L3Q _countQ(String place, int number, int pos) {
  final digits = <String, int>{
    'hundreds': number ~/ 100,
    'tens': number % 100 ~/ 10,
    'ones': number % 10,
  };
  final others = digits.entries.where((e) => e.key != place).toList();
  return _n(
    'What digit is in the $place place of $number?',
    digits[place]!,
    others[0].value,
    others[1].value,
    pos,
  );
}

L3Q _moreLessQ(bool greater, int a, int b, int pos) => _q(
      'Which number is ${greater ? 'greater' : 'smaller'}, $a or $b?',
      '${greater ? (a > b ? a : b) : (a < b ? a : b)}',
      ['${greater ? (a > b ? b : a) : (a < b ? b : a)}', 'They are equal'],
      pos,
    );

L3Q _signQ(int a, int b, int pos) {
  final answer = a > b ? '>' : (a < b ? '<' : '=');
  final wrong = ['<', '>', '='].where((s) => s != answer).toList();
  return _q('Which sign fits? $a ? $b', answer, wrong, pos);
}

L3Q _extremeQ(bool greatest, List<int> nums, int pos) {
  final sorted = [...nums]..sort();
  final answer = greatest ? sorted.last : sorted.first;
  return _q(
    'Which number is the ${greatest ? 'greatest' : 'smallest'} of: '
        '${nums.join(', ')}?',
    '$answer',
    [
      for (final n in nums)
        if (n != answer) '$n'
    ],
    pos,
  );
}

L3Q _addQ(int a, int b, int pos) => _n(
      'What is $a + $b?',
      a + b,
      a + b - 10, // forgot to carry
      a + b + 10, // carried twice
      pos,
    );

/// Takes the smaller digit from the bigger one in every column (no regrouping).
int _noRegroup(int a, int b) {
  var result = 0;
  var place = 1;
  var x = a;
  var y = b;
  while (x > 0 || y > 0) {
    result += ((x % 10) - (y % 10)).abs() * place;
    x ~/= 10;
    y ~/= 10;
    place *= 10;
  }
  return result;
}

L3Q _subQ(int a, int b, int pos) => _n(
      'What is $a - $b?',
      a - b,
      _noRegroup(a, b), // smaller from bigger in each column
      a - b + 10, // forgot to take 1 ten away
      pos,
    );

L3Q _skipQ(int start, int step, int pos) {
  final shown = [for (var i = 0; i < 4; i++) start + step * i];
  final next = start + step * 4;
  return _n('What comes next? ${shown.join(', ')}, ...', next, next + 1,
      next - 1, pos);
}

L3Q _groupQ(int a, int b, String word, String thing, int pos) => _n(
      'There are $a $word of $b $thing. How many $thing in all?',
      a * b,
      a + b, // added instead of multiplied
      a * b + a, // one group too many
      pos,
    );

L3Q _mulQ(int a, int b, int pos) =>
    _n('What is $a x $b?', a * b, a + b, a * b + a, pos);

L3Q _shareQ(int total, int kids, String thing, int pos) => _n(
      'Share $total $thing equally among $kids children. '
      'How many does each child get?',
      total ~/ kids,
      total - kids, // subtracted
      kids, // gave the number of children
      pos,
    );

L3Q _familyQ(int x, int y, int pos) => _n(
      '$x x $y = ${x * y}. What is ${x * y} ÷ $x?',
      y,
      x,
      x * y - x,
      pos,
    );

L3Q _missingQ(int a, int total, int pos) => _n(
      'What is the missing number? $a x ? = $total',
      total ~/ a,
      total - a,
      total + a,
      pos,
    );

L3Q _changeQ(int paid, int price, String item, int pos) => _n(
      'Asha has ₹$paid. She buys a $item for ₹$price. '
      'How much change does she get?',
      paid - price,
      paid + price,
      paid - price + 10,
      pos,
      prefix: '₹',
    );

L3Q _totalQ(int a, int b, int pos) => _n(
      'A pen costs ₹$a and a book costs ₹$b. '
      'How much do they cost in all?',
      a + b,
      b - a,
      a + b + 10,
      pos,
      prefix: '₹',
    );

L3Q _bagsQ(int bags, int each, int pos) => _n(
      'There are $bags bags with $each apples each. '
      'How many apples are there in all?',
      bags * each,
      bags + each,
      bags * each + bags,
      pos,
    );

L3Q _leftQ(int had, int gave, int pos) => _n(
      'Meena had $had mangoes. She gave $gave to her friend. '
      'How many mangoes are left?',
      had - gave,
      had + gave,
      had - gave + 10,
      pos,
    );

L3Q _moreQ(int had, int more, int pos) => _n(
      'Ravi has $had laddoos. He buys $more more. '
      'How many laddoos does he have now?',
      had + more,
      had - more,
      had + more - 10,
      pos,
    );

L3Q _packQ(int total, int boxes, int pos) => _n(
      '$total mangoes are packed equally into $boxes boxes. '
      'How many mangoes are in each box?',
      total ~/ boxes,
      total - boxes,
      total * boxes,
      pos,
    );

L3Q _twoStepQ(int had, int boxes, int each, int pos) => _n(
      'Sita has $had pencils. She buys $boxes boxes with $each pencils each. '
      'How many pencils does she have now?',
      had + boxes * each,
      had + boxes + each, // ignored the multiplication
      boxes * each, // forgot the pencils she had
      pos,
    );
