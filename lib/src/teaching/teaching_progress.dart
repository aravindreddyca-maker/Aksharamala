/// What a child has done in a taught lesson. Kept per lesson id, separate from
/// formal parent examinations, and additive to the save file.
library;

enum MasteryStatus { notStarted, learning, mastered, needsSupport }

/// The five teaching phases (also what [TeachingProgress.phasesDone] holds).
enum TeachingPhaseName { introduce, demonstrate, guided, practice, check }

class TeachingProgress {
  const TeachingProgress({
    this.viewed = false,
    this.phasesDone = const {},
    this.guidedDone = false,
    this.practiceDone = false,
    this.checkBestScore,
    this.checkLastScore,
    this.mastery = MasteryStatus.notStarted,
    this.remediationCycles = 0,
    this.updatedAt,
    this.phase,
  });

  static const empty = TeachingProgress();

  final bool viewed;
  final Set<String> phasesDone;
  final bool guidedDone;
  final bool practiceDone;
  final int? checkBestScore;
  final int? checkLastScore;
  final MasteryStatus mastery;
  final int remediationCycles;
  final String? updatedAt;

  /// Where to resume if the app was closed mid-lesson: a flow phase name
  /// (`introduce`, `demonstrate`, `guided`, `practice`, `check`,
  /// `remediation`), or null when the lesson is not part-way.
  final String? phase;

  bool get isMastered => mastery == MasteryStatus.mastered;

  TeachingProgress copyWith({
    bool? viewed,
    Set<String>? phasesDone,
    bool? guidedDone,
    bool? practiceDone,
    int? checkBestScore,
    int? checkLastScore,
    MasteryStatus? mastery,
    int? remediationCycles,
    String? updatedAt,
    String? phase,
    bool clearPhase = false,
  }) =>
      TeachingProgress(
        viewed: viewed ?? this.viewed,
        phasesDone: phasesDone ?? this.phasesDone,
        guidedDone: guidedDone ?? this.guidedDone,
        practiceDone: practiceDone ?? this.practiceDone,
        checkBestScore: checkBestScore ?? this.checkBestScore,
        checkLastScore: checkLastScore ?? this.checkLastScore,
        mastery: mastery ?? this.mastery,
        remediationCycles: remediationCycles ?? this.remediationCycles,
        updatedAt: updatedAt ?? this.updatedAt,
        phase: clearPhase ? null : (phase ?? this.phase),
      );

  Map<String, Object> toJson() => {
        'viewed': viewed,
        'phasesDone': phasesDone.toList()..sort(),
        'guidedDone': guidedDone,
        'practiceDone': practiceDone,
        if (checkBestScore != null) 'checkBestScore': checkBestScore!,
        if (checkLastScore != null) 'checkLastScore': checkLastScore!,
        'mastery': mastery.name,
        'remediationCycles': remediationCycles,
        if (updatedAt != null) 'updatedAt': updatedAt!,
        if (phase != null) 'phase': phase!,
      };

  /// Reads a saved record. A field of the wrong type is ignored (never
  /// thrown over) so the rest of the save still loads.
  factory TeachingProgress.fromJson(Map<String, dynamic> json) {
    bool flag(Object? v) => v is bool ? v : false;
    int? whole(Object? v) => v is num ? v.toInt() : null;
    String? text(Object? v) => v is String ? v : null;
    final done = json['phasesDone'];
    final mastery = json['mastery'];
    return TeachingProgress(
      viewed: flag(json['viewed']),
      phasesDone: {
        if (done is List)
          for (final p in done)
            if (p is String) p,
      },
      guidedDone: flag(json['guidedDone']),
      practiceDone: flag(json['practiceDone']),
      checkBestScore: whole(json['checkBestScore']),
      checkLastScore: whole(json['checkLastScore']),
      mastery: mastery is String
          ? (MasteryStatus.values.asNameMap()[mastery] ??
              MasteryStatus.notStarted)
          : MasteryStatus.notStarted,
      remediationCycles: whole(json['remediationCycles']) ?? 0,
      updatedAt: text(json['updatedAt']),
      phase: text(json['phase']),
    );
  }
}
