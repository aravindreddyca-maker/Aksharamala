import 'package:flutter/material.dart';

enum ExperienceStage { explorer, creator, scholar, champion }

extension ExperienceStageX on ExperienceStage {
  String get label => switch (this) {
        ExperienceStage.explorer => 'Little Explorer',
        ExperienceStage.creator => 'Brave Creator',
        ExperienceStage.scholar => 'Curious Scholar',
        ExperienceStage.champion => 'Learning Champion',
      };

  String get ageLabel => switch (this) {
        ExperienceStage.explorer => 'Ages 3–4',
        ExperienceStage.creator => 'Ages 5–6',
        ExperienceStage.scholar => 'Ages 7–9',
        ExperienceStage.champion => 'Ages 10–12',
      };

  String get focus => switch (this) {
        ExperienceStage.explorer => 'Listen • Tap • Count • Recognise',
        ExperienceStage.creator => 'Trace • Spell • Add • Subtract',
        ExperienceStage.scholar => 'Read • Write • Grammar • Arithmetic',
        ExperienceStage.champion => 'Comprehension • Writing • Advanced maths',
      };
}

ExperienceStage stageForAge(int age) {
  if (age <= 4) return ExperienceStage.explorer;
  if (age <= 6) return ExperienceStage.creator;
  if (age <= 9) return ExperienceStage.scholar;
  return ExperienceStage.champion;
}

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.avatar,
    this.stars = 0,
  });

  final String id;
  final String name;
  final int age;
  final String avatar;
  final int stars;
  ExperienceStage get stage => stageForAge(age);

  ChildProfile copyWith({int? stars}) => ChildProfile(
        id: id,
        name: name,
        age: age,
        avatar: avatar,
        stars: stars ?? this.stars,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'avatar': avatar,
        'stars': stars,
      };

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int,
        avatar: json['avatar'] as String,
        stars: json['stars'] as int? ?? 0,
      );
}

enum LessonKind { alphabet, words, numbers, story, tracing, game }

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.symbol,
    required this.speech,
    required this.locale,
    required this.challenge,
    required this.options,
    required this.answer,
    this.story = const [],
    this.pictures = const {},
    this.cover,
  });

  final String id;
  final String title;
  final String subtitle;
  final LessonKind kind;
  final String symbol;
  final String speech;
  final String locale;
  final String challenge;
  final List<String> options;
  final String answer;
  final List<String> story;

  /// Optional bundled picture per answer option. When present the quiz shows
  /// big picture answers (the word is written by the app, never baked in).
  final Map<String, String> pictures;

  /// Optional bundled scene shown in place of the lesson symbol (story covers).
  final String? cover;
}

class LearningWorld {
  const LearningWorld({
    required this.id,
    required this.name,
    required this.emoji,
    required this.assetPath,
    required this.color,
    required this.darkColor,
    required this.description,
    required this.lessons,
  });

  final String id;
  final String name;
  final String emoji;
  final String assetPath;
  final Color color;
  final Color darkColor;
  final String description;
  final List<Lesson> lessons;

  /// Gradient stops for cards that carry white text.
  /// Guaranteed contrast colors used by the artwork scrim behind card copy.
  Color get cardStart => const Color(0xFF253247);
  Color get cardEnd => const Color(0xFF070D17);
}

class ProgressRecord {
  const ProgressRecord({
    required this.completedLessons,
    required this.attempts,
    required this.correct,
    required this.lastPlayed,
    required this.earnedBadges,
    this.questStars = const {},
  });

  factory ProgressRecord.empty() => const ProgressRecord(
        completedLessons: {},
        attempts: {},
        correct: {},
        lastPlayed: {},
        earnedBadges: {},
      );

  /// Most stars one quest can ever pay: the reward for finishing it.
  static const starsPerQuest = 3;

  /// The badge for a quest in every world is 'all-world-hero'. Earlier saves
  /// stored it as 'four-world-hero' (from when there were four worlds); those
  /// load as the new id so nobody loses a badge they earned.
  static const allWorldHeroBadge = 'all-world-hero';
  static const legacyBadgeIds = <String, String>{
    'four-world-hero': allWorldHeroBadge,
  };

  final Set<String> completedLessons;
  final Map<String, int> attempts;
  final Map<String, int> correct;
  final Map<String, String> lastPlayed;
  final Set<String> earnedBadges;

  /// Stars already paid out by each quest (lesson id -> stars, up to
  /// [starsPerQuest]). Saves made before this field existed have none, so a
  /// finished quest from such a save counts as fully paid (see [starsPaidBy]).
  final Map<String, int> questStars;

  /// Stars [lessonId] has already paid. A finished quest with no record is
  /// treated as fully paid, so old saves cannot be replayed for more stars.
  int starsPaidBy(String lessonId) =>
      questStars[lessonId] ??
      (completedLessons.contains(lessonId) ? starsPerQuest : 0);

  Map<String, Object> toJson() => {
        'completedLessons': completedLessons.toList(),
        'attempts': attempts,
        'correct': correct,
        'lastPlayed': lastPlayed,
        'earnedBadges': earnedBadges.toList(),
        'questStars': questStars,
      };

  factory ProgressRecord.fromJson(Map<String, dynamic> json) => ProgressRecord(
        completedLessons: Set<String>.from(
          json['completedLessons'] as List? ?? const [],
        ),
        attempts: Map<String, int>.from(json['attempts'] as Map? ?? const {}),
        correct: Map<String, int>.from(json['correct'] as Map? ?? const {}),
        lastPlayed: Map<String, String>.from(
          json['lastPlayed'] as Map? ?? const {},
        ),
        earnedBadges: {
          for (final id in (json['earnedBadges'] as List? ?? const []))
            legacyBadgeIds[id as String] ?? id,
        },
        questStars: Map<String, int>.from(
          json['questStars'] as Map? ?? const {},
        ),
      );
}
