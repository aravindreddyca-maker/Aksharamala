# Gates: Aksharamala complete app and curriculum QA audit

OWNS: audit/QA_GATES.md, audit/COMPLETE_QA_AUDIT_2026-10-29.md, audit/COVERAGE_MATRIX_2026-10-29.csv

Scope: independently audit the implemented Flutter app, five curriculum modules, automated validation, and handwriting engine, and publish an evidence-backed report without changing product behavior.

- [x] G0: this audit ledger is structurally valid
  CHECK: node C:\Users\aravi\.codex\skills\unlazy\scripts\gate-lint.mjs QA_GATES.md
  EXPECT: LINT OK
  EVIDENCE: automatic-evidence=v1; definition-sha256=7d1fe0f18b83afc9b557dd70eebde66c511fdf7d88d3764667709f470b493d04; exit=0; EXPECT=matched; output-sha256=918114db404f55c08060a252bc00800578e1e3f93035b280071daf16d4e16e97; output-bytes=1361; shell=C:\Windows\system32\cmd.exe; cwd=E:\Aksharamala\audit; path=92512d1d8983/33 entries

- [x] G1: the report inventories architecture, screens, routes, dependencies, assets, activities, profiles, progress, rewards, language/audio behavior, and implementation boundaries with source evidence
  EVIDENCE: Manual review of pubspec.yaml, lib/src/app.dart, app_controller.dart, models.dart, curriculum.dart, all screen/service files, Android manifest/MainActivity, assets inventory and README; recorded in report sections 1 and 5.

- [x] G2: the coverage matrix distinguishes expected, implemented, playable, tested, missing, and severity for Telugu, Tamil, Hindi, English, and Number Galaxy across every declared age band
  EVIDENCE: audit/COVERAGE_MATRIX_2026-10-29.csv contains 20 rows: five modules multiplied by four age bands, with all required columns populated.

- [x] G3: every curriculum JSON record is independently parsed and checked for structural validity, declared answers, option ambiguity or duplication, progression metadata, and asset references
  EVIDENCE: Node parsed all five JSON files and all 4,532 rows; independent aggregation found zero duplicate choice options and zero declared answers outside their options, and reconciled counts to content/reports/COVERAGE_REPORT.md. Source validator and asset manifest logic were reviewed.

- [x] G4: Telugu, Tamil, Hindi, and English receive script-specific linguistic, sequencing, rendering, vocabulary, phonics, reading, grammar, story, and handwriting findings supported by exact data examples
  EVIDENCE: Report section 3 records per-language inventory and concrete examples; native-language judgements are explicitly left for educator sign-off.

- [x] G5: Number Galaxy questions are independently recalculated where machine-verifiable and reviewed for answer quality, edge cases, predictable patterns, and meaningful advanced content
  EVIDENCE: Independent Node calculation checked 750 arithmetic rows: zero wrong keys, duplicate options, division by zero or negative subtraction; all 750 correct answers were also the smallest option. Twenty advanced/intermediate concepts were confirmed outline_only.

- [x] G6: the handwriting audit distinguishes displayed glyphs, templates, demonstrations, tracing, independent writing, validation, stroke order/direction, and unsupported characters for every module
  EVIDENCE: Report section 4 reconciles 3,184 placeholder rows with handwriting_registry.dart, digit_templates.dart, writing_pad.dart and stroke validator/policy tests; no animation or teacher-verified stroke order exists.

- [x] G7: Flutter static analysis and the complete automated test suite run against the audited revision, with failures and environment limitations reported without concealment
  EVIDENCE: Flutter 3.47.8/Dart 3.13.7: analyze passed with no issues; full suite passed 352 with 13 named known-defect skips; strict audit passed 29 and failed 13 as expected; debug APK built successfully at build/app/outputs/flutter-apk/app-debug.apk.

- [x] G8: the final report reconciles every requirement present in the supplied brief, labels unverified runtime/manual claims honestly, and identifies that the supplied brief is truncated after handwriting item 9
  EVIDENCE: Report sections 2–7 cover the supplied modules, progression, assessment, maths, handwriting and limitations; header and release decision identify the truncated brief.

