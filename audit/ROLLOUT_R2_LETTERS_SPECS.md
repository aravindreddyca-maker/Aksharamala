# ROLLOUT R2 - Level 1 letter-recognition teaching plans (content-creator)

STATUS: rollout_unverified. Written by content-creator; NOT approved by anyone. Nothing here is native-speaker-verified, educator-verified, audio-verified or UI-verified. It must go to content-verifier.

Files: plans `content/teaching_pending/rollout_letters.json` (NOT promoted to content/teaching/ until the content-verifier passes it) (schema_version 1, status `rollout_unverified`); generator `tool/gen_teaching_letters.py`; checker `tool/check_rollout_letters.py`; field meanings `content/teaching/SCHEMA.md` (two additions below). Source data read, never modified: `lib/src/curriculum.dart` (recognition sequences) and `lib/src/alphabet/alphabet_data.dart` (picture words).

## 1. What the source really contains

Each existing recognition lesson (except the four pilot ones) is one question: the letter is spoken, the child picks it from three letters (the letter and the next two in the sequence). It has no picture words of its own. Picture words exist only in `alphabet_data.dart` and only for some letters: English 26 of 26, Telugu 14 of 51, Hindi 14 of 46, Tamil 16 of 30 (3 Telugu and 4 Tamil source words do not begin with exactly the lesson letter, see section 6; the English word for Q has no picture file named in the table). The plans use that table for the letter's word. Where it has none, the plan teaches the letter alone.

## 2. The three templates, in plain language

All three keep the pilot order: introduce -> demonstrate -> guided (hint ladder, retry, no penalty) -> practice (5, two hints that never reveal) -> check (3 new items, 3 options, no hints, pass 2 of 3) -> remediation only after a failed check (different, sound-first explanation, 2 guided items, 3 alternate check items; at most 2 cycles; then 'needs support' and the child continues). Pass marks are data fields.

**A. words_pictures** (the approved pilot template, filled in per letter): used when the letter and BOTH its option letters have a picture word that begins with them AND all three picture files exist. Introduce: letter, then letter+word+picture. Demonstrate: the letter, the word begins with it, two other words do not, the 'which does NOT begin' puzzle. Guided: pick the word, pick/match the letter (English: big letter for a small one), the NOT puzzle. Practice: picture to letter, name the picture, hear a word and pick the picture, hear the letter and pick the word, the NOT puzzle. Check (no caption, no glyph equal to the answer): hear a word and pick its first letter (English: the SMALL letter), find the word from the letter, name a captionless picture. Remediation: close your eyes and listen to the first sound, a different word that does not start with it, then the shape; extra items are the NOT puzzle, hear-a-word, and a different check.

**B. letter_with_word**: the letter has a picture word that begins with it, but the other two letters do not (or a picture file is missing). Pick-the-word and name-the-picture tasks are NOT used (two wrong words are not available / a missing picture would print its own label). The word is used in teaching steps and in heard-word-to-letter items (audio only, so a missing picture can never leak the answer). Demonstrate: letter, word begins with it, two different letters, the 'which one is the letter' puzzle. Guided: look-and-match, listen-and-pick, 'which letter is NOT the big letter'. Practice: listen-and-pick (different wording and option sets), heard-word-to-letter, the NOT puzzle (English adds big-letter to small-letter). Check: heard-word-to-letter, two listen-and-pick items. Remediation: close your eyes, say it softly; look at the shape beside a different letter; say the word and hear its first sound.

**C. letter_only**: no usable word (none in the source, or the word does not begin with exactly the letter - e.g. a Tamil pure consonant or a letter plus a vowel sign - so no 'begins with' claim is made, or English X by decision). Same as B without the word items: every question is look-and-match (guided only), listen-and-pick, or the NOT puzzle (guided/practice/remediation-guided only, never in a check).

Wrong letters (decision RR-2): each letter question draws its two wrong options from the lesson's own two options plus letters taught earlier (the 5 nearest earlier letters; for the first lessons the next letters of the alphabet fill the pool to 7). No (answer, option set) is used twice in a lesson, so check and remediation-check option sets are new. Practice item 6 and check item 3 are spaced reviews whose answer is the PREVIOUS letter (the prerequisite), marked with the field `purpose: spaced_review_previous_letter`. Check tasks vary: heard letter, heard-sound wording, heard word (B), previous-letter review. words_pictures lessons use the same pool for their letter items; their word items still reuse the three picture words (data limit). words_pictures demonstrate has 6 steps so the NOT puzzle shows both pictures (word with letterWord, then the odd word with picture). A lesson with a number picture (counted objects) among its three words is taught as letter_with_word so that picture only appears in teaching steps with its caption. Q (no picture file) and the Tamil name word are letter_only; te-letter-012 uses the existing boat.png.

