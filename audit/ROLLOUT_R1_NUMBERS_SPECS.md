# Rollout R1 - Number Galaxy teaching plans: specification

STATUS: `rollout_unverified`. Written by content-creator. Nothing here is educator-verified, audio-verified, UI-verified or approved; the independent content-verifier has not seen it. Every statement below says what the generator DOES, not that the result is correct for children.

## 1. What was produced

- `content/teaching_pending/rollout_numbers.json` (the source; an identical copy `content/teaching/rollout_numbers.json` is written by the generator's `promote()` only after `tool/check_rollout_numbers.py` and the Dart parser test pass; use `--no-promote` to skip) - 72 teaching plans (schema_version 1, same schema as `pilot_teaching_plans.json`, see `content/teaching/SCHEMA.md`): 1,008 questions and 699 teaching steps. Revision 2 (after the content-verifier's Rollout R1 report) is described in section 8.
- `tool/gen_teaching_numbers.py` - the generator (python -X utf8 -I tool/gen_teaching_numbers.py). Output is deterministic (two runs gave identical files).
- Lesson ids covered: `numbers-count-000` to `numbers-count-010` (11), `numbers-56-001` to `numbers-56-054` (54: identify_tens 9, compare_two_digit_numbers 8, add_within_20 12, subtract_within_20 12, continue_number_pattern 6, identify_shape_properties 4, understand_everyday_math 3), and the legacy `num-count`, `num-names`, `num-subtract`, `num-multiply`, `num-divide`, `num-fraction`, `num-percent` (7). `num-add` is already in the pilot file and is not repeated. No lesson was left uncovered.
- Existing lesson id, level, title, objective and prerequisites are copied from the real sources (see section 6 for where each came from) and checked against them by the checker.

## 2. How a plan is built (all skills)

Every plan has the pilot's shape: introduce (2 steps) -> demonstrate (4-5 steps, concrete -> pictorial -> symbolic, one step at a time, the complete worked solution is shown only here and in guided items) -> guided (2 questions, 2-step hint ladder, number lines may show hops) -> practice (4 questions, 2-step hint ladder, no hops, no results drawn) -> check (3 questions, no hints, `showResult` false, `showHops` false, no captions) -> remediation (3 explanation steps in a different representation, 2 guided questions, 3 alternate check questions). Mastery data is the pilot's: pass 2 of 3, remediation pass 2 of 3, at most 2 remediation cycles, then `offer_parent_support`.

Rules the generator applies to every question:

1. The answer is computed in code from the lesson's numbers; it is never typed. Distractors come from named error kinds (an operand you started with, a near miss, a distant number, the wrong operation, the whole number, forgetting the ten, reversed digits, a reversed sign, and so on). Each distractor is guaranteed different from the answer, distinct, and never two neighbours of the answer in the same item. Each wrong option gets feedback written for its error kind; no feedback or hint 1 contains the answer.
2. Options are stored in a mixed order. The key position in the check rotates by lesson (0, 1 or 2) so a lesson's three check items use three different positions (216 check items: 72 / 72 / 72 per position; the same for the remediation check). The UI should still shuffle (see limits).
3. Problem instances are drawn from a pool without replacement: no operand pair, number, shape-task or word is used twice in a lesson (exceptions: the count lessons, which are about one number, and num-names, which may reuse a number in a different task), and the lesson's own worked-example numbers (both orders) never appear in guided, practice, check or remediation items. Check items use a different task or different numbers from the guided and practice items.
4. Remediation is NOT the demonstration reordered: it uses a different strategy or representation, different numbers, and its own alternate check items (details per skill below).
5. Option text, prompts, hints and speech are English only; speech uses number words (no digits).

## 3. Per-skill template (plain language)

### 3.1 numbers-count-000 to numbers-count-010 (11 lessons, level 1)
Each lesson is one number n (0-10). Taught: the numeral and its name; counting n objects touching each once; the same count with different things; the number line (start at 0, n steps, land on n); which of n and its neighbour is bigger or smaller (the lesson's own pair, as in the existing lesson: even n asks "bigger", odd n asks "smaller"). Question tasks: `count` (objects -> number), `line` (marker on a number line -> number), `compare3` (biggest or smallest of three numbers that include n). Distractors: one more/one less, a number about three away, a number two away; all 0-10. Because the lesson is about ONE number, answers repeat by design, but every item differs in objects/emoji, prompt wording and distractors; the practice also counts a neighbouring number so the child cannot just answer n. Remediation: count in two parts (keep the first part in your head and count on), then find n on the number line. For 0 (no object group can be drawn) short stories with an empty container are used with visual none.

#### Example: numbers-count-003 - "Number 3" (level 1)

Objective (kept from the source): Count objects: 3  Prerequisites: ['numbers-count-002']

Teaching steps (demonstrate): Count the things one by one, touching each one only once: 1, 2, 3. There are 3. | Other things can be counted too. Here are 3 more things. Count: 1, 2, 3. It is the same number, 3. | On the number line, start at 0 and take 3 steps. We land on 3. | Which number is smaller, 3 or 4? On the number line, the number further to the right is bigger. So 3 is smaller.

Remediation explanation: Let us count in two parts. Here are the first 1. Say 1. | Now the other 2. Keep 1 in your head and count on: 2, 3. Altogether, 3. | Show 3 with your fingers and find 3 on the number line. It is three.

| item | task | prompt | visual | options (stored order) | KEY |
|---|---|---|---|---|---|
| guided.1 | count | How many things are in this group? | objects 3 | 3, 5, 2 | **3** |
| guided.2 | line | We start at 0 and take 3 steps. Which number do we land on? | numberLine 0..10 start 0 jump 3 hops=True | 6, 3, 2 | **3** |
| practice.1 | count | Count carefully. How many are there? | objects 5 | 3, 5, 2 | **5** |
| practice.2 | line | Where is the marker? Pick the number. | numberLine 0..10 start 3 jump 0 hops=False | 2, 1, 3 | **3** |
| practice.3 | compare3 | Find the biggest number. | none | 9, 2, 3 | **9** |
| practice.4 | count | Touch and count. How many? | objects 3 | 6, 3, 5 | **3** |
| check.1 | count | How many are in the picture? | objects 3 | 3, 7, 5 | **3** |
| check.2 | line | Read the number under the marker. | numberLine 0..10 start 3 jump 0 hops=False | 2, 3, 0 | **3** |
| check.3 | compare3 | Which number is the smallest? | none | 6, 9, 3 | **3** |
| rem guided.1 | count | Tell how many there are. | objects 5 | 9, 4, 5 | **5** |
| rem guided.2 | line | We start at 0 and take 5 steps. Which number do we land on? | numberLine 0..10 start 0 jump 5 hops=True | 5, 7, 2 | **5** |
| rem check.1 | count | How many are there? | objects 3 | 7, 3, 1 | **3** |
| rem check.2 | line | Which number has the marker on it? | numberLine 0..10 start 3 jump 0 hops=False | 4, 0, 3 | **3** |
| rem check.3 | compare3 | Which of these numbers is the biggest? | none | 7, 3, 4 | **7** |

Wrong-answer feedback example (check.1): "7": That is quite far off. Touch each one as you say the numbers.; "5": Not quite. Count again, one at a time.

### 3.2 identify_tens - numbers-56-001 to 009 (13, 23, ... 93)
Taught with that lesson's own number using the new `baseTen` visual (a bar per ten, a cube per one; never more than a few dozen drawn shapes, no 98-emoji pictures): full tens, then the single ones left after the tens; left digit = full tens, digit in the ones place = single ones; "N = T tens + O ones". One wording is used for every item and taught first (demonstrate 2-3): "In N, how many full tens are there?" and "In N, how many single ones are left after the tens?". Tasks: `tens_pic` and `ones_pic` (count blocks / loose ones in a picture), `tens_sym` and `ones_sym` (the same from the numeral only), `build` (which number is T tens and O ones). Practice and check use OTHER two-digit numbers (never the lesson's own number; picture items always have loose ones; the tens digit never equals the ones digit so the reversed-digit trap is real). Distractors: the other digit, the whole number, one off, reversed digits, one ten too many or too few. Remediation: cover the right digit and read the tens, then packets of 10 sweets (bars) with loose sweets (cubes) for a different number, then the same equation.

