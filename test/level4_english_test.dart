import 'package:aksharamala/src/batch/level4_english.dart';
import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('15 lessons with ids in order', () {
    expect(englishLevel4Lessons.length, 15);
    for (var i = 0; i < 15; i++) {
      expect(englishLevel4Lessons[i].id,
          'english-l4-${(i + 1).toString().padLeft(3, '0')}');
      expect(englishLevel4Lessons[i].ageBand, '10-12');
    }
  });

  test('structure, options and answers', () {
    final indexes = <int>{};
    for (final l in englishLevel4Lessons) {
      final listen = l.steps.where((s) => s.kind == StepKind.listen).toList();
      expect(listen.length, 1, reason: l.id);
      expect(listen.first.prompt.length <= 130, isTrue, reason: l.id);
      final choices = l.steps.where((s) => s.kind == StepKind.choice).toList();
      expect(choices.length, 5, reason: l.id);
      final prompts = <String>{};
      for (final s in choices) {
        final o = s.options;
        expect(o.length, 3, reason: s.prompt);
        expect(o.toSet().length, 3, reason: s.prompt);
        expect(o.every((e) => e.trim().isNotEmpty && e.length <= 40), isTrue,
            reason: s.prompt);
        expect(o.contains(s.answer), isTrue, reason: s.prompt);
        indexes.add(o.indexOf(s.answer));
        expect(prompts.add(s.prompt), isTrue, reason: 'dup ${s.prompt}');
        final a = s.answer!;
        if (RegExp(r'\w').hasMatch(a)) {
          final re = RegExp('(?<!\\w)${RegExp.escape(a)}(?!\\w)',
              caseSensitive: false);
          expect(re.hasMatch(s.prompt), isFalse,
              reason: 'answer in prompt: ${s.prompt}');
        }
      }
    }
    expect(indexes.length, 3);
  });
}
