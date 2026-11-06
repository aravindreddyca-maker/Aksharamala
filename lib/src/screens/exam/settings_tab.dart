import 'package:flutter/material.dart';

import '../../app.dart';
import '../../exam/question_bank.dart';
import '../../levels.dart';
import '../../models.dart';
import 'exam_scope.dart';
import 'exam_widgets.dart';
import 'pin_dialogs.dart';

/// Section (e): what the question bank holds, and the exam settings.
class SettingsTab extends StatelessWidget {
  const SettingsTab({required this.child, super.key});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final exams = ExamScope.of(context);
    final rows = exams.bank.coverage(AppScope.of(context).allWorlds);
    var pending = 0;
    var tts = 0;
    var verified = 0;
    var total = 0;
    for (final r in rows) {
      pending += r.educatorPending;
      tts += r.ttsUnverified;
      verified += r.educatorVerified;
      total += r.questions;
    }
    final hasPin = exams.hasPin(child.id);
    final pass = exams.passPercentFor(child.id).round();

    return PageBody(
      child: ListView(
        key: const Key('settings_list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          ExamCard(
            title: 'Exam settings for ${child.name}',
            children: [
              CountStepper(
                label: 'Default pass mark',
                value: pass,
                min: 10,
                max: 100,
                step: 5,
                unit: '%',
                keyPrefix: 'default_pass',
                onChanged: (v) =>
                    exams.setDefaultPassPercent(child.id, v.toDouble()),
              ),
              const SizedBox(height: 10),
              Text(
                hasPin ? 'An exam PIN is set.' : 'No exam PIN is set.',
                key: const Key('pin_status'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Text(
                'The PIN is asked for before the Examination Centre opens for this child.',
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  if (!hasPin)
                    FilledButton(
                      key: const Key('pin_set'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48)),
                      onPressed: () => showPinDialog(context,
                          controller: exams,
                          childId: child.id,
                          purpose: PinPurpose.set),
                      child: const Text('Set PIN'),
                    )
                  else ...[
                    OutlinedButton(
                      key: const Key('pin_change'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48)),
                      onPressed: () => showPinDialog(context,
                          controller: exams,
                          childId: child.id,
                          purpose: PinPurpose.change),
                      child: const Text('Change PIN'),
                    ),
                    OutlinedButton(
                      key: const Key('pin_clear'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48)),
                      onPressed: () => showPinDialog(context,
                          controller: exams,
                          childId: child.id,
                          purpose: PinPurpose.clear),
                      child: const Text('Remove PIN'),
                    ),
                  ],
                ],
              ),
            ],
          ),
          ExamCard(
            title: 'Question bank',
            children: [
              Text(
                  '$total auto-marked questions in all. '
                  'Educator-verified: $verified.',
                  key: const Key('bank_total')),
              Text('Waiting for an educator to check the language: $pending.',
                  key: const Key('flag_pending')),
              Text('Spoken by the phone voice, not yet checked: $tts.',
                  key: const Key('flag_tts')),
              const SizedBox(height: 4),
              const Text(
                'Questions come only from lessons already in the app. '
                'Nothing is invented. Telugu, Hindi and Tamil questions stay '
                'unverified until a person records that an educator checked them.',
              ),
            ],
          ),
          for (final level in allLevels)
            _LevelCoverage(
              level: level,
              rows: [
                for (final r in rows)
                  if (r.level == level) r
              ],
            ),
        ],
      ),
    );
  }
}

class _LevelCoverage extends StatelessWidget {
  const _LevelCoverage({required this.level, required this.rows});

  final int level;
  final List<CoverageRow> rows;

  @override
  Widget build(BuildContext context) {
    final count = rows.fold<int>(0, (a, r) => a + r.questions);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        key: Key('coverage_level_$level'),
        title: Text('Level $level: $count questions'),
        subtitle: Text(levelInfo(level).tagline),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (count == 0)
            Text(
              level == lastLevel
                  ? 'No questions yet - Level $level lessons are coming.'
                  : 'No questions yet for this level.',
              key: Key('coverage_empty_$level'),
            ),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${r.worldName}: ${r.questions} questions from '
                '${r.lessonsWithQuestions} of ${r.lessons} lessons'
                '${r.parentMarked > 0 ? ', ${r.parentMarked} parent-marked' : ''}'
                '${r.educatorPending > 0 ? ', ${r.educatorPending} educator pending' : ''}'
                '${r.ttsUnverified > 0 ? ', ${r.ttsUnverified} voice unverified' : ''}',
                key: Key('coverage_${level}_${r.worldId}'),
              ),
            ),
        ],
      ),
    );
  }
}
