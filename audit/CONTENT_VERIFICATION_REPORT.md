# Content verification report - pilot teaching plans

Verifier: content-verifier (independent of the creator). Date: 2026-10-31.
Subject: `content/teaching/pilot_teaching_plans.json` (schema_version 1, status `pilot_unverified`), lessons en-a, te-a, hi-a, ta-a, num-add.
Judged against the ORIGINAL implemented lessons in `lib/src/curriculum.dart` (lines 15-34 en-a, 108-127 te-a, 200-219 hi-a, 293-312 ta-a, 400-415 num-add and 385-399 num-count), not against `audit/PILOT_CONTENT_SPECS.md`. No plan or code file was edited; this report is the only file written.

## 1. Method and what was actually run

1. Read `.claude/agents/content-verifier.md`, `AKSHARAMALA_AGENT_RULES.md`, all of `curriculum.dart`, and the whole plan JSON (2,536 lines) by hand.
2. Wrote and ran a checker: `C:\Users\aravi\AppData\Local\Temp\claude\C--Users-aravi-OneDrive-Desktop-Claude\761260ff-07ea-4616-8488-8f450c083a38\scratchpad\verify_pilot.py` (command: `python -X utf8 -I verify_pilot.py`, output saved in `...\scratchpad\verify_out.txt`). It checks: unique ids; allowed visual types and field names; asset files exist; answer in options; wrong_feedback keys equal the distractors; check items have no hints; answer visible in check prompt/caption/feedback; every maths item re-solved from the prompt, the visual (group counts / number-line start+jump) and the spoken text; distractors wrong; sums within 10; feedback claims ("one of the numbers you started with", "too many", "close") tested numerically; explanation arithmetic; check items vs worked examples/guided/practice; language words, titles, locales, picture paths and first letters compared with `curriculum.dart`.
3. Viewed the picture files with the Read tool: apple.png, ball.png, cat.png, te_amma/te_house/te_elephant.webp, hi_pomegranate/hi_lotus/hi_house.webp, ta_mother/ta_leaf/ta_swing.webp, num_crystal.webp, num_rocket.webp.
4. Grepped the plan for stroke-order/tracing claims (0 hits) and `lib/` for the plan file or any consumer of the new visual fields (`revealCount`, `numberLine`, `letterWord`): none exist, so nothing renders this schema yet.

Real checker output (summary): ids 117 total / 117 unique; 0 disallowed visual types; 0 unexpected fields; 0 missing assets; every answer is in its options; every maths key correct (14/14); every maths distractor wrong; all sums and options <= 10; no explanation arithmetic mismatches; no check item has hints; 3 of 3 language lessons match `curriculum.dart` for title, locale, word list, picture paths. The checker's other output is incorporated below. Four of its "answer inside prompt/feedback" hits (te/hi/ta check.2 and rem_check.1) are false positives caused by the letter being a substring of the word "akshara" or similar; I reviewed each by hand and discarded them. They are not counted.

Not run / not possible: no audio (TTS) was heard, no screen was rendered (the app does not read this file), no native Telugu/Hindi/Tamil speaker consulted.

## 2. Decision to resolve: Telugu lesson id

CONFIRMED. `curriculum.dart` lesson `te-a` is titled `అ – అమ్మ`, options అమ్మ / ఇల్లు / ఏనుగు, answer అమ్మ, pictures te_amma / te_house / te_elephant (.webp). The plan matches exactly. Note for the owner: `lib/src/batch/batch_content.dart` (line ~115) holds a different first Telugu lesson, `telugu-recognise-001`, with options అమ్మ / ఉడుత / ఓడ, and `models.dart:336` aliases it to `te-a` progress. Attaching the plan to `te-a` is correct for the live curriculum; the product owner should still decide whether both first lessons stay visible at Level 1.

## 3. Per-lesson verdicts

| Lesson | Verdict | MAJOR | MINOR | GATE/INFO |
|---|---|---|---|---|
| en-a | REVISE | 4 | 4 | 0 |
| te-a | REVISE (plus native-review gate) | 3 | 2 | 1 gate, 1 info |
| hi-a | REVISE (plus native-review gate) | 3 | 3 | 1 gate |
| ta-a | REVISE (plus native-review gate) | 3 | 3 | 1 gate |
| num-add | REVISE | 4 | 7 | 0 |
| Cross-cutting | REVISE | 1 | 4 | 0 |

No lesson is PASS. No lesson is BLOCKED outright, but te-a, hi-a, ta-a cannot be labelled native-speaker-verified until the gate items are cleared.

### 3.1 en-a - REVISE

| # | Step / item | Sev | Evidence | Required correction | Owner |
|---|---|---|---|---|---|
| EN-1 | en-a.check.1, en-a.remediation_check.3 (also en-a.practice.2) | MAJOR | Visual is a picture with `caption` equal to the answer ("Apple", "Cat", "Ball") while the question is "What is this picture?". The answer is printed on screen. | Remove `caption` on all question pictures (keep captions in teaching steps only). | content-creator |
| EN-2 | en-a.check.1-3 | MAJOR | check.3 has the same answer and option set as guided.1 and practice.4 (only the order and prompt wording change); check.2 is guided.2/practice.1 with audio instead of the glyph. Checker confirmed identical signatures. A child can pass by memory. | Make check items new: new stimulus or new task type, not reused sets. With only 3 words this needs more words (see X-2). | content-creator |
| EN-3 | objective vs all items | MAJOR | Objective says "uppercase and lowercase A"; demonstrate.2 teaches `a`, but no guided/practice/check item ever shows or asks for lowercase `a` (checker: items testing lowercase = none). Objective is untested. | Add lowercase-matching items to guided, practice and check, or narrow the objective. | content-creator / educator |
| EN-4 | remediation.explain 1-3 | MAJOR | Remediation reuses the same Ball / Cat / Apple pictures and the same "does it begin with A? no/no/yes" elimination as demonstrate.3-5, only reordered. Not a different explanation or visual. remediation_guided/check are the same item types again. | Use a different method (for example the letter shape with a second word, mouth/first-sound cue, or sorting) and different visuals. | content-creator / educator |
| EN-5 | en-a.guided.1, practice.1, practice.4 | MINOR | The first hint "A says a, like in Apple" already states the answer (for practice.1 the answer IS the letter A). Practice items carry one hint each, so there is no ladder there. | Make hint 1 a nudge (say the word slowly), hint 2 the reveal; give practice a 2-step ladder. | content-creator |
| EN-6 | all `speech` using "A." and hints | MINOR / UNVERIFIED | A bare "A." in en-US TTS may be read as the article "a" (/ə/) or as the letter name /eɪ/; "A says a" does not say which sound (short /æ/). Letter name versus sound is not distinguished. | Educator to define letter name vs sound wording; test TTS audibly. | educator, audio reviewer |
| EN-7 | practice.2, check.1, remediation_check.3 feedback/hints | MINOR | "Listen again" is used where the prompt plays no audio of the target word. | Reword, or add the spoken word. | content-creator |
| EN-8 | en-a.check.1 | MINOR | Picture naming (with caption) measures reading/recognising the word, not the lesson objective (A / word begins with A). Only check.3 measures the objective, and it is a repeat (EN-2). | Re-balance the check toward the objective. | educator |

Verified correct in en-a: Apple begins with A; Ball (B) and Cat (C) do not; "big A and small a are the same letter" is accurate; words, locale `en-US`, title and picture paths equal the curriculum; all three pictures show what they name (apple, beach ball, cat); no invented vocabulary; every distractor is wrong; instructions are in English; no stroke-order claims.

### 3.2 te-a - REVISE

| # | Step / item | Sev | Evidence | Required correction | Owner |
|---|---|---|---|---|---|
| TE-1 | te-a.check.1, te-a.remediation_check.3 (and practice.2) | MAJOR | Picture `caption` equals the answer (అమ్మ, ఏనుగు, ఇల్లు) on "ఈ బొమ్మ ఏమిటి?" - answer visible. | Drop captions on question pictures. | content-creator |
| TE-2 | te-a.check.1-3 | MAJOR | Same repeat problem as EN-2: check.3 = guided.1/practice.4 option set and answer; check.2 = guided.2/practice.1 with audio. | New check items (see X-2). | content-creator |
| TE-3 | remediation.explain 1-3 | MAJOR | Same pictures and yes/no elimination as demonstrate.3-4, reordered; not a different explanation. | Different method and visual. | content-creator / educator |
| TE-4 | practice.2, check.1, remediation_check.3 | MINOR | "మళ్లీ వినండి" (listen again) used with no audio of the target. | Reword or add audio. | content-creator |
| TE-5 | te-a.check.1 | MINOR | Picture naming does not test the objective (see EN-8). | Re-balance. | educator |
| TE-6 | ALL Telugu text, speech, hints, feedback | GATE: UNVERIFIED | I can confirm the script, spelling of అమ్మ / ఇల్లు / ఏనుగు (matches curriculum), that each word begins with అ / ఇ / ఏ respectively (so the letter distractors ఇ and ఏ are genuinely wrong), and that instructions are in Telugu as the existing app does. I cannot confirm grammar or naturalness of: మొదలవుతుంది / మొదలవదు, "నాతో చెప్పండి", "ఇది వేరే అక్షరం", బొమ్మ for "picture", విన్నారు, the sentence "ఈ అక్షరంలా ఉన్న అక్షరాన్ని వెతకండి", the plural/respectful register for a 3-4 year old, or how Telugu TTS reads a lone "అ". | Native Telugu speaker review of every sentence plus listening to the TTS. | native Telugu reviewer |
| TE-7 | id decision | INFO | te-a title/options confirmed (section 2). te_amma shows a mother and a girl; a child may say "పాప". | Product owner to decide on the batch lesson; consider a cropped single-subject image later. | product owner |

Verified: no invented vocabulary; no stroke-order/tracing claims; wrong_feedback present for every distractor.

### 3.3 hi-a - REVISE

