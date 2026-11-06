import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/batch/level3_telugu.dart';
import 'package:flutter_test/flutter_test.dart';

bool _hasTelugu(String s) => s.runes.any((r) => r >= 0x0C00 && r <= 0x0C7F);

void main() {
  test('15 lessons with ids in order', () {
    expect(teluguLevel3Lessons.length, 15);
    for (var i = 0; i < 15; i++) {
      final l = teluguLevel3Lessons[i];
      expect(l.id, 'telugu-l3-${(i + 1).toString().padLeft(3, '0')}');
      expect(l.locale, 'te-IN');
      expect(l.ageBand, '7-9');
      expect(l.educatorReviewVerified, isFalse);
    }
  });

  test('structure, options, answers and Telugu script', () {
    final indexes = <int>{};
    for (final l in teluguLevel3Lessons) {
      final listens = l.steps.where((s) => s.kind == StepKind.listen).toList();
      expect(listens.length, 1, reason: l.id);
      expect(_hasTelugu(listens.first.prompt), isTrue, reason: l.id);
      final choices = l.steps.where((s) => s.kind == StepKind.choice).toList();
      expect(choices.length, 5, reason: l.id);
      final prompts = <String>{};
      for (final s in choices) {
        final o = s.options;
        expect(o.length, 3, reason: s.prompt);
        expect(o.toSet().length, 3, reason: s.prompt);
        expect(o.contains(s.answer), isTrue, reason: s.prompt);
        expect(_hasTelugu(s.prompt), isTrue, reason: s.prompt);
        for (final e in o) {
          expect(_hasTelugu(e), isTrue, reason: e);
        }
        indexes.add(o.indexOf(s.answer));
        expect(prompts.add(s.prompt), isTrue, reason: 'dup ${s.prompt}');
      }
    }
    expect(indexes.length, 3);
  });
}
