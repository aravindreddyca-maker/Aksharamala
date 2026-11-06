# Teaching plan data schema (pilot, schema_version 1)

STATUS: pilot_unverified. Written by content-creator; no UI reads this file yet. Nothing here has been rendered or verified.

## File
`pilot_teaching_plans.json`: `{schema_version, status, lessons[]}`. Each lesson has `lesson_id, world, level, locale, title, objective, mastery, introduce[], demonstrate[], guided[], practice[], check[], remediation{explain[], guided[], check[]}, review`. Number Galaxy also has `prerequisites` (list, like `Lesson.prerequisites`).

## mastery (all data, none hardcoded)
- `check_total` (3), `check_pass` (2): pass mark of the first check.
- `remediation_pass` (2): pass mark (of 3) of the remediation check.
- `max_remediation_cycles` (2): remediation can be offered at most this many times.
- `after_limit`: `"offer_parent_support"` - when the limit is reached the UI marks the concept "needs support", shows parent support, and lets the child continue. It never loops forever.

## STEP = {id, text, speech, visual}   QUESTION = {id, prompt, speech, options[2-4], answer, visual, hints[], wrong_feedback{}, explanation, difficulty 1-3, optionPictures?{}}
- `hints` is a ladder: hint 1 is a nudge and never contains the answer; hint 2 may reveal. `check` and `remediation.check` have `hints: []`.
- `options` are stored in a mixed order and the UI may shuffle them. `wrong_feedback` has exactly one key per wrong option.
- `optionPictures` maps an option string to an existing asset path (shown instead of / beside the text).

## QUESTION.task (optional)
One of letter_id, pick_word, not_word, word_to_letter, name_picture, hear_pick. Every task type in a check or remediation check also appears earlier (demonstrate, guided or practice).

## VISUAL fields
- `{"type":"none"}` nothing shown (audio-only or symbolic item).
- `{"type":"glyph","glyph":"A"}` a big letter.
- `{"type":"picture","asset":"assets/...","caption":"..."}` a picture. `caption` may be an EMPTY STRING: question pictures use "" so the answer is never printed; teaching steps keep a caption.
- `{"type":"letterWord","glyph":"A","word":"Apple","asset":"assets/..."}` letter beside word and picture.
- `{"type":"objects","groups":[{"emoji":"E","count":n},...],"operator":"+","revealCount":k,"countAll":bool,"result":n?,"showResult":bool?}`
  - `groups` are drawn left to right with `operator` between them.
  - `revealCount` = how many GROUPS (not objects) are visible in this step.
  - `countAll` true = number every visible object 1..n across the visible groups.
  - `result` = the total; drawn as "= n" only when `showResult` is true. Question visuals omit `result` and set `showResult: false`. A single group (one entry in `groups`, `revealCount` 1) is drawn without an operator (used to count 1..10 in the introduction).
- `{"type":"numberLine","from":0,"to":10,"start":a,"jump":b,"showHops":bool}`
  - draws the line from `from` to `to` with a marker on `start`.
  - `showHops` true = draw the `jump` hops (and the landing point) - used in teaching steps and guided items. `showHops` false = draw only the line and the start marker; used in practice/check/remediation-check so the answer is not shown. `jump` is still the second addend (data), renderers must ignore it when showHops is false. The introduce step uses start 0, jump 1, showHops false just to show the line.

## Fields used by this pilot but not yet implemented by any UI
`revealCount, countAll, result, showResult, showHops`, empty `caption`, and the new `mastery` fields. ui-creator must implement them; ui-verifier must check the rendering.

## IMPLEMENTED by the teaching UI (lib/src/teaching, update of 2026-10-31)
All fields above are implemented, plus the following values used by the number rollout. The plan validator accepts exactly these and rejects anything else.

### objects `operator`, `takeAway`, `labels`, and the 20-object cap
Allowed `operator`: `"+"`, `"-"` (ASCII hyphen), `"\u2212"` (the true minus sign, same meaning as `"-"`), `"vs"`. Any other value makes the plan invalid (its lesson then keeps its old screen).
- **At most 20 objects in all** (the sum of every group's `count`; for `-` the one group's count). More is rejected: use `baseTen` for big numbers.
- `"+"`: groups left to right with a plus between them (any number of groups; a single group has no sign).
- `"-"` / minus sign: **ONE group** (`groups` has exactly one entry, `count` = the first number) plus `takeAway` (integer, 0..count, default 0). The last `takeAway` objects are faded and crossed out (animated; instant with reduced motion) and "- n" is shown beside the group. `takeAway` 0 (or absent) draws the plain group. Show the start in one step (`takeAway` 0) and the taking away in the next step. `countAll` numbers only the objects that are left (1..count-takeAway). `result` is drawn as "= n" only when `showResult` is true. `takeAway` is rejected with any other operator. Two groups with `-` are rejected.
- `"vs"`: EXACTLY two groups, nothing added or removed. Optional `labels`: exactly two non-empty strings; with labels the groups are drawn as two labelled rows (label above its group, a neutral "vs" mark between the rows); without labels they sit side by side with the "vs" mark. `countAll` numbers EACH group from 1 on its own. `result` is never drawn.
- `revealCount` must be within 0..number of groups.
- Emoji size shrinks with the number of visible objects.

### baseTen
`{"type":"baseTen","tens":n,"ones":m,"showTotal":bool}` with `tens` 0-9 and `ones` 0-9 (anything else is rejected). One bar (ten segments) per ten, one single cube per one, captions "tens" and "ones" (no numbers). The total ("= N") is drawn only when `showTotal` is true; question visuals set it false. Overflow-safe for 9 tens + 9 ones.

### numberLine
- `start` must be on the line (`from <= start <= to`). When `showHops` is true the landing point `start + jump` must also be on the line.
- `jump` > 0: hops to the right. `jump` < 0: hops to the LEFT (count back), |jump| hops, with an arrow head on the last hop. `jump` == 0 with `showHops` true: no hops; the marker stays on `start` (a small loop is drawn over it and the landing dot sits on the start number).
- `showHops` false: the line and the start marker only, whatever `jump` is (it is ignored, nothing leaks the answer).
- Long lines (for example 0 to 90): tick marks and labels are thinned (1, 2, 5, 10, 20, 50 ...) so they never pile up; the start and both ends are always labelled.

### Plan loading (not data, for information)
Plan files are split into one JSON string per lesson off the main isolate at start-up and each lesson is parsed and validated only when it is first opened.
