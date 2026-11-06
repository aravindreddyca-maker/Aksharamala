/// Builds an exam attempt from the bank (design section 4). Deterministic for
/// a given seed: the same bank, config, seed and previous-attempt list always
/// give the same questions in the same order with the same option order.
library;

import 'dart:math';

import 'hash.dart';
import 'models.dart';

sealed class SelectionOutcome {
  const SelectionOutcome();
}

class SelectionOk extends SelectionOutcome {
  const SelectionOk(this.attempt);

  final ExamAttempt attempt;
}

/// The exam could not be built honestly. Nothing is invented to fill it.
class SelectionRefused extends SelectionOutcome {
  const SelectionRefused({
    required this.requested,
    required this.available,
    required this.reason,
  });

  final int requested;

  /// How many playable questions the chosen scope has. The UI can offer an
  /// exam of this size when it is above 0.
  final int available;
  final String reason;
}

class ExamSelection {
  const ExamSelection._();

  /// Playable, in-scope candidates (before any count is applied).
  static List<ExamQuestion> candidates(
    ExamConfig config,
    Iterable<ExamQuestion> bank, {
    bool Function(String assetPath)? assetExists,
  }) {
    final exists = assetExists ?? (_) => true;
    final worlds = config.worlds.toSet();
    final lessons = config.lessonIds.toSet();
    final seen = <String>{};
    final out = <ExamQuestion>[];
    for (final q in bank) {
      if (!q.levels.contains(config.level)) continue;
      if (q.isParentMarked && !config.includeParentMarked) continue;
      switch (config.type) {
        case ExamType.chapter:
          if (!lessons.contains(q.lessonId)) continue;
        case ExamType.subject:
          if (!worlds.contains(q.world)) continue;
        case ExamType.finalLevel:
          if (worlds.isNotEmpty && !worlds.contains(q.world)) continue;
      }
      if (!_playable(q, exists)) continue;
      if (!seen.add(q.id)) continue;
      out.add(q);
    }
    out.sort((a, b) => a.id.compareTo(b.id));
    return out;
  }

  static bool _playable(ExamQuestion q, bool Function(String) exists) {
    if (q.prompt.trim().isEmpty) return false;
    if (!q.isParentMarked) {
      if (q.options.length < 2 || !q.options.contains(q.correctAnswer))
        return false;
    }
    if (q.optionPictures.values.any((p) => !exists(p))) return false;
    final cover = q.promptPicture;
    if (cover != null && !exists(cover)) return false;
    return true;
  }

  static SelectionOutcome build({
    required ExamConfig config,
    required Iterable<ExamQuestion> bank,
    required int seed,
    required String attemptId,
    required DateTime now,
    Set<String> lastAskedIds = const {},
    int retestNumber = 1,
    bool Function(String assetPath)? assetExists,
  }) {
    final n = config.questionCount;
    if (n <= 0) {
      return SelectionRefused(
          requested: n,
          available: 0,
          reason: 'The question count must be at least 1.');
    }
    final pool = candidates(config, bank, assetExists: assetExists);
    if (pool.isEmpty) {
      return SelectionRefused(
        requested: n,
        available: 0,
        reason:
            'There are no questions for this scope at Level ${config.level}.',
      );
    }
    if (config.type == ExamType.finalLevel && config.worlds.isNotEmpty) {
      for (final w in config.worlds) {
        if (!pool.any((q) => q.world == w)) {
          return SelectionRefused(
            requested: n,
            available: pool.length,
            reason: 'World "$w" has no questions at Level ${config.level}.',
          );
        }
      }
    }
    if (pool.length < n) {
      return SelectionRefused(
        requested: n,
        available: pool.length,
        reason:
            'This scope has ${pool.length} questions at Level ${config.level}, '
            'fewer than the $n asked for.',
      );
    }

    final rng = Random(seed);
    final buckets = _difficultyTargets(pool, n, config.difficultyMix);
    final picked = <ExamQuestion>[];
    final used = <String>{};

    List<ExamQuestion> unused(Iterable<ExamQuestion> from) => [
          for (final q in from)
            if (!used.contains(q.id)) q
        ];

    void take(List<ExamQuestion> qs) {
      for (final q in qs) {
        used.add(q.id);
        picked.add(q);
        final i = _bucket(q);
        buckets[i] -= 1;
      }
    }

    // Final exam: a minimum from every chosen world first.
    if (config.type == ExamType.finalLevel) {
      final worlds = ({for (final q in pool) q.world}.toList()..sort());
      final quota = max(1, n ~/ (2 * worlds.length));
      for (final w in worlds) {
        final inWorld = pool.where((q) => q.world == w).toList();
        final want = min(quota, inWorld.length);
        take(_pickPhased(inWorld, want, buckets, rng, lastAskedIds));
      }
    }
    if (picked.length < n) {
      take(_pickPhased(
          unused(pool), n - picked.length, buckets, rng, lastAskedIds));
    }

    // Order shown: seeded shuffle, then each question's options shuffled.
    final order = [...picked]..sort((a, b) => a.id.compareTo(b.id));
    order.shuffle(rng);
    final frozen = [for (final q in order) _shuffledOptions(q, seed)];

    return SelectionOk(ExamAttempt(
      id: attemptId,
      config: config,
      childId: config.childId,
      startedAt: now,
      seed: seed,
      questions: frozen,
      retestNumber: retestNumber,
    ));
  }

