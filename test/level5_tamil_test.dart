import 'package:aksharamala/src/batch/level5_tamil.dart';
import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

final _tamil = RegExp(r'[஀-௿]');
final _letters = RegExp(r'[^\s\d\p{P}\p{S}]', unicode: true);
final _punct = RegExp(r'[\s\p{P}\p{S}]+', unicode: true);

bool _ok(String s) {
  // Every text with letters must contain Tamil script.
  if (!_letters.hasMatch(s)) return true;
  return _tamil.hasMatch(s);
}

String _norm(String s) =>
    ' ${s.split(_punct).where((w) => w.isNotEmpty).join(' ')} ';

void main() {
  test('15 Tamil Level 5 lessons in order', () {
    expect(tamilLevel5Lessons.length, 15);
    for (var i = 0; i < 15; i++) {
      final l = tamilLevel5Lessons[i];
      expect(l.id, 'tamil-l5-${(i + 1).toString().padLeft(3, '0')}');
      expect(l.locale, 'ta-IN');
      expect(l.levels, {5});
      expect(l.educatorReviewVerified, false);
      expect(l.steps.where((s) => s.kind == StepKind.listen).length, 1);
      expect(l.steps.where((s) => s.kind == StepKind.choice).length, 5);
      expect(l.steps.length, 6);
      expect(_ok(l.title) && _tamil.hasMatch(l.title), true, reason: l.id);
      expect(_tamil.hasMatch(l.learningObjective), true, reason: l.id);
      expect(l.steps.first.prompt.length <= 110, true, reason: l.id);
    }
  });

  test('questions are well formed', () {
    final positions = <int>{};
    for (final l in tamilLevel5Lessons) {
      final prompts = <String>{};
      for (final s in l.steps) {
        expect(_tamil.hasMatch(s.prompt), true, reason: '${l.id} ${s.prompt}');
        expect(_ok(s.prompt), true, reason: '${l.id} ${s.prompt}');
        expect(s.prompt.length <= 160, true,
            reason: '${l.id} ${s.prompt.length} ${s.prompt}');
        if (s.kind != StepKind.choice) continue;
        expect(prompts.add(s.prompt), true, reason: 'dup ${l.id}');
        final o = s.options;
        expect(o.length, 3, reason: l.id);
        expect(o.toSet().length, 3, reason: '${l.id} ${s.prompt}');
        expect(o.contains(s.answer), true, reason: '${l.id} ${s.prompt}');
        expect(_norm(s.prompt).contains(_norm(s.answer)), false,
            reason: 'answer in prompt ${l.id} ${s.prompt}');
        for (final x in o) {
          expect(_tamil.hasMatch(x), true, reason: '${l.id} $x');
          expect(x.length <= 32, true, reason: '${l.id} ${x.length} $x');
        }
        positions.add(o.indexOf(s.answer));
      }
    }
    expect(positions, {0, 1, 2});
  });
}
