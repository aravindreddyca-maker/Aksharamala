/// A problem found while reading or checking curriculum content.
///
/// Pure Dart (no Flutter imports) so the importer can run in tools and tests
/// and can never influence a screen.
library;

enum IssueSeverity {
  /// The content is structurally wrong and must be fixed before use.
  error,

  /// Valid, but not ready for a child (missing media, unverified, outline).
  warning,

  /// Worth knowing, not blocking.
  info,
}

class ContentIssue {
  const ContentIssue({
    required this.code,
    required this.severity,
    required this.module,
    required this.message,
    this.lessonId,
  });

  /// Stable rule id, e.g. `E006`. Errors start with E, warnings with W,
  /// information with I. See [contentRuleDescriptions].
  final String code;
  final IssueSeverity severity;
  final String module;
  final String? lessonId;
  final String message;

  @override
  String toString() =>
      '[$code] $module${lessonId == null ? '' : '/$lessonId'}: $message';
}

/// One-line meaning of every rule, used in reports.
const contentRuleDescriptions = <String, String>{
  'E001': 'Duplicate lesson id',
  'E002': 'Required field missing or of the wrong type',
  'E003': 'Unknown lesson type',
  'E004': 'Unknown age band (stage)',
  'E005': 'Module, language or locale mismatch',
  'E006': 'Correct answer is not one of the options',
  'E007': 'Duplicate answer options',
  'E008': 'Fewer than two answer options',
  'E009': 'Arithmetic answer key is wrong',
  'E010': 'Mastery or stroke validation switched on without verified strokes',
  'E011': 'Story order is not a permutation of the events',
  'E012': 'Prerequisite cycle (or a lesson that requires itself)',
  'E013': 'Estimated minutes must be a positive number',
  'E014': 'Chapter is not declared in the module',
  'E015': 'Text is in the wrong script (stray characters)',
  'E016': 'Assessment is empty for a lesson that needs one',
  'E017': 'Answer key does not match the lesson target',
  'W101': 'Prerequisite is not a lesson id (cannot be resolved)',
  'W102': 'Picture or story image is missing',
  'W103': 'No recorded audio, or audio not verified by a native speaker',
  'W104': 'Child-facing instruction is not in the module language',
  'W105': 'Outline only: an authoring backlog item, not a lesson',
  'W106': 'Blueprint: needed content (e.g. the combined letter) is missing',
  'W107': 'Handwriting target has no verified stroke geometry',
  'W108': 'Nothing to arrange: word ordering has no pieces',
  'W120': 'Correct answer is listed first and options are not shuffled',
  'I201': 'Native-educator review is required before publishing',
};
