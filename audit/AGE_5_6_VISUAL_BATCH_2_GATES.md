# Gates: Age 5–6 visual batch 2

OWNS: audit/AGE_5_6_VISUAL_BATCH_2_GATES.md, audit/AGE_5_6_ASSET_MANIFEST.csv, audit/AGE_5_6_COVERAGE_REPORT.md, audit/AGE_5_6_PRODUCTION_ARTWORK_SPEC.md, assets/images/age56/pin.webp, assets/images/age56/pig.webp, assets/images/age56/sit.webp, tool/generate_age56.dart, lib/src/batch/age56_content.dart, test/age56_visuals_test.dart

Scope: complete the English short-i phonics illustration batch for pin, sit and pig using semantically exact production WebP art and the existing lesson-media generator.

- [x] G0: gate ledger is structurally valid
  CHECK: node C:\Users\aravi\.codex\skills\unlazy\scripts\gate-lint.mjs audit\AGE_5_6_VISUAL_BATCH_2_GATES.md
  EXPECT: LINT OK
  EVIDENCE: LINT OK.

- [x] G1: pin, sit and pig lessons resolve exact production WebP illustrations
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\age56_visuals_test.dart
  EXPECT: All tests passed!
  EVIDENCE: Three generated assets were visually inspected, converted to compact WebP and passed path/decode tests.

- [x] G2: manifest completeness improves through verified reuse plus three new illustrations without broken paths
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\age56_visuals_test.dart test\age56_curriculum_test.dart
  EXPECT: All tests passed!
  EVIDENCE: Completion improved from 86 to 102 lessons; targeted suite passed 14/14.

- [x] G3: unchanged strict curriculum audit passes
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\audit --dart-define=AUDIT_STRICT=true
  EXPECT: All tests passed!
  EVIDENCE: Strict audit passed 42/42.

- [x] G4: Flutter analysis reports no issues
  CHECK: E:\flutter-sdk\bin\flutter.bat analyze
  EXPECT: No issues found!
  EVIDENCE: No issues found.

- [x] G5: complete Flutter regression suite passes
  CHECK: E:\flutter-sdk\bin\flutter.bat test
  EXPECT: All tests passed!
  EVIDENCE: Full suite passed 386/386.

- [x] G6: production specification accounts for every baseline concept and keeps unverified art pending
  CHECK: powershell -Command "if ((Select-String -Path audit\AGE_5_6_PRODUCTION_ARTWORK_SPEC.md -Pattern '\| Not generated' -AllMatches).Matches.Count -eq 57) { 'ARTWORK_SPEC_OK' } else { exit 1 }"
  EXPECT: ARTWORK_SPEC_OK
  EVIDENCE: ARTWORK_SPEC_OK; 70 baseline concepts accounted for, 57 pending rows remain explicitly unverified.
