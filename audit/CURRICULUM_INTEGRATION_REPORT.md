# Curriculum integration report: Stage 1 audit and Stage 2 plan

Date: 31 October 2026. Source workbook: `Aksharamala_Consolidated_Curriculum_Levels_1_to_5.xlsx`. Status: **audit and plan only. No application code has been changed for this task.** Stage 3 starts only after approval (see "Decisions I need from you").

## 1. Starting state of the repository

| Item | Finding |
|---|---|
| Branch | `main` at `188550f`; GitHub (`origin/main`) is at `aef2b97`, so 2 commits are local only |
| Uncommitted work | 32 files from earlier sessions: all-levels-by-default, English-only Number Galaxy, Level-1-only writing, 13 Hindi/Tamil alphabet pictures, the curriculum workbook, overflow fix. They pass the suite. **I recommend committing them as a baseline before Stage 3.** |
| Tests | 30 test files, 452 tests pass; strict curriculum audit 42/42; `flutter analyze` clean |
| Size | `age56_content.dart` (generated, 7,187 lines), `world_map_screen.dart` (1,210), `lesson_screen.dart` (984), `batch_lesson_screen.dart` (911) |

## 2. How the app is built today (what Stage 3 must respect)

- **Lessons**: two kinds share one `Lesson` model. 20 hand-written *legacy* lessons and ~340 generated or batch lessons. `BatchLesson` (a `Lesson` with ordered `steps`: listen, pick, count, compare, quiz question, write) is the engine for everything newer. `age56_content.dart` is **generated** by `tool/generate_age56.dart` from `content/age56/*.json`: it must be edited through its generator, not by hand.
- **Level today**: a lesson carries `ageBands` (a set of four `ExperienceStage` values). A profile stores one `age`; the "Level 1–4" tiles just save a representative age (4, 6, 8, 11). **There is no stored level and no Level 5.** `ExperienceStage` appears 72 times in 5 files.
- **Preview switch**: `newLessonsEnabled` / `setNewLessons` (13 uses in 3 files). It is now on by default and can be turned off by a parent. It is obsolete as a concept.
- **Progress**: `ProgressRecord` per child: finished lesson ids, stars per lesson, and attempts/correct **per world** (not per level). Because every lesson id belongs to one level, per-lesson progress is already independent between levels; per-level statistics do not exist.
- **Unlocking**: `isLessonUnlocked` only enforces prerequisites for ids containing `-56-`. Everything else is open.
- **Persistence**: one JSON file (`progress.json`, `"version": 1`) with profiles, progress and one setting. Writes go through a temp file and a rename. There is no backup and no migration step.
- **Parents section**: `ParentDashboard` behind an arithmetic gate ("What is 7 + 5?"). It is a screen, not a section with sub-pages; there is no parent PIN.
- **Questions**: there is no question bank. Questions live inside lessons (options + answer, or quiz steps).

## 3. The curriculum workbook (single source of truth)

**Source: `Aksharamala_Consolidated_Curriculum_Levels_1_to_5.xlsx`**, as you instructed. I also compared it row by row with the three earlier workbooks (`AKSHARAMALA_CURRICULUM_BY_LEVEL.xlsx`, `..._Level_2_and_3_...`, `..._Level_4_and_5_...`): it holds exactly the same **589 lesson ids, with no id missing, no extra id and no field that differs.** So nothing in the earlier audit changes.

| Sheet | Rows | Content |
|---|---:|---|
| Level 1 | 184 | 180 lessons + 4 combined "All letters" rows (one per language; not lessons) |
| Level 2 | 168 | the 168 lessons already in the app |
| Level 3 | 81 | 6 existing + 75 proposed |
| Level 4 | 81 | 6 existing + 75 proposed |
| Level 5 | 75 | 75 proposed |
| Level 1 letters | 153 | every letter with its picture word |
| Overview | n/a | counts and notes |