#### Example: numbers-56-004 - "43: tens and ones" (level 1)

Objective (kept from the source): Learner can identify tens in place_value.  Prerequisites: none

Teaching steps (demonstrate): Here is the number 43. First, the full tens. Each bar is one full ten. There are 4 full tens. | Then the single ones that are left after the tens. Each cube is one single one. There are 3 single ones left. | The digit on the left, 4, tells the full tens. The digit in the ones place, on the right, 3, tells the single ones left after the tens. | So 43 is 4 tens and 3 ones. Ten ones make one ten, so 4 tens is 40. | We can write it like this: 43 = 4 tens + 3 ones.

Remediation explanation: Let us try another way. Look at the number 96. The digit on the left tells how many full tens. Cover the digit on the right with your finger and read the tens. | Think of sweets in packets of 10. The bars are the full packets. The cubes are the loose sweets. Here are 9 full packets and 6 loose sweets. | So 96 is 9 tens and 6 ones. The loose ones are the single ones left after the tens.

| item | task | prompt | visual | options (stored order) | KEY |
|---|---|---|---|---|---|
| guided.1 | tens_pic | In 79, how many full tens are there? | baseTen 7 tens 9 ones showTotal=False | 4, 79, 7 | **7** |
| guided.2 | ones_pic | In 39, how many single ones are left after the tens? | baseTen 3 tens 9 ones showTotal=False | 9, 11, 10 | **9** |
| practice.1 | tens_sym | In 60, how many full tens are there? | none | 6, 0, 5 | **6** |
| practice.2 | ones_sym | In 49, how many single ones are left after the tens? | none | 49, 9, 6 | **9** |
| practice.3 | build | Which number is 6 tens and 2 ones? | none | 63, 8, 62 | **62** |
| practice.4 | tens_pic | In 31, how many full tens are there? | baseTen 3 tens 1 ones showTotal=False | 3, 31, 1 | **3** |
| check.1 | ones_pic | In 24, how many single ones are left after the tens? | baseTen 2 tens 4 ones showTotal=False | 24, 2, 4 | **4** |
| check.2 | tens_sym | In 47, how many full tens are there? | none | 4, 7, 6 | **4** |
| check.3 | build | Which number is 9 tens and 8 ones? | none | 88, 98, 17 | **98** |
| rem guided.1 | tens_pic | In 72, how many full tens are there? | baseTen 7 tens 2 ones showTotal=False | 72, 7, 4 | **7** |
| rem guided.2 | ones_pic | In 75, how many single ones are left after the tens? | baseTen 7 tens 5 ones showTotal=False | 7, 4, 5 | **5** |
| rem check.1 | tens_sym | In 95, how many full tens are there? | none | 9, 95, 8 | **9** |
| rem check.2 | ones_pic | In 83, how many single ones are left after the tens? | baseTen 8 tens 3 ones showTotal=False | 8, 3, 0 | **3** |
| rem check.3 | build | Which number is 8 tens and 5 ones? | none | 13, 95, 85 | **85** |

Wrong-answer feedback example (check.1): "24": 24 is the whole number. We want only the single ones left after the tens.; "2": 2 is the digit in the tens place. We want the single ones, the digit on the right.

### 3.3 add_within_20 - numbers-56-010 to 021 (12 lessons, level 2)
Two strategies chosen from the lesson's own numbers: **make ten** when both addends are under 10 and the sum is 10 or more (4+6, 7+8, 9+5, 8+8, 6+7): show the groups, move enough from the second group to make a ten, add the leftover (10 + r), then check on a 0-20 number line; **tens and ones** when the first addend is 10-19 (12+7, 14+5, 11+9, 13+6, 16+3, 10+9, 15+4): split the first number into a ten and ones, add the ones (note when they make another ten), put the ten back, then check on the number line. Tasks: `add_objects`, `add_line` (hops hidden in practice and check), `add_symbolic`, plus `bond10` ("7 + ? = 10", make-ten lessons) or `add_ones` ("add the ones first", tens-and-ones lessons). Pair pools: make-ten pairs 2-9 with sum 10-18; tens-and-ones pairs 11-17 plus 1-9 with sum at most 20. Distractors: an addend, a near miss, a distant number, the difference (wrong operation), the make-ten leftover (forgot to add the ten) or ones-only value. Remediation: start from the BIGGER number and count on the smaller one on the number line (the demonstration used regrouping), and order does not change the total.

#### Example: numbers-56-011 - "Add 7 + 8" (level 2)

Objective (kept from the source): Learner can add within 20 in addition_within_20.  Prerequisites: none

Teaching steps (demonstrate): Here are 7 things. | Now we add 8 more. Counting every one again is slow. Let us make a ten instead. | 7 needs 3 more to make 10. Take 3 from the 8 and put them with the 7. Now we have 10 and 5 left over. | 10 and 5 more make 15. So 7 + 8 = 15. | Check on the number line: start at 7 and count on 8 steps. We land on 15.

Remediation explanation: Here is another way. Look at 5 and 7. Start with the bigger number, 7. Do not count it again: just say 7. | Now count on 5 from 7: 8, 9, 10, 11, 12. We land on 12. | So 7 + 5 = 12. The order does not change the total: 5 + 7 is also 12.

| item | task | prompt | visual | options (stored order) | KEY |
|---|---|---|---|---|---|
| guided.1 | add_objects | How many altogether? | objects 3+8 | 11, 1, 5 | **11** |
| guided.2 | add_line | 3 + 9 = ? | numberLine 0..20 start 3 jump 9 hops=True | 6, 12, 3 | **12** |
| practice.1 | bond10 | 8 + ? = 10 | numberLine 0..10 start 8 jump 0 hops=False | 8, 2, 1 | **2** |
| practice.2 | add_objects | How many altogether? | objects 6+9 | 5, 17, 15 | **15** |
| practice.3 | add_line | 8 + 5 = ? | numberLine 0..20 start 8 jump 5 hops=False | 13, 3, 23 | **13** |
| practice.4 | add_symbolic | 8 + 9 = ? | none | 18, 17, 7 | **17** |
| check.1 | add_objects | How many altogether? | objects 4+8 | 12, 10, 22 | **12** |
| check.2 | add_line | 7 + 7 = ? | numberLine 0..20 start 7 jump 7 hops=False | 7, 14, 4 | **14** |
| check.3 | add_symbolic | 6 + 6 = ? | none | 2, 22, 12 | **12** |
| rem guided.1 | add_objects | How many altogether? | objects 5+5 | 5, 14, 10 | **10** |
| rem guided.2 | add_line | 2 + 9 = ? | numberLine 0..20 start 2 jump 9 hops=True | 11, 2, 7 | **11** |
| rem check.1 | add_objects | How many altogether? | objects 6+8 | 2, 14, 4 | **14** |
| rem check.2 | add_line | 4 + 9 = ? | numberLine 0..20 start 4 jump 9 hops=False | 23, 12, 13 | **13** |
| rem check.3 | add_symbolic | 4 + 7 = ? | none | 11, 1, 4 | **11** |

Wrong-answer feedback example (check.1): "10": Close, but not quite. Go back over it one step at a time.; "22": That is a long way from the answer. Use the objects or the number line.