Schema additions (not yet in SCHEMA.md; the UI does not read `task`): task value `not_letter` (like `not_word` but the options are letters, 2 options, never in a check); lesson field `variant` (`words_pictures` | `letter_with_word` | `letter_only`) and `prerequisites` on every lesson (copied from the source).

## 3. Counts

| language | recognition lessons in source | done in pilot | planned here | words_pictures | letter_with_word | letter_only | with missing picture files |
|---|---|---|---|---|---|---|---|
| English | 26 | 1 | 25 | 21 | 2 | 2 | 1 |
| Telugu | 51 | 1 | 50 | 3 | 7 | 40 | 0 |
| Hindi | 46 | 1 | 45 | 5 | 8 | 32 | 0 |
| Tamil | 30 | 1 | 29 | 2 | 7 | 20 | 0 |
| **total** | 153 | 4 | 149 | 31 | 24 | 94 | |

Each planned lesson has 2 introduce + 5 demonstrate (6 in words_pictures) + 3 guided + 5 practice (6 in letter_with_word/letter_only) + 3 check + (3 explain, 2 guided, 3 check) remediation steps/questions.

## 4. One worked example per language

### English

**en-letter-002** (english, variant `words_pictures`, prerequisite en-a)

Objective: Recognise the letter B, uppercase B and lowercase b.

*1. Introduce*

- `en-letter-002.introduce.1` [big letter(s) B b] "This is the letter B. It has a big B and a small b."
- `en-letter-002.introduce.2` [letter B + word Ball + picture ball.png] "B is for Ball."

*2. Demonstrate*

- `en-letter-002.demonstrate.1` [big letter(s) B] "This is big B. It is the capital letter."
- `en-letter-002.demonstrate.2` [big letter(s) b] "This is small b. Big B and small b are the same letter."
- `en-letter-002.demonstrate.3` [letter B + word Ball + picture ball.png] "Ball begins with B."
- `en-letter-002.demonstrate.4` [picture cat.png captioned Cat] "Cat does not begin with B. It is a different letter."
- `en-letter-002.demonstrate.5` [letter B + word Ball + picture ball.png] "A puzzle: which word does NOT begin with B? First look: Ball does begin with B."
- `en-letter-002.demonstrate.6` [picture dog.webp captioned Dog] "Now look: Dog does not begin with B. Dog is the odd one out."

*6. Remediation explain (only after a failed check)*

- `en-letter-002.remediation_explain.1` [picture ball.png (no caption)] "Close your eyes. Listen: Ball. The first sound is the sound of B."
- `en-letter-002.remediation_explain.2` [picture cat.png (no caption)] "Listen: Cat. Does it start with the sound of B? No. It starts with a different sound."
- `en-letter-002.remediation_explain.3` [picture ball.png captioned Ball] "When you hear the sound of B first, think of Ball."

*3-5, 7. Questions* (guided = 2 hints, may reveal on hint 2; practice = 2 hints that never reveal; check = no hints)

| id | task | visual | prompt | options | answer | hints |
|---|---|---|---|---|---|---|
| en-letter-002.guided.1 | pick_word | big letter(s) B | Which word begins with B? | Cat / Ball / Dog | **Ball** | 2 |
| en-letter-002.guided.2 | letter_id | big letter(s) b | Which big letter is the same as this small letter? | C / B / D | **B** | 2 |
| en-letter-002.guided.3 | not_word | big letter(s) B | Which word does NOT begin with B? | Ball / Cat | **Cat** | 2 |
| en-letter-002.practice.1 | word_to_letter | picture ball.png (no caption) | Which letter does this word begin with? | A / B / E | **B** | 2 |
| en-letter-002.practice.2 | name_picture | picture cat.png (no caption) | What is this picture? | Ball / Dog / Cat | **Cat** | 2 |
| en-letter-002.practice.3 | hear_pick | nothing shown | Listen. Which picture is it? | Cat / Dog / Ball | **Dog** | 2 |
| en-letter-002.practice.4 | pick_word | nothing shown | Listen to the letter. Which word begins with it? | Dog / Ball / Cat | **Ball** | 2 |
| en-letter-002.practice.5 | not_word | big letter(s) B | Which word does NOT begin with B? | Dog / Ball | **Dog** | 2 |
| en-letter-002.check.1 | word_to_letter | nothing shown | Listen to the word. Which small letter does it begin with? | c / d / b | **b** | 0 |
| en-letter-002.check.2 | pick_word | big letter(s) B | Find the word that begins with B. | Ball / Dog / Cat | **Ball** | 0 |
| en-letter-002.check.3 | name_picture | picture dog.webp (no caption) | What is this picture? | Cat / Dog / Ball | **Dog** | 0 |
| en-letter-002.remediation_guided.1 | not_word | nothing shown | Which word does NOT begin with B? | Ball / Cat | **Cat** | 2 |
| en-letter-002.remediation_guided.2 | hear_pick | nothing shown | Listen. Which word did you hear? | Dog / Ball / Cat | **Ball** | 2 |
| en-letter-002.remediation_check.1 | pick_word | nothing shown | Which word begins with B? | Ball / Cat / Dog | **Ball** | 0 |
| en-letter-002.remediation_check.2 | hear_pick | nothing shown | Listen. Which picture is it? | Ball / Dog / Cat | **Cat** | 0 |
| en-letter-002.remediation_check.3 | letter_id | nothing shown | Listen. Which letter is it? | F / B / G | **B** | 0 |