All level sheets use 13 columns (world, #, lesson id, title, what the child does, objective, topic/skill, examples, needs first, language, writing, needs preview switch, pictures still missing). Together: **589 rows; 360 exist in the app and 225 are proposed** (15 per world at each of Levels 3, 4 and 5). The workbook's own notes say the preview-switch column is legacy and that proposed rows need educator, language, artwork, audio and app validation; I agree and follow that.

### Integrity checks (script, all three workbooks)

| Check | Result |
|---|---|
| Duplicate lesson ids across Levels 1–5 | **0** |
| Level 2 identical in the two workbooks | yes (168 = 168, no text differences) |
| Level 3 and 4 "existing" rows identical to the original workbook | yes |
| Every non-proposed workbook id exists in the app | **yes (360 of 360)** |
| Consolidated workbook vs the three earlier workbooks | **identical**: same 589 ids, no field differs |
| Every app lesson id appears in the workbook | **yes (none missing)** |
| Prerequisites that point at an unknown id | **0** |
| Prerequisite self-references or cycles | **0** |
| Existing lessons that need a proposed lesson | **0** |

So **the workbooks and the app agree on every existing lesson id.** Existing ids can be kept as they are, and no child's saved progress is at risk from the id scheme.

## 4. Findings that change the plan

1. **The proposals are outlines, not lessons.** Each of the 225 rows has a title, a one-line activity, an objective and examples. None has teaching text, practice items, answer keys or distractors. They cannot be "imported" into playable lessons; the content has to be **written** (by me as drafts, then reviewed). That is the largest piece of work in this project.
2. **Levels 4 and 5 regional rows are English descriptions.** 90 Telugu/Hindi/Tamil proposals (45 each at Level 4 and 5) contain no native script. 90 further rows use **the same English title and activity for all three languages** (for example "Reading fluency", "Vocabulary in context"), so language-specific content (real passages, real morphology, real words) is not yet specified. Level 3 regional rows are in native script.
3. **Prerequisites chain across levels.** 20 rows (5 each at Levels 2, 3, 4 and 5, one per world) require a lesson from the level below: the existing Level 2 lesson `en-word` needs the Level 1 lesson `en-a`, the existing story needs the Level 2 word lesson, and so on, and the first proposed lesson of each chain continues from them. The proposed lessons then form one linear chain of 15 per world per level, each needing the one before. With free level choice, links that cross a level must not be locks.
4. **Some activities cannot be marked automatically.** 4 rows are read-aloud or fluency tasks; 100 rows are writing "practice only". They must stay practice or parent-judged, never auto-scored.
5. **Level 1 letter quests are indistinguishable on the map** (121 quests share one title per language: "Which letter is this?"). Not a data error, but a usability gap now that the All letters card exists.
6. **Examination data cannot be built from the proposals.** Today's questions: Level 1 has 207 question items, Level 2 has 168, **Level 3 has 6, Level 4 has 6, Level 5 has none** (one per world, two for numbers). Subject and final exams at Levels 3–5 are not possible until their lessons exist. See `EXAMINATION_QUESTION_BANK_COVERAGE.csv`.
7. **Three pieces of the old design are now in the way:** age-based `ageBands`, the preview switch, and per-world (not per level) statistics.
8. **Age 5–6 lessons are the current Level 2.** The workbook's Level 2 is exactly the 168 existing lessons; nothing there needs rewriting.

Details: `CURRICULUM_GAPS_AND_DUPLICATES.csv` (427 rows), `LEVEL_1_TO_5_COVERAGE_REPORT.md`.

## 5. Integration plan (Stage 3, in batches, each tested before the next)

**Batch 0: baseline.** Commit the 32 pending files. Copy the progress file to `progress.json.bak` on first launch of the new version.

**Batch 1: level model and safe migration.**
- Add a stored `level` (1–5) to `ChildProfile`. Existing profiles get `level = stage derived from their age` (4 to 1, 6 to 2, 8 to 3, 11 to 4), so nobody lands somewhere new. Age stays in the file for backward compatibility but is no longer read for navigation or shown.
- Replace `ageBands` with `levels` on lessons (same values, keeping `ageBands` readable during the transition). Add Level 5 to the picker, the home screen and the world map; no Level 5 content is shown until lessons exist.
- Remove the preview switch from the code; the parent screen keeps one **"Show only original quests"** option only if you want it (see decisions).
- Save format `version 2`. Migration is additive: **no lesson id, star count, badge or avatar is changed.** Add `levelStats` (attempts/correct per level and world) starting from migration; older per-world totals are kept and labelled "before levels".
- Tests: old-save fixtures from every earlier format load; level switching never changes completed lessons, stars or badges.

**Batch 2: curriculum import tooling.** A Dart tool reads the workbooks once and writes reviewed `content/levels/level{3,4,5}_*.json` (same shape as `content/age56`), then a generator produces Dart like `generate_age56.dart`. It validates ids, prerequisites (within a level), native script per language, and refuses lessons that have no teaching text, practice item or answer. Proposed rows with no authored content stay as **"proposed" and are never shown to a child.**

**Batch 3: question bank and exam engine (no screens).** Built from implemented lessons only (details in `EXAMINATION_SYSTEM_DESIGN.md`). Unit tests for selection, evaluation, pass/fail, recovery.

**Batch 4: Examination Centre.** Parents → Examination Centre with the five sections, the child exam screen, local storage, save and resume.

**Batch 5: results, recommendations, certificates.**

**Batches 6–8: write Level 3, then Level 4, then Level 5 content**, 15 lessons per world each, as drafts. English and Number Galaxy content I can write and check myself. Telugu, Hindi and Tamil content is drafted in native script but **marked "educator review required"** and not counted as verified. A level's content is released to children only lesson by lesson, as it is written and passes validation.

**Batch 9: reports and QA** (`LEVEL_1_TO_5_COVERAGE_REPORT.md`, `EXAMINATION_TEST_REPORT.md`, `REMAINING_WORK.md`).

## 6. Prerequisite and unlocking policy (proposed)

- **Within a level**, a lesson stays locked until its prerequisites are finished (as the age 5–6 lessons do now).
- **Across levels**, prerequisites become **recommendations** ("Best after: …"), not locks, because any child may choose any level.
- Level 1–2 legacy lessons keep their current open behaviour.

## 7. Decisions I need from you before Stage 3

1. **Cross-level prerequisites**: advisory (my proposal) or hard locks?
2. **Writing the 225 lessons**: do you want me to draft all of Levels 3–5 (English and Number Galaxy fully, regional lessons as native-script drafts for educator review), or only Level 3 first and stop for your review?
3. **Preview switch**: remove it entirely, or keep a parent option "Show only original quests"?
4. **Exam defaults** (all editable by the parent): Chapter test 10 questions, pass 60%, untimed. Subject exam 20 questions, pass 70%, 20 minutes optional. Final level exam up to 30 questions with at least 5 per chosen world, pass 75% overall **and** at least 50% in each world, unlimited retests. Change any of these?
5. **Certificates**: a PDF needs a PDF library (the app has no third-party packages today). OK to add the `pdf` package, or should a certificate be an image saved to the device?
6. **Parent protection**: keep the arithmetic gate, or add a 4-digit parent PIN for the Examination Centre (stronger; protects results and certificates from a child)?
7. **Commit the 32 pending files now** as the baseline?

## 8. What this report does not claim

No Level 3–5 lesson, exam, question bank or certificate exists yet. Nothing here is educator-verified. Audio is TTS only; no recording exists. Stroke order is unverified for every letter and number.
