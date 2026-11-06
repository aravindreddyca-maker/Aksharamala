# PILOT content specs - five lessons (content-creator, revision 2)

STATUS: pilot_unverified. Revised after the content-verifier REVISE report (audit/CONTENT_VERIFICATION_REPORT.md). NOT approved by anyone. Nothing here is native-speaker-verified, educator-verified, audio-verified or UI-verified. It must go back to content-verifier.

Machine-readable plan: `content/teaching/pilot_teaching_plans.json`; field meanings: `content/teaching/SCHEMA.md`. Scratchpad generators: `gen_pilot.py` (string tables) + `gen2.py`; checker: `check_pilot.py`.

Phase order: introduce -> demonstrate -> guided (hint ladder, retry, no penalty) -> practice (4, easy to harder, two-rung hint ladder that never reveals) -> check (3 new items, no hints; pass 2 of 3) -> remediation only if the check is failed (different explanation, 2 guided, 3 alternate check items; pass 2 of 3; at most 2 cycles; then the concept is marked 'needs support' and the child continues - never loops forever). All thresholds are data fields.

What changed in revision 2: question pictures have no caption; check items are new task types or option sets (not guided/practice items with audio swapped); remediation is sound-first / 'which does NOT begin' (languages) and a count-on explanation (maths); hints are ladders whose first rung never contains the answer; English tests lowercase a; Number Galaxy teaches counting to 10, the number line, + and =, and counting on inside the lesson, removes the make-ten items, hides hops/results in check items, and varies distractors and key positions; Tamil sandhi and Hindi 'whose' wording changed. The Telugu lesson id is te-a.


---

## en-a - A is for Apple  (world english, level 1, locale en-US)

Objective: Recognise uppercase and lowercase A, and tell that Apple is the picture word that begins with A.

Mastery data: check 2 of 3; remediation pass 2 of 3; max cycles 2; after limit `offer_parent_support`.

### What the child sees and hears

**1. Introduce**

- `en-a.introduce.1` [big letter A a] "This is the letter A. It has a big A and a small a."
- `en-a.introduce.2` [letter A + word Apple + picture apple.png] "A is for Apple."

**2. Demonstrate (one idea per step)**

- `en-a.demonstrate.1` [big letter A] "This is big A. It is the capital letter."
- `en-a.demonstrate.2` [big letter a] "This is small a. Big A and small a are the same letter."
- `en-a.demonstrate.3` [letter A + word Apple + picture apple.png] "Apple begins with A."
- `en-a.demonstrate.4` [picture ball.png captioned Ball] "Ball does not begin with A. It is a different letter."
- `en-a.demonstrate.5` [picture cat.png captioned Cat] "A puzzle: which word does NOT begin with A? Apple does begin with A. Cat does not. Cat is the odd one out."

**3. Guided** (hints 1 then 2, then answer + explanation; retry, no penalty), **4. Practice** (4 items one at a time), **5. Check** (3 new items, no hints) - see the table.

**6. Remediation explain (only if the check is failed; a different explanation)**

- `en-a.remediation_explain.1` [picture apple.png (no caption)] "Close your eyes. Listen: Apple. The first sound is the sound of A."
- `en-a.remediation_explain.2` [picture ball.png (no caption)] "Listen: Ball. Does it start with the sound of A? No. It starts with a different sound."
- `en-a.remediation_explain.3` [picture apple.png captioned Apple] "When you hear the sound of A first, think of Apple."

Then 2 extra guided items and 3 alternate check items (see the table).

### Question table (answer key)

| id | diff | visual | prompt | options | answer | hints |
|---|---|---|---|---|---|---|
| en-a.guided.1 | 1 | big letter A | Which word begins with A? | Ball / Apple / Cat | **Apple** | 2 |
| en-a.guided.2 | 1 | big letter a | Which big letter is the same as this small letter? | B / A / C | **A** | 2 |
| en-a.guided.3 | 2 | big letter A | Which word does NOT begin with A? | Apple / Ball | **Ball** | 2 |
| en-a.practice.1 | 1 | picture apple.png (no caption) | Which letter does this word begin with? | B / A / C | **A** | 2 |
| en-a.practice.2 | 1 | picture ball.png (no caption) | What is this picture? | Apple / Cat / Ball | **Ball** | 2 |
| en-a.practice.3 | 2 | nothing shown | Listen. Which picture is it? | Ball / Cat / Apple | **Cat** | 2 |
| en-a.practice.4 | 3 | nothing shown | Listen to the letter. Which word begins with it? | Cat / Apple / Ball | **Apple** | 2 |
| en-a.practice.5 | 3 | big letter A | Which word does NOT begin with A? | Cat / Apple | **Cat** | 2 |
| en-a.check.1 | 2 | nothing shown | Listen to the word. Which small letter does it begin with? | c / a / b | **a** | 0 |
| en-a.check.2 | 2 | big letter A | Find the word that begins with A. | Cat / Apple / Ball | **Apple** | 0 |
| en-a.check.3 | 2 | picture cat.png (no caption) | What is this picture? | Ball / Cat / Apple | **Cat** | 0 |
| en-a.remediation_guided.1 | 2 | nothing shown | Which word does NOT begin with A? | Apple / Ball | **Ball** | 2 |
| en-a.remediation_guided.2 | 1 | nothing shown | Listen. Which word did you hear? | Cat / Apple / Ball | **Apple** | 2 |
| en-a.remediation_check.1 | 2 | nothing shown | Which word begins with A? | Ball / Cat / Apple | **Apple** | 0 |
| en-a.remediation_check.2 | 2 | nothing shown | Listen. Which picture is it? | Apple / Ball / Cat | **Ball** | 0 |
| en-a.remediation_check.3 | 2 | nothing shown | Listen. Which letter is it? | C / A / B | **A** | 0 |

### UNVERIFIED / to review

