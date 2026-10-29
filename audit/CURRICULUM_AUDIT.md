# Aksharamala — Curriculum Quality Audit

Audit date: 29 Oct 2026. Repository: `E:\Aksharamala`, branch `main`, commit `d222c97`.
Scope: audit only. **No curriculum content was changed.** The only additions are `test/audit/curriculum_audit_test.dart` (new tests) and this report.
*Update, same day, on request:* one layout defect (AUD-031, "Check Answer" off-screen) was fixed in `lib/src/screens/lesson_screen.dart` with 31 new tests in `test/check_button_layout_test.dart`. Nothing else in the app was touched.

## How to read this report

Every finding carries a **Verification Status**:

| Status | Meaning |
|---|---|
| **Confirmed** | Proven by the repository text, a test run, or a measurement. Evidence is cited. |
| **Observed** | Seen by Claude on screen or in an image. A reviewer should re-confirm. |
| **Suspected** | A language or teaching judgement by Claude. **Needs a qualified native-language educator.** Not to be treated as an error until confirmed. |
| **Recommendation** | A design suggestion, not a defect. |

**What this audit cannot establish**
- **Pronunciation.** There are no recorded audio files. Speech is the phone's text-to-speech. No pronunciation was heard by anyone during this audit (the emulator has audio switched off). Real-device listening tests with native listeners are required.
- **Language correctness.** I checked every string and read it as a language specialist would, but AI-reviewed language content must not be signed off without a qualified native educator for Telugu, Tamil and Hindi, and an early-years literacy specialist for English.
- **Image appropriateness.** Picture-to-word checks are my visual review of the bundled images; they need a human reviewer.

---

# Phase 1 — Discovery

## 1.1 Where the content lives

| Content | Where | Form |
|---|---|---|
| All worlds, lessons, quests, vocabulary, quiz questions, answers, story pages, speech lines | `lib/src/curriculum.dart` (383 lines) | **Hardcoded Dart constants** |
| Number words 1–10 in four languages | `lib/src/curriculum.dart:371` (`numberNames`) | Hardcoded; **never used by the app** |
| Quest-card picture and label per quest | `lib/src/quest_art.dart` | Hardcoded maps |
| Result pop-up sentences (Tamil/Telugu/Hindi/English) | `lib/src/result_text.dart` | Hardcoded; written for the app, not from a curriculum |
| Age bands and their "focus" text | `lib/src/models.dart:3–33` | Hardcoded |
| Images | `assets/images/*` (62 files) | Bundled PNG/WebP |
| Audio | **None.** 0 audio files in `assets/` or `android/` | — |
| Speech | `lib/src/services/speech_service.dart`, `android/.../MainActivity.kt:33–49` | Android `TextToSpeech`, text from each lesson's `speech` field |
| JSON content, remote content, generated content | **None found.** | — |

Everything is offline and static. There is no dynamic or generated content.

## 1.2 Inventory per language

From `lib/src/curriculum.dart` (counts printed by the audit test, `INV|` lines):

| World | Quests | Kinds | Quizzes | Answer options | Option pictures | Story covers | Story pages |
|---|---|---|---|---|---|---|---|
| English Forest | 4 | letter, word, trace, story | 3 | 9 | 6 | 1 | 3 |
| Telugu Kingdom | 4 | letter, word, trace, story | 3 | 9 | 6 | 1 | 3 |
| Hindi Valley | 4 | letter, word, trace, story | 3 | 9 | 6 | 1 | 3 |
| Tamil Garden | 4 | letter, word, trace, story | 3 | 9 | 6 | 1 | 3 |
| Number Galaxy | 4 | 2 numbers, 2 game | 4 | 12 | 0 | 0 | 0 |
| **Total** | **20** | | | | | | |

**What is actually taught, per language** (read from `curriculum.dart`):

| Language | Letters taught | Words taught (as answer options) | Story |
|---|---|---|---|
| English | **A** (lines 15–31, 44–55) | Apple, Ball, Cat; CAT (spelling) | "Mina and the Mango" (3 sentences) |
| Telugu | **అ** (lines 90–106, 124–135) | అమ్మ, ఇల్లు, ఏనుగు, కలం, బడి, పండు | "చిన్ని చిలుక" (3 sentences) |
| Hindi | **अ** (lines 165–181, 194–205); letters म, न, र appear only as options | अनार, कमल, घर (कमल is the missing-letter target) | "नीला पतंग" (3 sentences) |
| Tamil | **அ** (lines 240–256, 274–285) | அம்மா, இலை, ஊஞ்சல், மலர், வீடு, கல் | "வண்ணத்துப்பூச்சி" (3 sentences) |
| Numbers | counting 3; 2+3; 7−2; names for 5 (vs 3, 7) | — | none |

Each language world teaches **exactly one letter**.

## 1.3 Missing, duplicated, unreachable and placeholder content

