# Gates: deterministic strict-audit stabilization

OWNS: audit/STABILIZATION_GATES.md, audit/COMPLETE_QA_AUDIT_2026-10-29.md, audit/COVERAGE_MATRIX_2026-10-29.csv, lib/src/curriculum.dart, lib/src/screens/lesson_screen.dart, lib/src/screens/achievements_screen.dart, test/audit/curriculum_audit_test.dart

Scope: resolve every deterministic strict-audit defect while leaving age-banded curriculum expansion and additional letter coverage for the next curriculum phase.

- [x] G0: this stabilization ledger is structurally valid
  CHECK: node C:\Users\aravi\.codex\skills\unlazy\scripts\gate-lint.mjs audit\STABILIZATION_GATES.md
  EXPECT: LINT OK
  EVIDENCE: automatic-evidence=v1; definition-sha256=b42cadb2e882c109018614c4a5e43a54dd44d81378ce4ef0250c7533befbb83b; exit=0; EXPECT=matched; output-sha256=79d8ddf7dcff86ae404fc634ddcc8db9f299c23374cdf05b0a5220f54addd21c; output-bytes=739; shell=C:\Windows\system32\cmd.exe; cwd=E:\Aksharamala; path=92512d1d8983/33 entries

- [x] G1: deterministic curriculum audit assertions run normally rather than being skipped and all pass
  CHECK: E:\flutter-sdk\bin\flutter.bat test test\audit\curriculum_audit_test.dart
  EXPECT: All tests passed!
  EVIDENCE: automatic-evidence=v1; definition-sha256=183630ef6fd2de45b35855d0df1dc3a9eafca804838f73135f7686bc6f0443b9; exit=0; EXPECT=matched; output-sha256=abcc31b3eec90b747414a3e6d825ac846dbadbf0639827ba4e6a48685a2ae6b6; output-bytes=5337; shell=C:\Windows\system32\cmd.exe; cwd=E:\Aksharamala; path=92512d1d8983/33 entries

- [x] G2: the complete Flutter regression suite passes after the content and presentation fixes
  CHECK: E:\flutter-sdk\bin\flutter.bat test
  EXPECT: All tests passed!
  EVIDENCE: automatic-evidence=v1; definition-sha256=cf771852f25e7a320c56f416d723095836f0a586d7a9dbb1e6ef1c411f85386a; exit=0; EXPECT=matched; output-sha256=60d14ebf5d1486228bc8bab83ef8bf5d43a99b1b670347fcb5ac7cee6bdeb519; output-bytes=49475; shell=C:\Windows\system32\cmd.exe; cwd=E:\Aksharamala; path=92512d1d8983/33 entries

- [x] G3: Flutter static analysis reports no issues
  CHECK: E:\flutter-sdk\bin\flutter.bat analyze
  EXPECT: No issues found!
  EVIDENCE: automatic-evidence=v1; definition-sha256=faf461d70d96ba586d1929d62c7459be9bf61c876450472506e55b631022f848; exit=0; EXPECT=matched; output-sha256=b5ee39aff32c13e13119f43df6c37e7ada07d21d4eea4fc0b856917122e6405f; output-bytes=520; shell=C:\Windows\system32\cmd.exe; cwd=E:\Aksharamala; path=92512d1d8983/33 entries

- [x] G4: English and Hindi word building show a central picture clue and English has only one valid offered completion
  EVIDENCE: English and Hindi word lessons now carry cat/lotus cover assets; English options are A/E/I. The formerly skipped picture-clue and unique-fill assertions pass in the targeted and full suites.

- [x] G5: story text, spoken facts, displayed answers, lesson symbols, multilingual number speech and tracing instructions are internally consistent
  EVIDENCE: Curriculum audit assertions for script/emoji, TTS script, prompt leakage, story answer presence, story/speech agreement and tracing-dot promises now run normally and pass.

- [x] G6: previously unused reward artwork is used by the reward cabinet and the number-name table is used outside its declaration
  EVIDENCE: AchievementsScreen uses crown/gem/gift/medal assets with icon fallback; LessonScreen derives number-name speech from numberNames. Both dead/unused-data assertions pass.

- [x] G7: the three intentionally deferred curriculum-expansion assertions remain explicitly documented as known defects rather than silently weakened
  EVIDENCE: Only AUD-002 (two assertions) and AUD-001 (one assertion) retain _known skips. Strict mode passes 39 and fails exactly those three assertions.

- [x] G8: the audit report and coverage matrix reflect the post-stabilization test counts and no longer list corrected defects as open
  EVIDENCE: Both artifacts now record 362 pass/3 skip and 39 pass/3 strict fail, describe the corrected legacy items, and retain the age/coverage blockers.
