# Curriculum coverage report

Source: `content/pack_v2` (schema 2.0-draft). Produced by the importer in `lib/src/content/`; regenerate with `flutter test --dart-define=WRITE_REPORTS=true test/batch/reports_test.dart`.

**Read this first.** The pack holds **4532** lesson records, but a record is not a lesson. A lesson is only usable once its text, pictures, audio and native-educator review all exist. This report sorts every record by how far it is from that. **No record is published or verified.**

## 0. What is playable in the app today

Only the first batch is imported, behind the parent switch "Try the new lessons". Everything else in the pack is still data.

| Module | Playable lessons | Pack records used by questions | Writing practice records | Still draft (not imported) | Placeholder, outline or blueprint |
|---|---:|---:|---:|---:|---:|
| telugu | 10 | 19 | 20 | 56 | 1415 |
| tamil | 0 | 0 | 0 | 54 | 543 |
| hindi | 0 | 0 | 0 | 70 | 1001 |
| english | 0 | 0 | 0 | 56 | 154 |
| numbers | 11 | 22 | 22 | 850 | 292 |

- *Playable lesson*: plays end to end offline in the app, every answer key checked against the pack.
- *Writing practice*: the handwriting engine checks the shape and gives feedback, but **no mastery is awarded** until a teacher verifies stroke order (see the asset manifest).
- Writing records are counted separately: in the pack they are still placeholders (no stroke geometry).

### What each playable lesson still lacks

| Lesson | Module | Picture missing for | Stroke template | Stroke order verified | Audio recorded | Native review |
|---|---|---|---|---|---|---|
| telugu-recognise-001 (అ అక్షరం) | telugu | — | no (font outline only) | no | no | no |
| telugu-recognise-002 (ఆ అక్షరం) | telugu | ఆవు | no (font outline only) | no | no | no |
| telugu-recognise-003 (ఇ అక్షరం) | telugu | — | no (font outline only) | no | no | no |
| telugu-recognise-004 (ఈ అక్షరం) | telugu | ఈగ | no (font outline only) | no | no | no |
| telugu-recognise-005 (ఉ అక్షరం) | telugu | ఉడుత | no (font outline only) | no | no | no |
| telugu-recognise-006 (ఊ అక్షరం) | telugu | ఊయల | no (font outline only) | no | no | no |
| telugu-recognise-008 (ఎ అక్షరం) | telugu | — | no (font outline only) | no | no | no |
| telugu-recognise-009 (ఏ అక్షరం) | telugu | — | no (font outline only) | no | no | no |
| telugu-recognise-010 (ఐ అక్షరం) | telugu | ఐదు | no (font outline only) | no | no | no |
| telugu-recognise-011 (ఒ అక్షరం) | telugu | ఒంటె | no (font outline only) | no | no | no |
| numbers-count-000 (Number 0) | numbers | — | yes | no | no | no |
| numbers-count-001 (Number 1) | numbers | — | yes | no | no | no |
| numbers-count-002 (Number 2) | numbers | — | yes | no | no | no |
| numbers-count-003 (Number 3) | numbers | — | yes | no | no | no |
| numbers-count-004 (Number 4) | numbers | — | yes | no | no | no |
| numbers-count-005 (Number 5) | numbers | — | yes | no | no | no |
| numbers-count-006 (Number 6) | numbers | — | yes | no | no | no |
| numbers-count-007 (Number 7) | numbers | — | yes | no | no | no |
| numbers-count-008 (Number 8) | numbers | — | yes | no | no | no |
| numbers-count-009 (Number 9) | numbers | — | yes | no | no | no |
| numbers-count-010 (Number 10) | numbers | — | yes | no | no | no |

## 1. Records by readiness

| Module | Records | handwriting placeholder | outline only | blueprint | needs images | text-complete draft |
|---|---:|---:|---:|---:|---:|---:|
| telugu | 1490 | 1363 | 18 | 34 | 22 | 53 |
| tamil | 597 | 494 | 18 | 31 | 22 | 32 |
| hindi | 1071 | 951 | 18 | 32 | 22 | 48 |
| english | 210 | 104 | 14 | 36 | 28 | 28 |
| numbers | 1164 | 272 | 20 | 0 | 0 | 872 |
| **All** | **4532** | **3184** | **88** | **133** | **94** | **1033** |

- *handwriting placeholder*: a letter or number to be written, with **no stroke geometry**; cannot be scored or taught yet.
- *outline only*: a topic heading for authors, not a lesson.
- *blueprint*: key content is missing (the combined letter, the letters to arrange, practice items).
- *needs images*: text is complete, the picture does not exist.
- *text-complete draft*: nothing missing in the text; still needs audio and native review.

## 2. Teachable content by age band

Text-complete drafts plus those waiting for images (placeholders, outlines and blueprints excluded).

