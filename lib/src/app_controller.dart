import 'package:flutter/foundation.dart';

import 'batch/batch_content.dart';
import 'curriculum.dart';
import 'models.dart';
import 'services/local_store.dart';

class AppController extends ChangeNotifier {
  AppController({LocalStore? store}) : _store = store ?? LocalStore();

  final LocalStore _store;
  List<ChildProfile> profiles = [];
  Map<String, ProgressRecord> progress = {};
  ChildProfile? activeProfile;
  bool loaded = false;

  /// Feature flag (a parent setting, off by default): when on, the first batch
  /// of curriculum-pack lessons is added to the Telugu and Number Galaxy worlds.
  bool newLessonsEnabled = false;

  /// The worlds the child sees: the existing curriculum, plus the new lessons
  /// when the flag is on. Existing quests are never changed or removed.
  List<LearningWorld> get worlds {
    final all = newLessonsEnabled ? worldsWithBatch(curriculum) : curriculum;
    final stage = activeProfile?.stage;
    if (stage == null) return all;
    return [for (final world in all) world.forStage(stage)];
  }

  Future<void> setNewLessons(bool value) async {
    if (value == newLessonsEnabled) return;
    newLessonsEnabled = value;
    await _persist();
    notifyListeners();
  }

  Future<void> initialise() async {
    final snapshot = await _store.load();
    profiles = List<ChildProfile>.of(snapshot.profiles);
    progress = Map<String, ProgressRecord>.of(snapshot.progress);
    newLessonsEnabled = snapshot.newLessons;
    if (profiles.isNotEmpty) activeProfile = profiles.first;
    loaded = true;
    notifyListeners();
  }

  Future<void> addProfile(String name, int age, String avatar) async {
    final profile = ChildProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      age: age,
      avatar: avatar,
    );
    profiles = [...profiles, profile];
    activeProfile = profile;
    progress[profile.id] = ProgressRecord.empty();
    await _persist();
    notifyListeners();
  }

  void selectProfile(ChildProfile profile) {
    activeProfile = profile;
    notifyListeners();
  }

  ProgressRecord get activeProgress => activeProfile == null
      ? ProgressRecord.empty()
      : progress[activeProfile!.id] ?? ProgressRecord.empty();

  int completedInWorld(LearningWorld world) => world.lessons
      .where((lesson) => activeProgress.completedWithLegacy.contains(lesson.id))
      .length;

  double accuracyFor(String worldId) {
    final record = activeProgress;
    final attempts = record.attempts[worldId] ?? 0;
    return attempts == 0 ? 0 : (record.correct[worldId] ?? 0) / attempts;
  }

  Lesson recommendedLesson(LearningWorld world) {
    // [worlds] already returns the active profile's age-filtered worlds. Keep
    // this scoped to the world it receives so deliberate subsets are not
    // silently filtered a second time.
    final candidates = world.lessons;
    final done = activeProgress.completedWithLegacy;
    final unfinished = candidates.where(
      (lesson) => !done.contains(lesson.id),
    );
    if (unfinished.isNotEmpty) return unfinished.first;
    // Adaptive review: replay a varied item after mastery.
    final index = (activeProgress.attempts[world.id] ?? 0) % candidates.length;
    return candidates[index];
  }

  String get adaptiveMessage {
    if (activeProfile == null) return '';
    final stage = activeProfile!.stage;
    final weakWorld = curriculum.reduce(
      (a, b) => accuracyFor(a.id) <= accuracyFor(b.id) ? a : b,
    );
    if ((activeProgress.attempts[weakWorld.id] ?? 0) >= 2 &&
        accuracyFor(weakWorld.id) < .7) {
      return 'Practice pick: ${weakWorld.name} — a gentle review is ready.';
    }
    return '${stage.focus}. Your next adventure is ready!';
  }

  Future<int> recordResult({
    required LearningWorld world,
    required Lesson lesson,
    required bool correct,
  }) async {
    final profile = activeProfile;
    if (profile == null) return 0;
    final old = activeProgress;
    final completed = {...old.completedLessons, if (correct) lesson.id};
    final attempts = {...old.attempts};
    final correctMap = {...old.correct};
    attempts[world.id] = (attempts[world.id] ?? 0) + 1;
    if (correct) correctMap[world.id] = (correctMap[world.id] ?? 0) + 1;
    final badges = {...old.earnedBadges};
    if (completed.isNotEmpty) badges.add('first-step');
    if (completed.length >= 4) badges.add('world-walker');
    if (completed.length >= 8) badges.add('bright-star');
    if (curriculum.every(
      (item) => item.lessons.any((l) => completed.contains(l.id)),
    )) {
      badges.add(ProgressRecord.allWorldHeroBadge);
    }
    // Stars: finishing a quest pays 3, a mistake pays 1, but a quest never pays
    // more than 3 in total. So a mistake then a right answer still adds up to
    // 3, and replaying a finished quest is practice only. Without a cap a
    // child could tap "Play again" for endless stars.
    final paid = old.starsPaidBy(lesson.id);
    final wanted = correct ? 3 : 1;
    final room = ProgressRecord.starsPerQuest - paid;
    final gained = room <= 0 ? 0 : (wanted < room ? wanted : room);
    progress[profile.id] = ProgressRecord(
      completedLessons: completed,
      attempts: attempts,
      correct: correctMap,
      lastPlayed: {...old.lastPlayed, world.id: lesson.id},
      earnedBadges: badges,
      questStars: {...old.questStars, lesson.id: paid + gained},
    );
    final updated = profile.copyWith(stars: profile.stars + gained);
    profiles =
        profiles.map((item) => item.id == profile.id ? updated : item).toList();
    activeProfile = updated;
    await _persist();
    notifyListeners();
    return gained;
  }

  Future<void> _persist() => _store.save(
        LocalSnapshot(
          profiles: profiles,
          progress: progress,
          newLessons: newLessonsEnabled,
        ),
      );
}
