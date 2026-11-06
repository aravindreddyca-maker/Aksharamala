// Run: flutter test tool/dump_curriculum_test.dart
// Dumps every implemented lesson and every exam-bank question to JSON for the
// Excel export (tool/export_full_curriculum_xlsx.py). Writes
// build/curriculum_dump.json.
import 'dart:convert';
import 'dart:io';

import 'package:aksharamala/src/batch/batch_content.dart';
import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/exam/question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dump curriculum', () {
    final worlds = worldsWithBatch(worldsWithLevel3(worldsWithAge56(curriculum)));
    final lessons = <Map<String, Object?>>[];
    for (final w in worlds) {
      for (final l in w.lessons) {
        lessons.add({
          'id': l.id,
          'world': w.id,
          'worldName': w.name,
          'levels': (l.levels.toList()..sort()),
          'title': l.title,
          'subtitle': l.subtitle,
          'kind': l is BatchLesson ? 'steps' : l.kind.name,
          'locale': l.locale,
          'objective': l.learningObjective,
          'prerequisites': l.prerequisites,
          'topic': l is BatchLesson ? l.topic : '',
          'skill': l is BatchLesson ? l.skill : '',
          'challenge': l.challenge,
          'options': l.options,
          'answer': l.answer,
          'story': l.story,
          'steps': l is BatchLesson
              ? [
                  for (var i = 0; i < l.steps.length; i++)
                    {
                      'index': i,
                      'kind': l.steps[i].kind.name,
                      'prompt': l.steps[i].prompt,
                      'glyph': l.steps[i].glyph,
                      'options': l.steps[i].options,
                      'answer': l.steps[i].answer,
                      'isQuestion': l.steps[i].kind.isQuestion,
                      'sourceRecord': l.steps[i].sourceRecord,
                    },
                ]
              : <Map<String, Object?>>[],
        });
      }
    }
    final bank = ExamQuestionBank.defaults();
    final questions = [
      for (final q in bank.questions)
        {
          'id': q.id,
          'lessonId': q.lessonId,
          'level': q.level,
          'world': q.world,
          'topic': q.topic,
          'objective': q.objective,
          'type': q.type.name,
          'prompt': q.prompt,
          'passage': q.passage,
          'glyph': q.glyph,
          'options': q.options,
          'answer': q.correctAnswer,
          'difficulty': q.difficulty,
          'explanation': q.explanation,
          'verification': q.verification.map((v) => v.name).toList(),
        },
    ];
    Directory('build').createSync(recursive: true);
    File('build/curriculum_dump.json').writeAsStringSync(
      jsonEncode({'lessons': lessons, 'questions': questions}),
    );
  });
}