- Educator review of wording, item mix and the three-word limitation.
- en-US TTS reading of the bare letter 'A.', 'A says a' and the words (EN-6).
- English: check item 1 asks for the SMALL letter a (listening) and practice item 1 asks the partner of small a, so both cases are tested; the letter name A versus the sound 'a' as spoken by en-US TTS is unverified.
- NOTE: TASK ORDER: the 'which word does NOT begin with the letter' puzzle is taught in demonstrate step 5, practised in guided 3 and practice 5, and used again only in remediation guided 1. It is NOT used in the check: with three words two words never begin with the letter, so a three-option version has two right answers and a two-option version is a 50% guess.
- NOTE: GUESS RATE: every check and remediation-check item has 3 options (a blind guess is 33%; passing 2 of 3 by guessing alone is about 26%). The thresholds are data fields; with only three words the guess rate cannot be lowered further in this pilot.
- NOTE: PILOT LIMITATION: only three picture words exist for this letter, so check and remediation items reuse the same three words. Items differ by task type (listen-to-word to letter, which word does NOT begin with the letter, picture naming without a caption, listen-to-letter to picture), option sets and distractor letters, but a child can still learn the three words by memory. More human-approved picture words are required before rollout.
- NOTE: Question pictures carry an empty caption so the answer is never printed on screen; teaching steps keep captions.
- NOTE: Audio-only items (visual none) need a replay button and a visual fallback if text-to-speech fails (UI decision).
- NOTE: No tracing / stroke order is taught.
- NOTE: After a failed check the child gets remediation (different explanation, 2 guided, 3 alternate check items), at most max_remediation_cycles times; then the UI marks the concept 'needs support' (after_limit offer_parent_support) and lets the child continue.
- native_review_needed: false; assets_missing: none required for this pilot.
- Not verified by any other agent or human: correctness, wording, pedagogy, audio, on-screen appearance.


---

## te-a - అ – అమ్మ  (world telugu, level 1, locale te-IN)

Objective: అ అక్షరాన్ని గుర్తించండి. (Recognise the Telugu letter అ and that అమ్మ begins with it.)

Mastery data: check 2 of 3; remediation pass 2 of 3; max cycles 2; after limit `offer_parent_support`.

### What the child sees and hears

**1. Introduce**

- `te-a.introduce.1` [big letter అ] "ఇది అ అక్షరం."  _(English gloss: This is the letter అ.)_
- `te-a.introduce.2` [letter అ + word అమ్మ + picture te_amma.webp] "అ – అమ్మ. అమ్మ అనే పదం అ తో మొదలవుతుంది."  _(English gloss: అ is for Amma (mother).)_

**2. Demonstrate (one idea per step)**

- `te-a.demonstrate.1` [big letter అ] "అ అక్షరాన్ని చూడండి. నాతో చెప్పండి: అ."  _(English gloss: Look at the letter అ. Say it with me: అ.)_
- `te-a.demonstrate.2` [letter అ + word అమ్మ + picture te_amma.webp] "అమ్మ అ తో మొదలవుతుంది."  _(English gloss: Amma (mother) begins with అ.)_
- `te-a.demonstrate.3` [picture te_house.webp captioned ఇల్లు] "ఇల్లు అ తో మొదలవదు. ఇది వేరే అక్షరం."  _(English gloss: House does not begin with అ. It is a different letter.)_
- `te-a.demonstrate.4` [picture te_elephant.webp captioned ఏనుగు] "ఏనుగు అ తో మొదలవదు. ఇది వేరే అక్షరం."  _(English gloss: Elephant does not begin with అ. It is a different letter.)_
- `te-a.demonstrate.5` [picture te_elephant.webp captioned ఏనుగు] "పజిల్: అ తో మొదలవని పదం ఏది? అమ్మ అ తో మొదలవుతుంది. ఏనుగు మొదలవదు. కాబట్టి ఏనుగు వేరుగా ఉంది."  _(English gloss: A puzzle: which word does NOT begin with అ? Amma (mother) does begin with అ. Elephant does not. Elephant is the odd one out.)_

**3. Guided** (hints 1 then 2, then answer + explanation; retry, no penalty), **4. Practice** (4 items one at a time), **5. Check** (3 new items, no hints) - see the table.

**6. Remediation explain (only if the check is failed; a different explanation)**

- `te-a.remediation_explain.1` [picture te_amma.webp (no caption)] "కళ్ళు మూసుకోండి. వినండి: అమ్మ. మొదటి శబ్దం అ శబ్దం."  _(English gloss: Close your eyes. Listen: Amma (mother). The first sound is the sound of అ.)_
- `te-a.remediation_explain.2` [picture te_house.webp (no caption)] "వినండి: ఇల్లు. ఇది అ శబ్దంతో మొదలవుతుందా? లేదు, వేరే శబ్దంతో మొదలవుతుంది."  _(English gloss: Listen: House. Does it start with the sound of అ? No. It starts with a different sound.)_
- `te-a.remediation_explain.3` [picture te_amma.webp captioned అమ్మ] "మొదట అ శబ్దం వినిపిస్తే, అమ్మ అని గుర్తుంచుకోండి."  _(English gloss: When you hear the sound of అ first, think of Amma (mother).)_

Then 2 extra guided items and 3 alternate check items (see the table).

### Question table (answer key)