| Finding | Evidence | Issue |
|---|---|---|
| One letter per language, no vowel/consonant families, no matras, gunintalu, ottulu, uyirmei, barakhadi | `curriculum.dart` (all lessons) | AUD-001 |
| `numberNames` (1–10 in 4 languages) is defined but **never read** | `curriculum.dart:371`; no other file references it | AUD-017 |
| `LearningWorld.emoji` (🌳 🏰 ⛰️ 🌺 🚀) is defined but **never read** | `curriculum.dart:9,84,159,234,309`; `models.dart:119` | AUD-017 |
| Story quests carry emoji as their `symbol` (📖 🪁 🦋) | `curriculum.dart:61,211,291` — only a fallback now that covers exist | AUD-017 |
| Four images shipped but never used: `rewards/crown.png`, `gem.png`, `gift.png`, `medal.png` | Strict test "no unused image files" | AUD-018 |
| Three near-identical house pictures for Telugu, Hindi and Tamil | `quiz/te_house.webp`, `hi_house.webp`, `ta_house.webp` | AUD-018 |
| **Unreachable quests: none.** All 20 quests open from the start, in any order | Test "every quest opens from its world map" | — |
| Placeholder content: none that the child sees, apart from the emoji fallback above | — | — |

## 1.4 Do all ages 3–12 have meaningful activities?

**No — every child gets the same 20 quests.** The age bands (3–4, 5–6, 7–9, 10–12) only change a label:

- `models.dart:28–33` maps age to a stage; the stage is used **only** for text: `app_controller.dart:71–79` (home banner) and the profile/parent screens.
- `recommendedLesson` (`app_controller.dart:58–67`) uses progress only, never age.
- The `Lesson` class (`models.dart:78–104`) has no age, level or difficulty field.

The labels promise things the app does not contain: "Read • Write • Grammar • Arithmetic" (7–9) and "Comprehension • Writing • Advanced maths" (10–12). There is no grammar quest, no writing beyond tracing one letter, and no maths beyond a single sum and difference. See AUD-002.

---

# Phase 2 — Linguistic verification

## 2.1 What was checked automatically (all passed)

Run with `flutter test test/audit`:

- Every lesson text is in its own script, with **no stray characters** from another script (Telugu, Tamil, Devanagari, Latin).
- **No** zero-width joiners, byte-order marks, or orphaned vowel signs at the start of a word.
- Telugu words never end in a bare virama.
- `locale` matches the language of each world.
- Every quiz has 2+ options, **no duplicate options**, and the answer appears exactly once.
- Each letter question has exactly **one** option that starts with the target letter.
- Maths: `2 + 3 = 5` and `7 − 2 = 5` are correct, and the star count (3) matches the stars drawn.
- The `Number Names` options agree with the number-name table.

## 2.2 Lesson-by-lesson review

Legend: ✔ = I found no error (still requires native sign-off) · ⚠ = see issue.

### English Forest

| Quest | Check | Result |
|---|---|---|
| `en-a` "A is for Apple" | Letter, answer, distractors (Ball, Cat), picture | ✔ Unique answer. Speech "A. Apple." gives the **letter name only** — AUD-011 |
| `en-word` "Word Builder" | Missing letter `C _ T`, options A, E, O | ⚠ **COT is also a word** — two correct answers (AUD-003). No picture clue (AUD-014). Subtitle "Spell a forest word" does not match the task (AUD-026) |
| `en-trace` | Letter A | ⚠ Accepts any scribble (AUD-006) |
| `en-story` | Text, question, cover | ⚠ Speech says "found", pages say "showed" (AUD-008). Cover shows a squirrel, text says a parrot (AUD-010) |

### Telugu Kingdom

| Quest | Check | Result |
|---|---|---|
| `te-a` "అ – అమ్మ" | అ vs అమ్మ, ఇల్లు, ఏనుగు | ✔ Spelling and meaning appear correct. Distractors begin with ఇ and ఏ, so the answer is unique. Images match |
| `te-word` "పదాల తోట" | Question "చిత్రానికి సరైన పదం?" | ⚠ The prompt panel shows **"క లం" — the answer** (AUD-005). Question has no verb ("…సరైన పదం ఏది?" would be fuller) — Suspected |
| `te-trace` "అ వ్రాయండి" | Title | Suspected: "వ్రాయండి" is the older form; modern usage often "రాయండి" (AUD-019). Instruction mentions **dots** that are not drawn (AUD-007) |
| `te-story` "చిన్ని చిలుక" | Pages, question, options | ✔ Grammar of the three sentences appears correct. Cover (parrot) shows **no red fruit** (AUD-010). No pictures for the options |

### Hindi Valley

