# Teaching content gap report

Generated 31 October 2026 from the app's own lesson data (`tool/teaching_audit_test.dart` → `audit/TEACHING_LESSON_AUDIT.csv`, one row per implemented lesson). Classification is by what the code of each lesson actually contains, not by what the workbook lists.

## Result

| Class | Count | What it means here |
|---|---:|---|
| Complete teaching experience | **0** | No lesson has a stepwise demonstration, guided practice with hints, independent practice, a separate mastery check **and** a remedial path. |
| Partial teaching experience | 183 | A "listen and see" first step, then questions with instant feedback. No demonstration sequence, no hint ladder, no separate mastery check, no remediation. |
| Practice-only | 0 | |
| Quiz-only | 173 | A symbol, a Listen button and one multiple-choice question (letters, words, stories, and the older number lessons). |
| Separate letter-tracing path | 4 | `en-trace`, `te-trace`, `hi-trace`, `ta-trace` open the alphabet screen (trace one letter after another). Not lessons in the teaching sense; tracing is Level 1 only. |
| **Total** | **360** | |

By world and level (Partial = has a listen/see step before questions):

| World | L1 | L2 | L3 | L4 |
|---|---|---|---|---|
| English Forest | 26 quiz-only | 30 partial, 1 quiz-only | 1 quiz-only | 1 quiz-only |
| Telugu Kingdom | 10 partial, 51 quiz-only | 26 partial, 1 quiz-only | 1 quiz-only | 1 quiz-only |
| Hindi Valley | 46 quiz-only | 26 partial, 1 quiz-only | 1 quiz-only | 1 quiz-only |
| Tamil Garden | 30 quiz-only | 26 partial, 1 quiz-only | 1 quiz-only | 1 quiz-only |
| Number Galaxy | 11 partial, 2 quiz-only | 54 partial, 2 quiz-only | 2 quiz-only | 2 quiz-only |

Level 5 has no lessons.

## The gaps, in order of importance

1. **No demonstration.** The "teach" step of the 168 Level 2 lessons is one sentence (e.g. "Start at 7. Count on 8 more. 7 + 8 = 15.") followed by one question. Nothing is built up one step at a time.
2. **No guided phase.** A wrong answer greys the option out; there is no hint ladder, no worked reveal, and the child is not led to the answer.
3. **No separate mastery check.** The same single question is the practice, the assessment and the pass mark; one correct tap finishes the lesson. A child can pass by elimination (three options).
4. **No remediation.** Failing leads only to "again" with the same item.
5. **No independent-practice progression.** One question per lesson, so there is no easy-to-hard sequence and no fresh items.
6. **Progress is a single flag.** `completedLessons` and stars record only that a lesson finished. Viewed, steps done, guided done, practice done, mastery score and mastery status are not stored.
7. **Levels 3 and 4 have one lesson per world** (two in Number Galaxy); Level 5 has none. Proposed lessons in the workbook are outlines, not content.
8. **Language lessons have no phonics build-up.** Letters are taught by showing the letter and its picture word once.
9. **Audio is the phone's voice only**; nothing is recorded or checked by a native speaker.

## What is verified and what is not

- The classification above is by code inspection and is reproducible (`flutter test tool/teaching_audit_test.dart`).
- No lesson content has been reviewed by an educator or a native speaker.
- This report describes the **starting position**. The pilot (five lessons) is tracked in `FOUR_AGENT_VERIFICATION_REPORT.md`.
