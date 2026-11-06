import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/batch/level6_english.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('10 lessons with ids in order', () {
    expect(englishLevel6Lessons.length, 10);
    for (var i = 0; i < 10; i++) {
      final l = englishLevel6Lessons[i];
      expect(l.id, 'english-l6-${(i + 1).toString().padLeft(3, '0')}');
      expect(l.ageBand, '10-12');
      expect(l.levelSet, {6});
    }
  });

  test('structure, options and answers', () {
    final indexes = <int>{};
    for (final l in englishLevel6Lessons) {
      final listen = l.steps.where((s) => s.kind == StepKind.listen).toList();
      expect(listen.length, 1, reason: l.id);
      expect(listen.first.prompt.length <= 130, isTrue, reason: l.id);
      final choices = l.steps.where((s) => s.kind == StepKind.choice).toList();
      expect(choices.length, 5, reason: l.id);
      final prompts = <String>{};
      final lessonIdx = <int>{};
      for (final s in choices) {
        final o = s.options;
        expect(o.length, 3, reason: s.prompt);
        expect(o.toSet().length, 3, reason: s.prompt);
        expect(o.every((e) => e.trim().isNotEmpty && e.length <= 45), isTrue,
            reason: s.prompt);
        expect(s.prompt.length <= 235, isTrue, reason: s.prompt);
        expect(o.where((e) => e == s.answer).length, 1, reason: s.prompt);
        indexes.add(o.indexOf(s.answer!));
        lessonIdx.add(o.indexOf(s.answer!));
        expect(prompts.add(s.prompt), isTrue, reason: 'dup ${s.prompt}');
        final a = s.answer!;
        if (RegExp(r'\w').hasMatch(a)) {
          final re = RegExp('(?<!\\w)${RegExp.escape(a)}(?!\\w)',
              caseSensitive: false);
          expect(re.hasMatch(s.prompt), isFalse,
              reason: 'answer in prompt: ${s.prompt}');
        }
      }
      expect(lessonIdx.length > 1, isTrue, reason: 'positions ${l.id}');
    }
    expect(indexes.length, 3);
  });
}
