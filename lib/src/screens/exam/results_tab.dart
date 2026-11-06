import 'package:flutter/material.dart';

import '../../exam/models.dart';
import '../../levels.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'exam_scope.dart';
import 'exam_widgets.dart';

/// Section (b): the latest result, in full.
class ResultsTab extends StatelessWidget {
  const ResultsTab({required this.child, super.key});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final exams = ExamScope.of(context);
    final results = exams.resultsFor(child.id);
    if (results.isEmpty) {
      return const PageBody(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Notice(
            'No results yet. When a child hands in an exam the result appears here.',
            key: Key('no_results'),
          ),
        ),
      );
    }
    return PageBody(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text('Latest result', style: Theme.of(context).textTheme.titleLarge),
          ResultDetail(attemptId: results.first.attemptId),
        ],
      ),
    );
  }
}

/// A result opened from History.
class ResultScreen extends StatelessWidget {
  const ResultScreen({required this.attemptId, super.key});

  final String attemptId;

  @override
  Widget build(BuildContext context) => GradientScaffold(
        appBar: AppBar(
          title: const Text('Exam result'),
          backgroundColor: Colors.transparent,
        ),
        child: PageBody(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [ResultDetail(attemptId: attemptId)],
          ),
        ),
      );
}

/// "Revise: Lesson title, objective: missed 2 of 3" (no internal ids).
String recommendationText(Recommendation r) {
  final title = r.lessonTitle.isEmpty ? 'this lesson' : r.lessonTitle;
  return 'Revise: $title${r.objective.isEmpty ? '' : ', ${r.objective}'}: '
      'missed ${r.missed} of ${r.asked}';
}

/// A topic key such as `alphabet` or `wordBuilder` as words.
String topicLabel(String raw) {
  final spaced =
      raw.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  final t = spaced.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  return t.isEmpty ? raw : t[0].toUpperCase() + t.substring(1);
}

/// Everything the parent needs to know about one submitted exam.
class ResultDetail extends StatelessWidget {
  const ResultDetail({required this.attemptId, super.key});

  final String attemptId;

