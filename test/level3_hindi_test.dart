import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/batch/level3_hindi.dart';
import 'package:flutter_test/flutter_test.dart';

final RegExp _deva = RegExp(r'[ऀ-ॿ]');

void main() {
  test('15 lessons with ids in order', () {
    expect(hindiLevel3Lessons.length, 15);
    for (var i = 0; i < 15; i++) {
      final l = hindiLevel3Lessons[i];
      expect(l.id, 'hindi-l3-${(i + 1).toString().padLeft(3, '0')}');
      expect(l.ageBand, '7-9');
      expect(l.locale, 'hi-IN');
      expect(l.educatorReviewVerified, isFalse);
    }
  });

  test('structure, options, answers and script', () {
    final indexes = <int>{};
    for (final l in hindiLevel3Lessons) {
      final listens = l.steps.where((s) => s.kind == StepKind.listen).toList();
      expect(listens.length, 1, reason: l.id);
      expect(_deva.hasMatch(listens.first.prompt), isTrue, reason: l.id);
      final choices = l.steps.where((s) => s.kind == StepKind.choice).toList();
      expect(choices.length, 5, reason: l.id);
      final prompts = <String>{};
      for (final s in choices) {
        final o = s.options;
        expect(o.length, 3, reason: s.prompt);
        expect(o.toSet().length, 3, reason: s.prompt);
        expect(o.contains(s.answer), isTrue, reason: s.prompt);
        indexes.add(o.indexOf(s.answer));
        expect(prompts.add(s.prompt), isTrue, reason: 'dup ${s.prompt}');
        expect(_deva.hasMatch(s.prompt), isTrue, reason: s.prompt);
        for (final e in o) {
          expect(_deva.hasMatch(e), isTrue, reason: '${s.prompt} / $e');
        }
      }
    }
    expect(indexes.length, 3);
  });
}