| Quest | Check | Result |
|---|---|---|
| `hi-a` "अ – अनार" | अ vs अनार, कमल, घर | ✔ Correct. Distractors begin with क and घ. Images match |
| `hi-word` "शब्द बनाओ" | `क _ ल`, options म, न, र | ✔ Only म gives a word (कमल). No picture clue (AUD-014). Speech reads the whole word, which gives the answer away (acceptable as a hint) |
| `hi-trace` "अ लिखो" | Title, subtitle "उंगली" | Suspected: "उंगली"/"उँगली" are both used (AUD-019). Instruction mentions dots not drawn (AUD-007) |
| `hi-story` "नीला पतंग" | Title vs text | ⚠ **Title says "नीला"; page 2 says "नीली पतंग"** — inconsistent (confirmed). पतंग is feminine in standard Hindi, so "नीली" is expected — needs educator ruling (AUD-004). Speech says "पहाड़ी" (hill), pages say "घाटी" (valley) (AUD-008). Cover shows a girl; the character is रवि (AUD-010). "उड़ाने दिया" omits the object (AUD-027) |

### Tamil Garden

| Quest | Check | Result |
|---|---|---|
| `ta-a` "அ – அம்மா" | அ vs அம்மா, இலை, ஊஞ்சல் | ✔ Spelling appears correct; the conjunct "ஞ்ச" and the dot mark on "ல்" render correctly on the emulator. Distractors begin with இ and ஊ |
| `ta-word` "சொல் தோட்டம்" | `ம லர்`, question about a flower | ⚠ Prompt panel shows **"ம லர்" — the answer** (AUD-005). The question uses the everyday word "பூ" but the answer is the literary "மலர்" (AUD-020, Suspected) |
| `ta-trace` "அ எழுதுங்கள்" | Instruction | Mentions dots not drawn (AUD-007). Subtitle and title both say "write/draw" — repetition is acceptable |
| `ta-story` "வண்ணத்துப்பூச்சி" | Spelling, sandhi, pages | ✔ "வண்ணத்துப்பூச்சி", "தோட்டக் கதை" and the three sentences appear correct. The answer "மலர்த் தோட்டம்" is **never stated in the pages** (AUD-009); speech says "to the flower garden", pages say "to see the flower" (AUD-008) |

### Number Galaxy

| Quest | Check | Result |
|---|---|---|
| `num-count` | 3 stars, options 2/3/4 | ✔ Answer matches what is drawn |
| `num-add` 2+3 | 5 | ✔ |
| `num-subtract` 7−2 | 5 | ✔ — but **both maths quests answer 5 with the same options 4/5/6** (AUD-015) |
| `num-names` | Triples for 5, 3, 7 | ✔ Each triple agrees with the table. Speech sends Telugu/Hindi/Tamil script to an **English** voice (AUD-013). Needs reading three scripts at once (AUD-016) |

### Number words 1–10 (`numberNames`)

I read all forty entries (en/te/hi/ta × 1–10): ఒకటి, రెండు, మూడు, నాలుగు, ఐదు, ఆరు, ఏడు, ఎనిమిది, తొమ్మిది, పది · एक, दो, तीन, चार, पाँच, छह, सात, आठ, नौ, दस · ஒன்று, இரண்டு, மூன்று, நான்கு, ஐந்து, ஆறு, ஏழு, எட்டு, ஒன்பது, பத்து. **I found no error.** Native confirmation still required. The table is unused (AUD-017).

## 2.3 The areas you asked me to pay particular attention to

| Area | Status in the app |
|---|---|
| **Telugu gunintalu and ottulu** | **Not taught.** One vowel (అ) only. Ottulu appear only incidentally inside words (e.g. "అమ్మ" contains మ్మ) with no explanation |
| **Tamil uyirmei combinations** | **Not taught.** One uyir letter (அ). No mei or uyirmei letters; none of the 216 combinations |
| **Hindi matras and barakhadi** | **Not taught.** One swar (अ). The only matras seen are incidental ("नीला", "पतंग", "घाटी") |
| **English phonics** | **Not taught.** Letter name only; no letter sounds, blending or CVC progression (AUD-011) |

---

# Phase 3 — Educational sequence

## 3.1 The existing path (identical for every language)

`1 letter-pick → 2 word-pick/fill → 3 trace → 4 story`

- **Prerequisite problem (AUD-024).** The story quest (4) requires reading full sentences, but only one letter has been taught, and the pages are **never read aloud** (AUD-008). A child cannot access it by reading or by hearing.
- **Order.** Word-building (2) comes before tracing (3). Tracing a letter right after recognising it would be a more natural next step.
- **Nothing is enforced.** All quests are open from the start (confirmed), so a child can start at the story.
- **Repetition with no purpose (AUD-023).** The same four-quest template is repeated in every language with the same single letter; the trace quest repeats the letter from quest 1.
- **Review choice (AUD-030).** After a world is mastered, the "review" quest is picked by `attempts % 4` (`app_controller.dart:63–66`), not by what the child found hard.

## 3.2 Do the quizzes measure what they claim? (AUD-012, AUD-028)

