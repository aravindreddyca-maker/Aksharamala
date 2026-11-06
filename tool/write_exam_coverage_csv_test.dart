// Regenerates audit/EXAMINATION_QUESTION_BANK_COVERAGE.csv from the real bank.
// Run: flutter test tool/write_exam_coverage_csv_test.dart
import 'dart:io';

import 'package:aksharamala/src/app_controller.dart';
import 'package:aksharamala/src/exam/question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('write coverage csv', () {
    final bank = ExamQuestionBank.defaults();
    final rows = bank.coverage(AppController().allWorlds);
    final b = StringBuffer('\u{FEFF}level,world,implemented_lessons,'
        'lessons_that_can_supply_a_question,question_items_available_today,'
        'largest_chapter_or_subject_exam_possible_without_repeats,verified_questions,'
        'unverified_questions_(TTS_audio_or_unreviewed_regional_text),'
        'proposed_lessons_not_yet_playable,status\n');
    for (final r in rows) {
      final proposed = r.level >= 3 ? 15 : 0;
      final status = r.questions == 0
          ? 'NO EXAM POSSIBLE: no questions'
          : r.questions < 10
              ? 'too few for a subject exam (needs 10+)'
              : 'ready (bank built from implemented lessons)';
      b.write('${r.level},${r.worldName},${r.lessons},${r.lessonsWithQuestions},'
          '${r.questions},${r.questions},${r.educatorVerified},'
          '${r.questions - r.educatorVerified},$proposed,$status\n');
    }
    File('audit/EXAMINATION_QUESTION_BANK_COVERAGE.csv').writeAsStringSync(b.toString());
    final per = {for (var l = 1; l <= 5; l++) l: bank.forLevel(l).length};
    // ignore: avoid_print
    print('levels $per rejected ${bank.rejected.length}');
  });
}