### Telugu

**te-letter-005** (telugu, variant `letter_with_word`, prerequisite te-letter-004)

Objective: అక్షరాన్ని గుర్తించండి: ఉ (Recognise the Telugu letter ఉ.)

*1. Introduce*

- `te-letter-005.introduce.1` [big letter(s) ఉ] "ఇది ఉ అక్షరం."
- `te-letter-005.introduce.2` [letter ఉ + word ఉడుత + picture te_squirrel.webp] "ఉ – ఉడుత. ఉడుత అనే పదం ఉ తో మొదలవుతుంది."

*2. Demonstrate*

- `te-letter-005.demonstrate.1` [big letter(s) ఉ] "ఉ అక్షరాన్ని జాగ్రత్తగా చూడండి. ఇది ఉ."
- `te-letter-005.demonstrate.2` [letter ఉ + word ఉడుత + picture te_squirrel.webp] "ఉడుత ఉ తో మొదలవుతుంది."
- `te-letter-005.demonstrate.3` [big letter(s) ఊ] "ఇది ఊ. ఊ అంటే ఉ కాదు. ఇది వేరే అక్షరం."
- `te-letter-005.demonstrate.4` [big letter(s) ఋ] "ఇది ఋ. ఋ అంటే ఉ కాదు. ఇది వేరే అక్షరం."
- `te-letter-005.demonstrate.5` [big letter(s) ఊ  ఉ  ఋ] "పజిల్: వీటిలో ఒకటి మాత్రమే ఉ. ఊ ఉ కాదు. ఋ ఉ కాదు. కాబట్టి మిగిలినదే ఉ."

*6. Remediation explain (only after a failed check)*

- `te-letter-005.remediation_explain.1` [big letter(s) ఉ ఉ ఉ] "కళ్ళు మూసుకోండి. వినండి: ఉ. మెల్లగా చెప్పండి: ఉ."
- `te-letter-005.remediation_explain.2` [big letter(s) ఋ  ఉ  ఊ] "ఇప్పుడు కళ్ళు తెరిచి ఉ ఆకారాన్ని చూడండి. ఊ ఆకారం వేరు."
- `te-letter-005.remediation_explain.3` [picture te_squirrel.webp captioned ఉడుత] "ఉడుత ని నెమ్మదిగా చెప్పండి. మొదటి శబ్దం ఉ శబ్దం."

*3-5, 7. Questions* (guided = 2 hints, may reveal on hint 2; practice = 2 hints that never reveal; check = no hints)

