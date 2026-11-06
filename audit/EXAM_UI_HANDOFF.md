# Examination UI hand-off for the independent ui-verifier

Status: **built and unit/widget tested; NOT visually verified.** No screenshot of
any exam screen has been captured or viewed. Nothing here is self-certified.

## Files

New (under `E:\Aksharamala`):
- `lib/src/screens/exam/exam_scope.dart` - `ExamScope` (InheritedNotifier for `ExamController`).
- `lib/src/screens/exam/exam_widgets.dart` - shared cards, `CountStepper`, `confirmDialog`, `Notice`, date helpers.
- `lib/src/screens/exam/pin_dialogs.dart` - PIN unlock/set/change/clear dialog.
- `lib/src/screens/exam/examination_centre.dart` - entry function `openExaminationCentre`, centre with 5 tabs, child picker.
- `lib/src/screens/exam/conduct_tab.dart`, `results_tab.dart` (also `ResultScreen`, `ResultDetail`, parent marking), `history_tab.dart`, `certificates_tab.dart` (also `CertificateScreen`), `settings_tab.dart`.
- `lib/src/screens/exam/child_exam_screen.dart` - the child's exam route.
- `test/exam_ui/{ui_helpers,entry_test,conduct_test,child_exam_test,results_test,layout_test}.dart`.

Edited (additive): `lib/src/app.dart` (optional `examController` param, `ExamScope` wrapped around `MaterialApp`, `examController.load()` at start, dispose), `lib/src/screens/parent_dashboard.dart` (one 'Examination Centre' button, shown only when an `ExamScope` exists).
Not touched by this work: world_map_screen.dart, models.dart, app_controller.dart, lib/src/teaching/, lesson IDs, progress.json, profiles, rewards.

## Route
Home -> Parents (existing arithmetic gate) -> Parent dashboard -> button `open_exam_centre` -> (PIN dialog if the active child has one) -> Examination Centre -> Start/Resume pushes `ChildExamScreen`.
Only `app.dart` and `parent_dashboard.dart` outside `screens/exam/` and `exam/` mention the centre or controller (enforced by a source-scan test).

## Behaviour decisions to check
- Finishing or leaving a child exam does `popUntil(first)`: it returns to the app's first route (Home), NOT to the parent centre, so a child cannot wander into the centre. The parent re-enters through Parents.
- The child sees only 'Well done!' (passed, fully marked), 'Good try!' (not passed) or 'You finished!' (awaiting parent marking). No marks, percentages or answers.
- Final-level exams default to the subjects that have questions at the chosen level (a subject with none made the controller refuse). The parent can change the chips.
- The availability line uses `ExamSelection.candidates` assuming all pictures exist; the controller's refusal (shown after Start) is the final word.
- Parent-marked items are only offered when 'Include writing items I will mark myself' is on.
- Listen uses `SpeechService`, locale from the world id (telugu te-IN, hindi hi-IN, tamil ta-IN, else en-US); shown only when the question has `speech`.
- Timer: wall-clock `startedAt + limit`; the screen takes an injectable clock for tests.

## Widget keys
Dashboard: `open_exam_centre`.
Centre: `tab_conduct tab_results tab_history tab_certificates tab_settings`, `exam_child`.
PIN dialog: `pin_current pin_new pin_error pin_ok pin_cancel`.
Conduct: `conduct_list level_1..5 type_chapter type_subject type_finalLevel world_<id> final_world_<id> lesson_<lessonId> availability count_minus/plus/value mix_0..2 include_parent pass_minus/plus/value per_world timed minutes_minus/plus/value retest_unlimited retest_maxAttempts retest_waitHours retest_value_minus/plus/value start_message use_available start_exam unfinished_card resume_exam discard_exam confirm_discard`.
Child exam: `exam_back exam_title exam_timer prompt passage glyph listen option_<index> prev_question next_question go_review question_list review_list review_summary review_<i> review_status_<i> review_back submit_exam confirm_submit keep_checking confirm_leave keep_going done_list done_headline done_body time_up_note hand_back`.
Results: `no_results result_summary result_marks result_percent result_verdict awaiting_note tamper_warning parent_marking mark_correct_<qid> mark_incorrect_<qid> subject_<worldId> topic_<topic> recommendation_<lessonId> no_recommendations readiness wrong_<qid> no_wrong`.
History: `history_list no_history history_<attemptId>`.
Certificates: `no_certificates certificate_<level> certificate_card certificate_name certificate_level certificate_date certificate_id certificate_reissued reissue_certificate confirm_reissue`.
Settings: `settings_list default_pass_minus/plus/value pin_status pin_set pin_change pin_clear bank_total flag_pending flag_tts coverage_level_<n> coverage_empty_<n> coverage_<n>_<worldId>`.

