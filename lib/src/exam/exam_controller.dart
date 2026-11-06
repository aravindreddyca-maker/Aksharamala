/// Runs exams for the parent: start, answer (saved after every answer),
/// resume, submit, history, certificates, parent marks and the optional PIN.
///
/// An exam never changes `progress.json`, stars or lesson completion: this
/// controller only talks to [ExamStore] (`exams.json`).
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import 'evaluation.dart';
import 'exam_store.dart';
import 'hash.dart';
import 'models.dart';
import 'question_bank.dart';
import 'selection.dart';

sealed class StartExamOutcome {
  const StartExamOutcome();
}

class StartExamStarted extends StartExamOutcome {
  const StartExamStarted(this.attempt);

  final ExamAttempt attempt;
}

/// The child already has an unfinished exam. Resume it or discard it first.
class StartExamResume extends StartExamOutcome {
  const StartExamResume(this.attempt);

  final ExamAttempt attempt;
}

/// The retest policy forbids another attempt now.
class StartExamPolicyRefused extends StartExamOutcome {
  const StartExamPolicyRefused(this.reason, {this.retryAt});

  final String reason;

  /// For a waiting-time policy: when the next attempt becomes possible.
  final DateTime? retryAt;
}

/// Too few questions in scope (carries the available count).
class StartExamNotEnoughQuestions extends StartExamOutcome {
  const StartExamNotEnoughQuestions(this.refusal);

  final SelectionRefused refusal;

  int get available => refusal.available;
}

class ExamController extends ChangeNotifier {
  ExamController({
    ExamStore? store,
    ExamQuestionBank? bank,
    DateTime Function()? clock,
    Random? random,
    bool Function(String assetPath)? assetExists,
  })  : _store = store ?? ExamStore(),
        _bank = bank,
        _clock = clock ?? DateTime.now,
        _random = random ?? Random.secure(),
        _assetExists = assetExists;

  final ExamStore _store;
  ExamQuestionBank? _bank;
  final DateTime Function() _clock;
  final Random _random;
  final bool Function(String assetPath)? _assetExists;

  ExamData _data = const ExamData();
  bool loaded = false;
  Future<void> _saving = Future<void>.value();

  /// The bank (built from the app's lessons the first time it is needed).
  ExamQuestionBank get bank => _bank ??= ExamQuestionBank.defaults();

  /// How the last load of `exams.json` went.
  ExamLoadStatus get loadStatus => _store.lastLoadStatus;

  Future<void> load() async {
    _data = await _store.load();
    loaded = true;
    notifyListeners();
  }

  // -- Queries ---------------------------------------------------------------

  ExamData get data => _data;

