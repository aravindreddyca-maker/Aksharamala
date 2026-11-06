import 'package:flutter/material.dart';

import '../../exam/models.dart';
import '../../models.dart';
import 'exam_scope.dart';
import 'exam_widgets.dart';
import 'results_tab.dart';

/// Section (c): every attempt of the child, newest first.
class HistoryTab extends StatelessWidget {
  const HistoryTab({required this.child, super.key});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final exams = ExamScope.of(context);
    final attempts = exams.attemptsFor(child.id);
    if (attempts.isEmpty) {
      return const PageBody(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Notice('No exams taken yet.', key: Key('no_history')),
        ),
      );
    }
    return PageBody(
      child: ListView.builder(
        key: const Key('history_list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: attempts.length,
        itemBuilder: (context, i) {
          final a = attempts[i];
          final r = exams.resultFor(a.id);
          final String status;
          switch (a.status) {
            case AttemptStatus.inProgress:
              status =
                  'Unfinished (${a.answeredCount} of ${a.questions.length} answered)';
            case AttemptStatus.abandoned:
              status = 'Discarded';
            case AttemptStatus.submitted:
              status = r == null
                  ? 'Handed in'
                  : r.isProvisional
                      ? 'Awaiting parent marking'
                      : '${formatPercent(r.percent)}: ${r.passed ? 'Passed' : 'Not passed yet'}';
          }
          return Card(
            child: ListTile(
              key: Key('history_${a.id}'),
              minTileHeight: 64,
              title: Text(
                  '${examTypeLabel(a.config.type)}, Level ${a.config.level}'),
              subtitle: Text('${formatDateTime(a.startedAt)}\n'
                  'Attempt ${a.retestNumber}: $status'),
              isThreeLine: true,
              trailing:
                  r == null ? null : const Icon(Icons.chevron_right_rounded),
              onTap: r == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ResultScreen(attemptId: a.id),
                        ),
                      ),
            ),
          );
        },
      ),
    );
  }
}
