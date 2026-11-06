import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/batch/level8_english.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('10 lessons with ids in order', () {
    expect(englishLevel8Lessons.length, 10);
    for (var i = 0; i < 10; i++) {
      final l = englishLevel8Lessons[i];
      expect(l.id, 'english-l8-${(i + 1).toString().padLeft(3, '0')}');
      expect(l.ageBand, '10-12');
      expect(l.levelSet, {8});
      expect(l.title, isNotEmpty);
    }
  });

  test('structure, options and answers', () {
    final indexes = <int>{};
    for (final l in englishLevel8Lessons) {
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
        expect(o.where((e) => e == s.answer).length, 1, reason: s.prompt);
        expect(s.prompt.length <= 270, isTrue, reason: s.prompt);
        indexes.add(o.indexOf(s.answer!));
        lessonIdx.add(o.indexOf(s.answer!));
        expect(prompts.add(s.prompt), isTrue, reason: 'dup ${s.prompt}');
        final a = s.answer!;
        final re =
            RegExp('(?<!\\w)${RegExp.escape(a)}(?!\\w)', caseSensitive: false);
        expect(re.hasMatch(s.prompt), isFalse,
            reason: 'answer in prompt: ${s.prompt}');
      }
      expect(lessonIdx.length, greaterThan(1),
          reason: '${l.id} answer position never varies');
    }
    expect(indexes.length, 3);
  });
}