### 3.4 subtract_within_20 - numbers-56-022 to 033 (12 lessons, level 2) and legacy num-subtract (within 10, level 2)
Taught: start with a group, take the second group away, count what is left (ONE objects group with operator "-" and `takeAway` = the number crossed out); count back on the number line (negative `jump`); check by adding (start at the answer, count on). Tasks: `sub_objects`, `sub_line`, `sub_symbolic`, `fact` (which addition fact checks this subtraction - options are three equations, only one true). Pools: first number 9-20 (4-10 for num-subtract), second 1-9, answer never equal to either number. Distractors: either number, a near miss, the SUM (wrong operation), a distant number. Remediation: think addition (count UP from the small number to the big one) with a different group picture and a number line counted forwards, then the related addition fact.

#### Example: numbers-56-023 - "Subtract 15 − 7" (level 2)

Objective (kept from the source): Learner can subtract within 20 in subtraction_within_20.  Prerequisites: none

Teaching steps (demonstrate): We start with 15 things. | Take away 7. These 7 things are crossed out: they go away. | Count what is left: 8. So 15 − 7 = 8. The − sign means: take away. | On the number line, count back 7 steps from 15: 14, 13, 12, 11, 10, 9, 8. We land on 8. | Check by adding: start at 8 and count on 7: we get back to 15. So 8 + 7 = 15. Subtracting and adding are partners.

Remediation explanation: Here is another way: think of adding. To find 14 − 8, ask: how many do we add to 8 to get to 14? | Start at 8 and count up to 14: 9, 10, 11, 12, 13, 14. That is 6 steps. | We added 6 to get from 8 to 14, so 14 − 8 = 6. We can check: 6 + 8 = 14.

| item | task | prompt | visual | options (stored order) | KEY |
|---|---|---|---|---|---|
| guided.1 | sub_objects | How many are left? | objects 16, takeAway 6 | 10, 16, 11 | **10** |
| guided.2 | sub_line | 10 − 3 = ? | numberLine 0..20 start 10 jump -3 hops=True | 13, 7, 17 | **7** |
| practice.1 | fact | Which addition fact checks 12 − 8? | none | 5 + 8 = 12, 4 + 8 = 12, 3 + 8 = 12 | **4 + 8 = 12** |
| practice.2 | sub_objects | How many are left? | objects 13, takeAway 6 | 11, 6, 7 | **7** |
| practice.3 | sub_line | 17 − 3 = ? | numberLine 0..20 start 17 jump -3 hops=False | 14, 3, 20 | **14** |
| practice.4 | sub_symbolic | 20 − 3 = ? | none | 23, 17, 3 | **17** |
| check.1 | sub_objects | How many are left? | objects 13, takeAway 9 | 4, 5, 0 | **4** |
| check.2 | sub_line | 19 − 3 = ? | numberLine 0..20 start 19 jump -3 hops=False | 22, 16, 20 | **16** |
| check.3 | sub_symbolic | 12 − 9 = ? | none | 7, 9, 3 | **3** |
| rem guided.1 | sub_objects | How many are left? | objects 9, takeAway 8 | 9, 17, 1 | **1** |
| rem guided.2 | sub_line | 12 − 2 = ? | numberLine 0..20 start 12 jump -2 hops=True | 10, 14, 12 | **10** |
| rem check.1 | sub_objects | How many are left? | objects 13, takeAway 7 | 20, 6, 7 | **6** |
| rem check.2 | sub_line | 15 − 2 = ? | numberLine 0..20 start 15 jump -2 hops=False | 15, 2, 13 | **13** |
| rem check.3 | sub_symbolic | 16 − 2 = ? | none | 14, 24, 18 | **14** |

Wrong-answer feedback example (check.1): "5": Close, but not quite. Go back over it one step at a time.; "0": That is a long way from the answer. Use the objects or the number line.

### 3.5 compare_two_digit_numbers - numbers-56-034 to 041 (level 1)
Taught with the lesson's own pair: the three signs <, > and = (mouth opens to the bigger number); each number as tens-and-ones blocks; tens first, then ones only if the tens match; write the sign; the bigger number is further right on a number line (range in tens around the pair). Tasks: `sign` (options always < > =), `bigger` and `smaller` (three numbers, pick the biggest or smallest). Pairs are drawn by category so that traps appear: swapped digits (34/43), tens smaller but ones bigger (29/31), same tens, across a ten (69/70), equal pairs (practice and some checks, so `=` is practised). Remediation: the number line (move right = bigger) with a different pair and a tip to look at the tens digit first.

#### Example: numbers-56-036 - "Compare 34 and 43" (level 1)

Objective (kept from the source): Learner can compare two digit numbers in compare_numbers.  Prerequisites: none

Teaching steps (demonstrate): Here is 34: 3 tens and 4 ones. | And here is 43: 4 tens and 3 ones. | Compare the tens first. 34 has 3 tens and 43 has 4 tens. 34 has fewer tens, so 34 is less than 43. We do not need the ones. | So we write 34 < 43. | On a number line, the number further to the right is bigger. 43 is further right than 34, so 43 is the bigger number and 34 is the smaller number.

Remediation explanation: Let us use the number line. Numbers go up as we move to the right. Here are 71 and 52. | Start at 52 and count up to 71. We move to the right, so 71 is bigger than 52. | Tip: look at the tens digit first. 71 has 7 tens and 52 has 5 tens. So 71 > 52.

| item | task | prompt | visual | options (stored order) | KEY |
|---|---|---|---|---|---|
| guided.1 | sign | Choose the sign: 36 __ 59 | numberLine 30..60 start 36 jump 23 hops=True | =, <, > | **<** |
| guided.2 | bigger | Which number is the biggest? | none | 14, 12, 18 | **18** |
| practice.1 | sign | Choose the sign: 49 __ 49 | none | <, >, = | **=** |
| practice.2 | smaller | Which number is the smallest? | none | 58, 85, 82 | **58** |
| practice.3 | sign | Choose the sign: 67 __ 84 | none | =, <, > | **<** |
| practice.4 | bigger | Which number is the biggest? | none | 89, 86, 90 | **90** |
| check.1 | smaller | Which number is the smallest? | none | 80, 79, 90 | **79** |
| check.2 | sign | Choose the sign: 72 __ 77 | none | =, >, < | **<** |
| check.3 | sign | Choose the sign: 56 __ 56 | none | =, >, < | **=** |
| rem guided.1 | sign | Choose the sign: 45 __ 33 | numberLine 30..50 start 33 jump 12 hops=True | >, =, < | **>** |
| rem guided.2 | bigger | Which number is the biggest? | none | 46, 57, 41 | **57** |
| rem check.1 | sign | Choose the sign: 63 __ 36 | none | <, =, > | **>** |
| rem check.2 | smaller | Which number is the smallest? | none | 17, 20, 19 | **17** |
| rem check.3 | sign | Choose the sign: 86 __ 86 | none | >, =, < | **=** |

Wrong-answer feedback example (check.1): "80": 80 is not the smallest. Compare the tens first: the smallest number has fewer tens, or the same tens and fewer ones.; "90": 90 is not the smallest. Compare the tens first: the smallest number has fewer tens, or the same tens and fewer ones.

### 3.6 continue_number_pattern - numbers-56-042 to 047 (level 2)
Taught with the lesson's own sequence: a pattern follows a rule; skip counting (increasing: groups up to 20 objects, otherwise a number line) or counting back on a number line (decreasing); then the OPPOSITE direction with a fixed example (an increasing lesson shows 12, 10, 8 with "take away 2"; a decreasing lesson shows 2, 4, 6 with "add 2"), so both rules are taught before items of either kind; use the rule to find the next number; use it to fill a missing number. Tasks: `next`, `rule` (options such as +2, -2, +1), `missing` ("a, __, c, d"). Sequence pool: add 1, 2, 3, 4, 5 or 10 (start numbers vary, not only multiples) and subtract 1, 2, 3, 5 or 10; the lesson's own sequence is excluded. Distractors: one more or one less than the last number, the last number again, a wrong step, the wrong direction; for `rule` a wrong step, the opposite direction and (sometimes) double the step. Remediation: the arrows between numbers show the same gap each time, then objects groups (or a number line for decreasing patterns), then the next number.

