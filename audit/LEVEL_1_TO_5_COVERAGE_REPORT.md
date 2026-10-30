# Level 1 to 5 coverage report (baseline, before integration)

Generated 31 October 2026 from `Aksharamala_Consolidated_Curriculum_Levels_1_to_5.xlsx` and the app's own lesson data. This is the **starting position**; it will be regenerated after each Stage 3 batch.

## By level and world

Columns: "In workbook (existing)" are rows that already exist in the app; "Proposed" are new rows with no content yet; "Implemented" is what a child can play today; "Art complete/missing" counts implemented lessons with/without every required picture; "Audio recorded" is recordings (the app uses the phone's voice only); "Question items" is how many exam questions today's lessons can supply; "Needs educator review" counts regional-language lessons (implemented + proposed) and every proposed lesson.

| Level | World | In workbook (existing) | Proposed | Implemented in app | Art complete | Art missing | Audio recorded | Question items | Needs educator review |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | English Forest | 27 | 0 | 27 | 27 | 0 | 0 | 26 | 0 |
| 1 | Telugu Kingdom | 62 | 0 | 62 | 62 | 0 | 0 | 70 | 62 |
| 1 | Hindi Valley | 47 | 0 | 47 | 47 | 0 | 0 | 46 | 47 |
| 1 | Tamil Garden | 31 | 0 | 31 | 31 | 0 | 0 | 30 | 31 |
| 1 | Number Galaxy | 13 | 0 | 13 | 13 | 0 | 0 | 35 | 0 |
| 2 | English Forest | 31 | 0 | 31 | 31 | 0 | 0 | 31 | 0 |
| 2 | Telugu Kingdom | 27 | 0 | 27 | 18 | 9 | 0 | 27 | 27 |
| 2 | Hindi Valley | 27 | 0 | 27 | 25 | 2 | 0 | 27 | 27 |
| 2 | Tamil Garden | 27 | 0 | 27 | 26 | 1 | 0 | 27 | 27 |
| 2 | Number Galaxy | 56 | 0 | 56 | 56 | 0 | 0 | 56 | 0 |
| 3 | English Forest | 1 | 15 | 1 | 1 | 0 | 0 | 1 | 15 |
| 3 | Telugu Kingdom | 1 | 15 | 1 | 1 | 0 | 0 | 1 | 16 |
| 3 | Hindi Valley | 1 | 15 | 1 | 1 | 0 | 0 | 1 | 16 |
| 3 | Tamil Garden | 1 | 15 | 1 | 1 | 0 | 0 | 1 | 16 |
| 3 | Number Galaxy | 2 | 15 | 2 | 2 | 0 | 0 | 2 | 15 |
| 4 | English Forest | 1 | 15 | 1 | 1 | 0 | 0 | 1 | 15 |
| 4 | Telugu Kingdom | 1 | 15 | 1 | 1 | 0 | 0 | 1 | 16 |
| 4 | Hindi Valley | 1 | 15 | 1 | 1 | 0 | 0 | 1 | 16 |
| 4 | Tamil Garden | 1 | 15 | 1 | 1 | 0 | 0 | 1 | 16 |
| 4 | Number Galaxy | 2 | 15 | 2 | 2 | 0 | 0 | 2 | 15 |
| 5 | English Forest | 0 | 15 | 0 | 0 | 0 | 0 | 0 | 15 |
| 5 | Telugu Kingdom | 0 | 15 | 0 | 0 | 0 | 0 | 0 | 15 |
| 5 | Hindi Valley | 0 | 15 | 0 | 0 | 0 | 0 | 0 | 15 |
| 5 | Tamil Garden | 0 | 15 | 0 | 0 | 0 | 0 | 0 | 15 |
| 5 | Number Galaxy | 0 | 15 | 0 | 0 | 0 | 0 | 0 | 15 |

## By level

| Level | Implemented | Proposed (no content yet) | Exam question items today |
|---|---:|---:|---:|
| 1 | 180 | 0 | 207 |
| 2 | 168 | 0 | 168 |
| 3 | 6 | 75 | 6 |
| 4 | 6 | 75 | 6 |
| 5 | 0 | 75 | 0 |
| **All** | **360** | **225** | **387** |

## Reading the table honestly

- "Art complete" means every picture the lesson asks for exists. It does **not** mean the pictures were approved; the artwork ledger (`AGE_5_6_ARTWORK_REVIEW_LEDGER.csv`) records that separately. Level 2 has 12 lessons still missing a picture (9 Telugu, 2 Hindi, 1 Tamil).
- **Audio recorded is 0 everywhere.** The Listen button uses the device's voice. No pronunciation has been checked by a native speaker.
- **Verified assessment questions is 0 everywhere**: no question has been reviewed by an educator. English and Number Galaxy questions are checked by code (the answer is among the options; sums recomputed); regional-language questions are not verified at all.
- Levels 3 and 4 have one lesson per language (two in Number Galaxy). The 75 proposals per level are outlines only (see the integration report).
- Level 1's 180 lessons exclude the four "All letters" cards (26 English, 51 Telugu, 46 Hindi, 30 Tamil letters traced one by one); those are a separate letter path, not lessons in the workbook sense.

## Outstanding educational review

Every Telugu, Hindi and Tamil lesson (implemented and proposed), every proposed lesson at any level, all sentences written for the app in those languages, the phone's reading of every line, and the stroke order of every English capital and number 0–10.