| id | diff | visual | prompt | English gloss | options | answer | hints |
|---|---|---|---|---|---|---|---|
| te-a.guided.1 | 1 | big letter అ | అ తో మొదలయ్యే పదం ఏది? | Which word begins with అ? | ఇల్లు / అమ్మ / ఏనుగు | **అమ్మ** | 2 |
| te-a.guided.2 | 1 | big letter అ | ఈ అక్షరం ఏది? | Which letter is this? | ఏ / ఇ / అ | **అ** | 2 |
| te-a.guided.3 | 2 | big letter అ | అ తో మొదలవని పదం ఏది? | Which word does NOT begin with అ? | అమ్మ / ఇల్లు | **ఇల్లు** | 2 |
| te-a.practice.1 | 1 | picture te_amma.webp (no caption) | ఈ పదం ఏ అక్షరంతో మొదలవుతుంది? | Which letter does this word begin with? | ఇ / అ / ఏ | **అ** | 2 |
| te-a.practice.2 | 1 | picture te_house.webp (no caption) | ఈ బొమ్మ ఏమిటి? | What is this picture? | అమ్మ / ఏనుగు / ఇల్లు | **ఇల్లు** | 2 |
| te-a.practice.3 | 2 | nothing shown | వినండి. ఏ బొమ్మ? | Listen. Which picture is it? | ఇల్లు / ఏనుగు / అమ్మ | **ఏనుగు** | 2 |
| te-a.practice.4 | 3 | nothing shown | అక్షరాన్ని వినండి. దానితో మొదలయ్యే పదం ఏది? | Listen to the letter. Which word begins with it? | ఏనుగు / అమ్మ / ఇల్లు | **అమ్మ** | 2 |
| te-a.practice.5 | 3 | big letter అ | అ తో మొదలవని పదం ఏది? | Which word does NOT begin with అ? | ఏనుగు / అమ్మ | **ఏనుగు** | 2 |
| te-a.check.1 | 2 | nothing shown | పదాన్ని వినండి. ఇది ఏ అక్షరంతో మొదలవుతుంది? | Listen to the word. Which letter does it begin with? | ఏ / ఇ / అ | **అ** | 0 |
| te-a.check.2 | 2 | big letter అ | అ తో మొదలయ్యే పదాన్ని కనుగొనండి. | Find the word that begins with అ. | ఏనుగు / అమ్మ / ఇల్లు | **అమ్మ** | 0 |
| te-a.check.3 | 2 | picture te_elephant.webp (no caption) | ఈ బొమ్మ ఏమిటి? | What is this picture? | ఇల్లు / ఏనుగు / అమ్మ | **ఏనుగు** | 0 |
| te-a.remediation_guided.1 | 2 | nothing shown | అ తో మొదలవని పదం ఏది? | Which word does NOT begin with అ? | అమ్మ / ఇల్లు | **ఇల్లు** | 2 |
| te-a.remediation_guided.2 | 1 | nothing shown | వినండి. మీరు ఏ పదం విన్నారు? | Listen. Which word did you hear? | ఏనుగు / అమ్మ / ఇల్లు | **అమ్మ** | 2 |
| te-a.remediation_check.1 | 2 | nothing shown | అ తో మొదలయ్యే పదం ఏది? | Which word begins with అ? | ఇల్లు / ఏనుగు / అమ్మ | **అమ్మ** | 0 |
| te-a.remediation_check.2 | 2 | nothing shown | వినండి. ఏ బొమ్మ? | Listen. Which picture is it? | అమ్మ / ఇల్లు / ఏనుగు | **ఇల్లు** | 0 |
| te-a.remediation_check.3 | 2 | nothing shown | వినండి. ఇది ఏ అక్షరం? | Listen. Which letter is it? | ఏ / అ / ఇ | **అ** | 0 |

### UNVERIFIED / to review

- Every sentence (text, speech, prompts, hints, feedback, explanations) is AI-written and UNVERIFIED by a native speaker: grammar, naturalness, register and age suitability.
- Text-to-speech in the lesson locale was not heard: how a lone letter is read (letter name versus sound, vowel length), and every sentence.
- The word used for 'picture' in prompts is not an existing picture-word vocabulary item; confirm it is acceptable.
- Negative prompt ('which word does NOT begin with the letter') is a difficulty-3 item: educator and native speaker to confirm the wording is clear for a young child and the task is suitable.
- Sound-first remediation sentences ('close your eyes and listen', 'the first sound is the sound of the letter') need native checking of phrasing and of what 'sound of the letter' should be called.
- The letter distractors in letter-choice items are the first letters of the other two picture words; confirm they are acceptable distractors.
- Whether each picture file clearly shows its word (te_amma and ta_mother show two people; a child may name them differently).
- Telugu points for the reviewer: మొదలవుతుంది / మొదలవదు / మొదలవని, 'నాతో చెప్పండి', బొమ్మ for picture, శబ్దం for sound, 'కళ్ళు మూసుకోండి', register for a 3-4 year old.
- ID decision: te-a (curriculum.dart) is the lesson planned; batch lesson telugu-recognise-001 with options అమ్మ/ఉడుత/ఓడ is a different lesson and was not planned.
- NOTE: TASK ORDER: the 'which word does NOT begin with the letter' puzzle is taught in demonstrate step 5, practised in guided 3 and practice 5, and used again only in remediation guided 1. It is NOT used in the check: with three words two words never begin with the letter, so a three-option version has two right answers and a two-option version is a 50% guess.
- NOTE: GUESS RATE: every check and remediation-check item has 3 options (a blind guess is 33%; passing 2 of 3 by guessing alone is about 26%). The thresholds are data fields; with only three words the guess rate cannot be lowered further in this pilot.
- NOTE: PILOT LIMITATION: only three picture words exist for this letter, so check and remediation items reuse the same three words. Items differ by task type (listen-to-word to letter, which word does NOT begin with the letter, picture naming without a caption, listen-to-letter to picture), option sets and distractor letters, but a child can still learn the three words by memory. More human-approved picture words are required before rollout.
- NOTE: Question pictures carry an empty caption so the answer is never printed on screen; teaching steps keep captions.
- NOTE: Audio-only items (visual none) need a replay button and a visual fallback if text-to-speech fails (UI decision).
- NOTE: No tracing / stroke order is taught.
- NOTE: After a failed check the child gets remediation (different explanation, 2 guided, 3 alternate check items), at most max_remediation_cycles times; then the UI marks the concept 'needs support' (after_limit offer_parent_support) and lets the child continue.
- native_review_needed: true; assets_missing: none required for this pilot.
- Not verified by any other agent or human: correctness, wording, pedagogy, audio, on-screen appearance.