| Module | 3–4 | 5–6 | 7–9 | 10–12 | Total |
|---|---:|---:|---:|---:|---:|
| telugu | 71 | 0 | 2 | 2 | 75 |
| tamil | 50 | 0 | 2 | 2 | 54 |
| hindi | 66 | 0 | 2 | 2 | 70 |
| english | 52 | 0 | 2 | 2 | 56 |
| numbers | 22 | 482 | 368 | 0 | 872 |

## 3. What kinds of lesson exist (per module)

**telugu** — 1490 records

| Type | Records | Of which usable as drafts |
|---|---:|---:|
| independent_writing | 699 | 0 |
| guided_tracing | 664 | 0 |
| recognition | 51 | 51 |
| picture_word_match | 20 | 20 |
| word_ordering | 20 | 0 |
| combine_character | 14 | 0 |
| grammar_practice | 8 | 0 |
| guided_writing | 6 | 0 |
| guided_practice | 4 | 0 |
| read_and_answer | 2 | 2 |
| story_sequencing | 2 | 2 |

**tamil** — 597 records

| Type | Records | Of which usable as drafts |
|---|---:|---:|
| guided_tracing | 247 | 0 |
| independent_writing | 247 | 0 |
| recognition | 30 | 30 |
| picture_word_match | 20 | 20 |
| word_ordering | 20 | 0 |
| combine_character | 11 | 0 |
| grammar_practice | 8 | 0 |
| guided_writing | 6 | 0 |
| guided_practice | 4 | 0 |
| read_and_answer | 2 | 2 |
| story_sequencing | 2 | 2 |

**hindi** — 1071 records

| Type | Records | Of which usable as drafts |
|---|---:|---:|
| independent_writing | 492 | 0 |
| guided_tracing | 459 | 0 |
| recognition | 46 | 46 |
| picture_word_match | 20 | 20 |
| word_ordering | 20 | 0 |
| combine_character | 12 | 0 |
| grammar_practice | 8 | 0 |
| guided_writing | 6 | 0 |
| guided_practice | 4 | 0 |
| read_and_answer | 2 | 2 |
| story_sequencing | 2 | 2 |

**english** — 210 records

| Type | Records | Of which usable as drafts |
|---|---:|---:|
| guided_tracing | 52 | 0 |
| independent_writing | 52 | 0 |
| recognition | 26 | 26 |
| picture_word_match | 26 | 26 |
| word_ordering | 26 | 0 |
| phonics_blending | 10 | 0 |
| grammar_practice | 8 | 0 |
| guided_writing | 6 | 0 |
| read_and_answer | 2 | 2 |
| story_sequencing | 2 | 2 |

**numbers** — 1164 records

| Type | Records | Of which usable as drafts |
|---|---:|---:|
| addition | 231 | 231 |
| subtraction | 231 | 231 |
| multiplication | 144 | 144 |
| division | 144 | 144 |
| guided_tracing | 136 | 0 |
| independent_writing | 136 | 0 |
| numeral_recognition | 101 | 101 |
| count_objects | 21 | 21 |
| concept_unit | 20 | 0 |

## 4. Chapters

**telugu**

| Chapter | handwriting placeholder | outline only | blueprint | needs images | text-complete draft |
|---|---:|---:|---:|---:|---:|
| letters | 0 | 0 | 0 | 0 | 51 |
| handwriting | 1363 | 0 | 0 | 0 | 0 |
| vocabulary | 0 | 0 | 0 | 20 | 0 |
| word_building | 0 | 0 | 20 | 0 | 0 |
| stories | 0 | 0 | 0 | 2 | 0 |
| comprehension | 0 | 0 | 0 | 0 | 2 |
| vowel_combinations | 0 | 0 | 14 | 0 | 0 |
| advanced_script | 0 | 4 | 0 | 0 | 0 |
| grammar | 0 | 8 | 0 | 0 | 0 |
| writing | 0 | 6 | 0 | 0 | 0 |

> Declared but **empty** chapters: listening, phonics, sentence_reading, review.

**tamil**

| Chapter | handwriting placeholder | outline only | blueprint | needs images | text-complete draft |
|---|---:|---:|---:|---:|---:|
| letters | 0 | 0 | 0 | 0 | 30 |
| handwriting | 494 | 0 | 0 | 0 | 0 |
| vocabulary | 0 | 0 | 0 | 20 | 0 |
| word_building | 0 | 0 | 20 | 0 | 0 |
| stories | 0 | 0 | 0 | 2 | 0 |
| comprehension | 0 | 0 | 0 | 0 | 2 |
| vowel_combinations | 0 | 0 | 11 | 0 | 0 |
| advanced_script | 0 | 4 | 0 | 0 | 0 |
| grammar | 0 | 8 | 0 | 0 | 0 |
| writing | 0 | 6 | 0 | 0 | 0 |

> Declared but **empty** chapters: listening, phonics, sentence_reading, review.

**hindi**