  ExamAttempt? attemptById(String id) {
    for (final a in _data.attempts) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// The child's unfinished exam, if any (resumable after a restart).
  ExamAttempt? inProgressFor(String childId) {
    for (final a in _data.attempts) {
      if (a.childId == childId && a.status == AttemptStatus.inProgress)
        return a;
    }
    return null;
  }

  /// Every attempt of the child, newest first.
  List<ExamAttempt> attemptsFor(String childId) => [
        for (final a in _data.attempts)
          if (a.childId == childId) a,
      ]..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  ExamResult? resultFor(String attemptId) {
    for (final r in _data.results) {
      if (r.attemptId == attemptId) return r;
    }
    return null;
  }

  /// Results of the child, newest first.
  List<ExamResult> resultsFor(String childId) => [
        for (final r in _data.results)
          if (r.childId == childId) r,
      ]..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));

  List<Certificate> certificatesFor(String childId) => [
        for (final c in _data.certificates)
          if (c.childId == childId) c,
      ];

  Certificate? certificateFor(String childId, int level) {
    for (final c in _data.certificates) {
      if (c.childId == childId && c.level == level) return c;
    }
    return null;
  }

  /// False when the stored result no longer matches its attempt ("result
  /// could not be verified").
  bool verifyResult(String attemptId) {
    final a = attemptById(attemptId);
    final r = resultFor(attemptId);
    if (a == null || r == null) return false;
    return ExamEvaluator.verify(r, a);
  }

  /// Readiness for the next level: ready only after a passed, fully marked
  /// and verifiable final exam at [level].
  Readiness readinessFor(String childId, int level) {
    final results = [
      for (final r in resultsFor(childId))
        if (r.level == level) r,
    ];
    for (final r in results) {
      if (r.type == ExamType.finalLevel &&
          r.passed &&
          !r.isProvisional &&
          verifyResult(r.attemptId)) {
        return r.readiness;
      }
    }
    if (results.isEmpty) {
      return Readiness(
        level: level,
        ready: false,
        text: 'No Level $level exam has been taken yet. '
            'Passing a Level $level final exam shows readiness for Level ${level + 1}.',
      );
    }
    final latest = results.first.readiness;
    return Readiness(
      level: level,
      ready: false,
      weakWorlds: latest.weakWorlds,
      weakObjectives: latest.weakObjectives,
      text: latest.text,
    );
  }

  /// True when the attempt's time limit has run out.
  bool isExpired(ExamAttempt attempt) {
    final limit = attempt.config.timeLimitSeconds;
    if (limit == null) return false;
    return _clock().difference(attempt.startedAt).inSeconds >= limit;
  }

  // -- Settings --------------------------------------------------------------

  ChildExamSettings settingsFor(String childId) =>
      _data.settings[childId] ?? const ChildExamSettings();

  double passPercentFor(String childId) =>
      settingsFor(childId).defaultPassPercent;

  Future<void> setDefaultPassPercent(String childId, double percent) async {
    if (percent < 1 || percent > 100) {
      throw ArgumentError.value(percent, 'percent', 'must be 1 to 100');
    }
    _putSettings(
        childId, settingsFor(childId).copyWith(defaultPassPercent: percent));
    await _persist();
    notifyListeners();
  }

  /// A config with the child's own default pass mark and a fresh id.
  ExamConfig buildConfig({
    required String childId,
    String childName = '',
    required int level,
    required ExamType type,
    List<String> worlds = const [],
    List<String> lessonIds = const [],
    required int questionCount,
    DifficultyMix difficultyMix = const DifficultyMix(),
    double? passPercent,
    double? perWorldMinPercent,
    int? timeLimitSeconds,
    RetestPolicy retestPolicy = const RetestPolicy.unlimited(),
    bool includeParentMarked = false,
  }) =>
      ExamConfig(
        id: _newId('C'),
        childId: childId,
        childName: childName,
        level: level,
        type: type,
        worlds: worlds,
        lessonIds: lessonIds,
        questionCount: questionCount,
        difficultyMix: difficultyMix,
        passPercent: passPercent ?? passPercentFor(childId),
        perWorldMinPercent: perWorldMinPercent,
        timeLimitSeconds: timeLimitSeconds,
        retestPolicy: retestPolicy,
        includeParentMarked: includeParentMarked,
        createdAt: _clock(),
      );

  // -- PIN (optional, per child) -----------------------------------------------

  bool hasPin(String childId) => settingsFor(childId).hasPin;

  /// True when [pin] is right. When no PIN is set there is nothing to check
  /// and this returns true (the existing arithmetic gate still applies).
  bool verifyPin(String childId, String pin) {
    final s = settingsFor(childId);
    if (!s.hasPin) return true;
    return pinHash(s.pinSalt!, pin) == s.pinHash;
  }

  /// Sets or changes the 4-digit PIN. Changing an existing PIN needs
  /// [currentPin]. Returns false when the PIN is not four digits or the
  /// current PIN is wrong.
  Future<bool> setPin(String childId, String newPin,
      {String? currentPin}) async {
    if (!RegExp(r'^\d{4}$').hasMatch(newPin)) return false;
    if (hasPin(childId) && !verifyPin(childId, currentPin ?? '')) return false;
    final salt = _hex(12);
    _putSettings(
        childId, settingsFor(childId).withPin(salt, pinHash(salt, newPin)));
    await _persist();
    notifyListeners();
    return true;
  }

  /// Removes the PIN; needs the current one.
  Future<bool> clearPin(String childId, String currentPin) async {
    if (!hasPin(childId)) return true;
    if (!verifyPin(childId, currentPin)) return false;
    _putSettings(childId, settingsFor(childId).withPin(null, null));
    await _persist();
    notifyListeners();
    return true;
  }

  // -- Running an exam -------------------------------------------------------

  Future<StartExamOutcome> startExam(ExamConfig config, {int? seed}) async {
    final existing = inProgressFor(config.childId);
    if (existing != null) return StartExamResume(existing);

    final prior = [
      for (final a in _data.attempts)
        if (a.childId == config.childId &&
            a.status == AttemptStatus.submitted &&
            a.config.scopeKey == config.scopeKey)
          a,
    ]..sort((a, b) =>
        (a.finishedAt ?? a.startedAt).compareTo(b.finishedAt ?? b.startedAt));

    final policy = config.retestPolicy;
    switch (policy.kind) {
      case RetestKind.unlimited:
        break;
      case RetestKind.maxAttempts:
        if (prior.length >= policy.value) {
          return StartExamPolicyRefused(
              'This exam may be taken at most ${policy.value} time(s); it has been taken ${prior.length}.');
        }
      case RetestKind.waitHours:
        if (prior.isNotEmpty) {
          final last = prior.last.finishedAt ?? prior.last.startedAt;
          final next = last.add(Duration(hours: policy.value));
          if (_clock().isBefore(next)) {
            return StartExamPolicyRefused(
              'Please wait ${policy.value} hour(s) between attempts.',
              retryAt: next,
            );
          }
        }
    }

    final lastAsked = prior.isEmpty
        ? const <String>{}
        : {for (final q in prior.last.questions) q.id};

    final outcome = ExamSelection.build(
      config: config,
      bank: bank.questions,
      seed: seed ?? _random.nextInt(0x7fffffff),
      attemptId: _newId('A'),
      now: _clock(),
      lastAskedIds: lastAsked,
      retestNumber: prior.length + 1,
      assetExists: _assetExists,
    );
    switch (outcome) {
      case SelectionRefused():
        return StartExamNotEnoughQuestions(outcome);
      case SelectionOk(:final attempt):
        _data = ExamData(
          attempts: [..._data.attempts, attempt],
          results: _data.results,
          certificates: _data.certificates,
          settings: _data.settings,
        );
        await _persist();
        notifyListeners();
        return StartExamStarted(attempt);
    }
  }

  /// Records (or changes) the answer to one question and saves immediately.
  /// Returns false when the answer is refused: the attempt is not in progress,
  /// the question is not part of it, the answer is not one of its options, or
  /// the time limit has passed.
  Future<bool> answer(
      String attemptId, String questionId, String answer) async {
    final attempt = attemptById(attemptId);
    if (attempt == null || !attempt.isInProgress) return false;
    if (isExpired(attempt)) return false;
    ExamQuestion? q;
    for (final x in attempt.questions) {
      if (x.id == questionId) q = x;
    }
    if (q == null || q.isParentMarked) return false;
    if (!q.options.contains(answer)) return false;
    final answers = {
      ...attempt.answers,
      questionId: ExamAnswer(answer, _clock())
    };
    _replaceAttempt(attempt.copyWith(answers: answers));
    await _persist();
    notifyListeners();
    return true;
  }

  /// Clears an answer (the child changed their mind and wants it blank).
  Future<bool> clearAnswer(String attemptId, String questionId) async {
    final attempt = attemptById(attemptId);
    if (attempt == null || !attempt.isInProgress) return false;
    if (!attempt.answers.containsKey(questionId)) return true;
    final answers = {...attempt.answers}..remove(questionId);
    _replaceAttempt(attempt.copyWith(answers: answers));
    await _persist();
    notifyListeners();
    return true;
  }

  /// Parent discards an unfinished exam. No result is created.
  Future<bool> abandon(String attemptId) async {
    final attempt = attemptById(attemptId);
    if (attempt == null || !attempt.isInProgress) return false;
    _replaceAttempt(attempt.copyWith(
      status: AttemptStatus.abandoned,
      finishedAt: _clock(),
    ));
    await _persist();
    notifyListeners();
    return true;
  }

  /// Finishes the attempt. Idempotent: a second call returns the stored
  /// result and changes nothing.
  Future<ExamResult> submit(String attemptId) async {
    final attempt = attemptById(attemptId);
    if (attempt == null) throw StateError('No exam attempt $attemptId');
    if (attempt.status == AttemptStatus.abandoned) {
      throw StateError('Attempt $attemptId was discarded');
    }
    if (attempt.status == AttemptStatus.submitted) {
      final stored = resultFor(attemptId);
      if (stored != null) return stored;
      // Submitted but the result was lost: rebuild it from the frozen attempt.
      final rebuilt = ExamEvaluator.evaluate(attempt);
      _putResult(rebuilt);
      _issueCertificateIfEarned(rebuilt, attempt);
      await _persist();
      notifyListeners();
      return rebuilt;
    }
    final finished = attempt.copyWith(
      status: AttemptStatus.submitted,
      finishedAt: _clock(),
    );
    _replaceAttempt(finished);
    final result = ExamEvaluator.evaluate(finished);
    _putResult(result);
    _issueCertificateIfEarned(result, finished);
    await _persist();
    notifyListeners();
    return result;
  }

  /// Parent marks one parent-marked question of a submitted attempt. The
  /// result is recalculated.
  Future<ExamResult?> markParentQuestion(
    String attemptId,
    String questionId,
    bool correct,
  ) async {
    final attempt = attemptById(attemptId);
    if (attempt == null || attempt.status != AttemptStatus.submitted)
      return null;
    final isMarkable =
        attempt.questions.any((q) => q.id == questionId && q.isParentMarked);
    if (!isMarkable) return null;
    final updated = attempt.copyWith(
      parentMarks: {...attempt.parentMarks, questionId: correct},
    );
    _replaceAttempt(updated);
    final result = ExamEvaluator.evaluate(updated);
    _putResult(result);
    _issueCertificateIfEarned(result, updated);
    await _persist();
    notifyListeners();
    return result;
  }

  // -- Certificates ----------------------------------------------------------

  /// The parent deliberately asks for the certificate again: the counter goes
  /// up; no second certificate is created. Null when none exists.
  Future<Certificate?> reissueCertificate(String childId, int level) async {
    final existing = certificateFor(childId, level);
    if (existing == null) return null;
    final updated = existing.reissued(_clock());
    _data = ExamData(
      attempts: _data.attempts,
      results: _data.results,
      certificates: [
        for (final c in _data.certificates) c.id == existing.id ? updated : c,
      ],
      settings: _data.settings,
    );
    await _persist();
    notifyListeners();
    return updated;
  }

  void _issueCertificateIfEarned(ExamResult result, ExamAttempt attempt) {
    if (attempt.config.type != ExamType.finalLevel) return;
    if (!result.passed || result.isProvisional) return;
    if (certificateFor(attempt.childId, attempt.config.level) != null) return;
    final now = _clock();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final code =
        fnv64Hex('${attempt.childId}|${attempt.config.level}|${attempt.id}')
            .substring(0, 4)
            .toUpperCase();
    final cert = Certificate(
      id: 'AKS-L${attempt.config.level}-$y$m$d-$code',
      childId: attempt.childId,
      displayName: attempt.config.childName,
      level: attempt.config.level,
      issuedAt: now,
      attemptId: attempt.id,
    );
    _data = ExamData(
      attempts: _data.attempts,
      results: _data.results,
      certificates: [..._data.certificates, cert],
      settings: _data.settings,
    );
  }

  // -- Internals -------------------------------------------------------------

  void _replaceAttempt(ExamAttempt updated) {
    _data = ExamData(
      attempts: [
        for (final a in _data.attempts) a.id == updated.id ? updated : a
      ],
      results: _data.results,
      certificates: _data.certificates,
      settings: _data.settings,
    );
  }

  void _putResult(ExamResult result) {
    _data = ExamData(
      attempts: _data.attempts,
      results: [
        for (final r in _data.results)
          if (r.attemptId != result.attemptId) r,
        result,
      ],
      certificates: _data.certificates,
      settings: _data.settings,
    );
  }

  void _putSettings(String childId, ChildExamSettings s) {
    _data = ExamData(
      attempts: _data.attempts,
      results: _data.results,
      certificates: _data.certificates,
      settings: {..._data.settings, childId: s},
    );
  }

  /// Saves run one after another so two quick answers cannot interleave.
  Future<void> _persist() {
    final snapshot = _data;
    final next =
        _saving.catchError((Object _) {}).then((_) => _store.save(snapshot));
    _saving = next;
    return next;
  }

  String _hex(int chars) =>
      List.generate(chars, (_) => _random.nextInt(16).toRadixString(16)).join();

  String _newId(String prefix) =>
      '$prefix${_clock().microsecondsSinceEpoch.toRadixString(36)}${_hex(4)}';
}