| # | Step / item | Sev | Evidence | Required correction | Owner |
|---|---|---|---|---|---|
| HI-1 | hi-a.check.1, hi-a.remediation_check.3 (and practice.2) | MAJOR | Caption equals answer (अनार, घर, कमल) while asking "यह चित्र किसका है?". | Remove captions on question pictures. | content-creator |
| HI-2 | hi-a.check.1-3 | MAJOR | check.3 = guided.1/practice.4; check.2 = guided.2/practice.1 (modality change only). | New check items. | content-creator |
| HI-3 | remediation.explain 1-3 | MAJOR | Same pictures and the same yes/no elimination as demonstrate.3-4. | Different method and visual. | content-creator / educator |
| HI-4 | practice.2, check.1, remediation_check.3 | MINOR | "फिर से सुनो" with no audio of the target. | Reword or add audio. | content-creator |
| HI-5 | hi-a.check.1 | MINOR | Picture naming does not test the objective. | Re-balance. | educator |
| HI-6 | prompt "यह चित्र किसका है?" | MINOR / UNVERIFIED | Literally "whose picture is this?"; "what is this a picture of" is the intent. May read as ownership. | Native review; consider "यह क्या है?". | native Hindi reviewer |
| HI-7 | ALL Hindi text, speech, hints, feedback | GATE: UNVERIFIED | Confirmed by me: script, spelling of अनार / कमल / घर and that they begin with अ / क / घ; the letter distractors क and घ are wrong; existing app uses the informal "तुम" imperative and the plan is consistent with it. Not confirmable by me: naturalness of "पहली आवाज़ सुनो", "दूसरे अक्षर से शुरू होता है", "तुमने ... सुना", danda/spacing in speech strings, and Hindi TTS for a lone "अ" (inherent-vowel/name versus sound). | Native Hindi review and listening test. | native Hindi reviewer |

### 3.4 ta-a - REVISE

| # | Step / item | Sev | Evidence | Required correction | Owner |
|---|---|---|---|---|---|
| TA-1 | ta-a.check.1, ta-a.remediation_check.3 (and practice.2) | MAJOR | Caption equals answer (அம்மா, ஊஞ்சல், இலை) on "இது என்ன படம்?". | Remove captions on question pictures. | content-creator |
| TA-2 | ta-a.check.1-3 | MAJOR | check.3 = guided.1/practice.4; check.2 = guided.2/practice.1. | New check items. | content-creator |
| TA-3 | remediation.explain 1-3 | MAJOR | Same pictures and elimination as demonstrate.3-4. | Different method and visual. | content-creator / educator |
| TA-4 | practice.2, check.1, remediation_check.3 | MINOR | "மீண்டும் கேளுங்கள்" with no audio of the target. | Reword or add audio. | content-creator |
| TA-5 | ta-a.check.1 | MINOR | Picture naming does not test the objective. | Re-balance. | educator |
| TA-6 | wrong_feedback "எழுத்தை கவனமாகப் பாருங்கள்"; explanations "நீங்கள் ஊஞ்சல் கேட்டீர்கள்", "நீங்கள் அம்மா கேட்டீர்கள்" | MINOR / UNVERIFIED (probable error) | The first appears to lack the joining consonant (Tamil sandhi: எழுத்தைக் கவனமாகப்); the plan itself writes "எழுத்தைக் கேளுங்கள்" elsewhere, so it is inconsistent. The second pair drops the quotation/accusative ("... என்ற சொல்லைக்") and may be unnatural. | Native Tamil reviewer to confirm and correct. | native Tamil reviewer |
| TA-7 | ALL Tamil text, speech, hints, feedback | GATE: UNVERIFIED | Confirmed by me: script and spelling of அம்மா / இலை / ஊஞ்சல் equal the curriculum; each begins with அ / இ / ஊ; letter distractors இ and ஊ are wrong; instructions in Tamil. Not confirmable: grammar and naturalness of the sentences, "படம்" for picture, the register, and Tamil TTS for a lone "அ". | Native Tamil review and listening test. | native Tamil reviewer |

### 3.5 num-add - REVISE

Independent solution of every item (checker table, all keys correct, all distractors wrong, all sums <= 10):

| Item | Problem | Key | Options (shown ascending) | Visual |
|---|---|---|---|---|
| demonstrate.1-4 | 2 + 3 | 5 | n/a | objects 2 and 3 |
| demonstrate.5 | 4 + 2 | 6 | n/a | number line 4, jump 2 |
| guided.1 | 3 + 1 | 4 | 3 4 5 | objects |
| guided.2 | 5 + 2 | 7 | 6 7 8 | number line |
| practice.1 | 1 + 2 | 3 | 2 3 4 | objects |
| practice.2 | 3 + 3 | 6 | 5 6 7 | objects |
| practice.3 | 3 + 4 | 7 | 6 7 8 | number line |
| practice.4 | 5 + 4 | 9 | 8 9 10 | none |
| check.1 | 5 + 3 | 8 | 7 8 9 | objects |
| check.2 | 6 + 3 | 9 | 8 9 10 | number line |
| check.3 | 8 + 2 | 10 | 8 9 10 | none |
| remediation explain | 6 + 2 | 8 | n/a | objects, then number line |
| remediation_guided.1 / .2 | 4 + 1 / 2 + 7 | 5 / 9 | 4 5 6 / 8 9 10 | objects / number line |
| remediation_check.1 / .2 / .3 | 1 + 6 / 4 + 4 / 6 + 4 | 7 / 8 / 10 | 6 7 8 / 7 8 9 / 8 9 10 | objects / number line / none |

Verified correct: all answer keys; all distractors wrong; nothing exceeds ten; every operand pair is unique (no repeat, no commuted repeat); check pairs (5+3, 6+3, 8+2) differ from worked examples (2+3, 4+2, 6+2) and from all guided/practice pairs; difficulty rises 1,1,1,2,2,3 then check 2,2,3; order is objects -> number line -> symbolic within practice and check; object counts in each step text match `groups`/`revealCount` (2 shown then 3 more then 5 counted); number-line hops are correct (4->5,6; 5->6,7; 2->3..9 is seven hops; all land at or below 10); every explanation's arithmetic is right; every "one of the numbers you started with / too many / close / missing the last hop" feedback is numerically true. The counting-on explanation (hold the first number, count the second group on from it: 6, then 7, 8) is mathematically sound, and level 2 / prerequisite `num-count` match `curriculum.dart` (creator age band = Level 2).

| # | Step / item | Sev | Evidence | Required correction | Owner |
|---|---|---|---|---|---|
| NM-1 | num-add.check.2, practice.3, guided.2, remediation_guided.2, remediation_check.2 | MAJOR | A `numberLine` item is defined by `start` and `jump`; drawing the hops lands on the key. In the check (no hints) the answer is on the screen. The plan has no field to hide the landing point or arcs. Creator's own review note admits "lands on the answer only through jump". | Add a data field (for example `showHops` / `showLanding`) so check items show the line and the start point only; document it for the UI. | content-creator, then ui-creator |
| NM-2 | all 14 option sets | MAJOR | Options are always n-1, n, n+1 in ascending order; the key is the middle value in 12 of 14 items (2 of 3 check items) and the largest in the other 2. "Always pick the middle" passes the check without maths. | Vary distractor patterns (not always +-1; include reversed/addend traps), randomise order, vary key position; state the shuffle policy in the data. | content-creator |
| NM-3 | prerequisite num-add vs num-count | MAJOR | `num-count` counts three stars only (`curriculum.dart` 385-399). num-add needs counting to 9-10, reading a number line 0-10 and hopping on it, and the "+" / "=" notation; none are taught before. The number line is demonstrated once (demonstrate.5) before it is asked in guided.2. The plan does not teach before it asks for these. | Add a counting-to-10 / number-line introduction (or prerequisite) and a second number-line demonstration before guided.2. | educator, content-creator |
| NM-4 | practice.4, check.3, remediation_check.3 | MAJOR | The symbolic items (5+4, 8+2, 6+4) have no visual and no bridge step; the only strategy taught in the main path is count-all (objects) and number-line hops. The count-on strategy appears only in remediation. 8+2=10 and 6+4=10 depend on number bonds to ten, which are never taught. Concrete -> pictorial -> symbolic is complete in order but the last jump has no scaffold. | Add a bridging step showing the equation with the objects/line, teach counting on (or the make-ten idea) in the main demonstration, then ask symbolic items. | educator, content-creator |
| NM-5 | guided.1 hint 2, remediation_guided.1 hint 2 | MINOR | "Count on 1 more" uses a term that the main path never introduces (only remediation does). | Introduce it in demonstrate, or reword. | content-creator |
| NM-6 | num-add.check.2 | MINOR | Prompt "6 + 3 = ? Start at 6 and hop 3" tells the strategy; this is guided-style, not an independent check. | Check items should not carry strategy instructions. | content-creator |
| NM-7 | visual spec (`revealCount`, `countAll`, `result`, `groups`) | MINOR | Meaning is not documented: is revealCount a group count or an object count? What does countAll do (numbering, highlight)? What does `result` draw? Both groups use the same emoji, so how are the groups visually separated? remediation_explain.1 says "6 apples" with groups [6,2] and revealCount 1. | Provide a field-level schema; ui-verifier to check render. | content-creator, ui-creator |
| NM-8 | objects emoji | MINOR | Introduce shows the blue crystal artwork (num_crystal.webp) but the objects are the white-diamond emoji; 🪐 needs Unicode 12 font support on the emulator/device. Rendering unverified. | Use bundled artwork or confirm emoji rendering on target devices. | ui-verifier |
| NM-9 | feedback text | MINOR | "Count each one only once" is attached to overshoot answers of symbolic and number-line items (practice.4, check.3, remediation_check.3), where there is nothing to count. | Use item-appropriate feedback. | content-creator |
| NM-10 | `prerequisite` field | MINOR | The plan uses a singular string; `curriculum.dart` uses a list `prerequisites`. | Align the schema. | content-creator |
| NM-11 | remediation_check.1 (1+6), remediation_guided.2 (2+7) | MINOR | The counting-on method taught ("count on from the first number") is slow when a small number comes first; commutativity / start from the larger number is not taught. Mathematically valid but pedagogically unexamined. | Educator to decide. | educator |

### 3.6 Cross-cutting

| # | Scope | Sev | Evidence | Required correction | Owner |
|---|---|---|---|---|---|
| X-1 | all 5 lessons | MAJOR | `mastery` holds only `check_total: 3` and `check_pass: 2` (data fields: good). There is no data for the remediation check pass mark, number of remediation cycles, or what happens if remediation also fails. Remediation checks mostly re-ask the same items. Rule: failed mastery needs different examples and support, not endless repeats. | Add remediation thresholds/limits and an exit path (for example parent/teacher flag) as data. | content-creator |
| X-2 | 4 language lessons | MINOR | Only three picture words per language lesson, so 23-24 steps carry three facts; checks and remediation reuse the same three words. Acceptable for a PILOT (these are the only existing picture words and the plan invents none), but not acceptable for rollout. A 2/3 pass on 3 questions is a weak signal. | Flag as a pilot limitation; require more words/pictures (human-approved) before rollout. | product owner, educator |
| X-3 | all `visual: none` items | MINOR | Listening items (visual none) are answerable only through TTS; no fallback if audio fails. Several check items depend on it. | Provide a replay and a visual fallback in the spec. | ui-creator |
| X-4 | check.3 / check.1 option pictures | MINOR | guided.1 / practice.3 / practice.4 have `optionPictures`; check.1 / check.3 do not, so a pre-reading child sees text-only options where the original lesson used picture answers. | State the rule for when option pictures are shown. | ui-creator |
| X-5 | schema | MINOR | No schema document exists in the repo; the allowed visual set (none, glyph, picture, letterWord, objects, numberLine) is satisfied (checker: 0 violations) but field meanings are undocumented. | Write the schema. | content-creator |

