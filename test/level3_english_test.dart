import 'package:aksharamala/src/batch/level3_english.dart';
import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('15 lessons with ids in order', () {
    expect(englishLevel3Lessons.length, 15);
    for (var i = 0; i < 15; i++) {
      expect(englishLevel3Lessons[i].id,
          'english-l3-${(i + 1).toString().padLeft(3, '0')}');
      expect(englishLevel3Lessons[i].ageBand, '7-9');
    }
  });

  test('structure, options and answers', () {
    final indexes = <int>{};
    for (final l in englishLevel3Lessons) {
      expect(l.steps.where((s) => s.kind == StepKind.listen).length, 1,
          reason: l.id);
      final choices = l.steps.where((s) => s.kind == StepKind.choice).toList();
      expect(choices.length, 5, reason: l.id);
      final prompts = <String>{};
      for (final s in choices) {
        final o = s.options;
        expect(o.length, 3, reason: s.prompt);
        expect(o.toSet().length, 3, reason: s.prompt);
        expect(o.every((e) => e.trim().isNotEmpty), isTrue);
        expect(o.contains(s.answer), isTrue, reason: s.prompt);
        indexes.add(o.indexOf(s.answer));
        expect(prompts.add(s.prompt), isTrue, reason: 'dup ${s.prompt}');
      }
    }
    expect(indexes.length, 3);
  });
}