---

## hi-a - अ – अनार  (world hindi, level 1, locale hi-IN)

Objective: अ अक्षर पहचानें। (Recognise the Hindi letter अ and that अनार begins with it.)

Mastery data: check 2 of 3; remediation pass 2 of 3; max cycles 2; after limit `offer_parent_support`.

### What the child sees and hears

**1. Introduce**

- `hi-a.introduce.1` [big letter अ] "यह अक्षर अ है।"  _(English gloss: This is the letter अ.)_
- `hi-a.introduce.2` [letter अ + word अनार + picture hi_pomegranate.webp] "अ से अनार। अनार शब्द अ से शुरू होता है।"  _(English gloss: अ is for Pomegranate.)_

**2. Demonstrate (one idea per step)**

- `hi-a.demonstrate.1` [big letter अ] "अक्षर अ को देखो। मेरे साथ बोलो: अ।"  _(English gloss: Look at the letter अ. Say it with me: अ.)_
- `hi-a.demonstrate.2` [letter अ + word अनार + picture hi_pomegranate.webp] "अनार अ से शुरू होता है।"  _(English gloss: Pomegranate begins with अ.)_
- `hi-a.demonstrate.3` [picture hi_lotus.webp captioned कमल] "कमल अ से शुरू नहीं होता। यह दूसरा अक्षर है।"  _(English gloss: Lotus does not begin with अ. It is a different letter.)_
- `hi-a.demonstrate.4` [picture hi_house.webp captioned घर] "घर अ से शुरू नहीं होता। यह दूसरा अक्षर है।"  _(English gloss: House does not begin with अ. It is a different letter.)_
- `hi-a.demonstrate.5` [picture hi_house.webp captioned घर] "पहेली: अ से कौन सा शब्द शुरू नहीं होता? अनार अ से शुरू होता है। घर नहीं होता। इसलिए घर अलग है।"  _(English gloss: A puzzle: which word does NOT begin with अ? Pomegranate does begin with अ. House does not. House is the odd one out.)_

**3. Guided** (hints 1 then 2, then answer + explanation; retry, no penalty), **4. Practice** (4 items one at a time), **5. Check** (3 new items, no hints) - see the table.

**6. Remediation explain (only if the check is failed; a different explanation)**

- `hi-a.remediation_explain.1` [picture hi_pomegranate.webp (no caption)] "आँखें बंद करो। सुनो: अनार। पहली आवाज़ अ की आवाज़ है।"  _(English gloss: Close your eyes. Listen: Pomegranate. The first sound is the sound of अ.)_
- `hi-a.remediation_explain.2` [picture hi_lotus.webp (no caption)] "सुनो: कमल। क्या यह अ की आवाज़ से शुरू होता है? नहीं, यह दूसरी आवाज़ से शुरू होता है।"  _(English gloss: Listen: Lotus. Does it start with the sound of अ? No. It starts with a different sound.)_
- `hi-a.remediation_explain.3` [picture hi_pomegranate.webp captioned अनार] "जब सबसे पहले अ की आवाज़ सुनाई दे, तो अनार याद करो।"  _(English gloss: When you hear the sound of अ first, think of Pomegranate.)_

Then 2 extra guided items and 3 alternate check items (see the table).

### Question table (answer key)

| id | diff | visual | prompt | English gloss | options | answer | hints |
|---|---|---|---|---|---|---|---|
| hi-a.guided.1 | 1 | big letter अ | अ से कौन सा शब्द शुरू होता है? | Which word begins with अ? | कमल / अनार / घर | **अनार** | 2 |
| hi-a.guided.2 | 1 | big letter अ | यह कौन सा अक्षर है? | Which letter is this? | घ / क / अ | **अ** | 2 |
| hi-a.guided.3 | 2 | big letter अ | अ से कौन सा शब्द शुरू नहीं होता? | Which word does NOT begin with अ? | अनार / कमल | **कमल** | 2 |
| hi-a.practice.1 | 1 | picture hi_pomegranate.webp (no caption) | इस चित्र का शब्द किस अक्षर से शुरू होता है? | Which letter does this word begin with? | क / अ / घ | **अ** | 2 |
| hi-a.practice.2 | 1 | picture hi_lotus.webp (no caption) | इस चित्र में क्या है? | What is this picture? | अनार / घर / कमल | **कमल** | 2 |
| hi-a.practice.3 | 2 | nothing shown | सुनो। कौन सा चित्र है? | Listen. Which picture is it? | कमल / घर / अनार | **घर** | 2 |
| hi-a.practice.4 | 3 | nothing shown | अक्षर सुनो। इससे शुरू होने वाला शब्द कौन सा है? | Listen to the letter. Which word begins with it? | घर / अनार / कमल | **अनार** | 2 |
| hi-a.practice.5 | 3 | big letter अ | अ से कौन सा शब्द शुरू नहीं होता? | Which word does NOT begin with अ? | घर / अनार | **घर** | 2 |
| hi-a.check.1 | 2 | nothing shown | शब्द सुनो। यह किस अक्षर से शुरू होता है? | Listen to the word. Which letter does it begin with? | घ / क / अ | **अ** | 0 |
| hi-a.check.2 | 2 | big letter अ | अ से शुरू होने वाला शब्द ढूँढो। | Find the word that begins with अ. | घर / अनार / कमल | **अनार** | 0 |
| hi-a.check.3 | 2 | picture hi_house.webp (no caption) | इस चित्र में क्या है? | What is this picture? | कमल / घर / अनार | **घर** | 0 |
| hi-a.remediation_guided.1 | 2 | nothing shown | अ से कौन सा शब्द शुरू नहीं होता? | Which word does NOT begin with अ? | अनार / कमल | **कमल** | 2 |
| hi-a.remediation_guided.2 | 1 | nothing shown | सुनो। तुमने कौन सा शब्द सुना? | Listen. Which word did you hear? | घर / अनार / कमल | **अनार** | 2 |
| hi-a.remediation_check.1 | 2 | nothing shown | अ से कौन सा शब्द शुरू होता है? | Which word begins with अ? | कमल / घर / अनार | **अनार** | 0 |
| hi-a.remediation_check.2 | 2 | nothing shown | सुनो। कौन सा चित्र है? | Listen. Which picture is it? | अनार / कमल / घर | **कमल** | 0 |
| hi-a.remediation_check.3 | 2 | nothing shown | सुनो। यह कौन सा अक्षर है? | Listen. Which letter is it? | घ / अ / क | **अ** | 0 |

