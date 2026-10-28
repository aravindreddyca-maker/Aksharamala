import 'package:flutter/foundation.dart';

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

  Future<void> initialise() async {
    final snapshot = await _store.load();
    profiles = List<ChildProfile>.of(snapshot.profiles);
    progress = Map<String, ProgressRecord>.of(snapshot.progress);
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
      .where((lesson) => activeProgress.completedLessons.contains(lesson.id))
      .length;

  double accuracyFor(String worldId) {
    final record = activeProgress;
    final attempts = record.attempts[worldId] ?? 0;
    return attempts == 0 ? 0 : (record.correct[worldId] ?? 0) / attempts;
  }

  Lesson recommendedLesson(LearningWorld world) {
    final unfinished = world.lessons
        .where((lesson) => !activeProgress.completedLessons.contains(lesson.id));
    if (unfinished.isNotEmpty) return unfinished.first;
    // Adaptive review: replay a varied item after mastery.
    final index = (activeProgress.attempts[world.id] ?? 0) % world.lessons.length;
    return world.lessons[index];
  }

  String get adaptiveMessage {
    if (activeProfile == null) return '';
    final stage = activeProfile!.stage;
    final weakWorld = curriculum.reduce((a, b) =>
        accuracyFor(a.id) <= accuracyFor(b.id) ? a : b);
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
    if (curriculum.every((item) =>
        item.lessons.any((l) => completed.contains(l.id)))) {
      badges.add('four-world-hero');
    }
    progress[profile.id] = ProgressRecord(
      completedLessons: completed,
      attempts: attempts,
      correct: correctMap,
      lastPlayed: {...old.lastPlayed, world.id: lesson.id},
      earnedBadges: badges,
    );
    final gained = correct ? 3 : 1;
    final updated = profile.copyWith(stars: profile.stars + gained);
    profiles = profiles.map((item) => item.id == profile.id ? updated : item).toList();
    activeProfile = updated;
    await _persist();
    notifyListeners();
    return gained;
  }

  Future<void> _persist() => _store.save(
        LocalSnapshot(profiles: profiles, progress: progress),
      );
}