## 4. Teaching-first coverage

Present in every lesson: introduce (2), demonstrate (4-5), guided (2, hints = 2-rung ladder), practice (4, difficulty 1,1,2,3), check (3, no hints), remediation (explain 3, guided 2, check 3). No ids are duplicated (117/117). Thresholds are data fields. No check item leaks the answer in a prompt or wrong_feedback; the only answer leaks are the picture captions (EN-1, TE-1, HI-1, TA-1) and the number-line hops (NM-1). Remediation uses a different explanation only in num-add (count-on versus count-all, with objects and a line); in the four language lessons it is the same explanation reordered (EN-4, TE-3, HI-3, TA-3). Check distinctness fails in the four language lessons (EN-2 etc.) and passes in num-add. The plan does not teach before asking for the symbolic and number-line rungs of num-add (NM-3, NM-4).

## 5. Schema / UI-readiness

Every visual type used is in the allowed set and all file paths exist. Items a UI could not render unambiguously without a spec: `objects` (revealCount/countAll/result, NM-7), `numberLine` (landing/hops, NM-1), `letterWord` with Latin "A" versus the plan's `glyph "A a"` string (two glyphs in one field), `visual: none` with audio-only stimulus (X-3), `optionPictures` presence rules (X-4). No code reads this file today, so nothing has been seen on screen; UI is not verified.

## 6. UNVERIFIED (nothing below may be called verified)

- All Telugu, Hindi and Tamil sentences (grammar, naturalness, register, age suitability) - native-speaker review needed (TE-6, HI-6, HI-7, TA-6, TA-7).
- All text-to-speech output in every locale: en-US reading of "A.", te-IN / hi-IN / ta-IN reading of lone vowels and sentences, en-IN number words (EN-6; no audio was heard).
- Letter name versus sound, and vowel length, for అ / अ / அ / A as spoken.
- Whether pictures are the best images for young children (te_amma / ta_mother show two people).
- Emoji rendering of 💎 ⭐ 🪐 🚀 🍎 🍓 🌙 on the target device; number-line and object rendering (no UI exists).
- Educator review of the maths progression, strategy teaching and pass marks (2 of 3).
- Stroke order / tracing: no claims are made in the plan (grep 0 hits), so nothing to verify.

## 7. Overall status

OVERALL: REVISE. All five lessons go back to content-creator (educator input for NM-3, NM-4, EN-3, EN-4 and the remediation design). Mathematics is arithmetically correct throughout; the problems are teaching design, answer exposure and guessability. Languages are linguistically correct as far as a non-native can confirm (words, letters, first-letter claims, picture matches) but have answer-exposure and weak-check problems, and the three Indic lessons are gated on native-speaker review. Nothing here is educator-verified, native-verified, audio-verified or UI-verified. Do not proceed to ui-creator for the language lessons until REVISE items are fixed; num-add needs NM-1 before UI work, as it affects the data schema.

Finding counts: en-a 8, te-a 7, hi-a 7, ta-a 7, num-add 11, cross-cutting 5 = 45 total (MAJOR 18 including X-1; MINOR 23 including the UNVERIFIED-minor items; 3 native-review GATE items; 1 INFO; 0 BLOCKER).


---

# Round 2 (re-verification of the revised plan)

Date: 2026-10-31. Subject: revised `content/teaching/pilot_teaching_plans.json` and new `content/teaching/SCHEMA.md`. Judged independently against `lib/src/curriculum.dart`; neither `PILOT_CONTENT_SPECS.md` nor the creator's checker was used. Only this report was written to.

## R2.1 What I ran

- New checker, written from scratch: `C:\Users\aravi\AppData\Local\Temp\claude\C--Users-aravi-OneDrive-Desktop-Claude\761260ff-07ea-4616-8488-8f450c083a38\scratchpad\verify_r2.py` (`python -X utf8 -I verify_r2.py`, output `...\scratchpad\r2_out.txt`). Plus `dump.py`, which dumped every step and question to `...\scratchpad\dump.txt`; I read that dump in full (all five lessons: text, hints, feedback, review notes).
- Automated result: 0 findings. Ids 117/117 unique; every visual type and field is in the allowed set and in SCHEMA.md; all assets exist; every key is in its options; wrong_feedback keys equal the distractors; no check or remediation-check item has hints; no check/remediation-check picture has a caption; no check objects visual has `result` or `showResult` true; every check/remediation-check `numberLine` has `showHops: false`; all five lessons carry `check_total, check_pass, remediation_pass, max_remediation_cycles (2), after_limit ("offer_parent_support")`; title, locale, words and picture paths of en-a/te-a/hi-a/ta-a equal curriculum.dart; no check item exactly repeats a guided/practice item (answer + option set + prompt).
- Maths re-solved: all 14 questions (prompt, visual and speech operands agree; keys correct; every distractor wrong; all sums and options <= 10; explanation arithmetic right; "one of the numbers you started with" and "too many" feedback numerically true). Worked examples: 2+3 (objects), 4+2 and 6+2 (counting on). Every pair is used once (no worked-example reuse, no commuted repeats): guided 3+1, 5+2; practice 1+2, 3+3, 3+4, 5+4; check 5+3, 6+3, 7+2; remediation 4+1, 8+1, 6+1, 4+4, 7+1.
- Option patterns now: key rank among sorted options is the middle in 8 of 14 and the top in 6 of 14; stored order is mixed (key at stored position 1/2/3: 2/7/5 times). Distractors vary (a starting number, a near miss, a distant number). Check key positions are 2, 1, 3.
- Teaching order in num-add is now: introduce.1 counts 10 objects, introduce.2 the 0-10 number line (no hops), demonstrate.2 the + sign, demonstrate.4 the = sign with 2 + 3 = 5, demonstrate.5 counting on along the number line; then guided (objects; number line with hops), practice (objects, objects, number line without hops, symbolic), check (objects, number line without hops, symbolic). Make-ten facts (8+2, 6+4) were removed, so every sum is solvable by counting on, which is taught before it is asked.

Not run: no audio, no rendering (no UI reads the file), no native speaker.

## R2.2 Disposition of the 45 Round 1 findings

FIXED = 31, OPEN = 14. Native-speaker items stay UNVERIFIED even where wording was changed.

| Round 1 id | Status | Evidence |
|---|---|---|
| EN-1, TE-1, HI-1, TA-1 | FIXED | Question pictures in practice, check and remediation-check use `caption: ""`; checker found no caption on any check picture. |
| EN-2, TE-2, HI-2, TA-2 | FIXED | Check is now (1) listen to a word, pick its first letter (lowercase for English), (2) "which word does NOT begin with the letter", (3) uncaptioned picture naming. None repeats a guided/practice item. See new N-1. |
| EN-3 | FIXED | practice.1 (small a to big letter) and check.1 (listen to Apple, pick small letter a) test lowercase. |
| EN-4, TE-3, HI-3, TA-3 | FIXED (structure) | Remediation explanation is a different, sound-first method (eyes closed, listen, "first sound is the sound of the letter", yes/no by ear, one picture at the end), not the demonstrate steps reordered. Sub-point N-3; wording UNVERIFIED for the Indic languages. |
| EN-5 | FIXED | Hint 1 never contains the answer; practice items now have 2 hints; check items none. |
| EN-6 | OPEN, UNVERIFIED | TTS of a bare "A." and letter name vs sound still unheard. |
| EN-7, TE-4, HI-4, TA-4 | FIXED | "Listen again" only where audio plays ("That is not what you heard"); picture items say "look again". |
| EN-8, TE-5, HI-5, TA-5 | OPEN (MINOR) | check.3 (picture naming) still does not test the letter objective; check.1 and check.2 now do, so this is a minor balance point. |
| TE-6, HI-7, TA-7 | OPEN, GATE (UNVERIFIED) | Every Telugu, Hindi and Tamil sentence still needs native review and TTS listening. |
| TE-7 | OPEN, INFO | Product decision on telugu-recognise-001 still pending. |
| HI-6 | FIXED, wording UNVERIFIED | "whose picture" wording replaced by "इस चित्र में क्या है?". Native confirmation needed. |
| TA-6 | FIXED, wording UNVERIFIED | Sandhi now written "எழுத்தைக் கவனமாகப்" and "... என்ற சொல்லைக் கேட்டீர்கள்". The corrections and the new words for sound (ஒலி), "does not begin" (தொடங்காத) etc. need native confirmation. |
| NM-1 | FIXED | showHops false on practice.3, check.2, remediation_check.2; true only on teaching and guided items; documented in SCHEMA.md. |
| NM-2 | FIXED | See option patterns above. |
| NM-3 | FIXED in the plan | Counting to 10, number line, +, = and counting on are taught inside the lesson before they are asked. num-count still counts to three; the plan asks the educator to decide whether the prerequisite should change. |
| NM-4 | OPEN (MINOR, residual) | Make-ten removed, equation step added; counting on is still shown with hops on the number line only (not with objects), and symbolic items 5+4, 7+2, 7+1 rely on the hint ladder for the strategy. Educator to confirm. |
| NM-5 | FIXED | "Count on" is introduced in demonstrate.5 before any hint uses it. |
| NM-6 | FIXED | check.2 prompt is "6 + 3 = ?" with no strategy instruction. |
| NM-7 | FIXED (data side) | SCHEMA.md defines revealCount (groups), countAll, result/showResult, showHops. A UI must still implement them. |
| NM-8 | OPEN (MINOR) | Emoji rendering unverified on device; the crystal artwork is no longer used, so the artwork/emoji mismatch is gone. |
| NM-9 | FIXED | Overshoot feedback no longer says "count each one" on symbolic items. |
| NM-10 | FIXED | `prerequisites: ["num-count"]` is a list like curriculum.dart. |
| NM-11 | FIXED | Remediation pairs changed; small-plus-large counting-on problem gone. |
| X-1 | FIXED | All five lessons have remediation_pass, max_remediation_cycles, after_limit as data. |
| X-2 | OPEN, accepted for the pilot only | Still three picture words per language lesson; stated as a pilot limitation. Not acceptable for rollout. |
| X-3 | OPEN (MINOR, UI) | Audio-only items noted as needing replay and a visual fallback; SCHEMA.md does not specify it. |
| X-4 | OPEN (MINOR, UI) | SCHEMA.md does not say when `optionPictures` are shown versus text only. |
| X-5 | FIXED | `content/teaching/SCHEMA.md` exists and matches the fields used. |