| Chapter | handwriting placeholder | outline only | blueprint | needs images | text-complete draft |
|---|---:|---:|---:|---:|---:|
| letters | 0 | 0 | 0 | 0 | 46 |
| handwriting | 951 | 0 | 0 | 0 | 0 |
| vocabulary | 0 | 0 | 0 | 20 | 0 |
| word_building | 0 | 0 | 20 | 0 | 0 |
| stories | 0 | 0 | 0 | 2 | 0 |
| comprehension | 0 | 0 | 0 | 0 | 2 |
| vowel_combinations | 0 | 0 | 12 | 0 | 0 |
| advanced_script | 0 | 4 | 0 | 0 | 0 |
| grammar | 0 | 8 | 0 | 0 | 0 |
| writing | 0 | 6 | 0 | 0 | 0 |

> Declared but **empty** chapters: listening, phonics, sentence_reading, review.

**english**

| Chapter | handwriting placeholder | outline only | blueprint | needs images | text-complete draft |
|---|---:|---:|---:|---:|---:|
| letters | 0 | 0 | 0 | 0 | 26 |
| handwriting | 104 | 0 | 0 | 0 | 0 |
| vocabulary | 0 | 0 | 0 | 26 | 0 |
| word_building | 0 | 0 | 26 | 0 | 0 |
| stories | 0 | 0 | 0 | 2 | 0 |
| comprehension | 0 | 0 | 0 | 0 | 2 |
| phonics | 0 | 0 | 10 | 0 | 0 |
| grammar | 0 | 8 | 0 | 0 | 0 |
| writing | 0 | 6 | 0 | 0 | 0 |

> Declared but **empty** chapters: listening, vowel_combinations, advanced_script, sentence_reading, review.

**numbers**

| Chapter | handwriting placeholder | outline only | blueprint | needs images | text-complete draft |
|---|---:|---:|---:|---:|---:|
| number_sense | 0 | 0 | 0 | 0 | 101 |
| counting | 0 | 0 | 0 | 0 | 21 |
| addition | 0 | 0 | 0 | 0 | 231 |
| subtraction | 0 | 0 | 0 | 0 | 231 |
| multiplication | 0 | 0 | 0 | 0 | 144 |
| division | 0 | 0 | 0 | 0 | 144 |
| math_topics | 0 | 20 | 0 | 0 | 0 |
| number_writing | 272 | 0 | 0 | 0 | 0 |

> Declared but **empty** chapters: comparison, place_value, fractions, decimals, measurement, time, money, geometry, data, word_problems, review.

## 5. Missing media

| Module | Images needed | Images present | Audio recorded | Audio native-verified | Verified stroke paths |
|---|---:|---:|---:|---:|---:|
| telugu | 22 | 0 | 0 | 0 | 0 |
| tamil | 22 | 0 | 0 | 0 | 0 |
| hindi | 22 | 0 | 0 | 0 | 0 |
| english | 28 | 0 | 0 | 0 | 0 |
| numbers | 0 | 0 | 0 | 0 | 0 |

## 6. Instruction language

| Module | Records | Instruction in the module language |
|---|---:|---:|
| telugu | 1490 | 0 |
| tamil | 597 | 0 |
| hindi | 1071 | 0 |
| english | 210 | n/a (English) |
| numbers | 1164 | n/a (English) |

## 7. Prerequisites

| Module | Records with a prerequisite | Prerequisite links | Links that are not lesson ids |
|---|---:|---:|---:|
| telugu | 22 of 1490 | 22 | 0 |
| tamil | 22 of 597 | 22 | 0 |
| hindi | 22 of 1071 | 22 | 0 |
| english | 28 of 210 | 28 | 0 |
| numbers | 0 of 1164 | 0 | 0 |

## 8. Answer options

| Module | Multiple-choice records | Correct answer listed first | `shuffle_options` true |
|---|---:|---:|---:|
| telugu | 73 | 72 | 73 |
| tamil | 52 | 51 | 52 |
| hindi | 68 | 66 | 68 |
| english | 54 | 52 | 54 |
| numbers | 872 | 872 | 872 |

The importer requires `shuffle_options`; the app must actually shuffle at play time (it does for the current 20 quests).

## 9. Validation results

| Rule | Meaning | Severity | Count |
|---|---|---|---:|
| I201 | Native-educator review is required before publishing | info | 4532 |
| W102 | Picture or story image is missing | warning | 94 |
| W103 | No recorded audio, or audio not verified by a native speaker | warning | 4532 |
| W104 | Child-facing instruction is not in the module language | warning | 3158 |
| W105 | Outline only: an authoring backlog item, not a lesson | warning | 88 |
| W106 | Blueprint: needed content (e.g. the combined letter) is missing | warning | 47 |
| W107 | Handwriting target has no verified stroke geometry | warning | 3184 |
| W108 | Nothing to arrange: word ordering has no pieces | warning | 86 |

**No structural errors.**

## 10. What this report does not tell you

- Whether any Telugu, Tamil or Hindi word, story, answer or script convention is **correct**. Structure and Unicode script are checked; meaning and pedagogy need native educators.
- Whether audio or pronunciation is right: none exists.
- Whether the age bands are right: they are the pack author's indicative labels.
