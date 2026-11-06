# Teaching UI verification report (ui-verifier)

Date: 2026-10-31. Verifier did not write the code under test. No lib/ or content/ file was edited. New tests added: `test/teaching_verify/teaching_adversarial_test.dart` (13 tests). Only the verifier's own screenshots are cited as visual evidence (scratchpad `v01.png` ... `v49.png`).

## Overall status: REVISE (not BLOCKED)

The flow rules are implemented and sound (teach -> demonstrate -> guided -> practice -> check -> remediation -> needsSupport; mastery pays once; no downgrade; old saves load). Four defects need ui-creator work before rollout: (1) the app bar title leaks check answers, (2) a quick double-tap on the last check "See my score" skips the score page, (3) in landscape phones the question, options and feedback do not fit together on one screen, (4) a fragile save parser. Nothing was found that loses progress or pays stars wrongly.

Counts: screens/areas judged 9 -> PASS 4, REVISE 5, BLOCKED 0. Findings: 0 blocker, 3 major, 4 minor, 2 info.

## Commands and results (verbatim)

| Command | Result |
|---|---|
| `flutter analyze` | `7 issues found. (ran in 3.1s)` - 2 unused_import warnings and 3 deprecated_member_use infos in `test/exam_verify/*` (other verifier's files), 1 unused_import in `tool/teaching_audit_test.dart`. 0 issues in lib/src/teaching, lib/src/art, or test/teaching. |
| `flutter test test/teaching` | `00:10 +70: All tests passed!` |
| `flutter test --reporter expanded` (whole suite, run while the other verifier was editing) | `02:48 +685 -3: Some tests failed.` The 3 failures are all in `test/exam_verify/` (child_exam_adversarial_test V6, V9; real_bank_scan_test S2). No teaching, exam_ui or audit test failed, and no timeout was seen in this run (the earlier exam_ui timeouts did not reproduce). exam_verify failures are the other verifier's territory; I did not re-run them in isolation. |
| `flutter test test/teaching_verify` | `+10 -6`. The 6 failures are real findings (below), not harness errors: 4 answer-leak tests (en-a, te-a, hi-a, ta-a), 1 double-tap test, 1 corrupt-save test. Passing 10: num-add leak check, wrong-everywhere -> needsSupport, replay pays 0 and mastered never downgraded, pass pays 3 once, backgrounding keeps hints/tried options, hint 1 never contains answer (all 5 lessons), shuffle never leaves answer in stored slot (200 seeds x 5 lessons), strict phase order / no question before teaching, level switching keeps teaching progress + no-plan lesson has no plan + bad plan file ignored, teaching pictures have captions / question pictures do not. |

## Source review against the rules

| Rule | Verdict | Evidence |
|---|---|---|
| teach -> demo -> guided -> practice -> check; no question before teaching | PASS | `teaching_flow.dart` `next()`; my test "no independent question before teaching; order is strict" (5 lessons). On device: Learn 1-2, Watch 1-5, Try with help, Practise, Check in order (v07-v31). |
| Guided hint ladder, free retry | PASS | Device v14-v20: wrong tap greys the option and shows tailored feedback; Hint then "Another hint"; Next stays disabled until solved. Test: hint 1 never contains the answer. |
| Check shows nothing until the end | PASS (device + test) | v28: chosen option is only highlighted, no tick/cross, no hint button, no feedback. Semantics never say "correct" (my test, asserted for every check item). |
| Remediation cap -> needsSupport, not mastered, child can continue | PASS | Widget test: wrong everywhere -> 2 remediation cycles -> `needs_support_card`; no stars, lesson not in completedLessons, status needsSupport, Back button present. Not seen on device. |
| Mastery calls recordResult once; replay pays 0; never downgraded | PASS | Tests above. Device: first pass paid 3 stars (60 -> 63, v32); quest count 1/56 afterwards (v34). |
| Resume, old saves, level switching | PASS (with F7) | Backgrounding test; level switching test; real-file test by creator; I switched L4 -> L2 -> L1 on device and the completed quest persisted. |
| Option shuffle mandatory | PASS | 200 seeds x 5 lessons x all questions: answer never in its stored slot. |
| Audio-only items | PASS visually, with F1 | v31 / v46: large "Listen again" tile, options visible. |
| Empty-caption question pictures never show answer text | PASS | v44: practice picture has no caption; test confirms plan data. |
| Native-review flags never shown to child | PASS | Not present in any screenshot or in the widget source. |

## Per-screen findings

### 1. App bar title during questions (all five pilot lessons) - REVISE, MAJOR (F1)
Evidence: every screenshot of te-a shows the title "అ – అమ్మ" across Learn, Watch, guided, practice (v38-v49) - it is the lesson title, drawn in every phase, including the check. For te-a, hi-a, ta-a the check items `*.check.1` (audio-only word_to_letter: the answer letter) and `*.check.2` (pick_word) contain text that appears in the title; my Semantics/visible-text test reports `te-a.check.1: [అ – అమ్మ]`, `te-a.check.2`, `hi-a.check.1/2` (अ – अनार), `ta-a.check.1/2`; en-a also fails. The audio-only check item is therefore readable from the title, defeating "listen and pick". Reproduce: `flutter test test/teaching_verify` (leak tests). Owner: ui-creator. Fix: in question phases of check/remediation check show a neutral title (e.g. "Check") or hide the plan title.

### 2. Last check item, "See my score" - REVISE, MAJOR (F2)
Evidence: on device two fast taps on "See my score" (v31 -> v32) went straight to the mastery dialog "You earned 3 stars", the score page and per-item review never appeared. Same in `flutter test` ("double-tap on the last check Next does not skip the score page" fails: no `check_score`). Cause: result phase reuses the same `next_button` at the same position and `canAdvance` is true on `isResult`. Owner: ui-creator. Fix: debounce/disable Next briefly after entering a result phase or move the result action.

### 3. Landscape phone layout (2400x1080 emulator, about 410 dp tall) - REVISE, MAJOR (F3)
Evidence v14, v19, v23, v29: the right column shows prompt, Listen, Hint and only the first one or two options; the other options are below the fold and must be scrolled. After scrolling (v15) the prompt is off screen. After a wrong tap the feedback text appears below the last option and is not visible without scrolling (v16 vs v17); after a hint the options are pushed completely off screen (v20). A child may not notice more options or the feedback. Picture steps are clipped by the card edge: v41 (caption under the elephant cut off). Owner: ui-creator. Suggest: compact prompt/Listen row in short heights, auto-scroll to feedback, or put options in a two-column grid on wide short screens.
Small phones in portrait (360x800 etc.) were covered only by creator widget tests (no overflow exceptions); not seen on device.

### 4. Number Galaxy 'Rocket Addition' (num-add, Level 2) on device - mostly PASS
Played Learn, Watch, guided (one wrong tap, hint), practice, check (one wrong, then pass 2/3). Emoji render with no tofu (v07, v11, v23, v29). Number line draws hops in guided (v19) and no hops in check (v29), as specified. Check shows no total or result. Notes: 
- F4 minor: step 4 "= 5" breaks across lines: "=" at the end of line 1 and "5" on line 2 (v12). 
- F5 minor: with 5 + 3 objects the "+" sits alone at line end (v27). 
- F6 minor: Next/Back bar is not right-aligned in landscape (Next floats left of centre, v08); touch targets look fine (Next about 60 dp tall).
- Pass dialog (v32) is clear; Play again / Back to map targets large.

### 5. Telugu first lesson te-a, 'అ - అమ్మ' (Level 1) on device - PASS for rendering, REVISE for F1/F3
Telugu text is shaped correctly in title, prompts, options and the big glyph (v38-v46); pictures with options render (v43, v46). Audio-only practice item shows the large "Listen again" tile and picture+word options (v46). Pressing Listen again showed no "voice missing" notice (v47); I cannot say whether audio played (emulator has no audio). The lesson was already completed on this profile, so this was a replay (Play again); the check phase of te-a was not reached on device (only in widget tests). Practice 1 question picture has no caption (v44) - good.

### 6. needsSupport and remediation screens - PASS in test only (not seen on device)
`needs_support_card` and remediation banner are covered by creator and verifier widget tests; not visually inspected on the emulator.

### 7. Save format robustness - REVISE, MINOR (F7)
`ProgressRecord.fromJson` / `TeachingProgress.fromJson` throw on a wrongly typed teaching field (e.g. `'teaching': 'x'` -> `type 'String' is not a subtype of type 'Map?'`, `'phasesDone': 'x'` -> `List?` cast), unlike enum parsing which falls back. Old saves with no teaching key load fine and re-save without a `teaching` key (my test passes). Only corrupted files are affected. Test: "old save without teaching round-trips; corrupt teaching field loads" (fails on corrupt types only).

### 8. Lesson with no plan - PASS
`planFor('te-b')` null; a broken plan file leaves the app loading with no plans. Routing in world_map_screen.dart falls back to LessonScreen/BatchLessonScreen. On device the other quests (e.g. Telugu 'All letters') still show their old cards.

### 9. Exam separation - PASS
The teaching screens never touch lib/src/exam; progress is stored under `ProgressRecord.teaching` only.

## Other observations (info)
- I1: remediation_explain pictures in all four language plans have empty captions (teaching steps, not questions); the step text names the word, so no answer leak, but they show no caption.
- I2: num-add check item 3 ("7 + 2 = ?", `visual: none`) is shown as text plus a Listen again tile; it is symbolic rather than audio-only, so a missing device voice does not block it.

## Unverified / not covered
- TTS audio was not heard (emulator has no audio); the missing-voice notice was not seen on device.
- Native-script correctness (Telugu/Hindi/Tamil wording, letters, words) not reviewed: needs native speakers. Hi-a, ta-a, en-a were not opened on device.
- TalkBack was not run (only Semantics tree inspected in tests).
- No other device sizes on hardware; 360x800, 390x844, 800x1280, 1024x768 only through the creator's widget tests; no enlarged-text test on device.
- te-a check phase, remediation and needsSupport screens not seen on device.
- Test profile on the emulator now has: Rocket Addition completed (+3 stars, 60 -> 63) and te-a saved at 'practice'. No data was wiped.
- The emulator package `app.aksharamala` (debug, last updated 2026-10-31 03:42) was assumed to be the current code; I did not diff the APK against source.
- The 3 failing `test/exam_verify` tests belong to the other verifier and were not investigated.

---

# Round 2 (re-verification after ui-creator fixes)

Build: `app.aksharamala` debug, `lastUpdateTime=2026-10-31 07:44:50` (freshly installed). Screenshots `w01`-`w35`, `x0`-`x10` in the scratchpad. No data wiped.

## Overall status after round 2: REVISE (one minor open item; F1, F2, F3 and the minors are fixed)

## Commands and results
| Command | Result |
|---|---|
| my test fix | The en-a leak test now matches a one-letter answer only when a Semantics segment equals the letter exactly (longer answers keep the substring check). It is still capable of failing: it caught the title leak in round 1. |
| `flutter test test/teaching_verify --reporter expanded` | `00:05 +16: All tests passed!` (all 16 tests incl. the 5 leak tests for en-a, te-a, hi-a, ta-a, num-add, the double-tap test, corrupt-save test) |
| `flutter analyze` | `5 issues found. (ran in 2.6s)`: deprecation infos in `test/exam_verify`, 1 unused import in `tool/teaching_audit_test.dart`, and 1 info (`prefer_single_quotes`) in my own `test/teaching_verify/teaching_adversarial_test.dart:52`. Nothing in lib/. |
| `flutter test test/teaching` | `00:10 +79: All tests passed!` |
| `flutter test --reporter expanded` (whole suite) | `02:43 +723 ~1: All tests passed!` (1 skipped; the 3 earlier exam_verify failures are gone) |

## Per-screen verdicts (device evidence)
| Screen | Verdict | Evidence |
|---|---|---|
| F1 neutral titles | PASS | Practice title is "Practise" (w15), check and remediation-check are "Show what you know" (w16, w18, w20, w24, w26, w31, w33), score pages too (w21, w27, w34). Learn/Watch/guided keep the lesson title. |
| F2 score page + Continue + double-tap | PASS | Two fast taps on "See my score" (adb, two taps in one shell call) now land on the score page "0 out of 3" with per-item review and a right-aligned Continue (w21). It does not skip. Continue then went to Extra help (w22, w23). |
| F3 landscape phone layout | PASS with one REVISE (R2-1) | Guided question shows prompt row + 3 options at once in two columns (w07). Picture caption "Cat" fully visible (w06). Hint shown and the options stay reachable below it (w08-w10). A wrong tap shows feedback (w12 "That is a different letter. Look closely at the letter."). Number-line, objects row ("+ / = 5") not re-checked on device (num-add not replayed in round 2). |
| Icon-only Listen/Hint (compact mode) | PASS (readable) | Speaker and lightbulb icons are clear and about 56 px tall on the emulator (about 48 dp); tooltips not seen (needs long-press). On pure step screens Listen is a labelled button. A child who cannot read must learn the lightbulb, acceptable. Practice shows only the speaker (no hint) as intended (w15). |
| Pass AND fail -> remediation | PASS | Fail: 0 of 3 (w21) -> Extra help 1/3 with amber phase bar and "Let's look at it another way." banner (w22, w23) -> remediation check 1/3 shows 1 out of 3 (w27) -> second Extra help cycle (w28) -> remediation check, 3 of 3 (w34) -> Continue -> LessonResultDialog "You already collected every star in this quest. Great practice!" with stars unchanged at 63 (w35). So the fail -> remediation x2 -> pass path and the no-extra-stars replay both work on device. needsSupport was not reached on device (covered by tests). |
| en-a lesson (Level 1) | PASS | Intro (w05), Watch with caption (w06), guided (w07-w14), practice with picture and speaker-only prompt (w15), audio-only check item with "Listen again" tile (w16), picture question without caption (w20). Emoji not applicable here; no tofu seen. |
| hi-a lesson (Level 1) | PASS | Devanagari shaped correctly in title, prompt and options (x3, x4, x5); picture options render. |
| ta-a lesson (Level 1) | PASS | Tamil shaped correctly in title, step text and caption (x9, x10), including long multi-line text that fits. |

## New / open findings
- R2-1 (REVISE, minor): when a hint and a wrong-answer feedback are both showing (guided, compact mode) the pinned strip (max 22%) only shows about one line; the hint box is scrolled partly out and the feedback is cut after its first line (w11 shows "Cat begins with a different letter. Look at another" cut off; second line needs an in-strip scroll). Reproduce: guided question 1 in en-a at the phone landscape size, tap the lightbulb, then tap Cat. Owner: ui-creator (raise the strip cap while both are present, or show only the latest hint above the feedback).
- R2-2 (info): practice question 4/5 in te-a and the check items use the large "Listen again" tile together with a text prompt that already says what to do; no duplication problem seen.

## Still unverified after round 2
- TTS audio (emulator has no audio); the missing-voice notice was not seen.
- Native-script correctness; I only judged shaping/legibility of Telugu (te-a, round 1), Hindi, Tamil.
- TalkBack was not run; Semantics checked only in widget tests.
- needsSupport screen on device (tests only); num-add re-check of the objects row and number line after the F3/minor fixes; portrait phones, tablets and enlarged text on hardware.
- Tooltips of the icon-only buttons.
- The emulator profile: en-a, hi-a and ta-a were opened but not completed in round 2; Rocket Addition remains completed; en-a replayed with no extra stars.


---

# Round 3 (device: tracing lessons, rolled-out plans, R2-1)

Build: `app.aksharamala` debug, `lastUpdateTime=2026-10-31 12:28:30`. Screenshots y01-y22, z1-z13, d1-d11, e4 in the scratchpad. No data wiped. The Test profile ended with 75 stars (72 before, +3 for Trace small a). Overall status: REVISE (minor items only; tracing PASS).

## Commands and results
| Command | Result |
|---|---|
| `flutter analyze` | `6 issues found. (ran in 2.4s)` (infos/warnings in test/exam_verify, tool/ and my test files; none in lib/) |
| `flutter test --reporter expanded` (whole suite, run before my sweep file existed) | `02:58 +816 ~3: All tests passed!` |
| `flutter test test/teaching_verify/rollout_sweep_test.dart` (new, mine) | Plays 112 rolled-out lessons (all 72 numbers lessons, every 4th letters lesson, the pilots) through the real UI to an end state at 915x410 and 360x800, deliberately failing the check on every 3rd: 0 layout exceptions. One lesson (numbers-56-050) did not finish; the cause is my harness (it matched the wrong one of two questions with the same prompt "What is the name of this shape?"), not the app. Test font, layout only. |

## (A) Tracing lessons
See audit/TRACING_LESSONS_VERIFICATION.md. PASS: order Trace big A, Trace small a, A is for Apple; both trace; stars +3 once; All letters path shows big then small and two counters. Minor: T1 wording "Follow the shape of the number" on a letter, T2 pale small-a guide, T3 quest and path count the small a separately.

## (B) Rolled-out teaching content
| Item | Verdict | Evidence |
|---|---|---|
| App start-up | PASS | `am start -W` cold start `TotalTime: 2983` ms; home screen already drawn in the first screenshot. |
| First open of a lesson | PASS | The Telugu lesson opened and was fully drawn about 1 s after the tap (d6 and d7, a second later, identical). No spinner or blank. |
| English en-b | PASS | "This is the letter B. It has a big B and a small b." with large "B b" (y11). |
| Telugu letter lesson (ఇ) | PASS | Glyph, title, step text shape correctly (d6); picture step with squirrel and caption ఉడుత (d8); guided question with 3 picture+word options and icon-only speaker/hint (d9). |
| Hindi, Tamil Level 1 | PASS | Opened in round 2 (x3-x10), unchanged. |
| Level 2 Moon Subtraction | PASS with R3-2, R3-3 | Counted oranges 1-7 (z7), crossed-out group with clear red X and "- 2" (z8, z9), number-line check by adding with hops (z10). R3-2 (minor): the equation row reads "- 2 = 5" with no starting 7 (only the text says 7). R3-3 (minor): number-line tick labels show only 0, 2, 5, 8, 10; the landing point 7 named in the text is not labelled. |
| Level 1 counting, tens-and-ones (baseTen), compare, number pattern, shape lessons | BLOCKED on device | These quests are Locked on the Test profile (z11, z13); I did not complete about 40 quests or change the profile. Only the layout sweep (0 exceptions) covers them. baseTen, compare, pattern and shape visuals are NOT visually verified. |
| Lessons WITHOUT a plan (Level 2 word lessons) | Cards only | Cards "morning", "longer", "rupees" are normal locked cards with the old subtitle "Learner can understand everyday math in everyday..." (z11). Could not open (locked); routing was verified in tests in round 1. |

## (C) R2-1 hint + wrong feedback in phone landscape
Telugu guided Q1, hint tapped then a wrong answer (d9-d11): the hint and the wrong-answer feedback are both fully visible. PASS for R2-1 itself.
New finding R3-1 (REVISE, owner ui-creator): once the hint is showing, the options region is squeezed, so the third option (ఇల్లు, the correct answer here) shows only as a thin sliver at the edge of a small scroll window (d10, d11) while roughly 200 px below stays empty. A child must scroll a tiny window to reach it. Reproduce: Level 1 Telugu, lesson "ఈ అక్షరం ఏది?" (the ఇ lesson), guided Q1, tap the lightbulb. Suggest giving the options the remaining height or shrinking the hint and feedback to one line each.

## Unverified after round 3
- TTS audio, native-script correctness, TalkBack.
- baseTen, compare, pattern and shape lessons on device (locked).
- The checks of the new Telugu and English lessons beyond the guided phase; real-device (not emulator) timing.
- needsSupport screen on device.