- "Listen and recognise" (and the Telugu, Hindi and Tamil equivalents) is the subtitle of every letter quest, but the question is printed text and can be answered by reading or by picture alone. **Audio is never required**, so listening is not measured.
- The question and instruction text is **never spoken** (AUD-029): only a short `speech` line such as "A. Apple." is read. A 3–6 year old cannot read "Which word begins with A?" and gets no audio instruction.
- Every quiz is three-option recognition. Nothing tests recall, production, or listening discrimination.
- The Telugu and Tamil word quizzes show the answer in the prompt panel (AUD-005), so they do not measure anything.
- Tracing accepts any scribble (AUD-006).

## 3.3 Progression by age band (as the app is today)

| Age | What the app offers | Assessment |
|---|---|---|
| **3–4** | Picture-matching of one letter's words, counting 3 stars | Partly meaningful, but instructions are text-only and the Listen button does not read them (AUD-029) |
| **5–6** | The same quests; one sum, one difference | Thin. "Trace • Spell • Add • Subtract" is promised; one letter, one spelling item, one sum, one difference exist |
| **7–9** | The same quests | **Not meaningful.** "Read • Write • Grammar • Arithmetic" is promised; none exists |
| **10–12** | The same quests | **Not meaningful.** "Comprehension • Writing • Advanced maths" is promised; none exists |

## 3.4 Recommended teaching order (Report C)

These are **recommendations** based on standard early-literacy sequencing; a native educator should confirm each list, the grouping and the pacing.

**Common order within every language:** *recognise (see + hear) → trace → build → read a sentence → read a story → answer questions.* Move **tracing before word-building**, and keep stories last.

**Telugu** — 1) vowels (అచ్చులు) in small groups starting with అ ఆ ఇ ఈ; 2) consonants (హల్లులు) starting with high-frequency ones; 3) **gunintalu** — each consonant with the vowel signs (క, కా, కి, కీ …), taught in groups; 4) two- and three-letter words; 5) **ottulu** (conjuncts such as మ్మ, ల్ల) only after gunintalu; 6) simple sentences, then stories; 7) basic grammar for ages 7+.
*Why:* the current quests use words with ottulu (అమ్మ, ఇల్లు) before any gunintam is taught.

**Tamil** — 1) uyir (உயிர்) letters in groups; 2) mei (மெய்) letters; 3) **uyirmei** combinations built from mei + uyir (க, கா, கி, கீ …) in groups; 4) the ஆய்த எழுத்து; 5) words, sentences, stories; 6) grammar for ages 7+.
*Why:* the current words (மலர், ஊஞ்சல்) need mei and uyirmei letters that are never taught.

**Hindi** — 1) swar (अ आ इ ई …); 2) vyanjan; 3) **barakhadi** — each consonant with the matras (क, का, कि, की …); 4) conjunct letters (संयुक्त अक्षर); 5) words, sentences, stories; 6) grammar (gender agreement, e.g. नीली पतंग) for ages 7+.
*Why:* a story needing "पतंग", "घाटी" and "उड़ाने" appears before any matra is taught.

**English** — 1) letter names *and sounds*, in a phonics order; 2) **blending** consonant-vowel-consonant words (and ensure each blank has one valid answer); 3) sight words; 4) simple sentences; 5) stories with literal and inferential questions.
*Why:* only the letter A and one word are taught, and the blank `C _ T` has two valid answers.

**Numbers** — 1) counting and recognising 1–10; 2) number order and comparison; 3) add and subtract within 10, then 20; 4) place value; 5) for 10–12 multiplication, fractions and word problems.
*Why:* the current four quests cover three counted stars, one sum and one difference.

---

# Phase 4 — Functional tests (Report D)

All tests are in `test/audit/curriculum_audit_test.dart` (new; no app code changed).

```
flutter test test/audit                                   # normal run
flutter test test/audit --dart-define=AUDIT_STRICT=true   # strict run
```

**Actual results**

| Run | Pass | Fail | Skipped |
|---|---|---|---|
| Audit, normal | **28** | 0 | 14 (known defects, each named by issue ID) |
| Audit, **strict** | **28** | **14** | 0 |
| Whole repository suite, normal | **204** | 0 | 14 |

*(First run, before any fix: 27 pass / 15 fail in strict mode. After AUD-031 was fixed the same day: 28 / 14. The whole suite also gained 31 layout tests for the fix.)*

In strict mode the 14 failures are **exactly** the 14 still-open defects I had marked: AUD-001, 002 (×2), 003, 005, 006, 007, 008, 009, 013, 014, 017 (×2), 018. No known-defect check passed unexpectedly after I replaced one weak check (a text search for "stroke" that passed for the wrong reason) with a behavioural test.

**What the passing tests prove**