  static int _bucket(ExamQuestion q) => (q.difficulty.clamp(1, 3)) - 1;

  /// How many questions to take at each difficulty: proportional to the mix,
  /// never more than exist.
  static List<int> _difficultyTargets(
      List<ExamQuestion> pool, int n, DifficultyMix mix) {
    final avail = [0, 0, 0];
    for (final q in pool) {
      avail[_bucket(q)] += 1;
    }
    var w = [mix.easy, mix.medium, mix.hard].map((e) => e < 0 ? 0 : e).toList();
    if (w.every((e) => e == 0)) w = [1, 1, 1];
    final total = w.fold<int>(0, (a, b) => a + b);
    final target = [0, 0, 0];
    for (var taken = 0; taken < n; taken++) {
      var best = -1;
      var bestDeficit = -double.infinity;
      for (var d = 0; d < 3; d++) {
        if (target[d] >= avail[d]) continue;
        final deficit = n * w[d] / total - target[d];
        if (deficit > bestDeficit) {
          bestDeficit = deficit;
          best = d;
        }
      }
      if (best < 0) break;
      target[best] += 1;
    }
    return target;
  }

  /// Prefers (1) questions not asked last time and (2) the difficulty mix,
  /// relaxing the mix only when it cannot be met.
  static List<ExamQuestion> _pickPhased(
    List<ExamQuestion> pool,
    int n,
    List<int> buckets,
    Random rng,
    Set<String> lastAsked,
  ) {
    final fresh = [
      for (final q in pool)
        if (!lastAsked.contains(q.id)) q
    ];
    final old = [
      for (final q in pool)
        if (lastAsked.contains(q.id)) q
    ];
    final result = <ExamQuestion>[];
    final local = [...buckets];
    final taken = <String>{};

    void phase(List<ExamQuestion> from, bool respect) {
      if (result.length >= n) return;
      final left = [
        for (final q in from)
          if (!taken.contains(q.id)) q
      ];
      final got = _roundRobin(left, n - result.length, local, respect, rng);
      for (final q in got) {
        taken.add(q.id);
        local[_bucket(q)] -= 1;
      }
      result.addAll(got);
    }

    phase(fresh, true);
    phase(old, true);
    phase(fresh, false);
    phase(old, false);
    return result;
  }

  /// One question per lesson per round, so no lesson fills the exam while
  /// others are still unrepresented.
  static List<ExamQuestion> _roundRobin(
    List<ExamQuestion> from,
    int n,
    List<int> buckets,
    bool respect,
    Random rng,
  ) {
    final byLesson = <String, List<ExamQuestion>>{};
    for (final q in from) {
      byLesson.putIfAbsent(q.lessonId, () => []).add(q);
    }
    final lessonIds = byLesson.keys.toList()..sort();
    lessonIds.shuffle(rng);
    for (final id in lessonIds) {
      final list = byLesson[id]!..sort((a, b) => a.id.compareTo(b.id));
      list.shuffle(rng);
    }
    final local = [...buckets];
    final out = <ExamQuestion>[];
    while (out.length < n) {
      var any = false;
      for (final id in lessonIds) {
        if (out.length >= n) break;
        final list = byLesson[id]!;
        final idx = respect
            ? list.indexWhere((q) => local[_bucket(q)] > 0)
            : (list.isEmpty ? -1 : 0);
        if (idx < 0) continue;
        final q = list.removeAt(idx);
        local[_bucket(q)] -= 1;
        out.add(q);
        any = true;
      }
      if (!any) break;
    }
    return out;
  }

  static ExamQuestion _shuffledOptions(ExamQuestion q, int seed) {
    if (q.options.length < 2) return q;
    final qSeed =
        int.parse(fnv64Hex('$seed|${q.id}').substring(0, 7), radix: 16);
    final options = [...q.options]..shuffle(Random(qSeed));
    return q.withOptions(options);
  }
}