#### Example: numbers-56-043 - "Continue [5, 10, 15]" (level 2)

Objective (kept from the source): Learner can continue number pattern in patterns.  Prerequisites: none

Teaching steps (demonstrate): Start with 5. Add 5. Now we have 10. | Add 5 again. Now we have 15. The rule is: add 5 each time. | Patterns can also go down. This one shrinks: 12, 10, 8. Each number is 2 less than the one before. The rule is: take away 2 each time. | To find the next number, use the rule: 15 + 5 = 20. The pattern continues: 5, 10, 15, 20. | A number can also be missing from the middle. Use the rule: 5 + 5 = 10, and it fits: 5, 10, 15.

Remediation explanation: Let us look at the gaps. Each arrow shows how the number changes: 20 to 30 is +10. 30 to 40 is also +10. | Now on the number line. Count on 10 from 20. We land on 30. | The gap stays the same. So the next number is 40 + 10 = 50.

| item | task | prompt | visual | options (stored order) | KEY |
|---|---|---|---|---|---|
| guided.1 | next | What number comes next: 10, 15, 20, __ ? | objects 10+5+5 | 24, 21, 25 | **25** |
| guided.2 | missing | Which number goes in the blank? | glyph "1, __, 5, 7" | 3, 4, 1 | **3** |
| practice.1 | next | What number comes next? | glyph "17, 18, 19, __" | 20, 18, 21 | **20** |
| practice.2 | rule | What is the rule for this pattern? | glyph "5, 7, 9, ..." | −2, +2, +1 | **+2** |
| practice.3 | missing | Which number goes in the blank? | glyph "12, __, 10, 9" | 13, 16, 11 | **11** |
| practice.4 | next | What number comes next? | glyph "13, 10, 7, __" | 4, 10, 6 | **4** |
| check.1 | missing | Which number goes in the blank? | glyph "38, __, 32, 29" | 37, 30, 35 | **35** |
| check.2 | next | What number comes next? | glyph "9, 7, 5, __" | 3, 7, 4 | **3** |
| check.3 | rule | What is the rule for this pattern? | glyph "11, 14, 17, ..." | −3, +3, +4 | **+3** |
| rem guided.1 | next | What number comes next: 25, 26, 27, __ ? | numberLine 0..28 start 27 jump 1 hops=True | 29, 28, 26 | **28** |
| rem guided.2 | missing | Which number goes in the blank? | glyph "33, __, 39, 42" | 32, 41, 36 | **36** |
| rem check.1 | next | What number comes next? | glyph "12, 16, 20, __" | 24, 16, 20 | **24** |
| rem check.2 | rule | What is the rule for this pattern? | glyph "10, 13, 16, ..." | +4, +3, −3 | **+3** |
| rem check.3 | missing | Which number goes in the blank? | glyph "16, __, 20, 22" | 19, 16, 18 | **18** |

Wrong-answer feedback example (check.1): "37": Not quite. Work out the gap between the numbers you can see.; "30": That is too far. Check the gap between the numbers.

### 3.7 identify_shape_properties - numbers-56-048 to 051 (triangle, square, rectangle, circle; level 1)
Taught with the lesson's own shape picture (`assets/images/age56/<shape>.webp`, all four exist): the name, how many straight sides (a count with the finger), how many corners, then equal sides (square) and long sides (rectangle) shown with their pictures (the earlier everyday-example step was removed to make room). Before any item: introduce 1 shows the shape and defines side and corner, introduce 2 names the four shapes in words (no symbol-font row) and gives triangle and circle, introduce 3 gives square (4 equal sides) and rectangle (2 long, 2 short); demonstrate 4 and 5 show the square (equal sides) and the rectangle (2 long, 2 short). Tasks: `name` (picture -> name), `sides` and `corners` (picture -> number), `which_prop` (a property sentence -> pick the shape, options carry their pictures via `optionPictures`). Question pictures have an empty caption so the answer is never printed. Each (task, shape) is used once per lesson; the check includes the lesson's own shape (a property sentence and its corners). Remediation: build the shape from sticks (one stick per side) and dots (one per corner) with objects groups, then the picture again (a circle is explained with a loop of string).

#### Example: numbers-56-048 - "Shape: triangle" (level 1)

Objective (kept from the source): Learner can identify shape properties in shapes.  Prerequisites: none

Teaching steps (demonstrate): This shape is a triangle. | Count the straight sides with your finger. A triangle has 3 straight sides. | Now count the corners, where two sides meet. A triangle has 3 corners. | Now look at the square. All 4 of its sides are the same length. We call them equal sides. A square has 4 corners. | Now look at the rectangle. It also has 4 sides and 4 corners, but 2 sides are long and 2 sides are short.

Remediation explanation: Let us build a triangle from sticks. Each stick is one side. We need 3 sticks. | Each place where two sticks meet is a corner. Here are the 3 corners as dots. | So a triangle has 3 sides and 3 corners. Now look at the picture again and count them.

| item | task | prompt | visual | options (stored order) | KEY |
|---|---|---|---|---|---|
| guided.1 | name | What is the name of this shape? | picture triangle.webp | Square, Triangle, Circle | **Triangle** |
| guided.2 | sides | How many straight sides does this shape have? | picture square.webp | 5, 6, 4 | **4** |
| practice.1 | corners | How many corners does this shape have? | picture rectangle.webp | 5, 6, 4 | **4** |
| practice.2 | which_prop | Which shape is round and has no straight sides? | none | Circle, Square, Rectangle | **Circle** |
| practice.3 | sides | How many straight sides does this shape have? | picture circle.webp | 1, 0, 3 | **0** |
| practice.4 | name | What is the name of this shape? | picture rectangle.webp | Square, Circle, Rectangle | **Rectangle** |
| check.1 | which_prop | Which shape has 3 corners? | none | Circle, Triangle, Rectangle | **Triangle** |
| check.2 | sides | How many straight sides does this shape have? | picture rectangle.webp | 5, 6, 4 | **4** |
| check.3 | corners | How many corners does this shape have? | picture triangle.webp | 3, 6, 4 | **3** |
| rem guided.1 | corners | How many corners does this shape have? | picture circle.webp | 0, 5, 1 | **0** |
| rem guided.2 | which_prop | Which shape has 4 equal sides? | none | Circle, Square, Rectangle | **Square** |
| rem check.1 | corners | How many corners does this shape have? | picture square.webp | 0, 5, 4 | **4** |
| rem check.2 | name | What is the name of this shape? | picture square.webp | Square, Triangle, Circle | **Square** |
| rem check.3 | which_prop | Which shape has 4 corners and 2 long sides? | none | Circle, Rectangle, Triangle | **Rectangle** |

Wrong-answer feedback example (check.1): "Circle": A circle has no straight sides. That does not match.; "Rectangle": A rectangle has 4 sides. That does not match.