| id | task | visual | prompt | options | answer | hints |
|---|---|---|---|---|---|---|
| te-letter-005.guided.1 | letter_id | big letter(s) ఉ | ఇక్కడి అక్షరం ఏది? | ఊ / ఉ / ఋ | **ఉ** | 2 |
| te-letter-005.guided.2 | letter_id | nothing shown | వినండి. ఇది ఏ అక్షరం? | ఉ / ఈ / ఇ | **ఉ** | 2 |
| te-letter-005.guided.3 | not_letter | big letter(s) ఉ | ఉ కాని అక్షరం ఏది? | ఊ / ఉ | **ఊ** | 2 |
| te-letter-005.practice.1 | letter_id | nothing shown | మీరు ఏ అక్షరం వింటున్నారు? | ఆ / ఉ / అ | **ఉ** | 2 |
| te-letter-005.practice.2 | letter_id | nothing shown | జాగ్రత్తగా వినండి. మీరు విన్న అక్షరాన్ని ఎంచుకోండి. | ఊ / ఎ / ఉ | **ఉ** | 2 |
| te-letter-005.practice.3 | word_to_letter | nothing shown | పదాన్ని వినండి. ఇది ఏ అక్షరంతో మొదలవుతుంది? | ఉ / ఋ / ఈ | **ఉ** | 2 |
| te-letter-005.practice.4 | letter_id | nothing shown | విని, అక్కడి అక్షరాన్ని కనుగొనండి. | ఉ / ఇ / ఆ | **ఉ** | 2 |
| te-letter-005.practice.5 | not_letter | big letter(s) ఉ | ఉ కాని అక్షరం ఏది? | ఋ / ఉ | **ఋ** | 2 |
| te-letter-005.practice.6 | letter_id | nothing shown | మళ్లీ ఒకసారి వినండి. అక్షరాన్ని కనుగొనండి. | ఉ / అ / ఈ | **ఈ** | 2 |
| te-letter-005.check.1 | word_to_letter | nothing shown | వినండి: ఇక్కడి పదం మొదటి అక్షరం ఏది? | ఋ / ఎ / ఉ | **ఉ** | 0 |
| te-letter-005.check.2 | letter_id | nothing shown | ఏ అక్షరం ఇక్కడి శబ్దం ఇస్తుంది? | ఉ / ఊ / ఈ | **ఉ** | 0 |
| te-letter-005.check.3 | letter_id | nothing shown | విని, అక్కడి అక్షరాన్ని కనుగొనండి. | ఉ / ఈ / ఇ | **ఈ** | 0 |
| te-letter-005.remediation_guided.1 | not_letter | nothing shown | ఉ కాని అక్షరం ఏది? | ఈ / ఉ | **ఈ** | 2 |
| te-letter-005.remediation_guided.2 | word_to_letter | nothing shown | పదాన్ని వినండి. ఇది ఏ అక్షరంతో మొదలవుతుంది? | ఆ / ఉ / ఎ | **ఉ** | 2 |
| te-letter-005.remediation_check.1 | letter_id | nothing shown | మీరు ఏ అక్షరం వింటున్నారు? | ఉ / ఊ / అ | **ఉ** | 0 |
| te-letter-005.remediation_check.2 | letter_id | nothing shown | నేను చెప్పిన అక్షరం ఏది? | ఋ / ఇ / ఉ | **ఉ** | 0 |
| te-letter-005.remediation_check.3 | word_to_letter | nothing shown | వినండి: ఇక్కడి పదం మొదటి అక్షరం ఏది? | ఈ / ఉ / ఆ | **ఉ** | 0 |

### Hindi

**hi-letter-006** (hindi, variant `letter_with_word`, prerequisite hi-letter-005)

Objective: अक्षर पहचानें: ऊ (Recognise the Hindi letter ऊ.)

*1. Introduce*

- `hi-letter-006.introduce.1` [big letter(s) ऊ] "यह अक्षर ऊ है।"
- `hi-letter-006.introduce.2` [letter ऊ + word ऊन + picture hi_wool.webp] "ऊ से ऊन। ऊन शब्द ऊ से शुरू होता है।"

*2. Demonstrate*

- `hi-letter-006.demonstrate.1` [big letter(s) ऊ] "अक्षर ऊ को ध्यान से देखो। यह ऊ है।"
- `hi-letter-006.demonstrate.2` [letter ऊ + word ऊन + picture hi_wool.webp] "ऊन ऊ से शुरू होता है।"
- `hi-letter-006.demonstrate.3` [big letter(s) ऋ] "यह ऋ है। ऋ, ऊ नहीं है। यह दूसरा अक्षर है।"
- `hi-letter-006.demonstrate.4` [big letter(s) ए] "यह ए है। ए, ऊ नहीं है। यह दूसरा अक्षर है।"
- `hi-letter-006.demonstrate.5` [big letter(s) ऋ  ऊ  ए] "पहेली: इनमें से एक ही ऊ है। ऋ, ऊ नहीं है। ए, ऊ नहीं है। इसलिए बचा हुआ अक्षर ऊ है।"

*6. Remediation explain (only after a failed check)*

- `hi-letter-006.remediation_explain.1` [big letter(s) ऊ ऊ ऊ] "आँखें बंद करो। सुनो: ऊ। धीरे से बोलो: ऊ।"
- `hi-letter-006.remediation_explain.2` [big letter(s) ए  ऊ  ऋ] "अब आँखें खोलो और ऊ का आकार देखो। ऋ का आकार अलग है।"
- `hi-letter-006.remediation_explain.3` [picture hi_wool.webp captioned ऊन] "ऊन को धीरे-धीरे बोलो। पहली आवाज़ ऊ की आवाज़ है।"

*3-5, 7. Questions* (guided = 2 hints, may reveal on hint 2; practice = 2 hints that never reveal; check = no hints)

