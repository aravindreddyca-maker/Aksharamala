# Examination Centre: independent UI verification report

Verifier: ui-verifier (did not write the code). Date: 2026-10-31. Scope: `lib/src/screens/exam/`, `lib/src/exam/`, edits to `lib/src/app.dart` and `lib/src/screens/parent_dashboard.dart`. No `lib/` file was edited.

## Overall status: REVISE (no BLOCKED screens)

The exam logic and the child's flow held up under attack. Three real defects were found (D1 to D3, all in how the bank/refusal/result text is produced or shown) plus minor items. Nothing is visually verified beyond English layout renders (see section 5).

## 1. Commands and counts (run independently, verbatim results)

| Command | Result |
|---|---|
| `flutter analyze` | `1 issue found.` warning: Unused import `package:aksharamala/src/models.dart` in `tool\teaching_audit_test.dart:9:8` (other agent's file, not exam code). Exam code: 0 issues. |
| `flutter test test/exam test/exam_ui` | `All tests passed!` 133 passed (+133), 0 failed. |
| `flutter test` (whole suite, before my tests were added) | `+663: All tests passed!` |
| `flutter test test/exam_verify` (my tests) | `+22 ~4: All tests passed!` (22 pass, 4 skipped: 3 are known-defect tests D1/D2/D3 that fail when un-skipped, 1 is the screenshot capture that only runs with env `EXAM_VERIFY_SHOTS=1`). |
| `flutter analyze test/exam_verify` | 3 infos (deprecated `pipelineOwner` / `hasFlag` in test code), 0 errors. |

No compile failure from the other agent's in-progress teaching files occurred.

## 2. Per-screen verdicts

| Screen | Verdict | Notes |
|---|---|---|
| Entry (Parents button, PIN gate, child switching) | PASS | Source: only `app.dart` and `parent_dashboard.dart` reference the centre; PIN asked for the active child and again when switching to a PIN child; a locked child's data is never built (`child = null`). Cancel leaves the previous child selected. |
| Conduct Exam | REVISE | D1 (misleading offer after a zero-question subject). Too-few refusal, Level 5 message, retest refusals, resume/discard all correct. |
| Child exam (question, review, confirm, done) | PASS | No right/wrong, no hints, changeable answers, save after every answer, resume, timer expiry, back-gesture confirm all held (V1, V3, V4, V7, V8, V10). |
| Results / ResultScreen | REVISE | D2 ("Ready for Level 6?" at Level 5); D4 internal ids shown. |
| History | PASS | Newest first, discarded and unfinished attempts listed. |
| Certificates / CertificateScreen | REVISE (minor) | D5 certificate number wraps mid-id and lines are inconsistently aligned. Once per level + reissue counter correct. |
| Bank & Settings | PASS | Coverage per level equals the real bank (S1). |
| Question bank content (as exam material) | REVISE | D3: 14 real questions show the answer in the prompt; 10 more are pure sight-matching. |

## 3. Findings

D1. Severity MEDIUM. Owner: ui-creator (conduct_tab.dart / selection message).
Evidence: test V6. Final Level exam with a subject that has no questions (Telugu at Level 1 with an English-only bank). Start is enabled (availability line says "This level has N questions for the chosen subjects"), refusal reads `World "telugu" has no questions at Level 1.` (raw internal id), and a button "Use 18 questions instead" is offered. Tapping it does not start an exam: the same refusal returns (the offer ignores that a chosen subject is empty). A parent can loop forever.
Reproduce: `test/exam_verify/child_exam_adversarial_test.dart` V6 (skip removed): tap `type_finalLevel`, `final_world_telugu`, `start_exam`, `use_available`.
Fix direction: show the subject's display name, offer to remove the empty subject instead of a count, or disable Start and say so up front.

D2. Severity LOW-MEDIUM. Owner: ui-creator (results_tab.dart line ~182).
Evidence: V9. A Level 5 result shows the card title "Ready for Level 6?" (there is no Level 6; evaluator text correctly says "This is the highest level"). Reproduce: finish a Level 5 exam, open its result.

D3. Severity MEDIUM (content derivation, exam validity). Owner: question-bank derivation (`question_bank.dart`) and content owner.
Evidence: S2 over the real bank (ids only): the visible prompt contains the correct answer in 14 questions: `english-56-013` to `-020` and `-027` to `-030` (all `#q1`; e.g. a "which spelling is correct for the word ..." prompt that states the word, or "Which is lowercase b?" with answer b), `te-letter-004#q0`, `telugu-recognise-004#q1`. In addition 10 `telugu-recognise-001..011#q1` show a large glyph identical to the correct option (sight matching, not recall). I cannot judge Telugu meaning; only that the string appears in both prompt and answer. The creator's design says the exam must not reveal answers. Listening questions put the answer in the spoken line by design (150 such, listed as expected, not counted as a defect).
Reproduce: `real_bank_scan_test.dart` S2 (skip removed) prints the ids.

D4. Severity LOW. Owner: ui-creator. Parent result screen shows machine ids and labels: "Revise: Animal sounds 0 (E0), ..." (lesson id in brackets) and "By topic: alphabet" (raw `lesson.kind.name`). Evidence: result_360x800.png.

D5. Severity LOW. Owner: ui-creator. Certificate card: "Certificate number: AKS-L1-20261031-2F99" wraps mid-id ("AKS-" / "L1-...") at 360 px and the Date/Number lines are aligned differently. Evidence: certificate_360x800.png.

D6. Severity LOW (usability, not a defect against the spec). At 800x360 landscape with 1.6 text only about one answer option is visible above the Back/Next bar; the child must scroll. No overflow. Evidence: child_question_800x360_t16.png.

D7. Severity INFO. `ExamController.answer(attemptId, questionId, answer)` has no child check: it trusts the attempt id. Unreachable from the child app (no route), and an attempt stores its own `childId`, so another child's exam stays invisible (V5), but there is no defence in depth if a route is ever added.

D8. Severity INFO. Retest `maxAttempts` counts only submitted attempts, so a parent who Discards an in-progress exam does not consume an attempt. Parent-only action; flagged for the decision owner.

## 4. Design checklist (evidence)

- No child route to creation/settings/detailed results: source scan (creator test) + my read; exam code never references `AppController` mutators or `progress.json` (grep of `lib/src/exam` and `lib/src/screens/exam`: only reads `activeProfile`, `profiles`, `allWorlds`). PASS.
- PIN incl. child switching: PASS (read; creator tests). My V12/V5 did not need PIN.
- Refusals (too few, Level 5, retest): PASS by read and creator tests; D1 is the exception.
- No right/wrong, no hints, no leakage in semantics/keys/Text: V1 PASS (semantics labels contain no "correct/right/wrong/hint/explanation"; all four option nodes have identical flags/actions; `ValueKey`s carry no answer text). Correct option is shown first in 130 of 400 shuffled real option lists (32.5%, chance for 3 options is 33%): V2/S4 PASS.
- Changeable answers, review page, confirm before submit, save after every answer: V4, V10 plus creator tests PASS.
- Resume after kill: V4 PASS (controller rebuilt from the stored JSON; question and option order identical; opens at the first unanswered question).
- Submit twice / concurrently: V3, V3b PASS (one result, one certificate, no extra store write).
- Timer expiry (on review page), late tap refused: V7 PASS. Back gesture via `handlePopRoute`: V8 PASS (Keep going stays; Leave keeps the attempt).
- Exam never changes stars/lesson completion/progress: no code path in exam code; creator test; PASS.
- Result breakdown, recommendations naming lessons, parent marking, tamper warning, history order, certificate once per level, reissue: creator tests (results_test.dart) all pass and I viewed the result and certificate renders. PASS apart from D2, D4, D5.
- Coverage numbers vs real bank: S1 PASS. Real bank per level: L1 207, L2 168, L3 6, L4 6, L5 0; an independent count of lesson steps/quizzes gives the same upper bound, 0 rejected questions.
- Zero-question subject in a final exam: V6 FAIL (D1).
- Large option text / 360x800 / 800x360 / 360x640, text 1.0 and 1.6: V11 (6 combos) and V12 (long child name, long topic/lesson/answers across all five tabs and certificate) PASS, no overflow, options >= 48 dp high, buttons on screen.
- Different child cannot answer another child's exam: V5 PASS at data level (D7 note).

## 5. Visual verification

Partial and English-only. No adb/emulator was available (`adb.exe` not found), so the app was not run on a device. I rendered the screens with the real Roboto and Material Icons fonts from the Flutter SDK using `test/exam_verify/screens_golden_test.dart` (`EXAM_VERIFY_SHOTS=1 flutter test --update-goldens`), and looked at: child question 360x800 and 800x360 (1.6 text), review, done, Conduct tab, Result, Certificate (PNG files in `test/exam_verify/goldens/`). Seen: clear hierarchy, readable touch targets, selected option clearly marked, no clipping at 360 wide (the Examination Centre tab bar scrolls, "Certificates" is partly cut off, as expected for a scrollable tab bar). Test-render artefacts, not app defects: a red debug ribbon over the timer, and white blocks where FilledButton labels should be (the test font loader did not map the heavy weight, so the button text rendered with the fallback). Because of that I could NOT visually confirm the filled-button labels or the timer legibility. Results, History and Settings tabs were captured but only the Result, Certificate, Conduct, Review, Done and Question images were inspected.

## 6. Left unverified

Real Telugu/Hindi/Tamil script shaping and fonts (no font bundled in tests); TTS Listen on a device; TalkBack/real screen reader (only the semantics tree was inspected); the physical back gesture (simulated by `handlePopRoute`); rotation mid-exam on a device; killing the real app process and rebooting from the real-disk `ExamStore` (simulated by rebuilding the controller from stored JSON); the full `AksharamalaApp` boot with `ExamController` on disk; filled-button label and timer appearance (render artefact above); contrast of tinted cards on a real display; Results/History/Settings tab screenshots; Telugu recognise questions' real meaning (educator review).

## 7. Files added by the verifier

- `test/exam_verify/child_exam_adversarial_test.dart` (V1 to V13)
- `test/exam_verify/real_bank_scan_test.dart` (S1 to S4)
- `test/exam_verify/screens_golden_test.dart` (skipped unless `EXAM_VERIFY_SHOTS` is set) and `test/exam_verify/goldens/*.png`

Tests that found real defects: V6 (D1), V9 (D2), S2 (D3). Tests V1, V3, V3b, V4, V5, V7, V8, V10, V11 (6 sizes), V12 (2 sizes), S1, S3, S4 passed and found nothing. Remove the `skip: true` lines on V6, V9 and S2 when the fixes land; those three then become regression tests. Return D1 to D5 to ui-creator (D3 also to the content owner).

---

# Round 2 (re-verification after the ui-creator fixes)

Commands: `flutter test test/exam test/exam_ui test/exam_verify` (with `EXAM_VERIFY_SHOTS=1`) gave 168 passed, 1 failed: the screenshot test compared against my round-1 goldens, which the fixes legitimately changed; after `--update-goldens` it passed. Outside exam code the whole suite has 6 failures in `test/teaching_verify` (teaching UI, not counted). `tool/write_exam_coverage_csv_test.dart` (new) passed.

## Findings re-checked
- D1 CLOSED. Empty subjects are now disabled chips ("Telugu Kingdom (no questions yet)") and Start runs an English-only exam; no loop. The creator's rewrite of V6 changes what it asserts (it no longer exercises a refusal), so it does weaken the check for the controller-refusal path: that path is no longer reachable from the UI, and `selection.dart` still words it with a raw id ("World "telugu" ..."), which is harmless only because the UI cannot trigger it. Residual: INFO.
- D2 CLOSED (V9 passes un-skipped: no "Level 6" text for Level 5).
- D3 CLOSED for answer-in-prompt. My scan S2 now reports 0 answer-in-prompt questions (was 14), 0 prompt pictures named after the answer. Remaining and by design: 9 sight-matching glyph questions (type `recognition`, difficulty 1), 149 listening questions (answer is spoken), 5 story questions (answer in passage = reading comprehension). Side effect to note: English Level 2 fell from 31 lessons with questions to 19 (the 12 spelling/lowercase items were the leaks), so English L2 now has 19 questions.
- Bank sizes confirmed independently by S1 and by the new CSV tool: L1 205, L2 156, L3 6, L4 6, L5 0; 14 rejected (12 English, 2 Telugu); independent lesson-step upper bound is still 207/168/6/6/0, the difference being exactly the rejected ones.
- D4 CLOSED: result screen shows "Revise: Animal sounds 0, Name common animals: missed 1 of 1" and topic "Alphabet" (viewed render).
- D5 CLOSED: certificate number is on one line, Date and Number both centred (viewed render).
- D6 CLOSED: 800x360 at 1.6 text shows prompt on the left and three options on the right, each side scrolling (viewed render; third option is clipped at the bottom edge of the scroll area, reachable by scrolling). Text 1.0 at 800x360 was not rendered by me; the creator's `fixes_test.dart` asserts options 0 and 1 fully on screen at 1.0 and 1.6 and my V11 800x360 runs (1.0 and 1.6) pass with no overflow.
- D7, D8: unchanged, INFO.

Regressions looked for: all 133 original exam tests, my V1 to V13 (V6 rewritten), S1 to S4 still pass; no new overflow in V11/V12 (6 + 2 size combos).

## Coverage CSV
`audit/EXAMINATION_QUESTION_BANK_COVERAGE.csv` regenerated from the real bank by `tool/write_exam_coverage_csv_test.dart` (run `flutter test tool/write_exam_coverage_csv_test.dart`), same ten columns. Level 1: English 26, Telugu 68, Hindi 46, Tamil 30, Number Galaxy 35 (total 205); Level 2: English 19, Telugu 27, Hindi 27, Tamil 27, Number 56 (156); Levels 3 and 4: 1 or 2 each (6); Level 5: 0. verified_questions is 0 everywhere. "proposed_lessons_not_yet_playable" keeps the old constants (0 for L1-2, 15 for L3-5), carried over, not recomputed. Status wording changed from "ready once the bank is built" to "ready (bank built from implemented lessons)".

## Round 2 per-screen verdicts
Entry/PIN PASS; Conduct Exam PASS; Child exam PASS (landscape layout improved); Results PASS; History PASS; Certificates PASS; Bank & Settings PASS; Question bank content PASS with the noted limits (recognition, listening and story questions are by design; English L2 now thin). Overall: PASS for the exam UI. Still unverified: real script shaping, TTS, TalkBack, device back gesture, real-disk boot, filled-button label legibility (render artefact), text 1.0 landscape render.