### 3.8 understand_everyday_math - numbers-56-052 (morning), 053 (longer), 054 (rupees), level 2
Three separate small templates, each built from the concept in the lesson title:
- **morning**: the four parts of the day in order (morning, afternoon, evening, night) with the sun/moon clue; tasks `time_of_day` (a situation -> the part of the day, 12 situations, "breakfast" is the demonstration example and is not asked) and `order_after` / `order_before` (cyclic order). Remediation: clues from the sky (sun low, high, going down, dark).
- **longer**: length; longer/shorter with the existing pencil picture (`longer.webp`); put the ends together; measure with equal units (paper clips); tasks `pic_longer` (guided only: there is one picture), `word_pick` (longer than -> the other is shorter; third option is a weight word), `how_compare`, `units_longer` / `units_shorter` (two objects groups joined by operator "vs"; counts differ each time, names and counts are drawn from pools). Remediation: lines of blocks counted one by one.
- **rupees**: coins and notes (`rupees.webp`), the unit for money is rupees; contrast with metres (length) and litres (liquid); tasks `money_word`, `unit_for` ("the price of ..." / "how long ..." / "how much ... is in ..."), `pay_with`. Remediation: ask "money, length or liquid?" with one example of each.

#### Example: numbers-56-052 - "morning" (level 2)

Objective (kept from the source): Learner can understand everyday math in everyday_math.  Prerequisites: none

Teaching steps (demonstrate): In the morning, the sun comes up and we wake up. | We eat breakfast in the morning. Breakfast is the first meal of the day. | The day has four parts: morning, afternoon, evening and night, in that order. | After the morning comes the afternoon, when the sun is high and we eat lunch. Before the morning comes the night. | To tell the part of the day, look at the clue: the sun rising is morning, the sun high is afternoon, the sun going down is evening, and the moon and stars mean night.

Remediation explanation: Let us use clues. When the sun is low and just coming up, it is the morning. We wake up. | When the sun is high, it is the afternoon. When the sun is going down, the sky turns orange and it is the evening. | When it is dark and we can see the moon and stars, it is night. We sleep at night.

| item | task | prompt | visual | options (stored order) | KEY |
|---|---|---|---|---|---|
| guided.1 | time_of_day | You have a short rest after lunch, in the middle of the day. What part of the day is it? | glyph "☀️" | evening, morning, afternoon | **afternoon** |
| guided.2 | order_after | Which part of the day comes after the night? | glyph "🌅 → ☀️ → 🌇 → 🌙" | morning, evening, afternoon | **morning** |
| practice.1 | time_of_day | You see the moon and the stars and you go to bed. What part of the day is it? | glyph "🌙" | night, afternoon, morning | **night** |
| practice.2 | time_of_day | The sun is going down and you play in the park. What part of the day is it? | none | afternoon, evening, night | **evening** |
| practice.3 | order_before | Which part of the day comes before the morning? | none | morning, evening, night | **night** |
| practice.4 | order_after | Which part of the day comes after the evening? | none | night, evening, morning | **night** |
| check.1 | time_of_day | You wake up when the sun is just coming up. What part of the day is it? | none | afternoon, evening, morning | **morning** |
| check.2 | order_after | Which part of the day comes after the morning? | none | afternoon, evening, morning | **afternoon** |
| check.3 | time_of_day | You play outside after lunch, while the sun is still high. What part of the day is it? | none | night, afternoon, morning | **afternoon** |
| rem guided.1 | time_of_day | Your family sits together as the sun sets. What part of the day is it? | glyph "🌇" | night, evening, afternoon | **evening** |
| rem guided.2 | order_before | Which part of the day comes before the afternoon? | glyph "🌅 → ☀️ → 🌇 → 🌙" | afternoon, evening, morning | **morning** |
| rem check.1 | time_of_day | It is dark outside and you are fast asleep. What part of the day is it? | none | night, afternoon, evening | **night** |
| rem check.2 | order_after | Which part of the day comes after the afternoon? | none | morning, evening, night | **evening** |
| rem check.3 | time_of_day | You eat lunch when the sun is high in the sky. What part of the day is it? | none | night, morning, afternoon | **afternoon** |

Wrong-answer feedback example (check.1): "afternoon": That is not the part of the day we want. Look at the clue again: where is the sun, or is it dark?; "evening": That is not the part of the day we want. Look at the clue again: where is the sun, or is it dark?

#### Example: numbers-56-053 - "longer" (level 2)

Objective (kept from the source): Learner can understand everyday math in everyday_math.  Prerequisites: none

Teaching steps (demonstrate): The top pencil is longer than the bottom pencil. Longer means it has more length. | The bottom pencil is shorter than the top pencil. Shorter means it has less length. | To compare lengths, put the ends of the two things together, at the same starting line. Then we can see which one reaches further. | We can also measure with the same small units, like paper clips. A rope of 6 clips and a rope of 4 clips: the rope with more clips is longer. | So 6 clips is longer, and 4 clips is shorter. A word we use to compare length is 'longer'. Longer, not lighter or heavier.

Remediation explanation: Let us line things up. Two things start at the same line. We look to see which one goes further. | Count the blocks in the first line: 1, 2, 3, 4, 5, 6. It is 6 blocks long. | The second line is 4 blocks long. 4 is fewer than 6, so the second line is shorter and the first line is longer.

| item | task | prompt | visual | options (stored order) | KEY |
|---|---|---|---|---|---|
| guided.1 | pic_longer | Which pencil is longer? | picture longer.webp | The top pencil, The bottom pencil, They are the same length | **The top pencil** |
| guided.2 | word_pick | The scarf is longer than the stick. So the stick is ___ | none | lighter, shorter, longer | **shorter** |
| practice.1 | how_compare | How do we compare the lengths of two things? | none | Look at their colours, Put their ends together, Weigh them | **Put their ends together** |
| practice.2 | units_longer | The pencil is 9 clips long. The string is 2 clips long. Which is longer? | objects 9vs2 labels=['The pencil', 'The string'] | The string, They are the same length, The pencil | **The pencil** |
| practice.3 | units_shorter | The string is 2 clips long. The pencil is 7 clips long. Which is shorter? | objects 2vs7 labels=['The string', 'The pencil'] | The string, The pencil, They are the same length | **The string** |
| practice.4 | word_pick | The string is shorter than the pencil. So the pencil is ___ | none | shorter, longer, lighter | **longer** |
| check.1 | units_longer | The pencil is 4 clips long. The stick is 9 clips long. Which is longer? | objects 4vs9 labels=['The pencil', 'The stick'] | The stick, The pencil, They are the same length | **The stick** |
| check.2 | word_pick | The stick is longer than the scarf. So the scarf is ___ | none | heavier, shorter, longer | **shorter** |
| check.3 | units_shorter | The rope is 5 clips long. The scarf is 6 clips long. Which is shorter? | objects 5vs6 labels=['The rope', 'The scarf'] | The scarf, They are the same length, The rope | **The rope** |
| rem guided.1 | units_longer | The ribbon is 2 clips long. The rope is 4 clips long. Which is longer? | objects 2vs4 labels=['The ribbon', 'The rope'] | They are the same length, The ribbon, The rope | **The rope** |
| rem guided.2 | word_pick | The pencil is shorter than the rope. So the rope is ___ | none | longer, lighter, shorter | **longer** |
| rem check.1 | units_shorter | The rope is 2 clips long. The pencil is 3 clips long. Which is shorter? | objects 2vs3 labels=['The rope', 'The pencil'] | They are the same length, The rope, The pencil | **The rope** |
| rem check.2 | word_pick | The ribbon is shorter than the stick. So the stick is ___ | none | lighter, shorter, longer | **longer** |
| rem check.3 | units_longer | The stick is 3 clips long. The ribbon is 5 clips long. Which is longer? | objects 3vs5 labels=['The stick', 'The ribbon'] | The ribbon, The stick, They are the same length | **The ribbon** |

Wrong-answer feedback example (check.1): "The pencil": Count the clips for each one. The one with more clips is longer.; "They are the same length": The numbers of clips are not the same, so the lengths are not the same.

#### Example: numbers-56-054 - "rupees" (level 2)

Objective (kept from the source): Learner can understand everyday math in everyday_math.  Prerequisites: none