| id | task | visual | prompt | options | answer | hints |
|---|---|---|---|---|---|---|
| hi-letter-006.guided.1 | letter_id | big letter(s) ऊ | यह कौन सा अक्षर है? | ऋ / ऊ / ए | **ऊ** | 2 |
| hi-letter-006.guided.2 | letter_id | nothing shown | सुनो। यह कौन सा अक्षर है? | ऊ / उ / ई | **ऊ** | 2 |
| hi-letter-006.guided.3 | not_letter | big letter(s) ऊ | कौन सा अक्षर ऊ नहीं है? | ऋ / ऊ | **ऋ** | 2 |
| hi-letter-006.practice.1 | letter_id | nothing shown | तुम कौन सा अक्षर सुन रहे हो? | इ / ऊ / आ | **ऊ** | 2 |
| hi-letter-006.practice.2 | letter_id | nothing shown | ध्यान से सुनो। जो अक्षर सुना, उसे चुनो। | ऋ / अ / ऊ | **ऊ** | 2 |
| hi-letter-006.practice.3 | word_to_letter | nothing shown | शब्द सुनो। यह किस अक्षर से शुरू होता है? | ऊ / ए / उ | **ऊ** | 2 |
| hi-letter-006.practice.4 | letter_id | nothing shown | सुनो और वह अक्षर ढूँढो। | ऊ / ई / इ | **ऊ** | 2 |
| hi-letter-006.practice.5 | not_letter | big letter(s) ऊ | कौन सा अक्षर ऊ नहीं है? | ए / ऊ | **ए** | 2 |
| hi-letter-006.practice.6 | letter_id | nothing shown | एक बार और सुनो। अक्षर ढूँढो। | ऊ / आ / उ | **उ** | 2 |
| hi-letter-006.check.1 | word_to_letter | nothing shown | सुनो: इस शब्द का पहला अक्षर कौन सा है? | ए / अ / ऊ | **ऊ** | 0 |
| hi-letter-006.check.2 | letter_id | nothing shown | कौन सा अक्षर यह आवाज़ देता है? | ऊ / ऋ / उ | **ऊ** | 0 |
| hi-letter-006.check.3 | letter_id | nothing shown | सुनो और वह अक्षर ढूँढो। | ऊ / उ / ई | **उ** | 0 |
| hi-letter-006.remediation_guided.1 | not_letter | nothing shown | कौन सा अक्षर ऊ नहीं है? | उ / ऊ | **उ** | 2 |
| hi-letter-006.remediation_guided.2 | word_to_letter | nothing shown | शब्द सुनो। यह किस अक्षर से शुरू होता है? | इ / ऊ / अ | **ऊ** | 2 |
| hi-letter-006.remediation_check.1 | letter_id | nothing shown | तुम कौन सा अक्षर सुन रहे हो? | ऊ / ऋ / आ | **ऊ** | 0 |
| hi-letter-006.remediation_check.2 | letter_id | nothing shown | मैंने कौन सा अक्षर बोला? | ए / ई / ऊ | **ऊ** | 0 |
| hi-letter-006.remediation_check.3 | word_to_letter | nothing shown | सुनो: इस शब्द का पहला अक्षर कौन सा है? | उ / ऊ / इ | **ऊ** | 0 |

### Tamil

**ta-letter-002** (tamil, variant `letter_with_word`, prerequisite ta-a)

Objective: எழுத்தை அடையாளம் காணுங்கள்: ஆ (Recognise the Tamil letter ஆ.)

*1. Introduce*

- `ta-letter-002.introduce.1` [big letter(s) ஆ] "இது ஆ என்ற எழுத்து."
- `ta-letter-002.introduce.2` [letter ஆ + word ஆடு + picture en_goat.webp] "ஆ – ஆடு. ஆடு என்ற சொல் ஆ என்ற எழுத்தில் தொடங்குகிறது."

*2. Demonstrate*

- `ta-letter-002.demonstrate.1` [big letter(s) ஆ] "ஆ என்ற எழுத்தைக் கவனமாகப் பாருங்கள். இது ஆ."
- `ta-letter-002.demonstrate.2` [letter ஆ + word ஆடு + picture en_goat.webp] "ஆடு ஆ என்ற எழுத்தில் தொடங்குகிறது."
- `ta-letter-002.demonstrate.3` [big letter(s) இ] "இது இ. இ என்பது ஆ அல்ல. இது வேறு எழுத்து."
- `ta-letter-002.demonstrate.4` [big letter(s) ஈ] "இது ஈ. ஈ என்பது ஆ அல்ல. இது வேறு எழுத்து."
- `ta-letter-002.demonstrate.5` [big letter(s) இ  ஆ  ஈ] "புதிர்: இவற்றில் ஒன்று மட்டுமே ஆ. இ ஆ அல்ல. ஈ ஆ அல்ல. எனவே மீதமுள்ளதே ஆ."

*6. Remediation explain (only after a failed check)*

