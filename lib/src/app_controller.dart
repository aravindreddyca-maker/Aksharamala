import 'package:flutter/foundation.dart';

import 'batch/batch_content.dart';
import 'batch/batch_lesson.dart';
import 'curriculum.dart';
import 'levels.dart';
import 'models.dart';
import 'services/local_store.dart';
import 'teaching/teaching_plan.dart';
import 'teaching/teaching_progress.dart';

class AppController extends ChangeNotifier {
  /// [teachingPlanLoader] supplies the teaching plan files (the app passes
  /// [assetTeachingPlanLoader]). With none, no lesson has a plan and every
  /// lesson keeps its existing screen.
  ///
  /// With [parseTeachingPlansInBackground] the plan files are split into
  /// lessons on another isolate and start-up does not wait for them (the app
  /// sets it; tests leave it off so loading is immediate and deterministic).
  AppController({
    LocalStore? store,
    this.teachingPlanLoader,
    this.parseTeachingPlansInBackground = false,
  }) : _store = store ?? LocalStore();

  final LocalStore _store;
  final TeachingPlanLoader? teachingPlanLoader;
  final bool parseTeachingPlansInBackground;

  /// Completes when the teaching plans are indexed (already complete when
  /// there is no loader).
  Future<void> teachingPlansReady = Future<void>.value();

  /// The teaching plans that loaded and validated, by lesson id.
  TeachingPlanLibrary teachingPlans = TeachingPlanLibrary.empty;
  List<ChildProfile> profiles = [];
  Map<String, ProgressRecord> progress = {};
  ChildProfile? activeProfile;
  bool loaded = false;

  /// Every lesson there is, across all levels. Which of them a child sees is
  /// decided by the child's level (see [worlds]).
  List<LearningWorld> get allWorlds =>
      worldsWithBatch(worldsWithLevel3(worldsWithAge56(curriculum)));

  /// The worlds the child sees: the lessons of the active child's level (Level
  /// 1 when no child is chosen yet). A world with no lessons at that level is
  /// still listed, empty: the screens show it as "coming soon".
  List<LearningWorld> get worlds {
    final level = activeProfile?.level ?? firstLevel;
    return [for (final world in allWorlds) world.forLevel(level)];
  }

  Future<void> initialise() async {
    if (parseTeachingPlansInBackground) {
      // Do not hold the app start-up for it; lessons without a plan yet simply
      // open their existing screen.
      teachingPlansReady = loadTeachingPlans().then((_) => notifyListeners());
    } else {
      await loadTeachingPlans();
    }
    final snapshot = await _store.load();
    profiles = List<ChildProfile>.of(snapshot.profiles);
    progress = Map<String, ProgressRecord>.of(snapshot.progress);
    if (profiles.isNotEmpty) activeProfile = profiles.first;
    loaded = true;
    notifyListeners();
  }

  /// Loads the teaching plans. A missing or broken plan file never stops the
  /// app: the lessons concerned simply keep their existing screens.
  Future<void> loadTeachingPlans() async {
    final loader = teachingPlanLoader;
    if (loader == null) return;
    try {
      final files = await loader();
      final index = parseTeachingPlansInBackground
          ? await compute(indexPlanFiles, files)
          : indexPlanFiles(files);
      teachingPlans = TeachingPlanLibrary.fromIndex(index);
    } on Object {
      teachingPlans = TeachingPlanLibrary.empty;
    }
  }

  /// The teaching plan for [lessonId], or null when it has none.
  TeachingPlan? planFor(String lessonId) => teachingPlans.planFor(lessonId);

  /// What the active child has done in a taught lesson.
  TeachingProgress teachingProgressFor(String lessonId) =>
      activeProgress.teaching[lessonId] ?? TeachingProgress.empty;