### UNVERIFIED / to review

- Every sentence (text, speech, prompts, hints, feedback, explanations) is AI-written and UNVERIFIED by a native speaker: grammar, naturalness, register and age suitability.
- Text-to-speech in the lesson locale was not heard: how a lone letter is read (letter name versus sound, vowel length), and every sentence.
- The word used for 'picture' in prompts is not an existing picture-word vocabulary item; confirm it is acceptable.
- Negative prompt ('which word does NOT begin with the letter') is a difficulty-3 item: educator and native speaker to confirm the wording is clear for a young child and the task is suitable.
- Sound-first remediation sentences ('close your eyes and listen', 'the first sound is the sound of the letter') need native checking of phrasing and of what 'sound of the letter' should be called.
- The letter distractors in letter-choice items are the first letters of the other two picture words; confirm they are acceptable distractors.
- Whether each picture file clearly shows its word (te_amma and ta_mother show two people; a child may name them differently).
- Hindi: 'whose picture' wording replaced by 'इस चित्र में क्या है?' (still needs native confirmation); 'पहली आवाज़ सुनो', 'दूसरी आवाज़', 'सबसे पहले ... की आवाज़ सुनाई दे', danda/spacing in speech strings.
- NOTE: TASK ORDER: the 'which word does NOT begin with the letter' puzzle is taught in demonstrate step 5, practised in guided 3 and practice 5, and used again only in remediation guided 1. It is NOT used in the check: with three words two words never begin with the letter, so a three-option version has two right answers and a two-option version is a 50% guess.
- NOTE: GUESS RATE: every check and remediation-check item has 3 options (a blind guess is 33%; passing 2 of 3 by guessing alone is about 26%). The thresholds are data fields; with only three words the guess rate cannot be lowered further in this pilot.
- NOTE: PILOT LIMITATION: only three picture words exist for this letter, so check and remediation items reuse the same three words. Items differ by task type (listen-to-word to letter, which word does NOT begin with the letter, picture naming without a caption, listen-to-letter to picture), option sets and distractor letters, but a child can still learn the three words by memory. More human-approved picture words are required before rollout.
- NOTE: Question pictures carry an empty caption so the answer is never printed on screen; teaching steps keep captions.
- NOTE: Audio-only items (visual none) need a replay button and a visual fallback if text-to-speech fails (UI decision).
- NOTE: No tracing / stroke order is taught.
- NOTE: After a failed check the child gets remediation (different explanation, 2 guided, 3 alternate check items), at most max_remediation_cycles times; then the UI marks the concept 'needs support' (after_limit offer_parent_support) and lets the child continue.
- native_review_needed: true; assets_missing: none required for this pilot.
- Not verified by any other agent or human: correctness, wording, pedagogy, audio, on-screen appearance.


---

## ta-a - அ – அம்மா  (world tamil, level 1, locale ta-IN)

Objective: அ எழுத்தை அடையாளம் காணுங்கள். (Recognise the Tamil letter அ and that அம்மா begins with it.)

Mastery data: check 2 of 3; remediation pass 2 of 3; max cycles 2; after limit `offer_parent_support`.

### What the child sees and hears

**1. Introduce**

- `ta-a.introduce.1` [big letter அ] "இது அ என்ற எழுத்து."  _(English gloss: This is the letter அ.)_
- `ta-a.introduce.2` [letter அ + word அம்மா + picture ta_mother.webp] "அ – அம்மா. அம்மா என்ற சொல் அ என்ற எழுத்தில் தொடங்குகிறது."  _(English gloss: அ is for Mother.)_

**2. Demonstrate (one idea per step)**

- `ta-a.demonstrate.1` [big letter அ] "அ என்ற எழுத்தைப் பாருங்கள். என்னோடு சொல்லுங்கள்: அ."  _(English gloss: Look at the letter அ. Say it with me: அ.)_
- `ta-a.demonstrate.2` [letter அ + word அம்மா + picture ta_mother.webp] "அம்மா அ என்ற எழுத்தில் தொடங்குகிறது."  _(English gloss: Mother begins with அ.)_
- `ta-a.demonstrate.3` [picture ta_leaf.webp captioned இலை] "இலை அ என்ற எழுத்தில் தொடங்கவில்லை. இது வேறு எழுத்து."  _(English gloss: Leaf does not begin with அ. It is a different letter.)_
- `ta-a.demonstrate.4` [picture ta_swing.webp captioned ஊஞ்சல்] "ஊஞ்சல் அ என்ற எழுத்தில் தொடங்கவில்லை. இது வேறு எழுத்து."  _(English gloss: Swing does not begin with அ. It is a different letter.)_
- `ta-a.demonstrate.5` [picture ta_swing.webp captioned ஊஞ்சல்] "புதிர்: அ என்ற எழுத்தில் தொடங்காத சொல் எது? அம்மா அ என்ற எழுத்தில் தொடங்குகிறது. ஊஞ்சல் தொடங்கவில்லை. எனவே ஊஞ்சல் வேறுபட்டது."  _(English gloss: A puzzle: which word does NOT begin with அ? Mother does begin with அ. Swing does not. Swing is the odd one out.)_

