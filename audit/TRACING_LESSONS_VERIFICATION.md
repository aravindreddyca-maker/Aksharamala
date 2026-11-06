# Tracing lessons verification (ui-verifier, round 3)

Build `app.aksharamala` debug (installed 2026-10-31 12:28:30), emulator-5554, landscape 2400x1080. Screenshots y01-y22 in the scratchpad. Verdict: **PASS with 3 minor REVISE items (T1, T2, T3)**.

## Order on the English Forest map (Level 1) - PASS
"Trace big A" (card 1), "Trace small a" (card 2, tagged "Next adventure" until done), then "A is for Apple" (card 3) (y04, y05, y13). The recommended-quest banner followed progress: "Trace small a" before it was done, "Which letter is this?" after (y12, y20).

## Trace big A - PASS
Route map shown: pale road, dashed route, arrows, numbered dots 1, 2, 3 (y06). I traced both legs and the crossbar with adb swipes; the green ink covered the road (y07), Check gave "Well written!" (y08) and "I traced it!" became enabled. The quest was already completed, so the dialog said "You already collected every star in this quest. Great practice!" (y09); stars unchanged (72).

## Trace small a - PASS (completion + stars), with T1 and T2
- No arrows or numbers; only a very pale "a" in the pad (y14). Left panel shows the big "a" and the instruction.
- A deliberately bad scribble (one stroke in the corner) and Check gave "Follow the shape of the number" (y17) and kept "I traced it!" disabled. T1 (minor wording): the message says "number" on a letter lesson.
- A rough hexagon-like "a" (y15) got "Well written!" (y16) and enabled "I traced it!". A second, cleaner attempt then "I traced it!" gave "You earned 3 stars and completed this quest." and stars went 72 to 75 (y18). Completion and stars work once; the already-done big A replay paid nothing.
- Could a child follow the guide? The guide is a thin, very pale grey-green "a" (about 13% ink), roughly one third of the pad (y14). It reads, but with low contrast, no start dot and no stroke order. A child could follow the outline but not the order. The rough hexagon scribble also passed, so acceptance is lenient (practice only, as the handoff says). T2 (minor): consider a darker guide for lowercase.

## All letters path - PASS with T3
Two counters: "4 of 26 letters traced" and "0 of 26 small letters traced", tiles with a small lowercase badge under each big letter, grey (y21). Opening A then the next step shows "1 / 26 · small" with the small a, the Apple picture, and "Next: B" (y22). Big then small per letter works.
T3 (minor): I had just completed the quest "Trace small a" and the path still says 0 of 26 small letters and the small-a badge is grey. The quest and the path use different lesson ids, so the same small a must be traced again (and may pay stars again). Decide if intended.

## Telugu / Hindi / Tamil - PASS (unchanged)
Telugu Kingdom map has no small-letter quests (e4); Hindi and Tamil lessons opened in round 2 unchanged. Several Telugu cards share the identical title "ఈ అక్షరం ఏది?" (pre-existing).

## Not verified
A real finger on a real phone; MaskValidator strictness beyond these swipes; Hindi/Tamil tracing quests; the tile badge turning green after tracing a small letter in the path; titles such as "2 / 26 · big" for later letters.