| Requirement | Result |
|---|---|
| Every quest can be opened | **Pass** — from its world map (all 20) and directly at four screen sizes, no errors |
| Every lesson references valid content | **Pass** — ids unique, fields present, locales correct, scripts clean |
| Every image asset exists | **Pass** — every picture, cover, quest card art and world image exists; none is tiny or oversized |
| Audio exists or has a supported fallback | **Documented** — there are **no audio files**. The fallback is text-to-speech, and a "Voice unavailable" pop-up appears when it fails. Not a pronunciation test |
| Every question has a valid answer | **Pass** |
| Answer choices not unintentionally duplicated | **Pass** |
| Correct answers are accepted | **Pass** — all 15 quizzes (stories read to their question first) |
| Incorrect answers get appropriate feedback | **Pass** — every wrong option in every quiz gives "Good try!", "Play again" and "Back to map" |
| Progress saved and restored | **Pass** — all 20 quests completed, saved to disk, reloaded identically (completed set, 60 stars, four badges, per-world counts) |
| Rewards cannot be repeated | **Pass** — 5 rounds of right and wrong answers across all 20 quests give exactly **60 stars**; wrong answers alone never complete a quest |
| No lesson becomes inaccessible | **Pass** — no locks; any completion order works; review recommendations stay valid |

**What the failing (strict) tests prove** — see the register below: 15 checks, each failing for the reason stated.

**A defect the audit itself found, now fixed:** my first behaviour run could not tap "Check Answer" on the English and Hindi word quizzes at 800×360. A probe showed the button was drawn **off-screen** (y 358–438 on a 360-high screen) on `en-word`, `hi-word` and `num-names` at 640×360 and 800×360 (AUD-031). It was fixed on request (button pinned under a scrolling answer list); the same probe style then found AUD-032 (Tamil story "Next Page", 640×360 only).

