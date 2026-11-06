import 'dart:io';

import 'package:aksharamala/src/teaching/teaching_plan.dart';
import 'package:flutter_test/flutter_test.dart';

bool _contains(String answer, String text) {
  final a = answer.toLowerCase().trim();
  if (a.length <= 2) return false;
  return RegExp('(?<![a-z])${RegExp.escape(a)}(?![a-z])')
      .hasMatch(text.toLowerCase());
}

void main() {
  final text = File('content/teaching/level5_english.json').readAsStringSync();
  final lib = TeachingPlanLibrary.parse([text]);

  test('all 15 Level 5 English plans parse with no issues', () {
    expect(lib.issues, isEmpty);
    expect(lib.plansById.length, 15);
    for (var n = 1; n <= 15; n++) {
      final id = 'english-l5-${n.toString().padLeft(3, '0')}';
      expect(lib.plansById.containsKey(id), isTrue, reason: id);
    }
  });

  test('phase counts and question integrity', () {
    for (final p in lib.plansById.values) {
      final id = p.lessonId;
      expect(p.world, 'english', reason: id);
      expect(p.level, 5, reason: id);
      expect(p.introduce.length, 2, reason: id);
      expect(p.demonstrate.length, 2, reason: id);
      expect(p.guided.length, 2, reason: id);
      expect(p.practice.length, 3, reason: id);
      expect(p.check.length, 3, reason: id);
      expect(p.remediation.explain.isNotEmpty, isTrue, reason: id);
      expect(p.remediation.guided.length, 2, reason: id);
      expect(p.remediation.check.length, 3, reason: id);
      for (final q in p.allQuestions) {
        expect(q.options.length, 3, reason: q.id);
        expect(q.options, contains(q.answer), reason: q.id);
        final wrong = q.options.where((o) => o != q.answer).toSet();
        expect(q.wrongFeedback.keys.toSet(), wrong, reason: q.id);
        expect(q.wrongFeedback.values.toSet().length, wrong.length,
            reason: '${q.id} wrong_feedback must differ per option');
        expect(q.prompt.length, lessThan(220), reason: q.id);
        expect(_contains(q.answer, q.prompt), isFalse,
            reason: '${q.id} answer appears in its prompt');
      }
      for (final q in [...p.guided, ...p.practice]) {
        expect(q.hints.length, 2, reason: q.id);
        expect(q.hints[0], isNot(q.hints[1]), reason: q.id);
        expect(_contains(q.answer, q.hints[0]), isFalse,
            reason: '${q.id} hint 1 gives the answer');
      }
      for (final q in [...p.check, ...p.remediation.check]) {
        expect(q.hints, isEmpty, reason: q.id);
      }
    }
  });

  test('answer positions vary within each lesson', () {
    for (final p in lib.plansById.values) {
      final positions =
          p.allQuestions.map((q) => q.options.indexOf(q.answer)).toSet();
      expect(positions.length, greaterThan(1), reason: p.lessonId);
    }
  });
}