  @override
  Widget build(BuildContext context) {
    final exams = ExamScope.of(context);
    final attempt = exams.attemptById(attemptId);
    final result = exams.resultFor(attemptId);
    if (attempt == null || result == null) {
      return const Notice('This result could not be found.');
    }
    final verified = exams.verifyResult(attemptId);
    final cfg = attempt.config;
    final scheme = Theme.of(context).colorScheme;
    final parentQs = [
      for (final q in attempt.questions)
        if (q.isParentMarked) q
    ];
    final readiness = exams.readinessFor(attempt.childId, result.level);

    final String verdict;
    final Color verdictColor;
    if (result.isProvisional) {
      verdict = 'Awaiting parent marking';
      verdictColor = const Color(0xFFFFF3CD);
    } else if (result.passed) {
      verdict = 'Passed';
      verdictColor = const Color(0xFFD7F5DD);
    } else {
      verdict = 'Not passed yet';
      verdictColor = const Color(0xFFFFE9D6);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!verified)
          const Notice(
            'Result could not be verified. The stored answers or marks do not '
            'match the checksum, so treat these figures with care.',
            key: Key('tamper_warning'),
            icon: Icons.gpp_maybe_rounded,
            color: Color(0xFFFFD6D6),
          ),
        ExamCard(
          key: const Key('result_summary'),
          color: verdictColor,
          title: '${examTypeLabel(cfg.type)}, Level ${result.level}',
          children: [
            Text(
              '${result.obtainedMarks} of ${result.totalMarks} marks',
              key: const Key('result_marks'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              '${formatPercent(result.percent)} (pass mark ${formatPercent(result.passPercent)})',
              key: const Key('result_percent'),
            ),
            const SizedBox(height: 6),
            Text(verdict,
                key: const Key('result_verdict'),
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            if (result.isProvisional)
              Text(
                '${result.awaitingParentMarks} writing item(s) are not counted until you mark them below.',
                key: const Key('awaiting_note'),
              ),
            const SizedBox(height: 6),
            Text('Taken ${formatDateTime(result.finishedAt)}. '
                'Time: ${formatClock(result.timeTakenSeconds)}. '
                'Attempt ${result.retestNumber}. '
                '${result.unanswered} unanswered.'),
          ],
        ),
        if (parentQs.isNotEmpty)
          ExamCard(
            key: const Key('parent_marking'),
            title: 'Parent marking',
            children: [
              for (final q in parentQs) _MarkRow(attempt: attempt, question: q),
            ],
          ),
        ExamCard(
          title: 'By subject',
          children: [
            for (final e in result.bySubject.entries)
              _ScoreRow(
                key: Key('subject_${e.key}'),
                label: worldNameOf(context, e.key),
                line: e.value,
              ),
          ],
        ),
        if (result.byTopic.isNotEmpty)
          ExamCard(
            title: 'By topic',
            children: [
              for (final e in result.byTopic.entries)
                _ScoreRow(
                    key: Key('topic_${e.key}'),
                    label: topicLabel(e.key),
                    line: e.value),
            ],
          ),
        ExamCard(
          title: 'Revise these lessons',
          children: [
            if (result.recommendations.isEmpty)
              const Text('Nothing to revise from this exam.',
                  key: Key('no_recommendations'))
            else
              for (final r in result.recommendations)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(recommendationText(r),
                      key: Key('recommendation_${r.lessonId}'),
                      style: scriptStyle(
                          recommendationText(r), const TextStyle())),
                ),
          ],
        ),
        ExamCard(
          title: result.level >= lastLevel
              ? 'Level ${result.level} is the highest level'
              : 'Ready for Level ${result.level + 1}?',
          children: [
            Text(readiness.ready ? 'Ready. ${readiness.text}' : readiness.text,
                key: const Key('readiness')),
            if (readiness.weakWorlds.isNotEmpty)
              Text('Subjects below the mark: '
                  '${readiness.weakWorlds.map((w) => worldNameOf(context, w)).join(', ')}'),
          ],
        ),
        ExamCard(
          title: 'Wrong or missed answers (${result.wrong.length})',
          children: [
            if (result.wrong.isEmpty)
              const Text('No wrong answers.', key: Key('no_wrong'))
            else
              for (final w in result.wrong)
                ExpansionTile(
                  key: Key('wrong_${w.questionId}'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(w.prompt,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: scriptStyle(w.prompt,
                          const TextStyle(fontWeight: FontWeight.w700))),
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.given.isEmpty
                          ? 'Child answered: not answered'
                          : 'Child answered: ${w.given}',
                      style: scriptStyle(w.given, const TextStyle()),
                    ),
                    Text('Correct answer: ${w.correct}',
                        style: scriptStyle(
                            w.correct,
                            TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800))),
                    if (w.explanation.isNotEmpty) Text(w.explanation),
                  ],
                ),
          ],
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.line, super.key});

  final String label;
  final ScoreLine line;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Semantics(
          container: true,
          label:
              '$label: ${line.obtained} of ${line.total}, ${formatPercent(line.percent)}',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '$label: ${line.obtained} of ${line.total} (${formatPercent(line.percent)})',
                    style: scriptStyle(label, const TextStyle())),
                const SizedBox(height: 3),
                LinearProgressIndicator(
                  value: (line.percent / 100).clamp(0, 1),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
        ),
      );
}

class _MarkRow extends StatelessWidget {
  const _MarkRow({required this.attempt, required this.question});

  final ExamAttempt attempt;
  final ExamQuestion question;

  @override
  Widget build(BuildContext context) {
    final exams = ExamScope.of(context);
    final mark = attempt.parentMarks[question.id];
    final id = question.id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.prompt,
              style: scriptStyle(question.prompt,
                  const TextStyle(fontWeight: FontWeight.w700))),
          Text(mark == null
              ? 'Not marked yet'
              : mark
                  ? 'Marked correct'
                  : 'Marked incorrect'),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              ChoiceChip(
                key: Key('mark_correct_$id'),
                label: const Text('Correct'),
                selected: mark == true,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) =>
                    exams.markParentQuestion(attempt.id, id, true),
              ),
              ChoiceChip(
                key: Key('mark_incorrect_$id'),
                label: const Text('Incorrect'),
                selected: mark == false,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) =>
                    exams.markParentQuestion(attempt.id, id, false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
