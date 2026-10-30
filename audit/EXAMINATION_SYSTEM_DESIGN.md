# Examination Centre: design (Stage 2, not yet built)

Status: **design for approval.** Nothing in this document is implemented.

## 1. Where it lives and who can reach it

`Home → Parents (existing gate) → Examination Centre`, five sections:

1. **Conduct Exam**: pick child, level, type, subjects, settings, start.
2. **Results and Performance**: latest result, subject and topic breakdown, wrong answers with explanations, revision lessons, readiness for the next level.
3. **Examination History**: every attempt, newest first; per child.
4. **Certificates**: list, view, export.
5. **Question Bank and Exam Settings**: coverage per level and world, defaults, retest policy.

The child exam screen is a separate route opened from "Conduct Exam" **after** the parent presses Start. A child using the normal app has no route to creating an exam, changing settings, or seeing detailed results. Parent protection: the existing arithmetic gate, plus an optional 4-digit PIN (decision 6 in the integration report). The child exam shows only a pass/try-again message and stars-free encouragement; detailed marks are parent-only.

## 2. Domain model (all offline, JSON)

```
ExamConfig     id, childId, level 1-5, type {chapter, subject, finalLevel},
               worlds[], lessonIds[] (chapter), questionCount,
               difficultyMix {easy, medium, hard}, passPercent,
               perWorldMinPercent?, timeLimitSeconds? (null = untimed),
               retestPolicy {unlimited | max N | wait hours}, createdAt
Question       id (stable), lessonId, level, world, topic, objective, type,
               prompt (text) , promptAudio? , options[], correctAnswer,
               difficulty {1,2,3}, marks, explanation, media[],
               verification {machine_checked, educator_pending, educator_verified,
                             tts_unverified}
ExamAttempt    id, configId (snapshot embedded), childId, startedAt, finishedAt?,
               status {inProgress, submitted, abandoned}, seed,
               questions[]  (full frozen copies, in the order shown),
               answers{questionId: answer, answeredAt}, retestNumber
ExamResult     attemptId, totalMarks, obtained, percent, passed,
               bySubject{}, byTopic{}, byObjective{}, timeTaken,
               wrong[{questionId, given, correct, explanation, lessonId}],
               recommendations[lessonId + reason], readiness
Certificate    id (AKS-L{level}-{yyyymmdd}-{4 chars}), childId, displayName,
               level, issuedAt, attemptId, issuedCount (reissue marker)
```

Attempts store **copies** of the questions shown, so a result stays reproducible even if the curriculum changes later.

## 3. Question bank (built, not authored)

The bank is **derived from implemented lessons only**; nothing is invented and no translation is added.

| Source in the app | Question produced | Type |
|---|---|---|
| Quiz lessons: options + answer (letters, words, stories) | the lesson's own question | multiple choice / picture identification when options carry pictures / reading comprehension for story lessons |
| `BatchStep` pick-letter / pick-word | recognise the letter or picture word | picture identification, multiple choice |
| `BatchStep` pick-quantity / count / compare | quantity, count, bigger/smaller | number recognition, arithmetic |
| Number lessons with operands (add/subtract/multiply/divide) | the sum, **answer computed by code** | arithmetic |
| English word builder (`C _ T`) | missing letter | fill in the blank |
| Listening: the lesson's speech line (TTS) | "listen, then pick" | listening and recognition, flagged `tts_unverified` |

Not offered until lessons contain verified items for them: **matching, sequencing, pattern recognition, word formation.** Handwriting and speech tasks appear only as **parent-marked** items (the parent marks correct or incorrect at the end); they are never auto-correct.

Today's size (from the app, see `EXAMINATION_QUESTION_BANK_COVERAGE.csv`): Level 1 about 207 items, Level 2 about 168, Level 3 6, Level 4 6, Level 5 0. The bank grows only as lessons are written.

**Verification status**: every machine-derived question is `machine_checked` (the answer is one of the options, options are unique, arithmetic recomputed, required pictures exist). Telugu, Hindi and Tamil questions are `educator_pending`. Nothing is `educator_verified` until a person records that.

