# Gates: age-banded complete foundation curriculum expansion

OWNS: audit/CURRICULUM_EXPANSION_GATES.md, audit/COMPLETE_QA_AUDIT_2026-10-29.md, audit/COVERAGE_MATRIX_2026-10-29.csv, audit/CURRICULUM_COVERAGE_REPORT_2026-10-29.md, content/reports/COVERAGE_REPORT.md, content/reports/COVERAGE_REPORT.csv, lib/src/models.dart, lib/src/curriculum.dart, lib/src/app_controller.dart, lib/src/batch/batch_lesson.dart, lib/src/screens/world_map_screen.dart, test/audit/curriculum_audit_test.dart, test/curriculum_expansion_test.dart, test/controller_test.dart, test/star_rules_test.dart, test/check_button_layout_test.dart, test/quest_map_test.dart, test/replay_and_language_test.dart, test/batch/batch_content_test.dart, test/batch/progress_migration_test.dart

Scope: make all five worlds genuinely age-specific, add explicit lesson metadata and complete four alphabet-recognition sequences while preserving existing IDs, saves, rewards and the current lesson engine.

- [x] G0: this expansion ledger is structurally valid
  CHECK: node C:\Users\aravi\.codex\skills\unlazy\scripts\gate-lint.mjs audit\CURRICULUM_EXPANSION_GATES.md
  EXPECT: LINT OK
  EVIDENCE: LINT OK (manual-gate warnings only)

- [x] G1: every lesson has explicit age-band, difficulty, learning-objective and prerequisite metadata; IDs and prerequisite graphs are valid
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\curriculum_expansion_test.dart
  EXPECT: All tests passed!
  EVIDENCE: 7/7 expansion tests passed

- [x] G2: the strict curriculum audit passes without disabling or deleting its three remaining assertions
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\audit --dart-define=AUDIT_STRICT=true
  EXPECT: All tests passed!
  EVIDENCE: 42/42 strict audit tests passed; obsolete skip helper removed

- [x] G3: the complete Flutter regression suite passes
  CHECK: E:\flutter-sdk\bin\flutter.bat test
  EXPECT: All tests passed!
  EVIDENCE: 372/372 tests passed

- [x] G4: Flutter static analysis reports no issues
  CHECK: E:\flutter-sdk\bin\flutter.bat analyze
  EXPECT: No issues found!
  EVIDENCE: No issues found

- [x] G5: Telugu, Tamil, Hindi and English expose their complete recognition inventories as real playable lessons with unique valid answers
  EVIDENCE: expansion inventory test passed; strict audit counted Telugu 51, Tamil 30, Hindi 46 and English 26

- [x] G6: every world offers substantively different playable content for ages 3–4, 5–6, 7–9 and 10–12
  EVIDENCE: distinct-stage-content and age-aware-recommendation tests passed for all five worlds

- [x] G7: existing lesson IDs, profile/progress JSON and reward semantics remain backward compatible
  EVIDENCE: all 20 legacy IDs retained; 23 targeted expansion/migration tests and full suite passed

- [x] G8: handwriting practice remains non-mastery unless verified stroke geometry and order exist
  EVIDENCE: handwriting non-mastery test passed; BatchStep.write remains non-required

- [x] G9: coverage artifacts report playable, incomplete and missing content separately for every module and age band
  EVIDENCE: audit/CURRICULUM_COVERAGE_REPORT_2026-10-29.md and 20-row COVERAGE_MATRIX_2026-10-29.csv
