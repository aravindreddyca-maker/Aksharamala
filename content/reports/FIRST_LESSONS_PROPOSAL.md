# Proposal: first 10 Telugu lessons and first 10 Number Galaxy lessons

Status: **proposal only. Nothing here is in the app.** No production curriculum, screen or save file has been changed. Every record ID below is a real ID in `content/pack_v2` (a test checks this, so the list cannot drift).

## Principle

A "lesson" for a 3–4 year old is **one idea, about 3 minutes, in this order**: see it → hear it → pick it → (word) match the picture. So each lesson below bundles records that already exist in the pack, instead of inventing new content.

---

## A. Telugu: first 10 lessons (age 3–4, vowels with a picture word)

Each lesson teaches one vowel and one common word that starts with it.

| # | Letter | Word (meaning) | Records used | Needs |
|---|---|---|---|---|
| T1 | అ | అమ్మ (mother) | `telugu-recognise-001`, `telugu-vocab-001` | 1 picture |
| T2 | ఆ | ఆవు (cow) | `telugu-recognise-002`, `telugu-vocab-002` | 1 picture |
| T3 | ఇ | ఇల్లు (house) | `telugu-recognise-003`, `telugu-vocab-003` | 1 picture |
| T4 | ఈ | ఈగ (fly) | `telugu-recognise-004`, `telugu-vocab-004` | 1 picture |
| T5 | ఉ | ఉడుత (squirrel) | `telugu-recognise-005`, `telugu-vocab-005` | 1 picture |
| T6 | ఊ | ఊయల (swing) | `telugu-recognise-006`, `telugu-vocab-006` | 1 picture |
| T7 | ఎ | (no word in pack) | `telugu-recognise-008` | letter only |
| T8 | ఏ | ఏనుగు (elephant) | `telugu-recognise-009`, `telugu-vocab-007` | 1 picture |
| T9 | ఐ | ఐదు (five) | `telugu-recognise-010`, `telugu-vocab-008` | 1 picture |
| T10 | ఒ | ఒంటె (camel) | `telugu-recognise-011`, `telugu-vocab-009` | 1 picture |

Choices to confirm:

- **ఋ (`telugu-recognise-007`) is skipped for now.** It is rare and has no picture word in the pack. Suggest teaching it later, among the last vowels.
- **T7 has no picture word.** The pack has no word for ఎ; an educator should supply one (e.g. a common word) before it is a full lesson.
- **Nine pictures are needed** (`telugu/vocab/001`–`009`). None exist in the app today. Until they do, these are "needs images", not finished.
- **Handwriting is deliberately not included.** The pack has no stroke geometry, so tracing cannot be scored. No tracing lesson should appear until stroke order is drawn and checked by a Telugu teacher.
- **Audio.** Today the app can only speak the lesson's one `speech` line with the phone's Telugu voice. The pack has no recordings. A native speaker should confirm that the phone voice says each letter and word correctly, or record them.
- **Answer position.** In the pack the correct answer is the first option in these records. The app already shuffles at play time, so that is safe, and the importer warns if it ever stops (W120).

## B. Number Galaxy: first 10 lessons (age 3–4, numbers 1–10)

Each lesson pairs counting objects with recognising the numeral.

| # | Number | Records used | Needs |
|---|---|---|---|
| N1 | 1 | `numbers-count-001`, `numbers-recognise-001` | nothing external |
| N2 | 2 | `numbers-count-002`, `numbers-recognise-002` | nothing external |
| N3 | 3 | `numbers-count-003`, `numbers-recognise-003` | nothing external |
| N4 | 4 | `numbers-count-004`, `numbers-recognise-004` | nothing external |
| N5 | 5 | `numbers-count-005`, `numbers-recognise-005` | nothing external |
| N6 | 6 | `numbers-count-006`, `numbers-recognise-006` | nothing external |
| N7 | 7 | `numbers-count-007`, `numbers-recognise-007` | nothing external |
| N8 | 8 | `numbers-count-008`, `numbers-recognise-008` | nothing external |
| N9 | 9 | `numbers-count-009`, `numbers-recognise-009` | nothing external |
| N10 | 10 | `numbers-count-010`, `numbers-recognise-010` | nothing external |

Choices to confirm:

- **Zero comes after ten** (`numbers-count-000`, `numbers-recognise-000`). It is a harder idea for a 3–4 year old than 1–10.
- **No new art is needed.** The app can draw the objects to be counted from the quantity in the record, using its existing star/object art.
- **A weakness in the pack's wrong answers.** Every distractor is simply the next two bigger numbers (for 4: 4, 5, 6). A child can learn "pick the smallest" without counting. Suggest the app builds distractors on both sides of the number (3, 4, 5) at play time. That is an app decision, not a content edit.
- **Language.** Instructions in this module are English only, which matches your decision that maths stays English.

---

## C. If you approve

1. A small adapter turns these records into the existing lesson screen format, behind a switch that is off by default, so today's 20 quests keep working.
2. **Progress safety.** Today's saves use IDs like `te-a`. New records use IDs like `telugu-recognise-001`. I would add a one-way mapping table (`te-a` → `telugu-recognise-001`, …) so stars and badges a child has already earned are kept. No save file is rewritten until you approve.
3. Pictures for T1–T10 are commissioned or generated, then dropped in and checked by the importer.
4. A Telugu-speaking educator reviews the 10 letters, 9 words and the phone voice before any child sees them.

## D. What I need from you

- Approve, change, or reorder the two lists.
- Decide whether I may start step C.1 and C.2 (hidden behind a switch, no change to what children see).
- Say who will review the Telugu.