  /// Saves teaching progress for the active child. It never touches stars,
  /// finished lessons or exam records.
  Future<void> saveTeachingProgress(
    String lessonId,
    TeachingProgress value,
  ) async {
    final profile = activeProfile;
    if (profile == null) return;
    final stamped = value.copyWith(
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    final old = activeProgress;
    progress[profile.id] =
        old.withTeaching({...old.teaching, lessonId: stamped});
    await _persist();
    notifyListeners();
  }

  /// The child passed the understanding check (or the remediation check).
  /// Saves the teaching progress as mastered and, the first time, sends the
  /// result through [recordResult] so stars, finished lessons and unlocks work
  /// exactly as for every other quest. Returns the stars gained.
  Future<int> recordTeachingMastery({
    required LearningWorld world,
    required Lesson lesson,
    required TeachingProgress teaching,
  }) async {
    await saveTeachingProgress(
      lesson.id,
      teaching.copyWith(mastery: MasteryStatus.mastered, clearPhase: true),
    );
    if (activeProgress.completedLessons.contains(lesson.id)) return 0;
    return recordResult(world: world, lesson: lesson, correct: true);
  }

  /// The child used up the remediation cycles. The status is saved, the lesson
  /// is NOT marked finished and no stars are paid; the child can carry on.
  Future<void> recordTeachingNeedsSupport({
    required Lesson lesson,
    required TeachingProgress teaching,
  }) =>
      saveTeachingProgress(
        lesson.id,
        teaching.copyWith(
          mastery: activeProgress.teaching[lesson.id]?.isMastered ?? false
              ? MasteryStatus.mastered
              : MasteryStatus.needsSupport,
          clearPhase: true,
        ),
      );

  /// What the active child has done with a rhyme.
  RhymeProgress rhymeProgressFor(String rhymeId) =>
      activeProgress.rhymes[rhymeId] ?? const RhymeProgress();

  /// The active child heard the rhyme (tapped a line or Hear all). Saves only
  /// the first time; never touches stars, finished lessons or exams.
  Future<void> markRhymeHeard(String rhymeId) =>
      _saveRhyme(rhymeId, heard: true, done: false);

  /// The active child finished the rhyme's word game. No stars are paid.
  Future<void> markRhymeDone(String rhymeId) =>
      _saveRhyme(rhymeId, heard: true, done: true);

  Future<void> _saveRhyme(
    String rhymeId, {
    required bool heard,
    required bool done,
  }) async {
    final profile = activeProfile;
    if (profile == null) return;
    final old = activeProgress;
    final before = old.rhymes[rhymeId] ?? const RhymeProgress();
    final next = RhymeProgress(
      heard: before.heard || heard,
      done: before.done || done,
    );
    if (next.heard == before.heard && next.done == before.done) return;
    progress[profile.id] = old.withRhymes({...old.rhymes, rhymeId: next});
    await _persist();
    notifyListeners();
  }

  /// Adds a child who starts at [level] (1 to 5).
  Future<void> createProfile({
    required String name,
    required int level,
    required String avatar,
  }) async {
    final profile = ChildProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      // Kept only for the save format; nothing reads or shows it.
      age: stageForLevel(level).representativeAge,
      level: clampLevel(level),
      avatar: avatar,
    );
    profiles = [...profiles, profile];
    activeProfile = profile;
    progress[profile.id] = ProgressRecord.empty();
    await _persist();
    notifyListeners();
  }

  /// Older shape of [createProfile], from when a child was entered by age. The
  /// age only picks the level that age band became.
  Future<void> addProfile(String name, int age, String avatar) => createProfile(
        name: name,
        level: levelForLegacyAge(age),
        avatar: avatar,
      );

  /// Anyone can pick any level at any time. It only changes which lessons are
  /// shown; nothing earned (stars, finished lessons, badges) is touched.
  Future<void> setLevel(int level) async {
    final profile = activeProfile;
    if (profile != null) await setLevelFor(profile.id, level);
  }