## R2.3 New findings from the rewrite

| # | Item | Sev | Evidence | Required correction | Owner |
|---|---|---|---|---|---|
| N-1 | en-a/te-a/hi-a/ta-a check.2 (and remediation_guided.1) | MAJOR | The negative format "which word does NOT begin with ..." first appears in the mastery check (difficulty 3) and in remediation; it is never practised in guided or practice, so the check tests an untaught format. It has two options, so it is a 50% guess. | Teach/practise the negative format earlier (add a guided or practice item) or replace it in check with a taught format. | content-creator, educator |
| N-2 | all language check sets | MINOR | Check items 1 and 2 have two options. Chance of passing 2 of 3 by guessing: English 33%, Telugu/Hindi/Tamil 42% (maths, three options: 26%). Thresholds are data, so adjustable. | Before rollout use more check items or a higher mark. | educator |
| N-3 | language remediation_explain.1-2 | MINOR | Two of three explanation steps have `visual: none`: the child sees an empty step while the teaching is audio-only. | Give these steps a visual (the glyph, or a speaking-icon spec). | content-creator, ui-creator |
| N-4 | en-a.check.2, en-a.remediation_guided.1 | MINOR | Explanation says "This picture is Ball/Cat" but the item shows a glyph with option pictures. | Reword. | content-creator |
| N-5 | num-add.remediation_guided.2 | MINOR | Text says "Count on 1 steps" (hint 1 and explanation); introduce.1 draws a single group with the "+" operator. | Fix plurals; document single-group display. | content-creator |
| N-6 | num-add remediation | MINOR | Four of five remediation sums are "+1" facts (4+1, 8+1, 6+1, 7+1): narrow practice after a failed check. | Educator to widen. | educator |
| N-7 | num-add.guided.2, remediation_guided.2 | MINOR | Overshoot distractors (8 for 5+2, 10 for 8+1) get "the number you start on is not a hop", which diagnoses an undercount, not an overshoot. | Reword the overshoot feedback. | content-creator |

## R2.4 Round 2 verdicts

"PASS" here only means content structure and arithmetic are OK for a UI build. It is not native-speaker, educator, audio or UI verification.

| Lesson | Verdict | Open MAJOR | Open MINOR | Gate / info | Notes |
|---|---|---|---|---|---|
| en-a | REVISE | 1 (N-1) | EN-6 (unverified), EN-8, N-2, N-3, N-4 | | One small fix: the negative format. Otherwise structurally sound. |
| te-a | REVISE | 1 (N-1) | TE-5, N-2, N-3 | TE-6 gate, TE-7 info | Telugu text UNVERIFIED. |
| hi-a | REVISE | 1 (N-1) | HI-5, N-2, N-3 | HI-7 gate | Hindi text UNVERIFIED. |
| ta-a | REVISE | 1 (N-1) | TA-5, N-2, N-3 | TA-7 gate | Tamil text UNVERIFIED. |
| num-add | PASS (structure and arithmetic OK for UI build) | 0 | NM-4, NM-8, N-2 (26%), N-5, N-6, N-7 | | Educator review of progression, prerequisite decision and pass marks still required; emoji rendering unverified. |

Still open for ui-creator: X-2 (pilot-only word count), X-3, X-4. The UI must implement `revealCount, countAll, result, showResult, showHops`, empty `caption`, audio-only items with replay/fallback, and the mastery fields.

Round 2 counts: of the 45 original findings, 31 FIXED and 14 OPEN (3 native-review gates, 1 info, 1 UNVERIFIED audio item, 9 minor or pilot-accepted items). New findings: 7 (1 MAJOR present in four lessons, 6 MINOR).

Overall Round 2 status: num-add PASS for UI build; en-a, te-a, hi-a, ta-a REVISE (one shared fix, N-1). Nothing in this plan is native-verified, educator-verified, audio-verified or UI-verified.


---

# Round 3 (re-verification after the N-1 fix)

Date: 2026-10-31. Subject: `content/teaching/pilot_teaching_plans.json` (revised again) and `content/teaching/SCHEMA.md` (new optional per-question `task` field). Judged independently against `lib/src/curriculum.dart`. Only this report was written to.

## R3.1 What I ran

- Re-ran my Round 2 checker unchanged (`...\scratchpad\verify_r3.py`, output `r3_out.txt`): 0 findings. It re-confirms: 117 unique ids (now more, none duplicated), allowed visual types/fields, assets exist, keys in options, wrong_feedback keys, no hints on check items, no captions on check pictures, no `result`/`showResult` on check objects, `showHops` false on every check number line, mastery fields in all five lessons, all language titles/locales/words/pictures equal curriculum.dart, all maths keys correct, distractors wrong, sums <= 10, pairs not reused.
- New checker `...\scratchpad\r3x.py` (output `r3x_out.txt`), plus a fresh dump of all text (`dump.txt`) which I read for en-a, te-a (all items), and the maths feedback. It tabulates, per language lesson: task type, visual, option count, hints, captions, and flags: check task not taught earlier in guided/practice, `not_word` in any check, fewer than 3 options in any check, check vs remediation-check near duplicates, check repeating a guided/practice item (task + answer + option set), hint 1 containing the answer, caption leaks, hint ladders under 2, key position.
- Not run: audio, rendering, native speaker.

## R3.2 N-1 and the Round 2 minors

| Round 2 id | Status | Evidence |
|---|---|---|
| N-1 (negative format untaught in check) | FIXED | `not_word` is taught in demonstrate.5 (all four languages: "puzzle: which word does NOT begin with ...; the other begins with it; this one is the odd one out"), used in guided.3 and practice.5 (2 options each, different answers: en Ball then Cat; te ఇల్లు then ఏనుగు), and in remediation_guided.1. Checker: `not_word` appears in no check or remediation check; every check and remediation-check task type also appears earlier in guided/practice; every check item has 3 options. SCHEMA.md documents `task` and the rule. |
| N-2 (guess pass chance) | FIXED to the maths level | All language checks now have 3 options each: about 26% blind chance to pass 2 of 3 (same as maths). Thresholds remain data; more items still advisable before rollout. |
| N-3 (remediation explain steps blank) | FIXED | All three remediation explain steps in every language lesson now have a picture; the first two use `caption: ""`, the last captions the target word. |
| N-4 (en "This picture is ..." with no picture) | FIXED | English explanations for the not_word items now read "Ball does not begin with A. It is a different letter." |
| N-5 ("Count on 1 steps") | FIXED | Now "1 step" in hints and explanation. |
| N-6 (remediation sums mostly +1) | PARTLY FIXED, MINOR open | remediation_guided.1 is now 2+2; remediation sums are 2+2, 8+1, 6+1, 4+4, 7+1 (three of five still +1). Educator choice. |
| N-7 (overshoot feedback mis-diagnosis) | FIXED | Overshoot answers now get "that is one step too far. Stop when you have counted all the steps."; the undercount answer (check.2, 8 for 6+3) gets "The number you start on is not a step." Both diagnoses are now correct. |

Earlier open items (EN-6 audio, EN-8/TE-5/HI-5/TA-5 check.3 balance, TE-6/HI-7/TA-7 native gates, TE-7 info, NM-4, NM-8, X-2, X-3, X-4) are unchanged and remain open as listed in Round 2; none of them is settled by anything in this plan.

## R3.3 New observations from the changes (all MINOR, none blocks a pilot UI build)

| # | Item | Sev | Evidence | Suggested correction | Owner |
|---|---|---|---|---|---|
| R3-1 | en-a.check.2, te/hi/ta check.2, te/hi/ta check.1, remediation_check.1 (all four) | MINOR (pilot limitation) | With three picture words, some check items repeat an earlier item in task, answer and option set: check.2 (pick_word) equals guided.1 and practice.4; Telugu/Hindi/Tamil check.1 (word to letter) equals practice.1 with audio instead of a picture; remediation_check.1 is the same item as check.2 in all four languages (same task, answer, options; only the prompt wording and glyph differ). English check.1 (lowercase) is genuinely different. A child can pass by memory. | Needs more approved picture words before rollout (X-2); for the pilot, vary the answer words across check and remediation check where possible. | educator, product owner |
| R3-2 | check key position | MINOR | Stored option order: English check keys are all at stored position 2; Telugu/Hindi/Tamil at 3, 2, 2. SCHEMA says the UI "may" shuffle. If it does not, "pick the middle" passes. | Make shuffling mandatory in the schema or vary stored positions. | content-creator, ui-creator |
| R3-3 | demonstrate.5 (all four languages) | MINOR | The step says "Apple does begin with A, Cat does not" but its visual is one picture (Cat / ఏనుగు / कमल... only the not-word). | Show both pictures or use a two-picture visual. | content-creator |
| R3-4 | num-add remediation | MINOR | See N-6. | Educator. | educator |

## R3.4 Round 3 verdicts

PASS here = structure, arithmetic and language-item correctness are fine for a UI build and for a pilot. It is NOT native-speaker, educator, audio or UI verification; those items are listed as UNVERIFIED below and are not held against the lessons.

| Lesson | Verdict | Open MAJOR | Open MINOR (incl. earlier) | Left UNVERIFIED |
|---|---|---|---|---|
| en-a | PASS | 0 | EN-8, R3-1, R3-2, R3-3 | TTS of bare "A." and letter name vs sound (EN-6); educator review of wording and item mix |
| te-a | PASS | 0 | TE-5, R3-1, R3-2, R3-3 | All Telugu sentences incl. మొదలవుతుంది / మొదలవదు / మొదలవని, శబ్దం, "పజిల్"... (TE-6); TTS; TE-7 product decision (info) |
| hi-a | PASS | 0 | HI-5, R3-1, R3-2, R3-3 | All Hindi sentences incl. the new puzzle wording (HI-7); TTS |
| ta-a | PASS | 0 | TA-5, R3-1, R3-2, R3-3 | All Tamil sentences incl. sandhi corrections, ஒலி, தொடங்காத (TA-7); TTS |
| num-add | PASS | 0 | NM-4, NM-8, N-6 | Educator review of progression, the num-count prerequisite decision and pass marks; emoji rendering; TTS |

Still open for ui-creator: implement `revealCount, countAll, result, showResult, showHops`, empty `caption`, per-question `task`, mandatory option shuffling (R3-2), replay and a visual fallback for audio-only items (X-3), and a rule for `optionPictures` (X-4). Pilot limitation X-2 (only three picture words per language lesson) must be lifted before rollout.

## R3.5 Counts

