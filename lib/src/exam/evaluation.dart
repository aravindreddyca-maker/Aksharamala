/// Marks an attempt (design section 6). Objective questions are marked by
/// comparing the stored answer; parent-marked questions wait for the parent
/// and are left out of the percentage until marked.
library;

import 'hash.dart';
import 'models.dart';

class ExamEvaluator {
  const ExamEvaluator._();

  static String _n(String s) => s.trim();

  /// True when [given] is the question's correct answer.
  static bool isCorrect(ExamQuestion q, String? given) =>
      given != null && _n(given) == _n(q.correctAnswer);

  static ExamResult evaluate(ExamAttempt attempt, {DateTime? now}) {
    final cfg = attempt.config;
    var total = 0;
    var obtained = 0;
    var awaiting = 0;
    var unanswered = 0;
    final subject = <String, _Acc>{};
    final topic = <String, _Acc>{};
    final objective = <String, _Acc>{};
    final byLesson = <String, _LessonAcc>{};
    final wrong = <WrongAnswer>[];

    for (final q in attempt.questions) {
      bool correct;
      String given = '';
      if (q.isParentMarked) {
        final mark = attempt.parentMarks[q.id];
        if (mark == null) {
          awaiting += 1;
          continue;
        }
        correct = mark;
        given = mark ? 'marked correct' : 'marked incorrect';
      } else {
        final a = attempt.answers[q.id]?.answer;
        if (a == null) unanswered += 1;
        given = a ?? '';
        correct = isCorrect(q, a);
      }
      total += q.marks;
      if (correct) obtained += q.marks;
      subject.putIfAbsent(q.world, _Acc.new).add(q.marks, correct);
      topic.putIfAbsent(q.topic, _Acc.new).add(q.marks, correct);
      objective.putIfAbsent(q.objective, _Acc.new).add(q.marks, correct);
      final l = byLesson.putIfAbsent(
          q.lessonId, () => _LessonAcc(q.lessonTitle, q.objective));
      l.asked += 1;
      if (!correct) {
        l.missed += 1;
        wrong.add(WrongAnswer(
          questionId: q.id,
          lessonId: q.lessonId,
          world: q.world,
          objective: q.objective,
          prompt: q.prompt,
          given: given,
          correct: q.isParentMarked ? 'written correctly' : q.correctAnswer,
          explanation: q.explanation,
        ));
      }
    }

    final percent = total == 0 ? 0.0 : obtained * 100 / total;
    final bySubject = {for (final e in subject.entries) e.key: e.value.line()};
    final byTopic = {for (final e in topic.entries) e.key: e.value.line()};
    final byObjective = {
      for (final e in objective.entries) e.key: e.value.line()
    };

    var worldsOk = true;
    final perWorldMin = cfg.perWorldMinPercent;
    if (cfg.type == ExamType.finalLevel && perWorldMin != null) {
      for (final e in bySubject.entries) {
        if (cfg.worlds.isNotEmpty && !cfg.worlds.contains(e.key)) continue;
        if (e.value.percent < perWorldMin) worldsOk = false;
      }
    }
    final passed = total > 0 && percent >= cfg.passPercent && worldsOk;

    final recommendations = [
      for (final e in byLesson.entries)
        if (e.value.missed > 0)
          Recommendation(
            lessonId: e.key,
            lessonTitle: e.value.title,
            objective: e.value.objective,
            missed: e.value.missed,
            asked: e.value.asked,
          ),
    ]..sort((a, b) {
        final c = b.missed.compareTo(a.missed);
        return c != 0 ? c : a.lessonId.compareTo(b.lessonId);
      });

    final readiness = _readiness(
        cfg, passed && awaiting == 0, bySubject, byObjective, awaiting);

    final finished = attempt.finishedAt ?? now ?? attempt.startedAt;
    var seconds = finished.difference(attempt.startedAt).inSeconds;
    if (seconds < 0) seconds = 0;
    final limit = cfg.timeLimitSeconds;
    if (limit != null && seconds > limit) seconds = limit;

    return ExamResult(
      attemptId: attempt.id,
      childId: attempt.childId,
      level: cfg.level,
      type: cfg.type,
      retestNumber: attempt.retestNumber,
      totalMarks: total,
      obtainedMarks: obtained,
      percent: percent,
      passPercent: cfg.passPercent,
      passed: passed,
      bySubject: bySubject,
      byTopic: byTopic,
      byObjective: byObjective,
      timeTakenSeconds: seconds,
      wrong: wrong,
      recommendations: recommendations,
      readiness: readiness,
      awaitingParentMarks: awaiting,
      unanswered: unanswered,
      finishedAt: finished,
      checksum: _checksum(attempt, total, obtained, passed, awaiting),
    );
  }