**Untested — not testable by these checks**
- Pronunciation, voice availability, and audio-to-letter / audio-to-word alignment (needs real devices and native listeners).
- Translation quality and grammar beyond the rules I could code (needs native educators).
- Whether each picture suits its word and age group (Claude's visual review only).
- Speech on a device with a different TTS engine or without Telugu, Hindi or Tamil voices installed.
- Large-scale use: learning outcomes with real children.

---

# Phase 5 — Reports

## A. Curriculum Coverage Matrix

Status: **Absent** = nothing exists · **Minimal** = one item · **Partial** = some, with gaps.

| Language | Age | Topic | Expected skills | Existing lessons | Missing skills | Status |
|---|---|---|---|---|---|---|
| English | 3–4 | Letter recognition | Recognise A–Z with sound and picture | `en-a` (A only) | B–Z, letter sounds | Minimal |
| English | 3–4 | Listening | Hear sounds and words, match | `en-a` Listen button | Sounds; instructions not spoken | Minimal |
| English | 5–6 | Phonics / blending | CVC words, blends | `en-word` (C _ T) | Sounds, blending, other words; blank has two answers | Minimal (flawed) |
| English | 5–6 | Writing | Form letters | `en-trace` (A) | Other letters; shape not checked | Minimal |
| English | 7–9 | Reading | Sentences, sight words | `en-story` (3 sentences) | Sight words, sentence work | Minimal |
| English | 7–9 | Grammar | Nouns, verbs, sentences | — | All | Absent |
| English | 10–12 | Comprehension | Inference, vocabulary | `en-story` (1 recall question) | All beyond literal recall | Minimal |
| English | 10–12 | Writing | Sentences, paragraphs | — | All | Absent |
| Telugu | 3–4 | Vowels (అచ్చులు) | Recognise 16 vowels | `te-a` (అ) | 15 vowels | Minimal |
| Telugu | 3–4 | Vocabulary | Common nouns | `te-a` (3 words) | Most categories | Minimal |
| Telugu | 5–6 | Consonants (హల్లులు) | Recognise consonants | — | All | Absent |
| Telugu | 5–6 | **Gunintalu** | Consonant + vowel signs | — | All | **Absent** |
| Telugu | 5–6 | Writing | Trace letters | `te-trace` (అ) | Others; shape not checked | Minimal |
| Telugu | 7–9 | **Ottulu** | Conjuncts | — (incidental in అమ్మ) | All | **Absent** |
| Telugu | 7–9 | Reading | Sentences, stories | `te-story` | Reading is not scaffolded; pages not spoken | Minimal |
| Telugu | 10–12 | Grammar / composition | Sentences, comprehension | — | All | Absent |
| Hindi | 3–4 | Swar | Recognise vowels | `hi-a` (अ) | 12 vowels | Minimal |
| Hindi | 5–6 | Vyanjan | Recognise consonants | `hi-word` (म, न, र as options only) | Consonants | Minimal |
| Hindi | 5–6 | **Matras / barakhadi** | Consonant + matra | — | All | **Absent** |
| Hindi | 5–6 | Writing | Trace letters | `hi-trace` (अ) | Others | Minimal |
| Hindi | 7–9 | Conjuncts, reading | संयुक्त अक्षर, sentences | `hi-story` | Conjuncts; reading scaffold | Minimal |
| Hindi | 10–12 | Grammar | Gender agreement, tenses | — | All | Absent |
| Tamil | 3–4 | Uyir letters | Recognise 12 vowels | `ta-a` (அ) | 11 uyir | Minimal |
| Tamil | 5–6 | Mei letters | Recognise 18 consonants | — | All | Absent |
| Tamil | 5–6 | **Uyirmei** | Mei + uyir combinations | — | All 216 | **Absent** |
| Tamil | 5–6 | Writing | Trace letters | `ta-trace` (அ) | Others | Minimal |
| Tamil | 7–9 | Reading | Words, sentences, stories | `ta-word`, `ta-story` | Reading scaffold | Minimal |
| Tamil | 10–12 | Grammar / composition | Sentences, comprehension | — | All | Absent |
| Numbers | 3–4 | Counting | Count to 10 | `num-count` (3) | 1, 2, 4–10 | Minimal |
| Numbers | 5–6 | Add / subtract | Within 10 | `num-add`, `num-subtract` | Varied items | Minimal |
| Numbers | 5–6 | Number recognition | Numerals 1–10 | — | All | Absent |
| Numbers | 7–9 | Arithmetic | Within 20/100, place value | — | All | Absent |
| Numbers | 10–12 | Advanced maths | Multiplication, fractions | — | All | Absent |

## B. Detailed Issue Register

Severity: Critical = the app does not meet its stated purpose · High = wrong or blocks learning · Medium = weakens learning · Low = polish or hygiene.
Line numbers refer to `lib/src/curriculum.dart` unless a path is given.

| Issue ID | Language | Quest | File path | Content | Problem | Severity | Suggested correction | Verification Status |
|---|---|---|---|---|---|---|---|---|
| AUD-001 | TE, HI, TA, EN | All letter quests | `curriculum.dart` 15–303 | One letter each (A / అ / अ / அ) | Each world teaches one letter; no vowel or consonant families, matras, gunintalu, ottulu, uyirmei, barakhadi, phonics | **Critical** | Build a letter sequence per language (see Report C) | **Confirmed** (test "each Indic world teaches more than one letter" fails) |
| AUD-002 | All | All | `models.dart:3–33`; `app_controller.dart:58–80` | Age bands and "focus" text | Content does not vary by age; ages 3–12 receive identical 20 quests; promised "Grammar", "Writing", "Advanced maths", "Comprehension" do not exist | **Critical** | Add an age/level to lessons; offer different quests per band; or remove promises the app cannot keep | **Confirmed** (2 tests fail) |
| AUD-003 | EN | `en-word` | `curriculum.dart` 32–43 | `C _ T`, options A, E, O | **CAT and COT are both words**; two correct answers | High | Replace the distractor O (and E if confusing) with letters that make no word, e.g. "X" or "Z" | **Confirmed** (test, using words CAT/COT/CUT) |
| AUD-004 | HI | `hi-story` | `curriculum.dart` 208, 225 | Title "नीला पतंग" vs page "नीली पतंग" | The title and the text disagree. पतंग is feminine in standard Hindi, so the title should be "नीली पतंग" | High | Educator to confirm; change title to "नीली पतंग" | Inconsistency **Confirmed**; grammatical ruling **Suspected** |
| AUD-005 | TE, TA | `te-word`, `ta-word` | `curriculum.dart` 112–117, 262–267 | Prompt panel shows "క లం" / "ம லர்" | The left panel displays the answer (spaced), so the quiz asks the child to match what is shown | High | Show the picture and ask for the word, or hide the written word | **Confirmed** (test fails) |
| AUD-006 | All | Tracing quests | `lib/src/screens/lesson_screen.dart:591` | "I traced it!" enabled after 12 touch points | Any scribble passes and earns 3 stars; the letter shape is never checked | High | Compare the stroke to the letter, or reword as a free-draw activity with no scoring | **Confirmed** (test: a zig-zag in the corner is accepted) |
| AUD-007 | TE, HI, TA | Tracing quests | `curriculum.dart` 132, 202, 282; `lesson_screen.dart:862–885` | "Draw over the dots" | No dots are drawn — the guide is a faint letter | Medium | Draw a dotted guide, or change the instruction | **Confirmed** (test fails) |
| AUD-008 | EN, HI, TA, TE | Story quests; all lessons | `curriculum.dart` 62, 212, 292; `lesson_screen.dart:81` | Listen speaks one `speech` line | The three story pages are never read aloud; the spoken line differs from the pages (HI "hill" vs "valley"; EN "found" vs "showed"; TA "to the flower garden" vs "to see the flower") | High | Speak each page; make the speech text identical to the page text | **Confirmed** (test fails) |
| AUD-009 | TA, EN | Story questions | `curriculum.dart` 294–296, 64–66 | Answer "மலர்த் தோட்டம்"; "What did Mina find?" | The answer is not stated in the pages (TA); the question says "find" but pages say "showed" (EN) | Medium | Add a page that states the answer, or change the question | **Confirmed** for TA/EN. For HI the check flags "नीला" only because the pages inflect it ("नीली"); that is not an error |
| AUD-010 | HI, EN, TE | Story covers | `assets/images/stories/` | kite.webp, mango.webp, parrot.webp | HI cover shows a girl but the character is रवि (a boy's name); EN cover shows a squirrel, text says a parrot; TE cover has no red fruit | Medium | Regenerate or caption the images to match the text | **Observed** (Claude, visual review) |
| AUD-011 | EN | `en-a` | `curriculum.dart` 21 | Speech "A. Apple." | Letter name only; the sound /æ/ is never spoken | Medium | Add letter sounds and a phonics order | Recommendation |
| AUD-012 | All | Letter quests | `curriculum.dart` 18, 93, 168, 243 | "Listen and recognise" | The task can be done without audio, so the listening objective is not measured | Medium | Speak the target and hide the written prompt | **Confirmed** (design review) |
| AUD-013 | TE, HI, TA, EN | All | `MainActivity.kt:33–49`; `curriculum.dart` 357–358 | All speech is text-to-speech; no audio files | Pronunciation unverified for te-IN, hi-IN, ta-IN. `num-names` sends Telugu, Hindi and Tamil text to an **English** (`en-IN`) voice. A missing voice shows a pop-up in English | High | Native-listener test on real devices; recorded audio for core content; speak number names per language | No-audio **Confirmed**; pronunciation **Unverified**. Emulator log showed the Tamil request reaching a Tamil voice (not heard) |
| AUD-014 | EN, HI | `en-word`, `hi-word` | `curriculum.dart` 32–43, 182–193 | `C _ T`, `क _ ल` | No picture clue, so the child cannot tell what word is wanted | Medium | Show the picture of the cat / lotus | **Confirmed** (test fails) |
| AUD-015 | Numbers | `num-count`, `num-add`, `num-subtract` | `curriculum.dart` 315–349 | Single items | Counting 3 only; both maths quests have answer 5 and options 4/5/6; no numerals, order, or comparison | Medium | Several items per skill with varied answers | **Confirmed** |
| AUD-016 | Numbers | `num-names` | `curriculum.dart` 351–366 | "ఐదు / पाँच / ஐந்து" | A child must read three scripts at once, so it suits no one aged 3–6; spoken via an English voice | Medium | Split into one language per quest, or listen-and-pick | **Confirmed** (text); suitability Suspected |
| AUD-017 | All | Data hygiene | `curriculum.dart` 9, 61, 84, 159, 211, 234, 291, 309, 371 | `emoji`, emoji `symbol`s, `numberNames` | Unused or placeholder data | Low | Remove, or use `numberNames` | **Confirmed** (2 tests fail) |
| AUD-018 | — | Assets | `assets/images/rewards/` (crown, gem, gift, medal); `quiz/te_house`, `hi_house`, `ta_house` | Images | Four shipped images are unused; three house pictures are near-identical | Low | Remove or use; differentiate | Orphans **Confirmed** (test); duplicates **Observed** |
| AUD-019 | TE, HI | `te-trace`, `hi-trace` | `curriculum.dart` 126, 197 | "వ్రాయండి"; "उंगली" | Variant spellings | Low | Educator to choose the form | **Suspected** |
| AUD-020 | TA | `ta-word` | `curriculum.dart` 265–267 | Question "பூவைக் குறிக்கும் சொல் எது?", answer "மலர்" | Asks with the everyday word பூ but teaches the literary மலர் | Medium | Educator to decide; consider teaching "பூ" first | **Suspected** |
| AUD-021 | TE | `te-word` | `assets/images/quiz/te_fruit.webp` | "పండు" (one fruit) | Picture shows a basket of mixed fruit | Low | Show one fruit | **Observed** |
| AUD-022 | All | Story quests | `curriculum.dart` 59–78, 138–153, 207–228, 287–303 | 3 sentences, 1 question | Literal recall only; nothing for ages 7–12 | Medium | Add sequencing and inference questions | **Confirmed** (data); recommendation |
| AUD-023 | TE, HI, TA, EN | All | `curriculum.dart` | Same four-quest template | Repeats a template with no progression inside a language | Medium | Progress letters, then words, then sentences | **Confirmed** |
| AUD-024 | TE, HI, TA, EN | Story quests | `curriculum.dart`; `world_map_screen.dart` | Story is quest 4 | Reading is required, but one letter is taught and pages are not spoken; no order is enforced | High | Teach reading skills first; order or gate quests; speak pages | **Confirmed** |
| AUD-025 | All | Speech failure | `lesson_screen.dart:89` | "Voice unavailable… ta-IN voice" | The pop-up is English and shows a locale code | Low | Plain wording, in the quest's language | **Confirmed** |
| AUD-026 | EN | `en-word`, `num-count` | `curriculum.dart` 35, 317–318 | "Spell a forest word"; title and subtitle both "Count the stars" | Label does not match the task (choose a missing letter; a cat is not a forest word); redundant subtitle | Low | Reword | **Confirmed** |
| AUD-027 | HI | `hi-story` | `curriculum.dart` 226 | "रवि ने अपने दोस्त को भी उड़ाने दिया।" | The object is missing; "…भी पतंग उड़ाने दी" is clearer | Low | Educator to decide | **Suspected** |
| AUD-028 | All | Quizzes | `curriculum.dart` | Three-option recognition only | No recall, production or listening-discrimination; 1-in-3 guessing | Medium | Vary question types; use audio prompts | **Confirmed** (design) |
| AUD-029 | All | All quizzes | `curriculum.dart` `challenge` vs `speech` fields; `lesson_screen.dart:81` | Question text is never spoken | Pre-readers (3–6) cannot read the instruction and Listen does not read it | High | Speak the question and instruction in the quest's language | **Confirmed** |
| AUD-030 | All | Review | `app_controller.dart:63–66` | `attempts % lessons.length` | After mastery, the "review" quest is round-robin, not based on what was difficult | Medium | Prioritise quests with errors | **Confirmed** |
| AUD-031 | EN, HI, TE, TA, Numbers | `en-word`, `hi-word`, `te-story`, `ta-story`, `num-names` | `lib/src/screens/lesson_screen.dart` (text-only quiz layout) | "Check Answer" button | Was drawn off-screen at 640×360 and 800×360 (e.g. y 358–438 on a 360-high screen); the child had to scroll to find it | High | Pin the button under a scrolling answer list; compact the answers on short screens | **FIXED 29 Oct 2026** — confirmed by 31 new layout tests and on the emulator (`test/check_button_layout_test.dart`) |
| AUD-032 | TA | `ta-story` | `lib/src/screens/lesson_screen.dart` (story page card) | "Next Page" button | At 640×360 the button is drawn 26 dp below the bottom edge (y 334–386 of 360); fine at the other 15 combinations measured | Medium | Same pinned-button approach as AUD-031 | **Confirmed** (measured); not yet fixed |

## C. Learning Sequence Report

See **§3.4 Recommended teaching order** above, for English, Telugu, Hindi, Tamil and Numbers, with the reasons for each change. All sequencing here is a **recommendation** for educator validation.

## D. Functional Test Report

See **Phase 4** above for the executed tests and results, and the list of untested areas.

## E. Prioritised Improvement Plan

**Critical**
1. AUD-001 — Build real letter sequences (vowels → consonants → gunintalu/uyirmei/barakhadi → ottulu/conjuncts → words) per language.
2. AUD-002 — Make content depend on age (add a level to each lesson), or stop promising what is not built.

**High** (wrong, or blocks learning)
3. ~~AUD-031 — Make "Check Answer" visible on 360 dp-high screens.~~ **Done.** Related: AUD-032 (Tamil story "Next Page" at 640×360) is open.
4. AUD-003 — Fix the `C _ T` blank (two valid answers).
5. AUD-005 — Stop showing the answer in the prompt panel (Telugu, Tamil).
6. AUD-006 — Check the tracing shape, or stop awarding stars for it.
7. AUD-029 and AUD-008 — Speak the question, every story page, and make speech text match the page text.
8. AUD-024 — Fix the prerequisite order; stories must come after reading skills.
9. AUD-013 — Run a real-device listening test with native listeners for te-IN, hi-IN and ta-IN; decide whether recorded audio is needed.
10. AUD-004 — Hindi title gender (native educator ruling).

**Medium**
AUD-007, 009, 010, 011, 012, 014, 015, 016, 020, 022, 023, 028, 030.

**Low**
AUD-017, 018, 019, 021, 025, 026, 027.

### Confirmed errors, suspected problems, recommendations

- **Confirmed errors** (proved by code, test or measurement): AUD-001, 002, 003, 005, 006, 007, 008, 009 (TA, EN), 012, 014, 015, 017, 018 (orphans), 023, 024, 025, 026, 028, 029, 030, 031; the **inconsistency** in AUD-004.
- **Suspected — needs a native educator:** AUD-004 (gender ruling), 019, 020, 027; also the correctness of every Telugu, Tamil and Hindi string in general.
- **Observed — needs a human reviewer:** AUD-010, 018 (duplicate pictures), 021.
- **Recommendations:** AUD-011, 022, and the teaching sequences in Report C.

---

## Approval needed before any change

No curriculum text, lesson, image or application code has been modified. I recommend you decide, in order:

1. ~~Whether to fix **AUD-031**~~ — done (layout only). Whether to fix **AUD-032** the same way.
2. Who will review the Telugu, Tamil and Hindi wording (**native educators**), and the English phonics approach (an early-years literacy specialist).
3. The curriculum scope for **AUD-001 and AUD-002** — this is a content-design project, not a bug fix.