- Round 2 findings: 7 total; 6 FIXED (N-1 major, N-2, N-3, N-4, N-5, N-7), 1 partly fixed and open as MINOR (N-6).
- Original 45 findings: unchanged since Round 2 (31 fixed, 14 open).
- New in Round 3: 4 MINOR (R3-1 to R3-4; R3-4 is the same item as N-6, so 3 distinct new).
- Currently open: 0 MAJOR; 0 BLOCKER; 14 earlier open items (3 native gates, 1 info, 1 unverified audio, 9 minor / pilot-accepted) + N-6 + R3-1, R3-2, R3-3 = 18 items, all MINOR, UNVERIFIED, INFO or GATE.
- Verdicts: en-a PASS, te-a PASS, hi-a PASS, ta-a PASS, num-add PASS. Nothing in the plan is native-verified, educator-verified, audio-verified or UI-verified.


---

# Rollout R2 - Level 1 letter lessons (`content/teaching/rollout_letters.json`)

Date: 2026-10-31. Subject: 149 plans (English 25, Telugu 50, Hindi 45, Tamil 29), status `rollout_unverified`. Judged against the ORIGINAL code, not `audit/ROLLOUT_R2_LETTERS_SPECS.md`: `lib/src/curriculum.dart` (the four `_recognitionSequence` lists, challenge text, locale, ids, prerequisites) and `lib/src/alphabet/alphabet_data.dart` (the only letter-to-picture-word table). Only this report was written to.

## RR.1 What I ran