Teaching steps (demonstrate): We use coins and notes to pay for things in a shop. | The unit for money in India is the rupee. We write rupees with the sign ₹. A toffee costs some rupees. | We do not measure money in metres. Metres measure length, like how long a rope is. | We do not measure money in litres. Litres measure how much liquid there is, like milk or water. | So: rupees for money, metres for length, and litres for liquids. To choose the unit, ask what we are measuring.

Remediation explanation: Let us think of three things in a shop. A toffee costs money, so we use rupees. | A ribbon has a length, so we use metres. A jug of milk is a liquid, so we use litres. | Ask yourself each time: money, length, or liquid? Money is rupees, length is metres, and liquid is litres.

| item | task | prompt | visual | options (stored order) | KEY |
|---|---|---|---|---|---|
| guided.1 | money_word | Which unit is used for money in India? | picture rupees.webp | litres, rupees, metres | **rupees** |
| guided.2 | unit_for | Which unit do we use to tell how long a rope is? | none | litres, rupees, metres | **metres** |
| practice.1 | unit_for | Which unit do we use to tell the price of a toy car? | none | litres, metres, rupees | **rupees** |
| practice.2 | pay_with | How do we pay for a ticket at the bus stop? | none | with notes and coins, with stones, with feathers | **with notes and coins** |
| practice.3 | unit_for | Which unit do we use to tell how much water is in a tank? | none | rupees, litres, metres | **litres** |
| practice.4 | unit_for | Which unit do we use to tell the price of a pencil? | none | metres, litres, rupees | **rupees** |
| check.1 | unit_for | Which unit do we use to tell the price of a bus ticket? | none | litres, rupees, metres | **rupees** |
| check.2 | unit_for | Which unit do we use to tell how long a ribbon is? | none | litres, rupees, metres | **metres** |
| check.3 | pay_with | Which of these is money? | none | a coin, a pebble, a button | **a coin** |
| rem guided.1 | unit_for | Which unit do we use to tell the price of a toffee? | none | rupees, metres, litres | **rupees** |
| rem guided.2 | unit_for | Which unit do we use to tell how tall a pole is? | none | rupees, metres, litres | **metres** |
| rem check.1 | unit_for | Which unit do we use to tell how much water is in a bucket? | none | rupees, metres, litres | **litres** |
| rem check.2 | pay_with | What do you give the shopkeeper to buy a toy? | none | money, paper boats, water | **money** |
| rem check.3 | unit_for | Which unit do we use to tell the price of a banana? | none | metres, rupees, litres | **rupees** |

Wrong-answer feedback example (check.1): "litres": Litres measure how much liquid there is.; "metres": Metres measure length, how long something is.

### 3.9 Legacy lessons
- **num-count** (count three stars): the same template as 3.1 with n = 3 (and a 0-5 line). Practice also counts 1, 2 or 4 things. See the 3.1 example for the shape.
- **num-names** (match 5 to "five"): taught with 5 objects, the numeral, the word, then the names one to five and six to ten as two numeral-and-word tables (every name an item uses is taught first), and the number line. Tasks: `numeral_to_word`, `word_to_numeral`, `count_to_word`. The check includes 5 ("five") once in a new form; other items use the names one to ten.
- **num-multiply** (4 x 3 = 12, equal groups): groups of equal size, count all, repeated addition, the x sign, skip counting. Tasks: `groups_pic`, `repeat_add`, `times_sym`, `story`; the check is always one picture, one story, one x item. Groups and sizes 2-7, product at most 30 (pictures only up to 20); no problem is used twice, even in the other order (4 x 3 and 3 x 4 never asked; 7 is needed to have enough different problems). Feedback is computed from the option's value (the sum, one group, the number of groups, one group too many or too few). Remediation: repeated addition as a chain, counting every object in ones, skip counting.
- **num-divide** (12 / 3 = 4, equal sharing): share one at a time, equal groups, the division sign, and the "how many bags of 3" view. Tasks: `share`, `bags`, `sym`, `share_story`. Divisors and answers 2-6 (never equal), totals at most 30; 12 / 3 never asked. Remediation: take away the same number again and again, then bags, then the sum.
- **num-fraction** (1/2 of 10 = 5): halves as two equal groups, two halves make the whole, unequal groups are not halves. Tasks: `half_set`, `half_sym`, `half_story`, `which_split`. Even numbers 2-40 are used so there are enough different problems (see limits). Remediation: put the set in pairs (one for you, one for a friend); half is the number of pairs.
- **num-percent** (25% of 20 = 5): 100% is the whole; 25% is one of four equal groups; 50% is one half. Tasks: `pct_set`, `pct_sym`, `pct_story`, `match_fraction` (50% / 100% / 25% -> one half / one whole / one quarter). Only 25% and 50% are asked. Feedback is computed from the option's value (all N, half of N = 50%, a quarter of N = 25%, the percent number itself); the 0 option is gone. Pictures only up to 20 things. Remediation: start from a half, a quarter is half of a half.
- **num-subtract**: see 3.4.

#### Example: num-multiply - "Array Multiplication" (level 3)

Objective (kept from the source): Model multiplication as equal groups.  Prerequisites: ['num-subtract']

Teaching steps (demonstrate): Here is 1 group of 3. | Here are 4 groups of 3. Every group has the same number. | Count them all, one by one: 1, 2, 3, ... up to 12. There are 12 altogether. | 3 + 3 + 3 + 3 = 12. We write this as 4 × 3 = 12. The × sign means: groups of. | So 4 groups of 3 is 12. Adding the same number again and again is multiplying.

Remediation explanation: Let us think of adding the same number again and again: 7 + 7. | Now count every thing in ones: there are 2 groups of 7, so we count 1, 2, 3 ... up to 14. | We can also skip count by 7: 7, 14. That is 2 × 7 = 14.

| item | task | prompt | visual | options (stored order) | KEY |
|---|---|---|---|---|---|
| guided.1 | groups_pic | How many altogether? | objects 4+4 | 6, 2, 8 | **8** |
| guided.2 | repeat_add | 7 + 7 + 7 = ? | none | 21, 7, 11 | **21** |
| practice.1 | story | There are 4 plates. Each one has 6 pencils. How many pencils are there altogether? | none | 24, 34, 18 | **24** |
| practice.2 | times_sym | 5 × 5 = ? | none | 35, 25, 26 | **25** |
| practice.3 | groups_pic | How many altogether? | objects 3+3+3+3+3 | 18, 25, 15 | **15** |
| practice.4 | repeat_add | 6 + 6 + 6 + 6 + 6 = ? | none | 30, 6, 36 | **30** |
| check.1 | times_sym | 4 × 7 = ? | none | 11, 4, 28 | **28** |
| check.2 | groups_pic | How many altogether? | objects 6+6 | 12, 2, 8 | **12** |
| check.3 | story | There are 5 boxes. Each one has 2 sweets. How many sweets are there altogether? | none | 11, 10, 7 | **10** |
| rem guided.1 | groups_pic | How many altogether? | objects 2+2+2 | 7, 6, 16 | **6** |
| rem guided.2 | repeat_add | 3 + 3 + 3 = ? | none | 6, 3, 9 | **9** |
| rem check.1 | groups_pic | How many altogether? | objects 6+6+6 | 18, 9, 19 | **18** |
| rem check.2 | times_sym | 4 × 4 = ? | none | 26, 16, 15 | **16** |
| rem check.3 | story | There are 5 boxes. Each one has 4 books. How many books are there altogether? | none | 10, 9, 20 | **20** |

Wrong-answer feedback example (check.1): "11": 11 is 4 + 7, the two numbers added. We want 4 groups of 7: add 7 again and again.; "4": 4 is only the number of groups. We want the total of the things in all the groups.

#### Example: num-fraction - "Fractions of a Set" (level 4)