**3. Guided** (hints 1 then 2, then answer + explanation; retry, no penalty), **4. Practice** (4 items one at a time), **5. Check** (3 new items, no hints) - see the table.

**6. Remediation explain (only if the check is failed; a different explanation)**

- `ta-a.remediation_explain.1` [picture ta_mother.webp (no caption)] "கண்களை மூடுங்கள். கேளுங்கள்: அம்மா. முதல் ஒலி அ ஒலி."  _(English gloss: Close your eyes. Listen: Mother. The first sound is the sound of அ.)_
- `ta-a.remediation_explain.2` [picture ta_leaf.webp (no caption)] "கேளுங்கள்: இலை. இது அ ஒலியில் தொடங்குகிறதா? இல்லை, இது வேறு ஒலியில் தொடங்குகிறது."  _(English gloss: Listen: Leaf. Does it start with the sound of அ? No. It starts with a different sound.)_
- `ta-a.remediation_explain.3` [picture ta_mother.webp captioned அம்மா] "முதலில் அ ஒலி கேட்டால், அம்மா என்று நினைவில் வைத்துக்கொள்ளுங்கள்."  _(English gloss: When you hear the sound of அ first, think of Mother.)_

Then 2 extra guided items and 3 alternate check items (see the table).

### Question table (answer key)

| id | diff | visual | prompt | English gloss | options | answer | hints |
|---|---|---|---|---|---|---|---|
| ta-a.guided.1 | 1 | big letter அ | அ என்ற எழுத்தில் தொடங்கும் சொல் எது? | Which word begins with அ? | இலை / அம்மா / ஊஞ்சல் | **அம்மா** | 2 |
| ta-a.guided.2 | 1 | big letter அ | இது எந்த எழுத்து? | Which letter is this? | ஊ / இ / அ | **அ** | 2 |
| ta-a.guided.3 | 2 | big letter அ | அ என்ற எழுத்தில் தொடங்காத சொல் எது? | Which word does NOT begin with அ? | அம்மா / இலை | **இலை** | 2 |
| ta-a.practice.1 | 1 | picture ta_mother.webp (no caption) | இந்தச் சொல் எந்த எழுத்தில் தொடங்குகிறது? | Which letter does this word begin with? | இ / அ / ஊ | **அ** | 2 |
| ta-a.practice.2 | 1 | picture ta_leaf.webp (no caption) | இது என்ன படம்? | What is this picture? | அம்மா / ஊஞ்சல் / இலை | **இலை** | 2 |
| ta-a.practice.3 | 2 | nothing shown | கேளுங்கள். எந்தப் படம்? | Listen. Which picture is it? | இலை / ஊஞ்சல் / அம்மா | **ஊஞ்சல்** | 2 |
| ta-a.practice.4 | 3 | nothing shown | எழுத்தைக் கேளுங்கள். அதில் தொடங்கும் சொல் எது? | Listen to the letter. Which word begins with it? | ஊஞ்சல் / அம்மா / இலை | **அம்மா** | 2 |
| ta-a.practice.5 | 3 | big letter அ | அ என்ற எழுத்தில் தொடங்காத சொல் எது? | Which word does NOT begin with அ? | ஊஞ்சல் / அம்மா | **ஊஞ்சல்** | 2 |
| ta-a.check.1 | 2 | nothing shown | சொல்லைக் கேளுங்கள். அது எந்த எழுத்தில் தொடங்குகிறது? | Listen to the word. Which letter does it begin with? | ஊ / இ / அ | **அ** | 0 |
| ta-a.check.2 | 2 | big letter அ | அ என்ற எழுத்தில் தொடங்கும் சொல்லைக் கண்டுபிடியுங்கள். | Find the word that begins with அ. | ஊஞ்சல் / அம்மா / இலை | **அம்மா** | 0 |
| ta-a.check.3 | 2 | picture ta_swing.webp (no caption) | இது என்ன படம்? | What is this picture? | இலை / ஊஞ்சல் / அம்மா | **ஊஞ்சல்** | 0 |
| ta-a.remediation_guided.1 | 2 | nothing shown | அ என்ற எழுத்தில் தொடங்காத சொல் எது? | Which word does NOT begin with அ? | அம்மா / இலை | **இலை** | 2 |
| ta-a.remediation_guided.2 | 1 | nothing shown | கேளுங்கள். நீங்கள் எந்தச் சொல்லைக் கேட்டீர்கள்? | Listen. Which word did you hear? | ஊஞ்சல் / அம்மா / இலை | **அம்மா** | 2 |
| ta-a.remediation_check.1 | 2 | nothing shown | அ என்ற எழுத்தில் தொடங்கும் சொல் எது? | Which word begins with அ? | இலை / ஊஞ்சல் / அம்மா | **அம்மா** | 0 |
| ta-a.remediation_check.2 | 2 | nothing shown | கேளுங்கள். எந்தப் படம்? | Listen. Which picture is it? | அம்மா / இலை / ஊஞ்சல் | **இலை** | 0 |
| ta-a.remediation_check.3 | 2 | nothing shown | கேளுங்கள். இது எந்த எழுத்து? | Listen. Which letter is it? | ஊ / அ / இ | **அ** | 0 |

### UNVERIFIED / to review

