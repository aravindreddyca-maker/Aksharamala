# Can a child learn from scratch? Audit of 30 October 2026

Question asked: can a child with no prior knowledge learn the letters and numbers
in each language, and is the screen easy to use? This is a read-only check of the
app as built at the commit that adds this file, using the real lesson data (a
throw-away test printed the counts below). It builds on
`COMPLETE_QA_AUDIT_2026-10-29.md` and does not repeat it.

## What a child can do today

| | English | Telugu | Hindi | Tamil | Numbers |
|---|---:|---:|---:|---:|---:|
| Letters / symbols the app teaches | 26 | 51 | 46 | 30 | 0–10 |
| Quests for Level 1 (ages 3–4) | 26 | 51 (+10 with the preview switch) | 46 | 30 | 13 |
| Quests for Level 2 (ages 5–6) | 32 | 28 | 28 | 28 | 56 |
| Quests for Level 3 (ages 7–9) | **1** | **1** | **1** | **1** | **2** |
| Quests for Level 4 (ages 10–12) | **1** | **1** | **1** | **1** | **2** |
| Letters that come with a picture word | 26 words, 5 pictures | 14 words, 12 pictures | 14 words, 4 pictures | 16 words, 4 pictures | — |

Level 1 and Level 2 can be followed from the very first letter. Levels 3 and 4
cannot: they hold one story quest per world.

## Findings

Fixed in this change:

1. **Only the first letter could be traced.** The old tracing quests taught A, అ,
   अ and அ only. Every letter can now be traced: 26 English, 51 Telugu, 46 Hindi,
   30 Tamil. A scribble is refused; a traced letter is accepted (shape check,
   not stroke order).
2. **Nothing said "go on to the next letter".** A traced letter now offers
   "Next: B" (and the last letter offers "All letters"). Arrows move to any
   letter freely.
3. **The letters were hard to find.** The quest map listed them as dozens of
   cards all titled "Which letter is this?". A new **All letters** button on
   each language's map opens one page with every letter, a tick on the ones
   done, and a highlighted "start here".
4. **The "Great!" line was hidden behind the Next / Finish button** on the new
   lessons; it is now at the top of the answers.
5. **Level could not be changed for a saved profile.** Anyone can now pick any
   level from the profile list or the home screen.

Still open, most important first:

1. **Levels 3 and 4 are almost empty** (above). The pack has the material in
   outline only (grammar, comprehension, writing, advanced maths). A child who
   picks Level 3 or 4 finds almost nothing. Because levels are free to choose,
   a beginner can still use Level 1, but older children have no path.
2. **Letters are taught alone.** The vowel-sign (matra) and letter-combination
   records in the pack are blueprints (the combined letter is missing), so a
   child cannot yet learn to build syllables or read words in Telugu, Hindi or
   Tamil. Spelling records also have no letters to arrange.
3. **Picture words are thin.** Telugu has 12 pictures for 14 words, Hindi and
   Tamil only 4 each, English 5 of 26. Letters with no picture show the word
   alone (or just the letter). 
4. **Tamil uses pure consonants (க், ங்…).** That follows the pack's list, but
   primers usually teach க, ங, ச… first. A Tamil educator should decide.
5. **No verified stroke order, no recorded audio.** Handwriting is shape-checked
   only; the Listen button uses the phone's voice, which no native speaker has
   checked. All Telugu, Hindi and Tamil sentences written for the app are drafts
   for review.
6. **Numbers stop at 10 in the new lessons.** 11–100 and the four operations
   exist as pack records or age 5–6 content but are not a guided path from zero.
7. **Parent switch still hides 10 Telugu and the Number Galaxy 0–10 lessons**
   by default ("Try the new lessons"). Decide whether the preview is now the
   normal path.

## Ease of use

Checked on the 960×540 and 640×360 landscape layouts in tests, and on the
emulator for the profile screen:

- One clear route: Start → learner → home → a language → **All letters** → tap
  the highlighted letter → trace → **Next**.
- Right and wrong answers are shown at once with a tick or a cross, colour, a
  short line in the child's language, and a buzz.
- Nothing is locked: any letter, any level, any order.
- Not yet checked with real children, with screen-reader users, or on a phone
  held in portrait.
