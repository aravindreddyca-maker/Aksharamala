/// Artwork the lessons need. A picture whose file does not exist yet is listed
/// here so the app shows a labelled placeholder (see [ArtPicture]) and the art
/// pipeline knows what to produce.
library;

enum ArtStatus { needed, requested, delivered }

class ArtAssetSpec {
  const ArtAssetSpec({
    required this.id,
    required this.concept,
    required this.description,
    required this.world,
    required this.level,
    required this.lessonIds,
    required this.width,
    required this.height,
    required this.transparent,
    required this.suggestedFilename,
    this.status = ArtStatus.needed,
    this.priority = 2,
  });

  /// The asset path the lesson plan refers to (`assets/...`).
  final String id;

  /// Short label shown on the placeholder, e.g. "Elephant".
  final String concept;
  final String description;
  final String world;
  final int level;
  final List<String> lessonIds;
  final int width;
  final int height;
  final bool transparent;
  final String suggestedFilename;
  final ArtStatus status;

  /// 1 = most urgent.
  final int priority;
}

/// Pictures referenced by teaching plans that are not yet files. Every path in
/// the five pilot plans exists today, so this starts empty; add an entry when
/// a plan names a picture that has not been drawn.
const Map<String, ArtAssetSpec> artRegistry = {};