- `ta-letter-002.remediation_explain.1` [big letter(s) ஆ ஆ ஆ] "கண்களை மூடுங்கள். கேளுங்கள்: ஆ. மெதுவாகச் சொல்லுங்கள்: ஆ."
- `ta-letter-002.remediation_explain.2` [big letter(s) ஈ  ஆ  இ] "இப்போது கண்களைத் திறந்து ஆ வடிவத்தைப் பாருங்கள். இ வடிவம் வேறு."
- `ta-letter-002.remediation_explain.3` [picture en_goat.webp captioned ஆடு] "ஆடு என்ற சொல்லை மெதுவாகச் சொல்லுங்கள். முதல் ஒலி ஆ ஒலி."

*3-5, 7. Questions* (guided = 2 hints, may reveal on hint 2; practice = 2 hints that never reveal; check = no hints)

| id | task | visual | prompt | options | answer | hints |
|---|---|---|---|---|---|---|
| ta-letter-002.guided.1 | letter_id | big letter(s) ஆ | இது எந்த எழுத்து? | இ / ஆ / ஈ | **ஆ** | 2 |
| ta-letter-002.guided.2 | letter_id | nothing shown | கேளுங்கள். இது எந்த எழுத்து? | ஆ / அ / உ | **ஆ** | 2 |
| ta-letter-002.guided.3 | not_letter | big letter(s) ஆ | ஆ அல்லாத எழுத்து எது? | இ / ஆ | **இ** | 2 |
| ta-letter-002.practice.1 | letter_id | nothing shown | நீங்கள் எந்த எழுத்தைக் கேட்கிறீர்கள்? | ஊ / ஆ / எ | **ஆ** | 2 |
| ta-letter-002.practice.2 | letter_id | nothing shown | கவனமாகக் கேளுங்கள். கேட்ட எழுத்தைத் தேர்ந்தெடுங்கள். | இ / ஏ / ஆ | **ஆ** | 2 |
| ta-letter-002.practice.3 | word_to_letter | nothing shown | சொல்லைக் கேளுங்கள். அது எந்த எழுத்தில் தொடங்குகிறது? | ஆ / ஈ / அ | **ஆ** | 2 |
| ta-letter-002.practice.4 | letter_id | nothing shown | கேட்டு, அந்த எழுத்தைக் கண்டுபிடியுங்கள். | ஆ / உ / ஊ | **ஆ** | 2 |
| ta-letter-002.practice.5 | not_letter | big letter(s) ஆ | ஆ அல்லாத எழுத்து எது? | ஈ / ஆ | **ஈ** | 2 |
| ta-letter-002.practice.6 | letter_id | nothing shown | இன்னொரு முறை கேளுங்கள். எழுத்தைக் கண்டுபிடியுங்கள். | ஆ / எ / அ | **அ** | 2 |
| ta-letter-002.check.1 | word_to_letter | nothing shown | கேளுங்கள்: இந்தச் சொல்லின் முதல் எழுத்து எது? | ஈ / ஏ / ஆ | **ஆ** | 0 |
| ta-letter-002.check.2 | letter_id | nothing shown | எந்த எழுத்து இந்த ஒலியைத் தருகிறது? | ஆ / இ / அ | **ஆ** | 0 |
| ta-letter-002.check.3 | letter_id | nothing shown | கேட்டு, அந்த எழுத்தைக் கண்டுபிடியுங்கள். | ஆ / அ / உ | **அ** | 0 |
| ta-letter-002.remediation_guided.1 | not_letter | nothing shown | ஆ அல்லாத எழுத்து எது? | அ / ஆ | **அ** | 2 |
| ta-letter-002.remediation_guided.2 | word_to_letter | nothing shown | சொல்லைக் கேளுங்கள். அது எந்த எழுத்தில் தொடங்குகிறது? | ஊ / ஆ / ஏ | **ஆ** | 2 |
| ta-letter-002.remediation_check.1 | letter_id | nothing shown | நீங்கள் எந்த எழுத்தைக் கேட்கிறீர்கள்? | ஆ / இ / எ | **ஆ** | 0 |
| ta-letter-002.remediation_check.2 | letter_id | nothing shown | நான் சொன்ன எழுத்து எது? | ஈ / உ / ஆ | **ஆ** | 0 |
| ta-letter-002.remediation_check.3 | word_to_letter | nothing shown | கேளுங்கள்: இந்தச் சொல்லின் முதல் எழுத்து எது? | அ / ஆ / ஊ | **ஆ** | 0 |

### Extra: a letter_only example (English)

**en-letter-017** (english, variant `letter_only`, prerequisite en-letter-016)

Objective: Recognise the letter Q, uppercase Q and lowercase q.

*1. Introduce*

