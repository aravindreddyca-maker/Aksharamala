/// What of the pack is actually playable in the app. Pure Dart; the app side
/// (which knows its lessons and pictures) fills this in, and the coverage report
/// prints it.
library;

import 'content_models.dart';

class PlayableLesson {
  const PlayableLesson({
    required this.id,
    required this.module,
    required this.title,
    required this.questionRecords,
    required this.writingRecords,
    required this.missingPictures,
    required this.hasStrokeTemplate,
    required this.strokeOrderVerified,
    this.audioRecorded = false,
    this.nativeReviewed = false,
  });

  final String id;
  final ContentModule module;
  final String title;

  /// Pack records behind steps a child must answer.
  final Set<String> questionRecords;

  /// Pack records behind writing practice (placeholders until strokes are
  /// verified).
  final Set<String> writingRecords;

  /// Words of this lesson that have no picture yet.
  final List<String> missingPictures;

  final bool hasStrokeTemplate;
  final bool strokeOrderVerified;
  final bool audioRecorded;
  final bool nativeReviewed;
}

class PlayableSummary {
  const PlayableSummary(this.lessons);

  final List<PlayableLesson> lessons;

  Iterable<PlayableLesson> forModule(ContentModule m) =>
      lessons.where((l) => l.module == m);

  Set<String> questionRecords(ContentModule m) =>
      {for (final l in forModule(m)) ...l.questionRecords};

  Set<String> writingRecords(ContentModule m) =>
      {for (final l in forModule(m)) ...l.writingRecords};
}