Objective (kept from the source): Calculate a unit fraction of a whole-number set.  Prerequisites: ['num-divide']

Teaching steps (demonstrate): Here is a set of 10 things. This is the whole set. | Share them equally into 2 groups. Each group has 5. Each group is one half of the set. | One half of 10 is 5. We write ½ of 10 = 5. | Check: 5 + 5 = 10. Two halves make the whole set. | Careful: the two groups must be equal. 6 and 4 are not equal, so they are not halves.

Remediation explanation: Let us try with pairs. Put the things in pairs, one for you and one for a friend. Here are 6 things. | There are 3 pairs. In each pair, one is for you and one is for your friend. So you get 3 and your friend gets 3. | So half of 6 is the number of pairs, 3. Half is the opposite of doubling: 3 + 3 = 6.

| item | task | prompt | visual | options (stored order) | KEY |
|---|---|---|---|---|---|
| guided.1 | half_set | What is half of this set? | objects 8 | 8, 4, 2 | **4** |
| guided.2 | which_split | 36 sweets are split into two groups. Which split gives two equal halves? | none | 19 and 17, 21 and 15, 18 and 18 | **18 and 18** |
| practice.1 | half_story | You have 34 marbles and you share them equally with one friend. How many does each of you get? | none | 2, 34, 17 | **17** |
| practice.2 | half_sym | ½ of 28 = ? | none | 14, 56, 28 | **14** |
| practice.3 | half_set | What is half of this set? | objects 14 | 16, 7, 6 | **7** |
| practice.4 | which_split | 22 sweets are split into two groups. Which split gives two equal halves? | none | 14 and 8, 13 and 9, 11 and 11 | **11 and 11** |
| check.1 | half_story | You have 30 stickers and you share them equally with one friend. How many does each of you get? | none | 30, 15, 2 | **15** |
| check.2 | which_split | 24 sweets are split into two groups. Which split gives two equal halves? | none | 14 and 10, 13 and 11, 12 and 12 | **12 and 12** |
| check.3 | half_sym | ½ of 32 = ? | none | 16, 34, 17 | **16** |
| rem guided.1 | half_set | What is half of this set? | objects 4 | 2, 6, 1 | **2** |
| rem guided.2 | which_split | 40 sweets are split into two groups. Which split gives two equal halves? | none | 22 and 18, 20 and 20, 21 and 19 | **20 and 20** |
| rem check.1 | half_set | What is half of this set? | objects 16 | 16, 4, 8 | **8** |
| rem check.2 | half_sym | ½ of 26 = ? | none | 13, 2, 26 | **13** |
| rem check.3 | half_story | You have 38 mangoes and you share them equally with one friend. How many does each of you get? | none | 20, 19, 76 | **19** |

Wrong-answer feedback example (check.1): "30": 30 is the whole set. A half is only part of it.; "2": That is a long way off. Split the set into 2 equal groups.

## 4. Checker (real output)

`check_rollout.py` (scratchpad, extends the pilot checker; it recomputes every answer from the prompt, the visual and the options with its own solvers; it does not import the generator). Real output of the last run:

```
﻿JSON parses; schema_version 1 status rollout_unverified lessons 72
ids across pilot+rollout: 1925 unique: 1925

lessons covered: 72 of 72 | missing: none
questions: 1008 | independently recomputed: 1005 | NOT recomputed (no solver): 3 {'pay_with': 3}
tasks: {'add_line': 56, 'add_objects': 56, 'add_ones': 11, 'add_symbolic': 36, 'bags': 4, 'bigger': 30, 'bond10': 9, 'build': 27, 'compare3': 36, 'corners': 16, 'count': 72, 'count_to_word': 5, 'fact': 22, 'groups_pic': 5, 'half_set': 4, 'half_story': 3, 'half_sym': 3, 'how_compare': 1, 'line': 60, 'match_fraction': 1, 'missing': 30, 'money_word': 1, 'name': 12, 'next': 36, 'numeral_to_word': 4, 'ones_pic': 33, 'ones_sym': 12, 'order_after': 4, 'order_before': 2, 'pay_with': 3, 'pct_set': 5, 'pct_story': 3, 'pct_sym': 5, 'pic_longer': 1, 'repeat_add': 3, 'rule': 18, 'share': 5, 'share_story': 2, 'sides': 12, 'sign': 58, 'smaller': 24, 'story': 3, 'sub_line': 60, 'sub_objects': 61, 'sub_symbolic': 39, 'sym': 3, 'tens_pic': 30, 'tens_sym': 24, 'time_of_day': 8, 'times_sym': 3, 'unit_for': 10, 'units_longer': 4, 'units_shorter': 3, 'which_prop': 16, 'which_split': 4, 'word_pick': 5, 'word_to_numeral': 5}
assets referenced: 7 ['assets/images/age56/circle.webp', 'assets/images/age56/longer.webp', 'assets/images/age56/morning.webp', 'assets/images/age56/rectangle.webp', 'assets/images/age56/rupees.webp', 'assets/images/age56/square.webp', 'assets/images/age56/triangle.webp']
check key position (stored index) distribution: {0: 72, 1: 72, 2: 72} of 216
rem-check key position distribution: {0: 72, 1: 72, 2: 72} of 216
lessons whose remediation uses exactly the same visual-type set as the demonstration (info only): 27
check/rem-check/other option sets in descending order (info, allowed): 118
multiply problems checked for commuted repeats: 14 | texts scanned for plural slips: 1720
objects visuals: 464 | baseTen visuals: 124 | cap of 20 objects enforced on every objects visual
term/name teach-before-test checks: {'terms': 681, 'pattern directions': 6, 'shape vocabulary': 4}
feedback sentences tested against the option's value: 575 {'ones digit': 26, 'whole': 54, 'ten off': 15, 'swapped digits': 14, 'tens digit': 16, 'taking away': 63, 'operand': 157, 'make-ten leftover': 28, 'ones only': 39, 'sum': 89, 'last +-1': 9, 'last number': 14, 'already shown': 17, 'shape sides': 5, 'groups number': 3, 'one group': 3, 'group off': 3, 'whole total': 4, 'percent whole': 5, 'percent number': 9, 'half': 2}
ERRORS: 0
```

What the checker covers: all 72 expected lesson ids present; title/objective/prerequisites/level equal to the sources; ids unique across the pilot and rollout files (1,912 ids); required mastery and review fields; step and question counts; visual types and field names; objects/number-line ranges; every asset exists; answer in options and equal to the independently recomputed answer (1,005 of 1,008; the 3 `pay_with` items have text answers with no solver); every distractor wrong (the wrong equations in `fact` and the unequal splits in `which_split` are tested); `wrong_feedback` keys equal the distractors; no hints on check items, two-step ladder elsewhere; hint 1 free of the answer; no caption or glyph equal to the answer on practice/check; no answer in the prompt or in feedback; no repeated check problem within a lesson (same task, answer and operands) and no check item equal to an earlier guided/practice item (for the 11 count lessons and num-count, which are about one number, the rule is relaxed to: no two items with the same prompt and visual); the lesson's own worked-example numbers not asked; remediation visuals and text not equal to the demonstration; every check and remediation-check task taught earlier in guided/practice; key position spread; numeric options never in ascending order; English-only letters; no digits left in speech; a dry run of the Dart `validate()` rules.

What it does NOT cover (so nothing is claimed): the real Dart loader was not run; no UI renders these plans; the wording, the pedagogy and the age suitability are not judged; text-answer tasks (time of day, shape properties, units, words) are recomputed only by simple keyword or table rules.

## 5. File loader finding (written before promotion; the bundled copy now exists, see section 1)

