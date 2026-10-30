# Gates: complete remaining Age 5–6 production artwork

OWNS: audit/AGE_5_6_ARTWORK_COMPLETION_GATES.md, audit/AGE_5_6_ASSET_MANIFEST.csv, audit/AGE_5_6_COVERAGE_REPORT.md, audit/AGE_5_6_PRODUCTION_ARTWORK_SPEC.md, assets/images/age56/, tool/generate_age56.dart, lib/src/batch/age56_content.dart, test/age56_visuals_test.dart

Scope: generate and integrate all 53 remaining specified concepts in four independently tested batches while preserving curriculum, progress, rewards, navigation, flags, pronunciation, educator-review and handwriting status.

- [ ] G0: completion ledger is structurally valid
  CHECK: node C:\Users\aravi\.codex\skills\unlazy\scripts\gate-lint.mjs audit\AGE_5_6_ARTWORK_COMPLETION_GATES.md
  EXPECT: LINT OK
  EVIDENCE: pending

- [ ] G1: batch 1 integrates 12 Number, English and simple-object concepts
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\age56_visuals_test.dart test\age56_curriculum_test.dart
  EXPECT: All tests passed!
  EVIDENCE: pending

- [ ] G2: batch 2 integrates 13 shared and concrete Indic concepts
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\age56_visuals_test.dart test\age56_curriculum_test.dart
  EXPECT: All tests passed!
  EVIDENCE: pending

- [ ] G3: batch 3 integrates 14 remaining concrete Indic concepts
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\age56_visuals_test.dart test\age56_curriculum_test.dart
  EXPECT: All tests passed!
  EVIDENCE: pending

- [ ] G4: batch 4 integrates 14 abstract, action, family and named-person concepts without changing review flags
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\age56_visuals_test.dart test\age56_curriculum_test.dart
  EXPECT: All tests passed!
  EVIDENCE: pending

- [ ] G5: every one of 162 lessons is visually complete with real resolvable assets
  CHECK: powershell -Command "$rows=Import-Csv audit\AGE_5_6_ASSET_MANIFEST.csv; if($rows.Count -eq 162 -and ($rows | Where-Object visually_complete -ne 'true').Count -eq 0){'ALL_VISUALS_COMPLETE'}else{exit 1}"
  EXPECT: ALL_VISUALS_COMPLETE
  EVIDENCE: pending

- [ ] G6: strict curriculum audit passes unchanged
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\audit --dart-define=AUDIT_STRICT=true
  EXPECT: All tests passed!
  EVIDENCE: pending

- [ ] G7: complete Flutter regression suite passes
  CHECK: E:\flutter-sdk\bin\flutter.bat test
  EXPECT: All tests passed!
  EVIDENCE: pending

- [ ] G8: Flutter analysis reports no issues
  CHECK: E:\flutter-sdk\bin\flutter.bat analyze
  EXPECT: No issues found!
  EVIDENCE: pending

- [ ] G9: pronunciation, educator review and handwriting mastery remain unverified
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\age56_curriculum_test.dart test\age56_visuals_test.dart
  EXPECT: All tests passed!
  EVIDENCE: pending