- Checker written from scratch: `C:\Users\aravi\AppData\Local\Temp\claude\C--Users-aravi-OneDrive-Desktop-Claude\761260ff-07ea-4616-8488-8f450c083a38\scratchpad\verify_rollout.py` (`python -X utf8 -I`, output `ro_out.txt`). It parses the Dart sources itself (recognition targets and the picture table, asserting that the table order equals the recognition order), then checks every plan. Helper scripts: `ro_stats.py`, `ro_more.py`, `ro_more2.py` (same folder), plus a text dump `ro_sample.txt` (34 lessons, 442 lines) that I read by eye.
- Source parse results (real output): English 26 letters / 26 with word / 25 with picture; Telugu 51 / 14 / 12; Hindi 46 / 14 / 14; Tamil 30 / 16 / 15. 153 source lessons; the plans cover 149, the 4 not planned are the pilot lessons en-a, te-a, hi-a, ta-a.
- Machine checks over ALL 149 plans, with these results: lesson ids unique (149/149) and none collides with a pilot id; 3,874 step ids, all unique; every lesson id, locale, level (1), prerequisite (previous recognition lesson, or the pilot lesson for the second letter) equals the source; every lesson title equals the source challenge text (149/149); the letter is in every objective; mastery fields present in all; allowed visual types only (none, glyph, picture, letterWord); every answer is in its options; wrong_feedback keys equal the distractors; every check and remediation-check item has exactly 3 options (447 check items counted), no hints, no caption, no answer glyph, no negative task; every check task type is taught earlier in guided/practice; no check item has the same prompt, options and visual as an earlier item; guided hint 1 and practice hints never contain the answer (token-aware, so a letter inside a longer word is not a false hit; my first run without this produced thousands of false hits, which I discarded after reading examples); no prompt, wrong_feedback or hint leaks an answer in a check; the heard stimulus (speech tail) is the lesson letter in all 1,297 letter items and a source word beginning with the lesson letter in all 117 word-to-letter items (the 37 other word-to-letter items are picture-based and have no speech tail by design).
- "Begins with" claims, tested against the source table with a grapheme-aware rule (the word must start with the letter and the next character must not be a combining vowel sign, virama, anusvara or visarga; English X excluded by the creator's decision): every `letterWord` step uses the source word and picture for the right letter; every word keyed as "begins with" does start with the letter; no wrong word in a pick-the-word item starts with the letter; every negative picture in a demonstrate step does not start with the letter; no letter_only plan makes any begins-with claim. Only one lesson that the rule would allow was downgraded: ta-letter-004 (ஈ), whose source word is the single letter ஈ itself (see RR-9).
- Option letters in letter items are all letters of the source sequence; the extra "previous letter" is always the prerequisite lesson's letter (112 of 149 lessons use it: 92 letter_only, 20 letter_with_word, 0 words_pictures), never equal to the answer.
- Assets: every path exists except the three listed in RR-1; the three declared lists in `review.assets_missing` equal the real missing paths.
- Variant counts (real output): English 21 words_pictures / 3 letter_with_word / 1 letter_only; Telugu 3 / 7 / 40; Hindi 8 / 5 / 32; Tamil 5 / 5 / 19; total 37 / 20 / 92.
- Eye review (not machine): 34 lessons, at least 3 per language per template where the template exists, plus the special cases: English B, K, W (words_pictures), O, Q (letter_with_word), X (letter_only); Telugu ఆ ఇ ఈ (all 3 words_pictures), ఉ ఓ బ (letter_with_word), ఋ అం అః క్ష (letter_only); Hindi आ ऋ ऐ (words_pictures), ओ क प (letter_with_word), अं अः ह (letter_only); Tamil உ ஊ ஐ (words_pictures), ஆ ஓ ஔ (letter_with_word), ஈ க் ன் (letter_only). I also viewed boat.png, te_five.webp, hi_one.webp, hi_sage.webp.
- Not run: no audio, no rendering, no native speaker.

## RR.2 Findings (numbered)

| # | Scope | Sev | Evidence | Required fix | Owner |
|---|---|---|---|---|---|
| RR-1 | en-letter-017 (Q), te-letter-012 (ఓ), ta-letter-012 (ஔ) | MAJOR (these 3 lessons BLOCKED) | Each lesson uses a picture file that does not exist: `assets/images/quiz/en_queen.webp`, `.../te_boat.webp`, `.../ta_name_0b94.webp`. They are used in introduce.2, demonstrate.2 and remediation_explain.3 (declared honestly in `review.assets_missing`, but a UI loading these lessons would show a broken picture). The source table itself has no picture for these three words. For Telugu ఓడ (boat) the repository already has `assets/images/quiz/boat.png`, which I viewed: a clear boat. The Tamil word ஔவை is a person's name ("a name" in the source), with no obvious picture. | (a) te-letter-012: point the three steps at `assets/images/quiz/boat.png`, or supply te_boat.webp. (b) en-letter-017 and ta-letter-012: either get approved artwork, or change the lesson to variant `letter_only` / no-picture rendering (drop the letterWord and the picture step and the begins-with claim). Until then the UI must not load them. | content-creator, art owner |
| RR-2 | all 92 letter_only lessons (en 1, te 40, hi 32, ta 19) | MAJOR (92 lessons REVISE) | See RR.3. The 3 check items per lesson are all the same task (hear the letter, pick it from 3 letters) and use all 3 of the only possible option sets (letter plus two of {next, next+1, previous}). 276 of 276 check items (en 3/3, te 120/120, hi 96/96, ta 57/57) have the same task, answer and option set as an item already asked in guided or practice, and 276 of 276 remediation-check items repeat a check item's task, answer and option set (only the prompt wording and the position of the options change). In every non-negative item the answer is the lesson's own letter (828 of 828 across the 92 lessons). So the "check" re-asks the practice question and the "remediation check" re-asks the check. | Widen the wrong-option pool to letters already taught earlier in the same alphabet (at least 5 candidates) so that: check option sets differ from each other and from every guided/practice set; remediation-check sets differ from the check; add one spaced-review item in practice and one in check whose answer is the PREVIOUS lesson's letter, so the lesson letter is not always the answer; keep 3 options, no hints, no negative task in checks. | content-creator, educator |
| RR-3 | 20 letter_with_word, 37 words_pictures | MINOR (carry-over of pilot R3-1; PASS accepted for a first version) | letter_with_word: 40 of 60 check items and 20 of 60 remediation-check items repeat an earlier task+answer+option set (the heard-word item is the one independent check item). words_pictures: with only three picture words per letter, 53 of 111 check items share task, answer and option set with a guided or practice item; the 3 check plus 3 remediation-check items of a lesson use only 2 or 3 distinct option sets (16 lessons: 2, 21 lessons: 3). | Apply the RR-2 distractor widening to these templates too when words/pictures are added. | educator |
| RR-4 | hi-letter-006 check.3, hi-letter-007 practice.2, hi-letter-008 practice.1, ta-letter-007 check.3, ta-letter-008 practice.2, ta-letter-009 practice.1 | MINOR | "What is this picture?" with `hi_one.webp` (one apple) or `te_five.webp` (five apples) keyed to एक / ஐந்து: a child may name the apples or count them, so the key is ambiguous. | Do not use the number pictures in name-the-picture items (two are check items); use only as a teaching picture with caption. | content-creator, educator |
| RR-5 | 37 words_pictures lessons, demonstrate.5 | MINOR (carry-over of pilot R3-3) | The puzzle step talks about two words but shows only the wrong word's picture. | Show both pictures. | content-creator |
| RR-6 | all 149 plans | INFO | Titles are copied from the source and are the same sentence in every lesson of a language ("Which letter is this?", "ఈ అక్షరం ఏది?", ...). Faithful to the source, but the lessons are not distinguishable by title. | UI should show the letter; no content change. | ui-creator |
| RR-7 | the "previous letter as extra wrong option" decision | judged OK | It is always the prerequisite lesson's letter (already taught, from the source alphabet), never equals the answer, adds no new vocabulary or picture, and never produces a letter the keyed word also starts with (checked). Its benefit is small: it only lifts the pool from 3 to 4 letters, which is why RR-2 still fails. At the ends of each alphabet the neighbours wrap round to the first letters (as in the source), which is harmless. | Keep, but widen the pool (RR-2). | |
| RR-8 | English X (en-letter-024) | judged OK | Source word Xylophone starts with the sound "z"; the creator teaches X letter-only and makes no begins-with claim. Xylophone is still used correctly as a wrong word in the W lesson (it does not begin with W). The Y/Z lessons are unaffected. | none (educator may later add a picture word for X with an "x-ray"-style word). | educator |
| RR-9 | Tamil pure consonants (13 lessons க் ... ன், letter_only), ta-letter-004 (ஈ), Telugu ఋ ఱ క్ష అం అః, Hindi ऋ ङ ञ अं अः | UNVERIFIED (educator) | The Tamil source lists pure consonants (க், ங் ...) as Level 1 letters; their source words (கல், நாய், பூனை, மரம்) begin with the vowel-bearing letter, so the creator rightly made no begins-with claim. Whether these belong in a Level 1 recognition set, and whether ஈ should be taught with its fly picture (the word is the letter itself), is a pedagogy call. | Educator decision. | educator |
| RR-10 | all letter_only and most letter_with_word lessons | UNVERIFIED (audio) | The whole lesson depends on how TTS speaks a bare letter: ఋ, అం, అః, క్ష, ఱ, ఙ, ञ, ङ, अं, अः, Tamil pure consonants (க், ங் ...), English "O." / "A." / "I.". If the voice reads a letter name inconsistently, the lessons teach the wrong sound. | Native/audio listening test before children use these lessons. | native reviewer, audio |
| RR-11 | all Telugu, Hindi, Tamil text | UNVERIFIED (native) | Same as the pilot: every sentence is AI-written. Read by eye and sensible to a non-native, with these points for a native speaker: Telugu "ఉడుత ని నెమ్మదిగా చెప్పండి" (case ending spaced), "ఈ శబ్దం ఇచ్చే అక్షరం ఏమిటి?", "తాకండి"; Hindi "जो अक्षर तुमने सुना, उसे छुओ", "बचा हुआ अक्षर"; Tamil "கேட்ட எழுத்தைத் தொடுங்கள்", "ஒலி", "மீதமுள்ளதே"; Telugu letters that are also ordinary words (ఈ this, ఆ that, ఏ which): the creator reworded the prompts of the lessons whose options contain them ("ఇక్కడి అక్షరం ఏది?"), which is correct in intent but not native-confirmed; negative prompts "which letter is NOT X". | Native review; no content change needed from me. | native reviewers |
| RR-12 | all plans | UNVERIFIED | `native_review_needed` is true on all 149 (English included, for educator review). Nothing here is educator-, audio- or UI-verified; no UI reads the new `variant` field or the `not_letter` task. | ui-creator to implement `variant`, `not_letter`, empty captions, `showHops` etc. | ui-creator |

## RR.3 Do the letter_only lessons satisfy teach -> demonstrate -> guided -> practice -> check -> remediation?

Honest answer: structurally yes, as teaching no, not yet.

What is there: introduce (shows the letter and says it), demonstrate (names two other letters as "not this one", a three-letter puzzle), guided (look-and-match, listen-and-pick, "which letter is NOT ..." with hint ladders), practice (4 listen-and-pick items with different wording, plus one negative item, hints that never reveal), check (3 items, 3 options, no hints), and a remediation that is genuinely different (sound-first, then the shape beside a neighbour, then recall) with its own guided and check items and a capped cycle count. Every stage exists and has a different purpose, the check contains no task that was not taught, and nothing leaks.

What is wrong: a recognition lesson needs the child to show, at the end, that they can recognise the letter in a situation they have not just practised. Here that does not happen. The lesson's letter is the answer in every non-negative item (828 of 828), the only stimulus is "hear the letter, pick it", the distractor pool is 4 letters so there are only 3 possible option sets (RR-2), and all 276 check items already appeared as practice items in task, answer and option set. A child who can do the practice has simply done the check; a child who fails the check is then given the same items again after remediation. That is the "endless identical questions" the rules forbid, and it means the check measures memory of the last few screens, not recognition. There is also no meaning anchor (no word, no picture) for these letters, which is a limit of the source data, not of the plan.

What must change (RR-2, exact): widen the distractors to earlier-taught letters; make check and remediation-check option sets new; add spaced-review items whose answer is the previous letter; keep everything else. This is a change to the generator and the data, not a rewrite. After that I would pass letter_only for use as a first version, with the audio gate (RR-10) still open.

## RR.4 Verdicts

PASS here = structure, source fidelity and language-item correctness fine for the UI to load and for a first version; native, educator and audio items stay UNVERIFIED and are not held against any lesson.

By template:

| Template | Lessons | Verdict | Reason |
|---|---|---|---|
| words_pictures | 37 | PASS | Approved pilot structure; only carried-over MINORs (RR-3, RR-4, RR-5). |
| letter_with_word | 20 | PASS, except te-letter-012, ta-letter-012 and en-letter-017 (BLOCKED, RR-1) | One of three check items is independent; the rest is the RR-2 limitation at minor weight. |
| letter_only | 92 | REVISE | RR-2. |

By language (lesson counts):

| Language | PASS | REVISE | BLOCKED | Language verdict |
|---|---|---|---|---|
| English (25) | 23 (21 words_pictures + O, P) | 1 (en-letter-024, X) | 1 (en-letter-017, Q) | PASS except the two |
| Telugu (50) | 9 (3 words_pictures + 6 letter_with_word) | 40 (letter_only) | 1 (te-letter-012) | REVISE |
| Hindi (45) | 13 (8 + 5) | 32 (letter_only) | 0 | REVISE |
| Tamil (29) | 9 (5 + 4) | 19 (letter_only) | 1 (ta-letter-012) | REVISE |
| Total (149) | 54 | 92 | 3 | |

Note: the English count is 21 + 2 = 23 PASS, 1 REVISE, 1 BLOCKED = 25.

## RR.5 Counts

- Findings: 12 numbered: 2 MAJOR (RR-1, RR-2); 3 MINOR (RR-3, RR-4, RR-5); 4 UNVERIFIED (RR-9 educator, RR-10 audio, RR-11 native, RR-12 whole batch); 1 INFO (RR-6); 2 judged OK (RR-7, RR-8).
- Lessons: 54 PASS, 92 REVISE, 3 BLOCKED.
- Checked clean (0 findings in 149 plans): ids, source fidelity (id, title, level, locale, prerequisites), answers in options, 3-option checks without hints, check tasks taught earlier, leaks via caption, glyph, hint, prompt and feedback, begins-with claims, option letters from the source.
- Required to reach PASS everywhere: RR-1 (three assets or plan changes) and RR-2 (generator change to the option pool and spaced-review items); RR-3 to RR-5 can follow.
- Nothing in this batch is native-verified, educator-verified, audio-verified or UI-verified.


---

# Rollout R1 - Number Galaxy (`content/teaching_pending/rollout_numbers.json`)

Date: 2026-10-31. Subject: 72 plans (numbers-count-000..010, numbers-56-001..054, and legacy num-count, num-names, num-subtract, num-multiply, num-divide, num-fraction, num-percent; num-add is in the pilot). Judged against the ORIGINAL sources: `content/age56/numbers_age_5_6.json`, `lib/src/curriculum.dart`, `lib/src/batch/batch_content.dart`, `content/pack_v2/content/numbers.json`, not against `audit/ROLLOUT_R1_NUMBERS_SPECS.md`. Only this report was written to.

## RN.1 What I ran

- My own solver `...\scratchpad\verify_numbers.py` (`python -X utf8 -I`, output `num_out.txt`), independent of the generator and of the creator's checker. It re-solves every question from the prompt, the visual (group counts, number-line start and jump, objects operator) and the options. Tasks solved: add (objects, line, symbolic, ones-first, make-ten bond), subtract (objects, line, symbolic, addition-fact check), tens and ones (picture and symbol, build), compare (sign, bigger, smaller, compare of three), patterns (next, missing, rule), counting (objects, line, zero stories), number names, shapes (name, sides, corners, property), multiplication (groups, repeated addition, times, story), division (share, bags, symbol, story), halves (set, story, symbol, split), percent (set, story, symbol, fraction match), longer (clip counts), time-of-day order. Text-only answers (time of day, units, pay-with, word-pick, how-compare, picture-longer) I judged by eye.
- Real results: 72 lessons, 72 unique ids; 1,707 step ids, all unique and none collides with the pilot; 1,008 questions, 977 re-solved by code (all agree with the keys; 0 wrong keys, 0 correct distractors; the `fact` items have exactly one true equation each), the other 31 (8 time-of-day, 10 unit-for, 5 word-pick, 3 pay-with, 1 how-compare, 1 money-word, 1 picture-longer, 2 shape-property prompts I mapped by hand) all correct by eye, and `longer.webp` really shows the top pencil longer; all four shape pictures show their shape (a 2:1 rectangle, a square, a triangle, a circle).
- Source fidelity: id, title, level, objective and prerequisites equal the source for all 72 (54 from the age 5-6 file, 7 legacy from curriculum.dart, 11 count lessons from the batch/pack records). Level 1/2/3/4 as in the source; num-subtract keeps prerequisite num-add.
- Structure: mastery fields present in all; every check and remediation-check item has 3 options, no hints, no caption, `showResult` false, `showHops` false; check key stored position is 0/1/2 in 72/72/72 of 216 items (rotated by lesson); hint 1 never contains the answer (0 hits); no check item repeats a guided/practice problem (0); number-line starts and ends stay inside the line; ranges: add and subtract within 20 (num-subtract within 10), tens and compare two-digit (10-98), counts 0-10, multiplication sizes 2-6 and product at most 30, division totals at most 20, percent 25% and 50% only, patterns up to 46.
- I read 31 lessons by eye (`num_sample.txt`, 768 lines): count 0, 3, 10, num-count; num-names; tens 001, 004, 009; compare 034, 036, 041; add 010, 013, 020; subtract 022, 023, 033, num-subtract; patterns 042, 043, 047; shapes 048, 050, 051; everyday 052, 053, 054; num-multiply, num-divide, num-fraction, num-percent. Plus targeted scripts (`num2.py`, `num3.py`, `num4.py`) for worked-example reuse, feedback truth, teach-before-test, object counts.
- Not run: no UI, no audio, no educator.

## RN.2 Findings

| # | Scope | Sev | Evidence | Required fix | Owner |
|---|---|---|---|---|---|
| RN-1 | objects operator "-" (100 steps: all subtract lessons and num-subtract, 12+1 lessons), "vs" (10 steps), negative jump, jump 0 | MAJOR (UI spec) | "-": the plan stores two groups, for example 19 and 9. Drawn as two groups with a minus sign it looks like 28 objects, and 28 is exactly the "sum" distractor offered in those items; the second group must be drawn as taken away from the first. "vs": two clip groups, with names only in the prompt; unclear which group is the pencil. Negative `jump` (hops to the left, with an arrow) and `jump` 0 with hops hidden (marker only) are unambiguous for a child as long as the marker and arrow directions are drawn; jump 0 with hops shown (count 0) draws nothing, which is acceptable. | Write the semantics into SCHEMA.md: "-" = ONE group of the first count with the last `b` objects crossed out or faded and no result in questions; "vs" = two labelled rows (names from the prompt) lined up at one start line. ui-verifier to check. | content-creator, ui-creator |
| RN-2 | num-names | MAJOR (teach before test) | demonstrate teaches only five, four, six. Guided, practice, check and remediation ask three, ten, seven, nine, eight, two, one (check items ask eight and two). | Add a demonstrate step with the names one to ten (a table of numeral and word), or restrict all items to the taught names. Names 1-10 already exist in the app (`numberNames`), so teaching all ten is within scope. | content-creator |
| RN-3 | tens lessons numbers-56-001..009 (45 `ones_pic` / `ones_sym` items in the batch) | MAJOR | "How many ones are in 26?" is ambiguous: 26 contains 26 ones, and the plan lists 26 as a WRONG option ("the whole number"). The intended question is the ones digit. | Reword: pictures "How many loose ones are there?"; symbols "What digit is in the ones place of 26?" and keep the same for the build items. | content-creator, educator |
| RN-4 | pattern lessons numbers-56-042, 043, 044, 045, 047 (increasing); 046 tests the opposite way | MAJOR (teach before test) | The increasing lessons demonstrate only "add d each time", yet practice (2 items) and check (1-3 items) use decreasing sequences, for example 13, 10, 7, __ and 38, __, 32, 29, with answers that need "take away d". Lesson 046 (decreasing) tests increasing patterns the same way. | Add a demonstrate step for the opposite direction (counting back with the rule "take away d"), or remove opposite-direction items from practice and check. | content-creator |
| RN-5 | shape lessons numbers-56-048..051 | MAJOR (teach before test) | Items ask "Which shape has 4 equal sides?" (square) and "Which shape has 4 corners and 2 long sides?" / "4 sides, 2 long and 2 short?" (rectangle) in check or remediation-check (and practice 051). No demonstrate step teaches "equal sides" or "long sides" and the square and rectangle (both 4 sides, 4 corners) are never contrasted in 048 and 051. | Teach the difference in 049 and 050 (show square and rectangle together: all sides equal vs two long, two short) and add one contrast step in 048 and 051, or remove those property prompts from the lessons that do not teach them. | content-creator, educator |
| RN-6 | num-percent (9 items), num-multiply (3 items) | MAJOR (false feedback) | num-percent: "0 is the percent number itself" is attached to the wrong option 0 for 50% in 8 items (the percent number is 50); "3 is for the other percent" for 50% of 14 (25% of 14 is 3.5, not 3). num-multiply guided.1, check.3, remediation_guided.2: "6 / 8 / 7 is what you get by adding the two numbers" when the two numbers shown add to something else (for 6 + 6 the feedback calls 8 "the sum"). | Regenerate those wrong options and their feedback so every sentence is true (drop the 0 option; use 25 or 50 as the "percent number" option; use a real sum). | content-creator |
| RN-7 | tens (54 items), subtract (21), patterns (5), num-fraction (1), num-percent (2): 83 items with more than 20 objects, up to 98 | MAJOR (readability), MINOR for others | Tens pictures are 9 groups of 10 emoji plus ones (up to 98 on a phone screen); subtract pictures show up to 28; num-fraction rc.1 shows 38; "next" pattern items show 28+1+1 objects. | Draw each group of ten as one compact bar or ten-frame (a base-ten visual), cap object pictures at 20 and use symbols above that, and use a number strip not objects for patterns. | content-creator, ui-creator |
| RN-8 | count lessons 0-10 and num-count | MINOR | demonstrate text says "Count the stars" while the objects are balloons, diamonds, moons, rockets; the zero story gets the hint "Touch each one". | Say "things" or draw the named object; remove the touching hint from empty-set items. | content-creator |
| RN-9 | tens lessons | MINOR | "There are 1 ten", "13 = 1 tens + 3 ones". | Fix singular and plural. | content-creator |
| RN-10 | num-multiply | MINOR | 2 of the 3 check items are additions (6 + 6, groups of 4), only one uses the × sign. | Give the check one picture, one story, one × item. | educator |
| RN-11 | remediation | MINOR (judged OK) | In 34 of 72 lessons the remediation uses the same visual types as the demonstration, but with a different method (start from the bigger number, count up to subtract, packets of ten, sticks and dots) and different numbers; I accept this as genuinely different. | none | |
| RN-12 | num-percent.check.3 | INFO | Uses the worked set size 20 with 50% (the worked example is 25% of 20); different problem, acceptable. | none | |
| RN-13 | everything | UNVERIFIED | Educator review of every progression, hint and sentence; pass marks (2 of 3: 26% blind chance); en-IN TTS of the number words and signs; emoji rendering; the whole set in a real UI. | educator, audio, ui-verifier | |

## RN.3 Scope choices the creator listed

| Choice | Verdict |
|---|---|
| num-count also counts 1, 2, 4 (distractors up to 5) | Acceptable for a first version. |
| num-names uses one to ten | Acceptable in scope (the app already has these names) but MUST change: teach all names used (RN-2). |
| num-fraction: halves of even numbers up to 40 | Acceptable up to 20 with objects; larger sets symbolic only (RN-7). The 38-object item must change. |
| num-percent: 50% (and naming 100%) added | Acceptable; fix the false feedback (RN-6). |
| num-multiply / num-divide sizes 2-6, product at most 30 | Acceptable. |
| morning lesson adds afternoon, evening, night | Acceptable. The situation "You come home from school after lunch time" depends on school hours; prefer clue-only wording (sun high, lunch). All other situations are clue-based and fine. |
| longer lesson adds paper-clip units; rupees lesson adds metres and litres | Acceptable. The pay-with items are easy by design (stones, feathers, pebble, button vs coin); fine for age. |
| shape everyday examples (pizza slice, door, biscuit) | Acceptable (circle: biscuit; triangle: pizza slice; rectangle: door). |

## RN.4 Verdicts ("PASS" = structure, arithmetic and teaching order OK for first use; educator items stay UNVERIFIED)

| Skill group | Lessons | Verdict | Reason |
|---|---|---|---|
| Counting 0-10 | numbers-count-000..010, num-count (12) | PASS | RN-8 minor. |
| Number names | num-names (1) | REVISE | RN-2. |
| Tens and ones | numbers-56-001..009 (9) | REVISE | RN-3 wording, RN-7 visual rule. |
| Compare two-digit | numbers-56-034..041 (8) | PASS | Clean. |
| Add within 20 | numbers-56-010..021 (12) | PASS | Clean (hops, objects, symbolic, make-ten). |
| Subtract within 20 / 10 | numbers-56-022..033 (12), num-subtract (1) | PASS (content); needs RN-1 spec before the UI draws the "-" pictures | Arithmetic correct. |
| Number patterns | numbers-56-042..047 (6) | REVISE | RN-4 (and RN-7 for "next" visuals). |
| Shapes | numbers-56-048..051 (4) | REVISE | RN-5. |
| Everyday maths | numbers-56-052, 053, 054 (3) | PASS | Educator items only. |
| Multiplication | num-multiply (1) | REVISE | RN-6. |
| Division | num-divide (1) | PASS | Clean. |
| Fractions | num-fraction (1) | PASS (cap objects at 20) | RN-7. |
| Percent | num-percent (1) | REVISE | RN-6. |

Totals: 50 PASS, 22 REVISE (num-names 1, tens 9, patterns 6, shapes 4, num-multiply 1, num-percent 1), 0 BLOCKED. Findings: 13 numbered (6 MAJOR RN-1 to RN-6, plus RN-7 MAJOR/MINOR, 3 MINOR RN-8 to RN-10, RN-11 judged OK, RN-12 INFO, RN-13 UNVERIFIED). The six MAJOR content fixes are RN-2 to RN-6 and the RN-3 reword; RN-1 and RN-7 are schema/visual requirements for the UI. Nothing here is educator-verified, audio-verified or UI-verified.


---

# Rollout R2 - round 2 (letters, `content/teaching_pending/rollout_letters.json`)

Date: 2026-10-31. The creator revised the 149 Level 1 letter plans and moved them to `content/teaching_pending/rollout_letters.json`. Re-verified with my own checker (`...\scratchpad\verify_rollout.py`, path updated; output `ro2_out.txt`) plus `ro2_an.py` (review items, option sets, pool, asset references) and by eye on te-letter-005, te-letter-012, hi-letter-012, ta-letter-002, ta-letter-012, en-letter-017 and en-letter-002. Only this report was written to.

## R2b.1 What the checker found (real output)

- 149 lessons, 149 unique ids; 4,023 step ids all unique and none collides with the pilot; id, title, level, locale and prerequisites still equal the source for all 149.
- New variant counts: English 21 words_pictures / 2 letter_with_word / 2 letter_only; Telugu 3 / 7 / 40; Hindi 5 / 8 / 32; Tamil 2 / 7 / 20; total 31 words_pictures, 24 letter_with_word, 94 letter_only. Hindi 006-008 and Tamil 007-009 are now letter_with_word (their neighbours' words are the "one apple" and "five apples" pictures) and Tamil 002-003 too (a neighbour's word is the letter ஈ itself); en-letter-017 (Q) and ta-letter-012 (ஔ) are letter_only because their picture is missing.
- Structure: words_pictures = 2 introduce + 6 demonstrate + 3 guided + 5 practice + 3 check; letter_with_word and letter_only = 2 + 5 + 3 + 6 practice + 3 check; remediation 3 explain + 2 guided + 3 check in all.
- All checks from round 1 still clean: answers in options; wrong_feedback keys; every check and remediation-check has exactly 3 options, no hints, no caption, no glyph equal to the answer, no negative task; every check task taught earlier; no answer in a check prompt or wrong_feedback; guided hint 1 and practice hints never contain the answer; every "begins with" claim and keyed word starts with the exact letter; the heard stimulus matches. The only codes my old checker raised were `l_key` on the new review items (expected, see below) and 3 `variant_downgrade` notes (Q, ஈ, ஔ, all deliberate).
- Review items (new): 118 practice items (practice.6) and 118 check items (check.3) in the 24 + 94 letter_with_word and letter_only lessons, plus 94 remediation-check items in letter_only. For every one the keyed letter equals the prerequisite lesson's letter, the heard letter equals the key, the check ones have no hints, and none leaks. 0 exceptions. words_pictures lessons have no review items.
- Option sets: in all 118 letter_with_word and letter_only lessons, 0 check items and 0 remediation-check items repeat an earlier (answer, option set); the three check sets are pairwise different; the remediation-check sets differ from the check. The wrong-option pool is now 8 letters per lesson counting the lesson letter (7 wrong options; up to 13 in letter_with_word). In words_pictures lessons it is unchanged (62 of 93 check items still share answer and option set with a practice item, one remediation-check item per lesson equals a check item).

## R2b.2 Disposition of the round 1 findings

| Id | Status | Evidence |
|---|---|---|
| RR-1 | FIXED | te-letter-012 now references `assets/images/quiz/boat.png`, which exists (checked: a clear boat); ta-letter-012 and en-letter-017 are letter_only and reference no picture at all, and make no begins-with claim; all asset references in the 149 plans exist. Residual MINOR: en-letter-017 still lists `en_queen.webp` in `review.assets_missing` although it is not used (stale). |
| RR-2 | FIXED | See option sets and review items above: check and remediation-check sets are new in all letter_only and letter_with_word lessons, the pool is 7 wrong options, and the lesson letter is no longer the answer of every item. |
| RR-3 | FIXED for letter_with_word (0 repeats); still OPEN as MINOR for the 31 words_pictures lessons (three picture words only: pilot limitation) | |
| RR-4 | FIXED | No question uses `hi_one.webp` or `te_five.webp` any more (0 hits); those lessons became letter_with_word and show the pictures only in teaching steps. |
| RR-5 | FIXED | The puzzle is split into two steps (demonstrate.5 shows Ball with its letter, demonstrate.6 shows the odd one, Dog), so both pictures appear. |
| RR-6 to RR-12 | unchanged | Titles are source sentences (INFO); Tamil pure consonants and rare letters (educator); TTS of bare letters (audio); all Telugu, Hindi and Tamil text (native): still UNVERIFIED. |

## R2b.3 New observations from the rewrite (all MINOR or INFO)

| # | Item | Sev | Evidence | Suggested change | Owner |
|---|---|---|---|---|---|
| N2-1 | pass rule in letter_with_word and letter_only | MINOR | The third check item is now a review of the previous letter, so only 2 of the 3 check items test the lesson's own letter. Pass mark 2 of 3 can be reached with one own-letter item right plus the review item. | Make the pass mark count only the own-letter items, or use 3 of 3 / more items; the mark is a data field. | educator |
| N2-2 | review items | INFO | They use the same prompt wording as the other items ("Which letter do you hear?"), so the UI cannot tell them apart and a child may expect the new letter. Pedagogically sound (it forces discrimination). | UI may label them "an earlier letter"; no data change needed. | ui-creator |
| N2-3 | en-letter-017 `assets_missing` | MINOR | Declares an unused file. | Clear it. | content-creator |
| N2-4 | words_pictures check repeats | MINOR | Carry-over of RR-3. | Needs more approved picture words before rollout. | product owner |
| N2-5 | wrong options that are later letters | INFO | Some wrong options are the next two letters of the sequence (not yet taught, for example అం in the ఓ lesson), as in the source's own recognition lessons; harmless. | none | |
| N2-6 | new review prompt wording | UNVERIFIED | Not native-confirmed; same register as the rest. | native review | native reviewers |

## R2b.4 Verdicts ("PASS" = ready for children as a first version; native, educator and audio review still open and not held against any lesson)

| Template | Lessons | Verdict |
|---|---|---|
| words_pictures | 31 | PASS (carry-over MINOR N2-4) |
| letter_with_word | 24 | PASS |
| letter_only | 94 | PASS |

| Language | Lessons | PASS | REVISE | BLOCKED |
|---|---|---|---|---|
| English | 25 | 25 | 0 | 0 |
| Telugu | 50 | 50 | 0 | 0 |
| Hindi | 45 | 45 | 0 | 0 |
| Tamil | 29 | 29 | 0 | 0 |
| Total | 149 | 149 | 0 | 0 |

Counts: round 1 findings RR-1, RR-2, RR-4, RR-5 FIXED; RR-3 fixed for 118 lessons and open (MINOR) for 31; RR-6 to RR-12 unchanged (UNVERIFIED or INFO). New: 6 (3 MINOR, 2 INFO, 1 UNVERIFIED). Open MAJOR: 0. Still open before children rely on these: native review of every Telugu, Hindi and Tamil sentence, listening tests of the bare-letter audio (the letter_only lessons depend entirely on it), and the UI work on `variant`, `not_letter`, empty captions and the other new fields. Nothing in this file is native-, educator-, audio- or UI-verified.


---

# Rollout R1 - round 2 (Number Galaxy, `content/teaching_pending/rollout_numbers.json`)

Date: 2026-10-31. The creator regenerated the 72 plans against my RN findings; the UI implemented `baseTen`, `takeAway`, `labels` and the 20-object cap (SCHEMA.md). Only this report was written to.

## RN2.1 What I ran

- My solver (`...\scratchpad\verify_numbers.py`, updated for the new visuals: `baseTen` tens and ones, single-group minus with `takeAway`, "vs" with labels; output `num2_out.txt`). Result: 72 lessons, 72 unique ids, 1,716 step ids all unique and none collides with the pilot; 1,008 questions, 977 re-solved by code, 0 wrong keys, 0 correct distractors; the 31 text answers re-read by eye and correct; id, title, level, objective and prerequisites still equal the sources for all 72; check key positions 72/72/72; no check or remediation-check has hints, captions, shown results or visible hops; hint 1 never contains the answer; no object picture exceeds 20 objects (maximum 20); every baseTen question visual has `showTotal` false.
- Feedback truth (`num3.py`, `takeAway` counted as an operand): 0 false templated claims (previously 12). Teach-before-test (`num4.py` plus reading): see table.
- `E:\flutter-sdk\bin\flutter.bat test test/teaching/rollout_visuals_test.dart`: "All tests passed" (65 passed, 2 skipped), including no-overflow cases for nine tens and nine ones, subtract 19 take 9, compare rows, hop left, stay.
- Read by eye: num-names, numbers-56-001, 004, 009 (tens), 042, 046, 047 (patterns), 048, 049, 050, 051 (shapes), num-percent, num-multiply, numbers-56-022 (subtract), 053 (longer), 052 (morning). Not run: no audio, no educator.

## RN2.2 Disposition of the round 1 findings

| Id | Status | Evidence |
|---|---|---|
| RN-1 (visual semantics) | FIXED | Subtraction is now ONE group with `takeAway`: the start step shows the plain group, the next shows the last b objects crossed out ("These 5 things are crossed out: they go away"), and every question shows the same crossed-out picture, so the child counts what is left; the "sum" distractor can no longer be read off the picture. "vs" always has labels in the order the prompt names the objects (0 mismatches; two labelled rows). Negative jump (hops left, arrow) and jump 0 with hops hidden (marker only) are unambiguous; no check shows hops. |
| RN-2 (num-names) | FIXED | demonstrate.3-4 show the whole table 1 one ... 10 ten; every word asked (one to ten) is taught before it is asked. |
| RN-3 (ones wording) | FIXED | "In 26, how many single ones are left after the tens?" and "In 61, how many full tens are there?", taught in demonstrate.2-3 ("the single ones that are left after the tens", "the full tens"). The whole-number option is now clearly wrong. |
| RN-4 (pattern direction) | FIXED | Every pattern lesson has a demonstrate step for the other direction (042-045, 047: "Patterns can also go down ... take away 2 each time"; 046: "Patterns can also go up"). |
| RN-5 (shape words) | FIXED | introduce.2 and demonstrate.4-5 of all four shape lessons teach 3 sides, 4 equal sides (square), 2 long and 2 short sides (rectangle), and show square and rectangle pictures with captions, before any item asks for them. |
| RN-6 (false feedback) | FIXED | 0 false claims in the whole file; percent feedback now reads for example "18 is half of 36, which is 50%. We want 25%." and "50 is the percent number itself", and multiply feedback "11 is 6 + 5, the two numbers added". |
| RN-7 (readability) | FIXED | No object picture over 20 (max 20); tens use `baseTen` (bars and cubes, captions "tens" and "ones", no numbers); pattern "next" items use a number line, not 28+ objects. The UI test shows no overflow at 9 tens 9 ones. |
| RN-8 (stars vs emoji) | not re-checked in detail | The count lessons are unchanged in my sample; still MINOR (text says "stars", pictures vary). |
| RN-9 (grammar) | MOSTLY FIXED | One step remains: numbers-56-001 demonstrate.1 "There are 1 full tens." |
| RN-10 (multiply check) | FIXED | The check is now one × item, one groups picture, one story. |
| RN-11, RN-12 | unchanged (judged OK / INFO) | |
| RN-13 | UNVERIFIED | educator, audio, emoji and glyph font rendering. |

## RN2.3 New findings from the rewrite (all MINOR / INFO)

| # | Item | Sev | Evidence | Required fix | Owner |
|---|---|---|---|---|---|
| N-R1 | num-multiply | MINOR | Commuted repeats: practice.4 (6 groups of 4) = guided.2 (4 groups of 6); check.1 6 × 5 = practice.2 5 × 6 (same product 30 in the check); remediation_guided.1 = check.3 (2 and 5); remediation_check.3 = remediation_check.2 (3 and 5). | Draw the check and remediation problems from pairs not used before in either order. | content-creator |
| N-R2 | numbers-56-001 demonstrate.1 | MINOR | "There are 1 full tens." | "There is 1 full ten." | content-creator |
| N-R3 | shape lessons | MINOR | introduce.2 is one long step (five facts and the glyph row of four shape symbols), identical in all four lessons; the shape symbols depend on font support. | Split the step or show the four pictures; confirm glyph rendering. | content-creator, ui-verifier |
| N-R4 | tens remediation | MINOR (judged OK) | The remediation uses the same bars-and-cubes visual as the demonstration but a different method (cover the digit, packets and loose sweets); accepted. | none | |
| N-R5 | everything | UNVERIFIED | Educator review of every progression, scope choice and hint; pass marks (26% blind pass chance); en-IN TTS of numbers and signs; emoji and glyph rendering on the device. | educator, audio, ui-verifier | |

## RN2.4 Verdicts ("PASS" = structure, arithmetic and teaching order OK for first use; educator review stays UNVERIFIED)

| Skill group | Lessons | Verdict |
|---|---|---|
| Counting 0-10, num-count | 12 | PASS (RN-8 minor) |
| Number names | num-names | PASS |
| Tens and ones | numbers-56-001..009 (9) | PASS (N-R2 minor on 001) |
| Compare two-digit | 8 | PASS |
| Add within 20 | 12 | PASS |
| Subtract within 20 / 10 | 12 + num-subtract | PASS |
| Number patterns | numbers-56-042..047 (6) | PASS |
| Shapes | numbers-56-048..051 (4) | PASS (N-R3 minor) |
| Everyday maths | numbers-56-052, 053, 054 | PASS |
| Multiplication | num-multiply | PASS (N-R1 minor) |
| Division | num-divide | PASS |
| Fractions | num-fraction | PASS |
| Percent | num-percent | PASS |

Totals: 72 PASS, 0 REVISE, 0 BLOCKED. Round 1 findings RN-1 to RN-7 and RN-10 fixed, RN-9 nearly; new findings 3 MINOR (N-R1 to N-R3) plus 1 judged OK and 1 UNVERIFIED. Open MAJOR: 0. Nothing in this file is educator-, audio- or UI-verified beyond the Dart validator and overflow tests that passed.