`lib/src/teaching/teaching_plan.dart` does NOT read specific file names. `assetTeachingPlanLoader` reads EVERY `*.json` under `content/teaching/` that is in the asset manifest, and `pubspec.yaml` lists the whole `content/teaching/` directory as an asset. So `rollout_numbers.json` will be bundled and parsed automatically next to `pilot_teaching_plans.json`; each plan is validated and a bad plan is skipped and reported in `TeachingPlanLibrary.issues`; a duplicate lesson id keeps the first plan. The file `status` ("rollout_unverified") is carried only for reports, it does not stop a plan being used. The loader was NOT edited. Decision for the product owner: as soon as the UI plays plans for any lesson that has one, these 72 unverified plans would be live. If that is not wanted before verification, keep this file out of the bundle until it passes content-verifier (the UI-creator can gate on `status`).

## 6. Where the existing lesson data came from

- numbers-56-xxx: `content/age56/numbers_age_5_6.json` (id, title, objective, prerequisites, level).
- legacy num-*: `lib/src/curriculum.dart` (title, learningObjective, prerequisites; level from the age band: explorer 1, creator 2, scholar 3, champion 4).
- numbers-count-0xx: `lib/src/batch/batch_content.dart` `_buildNumbers` (title "Number n", level 1 from age band 3-4, prerequisite = previous number). That Dart lesson has no objective of its own (it falls back to the default "Complete the guided lesson sequence."); the plan uses the content-pack record's objective `Count objects: n` from `content/pack_v2/content/numbers.json`.

## 7. Limits and UNVERIFIED items

Nothing below is claimed to be fine.

1. UNVERIFIED by anyone: educator review of every progression, strategy, hint, feedback sentence, item mix, pass marks (2 of 3 is a 26% blind-guess pass chance with three options) and age suitability; en-IN TTS of number words and of "plus", "minus", "times", "divided by", "equals", "percent"; emoji rendering; the whole plan set in a real UI.
2. Visual semantics used by this file (documented in `content/teaching/SCHEMA.md`, "Rollout R1 visual notes"; none of it is implemented or verified in a UI yet): `baseTen`; objects `operator` "-" = ONE group with `takeAway`; operator "vs" = two labelled rows (`labels`); a NEGATIVE numberLine `jump` (hops to the left); `jump` 0 (marker only, or "no move" with hops shown). The existing pilot fields (`showHops`, `showResult` and the rest) are also still unimplemented/unverified.
3. Weak visuals (review.notes of each lesson say what a better visual would be): patterns use text and groups (a pattern strip with a blank box is missing); everyday maths uses emoji glyphs and short stories (a clock, a ruler picture and a coin set are missing); zero has no empty-box picture; fractions and percent use plain emoji groups (a bar or circle picture is missing).
4. Scope choices to confirm: num-count practices 1, 2, 4 as well as 3 (distractors up to 5); num-names uses the names one to ten, not only five; num-fraction uses halves of even numbers up to 40 (the lesson covers only 1/2 of 10; sets above 20 are symbolic only, pictures up to 20 things); num-percent adds 50% and names 100%; num-multiply/num-divide use sizes 2-6; the morning lesson adds afternoon/evening/night; the rupees lesson adds metres and litres as contrasting units; the longer lesson adds paper-clip units.
5. Limited variety by nature: count lessons answer the same number in many items (differences are emoji, wording, distractors); shapes have only four shapes so `(task, shape)` items are close to exhausted and the check shares a shape with the demonstration; the rupees `unit_for` options are always the same three words in a shuffled order; `compare` signs are always < > =.
6. 118 option sets are in descending order when the key is in the middle and the distractors lie on both sides of it (an ascending order is never produced). Key positions in the check are balanced in the STORED order only; if the UI does not shuffle, the stored order is what the child sees.
7. Answer rules for text tasks (time of day, which shape, which unit, pay with) are tables in the generator; the independent checker covers all but `pay_with` (3 items) by keyword/table rules of its own. Everyday-maths situations (for example "You come home from school after lunch time" = afternoon, "Your family sits together as the sun sets" = evening) are my judgement and need an educator.
8. Remediation uses "start from the bigger number" (commutativity) and "count up to subtract" ideas that the lesson itself never teaches before; they are taught inside the remediation explanation only. Educator to decide.
9. Add/subtract hint 2 reveals the worked method; guided number-line items show the hops (and therefore the answer), by design, as scaffolding.
10. The loader fact in section 5 is a product decision, not a content fix.


## 8. Revision 2 (answers to the content-verifier's Rollout R1 findings)

Decisions applied (from the coordinator, after the verifier's 50 PASS / 22 REVISE):

| # | Change | Where |
|---|---|---|
| 1 | num-names now teaches every name it asks: demonstrate 3 = one to five, demonstrate 4 = six to ten (numeral-and-word tables) before any item. | num-names (RN-2) |
| 2 | Tens and ones: one unambiguous wording, taught first ("full tens" and "single ones left after the tens"); new `baseTen` visual replaces up to 98 emoji; every `objects` visual is capped at 20 objects in total (the generator refuses to write a bigger one). | 9 tens lessons, compare demos, all objects visuals (RN-3, RN-7, RN-9) |
| 3 | Number patterns teach both directions (own direction in demonstrate 1-2, the opposite direction in demonstrate 3) before any item; pattern pictures are objects only up to 20, otherwise a number line. | 6 pattern lessons (RN-4) |
| 4 | Shapes: introduce 2 names all four shapes with their sides; demonstrate 4-5 teach equal sides and long/short sides with the square and rectangle pictures. | 4 shape lessons (RN-5) |
| 5 | Feedback for num-percent and num-multiply is computed from the option's value; the false sentences and the 0 option are gone. | RN-6 |
| 6 | Subtraction: ONE group with `takeAway`; "vs": `labels`. Negative jump and jump 0 stay. | RN-1 |
| 7 | Fractions and percent: objects only up to 20; larger sets symbolic. Divide and multiply pictures also capped at 20. | RN-7 |
| 8 | "You come home from school after lunch time" replaced by "You play outside after lunch, while the sun is still high." | morning lesson |
| extra | Count lessons say "things" (not "stars") and the empty-set hint no longer says "touch each one" (RN-8); multiply check is always picture + story + x item (RN-10); "1 ten", "1 one" singulars also fixed in glyph text (RN-9). | |

### Visual notes for the UI (also in SCHEMA.md)

- `{"type":"baseTen","tens":2,"ones":6,"showTotal":false}`: draw `tens` ten-bars and `ones` single cubes; show the numeral only when `showTotal` is true (teaching steps); questions always false. Used for 124 visuals.
- `objects` with `operator` "-": exactly one group; draw `count` objects and cross out / fade the last `takeAway`. In questions there is no `result` and `showResult` is false; teaching step 3 has `result`.
- `objects` with `operator` "vs": exactly two groups and `labels` (two strings); draw two labelled rows lined up at one start line.
- Total objects drawn by any `objects` visual are at most 20 (for "-" the one group's count).
- `numberLine` with a negative `jump`: hops go left from `start`; `jump` 0: only the marker is drawn (hops shown or hidden).

### Checker additions (real output in section 4)

Cap of 20 objects on every objects visual; "-" is one group with a valid `takeAway` and no result in questions; "vs" has two labels; baseTen ranges and no total shown in questions; every shape, name, word, unit, part-of-day, fraction phrase, sign word and digit term asked is present in the lesson's introduce/demonstrate text; both pattern rules taught in every pattern lesson; shape vocabulary taught in all four shape lessons; feedback sentences tested against the option's own value (sum, taking away, make-ten leftover, ones only, operand, whole, tens/ones digit, swapped digits, ten off, percent whole/half/quarter/percent number, one group / number of groups / group too many or few, shape sides, last number / one off / already shown). All answer solvers still recompute independently; they were extended for baseTen and takeAway.
