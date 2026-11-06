// Run: flutter test tool/teaching_audit_test.dart
// Writes audit/TEACHING_LESSON_AUDIT.csv: one row per implemented lesson,
// classified by what the lesson actually contains in code.
import 'dart:io';

import 'package:aksharamala/src/batch/batch_content.dart';
import 'package:aksharamala/src/batch/batch_lesson.dart';
import 'package:aksharamala/src/curriculum.dart';
import 'package:aksharamala/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

String q(String s) => '"${s.replaceAll('"', '""').replaceAll('\n', ' ')}"';

void main() {
  test('teaching audit', () {
    final worlds = worldsWithBatch(worldsWithAge56(curriculum));
    final rows = <String>[
      'lesson_id,world,levels,kind,class,intro_steps,demonstration_steps,'
          'guided_steps,question_steps,write_steps,examples_listed,'
          'worked_example,mastery_check,remediation,notes',
    ];
    final counts = <String, int>{};
    for (final w in worlds) {
      for (final l in w.lessons) {
        var intro = 0, guided = 0, questions = 0, writes = 0, examples = 0;
        String cls;
        var notes = '';
        if (l is BatchLesson) {
          intro = l.steps.where((s) => s.kind == StepKind.listen).length;
          writes = l.steps.where((s) => s.kind == StepKind.write).length;
          guided = l.steps
              .where((s) =>
                  s.kind == StepKind.write && s.writeMode == WriteMode.guided)
              .length;
          questions = l.questions.length;
          examples = l.examples.length;
          if (intro > 0 && questions > 0) {
            cls = 'Partial teaching experience';
            notes = 'listen/see intro, then questions with instant feedback; '
                'no stepwise demonstration, no separate mastery check, '
                'no remedial path';
          } else if (questions > 0) {
            cls = 'Practice-only';
          } else {
            cls = 'Missing or inaccessible';
          }
        } else {
          questions = l.options.isNotEmpty ? 1 : 0;
          cls = questions > 0 ? 'Quiz-only' : 'Missing or inaccessible';
          notes = l.story.isNotEmpty ? 'story with one question' : '';
        }
        counts[cls] = (counts[cls] ?? 0) + 1;
        rows.add([
          l.id,
          w.id,
          (l.levels.toList()..sort()).join('|'),
          l is BatchLesson ? 'steps' : 'quiz',
          cls,
          intro,
          0,
          guided,
          questions,
          writes,
          examples,
          'no',
          'no',
          'no',
          q(notes),
        ].join(','));
      }
    }
    File('audit/TEACHING_LESSON_AUDIT.csv')
        .writeAsStringSync('﻿${rows.join('\n')}\n');
    File('audit/TEACHING_LESSON_AUDIT_SUMMARY.txt')
        .writeAsStringSync(counts.entries.map((e) => '${e.key}: ${e.value}\n').join());
  });
}
