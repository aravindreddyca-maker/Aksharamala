# Gates: Age 5–6 five-module curriculum import

OWNS: audit/AGE_5_6_IMPORT_GATES.md, audit/AGE_5_6_COVERAGE_REPORT.md, audit/AGE_5_6_ASSET_MANIFEST.csv, content/age56/english_age_5_6.json, content/age56/telugu_age_5_6.json, content/age56/hindi_age_5_6.json, content/age56/tamil_age_5_6.json, content/age56/numbers_age_5_6.json, tool/generate_age56.dart, lib/src/models.dart, lib/src/app_controller.dart, lib/src/batch/batch_content.dart, lib/src/batch/batch_lesson.dart, lib/src/batch/age56_content.dart, lib/src/screens/batch_lesson_screen.dart, lib/src/screens/world_map_screen.dart, lib/src/widgets/learning_visuals.dart, assets/images/age56/dog.webp, assets/images/age56/fish.webp, assets/images/age56/sun.webp, assets/images/age56/tree.webp, pubspec.yaml, test/age56_curriculum_test.dart, test/age56_visuals_test.dart, test/audit/curriculum_audit_test.dart, test/batch/batch_content_test.dart, test/batch/progress_migration_test.dart, test/controller_test.dart

Scope: import the supplied Age 5–6 JSON records for all five modules into the existing BatchLesson engine, enforce prerequisites in navigation, preserve all existing IDs/saves/rewards, and reject invalid content.

- [x] G0: gate ledger is structurally valid
  CHECK: node C:\Users\aravi\.codex\skills\unlazy\scripts\gate-lint.mjs audit\AGE_5_6_IMPORT_GATES.md
  EXPECT: LINT OK
  EVIDENCE: LINT OK.

- [x] G1: supplied JSON records validate with no placeholders, duplicate questions, invalid answers or missing prerequisites
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\age56_curriculum_test.dart
  EXPECT: All tests passed!
  EVIDENCE: Targeted suite passed; five files and 162 records validated.

- [x] G2: all five Age 5–6 modules are playable through BatchLesson with teaching, examples, questions and metadata
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\age56_curriculum_test.dart
  EXPECT: All tests passed!
  EVIDENCE: Targeted suite passed; generated/source parity verified for every record.

- [x] G3: prerequisite progression locks and unlocks lessons while legacy progress remains compatible
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\age56_curriculum_test.dart test\batch\progress_migration_test.dart test\controller_test.dart
  EXPECT: All tests passed!
  EVIDENCE: Combined curriculum, migration and controller suite passed (55 tests).

- [x] G4: strict curriculum audit passes without skipped or weakened requirements
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\audit --dart-define=AUDIT_STRICT=true
  EXPECT: All tests passed!
  EVIDENCE: Strict audit passed 42/42 with AUDIT_STRICT=true.

- [x] G5: complete Flutter regression suite passes
  CHECK: E:\flutter-sdk\bin\flutter.bat test
  EXPECT: All tests passed!
  EVIDENCE: Full Flutter suite passed 385/385.

- [x] G6: Flutter analysis reports no issues
  CHECK: E:\flutter-sdk\bin\flutter.bat analyze
  EXPECT: No issues found!
  EVIDENCE: No issues found.

- [x] G7: coverage report identifies imported, rejected and still-missing curriculum topics per module
  CHECK: powershell -Command "if (Test-Path audit\AGE_5_6_COVERAGE_REPORT.md) { 'COVERAGE_REPORT_OK' } else { exit 1 }"
  EXPECT: COVERAGE_REPORT_OK
  EVIDENCE: Report lists playable, incomplete, missing-topic and visual-art status for all five modules.

- [x] G8: reusable visual activities cover picture matching, phonics, combinations, word building, counting, drag arithmetic and guided tracing with reduced-motion support
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\age56_visuals_test.dart
  EXPECT: All tests passed!
  EVIDENCE: Visual widget and reduced-motion tests passed.

- [x] G9: every media reference resolves and lessons requiring absent production assets remain explicitly incomplete
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\age56_visuals_test.dart test\age56_curriculum_test.dart
  EXPECT: All tests passed!
  EVIDENCE: Manifest has 162 lesson rows; path and completeness tests passed.