- `en-letter-017.introduce.1` [big letter(s) Q q] "This is the letter Q. It has a big Q and a small q."
- `en-letter-017.introduce.2` [big letter(s) Q] "Listen to the letter Q. Say it with me: Q."

*2. Demonstrate*

- `en-letter-017.demonstrate.1` [big letter(s) Q] "This is big Q. It is the capital letter."
- `en-letter-017.demonstrate.2` [big letter(s) q] "This is small q. Big Q and small q are the same letter."
- `en-letter-017.demonstrate.3` [big letter(s) Q] "Now listen to the letter Q. Say it with me: Q."
- `en-letter-017.demonstrate.4` [big letter(s) R] "This is R. R is not Q. It is a different letter."
- `en-letter-017.demonstrate.5` [big letter(s) R  Q  S] "A puzzle: only one of these letters is Q. R is not Q. S is not Q. So the other one is Q."

*6. Remediation explain (only after a failed check)*

- `en-letter-017.remediation_explain.1` [big letter(s) Q Q Q] "Close your eyes. Listen: Q. Say it softly: Q."
- `en-letter-017.remediation_explain.2` [big letter(s) S  Q  R] "Now open your eyes and look at the shape of Q. R has a different shape."
- `en-letter-017.remediation_explain.3` [big letter(s) Q q] "When you hear Q, look for this shape: big Q and small q."

*3-5, 7. Questions* (guided = 2 hints, may reveal on hint 2; practice = 2 hints that never reveal; check = no hints)

| id | task | visual | prompt | options | answer | hints |
|---|---|---|---|---|---|---|
| en-letter-017.guided.1 | letter_id | big letter(s) q | Which big letter is the same as this small letter? | R / Q / S | **Q** | 2 |
| en-letter-017.guided.2 | letter_id | nothing shown | Listen. Which letter is it? | Q / P / O | **Q** | 2 |
| en-letter-017.guided.3 | not_letter | big letter(s) Q | Which letter is NOT Q? | R / Q | **R** | 2 |
| en-letter-017.practice.1 | letter_id | nothing shown | Which letter do you hear? | N / Q / M | **Q** | 2 |
| en-letter-017.practice.2 | letter_id | nothing shown | Listen carefully. Tap the letter you hear. | R / L / Q | **Q** | 2 |
| en-letter-017.practice.3 | letter_id | nothing shown | Which letter did I say? | S / Q / P | **Q** | 2 |
| en-letter-017.practice.4 | letter_id | big letter(s) Q | Which small letter is the partner of this big letter? | r / s / q | **q** | 2 |
| en-letter-017.practice.5 | not_letter | big letter(s) Q | Which letter is NOT Q? | S / Q | **S** | 2 |
| en-letter-017.practice.6 | letter_id | nothing shown | Listen once more. Find the letter. | Q / O / P | **P** | 2 |
| en-letter-017.check.1 | letter_id | nothing shown | Tap the letter that you hear. | N / L / Q | **Q** | 0 |
| en-letter-017.check.2 | letter_id | nothing shown | Which letter am I saying now? | Q / R / M | **Q** | 0 |
| en-letter-017.check.3 | letter_id | nothing shown | Listen and find the letter. | Q / P / S | **P** | 0 |
| en-letter-017.remediation_guided.1 | not_letter | nothing shown | Which letter is NOT Q? | P / Q | **P** | 2 |
| en-letter-017.remediation_guided.2 | letter_id | nothing shown | Listen. Which letter is it? | P / Q / N | **Q** | 2 |
| en-letter-017.remediation_check.1 | letter_id | nothing shown | Which letter do you hear? | Q / O / M | **Q** | 0 |
| en-letter-017.remediation_check.2 | letter_id | nothing shown | Which letter did I say? | S / L / Q | **Q** | 0 |
| en-letter-017.remediation_check.3 | letter_id | nothing shown | Tap the letter that you hear. | Q / P / R | **P** | 0 |

## 5. Skipped (not planned here) and why

- `en-a`: already planned in the approved pilot (pilot_teaching_plans.json)
- `te-a`: already planned in the approved pilot (pilot_teaching_plans.json)
- `hi-a`: already planned in the approved pilot (pilot_teaching_plans.json)
- `ta-a`: already planned in the approved pilot (pilot_teaching_plans.json)
- `en-word`: word builder lesson, level 2: not plain letter recognition
- `en-trace`: tracing path (the 'all letters' trace lesson), level 1: not letter recognition, no tracing/stroke order is taught
- `en-story`: story lesson, level 3: not letter recognition
- `english-story-002`: story lesson, level 4: not letter recognition
- `te-word`: word builder lesson, level 2: not plain letter recognition
- `te-trace`: tracing path (the 'all letters' trace lesson), level 1: not letter recognition, no tracing/stroke order is taught
- `te-story`: story lesson, level 3: not letter recognition
- `telugu-story-001`: story lesson, level 4: not letter recognition
- `hi-word`: word builder lesson, level 2: not plain letter recognition
- `hi-trace`: tracing path (the 'all letters' trace lesson), level 1: not letter recognition, no tracing/stroke order is taught
- `hi-story`: story lesson, level 3: not letter recognition
- `hindi-story-002`: story lesson, level 4: not letter recognition
- `ta-word`: word builder lesson, level 2: not plain letter recognition
- `ta-trace`: tracing path (the 'all letters' trace lesson), level 1: not letter recognition, no tracing/stroke order is taught
- `ta-story`: story lesson, level 3: not letter recognition
- `tamil-story-002`: story lesson, level 4: not letter recognition

