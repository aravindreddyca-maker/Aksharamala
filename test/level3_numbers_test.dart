import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/batch/level3_numbers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Recomputes the answer of a computed question straight from its prompt text,
/// without using any of the builder code. Returns null for hand-written ones.
String? recompute(int lesson, String p) {
  RegExpMatch? m;
  int n(RegExpMatch m, int i) => int.parse(m.group(i)!);
  switch (lesson) {
    case 1:
      m = RegExp(r'^What is (\d+) hundreds \+ (\d+) tens \+ (\d+) ones\?$')
          .firstMatch(p);
      if (m != null) return '${n(m, 1) * 100 + n(m, 2) * 10 + n(m, 3)}';
      m = RegExp(
              r'^What digit is in the (hundreds|tens|ones) place of (\d+)\?$')
          .firstMatch(p);
      if (m != null) {
        final s = m.group(2)!;
        final idx = {'hundreds': 0, 'tens': 1, 'ones': 2}[m.group(1)]!;
        return s[idx];
      }
    case 2:
      m = RegExp(r'^Which number is (greater|smaller), (\d+) or (\d+)\?$')
          .firstMatch(p);
      if (m != null) {
        final a = n(m, 2), b = n(m, 3);
        return '${m.group(1) == 'greater' ? (a > b ? a : b) : (a < b ? a : b)}';
      }
      m = RegExp(r'^Which sign fits\? (\d+) \? (\d+)$').firstMatch(p);
      if (m != null)
        return n(m, 1) > n(m, 2) ? '>' : (n(m, 1) < n(m, 2) ? '<' : '=');
      m = RegExp(r'^Which number is the (greatest|smallest) of: (.*)\?$')
          .firstMatch(p);
      if (m != null) {
        final xs = m.group(2)!.split(', ').map(int.parse).toList()..sort();
        return '${m.group(1) == 'greatest' ? xs.last : xs.first}';
      }
    case 3:
      m = RegExp(r'^What is (\d+) \+ (\d+)\?$').firstMatch(p);
      if (m != null) return '${n(m, 1) + n(m, 2)}';
    case 4:
      m = RegExp(r'^What is (\d+) - (\d+)\?$').firstMatch(p);
      if (m != null) return '${n(m, 1) - n(m, 2)}';
    case 5:
      m = RegExp(r'^What comes next\? ([-\d, ]+), \.\.\.$').firstMatch(p);
      if (m != null) {
        final xs = m.group(1)!.split(', ').map(int.parse).toList();
        final step = xs[1] - xs[0];
        for (var i = 1; i < xs.length; i++) {
          if (xs[i] - xs[i - 1] != step) return 'NOT-A-PATTERN';
        }
        return '${xs.last + step}';
      }
    case 6:
      m = RegExp(r'^There are (\d+) (groups|rows) of (\d+) \w+\.')
          .firstMatch(p);
      if (m != null) return '${n(m, 1) * n(m, 3)}';
    case 7:
    case 8:
      m = RegExp(r'^What is (\d+) x (\d+)\?$').firstMatch(p);
      if (m != null) return '${n(m, 1) * n(m, 2)}';
    case 9:
      m = RegExp(r'^Share (\d+) \w+ equally among (\d+) children\.')
          .firstMatch(p);
      if (m != null) {
        expect(n(m, 1) % n(m, 2), 0, reason: p);
        return '${n(m, 1) ~/ n(m, 2)}';
      }
    case 10:
      m = RegExp(r'^(\d+) x (\d+) = (\d+)\. What is (\d+) ÷ (\d+)\?$')
          .firstMatch(p);
      if (m != null) {
        expect(n(m, 1) * n(m, 2), n(m, 3), reason: p);
        expect(n(m, 4), n(m, 3), reason: p);
        return '${n(m, 3) ~/ n(m, 5)}';
      }
      m = RegExp(r'^What is the missing number\? (\d+) x \? = (\d+)$')
          .firstMatch(p);
      if (m != null) {
        expect(n(m, 2) % n(m, 1), 0, reason: p);
        return '${n(m, 2) ~/ n(m, 1)}';
      }
    case 12:
      final nums = RegExp(r'₹(\d+)')
          .allMatches(p)
          .map((e) => int.parse(e.group(1)!))
          .toList();
      if (p.contains('change')) return '₹${nums[0] - nums[1]}';
      if (p.contains('in all')) return '₹${nums[0] + nums[1]}';
    case 15:
      m = RegExp(r'^There are (\d+) bags with (\d+) apples each\.')
          .firstMatch(p);
      if (m != null) return '${n(m, 1) * n(m, 2)}';
      m = RegExp(r'^Meena had (\d+) mangoes\. She gave (\d+) ').firstMatch(p);
      if (m != null) return '${n(m, 1) - n(m, 2)}';
      m = RegExp(r'^Ravi has (\d+) laddoos\. He buys (\d+) more').firstMatch(p);
      if (m != null) return '${n(m, 1) + n(m, 2)}';
      m = RegExp(r'^(\d+) mangoes are packed equally into (\d+) boxes')
          .firstMatch(p);
      if (m != null) {
        expect(n(m, 1) % n(m, 2), 0, reason: p);
        return '${n(m, 1) ~/ n(m, 2)}';
      }
      m = RegExp(
              r'^Sita has (\d+) pencils\. She buys (\d+) boxes with (\d+) pencils each')
          .firstMatch(p);
      if (m != null) return '${n(m, 1) + n(m, 2) * n(m, 3)}';
  }
  return null;
}

void main() {
  const handWritten = {11, 13, 14};

  test('15 lessons with the right ids in order', () {
    expect(numbersLevel3Lessons, hasLength(15));
    for (var i = 0; i < 15; i++) {
      final lesson = numbersLevel3Lessons[i];
      expect(lesson.id, 'numbers-l3-${(i + 1).toString().padLeft(3, '0')}');
      expect(lesson.title, isNotEmpty);
      expect(lesson.ageBand, '7-9');
    }
  });

  for (var i = 0; i < 15; i++) {
    final no = i + 1;
    test('lesson $no structure and answers', () {
      final lesson = numbersLevel3Lessons[i];
      expect(lesson.steps, hasLength(6));
      expect(lesson.steps.first.kind, StepKind.listen);
      expect(lesson.steps.first.prompt.trim(), isNotEmpty);
      final choices = lesson.steps.skip(1).toList();
      expect(choices.every((s) => s.kind == StepKind.choice), isTrue);
      expect(choices, hasLength(5));

      final prompts = <String>{};
      for (final s in choices) {
        expect(prompts.add(s.prompt), isTrue, reason: 'duplicate ${s.prompt}');
        expect(s.options, hasLength(3), reason: s.prompt);
        expect(s.options.toSet(), hasLength(3), reason: s.prompt);
        expect(s.options.every((o) => o.trim().isNotEmpty), isTrue);
        expect(s.options.where((o) => o == s.answer), hasLength(1),
            reason: s.prompt);
        if (!handWritten.contains(no)) {
          final expected = recompute(no, s.prompt);
          expect(expected, isNotNull, reason: 'cannot parse: ${s.prompt}');
          expect(s.answer, expected, reason: s.prompt);
        }
      }
      final positions = choices.map((s) => s.options.indexOf(s.answer)).toSet();
      expect(positions.length, greaterThan(1),
          reason: 'answer position never varies');
    });
  }

  test('answer position varies across the whole set', () {
    final counts = <int, int>{};
    for (final lesson in numbersLevel3Lessons) {
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