- Every sentence (text, speech, prompts, hints, feedback, explanations) is AI-written and UNVERIFIED by a native speaker: grammar, naturalness, register and age suitability.
- Text-to-speech in the lesson locale was not heard: how a lone letter is read (letter name versus sound, vowel length), and every sentence.
- The word used for 'picture' in prompts is not an existing picture-word vocabulary item; confirm it is acceptable.
- Negative prompt ('which word does NOT begin with the letter') is a difficulty-3 item: educator and native speaker to confirm the wording is clear for a young child and the task is suitable.
- Sound-first remediation sentences ('close your eyes and listen', 'the first sound is the sound of the letter') need native checking of phrasing and of what 'sound of the letter' should be called.
- The letter distractors in letter-choice items are the first letters of the other two picture words; confirm they are acceptable distractors.
- Whether each picture file clearly shows its word (te_amma and ta_mother show two people; a child may name them differently).
- Tamil: sandhi fixed in 'எழுத்தைக் கவனமாகப்' and in 'நீங்கள் ... என்ற சொல்லைக் கேட்டீர்கள்' (the verifier's findings) - fixes are still unverified; also 'ஒலி' for sound, 'தொடங்காத', 'நினைவில் வைத்துக்கொள்ளுங்கள்', register.
- NOTE: TASK ORDER: the 'which word does NOT begin with the letter' puzzle is taught in demonstrate step 5, practised in guided 3 and practice 5, and used again only in remediation guided 1. It is NOT used in the check: with three words two words never begin with the letter, so a three-option version has two right answers and a two-option version is a 50% guess.
- NOTE: GUESS RATE: every check and remediation-check item has 3 options (a blind guess is 33%; passing 2 of 3 by guessing alone is about 26%). The thresholds are data fields; with only three words the guess rate cannot be lowered further in this pilot.
- NOTE: PILOT LIMITATION: only three picture words exist for this letter, so check and remediation items reuse the same three words. Items differ by task type (listen-to-word to letter, which word does NOT begin with the letter, picture naming without a caption, listen-to-letter to picture), option sets and distractor letters, but a child can still learn the three words by memory. More human-approved picture words are required before rollout.
- NOTE: Question pictures carry an empty caption so the answer is never printed on screen; teaching steps keep captions.
- NOTE: Audio-only items (visual none) need a replay button and a visual fallback if text-to-speech fails (UI decision).
- NOTE: No tracing / stroke order is taught.
- NOTE: After a failed check the child gets remediation (different explanation, 2 guided, 3 alternate check items), at most max_remediation_cycles times; then the UI marks the concept 'needs support' (after_limit offer_parent_support) and lets the child continue.
- native_review_needed: true; assets_missing: none required for this pilot.
- Not verified by any other agent or human: correctness, wording, pedagogy, audio, on-screen appearance.


---

## num-add - Rocket Addition  (world numbers, level 2, locale en-IN)

Objective: Add two quantities within ten

Prerequisite: num-count (REVIEW: it only counts to 3, see unverified list)

Mastery data: check 2 of 3; remediation pass 2 of 3; max cycles 2; after limit `offer_parent_support`.

### What the child sees and hears

**1. Introduce**

- `num-add.introduce.1` [objects 10x💎, numbered] "Welcome to Rocket Addition! Our rocket needs fuel crystals. Let us count them: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10."
- `num-add.introduce.2` [number line start 0, jump 1, hops hidden] "A number line shows the numbers in order, from 0 to 10. We move to the right to go up."

**2. Demonstrate (one idea per step)**

- `num-add.demonstrate.1` [objects 2x💎] "Here are 2 fuel crystals."
- `num-add.demonstrate.2` [objects 2x💎 + 3x💎] "Now we add 3 more crystals. The + sign means: add more."
- `num-add.demonstrate.3` [objects 2x💎 + 3x💎, numbered] "Count them all together: 1, 2, 3, 4, 5."
- `num-add.demonstrate.4` [objects 2x💎 + 3x💎, shows = 5] "There are 5 crystals. 2 + 3 = 5. The = sign means: makes, or is the same as."
- `num-add.demonstrate.5` [number line start 4, jump 2, hops shown] "On the number line, we count on. Start at 4. Count on 2 steps: 5, 6. So 4 + 2 = 6."

**3. Guided** (hints 1 then 2, then answer + explanation; retry, no penalty), **4. Practice** (4 items one at a time), **5. Check** (3 new items, no hints) - see the table.

**6. Remediation explain (only if the check is failed; a different explanation)**

- `num-add.remediation_explain.1` [objects 6x🍎] "Let us try a faster way. Here are 6 apples. We do not need to count them again. Just say 6."
- `num-add.remediation_explain.2` [objects 6x🍎 + 2x🍎] "Now 2 more apples. Keep 6 in your head and count on: 7, 8."
- `num-add.remediation_explain.3` [number line start 6, jump 2, hops shown] "On the number line: start at 6, count on 2, and land on 8. So 6 + 2 = 8."

Then 2 extra guided items and 3 alternate check items (see the table).

### Worked arithmetic (independent)

Teaching: 10 crystals counted 1..10; 2 + 3 = 5 (count all 1..5); 4 + 2 = 6 (count on 5, 6 on the line); remediation 6 + 2 = 8 (say 6, count on 7, 8).

| item | sum | working | options (stored order) | distractors, all wrong |
|---|---|---|---|---|
| num-add.guided.1 | 3 + 1 | 3+1=4; count on 4 | 6, 3, 4 | 6, 3 (none is 4) |
| num-add.guided.2 | 5 + 2 | 5+2=7; count on 6, 7 | 8, 5, 7 | 8, 5 (none is 7) |
| num-add.practice.1 | 1 + 2 | 1+2=3; count on 2, 3 | 2, 5, 3 | 2, 5 (none is 3) |
| num-add.practice.2 | 3 + 3 | 3+3=6; count on 4, 5, 6 | 9, 6, 4 | 9, 4 (none is 6) |
| num-add.practice.3 | 3 + 4 | 3+4=7; count on 4, 5, 6, 7 | 5, 7, 4 | 5, 4 (none is 7) |
| num-add.practice.4 | 5 + 4 | 5+4=9; count on 6, 7, 8, 9 | 8, 9, 4 | 8, 4 (none is 9) |
| num-add.check.1 | 5 + 3 | 5+3=8; count on 6, 7, 8 | 6, 8, 3 | 6, 3 (none is 8) |
| num-add.check.2 | 6 + 3 | 6+3=9; count on 7, 8, 9 | 9, 6, 8 | 6, 8 (none is 9) |
| num-add.check.3 | 7 + 2 | 7+2=9; count on 8, 9 | 10, 2, 9 | 10, 2 (none is 9) |
| num-add.remediation_guided.1 | 2 + 2 | 2+2=4; count on 3, 4 | 5, 2, 4 | 5, 2 (none is 4) |
| num-add.remediation_guided.2 | 8 + 1 | 8+1=9; count on 9 | 10, 9, 1 | 10, 1 (none is 9) |
| num-add.remediation_check.1 | 6 + 1 | 6+1=7; count on 7 | 9, 1, 7 | 9, 1 (none is 7) |
| num-add.remediation_check.2 | 4 + 4 | 4+4=8; count on 5, 6, 7, 8 | 6, 8, 4 | 6, 4 (none is 8) |
| num-add.remediation_check.3 | 7 + 1 | 7+1=8; count on 8 | 8, 5, 7 | 5, 7 (none is 8) |

### Question table (answer key)

| id | diff | visual | prompt | options | answer | hints |
|---|---|---|---|---|---|---|
| num-add.guided.1 | 1 | objects 3x💎 + 1x💎 | How many altogether? | 6 / 3 / 4 | **4** | 2 |
| num-add.guided.2 | 1 | number line start 5, jump 2, hops shown | 5 + 2 = ? | 8 / 5 / 7 | **7** | 2 |
| num-add.practice.1 | 1 | objects 1x⭐ + 2x⭐ | How many altogether? | 2 / 5 / 3 | **3** | 2 |
| num-add.practice.2 | 2 | objects 3x🌟 + 3x🌟 | How many altogether? | 9 / 6 / 4 | **6** | 2 |
| num-add.practice.3 | 2 | number line start 3, jump 4, hops hidden | 3 + 4 = ? | 5 / 7 / 4 | **7** | 2 |
| num-add.practice.4 | 3 | nothing shown | 5 + 4 = ? | 8 / 9 / 4 | **9** | 2 |
| num-add.check.1 | 2 | objects 5x🚀 + 3x🚀 | How many altogether? | 6 / 8 / 3 | **8** | 0 |
| num-add.check.2 | 2 | number line start 6, jump 3, hops hidden | 6 + 3 = ? | 9 / 6 / 8 | **9** | 0 |
| num-add.check.3 | 3 | nothing shown | 7 + 2 = ? | 10 / 2 / 9 | **9** | 0 |
| num-add.remediation_guided.1 | 1 | objects 2x🍓 + 2x🍓 | How many altogether? | 5 / 2 / 4 | **4** | 2 |
| num-add.remediation_guided.2 | 2 | number line start 8, jump 1, hops shown | 8 + 1 = ? | 10 / 9 / 1 | **9** | 2 |
| num-add.remediation_check.1 | 2 | objects 6x🌙 + 1x🌙 | How many altogether? | 9 / 1 / 7 | **7** | 0 |
| num-add.remediation_check.2 | 2 | number line start 4, jump 4, hops hidden | 4 + 4 = ? | 6 / 8 / 4 | **8** | 0 |
| num-add.remediation_check.3 | 3 | nothing shown | 7 + 1 = ? | 8 / 5 / 7 | **8** | 0 |

### UNVERIFIED / to review

- PREREQUISITE REVIEW: num-count (curriculum.dart) only counts three stars, but num-add needs counting to 10, reading a 0-10 number line, the + and = signs and counting on. This lesson teaches those inside (introduce 1-2, demonstrate 2, 4, 5) rather than assuming them; an educator should decide whether the prerequisite should change or this inline teaching is enough.
- Educator review of the concrete -> pictorial -> symbolic progression, the count-on strategy, pass marks, and whether symbolic items 5+4, 7+2, 7+1 are sufficiently scaffolded by the equation step and hint ladder.
- en-IN TTS reading of number words, 'plus', 'equals', 'count on'.
- Emoji rendering (💎 ⭐ 🌟 🚀 🍎 🍓 🌙) on the target device; the intro crystal artwork (num_crystal.webp) is no longer used, objects are emoji.
- New visual fields showHops / showResult are not implemented anywhere yet (see content/teaching/SCHEMA.md).
- Make-ten facts (8+2, 6+4) were REMOVED because they were never taught; all sums here are solved by counting on.
- NOTE: All answers independently computed; every distractor is wrong; distractor patterns vary (a starting number, a near miss, a distant number) and the key is not always in the same position. Options are stored in a mixed order; the UI may shuffle.
- NOTE: Check and remediation-check number-line items set showHops false and objects items showResult false, so the answer is not drawn; guided number-line items show the hops (scaffold).
- NOTE: After a failed check: remediation (count-on explanation, 2 guided, 3 alternate check items), at most max_remediation_cycles times, then 'needs support' (offer_parent_support); the child can continue.
- NOTE: Each operand pair is used once (either order) across the whole lesson.
- native_review_needed: false; assets_missing: none required for this pilot.
- Not verified by any other agent or human: correctness, wording, pedagogy, audio, on-screen appearance.


---

## Global notes

- The existing one-question lessons in curriculum.dart are unchanged; the guided item 1 of each language lesson resembles the original question and is hinted, not a check item.
- No tracing or stroke order is taught anywhere.
- Nothing here may be called verified. Next step: content-verifier, then (if PASS) ui-creator.