## 6. Letters that fell to a weaker template (so no 'begins with' claim)

- English (2 letter_only): en-letter-017, en-letter-024
- Telugu (40 letter_only): te-letter-007, te-letter-008, te-letter-011, te-letter-013, te-letter-014, te-letter-015, te-letter-017, te-letter-018, te-letter-019, te-letter-020, te-letter-021, te-letter-022, te-letter-023, te-letter-024, te-letter-025, te-letter-026, te-letter-027, te-letter-028, te-letter-029, te-letter-030, te-letter-031, te-letter-032, te-letter-033, te-letter-034, te-letter-035, te-letter-036, te-letter-037, te-letter-039, te-letter-040, te-letter-041, te-letter-042, te-letter-043, te-letter-044, te-letter-045, te-letter-046, te-letter-047, te-letter-048, te-letter-049, te-letter-050, te-letter-051
- Hindi (32 letter_only): hi-letter-012, hi-letter-013, hi-letter-015, hi-letter-016, hi-letter-018, hi-letter-019, hi-letter-020, hi-letter-021, hi-letter-022, hi-letter-023, hi-letter-024, hi-letter-025, hi-letter-026, hi-letter-027, hi-letter-028, hi-letter-029, hi-letter-030, hi-letter-031, hi-letter-032, hi-letter-033, hi-letter-035, hi-letter-036, hi-letter-037, hi-letter-038, hi-letter-039, hi-letter-040, hi-letter-041, hi-letter-042, hi-letter-043, hi-letter-044, hi-letter-045, hi-letter-046
- Tamil (20 letter_only): ta-letter-004, ta-letter-012, ta-letter-013, ta-letter-014, ta-letter-015, ta-letter-016, ta-letter-017, ta-letter-018, ta-letter-019, ta-letter-020, ta-letter-021, ta-letter-022, ta-letter-023, ta-letter-024, ta-letter-025, ta-letter-026, ta-letter-027, ta-letter-028, ta-letter-029, ta-letter-030

Source words that do NOT begin with exactly their letter (not used for any 'begins with' claim):

- Telugu: letter ఒ, source word ఒంటె (camel)
- Telugu: letter చ, source word చిలుక (parrot)
- Telugu: letter ప, source word పండు (fruit)
- Tamil: letter க், source word கல் (stone)
- Tamil: letter ந், source word நாய் (dog)
- Tamil: letter ப், source word பூனை (cat)
- Tamil: letter ம், source word மரம் (tree)

## 7. UNVERIFIED / to review (applies to every plan)

- Every Telugu, Hindi and Tamil sentence is AI-written and not checked by a native speaker (grammar, naturalness, register, age suitability); native_review_needed is true on all 149 plans, English included (educator review).
- Text-to-speech was not heard: how a bare letter is spoken (name vs sound), anusvara/visarga letters, Tamil pure consonants, rare letters (listed per plan in review.items_to_review).
- Content is not educator-verified, not audio-verified, not UI-verified; no UI reads the file yet; the new fields (empty caption, `variant`, `not_letter`) need ui-creator work and ui-verifier checks.
- Variety limitation (accepted by the verifier for the pilot, to be judged again for the rollout): with a letter, two neighbours and at most one picture word, check items repeat the same few letters and differ by task, wording, option set and position. letter_only checks are all listen-and-pick; this is a real limit of the source data.
- Decision RR-2: wrong letters come from earlier-taught letters (pool of 7) and one spaced-review item each in practice and check; the verifier to judge.
- English X is taught letter-only (the source word Xylophone starts with the sound z); educator to decide.
- Where a picture word exists in the source but its picture file does not (or no file is named), the plan still uses the word in teaching steps and lists the path in review.assets_missing; some paths are proposed names following the existing file naming, not existing files.
- Hindi/Telugu/Tamil prompts such as 'big letter' for the on-screen letter and 'sound of the letter' need confirmation.
- Nothing here is approved. Next step: content-verifier.