  static Readiness _readiness(
    ExamConfig cfg,
    bool passedFinalCleanly,
    Map<String, ScoreLine> bySubject,
    Map<String, ScoreLine> byObjective,
    int awaiting,
  ) {
    final level = cfg.level;
    if (cfg.type == ExamType.finalLevel && passedFinalCleanly) {
      return Readiness(
        level: level,
        ready: true,
        text: level >= 5
            ? 'Passed the Level $level final exam. This is the highest level.'
            : 'Passed the Level $level final exam: ready for Level ${level + 1}.',
      );
    }
    final bar = cfg.perWorldMinPercent ?? cfg.passPercent;
    final weakWorlds = [
      for (final e in bySubject.entries)
        if (e.value.percent < bar) e.key,
    ]..sort();
    final weakObjectives = [
      for (final e in byObjective.entries)
        if (e.value.correct < e.value.count) e.key,
    ]..sort();
    final buffer = StringBuffer(cfg.type == ExamType.finalLevel
        ? 'Not ready for Level ${level + 1} yet.'
        : 'Readiness for Level ${level + 1} is decided by passing a Level $level final exam.');
    if (awaiting > 0) {
      buffer
          .write(' $awaiting question(s) still wait for the parent\'s marks.');
    }
    if (weakWorlds.isNotEmpty)
      buffer.write(' Below the mark: ${weakWorlds.join(', ')}.');
    if (weakObjectives.isNotEmpty) {
      buffer.write(' Objectives with misses: ${weakObjectives.join('; ')}.');
    }
    return Readiness(
      level: level,
      ready: false,
      weakWorlds: weakWorlds,
      weakObjectives: weakObjectives,
      text: buffer.toString(),
    );
  }

  static String _checksum(
    ExamAttempt a,
    int total,
    int obtained,
    bool passed,
    int awaiting,
  ) {
    final answers = [
      for (final e in a.answers.entries) '${e.key}=${e.value.answer}',
    ]..sort();
    final marks = [
      for (final e in a.parentMarks.entries) '${e.key}=${e.value ? 1 : 0}',
    ]..sort();
    final correctAnswers = [
      for (final q in a.questions) '${q.id}=${q.correctAnswer}'
    ];
    return fnv64Hex([
      a.id,
      a.childId,
      '${a.retestNumber}',
      a.config.passPercent.toString(),
      correctAnswers.join('\u0001'),
      answers.join('\u0001'),
      marks.join('\u0001'),
      '$total/$obtained/${passed ? 1 : 0}/$awaiting',
    ].join('\u0002'));
  }

  /// True when [result] still matches [attempt]: the checksum over the
  /// answers and marks agrees and re-marking the attempt gives the same
  /// figures. A hand-edited answer, mark or score fails this.
  static bool verify(ExamResult result, ExamAttempt attempt) {
    if (result.attemptId != attempt.id) return false;
    final fresh = evaluate(attempt);
    if (fresh.obtainedMarks != result.obtainedMarks ||
        fresh.totalMarks != result.totalMarks ||
        fresh.passed != result.passed ||
        fresh.awaitingParentMarks != result.awaitingParentMarks) {
      return false;
    }
    return fresh.checksum == result.checksum;
  }
}

class _Acc {
  int obtained = 0;
  int total = 0;
  int correct = 0;
  int count = 0;

  void add(int marks, bool right) {
    total += marks;
    count += 1;
    if (right) {
      obtained += marks;
      correct += 1;
    }
  }

  ScoreLine line() => ScoreLine(
      obtained: obtained, total: total, correct: correct, count: count);
}

class _LessonAcc {
  _LessonAcc(this.title, this.objective);

  final String title;
  final String objective;
  int asked = 0;
  int missed = 0;
}