  /// The same for any saved profile, whether or not it is the one playing.
  Future<void> setLevelFor(String profileId, int level) async {
    final index = profiles.indexWhere((p) => p.id == profileId);
    if (index < 0) return;
    final profile = profiles[index];
    final target = clampLevel(level);
    if (profile.level == target) return;
    final updated = profile.copyWith(level: target);
    profiles = [...profiles]..[index] = updated;
    if (activeProfile?.id == profileId) activeProfile = updated;
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

  /// Answers right out of answers given for [worldId] at [level], counted from
  /// the version that introduced levels. 0 when nothing has been answered.
  double accuracyAtLevel(int level, String worldId) {
    final key = levelWorldKey(level, worldId);
    final given = activeProgress.levelAttempts[key] ?? 0;
    return given == 0 ? 0 : (activeProgress.levelCorrect[key] ?? 0) / given;
  }

  Lesson recommendedLesson(LearningWorld world) {
    // [worlds] already returns the active child's level. Keep this scoped to
    // the world it receives so deliberate subsets are not filtered again.
    final candidates = world.lessons;
    if (candidates.isEmpty) {
      throw StateError('${world.id} has no lessons to recommend at this level');
    }
    final done = activeProgress.completedWithLegacy;
    final unfinished = candidates.where(
        (lesson) => !done.contains(lesson.id) && isLessonUnlocked(lesson));
    if (unfinished.isNotEmpty) return unfinished.first;
    // Adaptive review: replay a varied item after mastery.
    final index = (activeProgress.attempts[world.id] ?? 0) % candidates.length;
    return candidates[index];
  }

  /// Core legacy quests remain open as before. Batch lessons use their real
  /// prerequisite graph and unlock only after every prerequisite is complete.
  bool isLessonUnlocked(Lesson lesson) =>
      lesson is! BatchLesson ||
      !lesson.id.contains('-56-') ||
      lesson.prerequisites.every(activeProgress.completedWithLegacy.contains);

  String get adaptiveMessage {
    if (activeProfile == null) return '';
    final weakWorld = curriculum.reduce(
      (a, b) => accuracyFor(a.id) <= accuracyFor(b.id) ? a : b,
    );
    if ((activeProgress.attempts[weakWorld.id] ?? 0) >= 2 &&
        accuracyFor(weakWorld.id) < .7) {
      return 'Practice pick: ${weakWorld.name} — a gentle review is ready.';
    }
    return 'Your next adventure is ready!';
  }

  Future<int> recordResult({
    required LearningWorld world,
    required Lesson lesson,
    required bool correct,
  }) async {
    final profile = activeProfile;
    if (profile == null) return 0;
    if (!isLessonUnlocked(lesson)) return 0;
    final old = activeProgress;
    final completed = {...old.completedLessons, if (correct) lesson.id};
    final attempts = {...old.attempts};
    final correctMap = {...old.correct};
    attempts[world.id] = (attempts[world.id] ?? 0) + 1;
    if (correct) correctMap[world.id] = (correctMap[world.id] ?? 0) + 1;
    // The same answer, counted for the level the child is working at.
    final levelKey = levelWorldKey(profile.level, world.id);
    final levelAttempts = {...old.levelAttempts};
    final levelCorrect = {...old.levelCorrect};
    levelAttempts[levelKey] = (levelAttempts[levelKey] ?? 0) + 1;
    if (correct) levelCorrect[levelKey] = (levelCorrect[levelKey] ?? 0) + 1;
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
      levelAttempts: levelAttempts,
      levelCorrect: levelCorrect,
      teaching: old.teaching,
      rhymes: old.rhymes,
    );
    final updated = profile.copyWith(stars: profile.stars + gained);
    profiles =
        profiles.map((item) => item.id == profile.id ? updated : item).toList();
    activeProfile = updated;
    await _persist();
    notifyListeners();
    return gained;
  }

  Future<void> _persist() =>
      _store.save(LocalSnapshot(profiles: profiles, progress: progress));
}