**Distractors** come from the lesson's own options. Where a lesson has only 2 or 3 options, the exam never invents new wrong answers.

## 4. Building an exam (selection)

1. Resolve scope: chapter = chosen lesson ids; subject = one world at one level; final = chosen worlds at one level.
2. Gather candidate questions in scope. Drop any whose pictures are missing.
3. **Refuse honestly** if fewer candidates exist than requested: show "this level has N questions for this subject" and offer N.
4. Balance by objective: round-robin across objectives (lesson topics), so one lesson cannot fill the exam.
5. Mix difficulty to the configured proportions where available.
6. For a final exam, guarantee at least the configured minimum per world.
7. No question twice in an attempt. A retest prefers questions not asked in the last attempt.
8. Shuffle question order and, within each question, option order (seeded; the seed is stored).
9. Freeze the questions into the `ExamAttempt`.

## 5. Child experience

One question per screen, large touch targets, picture or text prompt, optional Listen button, progress "3 of 12", optional calm timer (a number, no flashing). Answers are selectable and changeable until submission; **no right/wrong shown during the exam**. A review page lists answered/unanswered; a confirmation dialog precedes the final Submit. Progress is saved after every answer, so a closed app resumes where it stopped (parent chooses Resume or Discard from the Examination Centre). The timer stops the attempt and submits what has been answered.

Regular learning (instant right/wrong, stars) and exams are separate routes and stores. An exam never awards stars or changes lesson completion.

## 6. Evaluation and results

Objective questions are marked by comparing the stored answer. Parent-marked questions stay "awaiting parent" and are excluded from the percentage until marked (the result says so). Pass = percentage ≥ pass mark **and**, for a final exam, every chosen world ≥ the per-world minimum. Results store marks, percent, pass/fail, subject/topic/objective breakdown, time, retest number.

**Recommendations** come from the missed questions: each wrong question names its lesson and learning objective, grouped, with the lesson to revisit ("Revise: *Place value to 1000*: missed 3 of 4"). No generic advice.

**Readiness for the next level**: "ready" only when the child has passed a final exam at the current level; otherwise the report lists the worlds and objectives still below the mark.

## 7. Certificates

Offered when a final-level exam is passed. Content: child display name, level, date, id. Stored on the profile; a second pass for the same level does **not** create a second certificate (the parent may deliberately reissue, which increments a counter). Parent can view and export (format depends on decision 5). The certificate says "completed Level N", never claims external accreditation.

## 8. Persistence, offline use and integrity

- Separate file `exams.json` next to `progress.json`, written with the same temp-file-then-rename pattern, with `version` and a rolling `.bak`. Exam data is not part of progress, so a failed exam write can never damage learning progress and the reverse.
- Submitting is idempotent (an attempt id can be finalised once). A crash between answering and submitting leaves an `inProgress` attempt that can be resumed.
- No network is used anywhere.
- Each stored result carries a checksum of its answers and marks, so accidental corruption or hand-editing is **detected** and flagged "result could not be verified". This is not strong security: on a rooted phone a determined person could edit the files.
- Access control is UI-level (parent gate/PIN). The honest limit: the data sits in the app's private folder, which a child cannot browse on an unrooted device.

## 9. Tests planned

Workbook parsing/validation; id uniqueness; Level 1–5 availability; prerequisite integrity; profile migration from every earlier save format; level switching; exam creation (all three types); selection (balance, no repeats, refusal when too few); answer evaluation; pass/fail including per-world minimum; interrupted-exam recovery; retests; history; certificate eligibility and duplicates; parent-only access (no route from the child side); offline operation.

## 10. Known limits to accept up front

- Levels 3–5 cannot be examined until their lessons exist.
- The question bank can only be as good as the lessons; one question per lesson means a chapter test cannot repeat fewer than the number of lessons it covers.
- Regional-language questions are unverified until an educator confirms them.
- Listening questions use the phone's voice, whose pronunciation nobody has checked.