## Tests (test/exam_ui)
`layout_test.dart` runs the Examination Centre (all five tabs, every option on, certificate view, PIN dialog, a wrong-answer tile) and the child exam (every question, review, confirm dialog, done page) at 360x800, 390x844, 800x1280 and 1024x768, each at text scale 1.0 and 1.6; it asserts no layout exception and Start / option / Next / Hand-back buttons >= 48 dp high and on screen.

- child_exam_test.dart: one question per screen with progress and no right/wrong feedback
- child_exam_test.dart: an answer can be changed until submission
- child_exam_test.dart: review page lists answered and unanswered and goes back to a question
- child_exam_test.dart: submit asks for confirmation; Keep checking leaves the exam open
- child_exam_test.dart: after submit the child sees pass/try-again only, no marks; device handed back
- child_exam_test.dart: a failed exam gets an encouraging try-again message
- child_exam_test.dart: an exam awards no stars and changes no lesson progress
- child_exam_test.dart: back asks first and keeps the attempt resumable
- child_exam_test.dart: resume after rebuilding the controller from the same store
- child_exam_test.dart: timer is a plain number; expiry submits what is answered
- child_exam_test.dart: no timer is shown for an untimed exam
- child_exam_test.dart: Listen speaks the lesson line only when a question has one
- child_exam_test.dart: parent-marked items need no answer and are left to the parent
- conduct_test.dart: shows honest availability and starts a subject exam
- conduct_test.dart: rules chosen on screen reach the exam config
- conduct_test.dart: refuses with the controller message when too few, offers N
- conduct_test.dart: Level 5 says its lessons are coming and cannot start
- conduct_test.dart: chapter test lets the parent pick lessons
- conduct_test.dart: final level exam covers chosen worlds
- conduct_test.dart: unfinished attempt offers Resume or Discard
- conduct_test.dart: Resume reopens the child exam
- conduct_test.dart: retest policy refusal is shown
- entry_test.dart: parent dashboard has the Examination Centre button and opens it
- entry_test.dart: a PIN is asked for before the centre opens
- entry_test.dart: switching to a child with a PIN asks for that PIN
- entry_test.dart: the normal child app shows no exam entry
- entry_test.dart: no child-facing screen can reach the Examination Centre
- layout_test.dart: Examination Centre has no overflow at $tag
- layout_test.dart: child exam screens have no overflow at $tag
- results_test.dart: empty states say there is nothing yet
- results_test.dart: result screen shows score, breakdown, wrong answers and recommendations
- results_test.dart: failed exam shows Not passed yet
- results_test.dart: parent marking: awaiting state, then marks recalculate the result
- results_test.dart: a result that fails verification shows the tamper warning
- results_test.dart: history is newest first and opens a result
- results_test.dart: history lists discarded and unfinished attempts too
- results_test.dart: a passed final exam gives one certificate card
- results_test.dart: a second pass of the same level does not add a certificate
- results_test.dart: reissue asks first, then counts; cancel changes nothing
- results_test.dart: a failed final exam gives none
- results_test.dart: coverage per level, Level 5 empty, flags counted
- results_test.dart: default pass mark is saved for the child
- results_test.dart: PIN: set, change, clear

