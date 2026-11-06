# Tracing lessons handoff: big A, small a, small letters on the All letters path

Status: BUILT by ui-creator. Not verified by ui-verifier. Nothing committed.

## What was built

1. English Level 1 quest order (lib/src/curriculum.dart)
   - 1: `en-trace`, id unchanged, now "Trace big A", subtitle "Draw the big letter A with your finger", prerequisite on `en-a` removed.
   - 2: NEW `en-trace-a-lower`, "Trace small a", symbol `a`, kind tracing, `ageBands {explorer}` (Level 1 only), prerequisites `['en-trace']`.
   - 3: `en-a` ("A is for Apple") and everything after, in the same order (en-letter-002..026, en-word, en-story, ...).
   - No lesson id was changed or removed. Saved progress is untouched: a child with `en-a`/`en-trace` done keeps both; `en-trace-a-lower` shows as not done and is the recommended quest. `recommendedLesson` is unchanged (first unfinished lesson), so a new child gets big A, then small a.
   - Quest cards for tracing lessons already draw the letter big (`_GlyphArt`), so no art was added. Number Galaxy digit tracing and the Telugu/Hindi/Tamil trace quests are untouched; tracing still exists only at Level 1.
2. Tracing screen: `LessonScreen` / `WritingPad` unchanged. For `a` there is no template (`templateFor('a') == null`), so the pad uses the existing glyph-mask path: the pale font glyph is the guide, and `HandwritingPolicy` returns `goodShape` (practice only), never `mastered`. The capital A keeps its route map (pale road, dashed route, arrows, numbered dots). No arrows or numbers are shown for lowercase, and no stroke order was invented for it.
3. All letters path (lib/src/alphabet/alphabet_data.dart, lib/src/screens/alphabet_screen.dart)
   - `AlphabetSet.hasLowercase` (English only), `lowerGlyph(i)`, `lowerLessonId(i)` = `<big id>-lower`, e.g. `alpha-english-001-lower`. Big ids (`alpha-english-NNN`) are unchanged. The ids are `alpha-english-NNN`, not `en-letter-NNN`, because that is what the existing path already saves.
   - `LetterScreen` has a `lower` flag: for English, big X is followed by small x ("Next: x"), and only small x leads to the next big letter (or "All letters" at Z). App bar title shows "2 / 26 · big" / "2 / 26 · small" (English only).
   - Previous arrow from a small letter goes to its big letter; next arrow still jumps to the next big letter; nothing is locked.
   - Counters: "x of 26 letters traced" counts big letters only (unchanged); new "y of 26 small letters traced" below it. Tiles show a small lowercase badge (grey, green when traced).
   - "Next letter" button now also resumes at a small letter whose big letter is done.
   - Telugu, Hindi and Tamil: no lowercase step, no second counter (tested for Telugu).
   - The picture-word highlight now matches the first letter case-insensitively, so "Apple" highlights "A" for small `a` too.

Keys: existing `alphabet_progress_text`, `alphabet_continue`, `letter_tile_N`, `letter_pad`, `letter_big`, `next_letter`, `next_arrow`, `prev_letter`, `trace_pad`. New: `alphabet_lower_progress_text`, `lower_badge_<Letter>` (ValueKey on each tile badge). Pad key for the small step: `trace_<index>_lower`.

## Tests

New: test/tracing_lessons_test.dart (order and ids, prerequisites, Level 1 only, recommendation, old save with en-a/en-trace done, policy practice-only for `a`, A template unverified, two-step flow with separate saved ids, counters, Telugu unchanged, no-overflow at 360x800, 800x360, 1024x768 for both the tracing LessonScreen and the small-letter step, plus 1.6x text scale). All use fake stores and a ring mask; no disk.

Existing tests changed, each because the order, prerequisite or lesson count legitimately changed:
- test/audit/curriculum_audit_test.dart: total lesson count 177 to 178.
- test/app_widget_test.dart: first quest card key `lesson_en-a` to `lesson_en-trace`; the LessonScreen part now opens `en-a` explicitly (was `lessons.first`).
- test/controller_test.dart: reload test completes `en-a` explicitly (first lesson is now a trace).
- test/star_rules_test.dart: `lesson` = `en-a`, `other` = `en-letter-002` by id; recommended after en-a is now `en-trace`.
- test/replay_and_language_test.dart: English quiz tests use `en-a` by id instead of `lessons.first`; migration test uses `en-letter-002` instead of `lessons[1]`.
- test/home_responsive_test.dart: three `lessons.first` uses now `en-a` by id.
- test/alphabet_test.dart: "tracing A" test follows A, then a, then B and expects "2 / 26 · big"; last-letter test traces big Z then small z before "All letters"; progress-page test expects Next letter to open small `a`.

## Commands and real results

- `flutter analyze`: 6 issues found, all info/warning and all in files I did not touch (test/exam_verify, test/teaching, test/teaching_verify, tool/teaching_audit_test.dart). None in lib/.
- `flutter test` (whole suite, final run): `+816 ~3: All tests passed!` (3 skipped).
- An earlier full run had 26 failures; 25 were caused by this change (list above, now fixed) and 1 (`test/teaching/plan_test.dart` "answer must be one of the options") passed on a later run without any edit by me. It is not related to this work and was probably the teaching agent's file in flux.

## What was looked at, and what was not verified

- Rendered image: I rendered the pale glyph guide for A, a and g with the real Roboto font (a scratch test, since deleted) and looked at it. This was a replica of the guide's text style, not the actual `WritingPad` (the test environment cannot give the pad a real font), so it shows only the shape and size of the guide. `a` is Roboto's two-story `a`, readable and centred at the same size as the capital. The guide is pale (13% ink) as for every other non-template glyph; a child may find a thin pale outline harder to follow than the capital's road. Not checked on a device or emulator.
- NOT verified: the real `MaskValidator` against a real traced small `a` (tests use a ring mask); that a child's finger trace of a double-story `a` passes; touch behaviour on a phone; the full quest map scroll with the new first two cards on a real screen (only unit/widget checks of order and the first card key).
- Not verified: visual appearance of the "· big / · small" title, the tile badges or the second counter (only layout no-overflow tests ran).
- A single-story school `a` would suit children better, but the app has no handwriting font bundled; not done.
- Star behaviour: each small letter pays up to 3 stars once, through the existing `recordResult` cap, like the big letters (26 more quests of 3 stars). This was my default choice; say if small letters should not pay.
- Other agent's files: lib/src/models.dart, app_controller.dart, world_map_screen.dart and lib/src/teaching/* were not edited by me.
- ui-verifier review is still required.