## Harness notes
- `MemoryExamStore` replaces the file store (JSON round trip), so "resume after rebuilding the controller" is proved against the stored JSON.
- Controller calls that hit the store are run with `runAsync` (`real()` / `settle()` helpers); otherwise they never finish in the fake-async zone.
- Layout tests use the Flutter test font (Ahem), wider than real fonts: a strict width check, but it says nothing about real Telugu/Hindi/Tamil shaping. `scriptStyle` is applied to prompts, options, passage, glyph and lesson titles but no script rendering was looked at.

## Not verified (for the ui-verifier)
- Everything visual: spacing, contrast of the tinted cards, certificate look, tab bar scrolling at 360 wide, dropdown appearance.
- On a device: back gesture with the confirm dialog, TTS Listen, rotation mid-exam, killing and reopening the app (only simulated by rebuilding the controller).
- TalkBack: semantic labels exist (options, timer, review rows, score rows, certificate) but no screen reader was run.
- A full `AksharamalaApp` boot with the real disk `ExamStore` was not driven in a widget test (real disk hangs there); the existing `app_widget_test` still passes.
- English text only; wide screens use one centred column (max 760 dp), not two panes.

## Commands run
- `flutter analyze` -> one warning, an unused import in `tool/teaching_audit_test.dart` (other agent's file).
- `flutter test test/exam test/exam_ui` -> 133 passed (76 domain + 57 UI).
- `flutter test` (whole suite) -> 663 passed at the time of the run.

## Fixes (after the independent verification, REVISE)

Not self-certified; the ui-verifier must re-check.

- D1: Final Level: subjects with no questions at the chosen level are switched off (chip disabled, label "<friendly name> (no questions yet)", note `final_empty_note`) and never included; Start is blocked when no subject has questions. If the controller still refuses because of an empty subject, the message names it ("Telugu Kingdom has no questions at Level 1 yet. Switch it off to go on.") and "Use N questions instead" is not offered, so there is no refusal loop. `conduct_tab.dart`. Verifier test V6 was rewritten to this behaviour (the chip is disabled; Start runs an English-only exam) rather than expecting a refusal.
- D2: Level 5 results show "Level 5 is the highest level" instead of "Ready for Level 6?". `results_tab.dart`.
- D3: `question_bank.dart`: a question whose prompt contains the correct answer is rejected with reason "answer visible in prompt" (14 in `bank.rejected`; arithmetic exempt). Glyph == correct option questions are kept as new type `ExamQuestionType.recognition` (added to the enum in `exam/models.dart`, unknown names already fall back safely) with difficulty forced to 1 (9 remain in the real bank; the verifier counted 10, one of them was among the rejected leaks). Real bank sizes now: Level 1 205 (was 207), Level 2 156 (was 168), Levels 3/4 6, Level 5 0. `audit/EXAMINATION_QUESTION_BANK_COVERAGE.csv` is NOT generated by any tool in the repo and was NOT updated; its per-world "question_items_available_today" figures are now slightly high (total minus 14 leaks). Skips were removed from V6, V9 and S2, which now run and pass.
- D4: parent result shows "Revise: <lesson title>, <objective>: missed M of N" with no ids (`recommendationText`), and topic names as words (`topicLabel`: `wordBuilder` -> "Word Builder").
- D5: certificate number is one line scaled down with `FittedBox`; Date and Number lines are both centred.
- D6: on short landscape screens (question area under 420 dp high and at least 600 wide) the question and the answers sit side by side, each scrolling on its own. Test `fixes_test.dart` checks options 0 and 1 are fully on screen at 800x360 at text 1.0 and 1.6.
- D7: unchanged (no route exists). D8: left as is. Retest `maxAttempts` counts submitted attempts only; discarding does not consume one.
- New tests: `test/exam_ui/fixes_test.dart`. Test helper `reveal` now tries every vertical list.

Commands: `flutter analyze` -> 4 issues: 3 infos in `test/exam_verify` (deprecated API in the verifier's test) and the unused-import warning in `tool/teaching_audit_test.dart`; none in exam code. `flutter test test/exam test/exam_ui test/exam_verify` -> 168 passed, 1 skipped (the screenshot capture), 0 failed. Whole suite: 708 passed, 6 failed, all in `test/teaching_verify/teaching_adversarial_test.dart` (the other agent's in-progress work).
